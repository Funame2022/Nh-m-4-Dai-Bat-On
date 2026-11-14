const { Pool } = require('pg');

const pool = new Pool({
  connectionString: process.env.DATABASE_URL,
  ssl: { rejectUnauthorized: false },
  max: 5,
});

const truyVan = (sql, params) => pool.query(sql, params);

async function trongGiaoDich(callback) {
  const client = await pool.connect();
  try {
    await client.query('BEGIN');
    const ketQua = await callback(client);
    await client.query('COMMIT');
    return ketQua;
  } catch (e) {
    await client.query('ROLLBACK');
    throw e;
  } finally {
    client.release();
  }
}

module.exports = { pool, truyVan, trongGiaoDich };
