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

module.exports = router;
