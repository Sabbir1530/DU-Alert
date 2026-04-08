require('dotenv').config();
const express = require('express');
const { pool, testDbConnection } = require('./config/db');

const app = express();
const PORT = Number(process.env.APP_PORT || 3000);

app.use(express.json());

app.get('/health', async (_req, res) => {
  try {
    const result = await pool.query('SELECT NOW() AS db_time');
    return res.status(200).json({
      status: 'ok',
      service: 'du-alert-backend',
      dbTime: result.rows[0].db_time,
    });
  } catch (err) {
    return res.status(500).json({
      status: 'error',
      message: 'Database check failed',
      error: err.message,
    });
  }
});

app.get('/', (_req, res) => {
  res.json({ message: 'DU Alert backend is running' });
});

async function startServer() {
  try {
    await testDbConnection();
    app.listen(PORT, () => {
      console.log(`Server running on port ${PORT}`);
    });
  } catch (err) {
    console.error('Failed to connect to PostgreSQL:', err.message);
    process.exit(1);
  }
}

async function shutdown() {
  try {
    await pool.end();
    process.exit(0);
  } catch (err) {
    console.error('Error while closing DB pool:', err.message);
    process.exit(1);
  }
}

process.on('SIGINT', shutdown);
process.on('SIGTERM', shutdown);

startServer();
