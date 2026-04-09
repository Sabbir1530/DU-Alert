const { DataTypes } = require('sequelize');
const sequelize = require('../config/database');

const Complainant = sequelize.define('Complainant', {
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
  registration_number: {
    type: DataTypes.STRING(30),
    allowNull: true,
  },
}, {
  tableName: 'complainants',
  timestamps: false,
});

module.exports = Complainant;
