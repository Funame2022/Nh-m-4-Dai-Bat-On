const express = require('express');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const { truyVan } = require('../db');
const { xacThuc } = require('../middleware/auth');

const router = express.Router();

router.post('/dang-nhap', async (req, res) => {
  try {
    const { email, matKhau } = req.body;
    if (!email || !matKhau) return res.status(400).json({ loi: 'Thieu email hoac mat khau' });
    const kq = await truyVan('SELECT * FROM nguoi_dung WHERE email = $1', [email]);
    const user = kq.rows[0];
    if (!user || !(await bcrypt.compare(matKhau, user.mat_khau_hash))) {
      return res.status(401).json({ loi: 'Sai email hoac mat khau' });
    }
    const token = jwt.sign(
      { id: user.id, vaiTro: user.vai_tro, hoTen: user.ho_ten },
      process.env.JWT_SECRET,
      { expiresIn: '7d' }
    );
    res.json({
      token,
      nguoiDung: { id: user.id, email: user.email, hoTen: user.ho_ten, sdt: user.sdt, vaiTro: user.vai_tro }
    });
  } catch (e) {
    res.status(500).json({ loi: e.message });
  }
});

router.get('/toi', xacThuc, async (req, res) => {
  const kq = await truyVan('SELECT id, email, ho_ten, sdt, vai_tro FROM nguoi_dung WHERE id = $1', [req.nguoiDung.id]);
  res.json(kq.rows[0]);
});

router.patch('/toi', xacThuc, async (req, res) => {
  const hoTen = typeof req.body?.hoTen === 'string' ? req.body.hoTen.trim() : '';
  if (!hoTen || hoTen.length > 120) {
    return res.status(400).json({ loi: 'Tên phải có từ 1 đến 120 ký tự' });
  }

  try {
    const kq = await truyVan(
      'UPDATE nguoi_dung SET ho_ten = $1 WHERE id = $2 RETURNING id, email, ho_ten, sdt, vai_tro',
      [hoTen, req.nguoiDung.id],
    );
    if (!kq.rows[0]) return res.status(404).json({ loi: 'Không tìm thấy tài khoản' });
    res.json(kq.rows[0]);
  } catch (_) {
    res.status(500).json({ loi: 'Không thể cập nhật tên tài khoản' });
  }
});

router.patch('/mat-khau', xacThuc, async (req, res) => {
  const { matKhauHienTai, matKhauMoi } = req.body || {};
  if (typeof matKhauHienTai !== 'string' || typeof matKhauMoi !== 'string') {
    return res.status(400).json({ loi: 'Vui lòng nhập mật khẩu hiện tại và mật khẩu mới' });
  }
  if (matKhauMoi.length < 8 || Buffer.byteLength(matKhauMoi, 'utf8') > 72) {
    return res.status(400).json({ loi: 'Mật khẩu mới phải từ 8 đến 72 byte' });
  }

  try {
    const kq = await truyVan(
      'SELECT mat_khau_hash FROM nguoi_dung WHERE id = $1',
      [req.nguoiDung.id],
    );
    if (!kq.rows[0]) return res.status(404).json({ loi: 'Không tìm thấy tài khoản' });
    if (!(await bcrypt.compare(matKhauHienTai, kq.rows[0].mat_khau_hash))) {
      return res.status(400).json({ loi: 'Mật khẩu hiện tại không đúng' });
    }

    const hash = await bcrypt.hash(matKhauMoi, 10);
    await truyVan('UPDATE nguoi_dung SET mat_khau_hash = $1 WHERE id = $2', [
      hash,
      req.nguoiDung.id,
    ]);
    res.json({ thongBao: 'Đã đổi mật khẩu' });
  } catch (_) {
    res.status(500).json({ loi: 'Không thể đổi mật khẩu' });
  }
});

module.exports = router;
