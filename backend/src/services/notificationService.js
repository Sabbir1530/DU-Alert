const { Notification, User } = require('../models');
const { Op } = require('sequelize');

const normalizePayload = (payload) => ({
  type: payload.type,
  title: payload.title,
  message: payload.message,
  reference_type: payload.referenceType || null,
  reference_id: payload.referenceId || null,
  reference_sub_id: payload.referenceSubId || null,
  data: payload.data || null,
});

/**
 * Create a notification for a single user.
 */
const createNotificationForUser = async (userId, payload) => {
  if (!userId) return null;
  return Notification.create({
    user_id: userId,
    ...normalizePayload(payload),
  });
};

/**
 * Create notifications for multiple users.
 */
const createNotificationsForUsers = async (userIds, payload) => {
  const uniqueIds = [...new Set((userIds || []).filter(Boolean))];
  if (uniqueIds.length === 0) return [];
  const base = normalizePayload(payload);
  const rows = uniqueIds.map((userId) => ({
    user_id: userId,
    ...base,
  }));
  return Notification.bulkCreate(rows, { returning: false });
};

/**
 * Create notifications for all users with the given roles.
 */
const createNotificationsForRoles = async (roles, payload) => {
  const roleList = Array.isArray(roles) ? roles : [roles];
  const users = await User.findAll({
    where: { role: { [Op.in]: roleList } },
    attributes: ['id'],
  });
  const userIds = users.map((u) => u.id);
  return createNotificationsForUsers(userIds, payload);
};

module.exports = {
  createNotificationForUser,
  createNotificationsForUsers,
  createNotificationsForRoles,
};
