const router = require('express').Router();
const authenticate = require('../middleware/auth');
const roleGuard = require('../middleware/roleGuard');
const { emergencyRules, handleValidation } = require('../middleware/validate');
const ctrl = require('../controllers/emergencyController');

router.post('/', authenticate, emergencyRules, handleValidation, ctrl.createEmergency);
router.get('/my', authenticate, ctrl.getMyEmergencies);
router.get('/', authenticate, roleGuard('proctor', 'admin'), ctrl.getEmergencies);
router.patch('/:id', authenticate, roleGuard('proctor', 'admin'), ctrl.updateEmergencyStatus);

module.exports = router;
