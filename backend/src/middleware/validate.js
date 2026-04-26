const { body, validationResult } = require('express-validator');

const handleValidation = (req, res, next) => {
  const errors = validationResult(req);
  if (!errors.isEmpty()) {
    return res.status(400).json({ errors: errors.array() });
  }
  next();
};

const registerRules = [
  body('full_name').trim().notEmpty().withMessage('Full name is required'),
  body('university_email').trim().isEmail().withMessage('Valid university email required'),
  body('phone').trim().notEmpty().withMessage('Phone is required'),
  body('department').trim().notEmpty().withMessage('Department is required'),
  body('registration_number').trim().notEmpty().withMessage('Registration number is required'),
];

const otpVerifyRules = [
  body('phone_or_email').trim().notEmpty().withMessage('Phone or email is required'),
  body('otp_code').trim().isLength({ min: 6, max: 6 }).withMessage('OTP must be 6 digits'),
];

const setPasswordRules = [
  body('full_name').trim().notEmpty().withMessage('Full name is required'),
  body('department').trim().notEmpty().withMessage('Department is required'),
  body('registration_number').trim().notEmpty().withMessage('Registration number is required'),
  body('university_email').trim().isEmail().withMessage('Valid university email required'),
  body('phone').trim().notEmpty().withMessage('Phone is required'),
  body('username').trim().isLength({ min: 3 }).withMessage('Username must be at least 3 characters'),
  body('password').isLength({ min: 6 }).withMessage('Password must be at least 6 characters'),
];

const loginRules = [
  body('username').trim().notEmpty().withMessage('Username is required'),
  body('password').notEmpty().withMessage('Password is required'),
];

const requestPasswordResetRules = [
  body('university_email').trim().isEmail().withMessage('Valid university email required'),
];

const resetPasswordRules = [
  body('university_email').trim().isEmail().withMessage('Valid university email required'),
  body('otp_code').trim().isLength({ min: 6, max: 6 }).withMessage('OTP must be 6 digits'),
  body('new_password').isLength({ min: 6 }).withMessage('New password must be at least 6 characters'),
];

const emergencyRules = [
  body('latitude').isFloat({ min: -90, max: 90 }).withMessage('Valid latitude required'),
  body('longitude').isFloat({ min: -180, max: 180 }).withMessage('Valid longitude required'),
];

const complaintRules = [
  body('title')
    .optional({ checkFalsy: true })
    .trim()
    .isLength({ min: 3, max: 200 })
    .withMessage('Title must be between 3 and 200 characters'),
  body('category').notEmpty().withMessage('Category is required'),
  body('description').trim().notEmpty().withMessage('Description is required'),
];

const publicAlertRules = [
  body('title')
    .optional()
    .trim()
    .isLength({ min: 3, max: 200 })
    .withMessage('Title must be between 3 and 200 characters'),
  body('category').trim().notEmpty().withMessage('Category is required'),
  body('description').trim().notEmpty().withMessage('Description is required'),
  body('visibility')
    .optional()
    .isIn(['PUBLIC', 'PRIVATE'])
    .withMessage('visibility must be PUBLIC or PRIVATE'),
];

module.exports = {
  handleValidation,
  registerRules,
  otpVerifyRules,
  setPasswordRules,
  loginRules,
  requestPasswordResetRules,
  resetPasswordRules,
  emergencyRules,
  complaintRules,
  publicAlertRules,
};
