const { DataTypes } = require('sequelize');
const sequelize = require('../config/database');

const Complaint = sequelize.define('Complaint', {
  id: {
    type: DataTypes.UUID,
    defaultValue: DataTypes.UUIDV4,
    primaryKey: true,
  },
  category: {
    type: DataTypes.ENUM(
      'Harassment',
      'Theft',
      'Property Loss',
      'Suspicious Activity',
      'Fraud',
      'Cyber Issue',
      'Other'
    ),
    allowNull: false,
  },
  title: {
    type: DataTypes.STRING(200),
    allowNull: false,
    defaultValue: 'Untitled Complaint',
  },
  description: {
    type: DataTypes.TEXT,
    allowNull: false,
  },
  status: {
    type: DataTypes.ENUM('Received', 'In Progress', 'Resolved'),
    defaultValue: 'Received',
  },
  judgement_details: {
    type: DataTypes.TEXT,
    allowNull: true,
  },
  summary: {
    type: DataTypes.TEXT,
    allowNull: true,
  },
  summarized_at: {
    type: DataTypes.DATE,
    allowNull: true,
  },
  summary_source_hash: {
    type: DataTypes.STRING(64),
    allowNull: true,
  },
  created_by: {
    type: DataTypes.UUID,
    allowNull: false,
    references: { model: 'users', key: 'id' },
  },
}, {
  tableName: 'complaints',
  timestamps: true,
  createdAt: 'created_at',
  updatedAt: 'updated_at',
});

module.exports = Complaint;
