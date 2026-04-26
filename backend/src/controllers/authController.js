const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const { User } = require('../models');
const {
  sendOtp,
  verifyOtp,
  hasVerifiedOtp,
  consumeVerifiedOtp,
  normalizeContact,
} = require('../services/otpService');
const DEPARTMENTS = require('../utils/departments');

const issueAuthToken = (user) => {
  if (!process.env.JWT_SECRET) {
    throw new Error('JWT_SECRET is not configured');
  }

  return jwt.sign(
    { id: user.id, role: user.role },
    process.env.JWT_SECRET,
    { expiresIn: process.env.JWT_EXPIRE || '7d' }
  );
};

// Step 1: Register — collect info & send OTP
const register = async (req, res) => {
  try {
    const { full_name, department, registration_number, university_email, phone } = req.body;
    const normalizedEmail = normalizeContact(university_email);

    if (!DEPARTMENTS.includes(department)) {
      return res.status(400).json({ error: 'Invalid department selected' });
    }

    const existing = await User.findOne({
      where: { university_email: normalizedEmail },
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
    await sendOtp(normalizedEmail);

    return res.status(200).json({
      message: 'OTP sent to your university email',
      data: { full_name, department, registration_number, university_email: normalizedEmail, phone },
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
    const normalizedContact = normalizeContact(phone_or_email);
    const valid = await verifyOtp(normalizedContact, otp_code);
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
    const normalizedEmail = normalizeContact(university_email);

    const verified = await hasVerifiedOtp(normalizedEmail);
    if (!verified) {
      return res.status(400).json({ error: 'Verify OTP before completing registration' });
    }

    const existingUsername = await User.findOne({ where: { username } });
    if (existingUsername) {
      return res.status(409).json({ error: 'Username already taken' });
    }

    const existingEmail = await User.findOne({ where: { university_email: normalizedEmail } });
    if (existingEmail) {
      return res.status(409).json({ error: 'Email already registered' });
    }

    const existingReg = await User.findOne({ where: { registration_number } });
    if (existingReg) {
      return res.status(409).json({ error: 'Registration number already in use' });
    }

    const password_hash = await bcrypt.hash(password, 12);

    const user = await User.create({
      full_name,
      department,
      registration_number,
      university_email: normalizedEmail,
      phone,
      username,
      password_hash,
      role: 'student',
    });

    await consumeVerifiedOtp(normalizedEmail);

    const token = issueAuthToken(user);

    return res.status(201).json({
      message: 'Registration complete',
      token,
      user: {
        id: user.id,
        full_name: user.full_name,
        department: user.department,
        registration_number: user.registration_number,
        university_email: user.university_email,
        phone: user.phone,
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

    const token = issueAuthToken(user);

    return res.json({
      token,
      user: {
        id: user.id,
        full_name: user.full_name,
        registration_number: user.registration_number,
        university_email: user.university_email,
        phone: user.phone,
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
    const normalizedEmail = normalizeContact(university_email);
    const user = await User.findOne({ where: { university_email: normalizedEmail } });
    if (!user) {
      return res.status(404).json({ error: 'User not found' });
    }
    await sendOtp(normalizedEmail);
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
    const normalizedEmail = normalizeContact(university_email);

    // Supports both flows:
    // 1) verify OTP first, then reset
    // 2) directly reset with OTP
    const alreadyVerified = await hasVerifiedOtp(normalizedEmail, otp_code);
    if (!alreadyVerified) {
      const valid = await verifyOtp(normalizedEmail, otp_code);
      if (!valid) {
        return res.status(400).json({ error: 'Invalid or expired OTP' });
      }
    }

    const user = await User.findOne({ where: { university_email: normalizedEmail } });
    if (!user) {
      return res.status(404).json({ error: 'User not found' });
    }

    user.password_hash = await bcrypt.hash(new_password, 12);
    await user.save();

    await consumeVerifiedOtp(normalizedEmail, otp_code);

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
