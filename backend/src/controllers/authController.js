const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const { User, OtpVerification } = require('../models');
const { sendOtp, verifyOtp } = require('../services/otpService');
const DEPARTMENTS = require('../utils/departments');

// Step 1: Register — collect info & send OTP
const register = async (req, res) => {
  try {
    const { full_name, department, registration_number, university_email, phone } = req.body;

    const existing = await User.findOne({
      where: { university_email },
    });
    if (existing) {
      return res.status(409).json({ error: 'Email already registered' });
    }

    const existingReg = await User.findOne({
      where: { registration_number },
    });
    if (existingReg) {
      return res.status(409).json({ error: 'Registration number already in use' });
    }

    // Send OTP to university email
    await sendOtp(university_email);

    return res.status(200).json({
      message: 'OTP sent to your university email',
      data: { full_name, department, registration_number, university_email, phone },
    });
  } catch (err) {
    console.error('Register error:', err);
    return res.status(500).json({ error: 'Server error' });
  }
};

// Step 2: Verify OTP
const verifyRegistrationOtp = async (req, res) => {
  try {
    const { phone_or_email, otp_code } = req.body;
    const valid = await verifyOtp(phone_or_email, otp_code);
    if (!valid) {
      return res.status(400).json({ error: 'Invalid or expired OTP' });
    }
    return res.status(200).json({ message: 'OTP verified successfully' });
  } catch (err) {
    console.error('OTP verify error:', err);
    return res.status(500).json({ error: 'Server error' });
  }
};

// Step 3: Set username & password to complete registration
const completeRegistration = async (req, res) => {
  try {
    const {
      full_name,
      department,
      registration_number,
      university_email,
      phone,
      username,
      password,
    } = req.body;

    const existingUsername = await User.findOne({ where: { username } });
    if (existingUsername) {
      return res.status(409).json({ error: 'Username already taken' });
    }

    const password_hash = await bcrypt.hash(password, 12);

    const user = await User.create({
      full_name,
      department,
      registration_number,
      university_email,
      phone,
      username,
      password_hash,
      role: 'student',
    });

    const token = jwt.sign(
      { id: user.id, role: user.role },
      process.env.JWT_SECRET,
      { expiresIn: process.env.JWT_EXPIRE || '7d' }
    );

    return res.status(201).json({
      message: 'Registration complete',
      token,
      user: {
        id: user.id,
        full_name: user.full_name,
        username: user.username,
        role: user.role,
      },
    });
  } catch (err) {
    console.error('Complete registration error:', err);
    return res.status(500).json({ error: 'Server error' });
  }
};

// Login
const login = async (req, res) => {
  try {
    const { username, password } = req.body;
    const user = await User.findOne({ where: { username } });
    if (!user) {
      return res.status(401).json({ error: 'Invalid credentials' });
    }

    const match = await bcrypt.compare(password, user.password_hash);
    if (!match) {
      return res.status(401).json({ error: 'Invalid credentials' });
    }

    const token = jwt.sign(
      { id: user.id, role: user.role },
      process.env.JWT_SECRET,
      { expiresIn: process.env.JWT_EXPIRE || '7d' }
    );

    return res.json({
      token,
      user: {
        id: user.id,
        full_name: user.full_name,
        username: user.username,
        role: user.role,
        department: user.department,
      },
    });
  } catch (err) {
    console.error('Login error:', err);
    return res.status(500).json({ error: 'Server error' });
  }
};

// Get current user profile
const getProfile = async (req, res) => {
  return res.json({ user: req.user });
};

// Request password reset OTP
const requestPasswordReset = async (req, res) => {
  try {
    const { university_email } = req.body;
    const user = await User.findOne({ where: { university_email } });
    if (!user) {
      return res.status(404).json({ error: 'User not found' });
    }
    await sendOtp(university_email);
    return res.json({ message: 'OTP sent for password reset' });
  } catch (err) {
    console.error('Password reset request error:', err);
    return res.status(500).json({ error: 'Server error' });
  }
};

// Reset password after OTP verification
const resetPassword = async (req, res) => {
  try {
    const { university_email, otp_code, new_password } = req.body;
    const valid = await verifyOtp(university_email, otp_code);
    if (!valid) {
      return res.status(400).json({ error: 'Invalid or expired OTP' });
    }
    const user = await User.findOne({ where: { university_email } });
    if (!user) {
      return res.status(404).json({ error: 'User not found' });
    }
    user.password_hash = await bcrypt.hash(new_password, 12);
    await user.save();
    return res.json({ message: 'Password reset successful' });
  } catch (err) {
    console.error('Reset password error:', err);
    return res.status(500).json({ error: 'Server error' });
  }
};

// Get departments list
const getDepartments = (_req, res) => {
  return res.json({ departments: DEPARTMENTS });
};

module.exports = {
  register,
  verifyRegistrationOtp,
  completeRegistration,
  login,
  getProfile,
  requestPasswordReset,
  resetPassword,
  getDepartments,
};
