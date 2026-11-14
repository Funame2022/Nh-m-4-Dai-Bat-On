const express = require('express');
const { truyVan } = require('../db');
const { xacThuc, choPhep } = require('../middleware/auth');

const router = express.Router();
router.use(xacThuc, choPhep('PHU_HUYNH'));

router.get('/con-cua-toi', async (req, res) => {
  const kq = await truyVan(`
    SELECT hs.id, hs.ma_hs, hs.ho_ten, hs.anh_url, l.ten_lop, tr.ten AS ten_truong, phhs.quan_he
    FROM phu_huynh_hoc_sinh phhs
    JOIN hoc_sinh hs ON phhs.hoc_sinh_id = hs.id
    JOIN lop l ON hs.lop_id = l.id
    JOIN truong tr ON l.truong_id = tr.id
    WHERE phhs.phu_huynh_id = $1
  `, [req.nguoiDung.id]);
  res.json(kq.rows);
});

router.get('/con/:hocSinhId/theo-doi', async (req, res) => {
  const kq = await truyVan(`
    SELECT cd.id AS chuyen_di_id, cd.chieu, cd.trang_thai, t.ten_tuyen, x.bien_so,
      nd_tx.ho_ten AS ten_tai_xe, nd_tx.sdt AS sdt_tai_xe,
      dd_diem.ten AS ten_diem_dung, dd_diem.gio_du_kien,
      (SELECT vi_do FROM vi_tri_xe WHERE chuyen_di_id = cd.id ORDER BY thoi_diem DESC LIMIT 1) AS vi_do,
      (SELECT kinh_do FROM vi_tri_xe WHERE chuyen_di_id = cd.id ORDER BY thoi_diem DESC LIMIT 1) AS kinh_do,
      (SELECT thoi_diem FROM vi_tri_xe WHERE chuyen_di_id = cd.id ORDER BY thoi_diem DESC LIMIT 1) AS cap_nhat_luc,
      (SELECT json_agg(json_build_object('su_kien', su_kien, 'thoi_diem', thoi_diem))
       FROM diem_danh WHERE chuyen_di_id = cd.id AND hoc_sinh_id = $1) AS lich_su_diem_danh
    FROM dang_ky_tuyen dk
    JOIN chuyen_di cd ON cd.tuyen_id = dk.tuyen_id AND cd.chieu = dk.chieu AND cd.ngay = CURRENT_DATE
    JOIN tuyen t ON cd.tuyen_id = t.id
    JOIN xe x ON t.xe_id = x.id
    JOIN tai_xe tx ON t.tai_xe_id = tx.id
    JOIN nguoi_dung nd_tx ON tx.nguoi_dung_id = nd_tx.id
    JOIN diem_dung dd_diem ON dk.diem_dung_id = dd_diem.id
    WHERE dk.hoc_sinh_id = $1
  `, [req.params.hocSinhId]);
  res.json(kq.rows);
});

router.post('/bao-nghi', async (req, res) => {
  try {
    const { hocSinhId, ngay, lyDo } = req.body;
    const kq = await truyVan(`
      INSERT INTO bao_nghi (hoc_sinh_id, ngay, ly_do, tao_boi)
      VALUES ($1, $2, $3, $4)
      ON CONFLICT (hoc_sinh_id, ngay) DO UPDATE SET ly_do = $3
      RETURNING *
    `, [hocSinhId, ngay, lyDo, req.nguoiDung.id]);
    res.status(201).json(kq.rows[0]);
  } catch (e) { res.status(400).json({ loi: e.message }); }
});

module.exports = router;
