const { test, before, after, beforeEach } = require('node:test');
const assert = require('node:assert/strict');
const bcrypt = require('bcryptjs');
const express = require('express');
const jwt = require('jsonwebtoken');

process.env.JWT_SECRET = 'khoa-thu-nghiem';

const hienTai = { truyVan: async () => ({ rows: [] }) };
const fakeDb = { truyVan: (sql, params) => hienTai.truyVan(sql, params) };
const duongDanDb = require.resolve('../src/db');
require.cache[duongDanDb] = {
  id: duongDanDb,
  filename: duongDanDb,
  loaded: true,
  exports: fakeDb,
};

const authRouter = require('../src/routes/auth');
const TOKEN = jwt.sign({ id: 4, vaiTro: 'QUAN_LY' }, process.env.JWT_SECRET);
const matKhauCu = 'MatKhauCu123!';
let hashCu;
let server;
let baseUrl;

before(async () => {
  hashCu = await bcrypt.hash(matKhauCu, 4);
  const app = express();
  app.use(express.json());
  app.use('/api/auth', authRouter);
  await new Promise((resolve, reject) => {
    server = app.listen(0, '127.0.0.1', resolve);
    server.on('error', reject);
  });
  baseUrl = `http://127.0.0.1:${server.address().port}`;
});

after(async () => {
  await new Promise((resolve) => server.close(resolve));
});

beforeEach(() => {
  hienTai.truyVan = async () => ({ rows: [] });
});

async function goi(duongDan, body) {
  const response = await fetch(baseUrl + duongDan, {
    method: 'PATCH',
    headers: {
      Authorization: `Bearer ${TOKEN}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify(body),
  });
  return { status: response.status, body: await response.json() };
}

test('PATCH /toi giới hạn tên và không gọi dữ liệu với input sai', async () => {
  let soLanGoiDb = 0;
  hienTai.truyVan = async () => {
    soLanGoiDb += 1;
    return { rows: [] };
  };

  for (const hoTen of ['', ' '.repeat(3), 'x'.repeat(121)]) {
    const ketQua = await goi('/api/auth/toi', { hoTen });
    assert.equal(ketQua.status, 400);
  }
  assert.equal(soLanGoiDb, 0);
});

test('PATCH /toi lưu tên đã chuẩn hóa và chỉ trả thông tin hồ sơ', async () => {
  let truyVanGoi;
  hienTai.truyVan = async (sql, params) => {
    truyVanGoi = { sql, params };
    return {
      rows: [{ id: 4, email: 'admin@example.com', ho_ten: 'Quản trị viên', vai_tro: 'QUAN_LY' }],
    };
  };

  const ketQua = await goi('/api/auth/toi', { hoTen: '  Quản trị viên  ' });

  assert.equal(ketQua.status, 200);
  assert.deepEqual(truyVanGoi.params, ['Quản trị viên', 4]);
  assert.match(truyVanGoi.sql, /UPDATE nguoi_dung SET ho_ten/);
  assert.equal(ketQua.body.ho_ten, 'Quản trị viên');
  assert.equal(ketQua.body.mat_khau_hash, undefined);
});

test('PATCH /mat-khau từ chối mật khẩu hiện tại sai', async () => {
  const cacLenh = [];
  hienTai.truyVan = async (sql) => {
    cacLenh.push(sql);
    return { rows: [{ mat_khau_hash: hashCu }] };
  };

  const ketQua = await goi('/api/auth/mat-khau', {
    matKhauHienTai: 'khong-dung',
    matKhauMoi: 'MatKhauMoi123!',
  });

  assert.equal(ketQua.status, 400);
  assert.match(ketQua.body.loi, /không đúng/);
  assert.equal(cacLenh.length, 1);
});

test('PATCH /mat-khau kiểm tra mật khẩu mới và chỉ lưu hash sau khi xác minh', async () => {
  const cacLenh = [];
  hienTai.truyVan = async (sql, params) => {
    cacLenh.push({ sql, params });
    return /SELECT mat_khau_hash/.test(sql)
      ? { rows: [{ mat_khau_hash: hashCu }] }
      : { rows: [] };
  };

  const inputSai = await goi('/api/auth/mat-khau', {
    matKhauHienTai: matKhauCu,
    matKhauMoi: 'ngan',
  });
  assert.equal(inputSai.status, 400);
  assert.equal(cacLenh.length, 0);

  const ketQua = await goi('/api/auth/mat-khau', {
    matKhauHienTai: matKhauCu,
    matKhauMoi: 'MatKhauMoi123!',
  });

  assert.equal(ketQua.status, 200);
  assert.equal(cacLenh.length, 2);
  assert.match(cacLenh[1].sql, /UPDATE nguoi_dung SET mat_khau_hash/);
  assert.equal(cacLenh[1].params[1], 4);
  assert.notEqual(cacLenh[1].params[0], 'MatKhauMoi123!');
  assert.equal(await bcrypt.compare('MatKhauMoi123!', cacLenh[1].params[0]), true);
});
