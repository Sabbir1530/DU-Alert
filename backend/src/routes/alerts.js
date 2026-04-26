const router = require('express').Router();
const authenticate = require('../middleware/auth');
const optionalAuth = require('../middleware/optionalAuth');
const ctrl = require('../controllers/publicAlertController');

// Compatibility REST API for social feed consumers.
router.get('/public', optionalAuth, ctrl.getApprovedAlerts);
router.post('/:id/react', authenticate, ctrl.reactToAlert);
router.delete('/:id/react', authenticate, ctrl.removeReaction);
router.get('/:id/comments', optionalAuth, ctrl.getAlertComments);
router.post('/:id/comments', authenticate, ctrl.addComment);

module.exports = router;
