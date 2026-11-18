require('dotenv').config();
const express = require('express');
const cors = require('cors');
const http = require('node:http');
const { truyVan } = require('./db');
const { ganKenhGiamSat } = require('./giamSatSocket');

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

const PORT = process.env.PORT || 3000;
const server = http.createServer(app);
ganKenhGiamSat(server);
server.listen(PORT, () => console.log('Server dang chay tai cong ' + PORT));
