const router = require('express').Router();
const authenticate = require('../middleware/auth');
const roleGuard = require('../middleware/roleGuard');
const ctrl = require('../controllers/adminController');

router.get('/users', authenticate, roleGuard('admin'), ctrl.getUsers);
router.post('/proctors', authenticate, roleGuard('admin'), ctrl.createProctor);
router.delete('/users/:id', authenticate, roleGuard('admin'), ctrl.deleteUser);
router.get('/analytics', authenticate, roleGuard('admin', 'proctor'), ctrl.getAnalytics);

module.exports = router;
