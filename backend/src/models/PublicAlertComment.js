const { DataTypes } = require('sequelize');
const sequelize = require('../config/database');

const PublicAlertComment = sequelize.define('PublicAlertComment', {
  id: {
    type: DataTypes.UUID,
    defaultValue: DataTypes.UUIDV4,
    primaryKey: true,
  },
  alert_id: {
    type: DataTypes.UUID,
    allowNull: false,
    references: { model: 'public_alerts', key: 'id' },
  },
  user_id: {
    type: DataTypes.UUID,
    allowNull: false,
    references: { model: 'users', key: 'id' },
  },
  content: {
    type: DataTypes.TEXT,
    allowNull: false,
  },
}, {
  tableName: 'public_alert_comments',
  timestamps: true,
  createdAt: 'created_at',
  updatedAt: false,
});

module.exports = PublicAlertComment;
