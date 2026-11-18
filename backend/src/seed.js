require('dotenv').config();
const bcrypt = require('bcryptjs');
const { pool, trongGiaoDich } = require('./db');

const TEN_TRUONG = 'THPT Thực Hành Sài Gòn';
const DIA_CHI_TRUONG = '220 Trần Bình Trọng, Q5, TP.HCM';
const TEN_LOP = '10A1';
const TEN_TUYEN = 'Tuyến 01 - Quận 1 đi Quận 5';

const DS_NGUOI_DUNG = [
  ['admin@xetruong.vn', 'Nguyễn Văn Quản Lý', '0901000001', 'QUAN_LY'],
  ['taixe@xetruong.vn', 'Trần Văn Tài Xế', '0901000002', 'TAI_XE'],
  ['baomau@xetruong.vn', 'Lê Thị Bảo Mẫu', '0901000003', 'BAO_MAU'],
  ['phuhuynh@xetruong.vn', 'Phạm Minh Phụ Huynh', '0901000004', 'PHU_HUYNH'],
];

const DS_DIEM_DUNG = [
  { thuTu: 1, ten: 'Nhà thờ Đức Bà (Q1)', viDo: 10.7798, kinhDo: 106.6990, gioDuKien: '06:30' },
  { thuTu: 2, ten: 'Chợ Bến Thành (Q1)', viDo: 10.7725, kinhDo: 106.6980, gioDuKien: '06:45' },
  { thuTu: 3, ten: 'Cổng trường THPT Thực Hành Sài Gòn', viDo: 10.7599, kinhDo: 106.6822, gioDuKien: '07:05' },
];

async function napDuLieuMau() {
  const hash = await bcrypt.hash('123456', 10);

  return trongGiaoDich(async (client) => {
    // 1. Trường & lớp: dùng SELECT trước để không tạo bản ghi trùng khi chạy lại.
    let r = await client.query('SELECT id FROM truong WHERE ten = $1 ORDER BY id LIMIT 1', [TEN_TRUONG]);
    let truongId;
    if (r.rows[0]) {
      truongId = r.rows[0].id;
      await client.query('UPDATE truong SET dia_chi = $1 WHERE id = $2', [DIA_CHI_TRUONG, truongId]);
    } else {
      r = await client.query(
        'INSERT INTO truong (ten, dia_chi) VALUES ($1, $2) RETURNING id',
        [TEN_TRUONG, DIA_CHI_TRUONG]
      );
      truongId = r.rows[0].id;
    }

    r = await client.query(
      'SELECT id FROM lop WHERE truong_id = $1 AND ten_lop = $2 ORDER BY id LIMIT 1',
      [truongId, TEN_LOP]
    );
    let lopId;
    if (r.rows[0]) {
      lopId = r.rows[0].id;
    } else {
      r = await client.query(
        'INSERT INTO lop (truong_id, ten_lop) VALUES ($1, $2) RETURNING id',
        [truongId, TEN_LOP]
      );
      lopId = r.rows[0].id;
    }

    // 2. Bốn tài khoản mẫu: cập nhật cả mật khẩu và vai trò để thông tin đăng nhập mẫu luôn dùng được.
    const userIds = {};
    for (const [email, hoTen, sdt, vaiTro] of DS_NGUOI_DUNG) {
      const nguoiDung = await client.query(`
        INSERT INTO nguoi_dung (email, mat_khau_hash, ho_ten, sdt, vai_tro)
        VALUES ($1, $2, $3, $4, $5)
        ON CONFLICT (email) DO UPDATE
          SET mat_khau_hash = EXCLUDED.mat_khau_hash,
              ho_ten = EXCLUDED.ho_ten,
              sdt = EXCLUDED.sdt,
              vai_tro = EXCLUDED.vai_tro
        RETURNING id
      `, [email, hash, hoTen, sdt, vaiTro]);
      userIds[vaiTro] = nguoiDung.rows[0].id;
    }

    // 3. Hồ sơ tài xế, bảo mẫu và xe.
    const taiXe = await client.query(`
      INSERT INTO tai_xe (nguoi_dung_id, so_gplx, han_gplx)
      VALUES ($1, '790123456789', '2029-12-31')
      ON CONFLICT (nguoi_dung_id) DO UPDATE
        SET so_gplx = EXCLUDED.so_gplx, han_gplx = EXCLUDED.han_gplx
      RETURNING id
    `, [userIds.TAI_XE]);

    const baoMau = await client.query(`
      INSERT INTO bao_mau (nguoi_dung_id) VALUES ($1)
      ON CONFLICT (nguoi_dung_id) DO UPDATE SET nguoi_dung_id = EXCLUDED.nguoi_dung_id
      RETURNING id
    `, [userIds.BAO_MAU]);

    const xe = await client.query(`
      INSERT INTO xe (bien_so, suc_chua, han_dang_kiem)
      VALUES ('51B-246.89', 29, '2027-06-30')
      ON CONFLICT (bien_so) DO UPDATE
        SET suc_chua = EXCLUDED.suc_chua, han_dang_kiem = EXCLUDED.han_dang_kiem
      RETURNING id
    `);

    // 4. Tuyến và các điểm dừng được sửa/cập nhật tại chỗ; điểm dừng bị đổi thứ tự được tái sử dụng
    // để khôi phục fixture chuẩn mà không nhân bản hoặc làm mất tham chiếu.
    r = await client.query('SELECT id FROM tuyen WHERE ten_tuyen = $1 ORDER BY id LIMIT 1', [TEN_TUYEN]);
    let tuyenId;
    if (r.rows[0]) {
      tuyenId = r.rows[0].id;
      await client.query(
        'UPDATE tuyen SET xe_id = $1, tai_xe_id = $2, bao_mau_id = $3 WHERE id = $4',
        [xe.rows[0].id, taiXe.rows[0].id, baoMau.rows[0].id, tuyenId]
      );
    } else {
      r = await client.query(
        'INSERT INTO tuyen (ten_tuyen, xe_id, tai_xe_id, bao_mau_id) VALUES ($1, $2, $3, $4) RETURNING id',
        [TEN_TUYEN, xe.rows[0].id, taiXe.rows[0].id, baoMau.rows[0].id]
      );
      tuyenId = r.rows[0].id;
    }

    const dsDiemDungHienCo = await client.query(`
      SELECT dd.id, dd.thu_tu, dd.ten, dd.vi_do, dd.kinh_do, dd.gio_du_kien,
        EXISTS(SELECT 1 FROM dang_ky_tuyen dk WHERE dk.diem_dung_id = dd.id) AS co_dang_ky,
        EXISTS(SELECT 1 FROM diem_danh dh WHERE dh.diem_dung_id = dd.id) AS co_diem_danh
      FROM diem_dung dd
      WHERE dd.tuyen_id = $1
      ORDER BY dd.id ASC
    `, [tuyenId]);

    const diemChuaGan = [...dsDiemDungHienCo.rows];
    const diemTheoThuTu = new Map();
    const layDiemTheo = (dieuKien) => {
      const viTri = diemChuaGan.findIndex(dieuKien);
      if (viTri === -1) return null;
      return diemChuaGan.splice(viTri, 1)[0];
    };

    // 1. Nhận diện theo tên fixture trước: đổi thứ tự nhưng giữ tên vẫn khôi phục đúng điểm.
    for (const dd of DS_DIEM_DUNG) {
      const diem = layDiemTheo((d) => (d.ten || '').trim() === dd.ten);
      if (diem) diemTheoThuTu.set(dd.thuTu, diem);
    }

    // 2. Sau đó khớp theo thứ tự hiện tại nếu không trùng.
    for (const dd of DS_DIEM_DUNG) {
      if (diemTheoThuTu.has(dd.thuTu)) continue;
      const diem = layDiemTheo((d) => d.thu_tu === dd.thuTu);
      if (diem) diemTheoThuTu.set(dd.thuTu, diem);
    }

    // 3. Fallback tất định: ghép điểm còn lại theo id tăng dần vào các thứ tự còn thiếu.
    const thuTuConThieu = DS_DIEM_DUNG
      .map((dd) => dd.thuTu)
      .filter((thuTu) => !diemTheoThuTu.has(thuTu))
      .sort((a, b) => a - b);
    diemChuaGan.sort((a, b) => a.id - b.id);
    for (const thuTu of thuTuConThieu) {
      if (diemChuaGan.length === 0) break;
      diemTheoThuTu.set(thuTu, diemChuaGan.shift());
    }

    // 4. Ghi đè fixture chuẩn tại chỗ; chỉ chèn khi thật sự thiếu điểm.
    for (const dd of DS_DIEM_DUNG) {
      const diem = diemTheoThuTu.get(dd.thuTu);
      if (diem) {
        await client.query(
          'UPDATE diem_dung SET thu_tu = $1, ten = $2, vi_do = $3, kinh_do = $4, gio_du_kien = $5 WHERE id = $6',
          [dd.thuTu, dd.ten, dd.viDo, dd.kinhDo, dd.gioDuKien, diem.id]
        );
      } else {
        await client.query(
          'INSERT INTO diem_dung (tuyen_id, thu_tu, ten, vi_do, kinh_do, gio_du_kien) VALUES ($1, $2, $3, $4, $5, $6)',
          [tuyenId, dd.thuTu, dd.ten, dd.viDo, dd.kinhDo, dd.gioDuKien]
        );
      }
    }

    // 5. Dọn điểm dư: điểm còn được tham chiếu thì giữ và dời ra ngoài dải fixture;
    //    điểm không còn tham chiếu thì xóa để không để lại bản ghi mồ côi.
    const thuTuNgoaiFixture = Math.max(...DS_DIEM_DUNG.map((dd) => dd.thuTu)) + 1;
    let chiSoDiemDu = 0;
    for (const diem of diemChuaGan) {
      if (diem.co_dang_ky || diem.co_diem_danh) {
        await client.query(
          'UPDATE diem_dung SET thu_tu = $1 WHERE id = $2',
          [thuTuNgoaiFixture + chiSoDiemDu, diem.id]
        );
        chiSoDiemDu += 1;
      } else {
        await client.query(
          'DELETE FROM diem_dung WHERE id = $1 AND tuyen_id = $2',
          [diem.id, tuyenId]
        );
      }
    }

    const diemDungDau = await client.query(
      'SELECT id FROM diem_dung WHERE tuyen_id = $1 ORDER BY thu_tu ASC, id ASC LIMIT 1',
      [tuyenId]
    );
    const diemDungDauId = diemDungDau.rows[0]?.id;
    if (!diemDungDauId) {
      throw new Error('Khong tao duoc diem dung cho tuyen mau');
    }

    // 5. Học sinh, phụ huynh và đăng ký tuyến.
    const hocSinh1 = await client.query(`
      INSERT INTO hoc_sinh (ma_hs, ho_ten, lop_id)
      VALUES ('HS001', 'Phạm Gia Bảo', $1)
      ON CONFLICT (ma_hs) DO UPDATE
        SET ho_ten = EXCLUDED.ho_ten, lop_id = EXCLUDED.lop_id
      RETURNING id
    `, [lopId]);

    const hocSinh2 = await client.query(`
      INSERT INTO hoc_sinh (ma_hs, ho_ten, lop_id)
      VALUES ('HS002', 'Trần Ngọc Minh Châu', $1)
      ON CONFLICT (ma_hs) DO UPDATE
        SET ho_ten = EXCLUDED.ho_ten, lop_id = EXCLUDED.lop_id
      RETURNING id
    `, [lopId]);

    await client.query(`
      INSERT INTO phu_huynh_hoc_sinh (phu_huynh_id, hoc_sinh_id, quan_he)
      VALUES ($1, $2, 'Bố')
      ON CONFLICT (phu_huynh_id, hoc_sinh_id) DO UPDATE SET quan_he = EXCLUDED.quan_he
    `, [userIds.PHU_HUYNH, hocSinh1.rows[0].id]);

    for (const hocSinhId of [hocSinh1.rows[0].id, hocSinh2.rows[0].id]) {
      await client.query(`
        INSERT INTO dang_ky_tuyen (hoc_sinh_id, tuyen_id, diem_dung_id, chieu)
        VALUES ($1, $2, $3, $4)
        ON CONFLICT (hoc_sinh_id, chieu) DO UPDATE
          SET tuyen_id = EXCLUDED.tuyen_id, diem_dung_id = EXCLUDED.diem_dung_id
      `, [hocSinhId, tuyenId, diemDungDauId, 'DON_SANG']);
    }

    // 6. Chuyến đi hôm nay: chạy lại không được reset trạng thái/thời điểm vận hành.
    await client.query(`
      INSERT INTO chuyen_di (tuyen_id, ngay, chieu, trang_thai)
      VALUES ($1, CURRENT_DATE, $2, 'CHUA_CHAY')
      ON CONFLICT (tuyen_id, ngay, chieu) DO NOTHING
    `, [tuyenId, 'DON_SANG']);

    return { truongId, lopId, tuyenId };
  });
}

async function main() {
  try {
    await napDuLieuMau();
    console.log('THANH CONG! Da nap xong du lieu mau va 4 tai khoan (mat khau: 123456).');
  } catch (err) {
    console.error('Loi nap du lieu:', err);
    process.exitCode = 1;
  } finally {
    await pool.end();
  }
}

if (require.main === module) {
  main().catch((err) => {
    console.error('Loi nap du lieu:', err);
    process.exitCode = 1;
  });
}

module.exports = { napDuLieuMau, main };
