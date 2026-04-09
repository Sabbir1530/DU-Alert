const { DataTypes } = require('sequelize');
const sequelize = require('../config/database');

const Accused = sequelize.define('Accused', {
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
  name: {
    type: DataTypes.STRING(120),
    allowNull: false,
  },
  department: {
    type: DataTypes.STRING(120),
    allowNull: true,
  },
  description: {
    type: DataTypes.TEXT,
    allowNull: true,
  },
}, {
  tableName: 'accused',
  timestamps: false,
});

module.exports = Accused;

