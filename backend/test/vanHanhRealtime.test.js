const { test, before, after, beforeEach } = require('node:test');
const assert = require('node:assert/strict');
const express = require('express');
const http = require('node:http');
const jwt = require('jsonwebtoken');
const WebSocket = require('ws');

process.env.JWT_SECRET = 'khoa-thu-nghiem';

const hienTai = { truyVan: async () => ({ rows: [] }) };
const duongDanDb = require.resolve('../src/db');
require.cache[duongDanDb] = {
  id: duongDanDb,
  filename: duongDanDb,
  loaded: true,
  exports: {
    truyVan: (...args) => hienTai.truyVan(...args),
    pool: { end: async () => {} },
  },
};

const vanHanhRouter = require('../src/routes/vanHanh');
const { ganKenhGiamSat } = require('../src/giamSatSocket');

let server;
let kenh;
let baseUrl;

before(async () => {
  const app = express();
  app.use(express.json());
  app.use('/api/van-hanh', vanHanhRouter);
  server = http.createServer(app);
  kenh = ganKenhGiamSat(server);
  await new Promise((resolve, reject) => {
    server.listen(0, '127.0.0.1', resolve);
    server.on('error', reject);
  });
  baseUrl = `http://127.0.0.1:${server.address().port}`;
});

after(async () => {
  await kenh.dong();
  await new Promise((resolve) => server.close(resolve));
});

beforeEach(() => {
  hienTai.truyVan = async () => ({
    rows: [{
      id: 41,
      chuyen_di_id: 7,
      vi_do: 10.7725,
      kinh_do: 106.698,
      thoi_diem: '2026-11-17T10:20:00.000Z',
    }],
  });
});

function taoToken(vaiTro = 'QUAN_LY') {
  return jwt.sign({ id: 1, vaiTro }, process.env.JWT_SECRET, { expiresIn: '1h' });
}

function moSocket(token = taoToken()) {
  return new WebSocket(
    `ws://127.0.0.1:${server.address().port}/api/quan-ly/giam-sat/ws`,
    { headers: token ? { Authorization: `Bearer ${token}` } : {} },
  );
}

function taoTokenPhuHuynh(id = 3) {
  return jwt.sign({ id, vaiTro: 'PHU_HUYNH' }, process.env.JWT_SECRET, {
    expiresIn: '1h',
  });
}

function moSocketPhuHuynh(hocSinhId, token = taoTokenPhuHuynh()) {
  return new WebSocket(
    `ws://127.0.0.1:${server.address().port}/api/phu-huynh/theo-doi/ws?hocSinhId=${hocSinhId}`,
    { headers: token ? { Authorization: `Bearer ${token}` } : {} },
  );
}

function docTin(socket) {
  return new Promise((resolve, reject) => {
    socket.once('message', (data) => resolve(JSON.parse(data.toString())));
    socket.once('error', reject);
  });
}

function doiDenKhongCoTin(socket, ms = 100) {
  return new Promise((resolve, reject) => {
    const onMessage = () => {
      clearTimeout(timer);
      resolve(false);
    };
    const timer = setTimeout(() => {
      socket.off('message', onMessage);
      resolve(true);
    }, ms);
    socket.once('message', onMessage);
    socket.once('error', reject);
  });
}

async function postGps(chuyenId, viDo = 10.7725, kinhDo = 106.698) {
  return fetch(`${baseUrl}/api/van-hanh/chuyen/${chuyenId}/vi-tri`, {
    method: 'POST',
    headers: {
      Authorization: `Bearer ${taoToken()}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({ viDo, kinhDo }),
  });
}

test('WebSocket yêu cầu token hợp lệ và vai trò QUAN_LY', async () => {
  for (const token of [null, taoToken('TAI_XE')]) {
    const socket = moSocket(token);
    await new Promise((resolve, reject) => {
      socket.once('open', () => reject(new Error('Kết nối không được phép')));
      socket.once('error', resolve);
      socket.once('unexpected-response', resolve);
    });
  }
});

test('GPS mới được phát tới phiên QUAN_LY sau khi API lưu thành công', async () => {
  const socket = moSocket();
  const tinKetNoi = docTin(socket);
  await new Promise((resolve, reject) => {
    socket.once('open', resolve);
    socket.once('error', reject);
  });
  assert.deepEqual(await tinKetNoi, { type: 'connected' });

  const tinGps = docTin(socket);
  const response = await fetch(`${baseUrl}/api/van-hanh/chuyen/7/vi-tri`, {
    method: 'POST',
    headers: {
      Authorization: `Bearer ${taoToken()}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({ viDo: 10.7725, kinhDo: 106.698 }),
  });

  assert.equal(response.status, 201);
  assert.deepEqual(await tinGps, {
    type: 'gps_updated',
    data: {
      chuyen_di_id: 7,
      vi_do: 10.7725,
      kinh_do: 106.698,
      thoi_diem: '2026-11-17T10:20:00.000Z',
    },
  });
  socket.close();
});

test('API GPS từ chối tọa độ ngoài phạm vi trước khi truy vấn hoặc phát', async () => {
  const cacLenh = [];
  hienTai.truyVan = async (sql) => {
    cacLenh.push(sql);
    return { rows: [] };
  };

  for (const [viDo, kinhDo] of [[90.1, 10], [-90.1, 10], [10, 180.1], [10, -180.1], [null, 10]]) {
    const response = await postGps(7, viDo, kinhDo);
    assert.equal(response.status, 400);
  }
  assert.equal(cacLenh.length, 0);
});

test('API GPS không nhận tọa độ cho chuyến chưa chạy và không ghi vị trí', async () => {
  const cacLenh = [];
  hienTai.truyVan = async (sql) => {
    cacLenh.push(sql);
    return { rows: [] };
  };

  const response = await postGps(7);

  assert.equal(response.status, 409);
  assert.equal(cacLenh.length, 1);
  assert.match(cacLenh[0], /trang_thai = 'DANG_CHAY'/);
});

test('WebSocket từ chối phụ huynh chưa liên kết học sinh', async () => {
  hienTai.truyVan = async () => ({ rows: [] });
  const socket = moSocketPhuHuynh(9);
  const status = await new Promise((resolve, reject) => {
    socket.once('unexpected-response', (_request, response) => {
      resolve(response.statusCode);
    });
    socket.once('open', () => reject(new Error('Phụ huynh không liên kết được kết nối')));
    socket.once('error', (error) => {
      if (!socket.listenerCount('unexpected-response')) resolve(error.message);
    });
  });
  assert.equal(status, 401);
});

test('Phụ huynh liên kết chỉ nhận GPS của chuyến đã đăng ký cho học sinh', async () => {
  hienTai.truyVan = async (sql) => {
    if (/FROM phu_huynh_hoc_sinh/.test(sql)) {
      return { rows: [{ chuyen_di_id: 7 }] };
    }
    if (/SELECT DISTINCT phhs\.phu_huynh_id/.test(sql)) {
      return { rows: [{ phu_huynh_id: 3, hoc_sinh_id: 9 }] };
    }
    return {
      rows: [{
        id: 41,
        chuyen_di_id: 7,
        vi_do: 10.7725,
        kinh_do: 106.698,
        thoi_diem: '2026-11-17T10:20:00.000Z',
      }],
    };
  };

  const socket = moSocketPhuHuynh(9);
  assert.deepEqual(await docTin(socket), { type: 'connected' });
  const gpsMessage = docTin(socket);
  const response = await postGps(7);

  assert.equal(response.status, 201);
  assert.deepEqual(await gpsMessage, {
    type: 'gps_updated',
    data: {
      chuyen_di_id: 7,
      vi_do: 10.7725,
      kinh_do: 106.698,
      thoi_diem: '2026-11-17T10:20:00.000Z',
    },
  });
  socket.close();
});

test('Phụ huynh không nhận vị trí chuyến ngoài phạm vi đăng ký', async () => {
  hienTai.truyVan = async (sql) => {
    if (/FROM phu_huynh_hoc_sinh/.test(sql)) {
      return { rows: [{ chuyen_di_id: 7 }] };
    }
    if (/SELECT DISTINCT phhs\.phu_huynh_id/.test(sql)) {
      return { rows: [{ phu_huynh_id: 3, hoc_sinh_id: 9 }] };
    }
    return {
      rows: [{
        id: 42,
        chuyen_di_id: 8,
        vi_do: 10.7725,
        kinh_do: 106.698,
        thoi_diem: '2026-11-17T10:20:00.000Z',
      }],
    };
  };

  const socket = moSocketPhuHuynh(9);
  assert.deepEqual(await docTin(socket), { type: 'connected' });
  const noGps = doiDenKhongCoTin(socket);
  const response = await postGps(8);

  assert.equal(response.status, 201);
  assert.equal(await noGps, true);
  socket.close();
});
