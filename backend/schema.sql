-- =====================================================================
-- SCHEMA CƠ SỞ DỮ LIỆU: HỆ THỐNG QUẢN LÝ XE ĐƯA ĐÓN HỌC SINH (ĐỀ 07)
-- =====================================================================

CREATE TABLE IF NOT EXISTS truong (
  id SERIAL PRIMARY KEY,
  ten VARCHAR(150) NOT NULL,
  dia_chi TEXT
);

CREATE TABLE IF NOT EXISTS lop (
  id SERIAL PRIMARY KEY,
  truong_id INT NOT NULL REFERENCES truong(id) ON DELETE CASCADE,
  ten_lop VARCHAR(50) NOT NULL
);

CREATE TABLE IF NOT EXISTS nguoi_dung (
  id SERIAL PRIMARY KEY,
  email VARCHAR(150) UNIQUE NOT NULL,
  mat_khau_hash TEXT NOT NULL,
  ho_ten VARCHAR(120) NOT NULL,
  sdt VARCHAR(20),
  vai_tro VARCHAR(20) NOT NULL CHECK (vai_tro IN ('QUAN_LY', 'TAI_XE', 'BAO_MAU', 'PHU_HUYNH')),
  tao_luc TIMESTAMP DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS tai_xe (
  id SERIAL PRIMARY KEY,
  nguoi_dung_id INT UNIQUE NOT NULL REFERENCES nguoi_dung(id) ON DELETE CASCADE,
  so_gplx VARCHAR(50) NOT NULL,
  han_gplx DATE
);

CREATE TABLE IF NOT EXISTS bao_mau (
  id SERIAL PRIMARY KEY,
  nguoi_dung_id INT UNIQUE NOT NULL REFERENCES nguoi_dung(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS xe (
  id SERIAL PRIMARY KEY,
  bien_so VARCHAR(30) UNIQUE NOT NULL,
  suc_chua INT NOT NULL DEFAULT 29,
  han_dang_kiem DATE
);

CREATE TABLE IF NOT EXISTS tuyen (
  id SERIAL PRIMARY KEY,
  ten_tuyen VARCHAR(150) NOT NULL,
  xe_id INT NOT NULL REFERENCES xe(id),
  tai_xe_id INT NOT NULL REFERENCES tai_xe(id),
  bao_mau_id INT REFERENCES bao_mau(id)
);

CREATE TABLE IF NOT EXISTS diem_dung (
  id SERIAL PRIMARY KEY,
  tuyen_id INT NOT NULL REFERENCES tuyen(id) ON DELETE CASCADE,
  thu_tu INT NOT NULL,
  ten VARCHAR(150) NOT NULL,
  vi_do DOUBLE PRECISION NOT NULL,
  kinh_do DOUBLE PRECISION NOT NULL,
  gio_du_kien VARCHAR(10)
);

CREATE TABLE IF NOT EXISTS hoc_sinh (
  id SERIAL PRIMARY KEY,
  ma_hs VARCHAR(30) UNIQUE NOT NULL,
  ho_ten VARCHAR(120) NOT NULL,
  lop_id INT NOT NULL REFERENCES lop(id),
  anh_url TEXT
);

CREATE TABLE IF NOT EXISTS phu_huynh_hoc_sinh (
  phu_huynh_id INT NOT NULL REFERENCES nguoi_dung(id) ON DELETE CASCADE,
  hoc_sinh_id INT NOT NULL REFERENCES hoc_sinh(id) ON DELETE CASCADE,
  quan_he VARCHAR(50) DEFAULT 'PHU_HUYNH',
  PRIMARY KEY (phu_huynh_id, hoc_sinh_id)
);

CREATE TABLE IF NOT EXISTS dang_ky_tuyen (
  hoc_sinh_id INT NOT NULL REFERENCES hoc_sinh(id) ON DELETE CASCADE,
  tuyen_id INT NOT NULL REFERENCES tuyen(id) ON DELETE CASCADE,
  diem_dung_id INT NOT NULL REFERENCES diem_dung(id),
  chieu VARCHAR(20) NOT NULL CHECK (chieu IN ('DON_SANG', 'TRA_CHIEU')),
  PRIMARY KEY (hoc_sinh_id, chieu)
);

CREATE TABLE IF NOT EXISTS chuyen_di (
  id SERIAL PRIMARY KEY,
  tuyen_id INT NOT NULL REFERENCES tuyen(id),
  ngay DATE NOT NULL DEFAULT CURRENT_DATE,
  chieu VARCHAR(20) NOT NULL CHECK (chieu IN ('DON_SANG', 'TRA_CHIEU')),
  trang_thai VARCHAR(20) NOT NULL DEFAULT 'CHUA_CHAY' CHECK (trang_thai IN ('CHUA_CHAY', 'DANG_CHAY', 'HOAN_THANH')),
  bat_dau_luc TIMESTAMP,
  ket_thuc_luc TIMESTAMP,
  UNIQUE (tuyen_id, ngay, chieu)
);

CREATE TABLE IF NOT EXISTS diem_danh (
  id SERIAL PRIMARY KEY,
  chuyen_di_id INT NOT NULL REFERENCES chuyen_di(id) ON DELETE CASCADE,
  hoc_sinh_id INT NOT NULL REFERENCES hoc_sinh(id) ON DELETE CASCADE,
  diem_dung_id INT REFERENCES diem_dung(id),
  su_kien VARCHAR(20) NOT NULL CHECK (su_kien IN ('LEN_XE', 'XUONG_XE')),
  thoi_diem TIMESTAMP DEFAULT NOW(),
  UNIQUE (chuyen_di_id, hoc_sinh_id, su_kien)
);

CREATE TABLE IF NOT EXISTS vi_tri_xe (
  id SERIAL PRIMARY KEY,
  chuyen_di_id INT NOT NULL REFERENCES chuyen_di(id) ON DELETE CASCADE,
  vi_do DOUBLE PRECISION NOT NULL,
  kinh_do DOUBLE PRECISION NOT NULL,
  thoi_diem TIMESTAMP DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS bao_nghi (
  id SERIAL PRIMARY KEY,
  hoc_sinh_id INT NOT NULL REFERENCES hoc_sinh(id) ON DELETE CASCADE,
  ngay DATE NOT NULL,
  ly_do TEXT,
  tao_boi INT REFERENCES nguoi_dung(id),
  UNIQUE (hoc_sinh_id, ngay)
);