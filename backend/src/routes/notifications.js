const router = require('express').Router();
const authenticate = require('../middleware/auth');
const roleGuard = require('../middleware/roleGuard');
const ctrl = require('../controllers/notificationController');

router.get('/', authenticate, ctrl.getNotifications);
router.post('/', authenticate, roleGuard('admin'), ctrl.createAnnouncement);
router.patch('/:id/read', authenticate, ctrl.markRead);
router.post('/mark-all-read', authenticate, ctrl.markAllRead);

module.exports = router;
