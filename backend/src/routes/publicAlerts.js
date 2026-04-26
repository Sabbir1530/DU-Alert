const router = require('express').Router();
const authenticate = require('../middleware/auth');
const optionalAuth = require('../middleware/optionalAuth');
const roleGuard = require('../middleware/roleGuard');
const upload = require('../middleware/upload');
const { publicAlertRules, handleValidation } = require('../middleware/validate');
const ctrl = require('../controllers/publicAlertController');

router.post('/', authenticate, upload.array('media', 5), publicAlertRules, handleValidation, ctrl.createPublicAlert);
router.get('/feed', optionalAuth, ctrl.getApprovedAlerts);
router.get('/:id/comments', optionalAuth, ctrl.getAlertComments);
router.get('/my', authenticate, ctrl.getMyAlerts);
router.get('/:id', authenticate, ctrl.getAlertById);
router.get('/', authenticate, roleGuard('admin', 'proctor'), ctrl.getAllAlerts);
router.patch('/:id/review', authenticate, roleGuard('admin', 'proctor'), ctrl.reviewAlert);
router.post('/:id/reactions', authenticate, ctrl.reactToAlert);
router.delete('/:id/reactions', authenticate, ctrl.removeReaction);
router.post('/:id/comments', authenticate, ctrl.addComment);
router.delete('/comments/:commentId', authenticate, ctrl.deleteComment);

module.exports = router;
