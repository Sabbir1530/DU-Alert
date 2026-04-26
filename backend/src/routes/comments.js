const router = require('express').Router();
const authenticate = require('../middleware/auth');
const ctrl = require('../controllers/publicAlertController');

router.delete('/:id', authenticate, ctrl.deleteComment);

module.exports = router;
