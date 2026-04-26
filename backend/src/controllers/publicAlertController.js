const {
  PublicAlert,
  AlertMedia,
  User,
  PublicAlertReaction,
  PublicAlertComment,
} = require('../models');
const {
  createNotificationForUser,
  createNotificationsForRoles,
} = require('../services/notificationService');

const FEED_CACHE_TTL_MS = Number(process.env.ALERT_FEED_CACHE_TTL_MS || 30000);
const FEED_DEFAULT_LIMIT = 10;
const FEED_MAX_LIMIT = 25;

const feedCache = new Map();

const clearFeedCache = () => {
  feedCache.clear();
};

const readFeedCache = (key) => {
  const cached = feedCache.get(key);
  if (!cached) return null;
  if (Date.now() > cached.expiresAt) {
    feedCache.delete(key);
    return null;
  }
  return cached.payload;
};

const writeFeedCache = (key, payload) => {
  feedCache.set(key, {
    payload,
    expiresAt: Date.now() + FEED_CACHE_TTL_MS,
  });
};

const normalizeReactionType = (value) => {
  const raw = String(value || '').trim().toLowerCase();
  const mapped = {
    support: 'safe',
    concern: 'alerted',
  }[raw] || raw;

  const allowed = new Set(['like', 'important', 'safe', 'alerted']);
  return allowed.has(mapped) ? mapped : null;
};

const parsePage = (value) => {
  const parsed = Number.parseInt(String(value || '1'), 10);
  return Number.isFinite(parsed) && parsed > 0 ? parsed : 1;
};

const parseLimit = (value, fallback = FEED_DEFAULT_LIMIT) => {
  const parsed = Number.parseInt(String(value || ''), 10);
  if (!Number.isFinite(parsed) || parsed < 1) return fallback;
  return Math.min(parsed, FEED_MAX_LIMIT);
};

const mediaTypeFromPath = (pathValue) => {
  const lower = String(pathValue || '').toLowerCase();
  if (
    lower.endsWith('.jpg') ||
    lower.endsWith('.jpeg') ||
    lower.endsWith('.png') ||
    lower.endsWith('.gif') ||
    lower.endsWith('.webp') ||
    lower.endsWith('.heic') ||
    lower.endsWith('.heif')
  ) {
    return 'image';
  }
  if (
    lower.endsWith('.mp4') ||
    lower.endsWith('.mov') ||
    lower.endsWith('.m4v') ||
    lower.endsWith('.webm')
  ) {
    return 'video';
  }
  if (lower.endsWith('.pdf')) {
    return 'pdf';
  }
  return 'file';
};

const mediaTypeFromMime = (mimeType) => {
  const value = String(mimeType || '').toLowerCase();
  if (value.startsWith('image/')) return 'image';
  if (value.startsWith('video/')) return 'video';
  if (value === 'application/pdf') return 'pdf';
  return 'file';
};

const normalizeMedia = (media) => {
  const fileUrl = media?.file_url || media?.url || '';
  const fileType = media?.file_type || media?.type || mediaTypeFromPath(fileUrl);
  return {
    id: media?.id,
    file_url: fileUrl,
    url: fileUrl,
    file_type: fileType,
    type: fileType,
  };
};

const normalizeUser = (user) => {
  if (!user) return null;
  return {
    id: user.id,
    full_name: user.full_name,
    department: user.department,
    role: user.role,
    profile_image_url: user.profile_image_url || null,
  };
};

const toReactionSummary = (reactions) => {
  const summary = { like: 0, important: 0, safe: 0, alerted: 0 };
  for (const reaction of reactions || []) {
    const normalized = normalizeReactionType(reaction?.reaction_type);
    if (normalized) {
      summary[normalized] += 1;
    }
  }
  return summary;
};

const enrichAlert = (alert, viewerUserId = null) => {
  const json = typeof alert.toJSON === 'function' ? alert.toJSON() : { ...alert };
  const reactions = Array.isArray(json.reactions) ? json.reactions : [];
  const comments = Array.isArray(json.comments) ? json.comments : [];

  const reactionSummary = toReactionSummary(reactions);
  const myReaction = viewerUserId
    ? normalizeReactionType(reactions.find((r) => r.user_id === viewerUserId)?.reaction_type)
    : null;

  const normalizedComments = comments
    .map((comment) => ({
      id: comment.id,
      alert_id: comment.alert_id,
      user_id: comment.user_id,
      content: comment.content,
      created_at: comment.created_at,
      user: normalizeUser(comment.user),
    }))
    .sort((a, b) => new Date(a.created_at) - new Date(b.created_at));

  const normalizedMedia = (json.media || []).map((m) => normalizeMedia(m));

  delete json.reactions;

  json.title = String(json.title || '').trim() || json.category;
  json.media = normalizedMedia;
  json.comments = normalizedComments;
  json.comment_count = normalizedComments.length;
  json.reaction_summary = reactionSummary;
  json.reaction_count = Object.values(reactionSummary).reduce((sum, n) => sum + n, 0);
  json.my_reaction = myReaction;
  json.creator = json.anonymous ? null : normalizeUser(json.creator);

  return json;
};

const alertEngagementInclude = [
  { model: AlertMedia, as: 'media' },
  {
    model: User,
    as: 'creator',
    attributes: ['id', 'full_name', 'department', 'role', 'profile_image_url'],
  },
  {
    model: PublicAlertReaction,
    as: 'reactions',
    attributes: ['id', 'user_id', 'reaction_type'],
  },
  {
    model: PublicAlertComment,
    as: 'comments',
    attributes: ['id', 'alert_id', 'user_id', 'content', 'created_at'],
    include: [
      {
        model: User,
        as: 'user',
        attributes: ['id', 'full_name', 'department', 'role', 'profile_image_url'],
      },
    ],
  },
];

const approvedPublicWhere = {
  approval_status: 'Approved',
  visibility: 'PUBLIC',
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

const createPublicAlert = async (req, res) => {
  try {
    const { title, category, description, anonymous } = req.body;

    const alert = await PublicAlert.create({
      title: String(title || '').trim() || String(category || '').trim() || 'Campus Safety Alert',
      category,
      description,
      created_by: req.user.id,
      anonymous: anonymous === 'true' || anonymous === true,
      visibility: String(req.body?.visibility || 'PUBLIC').toUpperCase() === 'PRIVATE'
        ? 'PRIVATE'
        : 'PUBLIC',
    });

    if (req.files && req.files.length > 0) {
      for (const file of req.files) {
        await AlertMedia.create({
          alert_id: alert.id,
          file_url: `/uploads/${file.filename}`,
          file_type: mediaTypeFromMime(file.mimetype),
        });
      }
    }

    await createNotificationsForRoles(['admin', 'proctor'], {
      type: 'public_alert_review',
      title: 'New Public Alert Submitted',
      message: `A new public alert was submitted: ${alert.category}.`,
      referenceType: 'public_alert_review',
      referenceId: alert.id,
      data: { category: alert.category },
    });

    clearFeedCache();

    const full = await PublicAlert.findByPk(alert.id, { include: ['media'] });
    const payload = full ? full.toJSON() : alert.toJSON();
    payload.media = (payload.media || []).map((m) => normalizeMedia(m));
    payload.title = String(payload.title || '').trim() || payload.category;

    return res.status(201).json({ message: 'Alert submitted for approval', alert: payload });
  } catch (err) {
    const context = {
      userId: req.user?.id,
      body: req.body,
      files: Array.isArray(req.files) ? req.files.length : 0,
    };
    console.error('Create public alert error:', err, context);
    const payload = toClientError(err);
    return res.status(payload.status).json(payload);
  }
};

const getApprovedAlerts = async (req, res) => {
  try {
    const page = parsePage(req.query.page);
    const limit = parseLimit(req.query.limit);
    const offset = (page - 1) * limit;
    const viewerUserId = req.user?.id || 'anon';

    const cacheKey = `${viewerUserId}:${page}:${limit}`;
    const cached = readFeedCache(cacheKey);
    if (cached) {
      return res.json(cached);
    }

    const { count, rows } = await PublicAlert.findAndCountAll({
      where: approvedPublicWhere,
      include: alertEngagementInclude,
      order: [['created_at', 'DESC']],
      offset,
      limit,
      distinct: true,
    });

    const alerts = rows.map((a) => enrichAlert(a, req.user?.id || null));
    const totalPages = Math.max(1, Math.ceil(count / limit));

    const payload = {
      alerts,
      pagination: {
        page,
        limit,
        total: count,
        total_pages: totalPages,
        has_more: page < totalPages,
      },
    };

    writeFeedCache(cacheKey, payload);
    return res.json(payload);
  } catch (err) {
    console.error('Get approved alerts error:', err);
    return res.status(500).json({ error: 'Server error' });
  }
};

const getAllAlerts = async (req, res) => {
  try {
    const { approval_status } = req.query;
    const where = {};
    if (approval_status) where.approval_status = approval_status;

    const page = parsePage(req.query.page);
    const limit = parseLimit(req.query.limit, 20);
    const offset = (page - 1) * limit;

    const { count, rows } = await PublicAlert.findAndCountAll({
      where,
      include: alertEngagementInclude,
      order: [['created_at', 'DESC']],
      offset,
      limit,
      distinct: true,
    });

    const totalPages = Math.max(1, Math.ceil(count / limit));

    return res.json({
      alerts: rows.map((a) => enrichAlert(a, req.user?.id || null)),
      pagination: {
        page,
        limit,
        total: count,
        total_pages: totalPages,
        has_more: page < totalPages,
      },
    });
  } catch (err) {
    console.error('Get all alerts error:', err);
    return res.status(500).json({ error: 'Server error' });
  }
};

const reviewAlert = async (req, res) => {
  try {
    const { id } = req.params;
    const { approval_status, rejection_reason } = req.body;

    const normalizedStatus = {
      approved: 'Approved',
      rejected: 'Rejected',
      pending: 'Pending',
    }[String(approval_status || '').trim().toLowerCase()];

    if (!normalizedStatus || normalizedStatus === 'Pending') {
      return res.status(400).json({
        error: 'approval_status must be Approved or Rejected',
      });
    }

    const alert = await PublicAlert.findByPk(id);
    if (!alert) return res.status(404).json({ error: 'Alert not found' });

    alert.approval_status = normalizedStatus;
    if (normalizedStatus === 'Rejected') {
      const reason = String(rejection_reason || '').trim();
      if (!reason) {
        return res.status(400).json({ error: 'Rejection reason is required' });
      }
      alert.rejection_reason = reason;
    } else {
      alert.rejection_reason = null;
    }
    await alert.save();

    clearFeedCache();

    await createNotificationForUser(alert.created_by, {
      type: 'public_alert_moderation',
      title: `Public Alert ${normalizedStatus}`,
      message: normalizedStatus === 'Approved'
        ? 'Your public alert has been approved and published.'
        : `Your public alert was rejected. Reason: ${alert.rejection_reason}`,
      referenceType: 'public_alert',
      referenceId: alert.id,
      data: {
        status: normalizedStatus,
        rejection_reason: alert.rejection_reason || null,
      },
    });

    return res.json({ message: `Alert ${normalizedStatus.toLowerCase()}`, alert });
  } catch (err) {
    console.error('Review alert error:', err);
    return res.status(500).json({ error: 'Server error' });
  }
};

const getMyAlerts = async (req, res) => {
  try {
    const page = parsePage(req.query.page);
    const limit = parseLimit(req.query.limit, 20);
    const offset = (page - 1) * limit;

    const { count, rows } = await PublicAlert.findAndCountAll({
      where: { created_by: req.user.id },
      include: alertEngagementInclude,
      order: [['created_at', 'DESC']],
      offset,
      limit,
      distinct: true,
    });

    const totalPages = Math.max(1, Math.ceil(count / limit));

    return res.json({
      alerts: rows.map((a) => enrichAlert(a, req.user.id)),
      pagination: {
        page,
        limit,
        total: count,
        total_pages: totalPages,
        has_more: page < totalPages,
      },
    });
  } catch (err) {
    console.error('Get my alerts error:', err);
    return res.status(500).json({ error: 'Server error' });
  }
};

const getAlertById = async (req, res) => {
  try {
    const { id } = req.params;
    const alert = await PublicAlert.findByPk(id, {
      include: alertEngagementInclude,
    });

    if (!alert) return res.status(404).json({ error: 'Alert not found' });

    const canView =
      req.user.role === 'admin' ||
      req.user.role === 'proctor' ||
      alert.created_by === req.user.id ||
      (alert.approval_status === 'Approved' && alert.visibility === 'PUBLIC');

    if (!canView) return res.status(403).json({ error: 'Access denied' });

    return res.json({ alert: enrichAlert(alert, req.user.id) });
  } catch (err) {
    console.error('Get alert by id error:', err);
    return res.status(500).json({ error: 'Server error' });
  }
};

const reactToAlert = async (req, res) => {
  try {
    const { id } = req.params;
    const reactionType = normalizeReactionType(req.body?.reaction_type);

    if (!reactionType) {
      return res.status(400).json({
        error: 'reaction_type must be one of: like, important, safe, alerted',
      });
    }

    const alert = await PublicAlert.findOne({
      where: { id, ...approvedPublicWhere },
      attributes: ['id', 'created_by', 'category', 'title'],
    });
    if (!alert) {
      return res.status(404).json({ error: 'Approved public alert not found' });
    }

    const [reaction, created] = await PublicAlertReaction.findOrCreate({
      where: { alert_id: id, user_id: req.user.id },
      defaults: { reaction_type: reactionType },
    });

    if (!created && reaction.reaction_type !== reactionType) {
      reaction.reaction_type = reactionType;
      await reaction.save();
    }

    clearFeedCache();

    const allReactions = await PublicAlertReaction.findAll({
      where: { alert_id: id },
      attributes: ['reaction_type'],
    });

    const reactionSummary = toReactionSummary(allReactions);

    if (alert.created_by && alert.created_by !== req.user.id) {
      await createNotificationForUser(alert.created_by, {
        type: 'public_alert_reaction',
        title: 'New Reaction',
        message: `${req.user.full_name} reacted to your alert.`,
        referenceType: 'public_alert',
        referenceId: alert.id,
        data: { reaction_type: reactionType },
      });
    }

    return res.json({
      message: created ? 'Reaction saved' : 'Reaction updated',
      my_reaction: reactionType,
      reaction_summary: reactionSummary,
      reaction_count: Object.values(reactionSummary).reduce((sum, n) => sum + n, 0),
    });
  } catch (err) {
    console.error('React to alert error:', err);
    return res.status(500).json({ error: 'Server error' });
  }
};

const removeReaction = async (req, res) => {
  try {
    const { id } = req.params;

    const reaction = await PublicAlertReaction.findOne({
      where: { alert_id: id, user_id: req.user.id },
    });

    if (!reaction) {
      return res.status(404).json({ error: 'Reaction not found' });
    }

    await reaction.destroy();
    clearFeedCache();

    const allReactions = await PublicAlertReaction.findAll({
      where: { alert_id: id },
      attributes: ['reaction_type'],
    });

    const reactionSummary = toReactionSummary(allReactions);

    return res.json({
      message: 'Reaction removed',
      my_reaction: null,
      reaction_summary: reactionSummary,
      reaction_count: Object.values(reactionSummary).reduce((sum, n) => sum + n, 0),
    });
  } catch (err) {
    console.error('Remove alert reaction error:', err);
    return res.status(500).json({ error: 'Server error' });
  }
};

const addComment = async (req, res) => {
  try {
    const { id } = req.params;
    const content = String(req.body?.content || '').trim();

    if (!content) {
      return res.status(400).json({ error: 'Comment content is required' });
    }
    if (content.length > 1000) {
      return res.status(400).json({ error: 'Comment must be 1000 characters or fewer' });
    }

    const alert = await PublicAlert.findOne({
      where: { id, ...approvedPublicWhere },
      attributes: ['id', 'created_by', 'category', 'title'],
    });
    if (!alert) {
      return res.status(404).json({ error: 'Approved public alert not found' });
    }

    const comment = await PublicAlertComment.create({
      alert_id: id,
      user_id: req.user.id,
      content,
    });

    clearFeedCache();

    const hydrated = await PublicAlertComment.findByPk(comment.id, {
      attributes: ['id', 'alert_id', 'user_id', 'content', 'created_at'],
      include: [
        {
          model: User,
          as: 'user',
          attributes: ['id', 'full_name', 'department', 'role', 'profile_image_url'],
        },
      ],
    });

    const payload = {
      id: hydrated.id,
      alert_id: hydrated.alert_id,
      user_id: hydrated.user_id,
      content: hydrated.content,
      created_at: hydrated.created_at,
      user: normalizeUser(hydrated.user),
    };

    if (alert.created_by && alert.created_by !== req.user.id) {
      await createNotificationForUser(alert.created_by, {
        type: 'public_alert_comment',
        title: 'New Comment',
        message: `${req.user.full_name} commented on your alert.`,
        referenceType: 'public_alert_comment',
        referenceId: alert.id,
        referenceSubId: comment.id,
      });
    }

    return res.status(201).json({ message: 'Comment added', comment: payload });
  } catch (err) {
    console.error('Add alert comment error:', err);
    return res.status(500).json({ error: 'Server error' });
  }
};

const getAlertComments = async (req, res) => {
  try {
    const { id } = req.params;
    const page = parsePage(req.query.page);
    const limit = parseLimit(req.query.limit, 10);
    const offset = (page - 1) * limit;

    const alert = await PublicAlert.findOne({
      where: { id, ...approvedPublicWhere },
      attributes: ['id'],
    });
    if (!alert) {
      return res.status(404).json({ error: 'Approved public alert not found' });
    }

    const { count, rows } = await PublicAlertComment.findAndCountAll({
      where: { alert_id: id },
      attributes: ['id', 'alert_id', 'user_id', 'content', 'created_at'],
      include: [
        {
          model: User,
          as: 'user',
          attributes: ['id', 'full_name', 'department', 'role', 'profile_image_url'],
        },
      ],
      order: [['created_at', 'DESC']],
      offset,
      limit,
    });

    const totalPages = Math.max(1, Math.ceil(count / limit));

    return res.json({
      comments: rows.map((comment) => ({
        id: comment.id,
        alert_id: comment.alert_id,
        user_id: comment.user_id,
        content: comment.content,
        created_at: comment.created_at,
        user: normalizeUser(comment.user),
      })),
      pagination: {
        page,
        limit,
        total: count,
        total_pages: totalPages,
        has_more: page < totalPages,
      },
    });
  } catch (err) {
    console.error('Get alert comments error:', err);
    return res.status(500).json({ error: 'Server error' });
  }
};

const deleteComment = async (req, res) => {
  try {
    const commentId = req.params.commentId || req.params.id;
    const comment = await PublicAlertComment.findByPk(commentId);

    if (!comment) {
      return res.status(404).json({ error: 'Comment not found' });
    }

    if (comment.user_id !== req.user.id) {
      return res.status(403).json({ error: 'You can delete only your own comments' });
    }

    await comment.destroy();
    clearFeedCache();

    return res.json({ message: 'Comment deleted' });
  } catch (err) {
    console.error('Delete alert comment error:', err);
    return res.status(500).json({ error: 'Server error' });
  }
};

module.exports = {
  createPublicAlert,
  getApprovedAlerts,
  getAllAlerts,
  reviewAlert,
  getMyAlerts,
  getAlertById,
  reactToAlert,
  removeReaction,
  addComment,
  getAlertComments,
  deleteComment,
};
