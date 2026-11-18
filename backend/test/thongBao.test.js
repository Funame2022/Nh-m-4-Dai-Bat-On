const { test, before, after, beforeEach } = require('node:test');
const assert = require('node:assert/strict');
const express = require('express');
const http = require('node:http');
const jwt = require('jsonwebtoken');

process.env.JWT_SECRET = 'khoa-thu-nghiem';

const hienTai = { truyVan: async () => ({ rows: [] }) };
const duongDanDb = require.resolve('../src/db');
require.cache[duongDanDb] = {
  id: duongDanDb,
  filename: duongDanDb,
  loaded: true,
  exports: {
    truyVan: (...args) => hienTai.truyVan(...args),
    trongGiaoDich: (callback) => callback({
      query: (...args) => hienTai.truyVan(...args),
    }),
  },
};

const vanHanhRouter = require('../src/routes/vanHanh');
const thongBaoRouter = require('../src/routes/thongBao');
const trangThai = {};
let server;
let baseUrl;

before(async () => {
  const app = express();
  app.use(express.json());
  app.use('/api/van-hanh', vanHanhRouter);
  app.use('/api/phu-huynh', thongBaoRouter);
  server = http.createServer(app);
  await new Promise((resolve, reject) => {
    server.listen(0, '127.0.0.1', resolve);
    server.on('error', reject);
  });
  baseUrl = `http://127.0.0.1:${server.address().port}`;
});

after(async () => {
  await new Promise((resolve) => server.close(resolve));
});

beforeEach(() => {
  trangThai.notifications = [];
  trangThai.dedupe = new Set();
  trangThai.attendance = new Map();
  trangThai.preferences = new Map();
  trangThai.recipients = [
    { phu_huynh_id: 3, hoc_sinh_id: 9, ho_ten: 'An Nguyễn', ten_tuyen: 'Tuyến 1' },
  ];

  hienTai.truyVan = async (sql, params = []) => {
    if (/SELECT DISTINCT phhs\.phu_huynh_id/.test(sql)) {
      const event = params[2];
      if (trangThai.preferences.get(`3:${event}`) === false) return { rows: [] };
      if (event === 'TRIP_COMPLETED' && !trangThai.attendance.has('7:9:XUONG_XE')) {
        return { rows: [] };
      }
      return { rows: trangThai.recipients };
    }
    if (/INSERT INTO thong_bao \(/.test(sql)) {
      const [recipient, student, trip, event, title, body, key] = params;
      if (trangThai.dedupe.has(key)) return { rows: [], rowCount: 0 };
      trangThai.dedupe.add(key);
      trangThai.notifications.push({
        id: trangThai.notifications.length + 1,
        nguoi_nhan_id: recipient,
        hoc_sinh_id: student,
        chuyen_di_id: trip,
        loai_su_kien: event,
        tieu_de: title,
        noi_dung: body,
        tao_luc: '2026-11-18T07:00:00.000Z',
        da_doc_luc: null,
      });
      return { rows: [], rowCount: 1 };
    }
    if (/UPDATE chuyen_di SET trang_thai = 'DANG_CHAY'/.test(sql)) {
      return { rows: [{ id: Number(params[0]), trang_thai: 'DANG_CHAY' }] };
    }
    if (/SELECT hs\.ho_ten/.test(sql)) return { rows: [] };
    if (/UPDATE chuyen_di SET trang_thai = 'HOAN_THANH'/.test(sql)) {
      return { rows: [{ id: Number(params[0]), trang_thai: 'HOAN_THANH' }] };
    }
    if (/SELECT 1 FROM chuyen_di cd\s+JOIN tuyen/.test(sql)) {
      return { rows: [{ '?column?': 1 }] };
    }
    if (/FROM chuyen_di cd/.test(sql) && /JOIN dang_ky_tuyen dk/.test(sql)) {
      return { rows: [{ id: 1 }] };
    }
    if (/INSERT INTO diem_danh/.test(sql)) {
      const [trip, student, stop, event] = params;
      const key = `${trip}:${student}:${event}`;
      if (trangThai.attendance.has(key)) return { rows: [] };
      const row = {
        id: trangThai.attendance.size + 1,
        chuyen_di_id: trip,
        hoc_sinh_id: student,
        diem_dung_id: stop,
        su_kien: event,
      };
      trangThai.attendance.set(key, row);
      return { rows: [row] };
    }
    if (/UPDATE diem_danh SET thoi_diem/.test(sql)) {
      const row = trangThai.attendance.get(`${params[0]}:${params[1]}:${params[2]}`);
      return { rows: row ? [row] : [] };
    }
    if (/FROM thong_bao_cai_dat WHERE nguoi_dung_id/.test(sql)) {
      return {
        rows: [...trangThai.preferences.entries()]
          .filter(([key]) => key.startsWith(`${params[0]}:`))
          .map(([key, bat]) => ({ loai_su_kien: key.slice(String(params[0]).length + 1), bat })),
      };
    }
    if (/INSERT INTO thong_bao_cai_dat/.test(sql)) {
      const [user, event, enabled] = params;
      trangThai.preferences.set(`${user}:${event}`, enabled);
      return { rows: [], rowCount: 1 };
    }
    if (/SELECT COUNT\(\*\)::INTEGER AS so_chua_doc/.test(sql)) {
      return {
        rows: [{
          so_chua_doc: trangThai.notifications.filter(
            (item) => item.nguoi_nhan_id === params[0] && item.da_doc_luc == null,
          ).length,
        }],
      };
    }
    if (/ORDER BY id DESC/.test(sql) && /FROM thong_bao/.test(sql)) {
      const [user, before, limit] = params;
      const rows = trangThai.notifications
        .filter((item) => item.nguoi_nhan_id === user && (before == null || item.id < before))
        .sort((a, b) => b.id - a.id)
        .slice(0, limit);
      return { rows };
    }
    if (/UPDATE thong_bao SET da_doc_luc = COALESCE/.test(sql)) {
      const [id, user] = params;
      const row = trangThai.notifications.find(
        (item) => item.id === Number(id) && item.nguoi_nhan_id === user,
      );
      if (!row) return { rows: [] };
      row.da_doc_luc ??= '2026-11-18T07:05:00.000Z';
      return { rows: [{ id: row.id, da_doc_luc: row.da_doc_luc }] };
    }
    if (/UPDATE thong_bao SET da_doc_luc = NOW\(\)/.test(sql)) {
      const items = trangThai.notifications.filter(
        (item) => item.nguoi_nhan_id === params[0] && item.da_doc_luc == null,
      );
      for (const item of items) item.da_doc_luc = '2026-11-18T07:05:00.000Z';
      return { rows: [], rowCount: items.length };
    }
    return { rows: [] };
  };
});

function token(id, role) {
  return jwt.sign({ id, vaiTro: role }, process.env.JWT_SECRET, { expiresIn: '1h' });
}

async function call(path, { method = 'GET', role = 'PHU_HUYNH', userId = 3, body } = {}) {
  const response = await fetch(`${baseUrl}${path}`, {
    method,
    headers: {
      Authorization: `Bearer ${token(userId, role)}`,
      ...(body === undefined ? {} : { 'Content-Type': 'application/json' }),
    },
    ...(body === undefined ? {} : { body: JSON.stringify(body) }),
  });
  return { status: response.status, body: await response.json().catch(() => null) };
}

test('bắt đầu chuyến tạo thông báo một lần cho phụ huynh của học sinh được phân công', async () => {
  const first = await call('/api/van-hanh/chuyen/7/bat-dau', { method: 'POST', role: 'QUAN_LY' });
  const second = await call('/api/van-hanh/chuyen/7/bat-dau', { method: 'POST', role: 'QUAN_LY' });

  assert.equal(first.status, 200);
  assert.equal(second.status, 200);
  assert.equal(trangThai.notifications.length, 1);
  assert.equal(trangThai.notifications[0].loai_su_kien, 'TRIP_STARTED');
  assert.match(trangThai.notifications[0].noi_dung, /Tuyến 1/);
});

test('điểm danh lên/xuống tạo sự kiện đúng loại và sự kiện hoàn tất chỉ tới học sinh đã xuống xe', async () => {
  for (const suKien of ['LEN_XE', 'XUONG_XE']) {
    const result = await call('/api/van-hanh/chuyen/7/diem-danh', {
      method: 'POST',
      role: 'TAI_XE',
      userId: 5,
      body: { hocSinhId: 9, diemDungId: 2, suKien },
    });
    assert.equal(result.status, 201);
  }
  const duplicate = await call('/api/van-hanh/chuyen/7/diem-danh', {
    method: 'POST',
    role: 'TAI_XE',
    userId: 5,
    body: { hocSinhId: 9, diemDungId: 2, suKien: 'LEN_XE' },
  });
  assert.equal(duplicate.status, 201);
  assert.equal(trangThai.notifications.filter((item) => item.loai_su_kien === 'STUDENT_BOARDED').length, 1);
  assert.equal(trangThai.notifications.filter((item) => item.loai_su_kien === 'STUDENT_DROPPED_OFF').length, 1);

  const completed = await call('/api/van-hanh/chuyen/7/ket-thuc', {
    method: 'POST',
    role: 'QUAN_LY',
  });
  assert.equal(completed.status, 200);
  assert.equal(trangThai.notifications.filter((item) => item.loai_su_kien === 'TRIP_COMPLETED').length, 1);
});

test('cài đặt phụ huynh bật tắt từng loại; loại đã tắt không phát sinh thông báo mới', async () => {
  const defaults = await call('/api/phu-huynh/thong-bao/cai-dat');
  assert.equal(defaults.status, 200);
  assert.equal(defaults.body.preferences.STUDENT_BOARDED, true);

  const saved = await call('/api/phu-huynh/thong-bao/cai-dat', {
    method: 'PUT',
    body: { preferences: { STUDENT_BOARDED: false } },
  });
  assert.equal(saved.status, 200);
  assert.equal(saved.body.preferences.STUDENT_BOARDED, false);

  await call('/api/van-hanh/chuyen/7/diem-danh', {
    method: 'POST',
    role: 'TAI_XE',
    userId: 5,
    body: { hocSinhId: 9, diemDungId: 2, suKien: 'LEN_XE' },
  });
  assert.equal(trangThai.notifications.length, 0);
});

test('hộp thư chỉ trả dữ liệu của người nhận; đánh dấu đã đọc giới hạn theo chủ sở hữu', async () => {
  await call('/api/van-hanh/chuyen/7/bat-dau', { method: 'POST', role: 'QUAN_LY' });

  const inbox = await call('/api/phu-huynh/thong-bao?limit=50');
  assert.equal(inbox.status, 200);
  assert.equal(inbox.body.notifications.length, 1);
  assert.equal(inbox.body.unreadCount, 1);

  const forbiddenRead = await call('/api/phu-huynh/thong-bao/1/doc', {
    method: 'PATCH',
    userId: 4,
  });
  assert.equal(forbiddenRead.status, 404);
  assert.equal(trangThai.notifications[0].da_doc_luc, null);

  const read = await call('/api/phu-huynh/thong-bao/1/doc', { method: 'PATCH' });
  assert.equal(read.status, 200);
  assert.notEqual(trangThai.notifications[0].da_doc_luc, null);

  const afterRead = await call('/api/phu-huynh/thong-bao?limit=50');
  assert.equal(afterRead.body.unreadCount, 0);
});

test('tùy chọn và truy cập hộp thư kiểm tra dữ liệu đầu vào và vai trò', async () => {
  const invalid = await call('/api/phu-huynh/thong-bao/cai-dat', {
    method: 'PUT',
    body: { preferences: { UNKNOWN: true } },
  });
  assert.equal(invalid.status, 400);

  const denied = await call('/api/phu-huynh/thong-bao', { role: 'TAI_XE', userId: 5 });
  assert.equal(denied.status, 403);
});
