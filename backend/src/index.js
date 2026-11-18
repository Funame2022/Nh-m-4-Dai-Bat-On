require('dotenv').config();
const express = require('express');
const cors = require('cors');
const http = require('node:http');
const { truyVan, pool } = require('./db');
const { ganKenhGiamSat } = require('./giamSatSocket');
const { apDungMigrations } = require('./migrations');

const app = express();
app.use(cors());
app.use(express.json());

app.get('/health', async (req, res) => {
  try {
    await truyVan('SELECT 1');
    res.status(200).json({ status: 'OK', db: 'Connected', project: 'De 7 - Xe Truong - Nhom 4' });
  } catch (err) {
    res.status(500).json({ status: 'ERROR', loi: err.message });
  }
});

app.use('/api/auth', require('./routes/auth'));
app.use('/api/quan-ly', require('./routes/quanLy'));
app.use('/api/van-hanh', require('./routes/vanHanh'));
app.use('/api/phu-huynh', require('./routes/phuHuynh'));
app.use('/api/phu-huynh', require('./routes/thongBao'));

const PORT = process.env.PORT || 3000;
const server = http.createServer(app);
ganKenhGiamSat(server);
apDungMigrations(pool)
  .then(() => server.listen(PORT, () => console.log('Server dang chay tai cong ' + PORT)))
  .catch(async (error) => {
    console.error('Khong the cap nhat co so du lieu:', error.message);
    await pool.end();
    process.exitCode = 1;
  });
