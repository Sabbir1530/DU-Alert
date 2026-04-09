const router = require('express').Router();
const authenticate = require('../middleware/auth');
const roleGuard = require('../middleware/roleGuard');
const upload = require('../middleware/upload');
const { complaintRules, handleValidation } = require('../middleware/validate');
const ctrl = require('../controllers/complaintController');

router.post('/', authenticate, upload.array('media', 5), complaintRules, handleValidation, ctrl.createComplaint);
router.get('/my', authenticate, ctrl.getMyComplaints);
router.get('/:id', authenticate, ctrl.getComplaintById);
router.get('/', authenticate, roleGuard('proctor', 'admin'), ctrl.getAllComplaints);
router.patch('/:id/status', authenticate, roleGuard('proctor', 'admin'), ctrl.updateComplaintStatus);

module.exports = router;
