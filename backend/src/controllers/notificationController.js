const { Notification } = require('../models');
const { createNotificationsForRoles } = require('../services/notificationService');

// Get notifications for current user
const getNotifications = async (req, res) => {
  try {
    const onlyUnread = String(req.query.unread || '').toLowerCase() === 'true';
    const limit = Number.parseInt(String(req.query.limit || '50'), 10);
    const safeLimit = Number.isFinite(limit) && limit > 0 ? Math.min(limit, 100) : 50;
    const where = { user_id: req.user.id };
    if (onlyUnread) where.is_read = false;

    const notifications = await Notification.findAll({
      where,
      order: [['created_at', 'DESC']],
      limit: safeLimit,
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
    const roles = target_role ? [target_role] : ['student', 'proctor', 'admin'];
    await createNotificationsForRoles(roles, {
      type: 'announcement',
      title: String(title || 'Announcement'),
      message: String(message || ''),
      referenceType: 'announcement',
    });
    return res.status(201).json({ message: 'Announcement created' });
  } catch (err) {
    console.error('Create announcement error:', err);
    return res.status(500).json({ error: 'Server error' });
  }
};

// Mark single notification as read
const markRead = async (req, res) => {
  try {
    const { id } = req.params;
    const [count] = await Notification.update(
      { is_read: true },
      { where: { id, user_id: req.user.id } }
    );
    if (count === 0) return res.status(404).json({ error: 'Notification not found' });
    return res.json({ message: 'Notification marked as read' });
  } catch (err) {
    console.error('Mark notification read error:', err);
    return res.status(500).json({ error: 'Server error' });
  }
};

// Mark all notifications as read
const markAllRead = async (req, res) => {
  try {
    await Notification.update(
      { is_read: true },
      { where: { user_id: req.user.id, is_read: false } }
    );
    return res.json({ message: 'All notifications marked as read' });
  } catch (err) {
    console.error('Mark all notifications read error:', err);
    return res.status(500).json({ error: 'Server error' });
  }
};

module.exports = { getNotifications, createAnnouncement, markRead, markAllRead };
