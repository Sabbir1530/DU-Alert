const { DataTypes } = require('sequelize');
const sequelize = require('../config/database');

const OtpVerification = sequelize.define('OtpVerification', {
  id: {
    type: DataTypes.UUID,
    defaultValue: DataTypes.UUIDV4,
    primaryKey: true,
  },
  phone_or_email: {
    type: DataTypes.STRING(120),
    allowNull: false,
  },
  otp_code: {
    type: DataTypes.STRING(6),
    allowNull: false,
  },
  expires_at: {
    type: DataTypes.DATE,
    allowNull: false,
  },
  verified: {
    type: DataTypes.BOOLEAN,
    defaultValue: false,
  },
}, {
  tableName: 'otp_verifications',
  timestamps: false,
});

module.exports = OtpVerification;
