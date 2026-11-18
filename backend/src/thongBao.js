const CAC_LOAI = Object.freeze({
  TRIP_STARTED: {
    title: 'Chuyến xe đã bắt đầu',
    body: (name, route) => `Xe buýt tuyến ${route} đã bắt đầu chuyến.`,
  },
  STUDENT_BOARDED: {
    title: 'Học sinh đã lên xe',
    body: (name, route) => `${name} đã lên xe buýt tuyến ${route}.`,
  },
  STUDENT_DROPPED_OFF: {
    title: 'Học sinh đã xuống xe',
    body: (name, route) => `${name} đã xuống xe buýt tuyến ${route}.`,
  },
  TRIP_COMPLETED: {
    title: 'Chuyến xe đã hoàn tất',
    body: (name, route) => `Chuyến xe tuyến ${route} đã hoàn tất.`,
  },
});

const CAC_LOAI_THONG_BAO = Object.freeze(Object.keys(CAC_LOAI));

async function taoThongBaoChoChuyen(db, { chuyenId, loai, hocSinhId = null }) {
  const mau = CAC_LOAI[loai];
  if (!mau) throw new TypeError('Loại thông báo không hợp lệ');

  const nguoiNhan = await db.query(`
    SELECT DISTINCT phhs.phu_huynh_id, hs.id AS hoc_sinh_id,
      hs.ho_ten, t.ten_tuyen
    FROM chuyen_di cd
    JOIN dang_ky_tuyen dk ON dk.tuyen_id = cd.tuyen_id AND dk.chieu = cd.chieu
    JOIN hoc_sinh hs ON hs.id = dk.hoc_sinh_id
    JOIN phu_huynh_hoc_sinh phhs ON phhs.hoc_sinh_id = hs.id
    JOIN tuyen t ON t.id = cd.tuyen_id
    WHERE cd.id = $1
      AND ($2::INTEGER IS NULL OR hs.id = $2)
      AND NOT EXISTS (
        SELECT 1 FROM thong_bao_cai_dat tc
        WHERE tc.nguoi_dung_id = phhs.phu_huynh_id
          AND tc.loai_su_kien = $3 AND tc.bat = FALSE
      )
      AND (
        $3 <> 'TRIP_STARTED' OR NOT EXISTS (
          SELECT 1 FROM bao_nghi bn
          WHERE bn.hoc_sinh_id = hs.id AND bn.ngay = cd.ngay
        )
      )
      AND (
        $3 <> 'TRIP_COMPLETED' OR EXISTS (
          SELECT 1 FROM diem_danh dd
          WHERE dd.chuyen_di_id = cd.id
            AND dd.hoc_sinh_id = hs.id
            AND dd.su_kien = 'XUONG_XE'
        )
      )
  `, [chuyenId, hocSinhId, loai]);

  for (const nguoi of nguoiNhan.rows) {
    await db.query(`
      INSERT INTO thong_bao (
        nguoi_nhan_id, hoc_sinh_id, chuyen_di_id, loai_su_kien,
        tieu_de, noi_dung, khoa_chong_trung
      ) VALUES ($1, $2, $3, $4, $5, $6, $7)
      ON CONFLICT (khoa_chong_trung) DO NOTHING
    `, [
      nguoi.phu_huynh_id,
      nguoi.hoc_sinh_id,
      chuyenId,
      loai,
      mau.title,
      mau.body(nguoi.ho_ten, nguoi.ten_tuyen),
      `${nguoi.phu_huynh_id}:${chuyenId}:${nguoi.hoc_sinh_id}:${loai}`,
    ]);
  }
}

module.exports = { CAC_LOAI, CAC_LOAI_THONG_BAO, taoThongBaoChoChuyen };
