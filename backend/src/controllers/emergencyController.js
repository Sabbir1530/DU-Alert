const { EmergencyAlert, User } = require('../models');
const { createNotification } = require('../services/notificationService');

// Student sends SOS
const createEmergency = async (req, res) => {
  try {
    const { latitude, longitude } = req.body;
    const alert = await EmergencyAlert.create({
      student_id: req.user.id,
      latitude,
      longitude,
    });

    // Notify proctors
    await createNotification(
      'Emergency SOS Alert',
      `SOS from ${req.user.full_name} at (${latitude}, ${longitude})`,
      'proctor'
    );

    return res.status(201).json({ message: 'SOS alert sent', alert });
  } catch (err) {
    console.error('Emergency create error:', err);
    return res.status(500).json({ error: 'Server error' });
  }
};

// Proctor/Admin: list all emergency alerts
const getEmergencies = async (req, res) => {
  try {
    const { status } = req.query;
    const where = {};
    if (status) where.status = status;

    const alerts = await EmergencyAlert.findAll({
      where,
      include: [
        { model: User, as: 'student', attributes: ['id', 'full_name', 'phone', 'department'] },
        { model: User, as: 'proctor', attributes: ['id', 'full_name'] },
      ],
      order: [['created_at', 'DESC']],
    });
    return res.json({ alerts });
  } catch (err) {
    console.error('Get emergencies error:', err);
    return res.status(500).json({ error: 'Server error' });
  }
};

// Proctor: acknowledge / resolve alert
const updateEmergencyStatus = async (req, res) => {
  try {
    const { id } = req.params;
    const { status } = req.body;

    const alert = await EmergencyAlert.findByPk(id);
    if (!alert) return res.status(404).json({ error: 'Alert not found' });

    alert.status = status;
    if (status === 'acknowledged') {
      alert.assigned_proctor = req.user.id;
    }
    await alert.save();

    return res.json({ message: 'Status updated', alert });
  } catch (err) {
    console.error('Update emergency error:', err);
    return res.status(500).json({ error: 'Server error' });
  }
};

// Student: list own emergency alerts
const getMyEmergencies = async (req, res) => {
  try {
    const alerts = await EmergencyAlert.findAll({
      where: { student_id: req.user.id },
      order: [['created_at', 'DESC']],
    });
    return res.json({ alerts });
  } catch (err) {
    console.error('Get my emergencies error:', err);
    return res.status(500).json({ error: 'Server error' });
  }
};

module.exports = { createEmergency, getEmergencies, updateEmergencyStatus, getMyEmergencies };
