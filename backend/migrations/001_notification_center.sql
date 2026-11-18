CREATE TABLE IF NOT EXISTS thong_bao_cai_dat (
  nguoi_dung_id INT NOT NULL REFERENCES nguoi_dung(id) ON DELETE CASCADE,
  loai_su_kien VARCHAR(30) NOT NULL CHECK (
    loai_su_kien IN ('TRIP_STARTED', 'STUDENT_BOARDED', 'STUDENT_DROPPED_OFF', 'TRIP_COMPLETED')
  ),
  bat BOOLEAN NOT NULL DEFAULT TRUE,
  cap_nhat_luc TIMESTAMP NOT NULL DEFAULT NOW(),
  PRIMARY KEY (nguoi_dung_id, loai_su_kien)
);

CREATE TABLE IF NOT EXISTS thong_bao (
  id BIGSERIAL PRIMARY KEY,
  nguoi_nhan_id INT NOT NULL REFERENCES nguoi_dung(id) ON DELETE CASCADE,
  hoc_sinh_id INT NOT NULL REFERENCES hoc_sinh(id) ON DELETE CASCADE,
  chuyen_di_id INT NOT NULL REFERENCES chuyen_di(id) ON DELETE CASCADE,
  loai_su_kien VARCHAR(30) NOT NULL CHECK (
    loai_su_kien IN ('TRIP_STARTED', 'STUDENT_BOARDED', 'STUDENT_DROPPED_OFF', 'TRIP_COMPLETED')
  ),
  tieu_de VARCHAR(160) NOT NULL,
  noi_dung TEXT NOT NULL,
  khoa_chong_trung VARCHAR(180) NOT NULL UNIQUE,
  tao_luc TIMESTAMP NOT NULL DEFAULT NOW(),
  da_doc_luc TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_thong_bao_nguoi_nhan_id
  ON thong_bao (nguoi_nhan_id, id DESC);
