const router = require('express').Router();
const auth = require('../controllers/authController');
const {
  registerRules,
  otpVerifyRules,
  setPasswordRules,
  loginRules,
  handleValidation,
} = require('../middleware/validate');

router.post('/register', registerRules, handleValidation, auth.register);
router.post('/verify-otp', otpVerifyRules, handleValidation, auth.verifyRegistrationOtp);
router.post('/complete-registration', setPasswordRules, handleValidation, auth.completeRegistration);
router.post('/login', loginRules, handleValidation, auth.login);
router.post('/request-password-reset', auth.requestPasswordReset);
router.post('/reset-password', auth.resetPassword);
router.get('/departments', auth.getDepartments);

const authenticate = require('../middleware/auth');
router.get('/profile', authenticate, auth.getProfile);

module.exports = router;
