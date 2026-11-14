require('dotenv').config();
const bcrypt = require('bcryptjs');
const { truyVan, pool } = require('./db');

async function napDuLieuMau() {
  try {
    console.log('Dang nap du lieu mau cho De 07...');
    const hash = await bcrypt.hash('123456', 10);

    // 1. Tạo Trường & Lớp
    const truong = await truyVan(
      "INSERT INTO truong (ten, dia_chi) VALUES ('THPT Thực Hành Sài Gòn', '220 Trần Bình Trọng, Q5, TP.HCM') ON CONFLICT DO NOTHING RETURNING id"
    );
    const truongId = truong.rows[0]?.id || (await truyVan('SELECT id FROM truong LIMIT 1')).rows[0].id;

    const lop = await truyVan(
      "INSERT INTO lop (truong_id, ten_lop) VALUES ($1, '10A1') ON CONFLICT DO NOTHING RETURNING id",
      [truongId]
    );
    const lopId = lop.rows[0]?.id || (await truyVan('SELECT id FROM lop LIMIT 1')).rows[0].id;

    // 2. Tạo 4 tài khoản cho 4 vai trò (mật khẩu chung: 123456)
    const users = [
      ['admin@xetruong.vn', 'Nguyễn Văn Quản Lý', '0901000001', 'QUAN_LY'],
      ['taixe@xetruong.vn', 'Trần Văn Tài Xế', '0901000002', 'TAI_XE'],
      ['baomau@xetruong.vn', 'Lê Thị Bảo Mẫu', '0901000003', 'BAO_MAU'],
      ['phuhuynh@xetruong.vn', 'Phạm Minh Phụ Huynh', '0901000004', 'PHU_HUYNH'],
    ];
    const userIds = {};
    for (const [email, hoTen, sdt, vaiTro] of users) {
      const r = await truyVan(`
        INSERT INTO nguoi_dung (email, mat_khau_hash, ho_ten, sdt, vai_tro)
        VALUES ($1, $2, $3, $4, $5)
        ON CONFLICT (email) DO UPDATE SET ho_ten = $3 RETURNING id
      `, [email, hash, hoTen, sdt, vaiTro]);
      userIds[vaiTro] = r.rows[0].id;
    }

    // 3. Tạo hồ sơ Tài xế, Bảo mẫu, Xe
    const tx = await truyVan(
      "INSERT INTO tai_xe (nguoi_dung_id, so_gplx, han_gplx) VALUES ($1, '790123456789', '2029-12-31') ON CONFLICT (nguoi_dung_id) DO UPDATE SET han_gplx = '2029-12-31' RETURNING id",
      [userIds.TAI_XE]
    );
    const bm = await truyVan(
      "INSERT INTO bao_mau (nguoi_dung_id) VALUES ($1) ON CONFLICT (nguoi_dung_id) DO UPDATE SET nguoi_dung_id = $1 RETURNING id",
      [userIds.BAO_MAU]
    );
    const xe = await truyVan(
      "INSERT INTO xe (bien_so, suc_chua, han_dang_kiem) VALUES ('51B-246.89', 29, '2027-06-30') ON CONFLICT (bien_so) DO UPDATE SET suc_chua = 29 RETURNING id"
    );

    // 4. Tạo Tuyến 01 & 3 Điểm dừng
    let tuyenRes = await truyVan("SELECT id FROM tuyen WHERE ten_tuyen = 'Tuyến 01 - Quận 1 đi Quận 5'");
    let tuyenId;
    if (tuyenRes.rows.length === 0) {
      const t = await truyVan(
        "INSERT INTO tuyen (ten_tuyen, xe_id, tai_xe_id, bao_mau_id) VALUES ('Tuyến 01 - Quận 1 đi Quận 5', $1, $2, $3) RETURNING id",
        [xe.rows[0].id, tx.rows[0].id, bm.rows[0].id]
      );
      tuyenId = t.rows[0].id;
      await truyVan(`
        INSERT INTO diem_dung (tuyen_id, thu_tu, ten, vi_do, kinh_do, gio_du_kien) VALUES
        ($1, 1, 'Nhà thờ Đức Bà (Q1)', 10.7798, 106.6990, '06:30'),
        ($1, 2, 'Chợ Bến Thành (Q1)', 10.7725, 106.6980, '06:45'),
        ($1, 3, 'Cổng trường THPT Thực Hành Sài Gòn', 10.7599, 106.6822, '07:05')
      `, [tuyenId]);
    } else {
      tuyenId = tuyenRes.rows[0].id;
    }

    const ddRes = await truyVan('SELECT id FROM diem_dung WHERE tuyen_id = $1 ORDER BY thu_tu ASC', [tuyenId]);
    const diemDung1Id = ddRes.rows[0].id;

    // 5. Tạo 2 Học sinh, gắn Phụ huynh & Xếp vào Tuyến 01
    const hs1 = await truyVan(
      "INSERT INTO hoc_sinh (ma_hs, ho_ten, lop_id) VALUES ('HS001', 'Phạm Gia Bảo', $1) ON CONFLICT (ma_hs) DO UPDATE SET ho_ten = 'Phạm Gia Bảo' RETURNING id",
      [lopId]
    );
    const hs2 = await truyVan(
      "INSERT INTO hoc_sinh (ma_hs, ho_ten, lop_id) VALUES ('HS002', 'Trần Ngọc Minh Châu', $1) ON CONFLICT (ma_hs) DO UPDATE SET ho_ten = 'Trần Ngọc Minh Châu' RETURNING id",
      [lopId]
    );

    await truyVan(
      "INSERT INTO phu_huynh_hoc_sinh (phu_huynh_id, hoc_sinh_id, quan_he) VALUES ($1, $2, 'Bố') ON CONFLICT DO NOTHING",
      [userIds.PHU_HUYNH, hs1.rows[0].id]
    );

    for (const hsId of [hs1.rows[0].id, hs2.rows[0].id]) {
      await truyVan(
        "INSERT INTO dang_ky_tuyen (hoc_sinh_id, tuyen_id, diem_dung_id, chieu) VALUES ($1, $2, $3, 'DON') ON CONFLICT DO NOTHING",
        [hsId, tuyenId, diemDung1Id]
      );
    }

    // 6. Tạo Chuyến đi hôm nay (DON_SANG) để test ngay
    await truyVan(`
      INSERT INTO chuyen_di (tuyen_id, ngay, chieu, trang_thai)
      VALUES ($1, CURRENT_DATE, 'DON', 'CHUA_CHAY')
      ON CONFLICT DO NOTHING
    `, [tuyenId]);

    console.log('THANH CONG! Da nap xong du lieu mau va 4 tai khoan (mat khau: 123456).');
  } catch (err) {
    console.error('Loi nap du lieu:', err);
  } finally {
    await pool.end();
  }
}

napDuLieuMau();
