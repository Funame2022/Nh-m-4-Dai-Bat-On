const jwt = require('jsonwebtoken');

function xacThuc(req, res, next) {
  const header = req.headers.authorization || '';
  const token = header.startsWith('Bearer ') ? header.slice(7) : null;
  if (!token) return res.status(401).json({ loi: 'Thieu token xac thuc' });
  try {
    req.nguoiDung = jwt.verify(token, process.env.JWT_SECRET);
    next();
  } catch (e) {
    return res.status(401).json({ loi: 'Token khong hop le hoac da het han' });
  }
}

function choPhep(...vaiTroChoPhep) {
  return (req, res, next) => {
    if (!vaiTroChoPhep.includes(req.nguoiDung.vaiTro)) {
      return res.status(403).json({ loi: 'Khong co quyen thuc hien chuc nang nay' });
    }
    next();
  };
}

module.exports = { xacThuc, choPhep };
