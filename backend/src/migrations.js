const fs = require('node:fs/promises');
const path = require('node:path');

async function apDungMigrations(pool) {
  const client = await pool.connect();
  let daKhoa = false;
  try {
    await client.query('SELECT pg_advisory_lock($1)', [731082145]);
    daKhoa = true;
    await client.query(`
      CREATE TABLE IF NOT EXISTS schema_migrations (
        name TEXT PRIMARY KEY,
        applied_at TIMESTAMP NOT NULL DEFAULT NOW()
      )
    `);

    const thuMuc = path.resolve(__dirname, '../migrations');
    const cacTep = (await fs.readdir(thuMuc))
      .filter((ten) => /^\d+_[a-z0-9_]+\.sql$/.test(ten))
      .sort();

    for (const ten of cacTep) {
      await client.query('BEGIN');
      try {
        const daApDung = await client.query(
          'SELECT 1 FROM schema_migrations WHERE name = $1',
          [ten],
        );
        if (daApDung.rows.length === 0) {
          const sql = await fs.readFile(path.join(thuMuc, ten), 'utf8');
          await client.query(sql);
          await client.query('INSERT INTO schema_migrations (name) VALUES ($1)', [ten]);
        }
        await client.query('COMMIT');
      } catch (error) {
        await client.query('ROLLBACK');
        throw error;
      }
    }
  } finally {
    if (daKhoa) {
      try {
        await client.query('SELECT pg_advisory_unlock($1)', [731082145]);
      } catch (_) {
        client.release(true);
        throw new Error('Không thể giải phóng khóa cập nhật cơ sở dữ liệu');
      }
    }
    client.release();
  }
}

module.exports = { apDungMigrations };
