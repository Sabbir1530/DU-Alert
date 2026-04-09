const bcrypt = require('bcryptjs');
const { User, Complaint, EmergencyAlert, PublicAlert } = require('../models');
const { Op, fn, col, literal } = require('sequelize');

// List all users with optional role filter
const getUsers = async (req, res) => {
  try {
    const { role } = req.query;
    const where = {};
    if (role) where.role = role;

    const users = await User.findAll({
      where,
      attributes: { exclude: ['password_hash'] },
      order: [['created_at', 'DESC']],
    });
    return res.json({ users });
  } catch (err) {
    console.error('Get users error:', err);
    return res.status(500).json({ error: 'Server error' });
  }
};

// Create proctor account
const createProctor = async (req, res) => {
  try {
    const { full_name, university_email, phone, username, password } = req.body;

    const existing = await User.findOne({
      where: { [Op.or]: [{ university_email }, { username }] },
    });
    if (existing) {
      return res.status(409).json({ error: 'Email or username already exists' });
    }

    const password_hash = await bcrypt.hash(password, 12);
    const user = await User.create({
      full_name,
      university_email,
      phone,
      username,
      password_hash,
      role: 'proctor',
    });

    return res.status(201).json({
      message: 'Proctor account created',
      user: { id: user.id, full_name: user.full_name, username: user.username, role: user.role },
    });
  } catch (err) {
    console.error('Create proctor error:', err);
    return res.status(500).json({ error: 'Server error' });
  }
};

// Delete user
const deleteUser = async (req, res) => {
  try {
    const { id } = req.params;
    const user = await User.findByPk(id);
    if (!user) return res.status(404).json({ error: 'User not found' });
    await user.destroy();
    return res.json({ message: 'User deleted' });
  } catch (err) {
    console.error('Delete user error:', err);
    return res.status(500).json({ error: 'Server error' });
  }
};

// Analytics
const getAnalytics = async (_req, res) => {
  try {
    // Monthly complaint counts (last 12 months)
    const monthlyComplaints = await Complaint.findAll({
      attributes: [
        [fn('date_trunc', 'month', col('created_at')), 'month'],
        [fn('count', '*'), 'count'],
      ],
      where: {
        created_at: { [Op.gte]: new Date(Date.now() - 365 * 24 * 60 * 60 * 1000) },
      },
      group: [literal("date_trunc('month', created_at)")],
      order: [[literal("date_trunc('month', created_at)"), 'ASC']],
      raw: true,
    });

    // Category distribution
    const categoryDistribution = await Complaint.findAll({
      attributes: ['category', [fn('count', '*'), 'count']],
      group: ['category'],
      raw: true,
    });

    // Status counts
    const statusCounts = await Complaint.findAll({
      attributes: ['status', [fn('count', '*'), 'count']],
      group: ['status'],
      raw: true,
    });

    // Total emergency alerts
    const totalEmergencies = await EmergencyAlert.count();

    // Total users by role
    const userCounts = await User.findAll({
      attributes: ['role', [fn('count', '*'), 'count']],
      group: ['role'],
      raw: true,
    });

    // Pending public alerts
    const pendingAlerts = await PublicAlert.count({ where: { approval_status: 'Pending' } });

    return res.json({
      analytics: {
        monthlyComplaints,
        categoryDistribution,
        statusCounts,
        totalEmergencies,
        userCounts,
        pendingAlerts,
      },
    });
  } catch (err) {
    console.error('Analytics error:', err);
    return res.status(500).json({ error: 'Server error' });
  }
};

module.exports = { getUsers, createProctor, deleteUser, getAnalytics };

