const crypto = require('crypto');
const { OtpVerification } = require('../models');
const { sendEmail } = require('./emailService');

const normalizeContact = (phoneOrEmail) => {
  const value = String(phoneOrEmail || '').trim();
  if (!value) return '';
  return value.includes('@') ? value.toLowerCase() : value;
};

const generateOtp = () => {
  return crypto.randomInt(100000, 999999).toString();
};

const sendOtp = async (phoneOrEmail) => {
  const normalizedContact = normalizeContact(phoneOrEmail);
  if (!normalizedContact) {
    throw new Error('Phone or email is required to send OTP');
  }

  const otpCode = generateOtp();
  const expiresAt = new Date(Date.now() + 5 * 60 * 1000); // 5 minutes

  // Keep only one active OTP per contact.
  await OtpVerification.destroy({ where: { phone_or_email: normalizedContact } });

  await OtpVerification.create({
    phone_or_email: normalizedContact,
    otp_code: otpCode,
    expires_at: expiresAt,
  });

  // Send via email (for university email verification)
  if (normalizedContact.includes('@')) {
    await sendEmail(
      normalizedContact,
      'DU Alert - OTP Verification',
      `<h2>Your OTP Code</h2><p>Your verification code is: <strong>${otpCode}</strong></p><p>This code expires in 5 minutes.</p>`
    );
  }
  // For phone-based OTP, integrate an SMS gateway here.
  // For now, log it in development mode.
  if (process.env.NODE_ENV === 'development') {
    console.log(`[DEV] OTP for ${normalizedContact}: ${otpCode}`);
  }

  return true;
};

const verifyOtp = async (phoneOrEmail, otpCode) => {
  const normalizedContact = normalizeContact(phoneOrEmail);
  const normalizedOtp = String(otpCode || '').trim();
  if (!normalizedContact || !normalizedOtp) return false;

  const record = await OtpVerification.findOne({
    where: {
      phone_or_email: normalizedContact,
      otp_code: normalizedOtp,
      verified: false,
    },
    order: [['expires_at', 'DESC']],
  });

  if (!record) return false;
  if (new Date() > record.expires_at) return false;

  record.verified = true;
  await record.save();
  return true;
};

const hasVerifiedOtp = async (phoneOrEmail, otpCode) => {
  const normalizedContact = normalizeContact(phoneOrEmail);
  if (!normalizedContact) return false;

  const where = {
    phone_or_email: normalizedContact,
    verified: true,
  };

  if (otpCode !== undefined && otpCode !== null) {
    where.otp_code = String(otpCode).trim();
  }

  const record = await OtpVerification.findOne({
    where,
    order: [['expires_at', 'DESC']],
  });

  if (!record) return false;
  return new Date() <= record.expires_at;
};

const consumeVerifiedOtp = async (phoneOrEmail, otpCode) => {
  const normalizedContact = normalizeContact(phoneOrEmail);
  if (!normalizedContact) return false;

  const where = {
    phone_or_email: normalizedContact,
    verified: true,
  };

  if (otpCode !== undefined && otpCode !== null) {
    where.otp_code = String(otpCode).trim();
  }

  const record = await OtpVerification.findOne({
    where,
    order: [['expires_at', 'DESC']],
  });

  if (!record) return false;
  await record.destroy();
  return true;
};

module.exports = {
  sendOtp,
  verifyOtp,
  hasVerifiedOtp,
  consumeVerifiedOtp,
  normalizeContact,
};
