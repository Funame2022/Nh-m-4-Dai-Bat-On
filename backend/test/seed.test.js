const { test, beforeEach } = require('node:test');
const assert = require('node:assert/strict');

const trangThai = {
  cacLenh: [],
  soLanGiaoDich: 0,
  daDongPool: false,
  query: async () => ({ rows: [{ id: 1 }] }),
};

const fakeDb = {
  pool: {
    end: async () => {
      trangThai.daDongPool = true;
    },
  },
  truyVan: async () => {
    throw new Error('seed phai dung client trong giao dich');
  },
  trongGiaoDich: async (callback) => {
    trangThai.soLanGiaoDich += 1;
    return callback({
      query: (sql, params) => {
        trangThai.cacLenh.push({ sql, params });
        return trangThai.query(sql, params);
      },
    });
  },
};

const duongDanDb = require.resolve('../src/db');
require.cache[duongDanDb] = {
  id: duongDanDb,
  filename: duongDanDb,
  loaded: true,
  exports: fakeDb,
};

const seed = require('../src/seed');
const soLenhKhiRequire = trangThai.cacLenh.length;

beforeEach(() => {
  trangThai.cacLenh = [];
  trangThai.soLanGiaoDich = 0;
  trangThai.daDongPool = false;
  trangThai.query = async () => ({ rows: [{ id: 1 }] });
});

function taoDbDiemDungGiaLap(dsBanDau) {
  const state = { stops: dsBanDau.map((diem) => ({ ...diem })) };
  let idTiepTheo = Math.max(0, ...state.stops.map((diem) => diem.id)) + 1;

  trangThai.query = async (sql, params = []) => {
    const lenh = sql.replace(/\s+/g, ' ').trim();

    if (/FROM diem_dung dd/.test(lenh)) {
      return {
        rows: state.stops
          .slice()
          .sort((a, b) => a.id - b.id)
          .map((diem) => ({ ...diem })),
      };
    }

    if (/^UPDATE diem_dung SET thu_tu = \$1, ten = \$2, vi_do = \$3, kinh_do = \$4, gio_du_kien = \$5 WHERE id = \$6/.test(lenh)) {
      const [thu_tu, ten, vi_do, kinh_do, gio_du_kien, id] = params;
      const diem = state.stops.find((d) => d.id === id);
      Object.assign(diem, { thu_tu, ten, vi_do, kinh_do, gio_du_kien });
      return { rows: [{ ...diem }] };
    }

    if (/^UPDATE diem_dung SET thu_tu = \$1 WHERE id = \$2/.test(lenh)) {
      const [thu_tu, id] = params;
      const diem = state.stops.find((d) => d.id === id);
      diem.thu_tu = thu_tu;
      return { rows: [{ ...diem }] };
    }

    if (/^INSERT INTO diem_dung/.test(lenh)) {
      const [tuyen_id, thu_tu, ten, vi_do, kinh_do, gio_du_kien] = params;
      const diem = {
        id: idTiepTheo,
        tuyen_id,
        thu_tu,
        ten,
        vi_do,
        kinh_do,
        gio_du_kien,
        co_dang_ky: false,
        co_diem_danh: false,
      };
      idTiepTheo += 1;
      state.stops.push(diem);
      return { rows: [{ ...diem }] };
    }

    if (/^DELETE FROM diem_dung/.test(lenh)) {
      const [id, tuyen_id] = params;
      state.stops = state.stops.filter(
        (diem) => !(diem.id === id && diem.tuyen_id === tuyen_id)
      );
      return { rows: [] };
    }

    return { rows: [{ id: 1 }] };
  };

  return state;
}

test('require seed khong tu dong nap du lieu', () => {
  assert.equal(typeof seed.napDuLieuMau, 'function');
  assert.equal(typeof seed.main, 'function');
  assert.equal(soLenhKhiRequire, 0);
});

test('seed dung DON_SANG hop le cho dang ky va chuyen di', async () => {
  await seed.napDuLieuMau();

  const cacLenhLienQuan = trangThai.cacLenh.filter(({ sql }) =>
    /INSERT INTO (dang_ky_tuyen|chuyen_di)/.test(sql)
  );
  assert.equal(
    cacLenhLienQuan.filter(({ sql }) => /INSERT INTO dang_ky_tuyen/.test(sql)).length,
    2
  );
  assert.equal(
    cacLenhLienQuan.filter(({ sql }) => /INSERT INTO chuyen_di/.test(sql)).length,
    1
  );

  const giaTriChieu = [];
  for (const { sql, params } of cacLenhLienQuan) {
    assert.doesNotMatch(sql, /'DON'(?!_)/);
    assert.doesNotMatch(sql, /'TRA_CHIEU'/);
    giaTriChieu.push(
      ...params.filter(
        (giaTri) => giaTri === 'DON' || giaTri === 'DON_SANG' || giaTri === 'TRA_CHIEU'
      )
    );
  }

  assert.deepEqual(giaTriChieu, ['DON_SANG', 'DON_SANG', 'DON_SANG']);
  for (const giaTri of giaTriChieu) {
    assert.ok(['DON_SANG', 'TRA_CHIEU'].includes(giaTri));
  }
});

test('seed khong reset trang thai va thoi diem cua chuyen di khi chay lai', async () => {
  await seed.napDuLieuMau();

  const lenhChuyenDi = trangThai.cacLenh.find(({ sql }) => /INSERT INTO chuyen_di/.test(sql));
  assert.ok(lenhChuyenDi);
  assert.match(lenhChuyenDi.sql, /ON CONFLICT \(tuyen_id, ngay, chieu\) DO NOTHING/);
  assert.doesNotMatch(lenhChuyenDi.sql, /DO UPDATE/);
  assert.ok(!trangThai.cacLenh.some(({ sql }) => /UPDATE chuyen_di/.test(sql)));
});

test('seed chay trong mot giao dich va dung upsert cho du lieu chay lai', async () => {
  await seed.napDuLieuMau();

  assert.equal(trangThai.soLanGiaoDich, 1);

  const timLenh = (regex) => trangThai.cacLenh.find(({ sql }) => regex.test(sql))?.sql || '';

  assert.match(
    timLenh(/INSERT INTO nguoi_dung/),
    /ON CONFLICT \(email\) DO UPDATE[\s\S]*mat_khau_hash = EXCLUDED\.mat_khau_hash[\s\S]*vai_tro = EXCLUDED\.vai_tro/
  );
  assert.match(
    timLenh(/INSERT INTO tai_xe/),
    /ON CONFLICT \(nguoi_dung_id\) DO UPDATE/
  );
  assert.match(timLenh(/INSERT INTO xe/), /ON CONFLICT \(bien_so\) DO UPDATE/);
  assert.match(timLenh(/INSERT INTO hoc_sinh/), /ON CONFLICT \(ma_hs\) DO UPDATE/);
  assert.match(
    timLenh(/INSERT INTO phu_huynh_hoc_sinh/),
    /ON CONFLICT \(phu_huynh_id, hoc_sinh_id\) DO UPDATE/
  );
});

test('seed khoi phuc diem dung bi doi thu tu/ten ma khong tao ban trung', async () => {
  const state = taoDbDiemDungGiaLap([
    {
      id: 1, tuyen_id: 1, thu_tu: 2, ten: 'Nhà thờ Đức Bà (Q1) - da doi ten',
      vi_do: 10.1, kinh_do: 106.1, gio_du_kien: '09:00', co_dang_ky: true, co_diem_danh: false,
    },
    {
      id: 2, tuyen_id: 1, thu_tu: 2, ten: 'Chợ Bến Thành (Q1)',
      vi_do: 10.7725, kinh_do: 106.6980, gio_du_kien: '06:45', co_dang_ky: false, co_diem_danh: false,
    },
    {
      id: 3, tuyen_id: 1, thu_tu: 3, ten: 'Cổng trường THPT Thực Hành Sài Gòn',
      vi_do: 10.7599, kinh_do: 106.6822, gio_du_kien: '07:05', co_dang_ky: false, co_diem_danh: false,
    },
  ]);

  await seed.napDuLieuMau();

  const thuTu = new Map();
  for (const diem of state.stops) {
    assert.ok(!thuTu.has(diem.thu_tu), `trung thu_tu ${diem.thu_tu}`);
    thuTu.set(diem.thu_tu, diem);
  }

  assert.equal(state.stops.length, 3);
  assert.ok(state.stops.some((diem) => diem.id === 1), 'giu diem dang duoc tham chieu');
  assert.equal(thuTu.get(1).ten, 'Nhà thờ Đức Bà (Q1)');
  assert.equal(thuTu.get(2).ten, 'Chợ Bến Thành (Q1)');
  assert.equal(thuTu.get(3).ten, 'Cổng trường THPT Thực Hành Sài Gòn');
  assert.equal(
    trangThai.cacLenh.filter(({ sql }) => /INSERT INTO diem_dung/.test(sql)).length,
    0
  );
});

test('seed xoa diem mo coi va giu diem du co tham chieu ngoai dai fixture', async () => {
  const state = taoDbDiemDungGiaLap([
    {
      id: 1, tuyen_id: 1, thu_tu: 1, ten: 'Nhà thờ Đức Bà (Q1)',
      vi_do: 10.7798, kinh_do: 106.6990, gio_du_kien: '06:30', co_dang_ky: false, co_diem_danh: false,
    },
    {
      id: 2, tuyen_id: 1, thu_tu: 2, ten: 'Chợ Bến Thành (Q1)',
      vi_do: 10.7725, kinh_do: 106.6980, gio_du_kien: '06:45', co_dang_ky: false, co_diem_danh: false,
    },
    {
      id: 3, tuyen_id: 1, thu_tu: 3, ten: 'Cổng trường THPT Thực Hành Sài Gòn',
      vi_do: 10.7599, kinh_do: 106.6822, gio_du_kien: '07:05', co_dang_ky: false, co_diem_danh: false,
    },
    {
      id: 4, tuyen_id: 1, thu_tu: 4, ten: 'Diem mo coi',
      vi_do: 10.5, kinh_do: 106.5, gio_du_kien: '08:00', co_dang_ky: false, co_diem_danh: false,
    },
    {
      id: 5, tuyen_id: 1, thu_tu: 5, ten: 'Diem du co tham chieu',
      vi_do: 10.6, kinh_do: 106.6, gio_du_kien: '08:30', co_dang_ky: true, co_diem_danh: false,
    },
  ]);

  await seed.napDuLieuMau();

  assert.ok(!state.stops.some((diem) => diem.id === 4), 'xoa diem mo coi');
  const diemDu = state.stops.find((diem) => diem.id === 5);
  assert.ok(diemDu, 'giu diem du co tham chieu');
  assert.ok(diemDu.thu_tu > 3, 'dua diem du ra ngoai dai fixture');

  const thuTuFixture = state.stops
    .filter((diem) => diem.thu_tu >= 1 && diem.thu_tu <= 3)
    .map((diem) => diem.thu_tu)
    .sort((a, b) => a - b);
  assert.deepEqual(thuTuFixture, [1, 2, 3]);
});

test('napDuLieuMau khong nuot loi co so du lieu', async () => {
  trangThai.query = async () => {
    throw new Error('loi co so du lieu');
  };

  await assert.rejects(() => seed.napDuLieuMau(), /loi co so du lieu/);
});

test('main dat process.exitCode = 1 va dong pool khi seed loi', async () => {
  const exitCodeCu = process.exitCode;
  const consoleErrorCu = console.error;
  process.exitCode = undefined;
  console.error = () => {};
  trangThai.query = async () => {
    throw new Error('loi DB');
  };

  try {
    await seed.main();
    assert.equal(process.exitCode, 1);
    assert.equal(trangThai.daDongPool, true);
  } finally {
    console.error = consoleErrorCu;
    process.exitCode = exitCodeCu;
  }
});

test('main dong pool va khong dat exit code loi khi thanh cong', async () => {
  const exitCodeCu = process.exitCode;
  const consoleLogCu = console.log;
  process.exitCode = undefined;
  console.log = () => {};

  try {
    await seed.main();
    assert.equal(process.exitCode, undefined);
    assert.equal(trangThai.daDongPool, true);
  } finally {
    console.log = consoleLogCu;
    process.exitCode = exitCodeCu;
  }
});
