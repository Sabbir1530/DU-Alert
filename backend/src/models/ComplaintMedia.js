const { DataTypes } = require('sequelize');
const sequelize = require('../config/database');

const ComplaintMedia = sequelize.define('ComplaintMedia', {
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
  file_url: {
    type: DataTypes.STRING(500),
    allowNull: false,
  },
}, {
  tableName: 'complaint_media',
  timestamps: true,
  createdAt: 'uploaded_at',
  updatedAt: false,
});

module.exports = ComplaintMedia;
