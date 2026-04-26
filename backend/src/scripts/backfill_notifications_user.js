const path = require('path');
const { Client } = require('pg');
require('dotenv').config({ path: path.resolve(__dirname, '..', '..', '.env') });

const DB_HOST = process.env.DB_HOST || 'localhost';
const DB_PORT = Number(process.env.DB_PORT || 5432);
const DB_USER = process.env.DB_USER;
const DB_PASSWORD = process.env.DB_PASSWORD || process.env.DB_PASS;
const DB_NAME = process.env.DB_NAME || 'dualertdb';

const userId = process.argv[2];
if (!userId) {
  console.error('Usage: node src/scripts/backfill_notifications_user.js <user-uuid>');
  process.exit(1);
}

async function main() {
  const client = new Client({
    host: DB_HOST,
    port: DB_PORT,
    user: DB_USER,
    password: DB_PASSWORD,
    database: DB_NAME,
  });

  await client.connect();
  try {
    await client.query('BEGIN');
    await client.query('ALTER TABLE notifications ADD COLUMN IF NOT EXISTS user_id UUID');
    await client.query(
      "ALTER TABLE notifications ADD COLUMN IF NOT EXISTS type VARCHAR(50)"
    );
    await client.query(
      "ALTER TABLE notifications ADD COLUMN IF NOT EXISTS reference_type VARCHAR(50)"
    );
    await client.query(
      "ALTER TABLE notifications ADD COLUMN IF NOT EXISTS reference_id UUID"
    );
    await client.query(
      "ALTER TABLE notifications ADD COLUMN IF NOT EXISTS reference_sub_id UUID"
    );
    await client.query(
      "ALTER TABLE notifications ADD COLUMN IF NOT EXISTS is_read BOOLEAN"
    );
    await client.query(
      "ALTER TABLE notifications ADD COLUMN IF NOT EXISTS data JSONB"
    );

    await client.query(
      "UPDATE notifications SET type = 'announcement' WHERE type IS NULL"
    );
    await client.query(
      "ALTER TABLE notifications DROP COLUMN IF EXISTS target_role"
    );
    await client.query(
      "UPDATE notifications SET is_read = false WHERE is_read IS NULL"
    );
    await client.query('UPDATE notifications SET user_id = $1 WHERE user_id IS NULL', [userId]);
    await client.query("ALTER TABLE notifications ALTER COLUMN type SET NOT NULL");
    await client.query("ALTER TABLE notifications ALTER COLUMN is_read SET NOT NULL");
    await client.query('ALTER TABLE notifications ALTER COLUMN user_id SET NOT NULL');
    await client.query(
      "ALTER TABLE notifications ADD CONSTRAINT notifications_user_id_fkey FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE"
    ).catch(() => {});
    await client.query('COMMIT');
    console.log('Backfill completed.');
  } catch (err) {
    await client.query('ROLLBACK');
    console.error('Backfill failed:', err.message);
    process.exitCode = 1;
  } finally {
    await client.end();
  }
}

main().catch((err) => {
  console.error('Unexpected error:', err.message);
  process.exit(1);
});
