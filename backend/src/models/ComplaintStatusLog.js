const { DataTypes } = require('sequelize');
const sequelize = require('../config/database');

const ComplaintStatusLog = sequelize.define('ComplaintStatusLog', {
  id: {
    type: DataTypes.UUID,
    defaultValue: DataTypes.UUIDV4,
    primaryKey: true,
  },
  complaint_id: {
    type: DataTypes.UUID,
    allowNull: false,
    references: { model: 'complaints', key: 'id' },
  },
  status: {
    type: DataTypes.ENUM('Received', 'In Progress', 'Resolved'),
    allowNull: false,
  },
  updated_by: {
    type: DataTypes.UUID,
    allowNull: false,
    references: { model: 'users', key: 'id' },
  },
}, {
  tableName: 'complaint_status_log',
  timestamps: true,
  createdAt: 'updated_at',
  updatedAt: false,
});

module.exports = ComplaintStatusLog;
