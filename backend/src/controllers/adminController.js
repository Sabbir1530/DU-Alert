const bcrypt = require('bcryptjs');
const { User, Complaint, EmergencyAlert, PublicAlert } = require('../models');
const { Op, fn, col, literal } = require('sequelize');

const isValidEmail = (value) => /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(String(value || '').trim());

const normalizeComplaintStatusForAnalytics = (value) => {
  const raw = String(value || '').trim();
  const key = raw.toLowerCase();

  if (key === 'received') return 'Received';
  if (key === 'in progress' || key === 'inprogress') return 'In Progress';
  if (key === 'resolved' || key === 'managed') return 'Resolved';
  if (key === 'rejected') return 'Rejected';
  if (key === 'pending') return 'Pending';

  return raw || 'Unknown';
};

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
    const full_name = String(req.body?.full_name || '').trim();
    const university_email = String(req.body?.university_email || '').trim().toLowerCase();
    const phone = String(req.body?.phone || '').trim();
    const username = String(req.body?.username || '').trim();
    const password = String(req.body?.password || '');

    if (!full_name || !university_email || !phone || !username || !password) {
      return res.status(400).json({ error: 'All fields are required' });
    }

    if (!isValidEmail(university_email)) {
      return res.status(400).json({ error: 'Invalid university email format' });
    }

    if (password.length < 6) {
      return res.status(400).json({ error: 'Password must be at least 6 characters' });
    }

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
      user: {
        id: user.id,
        full_name: user.full_name,
        university_email: user.university_email,
        phone: user.phone,
        username: user.username,
        role: user.role,
      },
    });
  } catch (err) {
    console.error('Create proctor error:', err);

    if (err?.name === 'SequelizeUniqueConstraintError') {
      return res.status(409).json({ error: 'Email or username already exists' });
    }

    if (err?.name === 'SequelizeValidationError') {
      return res.status(400).json({
        error: 'Validation failed',
        details: err.errors?.map((e) => e.message) || [],
      });
    }

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

    const totalUsers = await User.count();

    const normalizedStatusCounts = statusCounts.reduce((acc, row) => {
      const normalized = normalizeComplaintStatusForAnalytics(row.status);
      const count = Number(row.count || 0);
      acc[normalized] = (acc[normalized] || 0) + count;
      return acc;
    }, {});

    const received = Number(normalizedStatusCounts['Received'] || 0);
    const inProgress = Number(normalizedStatusCounts['In Progress'] || 0);
    const resolved = Number(normalizedStatusCounts['Resolved'] || 0);
    const total = Object.values(normalizedStatusCounts).reduce(
      (sum, count) => sum + Number(count || 0),
      0
    );
    const totalComplaints = total;

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

    const monthly = monthlyComplaints.map((row) => ({
      label: new Date(row.month).toISOString().slice(0, 7),
      count: Number(row.count || 0),
    }));

    const byCategory = categoryDistribution.map((row) => ({
      label: row.category,
      count: Number(row.count || 0),
    }));

    const preferredStatuses = ['Received', 'In Progress', 'Resolved'];

    const preferredStatusRows = preferredStatuses.map((label) => ({
      label,
      count: Number(normalizedStatusCounts[label] || 0),
    }));

    const byStatus = preferredStatusRows;

    return res.json({
      analytics: {
        totalUsers,
        totalComplaints,
        totalEmergencies,
        monthly,
        byCategory,
        byStatus,
        complaintSummary: {
          total,
          inProgress,
          received,
          resolved,
        },

        // Backward-compatible keys for existing clients
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
