const router = require('express').Router();
const auth = require('../controllers/authController');
const {
  registerRules,
  otpVerifyRules,
  setPasswordRules,
  loginRules,
  requestPasswordResetRules,
  resetPasswordRules,
  handleValidation,
} = require('../middleware/validate');

router.post('/register', registerRules, handleValidation, auth.register);
router.post('/verify-otp', otpVerifyRules, handleValidation, auth.verifyRegistrationOtp);
router.post('/complete-registration', setPasswordRules, handleValidation, auth.completeRegistration);
router.post('/login', loginRules, handleValidation, auth.login);
router.post('/request-password-reset', requestPasswordResetRules, handleValidation, auth.requestPasswordReset);
router.post('/reset-password', resetPasswordRules, handleValidation, auth.resetPassword);
router.get('/departments', auth.getDepartments);

const authenticate = require('../middleware/auth');
router.get('/profile', authenticate, auth.getProfile);

module.exports = router;
