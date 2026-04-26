const { EmergencyAlert, User } = require('../models');
const { Op } = require('sequelize');
const { createNotificationForUser, createNotificationsForRoles } = require('../services/notificationService');
const { sendEmail } = require('../services/emailService');

const toFiniteNumber = (value) => {
  const parsed = Number.parseFloat(String(value));
  return Number.isFinite(parsed) ? parsed : null;
};

const haversineDistanceKm = (lat1, lon1, lat2, lon2) => {
  const toRad = (deg) => (deg * Math.PI) / 180;
  const R = 6371;
  const dLat = toRad(lat2 - lat1);
  const dLon = toRad(lon2 - lon1);
  const a =
    Math.sin(dLat / 2) * Math.sin(dLat / 2) +
    Math.cos(toRad(lat1)) * Math.cos(toRad(lat2)) *
      Math.sin(dLon / 2) * Math.sin(dLon / 2);
  const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
  return R * c;
};

// Student sends SOS
const createEmergency = async (req, res) => {
  try {
    const { latitude, longitude } = req.body;
    const alert = await EmergencyAlert.create({
      student_id: req.user.id,
      latitude,
      longitude,
    });

    // Notify admins and proctors in-app.
    await createNotificationsForRoles(['admin', 'proctor'], {
      type: 'emergency_alert',
      title: 'Emergency SOS Alert',
      message: `SOS from ${req.user.full_name} at (${latitude}, ${longitude})`,
      referenceType: 'emergency_alert',
      referenceId: alert.id,
      data: {
        latitude,
        longitude,
        student_id: req.user.id,
      },
    });

    // Notify all users by email with victim and location details.
    try {
      const recipients = await User.findAll({
        attributes: ['university_email'],
      });

      const emails = [
        ...new Set(
          recipients
            .map((u) => String(u.university_email || '').trim().toLowerCase())
            .filter(Boolean)
        ),
      ];

      if (emails.length > 0) {
        const mapsLink = `https://www.google.com/maps?q=${latitude},${longitude}`;
        const victimName = req.user.full_name || 'Unknown';
        const victimDepartment = req.user.department || 'N/A';

        await sendEmail(
          emails,
          `DU Alert SOS: ${victimName} needs immediate help`,
          `
            <h2>Emergency SOS Alert</h2>
            <p><strong>Victim Name:</strong> ${victimName}</p>
            <p><strong>Department:</strong> ${victimDepartment}</p>
            <p><strong>Location:</strong> ${latitude}, ${longitude}</p>
            <p><a href="${mapsLink}" target="_blank" rel="noopener noreferrer">Open location in Google Maps</a></p>
            <p><strong>Time:</strong> ${new Date(alert.created_at).toISOString()}</p>
            <p>Please respond immediately.</p>
          `
        );
      }
    } catch (emailErr) {
      console.error('Emergency email notification failed:', emailErr);
    }

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
        { model: User, as: 'acknowledgedBy', attributes: ['id', 'full_name'] },
      ],
      order: [['created_at', 'DESC']],
    });
    return res.json({ alerts });
  } catch (err) {
    console.error('Get emergencies error:', err);
    return res.status(500).json({ error: 'Server error' });
  }
};

// Get single emergency alert by ID
const getEmergencyById = async (req, res) => {
  try {
    const { id } = req.params;
    const alert = await EmergencyAlert.findByPk(id, {
      include: [
        { model: User, as: 'student', attributes: ['id', 'full_name', 'phone', 'department'] },
        { model: User, as: 'proctor', attributes: ['id', 'full_name'] },
        { model: User, as: 'acknowledgedBy', attributes: ['id', 'full_name'] },
      ],
    });

    if (!alert) return res.status(404).json({ error: 'Alert not found' });

    if (req.user.role === 'student' && alert.student_id !== req.user.id) {
      return res.status(403).json({ error: 'Access denied' });
    }

    return res.json({ alert });
  } catch (err) {
    console.error('Get emergency by id error:', err);
    return res.status(500).json({ error: 'Server error' });
  }
};

// Proctor: acknowledge / resolve alert
const updateEmergencyStatus = async (req, res) => {
  try {
    const { id } = req.params;
    const { status } = req.body;

    if (!['acknowledged', 'resolved'].includes(status)) {
      return res.status(400).json({ error: 'Invalid status. Use acknowledged or resolved.' });
    }

    if (status === 'acknowledged') {
      const responderLatitude = toFiniteNumber(req.body?.responder_latitude);
      const responderLongitude = toFiniteNumber(req.body?.responder_longitude);

      const currentAlert = await EmergencyAlert.findByPk(id);
      if (!currentAlert) return res.status(404).json({ error: 'Alert not found' });

      const canComputeDistance =
        responderLatitude !== null &&
        responderLongitude !== null &&
        Number.isFinite(currentAlert.latitude) &&
        Number.isFinite(currentAlert.longitude);

      const distanceKm = canComputeDistance
        ? haversineDistanceKm(
            currentAlert.latitude,
            currentAlert.longitude,
            responderLatitude,
            responderLongitude
          )
        : null;

      const acknowledgedAt = new Date();
      const [updatedCount] = await EmergencyAlert.update(
        {
          status: 'acknowledged',
          assigned_proctor: req.user.id,
          acknowledged_by_user_id: req.user.id,
          acknowledged_by_name: req.user.full_name,
          acknowledged_at: acknowledgedAt,
          responder_location:
            responderLatitude !== null && responderLongitude !== null
              ? { latitude: responderLatitude, longitude: responderLongitude }
              : null,
          distance_in_km: distanceKm !== null ? Number(distanceKm.toFixed(3)) : null,
        },
        {
          where: {
            id,
            status: 'active',
            acknowledged_by_user_id: null,
          },
        }
      );

      if (!updatedCount) {
        const existing = await EmergencyAlert.findByPk(id, {
          include: [{ model: User, as: 'acknowledgedBy', attributes: ['id', 'full_name'] }],
        });

        if (!existing) return res.status(404).json({ error: 'Alert not found' });

        const byName =
          existing.acknowledged_by_name || existing.acknowledgedBy?.full_name || 'another responder';
        return res.status(409).json({
          error: 'Alert already acknowledged by another responder.',
          details: `Already acknowledged by ${byName}`,
          alert: existing,
        });
      }

      const alert = await EmergencyAlert.findByPk(id, {
        include: [
          { model: User, as: 'student', attributes: ['id', 'full_name', 'phone', 'department'] },
          { model: User, as: 'acknowledgedBy', attributes: ['id', 'full_name'] },
        ],
      });

      const distanceText = alert?.distance_in_km !== null && alert?.distance_in_km !== undefined
        ? Number(alert.distance_in_km).toFixed(1)
        : 'an unknown';

      await createNotificationForUser(alert.student_id, {
        type: 'emergency_acknowledged',
        title: 'Emergency Alert Acknowledged',
        message:
          distanceText === 'an unknown'
            ? `Your emergency alert has been acknowledged by ${req.user.full_name}.`
            : `Your emergency alert has been acknowledged by ${req.user.full_name}, who is approximately ${distanceText} km away.`,
        referenceType: 'emergency_alert',
        referenceId: alert.id,
        data: {
          acknowledged_by_user_id: req.user.id,
          acknowledged_by_name: req.user.full_name,
          acknowledged_at: acknowledgedAt.toISOString(),
          distance_in_km: alert.distance_in_km,
          responder_location: alert.responder_location,
        },
      });

      return res.json({ message: 'Alert acknowledged', alert });
    }

    // status === 'resolved'
    const [resolvedCount] = await EmergencyAlert.update(
      { status: 'resolved' },
      {
        where: {
          id,
          status: { [Op.in]: ['active', 'acknowledged'] },
        },
      }
    );

    if (!resolvedCount) {
      return res.status(404).json({ error: 'Alert not found' });
    }

    const alert = await EmergencyAlert.findByPk(id);
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

module.exports = {
  createEmergency,
  getEmergencies,
  getEmergencyById,
  updateEmergencyStatus,
  getMyEmergencies,
};
