const { Notification } = require('../models');

/**
 * Create a notification record visible to users with the given role.
 */
const createNotification = async (title, message, targetRole = 'all') => {
  return Notification.create({ title, message, target_role: targetRole });
};

module.exports = { createNotification };
