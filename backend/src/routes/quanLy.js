const express = require('express');
const bcrypt = require('bcryptjs');
const { truyVan, trongGiaoDich } = require('../db');
const { xacThuc, choPhep } = require('../middleware/auth');

const router = express.Router();
router.use(xacThuc, choPhep('QUAN_LY'));

// ================= 1. QUẢN LÝ TÀI XẾ & BẢO MẪU =================
router.get('/tai-xe', async (req, res) => {
  const kq = await truyVan(`
    SELECT tx.id, tx.nguoi_dung_id, nd.ho_ten, nd.email, nd.sdt, tx.so_gplx, tx.han_gplx
    FROM tai_xe tx
    JOIN nguoi_dung nd ON tx.nguoi_dung_id = nd.id
    ORDER BY tx.id DESC
  `);
  res.json(kq.rows);
});

router.post('/tai-xe', async (req, res) => {
  try {
    const { email, matKhau, hoTen, sdt, soGplx, hanGplx } = req.body;
    const hash = await bcrypt.hash(matKhau || '123456', 10);
    const kq = await trongGiaoDich(async (client) => {
      const nd = await client.query(
        `INSERT INTO nguoi_dung (email, mat_khau_hash, ho_ten, sdt, vai_tro)
         VALUES ($1, $2, $3, $4, 'TAI_XE') RETURNING id, email, ho_ten, sdt`,
        [email, hash, hoTen, sdt]
      );
      const tx = await client.query(
        `INSERT INTO tai_xe (nguoi_dung_id, so_gplx, han_gplx)
         VALUES ($1, $2, $3) RETURNING *`,
        [nd.rows[0].id, soGplx, hanGplx]
      );
      return { ...tx.rows[0], ...nd.rows[0], id: tx.rows[0].id, nguoi_dung_id: nd.rows[0].id };
    });
    res.status(201).json(kq);
  } catch (e) { res.status(400).json({ loi: e.message }); }
});

router.put('/tai-xe/:id', async (req, res) => {
  try {
    const { hoTen, sdt, soGplx, hanGplx } = req.body;
    const kq = await trongGiaoDich(async (client) => {
      const tx = await client.query(
        'UPDATE tai_xe SET so_gplx = $1, han_gplx = $2 WHERE id = $3 RETURNING *',
        [soGplx, hanGplx, req.params.id]
      );
      if (!tx.rows[0]) throw new Error('Không tìm thấy tài xế');
      await client.query(
        'UPDATE nguoi_dung SET ho_ten = $1, sdt = $2 WHERE id = $3',
        [hoTen, sdt, tx.rows[0].nguoi_dung_id]
      );
      return tx.rows[0];
    });
    res.json(kq);
  } catch (e) { res.status(400).json({ loi: e.message }); }
});

router.delete('/tai-xe/:id', async (req, res) => {
  try {
    const tx = await truyVan('SELECT nguoi_dung_id FROM tai_xe WHERE id = $1', [req.params.id]);
    if (!tx.rows[0]) return res.status(404).json({ loi: 'Không tìm thấy tài xế' });
    await truyVan('DELETE FROM tai_xe WHERE id = $1', [req.params.id]);
    await truyVan('DELETE FROM nguoi_dung WHERE id = $1', [tx.rows[0].nguoi_dung_id]);
    res.json({ thongBao: 'Đã xóa tài xế' });
  } catch (e) { res.status(400).json({ loi: e.message }); }
});

router.get('/bao-mau', async (req, res) => {
  const kq = await truyVan(`
    SELECT bm.id, bm.nguoi_dung_id, nd.ho_ten, nd.email, nd.sdt
    FROM bao_mau bm
    JOIN nguoi_dung nd ON bm.nguoi_dung_id = nd.id
    ORDER BY bm.id DESC
  `);
  res.json(kq.rows);
});

// ================= 2. QUẢN LÝ XE (CRUD ĐẦY ĐỦ) =================
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

router.put('/xe/:id', async (req, res) => {
  try {
    const { bienSo, sucChua, hanDangKiem } = req.body;
    const kq = await truyVan(
      'UPDATE xe SET bien_so = $1, suc_chua = $2, han_dang_kiem = $3 WHERE id = $4 RETURNING *',
      [bienSo, sucChua, hanDangKiem, req.params.id]
    );
    if (!kq.rows[0]) return res.status(404).json({ loi: 'Không tìm thấy xe' });
    res.json(kq.rows[0]);
  } catch (e) { res.status(400).json({ loi: e.message }); }
});

router.delete('/xe/:id', async (req, res) => {
  try {
    await truyVan('DELETE FROM xe WHERE id = $1', [req.params.id]);
    res.json({ thongBao: 'Đã xóa xe' });
  } catch (e) { res.status(400).json({ loi: e.message }); }
});

// ================= 3. QUẢN LÝ TUYẾN & ĐIỂM DỪNG =================
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

router.put('/tuyen/:id', async (req, res) => {
  try {
    const { tenTuyen, xeId, taiXeId, baoMauId } = req.body;
    const kq = await truyVan(
      'UPDATE tuyen SET ten_tuyen = $1, xe_id = $2, tai_xe_id = $3, bao_mau_id = $4 WHERE id = $5 RETURNING *',
      [tenTuyen, xeId, taiXeId, baoMauId || null, req.params.id]
    );
    if (!kq.rows[0]) return res.status(404).json({ loi: 'Không tìm thấy tuyến' });
    res.json(kq.rows[0]);
  } catch (e) { res.status(400).json({ loi: e.message }); }
});

router.delete('/tuyen/:id', async (req, res) => {
  try {
    await truyVan('DELETE FROM diem_dung WHERE tuyen_id = $1', [req.params.id]);
    await truyVan('DELETE FROM tuyen WHERE id = $1', [req.params.id]);
    res.json({ thongBao: 'Đã xóa tuyến' });
  } catch (e) { res.status(400).json({ loi: e.message }); }
});

// ================= 4. HỌC SINH, CHUYẾN ĐI & GIÁM SÁT =================
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

router.post('/chuyen-di', async (req, res) => {
  try {
    const { tuyenId, ngay, chieu } = req.body;
    const kq = await truyVan(`
      INSERT INTO chuyen_di (tuyen_id, ngay, chieu, trang_thai)
      VALUES ($1, COALESCE($2::date, CURRENT_DATE), $3, 'CHUA_CHAY')
      RETURNING *
    `, [tuyenId, ngay || null, chieu || 'DON_SANG']);
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

// ================= 5. BÁO CÁO THỐNG KÊ =================
router.get('/thong-ke', async (req, res) => {
  const ngay = req.query.ngay || null;
  const kq = await truyVan(`
    SELECT
      (SELECT COUNT(*)::int FROM xe) AS tong_xe,
      (SELECT COUNT(*)::int FROM tuyen) AS tong_tuyen,
      (SELECT COUNT(*)::int FROM hoc_sinh) AS tong_hoc_sinh,
      (SELECT COUNT(*)::int FROM chuyen_di WHERE ngay = COALESCE($1::date, CURRENT_DATE)) AS tong_chuyen_ngay,
      (SELECT COUNT(*)::int FROM chuyen_di WHERE ngay = COALESCE($1::date, CURRENT_DATE) AND trang_thai = 'HOAN_THANH') AS chuyen_hoan_thanh,
      (SELECT COUNT(*)::int FROM bao_nghi WHERE ngay = COALESCE($1::date, CURRENT_DATE)) AS so_bao_nghi,
      (SELECT COUNT(DISTINCT dd.hoc_sinh_id)::int FROM diem_danh dd
        JOIN chuyen_di cd ON dd.chuyen_di_id = cd.id
        WHERE cd.ngay = COALESCE($1::date, CURRENT_DATE) AND dd.su_kien = 'LEN_XE') AS so_da_len_xe
  `, [ngay]);
  res.json(kq.rows[0]);
});

module.exports = router;