const crypto = require('crypto');
const { OtpVerification } = require('../models');
const { sendEmail } = require('./emailService');

const generateOtp = () => {
  return crypto.randomInt(100000, 999999).toString();
};

const sendOtp = async (phoneOrEmail) => {
  const otpCode = generateOtp();
  const expiresAt = new Date(Date.now() + 5 * 60 * 1000); // 5 minutes

  // Invalidate previous OTPs for this contact
  await OtpVerification.update(
    { verified: true },
    { where: { phone_or_email: phoneOrEmail, verified: false } }
  );

  await OtpVerification.create({
    phone_or_email: phoneOrEmail,
    otp_code: otpCode,
    expires_at: expiresAt,
  });

  // Send via email (for university email verification)
  if (phoneOrEmail.includes('@')) {
    await sendEmail(
      phoneOrEmail,
      'DU Alert - OTP Verification',
      `<h2>Your OTP Code</h2><p>Your verification code is: <strong>${otpCode}</strong></p><p>This code expires in 5 minutes.</p>`
    );
  }
  // For phone-based OTP, integrate an SMS gateway here.
  // For now, log it in development mode.
  if (process.env.NODE_ENV === 'development') {
    console.log(`[DEV] OTP for ${phoneOrEmail}: ${otpCode}`);
  }

  return true;
};

const verifyOtp = async (phoneOrEmail, otpCode) => {
  const record = await OtpVerification.findOne({
    where: {
      phone_or_email: phoneOrEmail,
      otp_code: otpCode,
      verified: false,
    },
  });

  if (!record) return false;
  if (new Date() > record.expires_at) return false;

  record.verified = true;
  await record.save();
  return true;
};

module.exports = { sendOtp, verifyOtp };
