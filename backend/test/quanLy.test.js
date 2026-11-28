const { test, before, after, beforeEach } = require('node:test');
const assert = require('node:assert/strict');
const express = require('express');
const jwt = require('jsonwebtoken');

process.env.JWT_SECRET = 'khoa-thu-nghiem';

const hienTai = {
  truyVan: async () => ({ rows: [] }),
  trongGiaoDich: async (callback) => callback({ query: async () => ({ rows: [] }) }),
};

const fakeDb = {
  truyVan: (sql, params) => hienTai.truyVan(sql, params),
  trongGiaoDich: (callback) => hienTai.trongGiaoDich(callback),
  pool: { end: async () => {} },
};

const duongDanDb = require.resolve('../src/db');
require.cache[duongDanDb] = {
  id: duongDanDb,
  filename: duongDanDb,
  loaded: true,
  exports: fakeDb,
};

const quanLyRouter = require('../src/routes/quanLy');
const TOKEN = jwt.sign({ id: 1, vaiTro: 'QUAN_LY' }, process.env.JWT_SECRET, { expiresIn: '1h' });

let server;
let baseUrl;

before(async () => {
  const app = express();
  app.use(express.json());
  app.use('/api/quan-ly', quanLyRouter);
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
  hienTai.trongGiaoDich = async (callback) => callback({ query: async () => ({ rows: [] }) });
});

async function goi(duongDan, tuyChon = {}) {
  const headers = { Authorization: `Bearer ${TOKEN}`, ...(tuyChon.headers || {}) };
  if (tuyChon.body !== undefined) headers['Content-Type'] = 'application/json';
  const phanHoi = await fetch(baseUrl + duongDan, { ...tuyChon, headers });
  const body = await phanHoi.json().catch(() => null);
  return { status: phanHoi.status, body };
}

const BODY_DIEM_DUNG = {
  thuTu: 4,
  ten: ' Cổng phụ ',
  viDo: 10.75,
  kinhDo: 106.68,
  gioDuKien: '07:15',
};

function goiCapNhat(tuyenId = 2, diemDungId = 5, body = BODY_DIEM_DUNG) {
  return goi(`/api/quan-ly/tuyen/${tuyenId}/diem-dung/${diemDungId}`, {
    method: 'PUT',
    body: JSON.stringify(body),
  });
}

// ================= GET /dang-ky-tuyen =================

test('GET /dang-ky-tuyen loc theo bo loc va tra ve cac cot join', async () => {
  const daGoi = [];
  hienTai.truyVan = async (sql, params) => {
    daGoi.push({ sql, params });
    return {
      rows: [{
        hoc_sinh_id: 7,
        tuyen_id: 2,
        diem_dung_id: 5,
        chieu: 'DON_SANG',
        ma_hs: 'HS007',
        ho_ten: 'Nguyễn Văn A',
        ten_tuyen: 'Tuyến 02',
        ten_diem_dung: 'Điểm 05',
        thu_tu_diem_dung: 3,
      }],
    };
  };

  const kq = await goi('/api/quan-ly/dang-ky-tuyen?hocSinhId=7&tuyenId=2&chieu=DON_SANG');

  assert.equal(kq.status, 200);
  assert.equal(daGoi.length, 1);
  assert.deepEqual(daGoi[0].params, [7, 2, 'DON_SANG']);
  assert.match(daGoi[0].sql, /FROM dang_ky_tuyen dk/);
  assert.match(daGoi[0].sql, /JOIN hoc_sinh/);
  assert.match(daGoi[0].sql, /JOIN tuyen/);
  assert.match(daGoi[0].sql, /dd\.ten AS ten_diem_dung/);
  assert.match(daGoi[0].sql, /dd\.thu_tu AS thu_tu_diem_dung/);
  assert.equal(kq.body[0].ma_hs, 'HS007');
  assert.equal(kq.body[0].ten_diem_dung, 'Điểm 05');
  assert.equal(kq.body[0].thu_tu_diem_dung, 3);
});

test('GET /dang-ky-tuyen khong co bo loc thi tra ve tat ca', async () => {
  const daGoi = [];
  hienTai.truyVan = async (sql, params) => {
    daGoi.push({ sql, params });
    return { rows: [] };
  };

  const kq = await goi('/api/quan-ly/dang-ky-tuyen');

  assert.equal(kq.status, 200);
  assert.deepEqual(daGoi[0].params, []);
  assert.doesNotMatch(daGoi[0].sql, /WHERE/);
});

test('GET /dang-ky-tuyen tu choi bo loc khong hop le', async () => {
  let soLanGoiDb = 0;
  hienTai.truyVan = async () => {
    soLanGoiDb += 1;
    return { rows: [] };
  };

  const dsDuongDanSai = [
    '/api/quan-ly/dang-ky-tuyen?hocSinhId=abc',
    '/api/quan-ly/dang-ky-tuyen?hocSinhId=0',
    '/api/quan-ly/dang-ky-tuyen?hocSinhId=9007199254740993',
    '/api/quan-ly/dang-ky-tuyen?tuyenId=-1',
    '/api/quan-ly/dang-ky-tuyen?tuyenId=1.5',
    '/api/quan-ly/dang-ky-tuyen?tuyenId=2147483648',
    '/api/quan-ly/dang-ky-tuyen?chieu=SAI',
    '/api/quan-ly/dang-ky-tuyen?chieu=DON',
  ];

  for (const duongDan of dsDuongDanSai) {
    const kq = await goi(duongDan);
    assert.equal(kq.status, 400, duongDan);
  }
  assert.equal(soLanGoiDb, 0);
});

// ================= PUT /tuyen/:tuyenId/diem-dung/:diemDungId =================

test('PUT diem dung cap nhat thanh cong va giu tuyen_id', async () => {
  const cacLenh = [];
  let daGiaoDich = false;
  hienTai.trongGiaoDich = async (callback) => {
    daGiaoDich = true;
    return callback({
      query: async (sql, params) => {
        cacLenh.push({ sql, params });
        if (/FOR UPDATE/.test(sql)) return { rows: [{ id: 2 }] };
        if (/SELECT id FROM diem_dung WHERE id = \$1 AND tuyen_id = \$2/.test(sql)) {
          return { rows: [{ id: 5 }] };
        }
        if (/thu_tu = \$2 AND id <> \$3/.test(sql)) return { rows: [] };
        if (/UPDATE diem_dung/.test(sql)) {
          return {
            rows: [{
              id: 5,
              tuyen_id: 2,
              thu_tu: 4,
              ten: 'Cổng phụ',
              vi_do: 10.75,
              kinh_do: 106.68,
              gio_du_kien: '07:15',
            }],
          };
        }
        throw new Error(`SQL khong mong doi: ${sql}`);
      },
    });
  };

  const kq = await goiCapNhat();

  assert.equal(kq.status, 200);
  assert.equal(daGiaoDich, true);
  assert.equal(kq.body.id, 5);
  assert.equal(kq.body.tuyen_id, 2);
  assert.equal(kq.body.thu_tu, 4);

  const lenhCapNhat = cacLenh.find(({ sql }) => /UPDATE diem_dung/.test(sql));
  assert.deepEqual(lenhCapNhat.params, [4, 'Cổng phụ', 10.75, 106.68, '07:15', 5, 2]);
});

test('PUT diem dung tu choi toa do khong hop le', async () => {
  let daGiaoDich = false;
  hienTai.trongGiaoDich = async () => {
    daGiaoDich = true;
    throw new Error('khong duoc mo giao dich');
  };

  const dsBodySai = [
    { ...BODY_DIEM_DUNG, viDo: 91 },
    { ...BODY_DIEM_DUNG, viDo: -91 },
    { ...BODY_DIEM_DUNG, viDo: 'abc' },
    { ...BODY_DIEM_DUNG, kinhDo: 181 },
    { ...BODY_DIEM_DUNG, kinhDo: -181 },
  ];

  for (const body of dsBodySai) {
    const kq = await goiCapNhat(2, 5, body);
    assert.equal(kq.status, 400);
  }
  assert.equal(daGiaoDich, false);
});

test('PUT diem dung tu choi body khong hop le', async () => {
  let daGiaoDich = false;
  hienTai.trongGiaoDich = async () => {
    daGiaoDich = true;
    throw new Error('khong duoc mo giao dich');
  };

  const dsBodySai = [
    { ...BODY_DIEM_DUNG, thuTu: 0 },
    { ...BODY_DIEM_DUNG, thuTu: 1.5 },
    { ...BODY_DIEM_DUNG, thuTu: 2147483648 },
    { ...BODY_DIEM_DUNG, ten: '   ' },
    { ...BODY_DIEM_DUNG, gioDuKien: '7:15' },
    { ...BODY_DIEM_DUNG, gioDuKien: '24:00' },
    { thuTu: 1, ten: 'A', viDo: 0, kinhDo: 0 },
  ];

  for (const body of dsBodySai) {
    const kq = await goiCapNhat(2, 5, body);
    assert.equal(kq.status, 400);
  }
  assert.equal(daGiaoDich, false);
});

test('PUT diem dung tu choi id tuyen hoac diem dung khong hop le', async () => {
  let daGiaoDich = false;
  hienTai.trongGiaoDich = async () => {
    daGiaoDich = true;
    throw new Error('khong duoc mo giao dich');
  };

  assert.equal((await goiCapNhat('abc', 5)).status, 400);
  assert.equal((await goiCapNhat(2, '0')).status, 400);
  assert.equal(daGiaoDich, false);
});

test('PUT diem dung tra 404 khi khong tim thay tuyen', async () => {
  hienTai.trongGiaoDich = async (callback) => callback({
    query: async (sql) => {
      if (/FOR UPDATE/.test(sql)) return { rows: [] };
      throw new Error(`SQL khong mong doi: ${sql}`);
    },
  });

  const kq = await goiCapNhat(99, 5);
  assert.equal(kq.status, 404);
});

test('PUT diem dung tra 404 khi diem dung khong thuoc tuyen', async () => {
  hienTai.trongGiaoDich = async (callback) => callback({
    query: async (sql) => {
      if (/FOR UPDATE/.test(sql)) return { rows: [{ id: 2 }] };
      if (/SELECT id FROM diem_dung WHERE id = \$1 AND tuyen_id = \$2/.test(sql)) {
        return { rows: [] };
      }
      throw new Error(`SQL khong mong doi: ${sql}`);
    },
  });

  const kq = await goiCapNhat(2, 999);
  assert.equal(kq.status, 404);
});

test('PUT diem dung tra 409 khi thu tu bi trung trong tuyen', async () => {
  let soLanCapNhat = 0;
  hienTai.trongGiaoDich = async (callback) => callback({
    query: async (sql) => {
      if (/FOR UPDATE/.test(sql)) return { rows: [{ id: 2 }] };
      if (/SELECT id FROM diem_dung WHERE id = \$1 AND tuyen_id = \$2/.test(sql)) {
        return { rows: [{ id: 5 }] };
      }
      if (/thu_tu = \$2 AND id <> \$3/.test(sql)) return { rows: [{ id: 9 }] };
      if (/UPDATE diem_dung/.test(sql)) soLanCapNhat += 1;
      throw new Error(`SQL khong mong doi: ${sql}`);
    },
  });

  const kq = await goiCapNhat();
  assert.equal(kq.status, 409);
  assert.equal(soLanCapNhat, 0);
});

// ================= POST /tuyen/:tuyenId/diem-dung =================

test('POST diem dung them thanh cong', async () => {
  const cacLenh = [];
  hienTai.trongGiaoDich = async (callback) => callback({
    query: async (sql, params) => {
      cacLenh.push({ sql, params });
      if (/FOR UPDATE/.test(sql)) return { rows: [{ id: 2 }] };
      if (/SELECT id FROM diem_dung WHERE tuyen_id = \$1 AND thu_tu = \$2/.test(sql)) {
        return { rows: [] };
      }
      if (/INSERT INTO diem_dung/.test(sql)) {
        return {
          rows: [{
            id: 8,
            tuyen_id: 2,
            thu_tu: 4,
            ten: 'Cổng phụ',
            vi_do: 10.75,
            kinh_do: 106.68,
            gio_du_kien: '07:15',
          }],
        };
      }
      throw new Error(`SQL khong mong doi: ${sql}`);
    },
  });

  const kq = await goi('/api/quan-ly/tuyen/2/diem-dung', {
    method: 'POST',
    body: JSON.stringify(BODY_DIEM_DUNG),
  });

  assert.equal(kq.status, 201);
  assert.equal(kq.body.id, 8);
  assert.equal(kq.body.tuyen_id, 2);
  const lenhChen = cacLenh.find(({ sql }) => /INSERT INTO diem_dung/.test(sql));
  assert.deepEqual(lenhChen.params, [2, 4, 'Cổng phụ', 10.75, 106.68, '07:15']);
});

test('POST diem dung tra 409 khi thu tu bi trung trong tuyen', async () => {
  let daChen = false;
  hienTai.trongGiaoDich = async (callback) => callback({
    query: async (sql) => {
      if (/FOR UPDATE/.test(sql)) return { rows: [{ id: 2 }] };
      if (/SELECT id FROM diem_dung WHERE tuyen_id = \$1 AND thu_tu = \$2/.test(sql)) {
        return { rows: [{ id: 9 }] };
      }
      if (/INSERT INTO diem_dung/.test(sql)) daChen = true;
      throw new Error(`SQL khong mong doi: ${sql}`);
    },
  });

  const kq = await goi('/api/quan-ly/tuyen/2/diem-dung', {
    method: 'POST',
    body: JSON.stringify(BODY_DIEM_DUNG),
  });

  assert.equal(kq.status, 409);
  assert.equal(daChen, false);
});

// ================= GET /giam-sat =================

test('GET /giam-sat lay vi tri va thoi diem tu cung mot ban ghi GPS moi nhat', async () => {
  let sqlNhan = '';
  hienTai.truyVan = async (sql) => {
    sqlNhan = sql;
    return {
      rows: [{
        id: 1,
        vi_do: 10.1,
        kinh_do: 106.2,
        vi_tri_cap_nhat_luc: '2026-11-17T01:00:00.000Z',
      }],
    };
  };

  const kq = await goi('/api/quan-ly/giam-sat');

  assert.equal(kq.status, 200);
  assert.match(sqlNhan, /LEFT JOIN LATERAL/);
  assert.match(sqlNhan, /ORDER BY\s+thoi_diem DESC,\s*id DESC/i);
  assert.match(sqlNhan, /vt\.vi_do/);
  assert.match(sqlNhan, /vt\.kinh_do/);
  assert.match(sqlNhan, /vt\.thoi_diem AS vi_tri_cap_nhat_luc/);
  assert.doesNotMatch(sqlNhan, /\(SELECT vi_do FROM vi_tri_xe/);
  assert.equal(kq.body[0].vi_do, 10.1);
  assert.equal(kq.body[0].kinh_do, 106.2);
  assert.equal(kq.body[0].vi_tri_cap_nhat_luc, '2026-11-17T01:00:00.000Z');
});

test('GET /giam-sat tra ve null khi chuyen di chua co GPS', async () => {
  hienTai.truyVan = async () => ({
    rows: [{ id: 1, vi_do: null, kinh_do: null, vi_tri_cap_nhat_luc: null }],
  });

  const kq = await goi('/api/quan-ly/giam-sat');

  assert.equal(kq.status, 200);
  assert.equal(kq.body[0].vi_do, null);
  assert.equal(kq.body[0].kinh_do, null);
  assert.equal(kq.body[0].vi_tri_cap_nhat_luc, null);
});

// ================= PHÂN QUYỀN CRUD XE / TÀI XẾ =================

const DS_VAI_TRO_KHONG_PHAI_QUAN_LY = [
  'PHU_HUYNH',
  'TAI_XE',
  'BAO_MAU',
  'UNKNOWN',
];

const DS_ROUTE_CRUD_XE_TAI_XE = [
  ['GET', '/api/quan-ly/xe'],
  ['POST', '/api/quan-ly/xe'],
  ['PUT', '/api/quan-ly/xe/1'],
  ['DELETE', '/api/quan-ly/xe/1'],
  ['GET', '/api/quan-ly/tai-xe'],
  ['POST', '/api/quan-ly/tai-xe'],
  ['PUT', '/api/quan-ly/tai-xe/1'],
  ['DELETE', '/api/quan-ly/tai-xe/1'],
];

test('CRUD xe/tai-xe tu choi vai tro khong phai QUAN_LY ma khong goi DB', async () => {
  let soLanTruyVan = 0;
  let soLanGiaoDich = 0;
  hienTai.truyVan = async () => {
    soLanTruyVan += 1;
    return { rows: [] };
  };
  hienTai.trongGiaoDich = async () => {
    soLanGiaoDich += 1;
    throw new Error('khong duoc mo giao dich');
  };

  for (const vaiTro of DS_VAI_TRO_KHONG_PHAI_QUAN_LY) {
    const token = jwt.sign(
      { id: 1, vaiTro },
      process.env.JWT_SECRET,
      { expiresIn: '1h' }
    );
    for (const [method, duongDan] of DS_ROUTE_CRUD_XE_TAI_XE) {
      const kq = await goi(duongDan, {
        method,
        headers: { Authorization: `Bearer ${token}` },
      });
      assert.equal(kq.status, 403, `${vaiTro} ${method} ${duongDan}`);
    }
  }

  assert.equal(soLanTruyVan, 0);
  assert.equal(soLanGiaoDich, 0);
});

test('CRUD xe/tai-xe khong co token tra 401 ma khong goi DB', async () => {
  let soLanTruyVan = 0;
  let soLanGiaoDich = 0;
  hienTai.truyVan = async () => {
    soLanTruyVan += 1;
    return { rows: [] };
  };
  hienTai.trongGiaoDich = async () => {
    soLanGiaoDich += 1;
    throw new Error('khong duoc mo giao dich');
  };

  for (const [method, duongDan] of DS_ROUTE_CRUD_XE_TAI_XE) {
    const kq = await goi(duongDan, {
      method,
      headers: { Authorization: '' },
    });
    assert.equal(kq.status, 401, `${method} ${duongDan}`);
  }

  assert.equal(soLanTruyVan, 0);
  assert.equal(soLanGiaoDich, 0);
});

// ================= DELETE TUYEN =================

function cauHinhXoaTuyen({ coChuyenDi, coDangKy, coTuyen = true }) {
  const cacLenh = [];
  let soLanGiaoDich = 0;
  let soLanTruyVan = 0;

  hienTai.truyVan = async (sql, params) => {
    soLanTruyVan += 1;
    cacLenh.push({ sql, params, qua: 'truyVan' });
    return { rows: [] };
  };

  hienTai.trongGiaoDich = async (callback) => {
    soLanGiaoDich += 1;
    return callback({
      query: async (sql, params) => {
        cacLenh.push({ sql, params, qua: 'giaoDich' });

        if (/SELECT id FROM tuyen WHERE id = \$1 FOR UPDATE/.test(sql)) {
          return { rows: coTuyen ? [{ id: 2 }] : [] };
        }
        if (/EXISTS\(SELECT 1 FROM chuyen_di/.test(sql)) {
          return {
            rows: [{
              co_chuyen_di: coChuyenDi,
              co_dang_ky: coDangKy,
            }],
          };
        }
        if (/DELETE FROM diem_dung/.test(sql)) return { rows: [] };
        if (/DELETE FROM tuyen/.test(sql)) return { rows: [] };
        throw new Error(`SQL khong mong doi: ${sql}`);
      },
    });
  };

  return {
    cacLenh,
    laySoLanGiaoDich: () => soLanGiaoDich,
    laySoLanTruyVan: () => soLanTruyVan,
  };
}

test('DELETE tuyen co chuyen di tra 409 va khong xoa diem dung', async () => {
  const theoDoi = cauHinhXoaTuyen({
    coChuyenDi: true,
    coDangKy: false,
  });

  const kq = await goi('/api/quan-ly/tuyen/2', { method: 'DELETE' });

  assert.equal(kq.status, 409);
  assert.equal(theoDoi.laySoLanGiaoDich(), 1);
  assert.equal(theoDoi.laySoLanTruyVan(), 0);
  assert.ok(
    !theoDoi.cacLenh.some(({ sql }) => /DELETE FROM diem_dung/.test(sql)),
    'khong duoc xoa diem dung khi tuyen con chuyen di'
  );
  assert.ok(
    !theoDoi.cacLenh.some(({ sql }) => /DELETE FROM tuyen/.test(sql)),
    'khong duoc xoa tuyen khi tuyen con chuyen di'
  );
  assert.match(kq.body.loi, /chuyến đi|đăng ký/);
});

test('DELETE tuyen co hoc sinh dang ky tra 409 va khong xoa diem dung', async () => {
  const theoDoi = cauHinhXoaTuyen({
    coChuyenDi: false,
    coDangKy: true,
  });

  const kq = await goi('/api/quan-ly/tuyen/2', { method: 'DELETE' });

  assert.equal(kq.status, 409);
  assert.equal(theoDoi.laySoLanGiaoDich(), 1);
  assert.equal(theoDoi.laySoLanTruyVan(), 0);
  assert.ok(
    !theoDoi.cacLenh.some(({ sql }) => /DELETE FROM diem_dung/.test(sql)),
    'khong duoc xoa diem dung khi tuyen con dang ky'
  );
  assert.ok(
    !theoDoi.cacLenh.some(({ sql }) => /DELETE FROM tuyen/.test(sql)),
    'khong duoc xoa tuyen khi tuyen con dang ky'
  );
  assert.match(kq.body.loi, /chuyến đi|đăng ký/);
});

test('DELETE tuyen khong ton tai tra 404 va khong xoa du lieu', async () => {
  const theoDoi = cauHinhXoaTuyen({
    coChuyenDi: false,
    coDangKy: false,
    coTuyen: false,
  });

  const kq = await goi('/api/quan-ly/tuyen/99', { method: 'DELETE' });

  assert.equal(kq.status, 404);
  assert.equal(theoDoi.laySoLanGiaoDich(), 1);
  assert.equal(theoDoi.laySoLanTruyVan(), 0);
  assert.ok(
    !theoDoi.cacLenh.some(({ sql }) => /DELETE FROM diem_dung/.test(sql)),
    'khong duoc xoa diem dung khi tuyen khong ton tai'
  );
  assert.ok(
    !theoDoi.cacLenh.some(({ sql }) => /DELETE FROM tuyen/.test(sql)),
    'khong duoc xoa tuyen khi tuyen khong ton tai'
  );
});

test('DELETE tuyen khong co tham chieu xoa diem dung va tuyen trong cung giao dich', async () => {
  const theoDoi = cauHinhXoaTuyen({
    coChuyenDi: false,
    coDangKy: false,
  });

  const kq = await goi('/api/quan-ly/tuyen/2', { method: 'DELETE' });

  assert.equal(kq.status, 200);
  assert.equal(kq.body.thongBao, 'Đã xóa tuyến');
  assert.equal(theoDoi.laySoLanGiaoDich(), 1);
  assert.equal(theoDoi.laySoLanTruyVan(), 0);

  const viTriXoaDiemDung = theoDoi.cacLenh.findIndex(({ sql }) =>
    /DELETE FROM diem_dung/.test(sql)
  );
  const viTriXoaTuyen = theoDoi.cacLenh.findIndex(({ sql }) =>
    /DELETE FROM tuyen/.test(sql)
  );

  assert.ok(viTriXoaDiemDung >= 0, 'phai xoa diem dung');
  assert.ok(viTriXoaTuyen >= 0, 'phai xoa tuyen');
  assert.ok(
    viTriXoaDiemDung < viTriXoaTuyen,
    'phai xoa diem dung truoc tuyen'
  );
});
