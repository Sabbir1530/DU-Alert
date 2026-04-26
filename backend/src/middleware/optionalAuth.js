const jwt = require('jsonwebtoken');
const { User } = require('../models');

const optionalAuth = async (req, _res, next) => {
  const header = req.headers.authorization;
  if (!header || !header.startsWith('Bearer ')) {
    req.user = null;
    return next();
  }

  try {
    const token = header.split(' ')[1];
    const decoded = jwt.verify(token, process.env.JWT_SECRET);
    const user = await User.findByPk(decoded.id, {
      attributes: { exclude: ['password_hash'] },
    });
    req.user = user || null;
  } catch {
    req.user = null;
  }

  return next();
};

module.exports = optionalAuth;
