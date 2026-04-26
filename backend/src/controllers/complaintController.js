const {
  Complaint,
  Complainant,
  Accused,
  ComplaintMedia,
  ComplaintStatusLog,
  User,
} = require('../models');
const crypto = require('crypto');
const {
  createNotificationForUser,
  createNotificationsForRoles,
} = require('../services/notificationService');

const computeSummarySourceHash = (text) =>
  crypto.createHash('sha256').update(String(text || '').trim(), 'utf8').digest('hex');

const parseIndexedJsonArray = (body, key) => {
  if (!body || typeof body !== 'object') return [];

  const direct = body[key];
  if (Array.isArray(direct)) {
    return direct
      .map((item) => {
        if (typeof item === 'string') {
          try {
            return JSON.parse(item);
          } catch {
            return null;
          }
        }
        return item;
      })
      .filter((item) => item && typeof item === 'object');
  }

  if (typeof direct === 'string' && direct.trim().startsWith('[')) {
    try {
      const arr = JSON.parse(direct);
      return Array.isArray(arr) ? arr.filter((item) => item && typeof item === 'object') : [];
    } catch {
      return [];
    }
  }

  const pattern = new RegExp(`^${key}\\[(\\d+)\\]$`);
  return Object.entries(body)
    .map(([field, value]) => {
      const match = field.match(pattern);
      if (!match) return null;

      const index = Number.parseInt(match[1], 10);
      if (!Number.isFinite(index)) return null;

      let parsed = value;
      if (typeof value === 'string') {
        try {
          parsed = JSON.parse(value);
        } catch {
          return null;
        }
      }

      if (!parsed || typeof parsed !== 'object') return null;
      return { index, parsed };
    })
    .filter(Boolean)
    .sort((a, b) => a.index - b.index)
    .map((entry) => entry.parsed);
};

const normalizeComplaintStatus = (value) => {
  const key = String(value || '').trim().toLowerCase();
  return {
    received: 'Received',
    'in progress': 'In Progress',
    inprogress: 'In Progress',
    solved: 'Resolved',
    resolved: 'Resolved',
  }[key] || null;
};

const toClientError = (err) => {
  if (!err) return { status: 500, error: 'Server error' };
  if (err.name === 'SequelizeValidationError') {
    return {
      status: 400,
      error: 'Validation failed',
      details: err.errors?.map((e) => e.message) || [],
    };
  }
  if (err.name === 'SequelizeDatabaseError') {
    return {
      status: 400,
      error: err.message || 'Invalid data',
    };
  }
  return { status: 500, error: 'Server error' };
};

// Student: create complaint
const createComplaint = async (req, res) => {
  try {
    const { category, title, description } = req.body;
    const complainants = parseIndexedJsonArray(req.body, 'complainants');
    const accused = parseIndexedJsonArray(req.body, 'accused');

    const complaint = await Complaint.create({
      category,
      title: String(title || '').trim() || `${category} Complaint`,
      description,
      created_by: req.user.id,
    });

    // Initial status log
    await ComplaintStatusLog.create({
      complaint_id: complaint.id,
      status: 'Received',
      updated_by: req.user.id,
    });

    // Add complainants
    if (complainants.length > 0) {
      for (const c of complainants) {
        await Complainant.create({
          complaint_id: complaint.id,
          name: c.name,
          registration_number: c.registration_number || null,
        });
      }
    }

    // Add accused
    if (accused.length > 0) {
      for (const a of accused) {
        await Accused.create({
          complaint_id: complaint.id,
          name: a.name,
          department: a.department || null,
          description: a.description || null,
        });
      }
    }

    // Handle uploaded media
    if (req.files && req.files.length > 0) {
      for (const file of req.files) {
        await ComplaintMedia.create({
          complaint_id: complaint.id,
          file_url: `/uploads/${file.filename}`,
        });
      }
    }

    await createNotificationsForRoles(['admin', 'proctor'], {
      type: 'complaint_review',
      title: 'New Complaint Filed',
      message: `A new ${category} complaint has been filed.`,
      referenceType: 'complaint_review',
      referenceId: complaint.id,
      data: { category },
    });

    const full = await Complaint.findByPk(complaint.id, {
      include: ['complainants', 'accusedPersons', 'media', 'statusLog'],
    });

    return res.status(201).json({ message: 'Complaint filed', complaint: full });
  } catch (err) {
    const context = {
      userId: req.user?.id,
      body: req.body,
      files: Array.isArray(req.files) ? req.files.length : 0,
    };
    console.error('Create complaint error:', err, context);
    const payload = toClientError(err);
    return res.status(payload.status).json(payload);
  }
};

// Student: list own complaints
const getMyComplaints = async (req, res) => {
  try {
    const complaints = await Complaint.findAll({
      where: { created_by: req.user.id },
      include: ['complainants', 'accusedPersons', 'media', 'statusLog'],
      order: [['created_at', 'DESC']],
    });
    return res.json({ complaints });
  } catch (err) {
    console.error('Get my complaints error:', err);
    return res.status(500).json({ error: 'Server error' });
  }
};

// Get single complaint by ID
const getComplaintById = async (req, res) => {
  try {
    const complaint = await Complaint.findByPk(req.params.id, {
      include: [
        'complainants',
        'accusedPersons',
        'media',
        {
          model: ComplaintStatusLog,
          as: 'statusLog',
          include: [{ model: User, as: 'updatedByUser', attributes: ['id', 'full_name'] }],
        },
        { model: User, as: 'creator', attributes: ['id', 'full_name', 'department'] },
      ],
    });
    if (!complaint) return res.status(404).json({ error: 'Complaint not found' });

    // Students can only see their own
    if (req.user.role === 'student' && complaint.created_by !== req.user.id) {
      return res.status(403).json({ error: 'Access denied' });
    }

    return res.json({ complaint });
  } catch (err) {
    console.error('Get complaint error:', err);
    return res.status(500).json({ error: 'Server error' });
  }
};

// Proctor/Admin: list all complaints with filters
const getAllComplaints = async (req, res) => {
  try {
    const { category, status, from, to } = req.query;
    const where = {};
    if (category) where.category = category;
    if (status) where.status = status;
    if (from || to) {
      const { Op } = require('sequelize');
      where.created_at = {};
      if (from) where.created_at[Op.gte] = new Date(from);
      if (to) where.created_at[Op.lte] = new Date(to);
    }

    const complaints = await Complaint.findAll({
      where,
      include: [
        'complainants',
        'accusedPersons',
        'media',
        'statusLog',
        { model: User, as: 'creator', attributes: ['id', 'full_name', 'department'] },
      ],
      order: [['created_at', 'DESC']],
    });
    return res.json({ complaints });
  } catch (err) {
    console.error('Get all complaints error:', err);
    return res.status(500).json({ error: 'Server error' });
  }
};

// Proctor/Admin: update complaint status
const updateComplaintStatus = async (req, res) => {
  try {
    const { id } = req.params;
    const { status, judgement_details } = req.body;

    const normalizedStatus =
      status !== undefined ? normalizeComplaintStatus(status) : null;
    const hasJudgement = judgement_details !== undefined;

    if (!normalizedStatus && !hasJudgement) {
      return res.status(400).json({
        error: 'Provide a valid status (Received, In Progress, Solved) or judgement_details',
      });
    }

    if (status !== undefined && !normalizedStatus) {
      return res.status(400).json({
        error: 'Invalid status. Use Received, In Progress, or Solved',
      });
    }

    const complaint = await Complaint.findByPk(id);
    if (!complaint) return res.status(404).json({ error: 'Complaint not found' });

    const previousStatus = complaint.status;

    if (normalizedStatus) {
      complaint.status = normalizedStatus;
    }

    if (hasJudgement) {
      const text = String(judgement_details || '').trim();
      complaint.judgement_details = text || null;
    }

    await complaint.save();

    if (normalizedStatus && previousStatus !== normalizedStatus) {
      await ComplaintStatusLog.create({
        complaint_id: id,
        status: normalizedStatus,
        updated_by: req.user.id,
      });
    }

    // Notify the student
    if (normalizedStatus) {
      await createNotificationForUser(complaint.created_by, {
        type: 'complaint_status',
        title: 'Complaint Status Updated',
        message: `Your complaint status is now: ${normalizedStatus}`,
        referenceType: 'complaint',
        referenceId: complaint.id,
        data: {
          status: normalizedStatus,
          judgement_details: complaint.judgement_details || null,
        },
      });

      await createNotificationsForRoles(['admin', 'proctor'], {
        type: 'status_review',
        title: 'Complaint Status Changed',
        message: `Complaint status updated to ${normalizedStatus} and may require review.`,
        referenceType: 'complaint_review',
        referenceId: complaint.id,
        data: {
          status: normalizedStatus,
          updated_by: req.user.id,
        },
      });
    }

    return res.json({ message: 'Status updated', complaint });
  } catch (err) {
    console.error('Update complaint status error:', err);
    return res.status(500).json({ error: 'Server error' });
  }
};

// Generate AI summary for complaint
const generateSummary = async (req, res) => {
  try {
    const { id } = req.params;
    const regenerate = String(req.query.regenerate || '').toLowerCase() === 'true';

    const complaint = await Complaint.findByPk(id);
    if (!complaint) {
      return res.status(404).json({ error: 'Complaint not found' });
    }

    // Check authorization (student can only get own, admin/proctor can get all)
    if (req.user.role === 'student' && complaint.created_by !== req.user.id) {
      return res.status(403).json({ error: 'Access denied' });
    }

    const summarySourceHash = computeSummarySourceHash(complaint.description);

    if (
      complaint.summary &&
      !regenerate &&
      (!complaint.summary_source_hash || complaint.summary_source_hash === summarySourceHash)
    ) {
      return res.json({
        summary: complaint.summary,
        cached: true,
        generatedAt: complaint.summarized_at,
      });
    }

    // Generate new summary using the configured AI provider (OpenRouter-compatible)
    const summaryService = require('../services/summaryService');
    let summary;

    try {
      summary = await summaryService.generateSummary(complaint.description);
    } catch (error) {
      console.error('Summary generation error:', {
        message: error.message,
        code: error.code,
        reason: error.reason,
      });

      const payload = {
        error: error.message || 'AI summary service unavailable. Please try again.',
      };

      if (process.env.NODE_ENV !== 'production' && error.reason) {
        payload.reason = error.reason;
      }

      return res.status(error.httpStatus || 503).json(payload);
    }

    // Cache the summary in database
    complaint.summary = summary;
    complaint.summarized_at = new Date();
    complaint.summary_source_hash = summarySourceHash;
    await complaint.save();

    return res.json({
      summary,
      cached: false,
      generatedAt: complaint.summarized_at,
    });
  } catch (err) {
    console.error('Generate summary outer error:', {
      message: err.message,
      name: err.name,
      stack: err.stack,
      errors: err.errors?.map(e => ({ 
        message: e.message, 
        type: e.type,
        path: e.path 
      }))
    });
    
    // Check if it's a Sequelize validation error
    if (err.name === 'SequelizeValidationError' || err.errors) {
      const messages = err.errors?.map(e => e.message).join(', ') || err.message;
      return res.status(400).json({ error: `Validation error: ${messages}` });
    }
    
    return res.status(500).json({ error: err.message || 'Server error' });
  }
};

module.exports = {
  createComplaint,
  getMyComplaints,
  getComplaintById,
  getAllComplaints,
  updateComplaintStatus,
  generateSummary,
};
