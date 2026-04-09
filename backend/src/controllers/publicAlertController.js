const { PublicAlert, AlertMedia, User } = require('../models');
const { createNotification } = require('../services/notificationService');

// Student: create public alert
const createPublicAlert = async (req, res) => {
  try {
    const { category, description, anonymous } = req.body;

    const alert = await PublicAlert.create({
      category,
      description,
      created_by: req.user.id,
      anonymous: anonymous === 'true' || anonymous === true,
    });

    if (req.files && req.files.length > 0) {
      for (const file of req.files) {
        await AlertMedia.create({
          alert_id: alert.id,
          file_url: `/uploads/${file.filename}`,
        });
      }
    }

    const full = await PublicAlert.findByPk(alert.id, { include: ['media'] });
    return res.status(201).json({ message: 'Alert submitted for approval', alert: full });
  } catch (err) {
    console.error('Create public alert error:', err);
    return res.status(500).json({ error: 'Server error' });
  }
};

// Public: get approved alerts
const getApprovedAlerts = async (_req, res) => {
  try {
    const alerts = await PublicAlert.findAll({
      where: { approval_status: 'Approved' },
      include: [
        'media',
        { model: User, as: 'creator', attributes: ['id', 'full_name', 'department'] },
      ],
      order: [['created_at', 'DESC']],
    });

    // Hide creator info for anonymous alerts
    const sanitized = alerts.map((a) => {
      const json = a.toJSON();
      if (json.anonymous) {
        json.creator = null;
      }
      return json;
    });

    return res.json({ alerts: sanitized });
  } catch (err) {
    console.error('Get approved alerts error:', err);
    return res.status(500).json({ error: 'Server error' });
  }
};

// Admin: get all alerts (any status)
const getAllAlerts = async (req, res) => {
  try {
    const { approval_status } = req.query;
    const where = {};
    if (approval_status) where.approval_status = approval_status;

    const alerts = await PublicAlert.findAll({
      where,
      include: [
        'media',
        { model: User, as: 'creator', attributes: ['id', 'full_name', 'department'] },
      ],
      order: [['created_at', 'DESC']],
    });
    return res.json({ alerts });
  } catch (err) {
    console.error('Get all alerts error:', err);
    return res.status(500).json({ error: 'Server error' });
  }
};

// Admin: approve or reject alert
const reviewAlert = async (req, res) => {
  try {
    const { id } = req.params;
    const { approval_status } = req.body; // 'Approved' or 'Rejected'

    const alert = await PublicAlert.findByPk(id);
    if (!alert) return res.status(404).json({ error: 'Alert not found' });

    alert.approval_status = approval_status;
    await alert.save();

    if (approval_status === 'Approved') {
      await createNotification(
        'Public Alert Published',
        `A new safety alert has been published: ${alert.category}`,
        'all'
      );
    }

    return res.json({ message: `Alert ${approval_status.toLowerCase()}`, alert });
  } catch (err) {
    console.error('Review alert error:', err);
    return res.status(500).json({ error: 'Server error' });
  }
};

// Student: get own alerts
const getMyAlerts = async (req, res) => {
  try {
    const alerts = await PublicAlert.findAll({
      where: { created_by: req.user.id },
      include: ['media'],
      order: [['created_at', 'DESC']],
    });
    return res.json({ alerts });
  } catch (err) {
    console.error('Get my alerts error:', err);
    return res.status(500).json({ error: 'Server error' });
  }
};

module.exports = { createPublicAlert, getApprovedAlerts, getAllAlerts, reviewAlert, getMyAlerts };
