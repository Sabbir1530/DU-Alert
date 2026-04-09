const router = require('express').Router();
const authenticate = require('../middleware/auth');
const roleGuard = require('../middleware/roleGuard');
const ctrl = require('../controllers/notificationController');

router.get('/', authenticate, ctrl.getNotifications);
router.post('/', authenticate, roleGuard('admin'), ctrl.createAnnouncement);

module.exports = router;
