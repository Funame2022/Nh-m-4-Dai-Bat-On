const { test } = require('node:test');
const assert = require('node:assert/strict');
const { apDungMigrations } = require('../src/migrations');

test('chạy mỗi migration một lần và giải phóng khóa khi chạy lặp', async () => {
  const daApDung = new Set();
  const cacSqlMigration = [];
  const cacKhoa = [];
  const client = {
    async query(sql, params = []) {
      if (sql.includes('pg_advisory_lock')) cacKhoa.push(`lock:${params[0]}`);
      if (sql.includes('pg_advisory_unlock')) cacKhoa.push(`unlock:${params[0]}`);
      if (sql.includes('SELECT 1 FROM schema_migrations')) {
        return { rows: daApDung.has(params[0]) ? [{ '?column?': 1 }] : [] };
      }
      if (sql.startsWith('CREATE TABLE IF NOT EXISTS thong_bao_cai_dat')) {
        cacSqlMigration.push(sql);
      }
      if (sql.includes('INSERT INTO schema_migrations')) daApDung.add(params[0]);
      return { rows: [] };
    },
    release() {},
  };
  const pool = { connect: async () => client };

  await apDungMigrations(pool);
  await apDungMigrations(pool);

  assert.equal(cacSqlMigration.length, 1);
  assert.equal(daApDung.size, 1);
  assert.equal(cacKhoa.length, 4);
  assert.equal(cacKhoa[0], 'lock:731082145');
  assert.equal(cacKhoa[3], 'unlock:731082145');
});
