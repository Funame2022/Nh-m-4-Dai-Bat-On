const express = require('express');
const { truyVan } = require('../db');
const { xacThuc, choPhep } = require('../middleware/auth');
const { phatCapNhatGps } = require('../giamSatSocket');

const router = express.Router();
router.use(xacThuc, choPhep('TAI_XE', 'BAO_MAU', 'QUAN_LY'));

// Hàm kiểm tra người dùng có quyền thao tác trên chuyến đi này không
async function kiemTraQuyenChuyen(chuyenId, nguoiDung) {
  if (nguoiDung.vaiTro === 'QUAN_LY') return true;
  const kq = await truyVan(`
    SELECT 1 FROM chuyen_di cd
    JOIN tuyen t ON cd.tuyen_id = t.id
    LEFT JOIN tai_xe tx ON t.tai_xe_id = tx.id
    LEFT JOIN bao_mau bm ON t.bao_mau_id = bm.id
    WHERE cd.id = $1 AND (tx.nguoi_dung_id = $2 OR bm.nguoi_dung_id = $2)
  `, [chuyenId, nguoiDung.id]);
  return kq.rows.length > 0;
}

router.get('/chuyen-hom-nay', async (req, res) => {
  const kq = await truyVan(`
    SELECT cd.*, t.ten_tuyen, x.bien_so
    FROM chuyen_di cd
    JOIN tuyen t ON cd.tuyen_id = t.id
    JOIN xe x ON t.xe_id = x.id
    LEFT JOIN tai_xe tx ON t.tai_xe_id = tx.id
    LEFT JOIN bao_mau bm ON t.bao_mau_id = bm.id
    WHERE cd.ngay = CURRENT_DATE
      AND (tx.nguoi_dung_id = $1 OR bm.nguoi_dung_id = $1 OR $2 = 'QUAN_LY')
    ORDER BY cd.chieu ASC
  `, [req.nguoiDung.id, req.nguoiDung.vaiTro]);
  res.json(kq.rows);
});

router.get('/chuyen/:id', async (req, res) => {
  if (!(await kiemTraQuyenChuyen(req.params.id, req.nguoiDung))) {
    return res.status(403).json({ loi: 'Bạn không được phân công trên chuyến đi này!' });
  }
  const cd = await truyVan(`
    SELECT cd.*, t.ten_tuyen, x.bien_so
    FROM chuyen_di cd JOIN tuyen t ON cd.tuyen_id = t.id JOIN xe x ON t.xe_id = x.id
    WHERE cd.id = $1
  `, [req.params.id]);
  if (!cd.rows[0]) return res.status(404).json({ loi: 'Không tìm thấy chuyến đi' });

  const diemDung = await truyVan('SELECT * FROM diem_dung WHERE tuyen_id = $1 ORDER BY thu_tu ASC', [cd.rows[0].tuyen_id]);
  const hocSinh = await truyVan(`
    SELECT hs.id, hs.ma_hs, hs.ho_ten, hs.anh_url, l.ten_lop, dk.diem_dung_id,
      (SELECT ly_do FROM bao_nghi WHERE hoc_sinh_id = hs.id AND ngay = cd.ngay) AS ly_do_nghi,
      EXISTS(SELECT 1 FROM diem_danh WHERE chuyen_di_id = cd.id AND hoc_sinh_id = hs.id AND su_kien = 'LEN_XE') AS da_len_xe,
      EXISTS(SELECT 1 FROM diem_danh WHERE chuyen_di_id = cd.id AND hoc_sinh_id = hs.id AND su_kien = 'XUONG_XE') AS da_xuong_xe
    FROM dang_ky_tuyen dk
    JOIN hoc_sinh hs ON dk.hoc_sinh_id = hs.id
    JOIN lop l ON hs.lop_id = l.id
    JOIN chuyen_di cd ON cd.id = $1
    WHERE dk.tuyen_id = cd.tuyen_id AND dk.chieu = cd.chieu
    ORDER BY hs.ho_ten ASC
  `, [req.params.id]);

  res.json({ chuyenDi: cd.rows[0], diemDung: diemDung.rows, hocSinh: hocSinh.rows });
});

router.post('/chuyen/:id/bat-dau', async (req, res) => {
  if (!(await kiemTraQuyenChuyen(req.params.id, req.nguoiDung))) {
    return res.status(403).json({ loi: 'Không có quyền bắt đầu chuyến này' });
  }
  const kq = await truyVan(
    "UPDATE chuyen_di SET trang_thai = 'DANG_CHAY', bat_dau_luc = NOW() WHERE id = $1 RETURNING *",
    [req.params.id]
  );
  res.json(kq.rows[0]);
});

router.post('/chuyen/:id/ket-thuc', async (req, res) => {
  if (!(await kiemTraQuyenChuyen(req.params.id, req.nguoiDung))) {
    return res.status(403).json({ loi: 'Không có quyền kết thúc chuyến này' });
  }

  // Kiểm tra TẤT CẢ học sinh đăng ký trên chuyến: phải (Đã lên & Đã xuống) HOẶC (Có đơn báo nghỉ)
  const chuaHoanTat = await truyVan(`
    SELECT hs.ho_ten,
      EXISTS(SELECT 1 FROM diem_danh dd1 WHERE dd1.chuyen_di_id = cd.id AND dd1.hoc_sinh_id = hs.id AND dd1.su_kien = 'LEN_XE') AS da_len,
      EXISTS(SELECT 1 FROM diem_danh dd2 WHERE dd2.chuyen_di_id = cd.id AND dd2.hoc_sinh_id = hs.id AND dd2.su_kien = 'XUONG_XE') AS da_xuong
    FROM chuyen_di cd
    JOIN dang_ky_tuyen dk ON dk.tuyen_id = cd.tuyen_id AND dk.chieu = cd.chieu
    JOIN hoc_sinh hs ON dk.hoc_sinh_id = hs.id
    WHERE cd.id = $1
      AND NOT EXISTS (SELECT 1 FROM bao_nghi bn WHERE bn.hoc_sinh_id = hs.id AND bn.ngay = cd.ngay)
      AND NOT (
        EXISTS(SELECT 1 FROM diem_danh dd1 WHERE dd1.chuyen_di_id = cd.id AND dd1.hoc_sinh_id = hs.id AND dd1.su_kien = 'LEN_XE')
        AND
        EXISTS(SELECT 1 FROM diem_danh dd2 WHERE dd2.chuyen_di_id = cd.id AND dd2.hoc_sinh_id = hs.id AND dd2.su_kien = 'XUONG_XE')
      )
  `, [req.params.id]);

  if (chuaHoanTat.rows.length > 0) {
    const chiTiet = chuaHoanTat.rows.map(
      (r) => `${r.ho_ten} (${r.da_len ? 'chưa xuống xe' : 'chưa điểm danh lên xe'})`
    );
    return res.status(409).json({
      canhBao: 'Không thể kết thúc chuyến vì còn học sinh chưa hoàn tất điểm danh!',
      danhSachChuaHoanTat: chiTiet,
    });
  }

  const kq = await truyVan(
    "UPDATE chuyen_di SET trang_thai = 'HOAN_THANH', ket_thuc_luc = NOW() WHERE id = $1 RETURNING *",
    [req.params.id]
  );
  res.json(kq.rows[0]);
});

router.post('/chuyen/:id/diem-danh', async (req, res) => {
  try {
    if (!(await kiemTraQuyenChuyen(req.params.id, req.nguoiDung))) {
      return res.status(403).json({ loi: 'Không có quyền điểm danh chuyến này' });
    }
    const { hocSinhId, diemDungId, suKien } = req.body;
    const kq = await truyVan(`
      INSERT INTO diem_danh (chuyen_di_id, hoc_sinh_id, diem_dung_id, su_kien)
      VALUES ($1, $2, $3, $4)
      ON CONFLICT (chuyen_di_id, hoc_sinh_id, su_kien) DO UPDATE SET thoi_diem = NOW()
      RETURNING *
    `, [req.params.id, hocSinhId, diemDungId, suKien]);
    res.status(201).json(kq.rows[0]);
  } catch (e) { res.status(400).json({ loi: e.message }); }
});

router.post('/chuyen/:id/vi-tri', async (req, res) => {
  try {
    if (!(await kiemTraQuyenChuyen(req.params.id, req.nguoiDung))) {
      return res.status(403).json({ loi: 'Không có quyền cập nhật vị trí chuyến này' });
    }
    const { viDo, kinhDo } = req.body || {};
    if (
      !Number.isFinite(viDo) ||
      !Number.isFinite(kinhDo) ||
      viDo < -90 || viDo > 90 ||
      kinhDo < -180 || kinhDo > 180
    ) {
      return res.status(400).json({ loi: 'Tọa độ GPS không hợp lệ' });
    }

    const chuyen = await truyVan(
      "SELECT id FROM chuyen_di WHERE id = $1 AND trang_thai = 'DANG_CHAY'",
      [req.params.id],
    );
    if (!chuyen.rows[0]) {
      return res.status(409).json({ loi: 'Chỉ có thể gửi GPS khi chuyến đang chạy' });
    }

    const kq = await truyVan(
      'INSERT INTO vi_tri_xe (chuyen_di_id, vi_do, kinh_do) VALUES ($1, $2, $3) RETURNING *',
      [req.params.id, viDo, kinhDo]
    );
    const viTri = kq.rows[0];
    await phatCapNhatGps({
      chuyen_di_id: viTri.chuyen_di_id,
      vi_do: viTri.vi_do,
      kinh_do: viTri.kinh_do,
      thoi_diem: viTri.thoi_diem,
    });
    res.status(201).json(viTri);
  } catch (e) { res.status(400).json({ loi: e.message }); }
});

module.exports = router;
