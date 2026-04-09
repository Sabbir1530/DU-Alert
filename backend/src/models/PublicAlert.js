const { DataTypes } = require('sequelize');
const sequelize = require('../config/database');

const PublicAlert = sequelize.define('PublicAlert', {
  id: {
    type: DataTypes.UUID,
    defaultValue: DataTypes.UUIDV4,
    primaryKey: true,
  },
  category: {
    type: DataTypes.STRING(80),
    allowNull: false,
  },
  description: {
    type: DataTypes.TEXT,
    allowNull: false,
  },
  created_by: {
    type: DataTypes.UUID,
    allowNull: false,
    references: { model: 'users', key: 'id' },
  },
  anonymous: {
    type: DataTypes.BOOLEAN,
    defaultValue: false,
  },
  approval_status: {
    type: DataTypes.ENUM('Pending', 'Approved', 'Rejected'),
    defaultValue: 'Pending',
  },
}, {
  tableName: 'public_alerts',
  timestamps: true,
  createdAt: 'created_at',
  updatedAt: false,
});

module.exports = PublicAlert;
