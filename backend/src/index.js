require('dotenv').config();
const express = require('express');
const cors = require('cors');
const { truyVan } = require('./db');

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
app.listen(PORT, () => console.log('Server dang chay tai cong ' + PORT));
