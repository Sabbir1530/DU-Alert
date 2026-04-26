const { DataTypes } = require('sequelize');
const sequelize = require('../config/database');

const PublicAlertReaction = sequelize.define('PublicAlertReaction', {
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
  reaction_type: {
    type: DataTypes.ENUM('like', 'important', 'safe', 'alerted', 'support', 'concern'),
    allowNull: false,
    defaultValue: 'like',
  },
}, {
  tableName: 'public_alert_reactions',
  timestamps: true,
  createdAt: 'created_at',
  updatedAt: 'updated_at',
  indexes: [
    {
      unique: true,
      fields: ['alert_id', 'user_id'],
      name: 'uniq_public_alert_reaction_per_user',
    },
  ],
});

module.exports = PublicAlertReaction;
