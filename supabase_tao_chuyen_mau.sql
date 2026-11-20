-- =====================================================================
-- SCRIPT SUPABASE: TẠO CHUYẾN ĐI VẬN HÀNH & ĐIỂM DANH HÔM NAY (ĐỀ 07)
-- Hướng dẫn: Mở Supabase -> SQL Editor -> Dán toàn bộ script này và nhấn RUN.
-- =====================================================================

DO $$
DECLARE
  v_tuyen_id INT;
  v_chieu_don VARCHAR(20) := 'DON';
  v_chieu_tra VARCHAR(20) := 'TRA';
  v_diem_dung_id INT;
  v_hs1_id INT;
  v_hs2_id INT;
BEGIN
  -- 1. Lấy tuyến đầu tiên trong hệ thống
  SELECT id INTO v_tuyen_id FROM tuyen ORDER BY id LIMIT 1;
  
  IF v_tuyen_id IS NULL THEN
    RAISE NOTICE 'Chưa có tuyến xe nào trong CSDL. Vui lòng tạo tuyến trước.';
    RETURN;
  END IF;

  -- 2. Thêm chuyến ĐÓN hôm nay nếu chưa có (dùng NOT EXISTS, không dùng ON CONFLICT để tương thích mọi schema)
  IF NOT EXISTS (
    SELECT 1 FROM chuyen_di 
    WHERE tuyen_id = v_tuyen_id AND ngay = CURRENT_DATE AND (chieu = 'DON' OR chieu = 'DON_SANG')
  ) THEN
    BEGIN
      INSERT INTO chuyen_di (tuyen_id, ngay, chieu, trang_thai)
      VALUES (v_tuyen_id, CURRENT_DATE, 'DON', 'CHUA_CHAY');
      v_chieu_don := 'DON';
      v_chieu_tra := 'TRA';
    EXCEPTION WHEN check_violation THEN
      INSERT INTO chuyen_di (tuyen_id, ngay, chieu, trang_thai)
      VALUES (v_tuyen_id, CURRENT_DATE, 'DON_SANG', 'CHUA_CHAY');
      v_chieu_don := 'DON_SANG';
      v_chieu_tra := 'TRA_CHIEU';
    END;
  ELSE
    SELECT chieu INTO v_chieu_don FROM chuyen_di 
    WHERE tuyen_id = v_tuyen_id AND ngay = CURRENT_DATE AND (chieu = 'DON' OR chieu = 'DON_SANG')
    LIMIT 1;
    IF v_chieu_don = 'DON' THEN v_chieu_tra := 'TRA'; ELSE v_chieu_tra := 'TRA_CHIEU'; END IF;
  END IF;

  -- 3. Thêm chuyến TRẢ hôm nay nếu chưa có
  IF NOT EXISTS (
    SELECT 1 FROM chuyen_di 
    WHERE tuyen_id = v_tuyen_id AND ngay = CURRENT_DATE AND (chieu = 'TRA' OR chieu = 'TRA_CHIEU')
  ) THEN
    BEGIN
      INSERT INTO chuyen_di (tuyen_id, ngay, chieu, trang_thai)
      VALUES (v_tuyen_id, CURRENT_DATE, v_chieu_tra, 'CHUA_CHAY');
    EXCEPTION WHEN OTHERS THEN
      NULL;
    END;
  END IF;

  -- 4. Lấy điểm dừng đầu tiên của tuyến
  SELECT id INTO v_diem_dung_id FROM diem_dung WHERE tuyen_id = v_tuyen_id ORDER BY thu_tu LIMIT 1;

  -- 5. Lấy danh sách học sinh mẫu HS001, HS002
  SELECT id INTO v_hs1_id FROM hoc_sinh WHERE ma_hs = 'HS001';
  SELECT id INTO v_hs2_id FROM hoc_sinh WHERE ma_hs = 'HS002';

  -- 6. Gán học sinh vào tuyến & điểm dừng nếu chưa gán
  IF v_hs1_id IS NOT NULL AND v_diem_dung_id IS NOT NULL THEN
    IF NOT EXISTS (
      SELECT 1 FROM dang_ky_tuyen 
      WHERE hoc_sinh_id = v_hs1_id AND (chieu = 'DON' OR chieu = 'DON_SANG')
    ) THEN
      BEGIN
        INSERT INTO dang_ky_tuyen (hoc_sinh_id, tuyen_id, diem_dung_id, chieu)
        VALUES (v_hs1_id, v_tuyen_id, v_diem_dung_id, v_chieu_don);
      EXCEPTION WHEN OTHERS THEN NULL;
      END;
    END IF;
  END IF;

  IF v_hs2_id IS NOT NULL AND v_diem_dung_id IS NOT NULL THEN
    IF NOT EXISTS (
      SELECT 1 FROM dang_ky_tuyen 
      WHERE hoc_sinh_id = v_hs2_id AND (chieu = 'DON' OR chieu = 'DON_SANG')
    ) THEN
      BEGIN
        INSERT INTO dang_ky_tuyen (hoc_sinh_id, tuyen_id, diem_dung_id, chieu)
        VALUES (v_hs2_id, v_tuyen_id, v_diem_dung_id, v_chieu_don);
      EXCEPTION WHEN OTHERS THEN NULL;
      END;
    END IF;
  END IF;

  RAISE NOTICE 'Hoàn tất khởi tạo dữ liệu chuyến đi hôm nay thành công!';
END $$;

-- Xem danh sách chuyến đi hôm nay
SELECT cd.id, cd.ngay, cd.chieu, cd.trang_thai, t.ten_tuyen, x.bien_so
FROM chuyen_di cd
JOIN tuyen t ON cd.tuyen_id = t.id
JOIN xe x ON t.xe_id = x.id
WHERE cd.ngay = CURRENT_DATE;
