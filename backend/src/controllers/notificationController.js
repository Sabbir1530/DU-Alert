const { Notification } = require('../models');
const { Op } = require('sequelize');

// Get notifications for current user's role
const getNotifications = async (req, res) => {
  try {
    const notifications = await Notification.findAll({
      where: {
        target_role: { [Op.in]: [req.user.role, 'all'] },
      },
      order: [['created_at', 'DESC']],
      limit: 50,
    });
    return res.json({ notifications });
  } catch (err) {
    console.error('Get notifications error:', err);
    return res.status(500).json({ error: 'Server error' });
  }
};

// Admin: create announcement
const createAnnouncement = async (req, res) => {
  try {
    const { title, message, target_role } = req.body;
    const notification = await Notification.create({
      title,
      message,
      target_role: target_role || 'all',
    });
    return res.status(201).json({ message: 'Announcement created', notification });
  } catch (err) {
    console.error('Create announcement error:', err);
    return res.status(500).json({ error: 'Server error' });
  }
};

module.exports = { getNotifications, createAnnouncement };
