require('dotenv').config({
  path: "./.env"
});
const express = require('express');
const cors = require('cors');
const path = require('path');
const { sequelize } = require('./src/models');

const app = express();
const authOnlyMode = String(process.env.AUTH_ONLY || 'false').toLowerCase() === 'true';

// ── Middleware ──
app.use(cors({ origin: process.env.CORS_ORIGIN || '*' }));
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// Serve uploaded files
app.use('/uploads', express.static(path.join(__dirname, 'uploads')));

// ── Routes ──
app.use('/auth', require('./src/routes/auth'));
if (!authOnlyMode) {
  const complaintsRouter = require('./src/routes/complaints');
  app.use('/emergency', require('./src/routes/emergency'));
  app.use('/complaints', complaintsRouter);
  app.use('/api/complaints', complaintsRouter);
  app.use('/public-alerts', require('./src/routes/publicAlerts'));
  app.use('/alerts', require('./src/routes/alerts'));
  app.use('/comments', require('./src/routes/comments'));
  app.use('/notifications', require('./src/routes/notifications'));
  app.use('/admin', require('./src/routes/admin'));
}

// Health check
app.get('/', (_req, res) => res.json({ status: 'DU Alert API running' }));
app.get('/health', (_req, res) => {
  res.json({ status: 'ok', mode: authOnlyMode ? 'auth-only' : 'full-api' });
});

// ── Error handler ──
app.use((err, _req, res, _next) => {
  console.error(err);
  if (err.name === 'MulterError' || err.message === 'File type not allowed') {
    return res.status(400).json({ error: err.message });
  }
  return res.status(500).json({ error: 'Internal server error' });
});

// ── Start ──
const PORT = process.env.APP_PORT || 3000;

sequelize
  .sync({ alter: false })
  .then(async () => {
    await sequelize.query(
      'ALTER TABLE complaints ADD COLUMN IF NOT EXISTS summary_source_hash VARCHAR(64);'
    );
    await sequelize.query(
      "UPDATE complaints SET status = 'Resolved' WHERE LOWER(status::text) = 'managed';"
    );
    await sequelize.query(
      "UPDATE complaint_status_log SET status = 'Resolved' WHERE LOWER(status::text) = 'managed';"
    );
    await sequelize.query(
      'ALTER TABLE emergency_alerts ADD COLUMN IF NOT EXISTS acknowledged_by_user_id UUID;'
    );
    await sequelize.query(
      'ALTER TABLE emergency_alerts ADD COLUMN IF NOT EXISTS acknowledged_by_name VARCHAR(120);'
    );
    await sequelize.query(
      'ALTER TABLE emergency_alerts ADD COLUMN IF NOT EXISTS acknowledged_at TIMESTAMPTZ;'
    );
    await sequelize.query(
      'ALTER TABLE emergency_alerts ADD COLUMN IF NOT EXISTS responder_location JSONB;'
    );
    await sequelize.query(
      'ALTER TABLE emergency_alerts ADD COLUMN IF NOT EXISTS distance_in_km NUMERIC(8, 3);'
    );
    console.log('Database synced');
    app.listen(PORT, () => console.log(`Server running on port ${PORT}`));
  })
  .catch((err) => {
    console.error('Database connection failed:', err);
    process.exit(1);
  });
