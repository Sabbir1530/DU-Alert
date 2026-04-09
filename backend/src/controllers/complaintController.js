const {
  Complaint,
  Complainant,
  Accused,
  ComplaintMedia,
  ComplaintStatusLog,
  User,
} = require('../models');
const { createNotification } = require('../services/notificationService');

// Student: create complaint
const createComplaint = async (req, res) => {
  try {
    const { category, description, complainants, accused } = req.body;

    const complaint = await Complaint.create({
      category,
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
    if (complainants && Array.isArray(complainants)) {
      const parsed = typeof complainants[0] === 'string' ? complainants.map(c => JSON.parse(c)) : complainants;
      for (const c of parsed) {
        await Complainant.create({
          complaint_id: complaint.id,
          name: c.name,
          registration_number: c.registration_number || null,
        });
      }
    }

    // Add accused
    if (accused && Array.isArray(accused)) {
      const parsed = typeof accused[0] === 'string' ? accused.map(a => JSON.parse(a)) : accused;
      for (const a of parsed) {
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

    await createNotification(
      'New Complaint Filed',
      `A new ${category} complaint has been filed.`,
      'proctor'
    );

    const full = await Complaint.findByPk(complaint.id, {
      include: ['complainants', 'accusedPersons', 'media', 'statusLog'],
    });

    return res.status(201).json({ message: 'Complaint filed', complaint: full });
  } catch (err) {
    console.error('Create complaint error:', err);
    return res.status(500).json({ error: 'Server error' });
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
    const { status } = req.body;

    const complaint = await Complaint.findByPk(id);
    if (!complaint) return res.status(404).json({ error: 'Complaint not found' });

    complaint.status = status;
    await complaint.save();

    await ComplaintStatusLog.create({
      complaint_id: id,
      status,
      updated_by: req.user.id,
    });

    // Notify the student
    await createNotification(
      'Complaint Status Updated',
      `Your complaint #${id.slice(0, 8)} status is now: ${status}`,
      'student'
    );

    return res.json({ message: 'Status updated', complaint });
  } catch (err) {
    console.error('Update complaint status error:', err);
    return res.status(500).json({ error: 'Server error' });
  }
};

module.exports = {
  createComplaint,
  getMyComplaints,
  getComplaintById,
  getAllComplaints,
  updateComplaintStatus,
};
