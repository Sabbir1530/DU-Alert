const { DataTypes } = require('sequelize');
const sequelize = require('../config/database');

const EmergencyAlert = sequelize.define('EmergencyAlert', {
  id: {
    type: DataTypes.UUID,
    defaultValue: DataTypes.UUIDV4,
    primaryKey: true,
  },
  student_id: {
    type: DataTypes.UUID,
    allowNull: false,
    references: { model: 'users', key: 'id' },
  },
  latitude: {
    type: DataTypes.DOUBLE,
    allowNull: false,
  },
  longitude: {
    type: DataTypes.DOUBLE,
    allowNull: false,
  },
  assigned_proctor: {
    type: DataTypes.UUID,
    allowNull: true,
    references: { model: 'users', key: 'id' },
  },
  status: {
    type: DataTypes.ENUM('active', 'acknowledged', 'resolved'),
    defaultValue: 'active',
  },
}, {
  tableName: 'emergency_alerts',
  timestamps: true,
  createdAt: 'created_at',
  updatedAt: false,
});

module.exports = EmergencyAlert;
