const { DataTypes } = require('sequelize');
const sequelize = require('../config/database');

const User = sequelize.define('User', {
  id: {
    type: DataTypes.UUID,
    defaultValue: DataTypes.UUIDV4,
    primaryKey: true,
  },
  full_name: {
    type: DataTypes.STRING(120),
    allowNull: false,
  },
  department: {
    type: DataTypes.STRING(120),
    allowNull: true,
  },
  registration_number: {
    type: DataTypes.STRING(30),
    allowNull: true,
    unique: true,
  },
  university_email: {
    type: DataTypes.STRING(120),
    allowNull: false,
    unique: true,
    validate: { isEmail: true },
  },
  phone: {
    type: DataTypes.STRING(20),
    allowNull: false,
  },
  profile_image_url: {
    type: DataTypes.STRING(500),
    allowNull: true,
  },
  username: {
    type: DataTypes.STRING(50),
    allowNull: false,
    unique: true,
  },
  password_hash: {
    type: DataTypes.STRING(255),
    allowNull: false,
  },
  role: {
    type: DataTypes.ENUM('student', 'proctor', 'admin'),
    defaultValue: 'student',
    allowNull: false,
  },
}, {
  tableName: 'users',
  timestamps: true,
  createdAt: 'created_at',
  updatedAt: false,
});

module.exports = User;
