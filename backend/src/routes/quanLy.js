const express = require('express');
const { truyVan, trongGiaoDich } = require('../db');
const { xacThuc, choPhep } = require('../middleware/auth');

const router = express.Router();
router.use(xacThuc, choPhep('QUAN_LY'));

router.get('/xe', async (req, res) => {
  const kq = await truyVan('SELECT * FROM xe ORDER BY id DESC');
  res.json(kq.rows);
});

router.post('/xe', async (req, res) => {
  try {
    const { bienSo, sucChua, hanDangKiem } = req.body;
    const kq = await truyVan(
      'INSERT INTO xe (bien_so, suc_chua, han_dang_kiem) VALUES ($1, $2, $3) RETURNING *',
      [bienSo, sucChua, hanDangKiem]
    );
    res.status(201).json(kq.rows[0]);
  } catch (e) { res.status(400).json({ loi: e.message }); }
});

router.get('/tuyen', async (req, res) => {
  const kq = await truyVan(`
    SELECT t.*, x.bien_so, nd_tx.ho_ten AS ten_tai_xe, nd_bm.ho_ten AS ten_bao_mau
    FROM tuyen t
    JOIN xe x ON t.xe_id = x.id
    JOIN tai_xe tx ON t.tai_xe_id = tx.id
    JOIN nguoi_dung nd_tx ON tx.nguoi_dung_id = nd_tx.id
    LEFT JOIN bao_mau bm ON t.bao_mau_id = bm.id
    LEFT JOIN nguoi_dung nd_bm ON bm.nguoi_dung_id = nd_bm.id
    ORDER BY t.id DESC
  `);
  res.json(kq.rows);
});

router.get('/tuyen/:id/diem-dung', async (req, res) => {
  const kq = await truyVan('SELECT * FROM diem_dung WHERE tuyen_id = $1 ORDER BY thu_tu ASC', [req.params.id]);
  res.json(kq.rows);
});

router.post('/tuyen', async (req, res) => {
  try {
    const { tenTuyen, xeId, taiXeId, baoMauId, danhSachDiemDung } = req.body;
    const tuyen = await trongGiaoDich(async (client) => {
      const r = await client.query(
        'INSERT INTO tuyen (ten_tuyen, xe_id, tai_xe_id, bao_mau_id) VALUES ($1, $2, $3, $4) RETURNING *',
        [tenTuyen, xeId, taiXeId, baoMauId || null]
      );
      if (Array.isArray(danhSachDiemDung)) {
        for (const dd of danhSachDiemDung) {
          await client.query(
            'INSERT INTO diem_dung (tuyen_id, thu_tu, ten, vi_do, kinh_do, gio_du_kien) VALUES ($1, $2, $3, $4, $5, $6)',
            [r.rows[0].id, dd.thuTu, dd.ten, dd.viDo, dd.kinhDo, dd.gioDuKien]
          );
        }
      }
      return r.rows[0];
    });
    res.status(201).json(tuyen);
  } catch (e) { res.status(400).json({ loi: e.message }); }
});

router.get('/hoc-sinh', async (req, res) => {
  const kq = await truyVan(`
    SELECT hs.*, l.ten_lop, tr.ten AS ten_truong
    FROM hoc_sinh hs
    JOIN lop l ON hs.lop_id = l.id
    JOIN truong tr ON l.truong_id = tr.id
    ORDER BY hs.id DESC
  `);
  res.json(kq.rows);
});

router.post('/hoc-sinh', async (req, res) => {
  try {
    const { maHs, hoTen, lopId, anhUrl } = req.body;
    const kq = await truyVan(
      'INSERT INTO hoc_sinh (ma_hs, ho_ten, lop_id, anh_url) VALUES ($1, $2, $3, $4) RETURNING *',
      [maHs, hoTen, lopId, anhUrl || null]
    );
    res.status(201).json(kq.rows[0]);
  } catch (e) { res.status(400).json({ loi: e.message }); }
});

router.post('/dang-ky-tuyen', async (req, res) => {
  try {
    const { hocSinhId, tuyenId, diemDungId, chieu } = req.body;
    const kq = await truyVan(`
      INSERT INTO dang_ky_tuyen (hoc_sinh_id, tuyen_id, diem_dung_id, chieu)
      VALUES ($1, $2, $3, $4)
      ON CONFLICT (hoc_sinh_id, chieu) DO UPDATE SET tuyen_id = $2, diem_dung_id = $3
      RETURNING *
    `, [hocSinhId, tuyenId, diemDungId, chieu]);
    res.status(201).json(kq.rows[0]);
  } catch (e) { res.status(400).json({ loi: e.message }); }
});

router.get('/giam-sat', async (req, res) => {
  const chuyen = await truyVan(`
    SELECT cd.*, t.ten_tuyen, x.bien_so,
      (SELECT vi_do FROM vi_tri_xe WHERE chuyen_di_id = cd.id ORDER BY thoi_diem DESC LIMIT 1) AS vi_do,
      (SELECT kinh_do FROM vi_tri_xe WHERE chuyen_di_id = cd.id ORDER BY thoi_diem DESC LIMIT 1) AS kinh_do
    FROM chuyen_di cd
    JOIN tuyen t ON cd.tuyen_id = t.id
    JOIN xe x ON t.xe_id = x.id
    WHERE cd.ngay = CURRENT_DATE
    ORDER BY cd.id DESC
  `);
  res.json(chuyen.rows);
});

module.exports = router;
