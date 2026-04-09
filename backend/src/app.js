require('dotenv').config();
const express = require('express');
const cors = require('cors');
const path = require('path');
const { sequelize } = require('./models');

const app = express();
const authOnlyMode = String(process.env.AUTH_ONLY || 'false').toLowerCase() === 'true';

// ── Middleware ──
app.use(cors({ origin: process.env.CORS_ORIGIN || '*' }));
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// Serve uploaded files
app.use('/uploads', express.static(path.join(__dirname, '..', 'uploads')));

// ── Routes ──
app.use('/auth', require('./routes/auth'));
if (!authOnlyMode) {
  app.use('/emergency', require('./routes/emergency'));
  app.use('/complaints', require('./routes/complaints'));
  app.use('/public-alerts', require('./routes/publicAlerts'));
  app.use('/notifications', require('./routes/notifications'));
  app.use('/admin', require('./routes/admin'));
}

// Health check
app.get('/', (_req, res) => res.json({ status: 'DU Alert API running' }));
app.get('/health', (_req, res) => {
  res.json({ status: 'ok', mode: authOnlyMode ? 'auth-only' : 'full-api' });
});

// ── Error handler ──
app.use((err, _req, res, _next) => {
  console.error(err);
  if (err.name === 'MulterError') {
    return res.status(400).json({ error: err.message });
  }
  return res.status(500).json({ error: 'Internal server error' });
});

// ── Start ──
const PORT = process.env.APP_PORT || 3000;

sequelize
  .sync({ alter: process.env.NODE_ENV === 'development' })
  .then(() => {
    console.log('Database synced');
    app.listen(PORT, () => console.log(`Server running on port ${PORT}`));
  })
  .catch((err) => {
    console.error('Database connection failed:', err);
    process.exit(1);
  });
