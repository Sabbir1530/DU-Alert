const sequelize = require('../config/database');
const User = require('./User');
const OtpVerification = require('./OtpVerification');
const EmergencyAlert = require('./EmergencyAlert');
const Complaint = require('./Complaint');
const Complainant = require('./Complainant');
const Accused = require('./Accused');
const ComplaintMedia = require('./ComplaintMedia');
const ComplaintStatusLog = require('./ComplaintStatusLog');
const PublicAlert = require('./PublicAlert');
const AlertMedia = require('./AlertMedia');
const PublicAlertReaction = require('./PublicAlertReaction');
const PublicAlertComment = require('./PublicAlertComment');
const Notification = require('./Notification');

// ── Associations ──

// Emergency Alerts
User.hasMany(EmergencyAlert, { foreignKey: 'student_id', as: 'emergencyAlerts' });
EmergencyAlert.belongsTo(User, { foreignKey: 'student_id', as: 'student' });
EmergencyAlert.belongsTo(User, { foreignKey: 'assigned_proctor', as: 'proctor' });
EmergencyAlert.belongsTo(User, { foreignKey: 'acknowledged_by_user_id', as: 'acknowledgedBy' });

// Complaints
User.hasMany(Complaint, { foreignKey: 'created_by', as: 'complaints' });
Complaint.belongsTo(User, { foreignKey: 'created_by', as: 'creator' });

Complaint.hasMany(Complainant, { foreignKey: 'complaint_id', as: 'complainants' });
Complainant.belongsTo(Complaint, { foreignKey: 'complaint_id' });

Complaint.hasMany(Accused, { foreignKey: 'complaint_id', as: 'accusedPersons' });
Accused.belongsTo(Complaint, { foreignKey: 'complaint_id' });

Complaint.hasMany(ComplaintMedia, { foreignKey: 'complaint_id', as: 'media' });
ComplaintMedia.belongsTo(Complaint, { foreignKey: 'complaint_id' });

Complaint.hasMany(ComplaintStatusLog, { foreignKey: 'complaint_id', as: 'statusLog' });
ComplaintStatusLog.belongsTo(Complaint, { foreignKey: 'complaint_id' });
ComplaintStatusLog.belongsTo(User, { foreignKey: 'updated_by', as: 'updatedByUser' });

// Public Alerts
User.hasMany(PublicAlert, { foreignKey: 'created_by', as: 'publicAlerts' });
PublicAlert.belongsTo(User, { foreignKey: 'created_by', as: 'creator' });

PublicAlert.hasMany(AlertMedia, { foreignKey: 'alert_id', as: 'media' });
AlertMedia.belongsTo(PublicAlert, { foreignKey: 'alert_id' });

PublicAlert.hasMany(PublicAlertReaction, { foreignKey: 'alert_id', as: 'reactions' });
PublicAlertReaction.belongsTo(PublicAlert, { foreignKey: 'alert_id' });
User.hasMany(PublicAlertReaction, { foreignKey: 'user_id', as: 'alertReactions' });
PublicAlertReaction.belongsTo(User, { foreignKey: 'user_id', as: 'user' });

PublicAlert.hasMany(PublicAlertComment, { foreignKey: 'alert_id', as: 'comments' });
PublicAlertComment.belongsTo(PublicAlert, { foreignKey: 'alert_id' });
User.hasMany(PublicAlertComment, { foreignKey: 'user_id', as: 'alertComments' });
PublicAlertComment.belongsTo(User, { foreignKey: 'user_id', as: 'user' });

// Notifications
User.hasMany(Notification, { foreignKey: 'user_id', as: 'notifications' });
Notification.belongsTo(User, { foreignKey: 'user_id', as: 'recipient' });

module.exports = {
  sequelize,
  User,
  OtpVerification,
  EmergencyAlert,
  Complaint,
  Complainant,
  Accused,
  ComplaintMedia,
  ComplaintStatusLog,
  PublicAlert,
  AlertMedia,
  PublicAlertReaction,
  PublicAlertComment,
  Notification,
};
