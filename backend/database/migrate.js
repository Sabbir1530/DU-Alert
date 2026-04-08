const fs = require('fs/promises');
const path = require('path');
const { Client } = require('pg');
require('dotenv').config({ path: path.resolve(__dirname, '..', '.env') });

const DB_HOST = process.env.DB_HOST || 'localhost';
const DB_PORT = Number(process.env.DB_PORT || 5432);
const DB_USER = process.env.DB_USER;
const DB_PASSWORD = process.env.DB_PASSWORD || process.env.DB_PASS;
const DB_NAME = process.env.DB_NAME || 'dualert';
const POSTGRES_DB = process.env.POSTGRES_DB || 'postgres';

if (!DB_USER) {
  console.error('Missing DB_USER in .env');
  process.exit(1);
}

if (!DB_PASSWORD) {
  console.error('Missing DB_PASSWORD (or DB_PASS) in .env');
  process.exit(1);
}

function quoteIdentifier(identifier) {
  return `"${String(identifier).replace(/"/g, '""')}"`;
}

async function createAdminClient() {
  const client = new Client({
    host: DB_HOST,
    port: DB_PORT,
    user: DB_USER,
    password: DB_PASSWORD,
    database: POSTGRES_DB,
  });
  await client.connect();
  return client;
}

async function createAppClient() {
  const client = new Client({
    host: DB_HOST,
    port: DB_PORT,
    user: DB_USER,
    password: DB_PASSWORD,
    database: DB_NAME,
  });
  await client.connect();
  return client;
}

async function ensureDatabaseExists() {
  const admin = await createAdminClient();
  try {
    const result = await admin.query('SELECT 1 FROM pg_database WHERE datname = $1', [DB_NAME]);
    if (result.rowCount === 0) {
      await admin.query(`CREATE DATABASE ${quoteIdentifier(DB_NAME)}`);
      console.log(`Created database: ${DB_NAME}`);
    } else {
      console.log(`Database already exists: ${DB_NAME}`);
    }
  } finally {
    await admin.end();
  }
}

async function runSqlFile(client, fileName) {
  const filePath = path.join(__dirname, fileName);
  const sql = await fs.readFile(filePath, 'utf8');
  await client.query(sql);
  console.log(`Executed ${fileName}`);
}

async function runMigrate() {
  await ensureDatabaseExists();
  const app = await createAppClient();
  try {
    await app.query('BEGIN');
    await runSqlFile(app, 'schema.sql');
    await app.query('COMMIT');
    console.log('Migration completed successfully.');
  } catch (err) {
    await app.query('ROLLBACK');
    console.error('Migration failed:', err.message);
    process.exitCode = 1;
  } finally {
    await app.end();
  }
}

async function runSeed() {
  await ensureDatabaseExists();
  const app = await createAppClient();
  try {
    await app.query('BEGIN');
    await runSqlFile(app, 'seed.sql');
    await app.query('COMMIT');
    console.log('Seed completed successfully.');
  } catch (err) {
    await app.query('ROLLBACK');
    console.error('Seed failed:', err.message);
    process.exitCode = 1;
  } finally {
    await app.end();
  }
}

async function runReset() {
  await ensureDatabaseExists();
  const app = await createAppClient();
  try {
    await app.query('BEGIN');
    await app.query('DROP SCHEMA IF EXISTS public CASCADE;');
    await app.query('CREATE SCHEMA public;');
    await app.query('COMMIT');
    console.log('Database reset completed successfully.');
  } catch (err) {
    await app.query('ROLLBACK');
    console.error('Reset failed:', err.message);
    process.exitCode = 1;
  } finally {
    await app.end();
  }
}

async function main() {
  const action = (process.argv[2] || 'migrate').toLowerCase();

  if (action === 'migrate') {
    await runMigrate();
    return;
  }

  if (action === 'seed') {
    await runSeed();
    return;
  }

  if (action === 'reset') {
    await runReset();
    return;
  }

  if (action === 'all') {
    await runReset();
    if (process.exitCode) return;
    await runMigrate();
    if (process.exitCode) return;
    await runSeed();
    return;
  }

  console.error('Invalid action. Use one of: migrate | seed | reset | all');
  process.exit(1);
}

main().catch((err) => {
  console.error('Unexpected migration error:', err.message);
  process.exit(1);
});
