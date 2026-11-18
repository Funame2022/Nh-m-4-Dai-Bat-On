const express = require('express');
const { truyVan, trongGiaoDich } = require('../db');
const { xacThuc, choPhep } = require('../middleware/auth');
const { CAC_LOAI_THONG_BAO } = require('../thongBao');

const router = express.Router();
router.use(xacThuc, choPhep('PHU_HUYNH'));

function laIdDuong(giaTri) {
  return typeof giaTri === 'string' && /^[1-9]\d*$/.test(giaTri) &&
    Number.isSafeInteger(Number(giaTri));
}

function taoTuyChon(rows) {
  return Object.fromEntries(CAC_LOAI_THONG_BAO.map((loai) => [
    loai,
    rows.find((row) => row.loai_su_kien === loai)?.bat ?? true,
  ]));
}

router.get('/thong-bao', async (req, res) => {
  const limitText = req.query.limit ?? '50';
  const beforeText = req.query.before;
  if (
    typeof limitText !== 'string' || !/^\d+$/.test(limitText) ||
    Number(limitText) < 1 || Number(limitText) > 100 ||
    (beforeText !== undefined && !laIdDuong(beforeText))
  ) {
    return res.status(400).json({ loi: 'Bộ lọc thông báo không hợp lệ' });
  }

  try {
    const [notifications, count] = await Promise.all([
      truyVan(`
        SELECT id, hoc_sinh_id, chuyen_di_id, loai_su_kien,
          tieu_de, noi_dung, tao_luc, da_doc_luc
        FROM thong_bao
        WHERE nguoi_nhan_id = $1
          AND ($2::BIGINT IS NULL OR id < $2)
        ORDER BY id DESC
        LIMIT $3
      `, [req.nguoiDung.id, beforeText ?? null, Number(limitText)]),
      truyVan(`
        SELECT COUNT(*)::INTEGER AS so_chua_doc
        FROM thong_bao
        WHERE nguoi_nhan_id = $1 AND da_doc_luc IS NULL
      `, [req.nguoiDung.id]),
    ]);
    res.json({
      notifications: notifications.rows,
      unreadCount: count.rows[0]?.so_chua_doc ?? 0,
    });
  } catch (error) {
    res.status(500).json({ loi: 'Không thể tải hộp thư thông báo' });
  }
});

router.get('/thong-bao/cai-dat', async (req, res) => {
  try {
    const kq = await truyVan(
      'SELECT loai_su_kien, bat FROM thong_bao_cai_dat WHERE nguoi_dung_id = $1',
      [req.nguoiDung.id],
    );
    res.json({ preferences: taoTuyChon(kq.rows) });
  } catch (error) {
    res.status(500).json({ loi: 'Không thể tải cài đặt thông báo' });
  }
});

router.put('/thong-bao/cai-dat', async (req, res) => {
  const preferences = req.body?.preferences;
  if (
    !preferences || typeof preferences !== 'object' || Array.isArray(preferences) ||
    Object.keys(preferences).length === 0 ||
    Object.entries(preferences).some(([loai, bat]) =>
      !CAC_LOAI_THONG_BAO.includes(loai) || typeof bat !== 'boolean')
  ) {
    return res.status(400).json({ loi: 'Cài đặt thông báo không hợp lệ' });
  }

  try {
    await trongGiaoDich(async (client) => {
      for (const [loai, bat] of Object.entries(preferences)) {
        await client.query(`
          INSERT INTO thong_bao_cai_dat (nguoi_dung_id, loai_su_kien, bat)
          VALUES ($1, $2, $3)
          ON CONFLICT (nguoi_dung_id, loai_su_kien)
          DO UPDATE SET bat = EXCLUDED.bat, cap_nhat_luc = NOW()
        `, [req.nguoiDung.id, loai, bat]);
      }
    });
    const kq = await truyVan(
      'SELECT loai_su_kien, bat FROM thong_bao_cai_dat WHERE nguoi_dung_id = $1',
      [req.nguoiDung.id],
    );
    res.json({ preferences: taoTuyChon(kq.rows) });
  } catch (error) {
    res.status(500).json({ loi: 'Không thể lưu cài đặt thông báo' });
  }
});

router.patch('/thong-bao/doc-tat-ca', async (req, res) => {
  try {
    const kq = await truyVan(`
      UPDATE thong_bao SET da_doc_luc = NOW()
      WHERE nguoi_nhan_id = $1 AND da_doc_luc IS NULL
    `, [req.nguoiDung.id]);
    res.json({ updatedCount: kq.rowCount ?? 0 });
  } catch (error) {
    res.status(500).json({ loi: 'Không thể đánh dấu thông báo đã đọc' });
  }
});

router.patch('/thong-bao/:id/doc', async (req, res) => {
  if (!laIdDuong(req.params.id)) {
    return res.status(400).json({ loi: 'Mã thông báo không hợp lệ' });
  }
  try {
    const kq = await truyVan(`
      UPDATE thong_bao SET da_doc_luc = COALESCE(da_doc_luc, NOW())
      WHERE id = $1 AND nguoi_nhan_id = $2
      RETURNING id, da_doc_luc
    `, [req.params.id, req.nguoiDung.id]);
    if (!kq.rows[0]) return res.status(404).json({ loi: 'Không tìm thấy thông báo' });
    res.json(kq.rows[0]);
  } catch (error) {
    res.status(500).json({ loi: 'Không thể đánh dấu thông báo đã đọc' });
  }
});

module.exports = router;
