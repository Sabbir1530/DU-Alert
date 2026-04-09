const { DataTypes } = require('sequelize');
const sequelize = require('../config/database');

const AlertMedia = sequelize.define('AlertMedia', {
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
  file_url: {
    type: DataTypes.STRING(500),
    allowNull: false,
  },
}, {
  tableName: 'alert_media',
  timestamps: false,
});

module.exports = AlertMedia;
