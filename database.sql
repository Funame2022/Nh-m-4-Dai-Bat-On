-- WARNING: This schema is for context only and is not meant to be run.
-- Table order and constraints may not be valid for execution.

CREATE TABLE public.nguoi_dung (
  id integer NOT NULL DEFAULT nextval('nguoi_dung_id_seq'::regclass),
  email character varying NOT NULL UNIQUE,
  mat_khau_hash character varying NOT NULL,
  ho_ten character varying NOT NULL,
  sdt character varying NOT NULL UNIQUE,
  vai_tro character varying NOT NULL CHECK (vai_tro::text = ANY (ARRAY['QUAN_LY'::character varying, 'TAI_XE'::character varying, 'BAO_MAU'::character varying, 'PHU_HUYNH'::character varying]::text[])),
  tao_luc timestamp without time zone DEFAULT now(),
  CONSTRAINT nguoi_dung_pkey PRIMARY KEY (id)
);
CREATE TABLE public.truong (
  id integer NOT NULL DEFAULT nextval('truong_id_seq'::regclass),
  ten character varying NOT NULL,
  dia_chi text NOT NULL,
  CONSTRAINT truong_pkey PRIMARY KEY (id)
);
CREATE TABLE public.lop (
  id integer NOT NULL DEFAULT nextval('lop_id_seq'::regclass),
  truong_id integer NOT NULL,
  ten_lop character varying NOT NULL,
  CONSTRAINT lop_pkey PRIMARY KEY (id),
  CONSTRAINT lop_truong_id_fkey FOREIGN KEY (truong_id) REFERENCES public.truong(id)
);
CREATE TABLE public.hoc_sinh (
  id integer NOT NULL DEFAULT nextval('hoc_sinh_id_seq'::regclass),
  ma_hs character varying NOT NULL UNIQUE,
  ho_ten character varying NOT NULL,
  lop_id integer NOT NULL,
  anh_url text,
  CONSTRAINT hoc_sinh_pkey PRIMARY KEY (id),
  CONSTRAINT hoc_sinh_lop_id_fkey FOREIGN KEY (lop_id) REFERENCES public.lop(id)
);
CREATE TABLE public.phu_huynh_hoc_sinh (
  phu_huynh_id integer NOT NULL,
  hoc_sinh_id integer NOT NULL,
  quan_he character varying NOT NULL,
  CONSTRAINT phu_huynh_hoc_sinh_pkey PRIMARY KEY (phu_huynh_id, hoc_sinh_id),
  CONSTRAINT phu_huynh_hoc_sinh_phu_huynh_id_fkey FOREIGN KEY (phu_huynh_id) REFERENCES public.nguoi_dung(id),
  CONSTRAINT phu_huynh_hoc_sinh_hoc_sinh_id_fkey FOREIGN KEY (hoc_sinh_id) REFERENCES public.hoc_sinh(id)
);
CREATE TABLE public.xe (
  id integer NOT NULL DEFAULT nextval('xe_id_seq'::regclass),
  bien_so character varying NOT NULL UNIQUE,
  suc_chua integer NOT NULL CHECK (suc_chua > 0),
  han_dang_kiem date NOT NULL,
  CONSTRAINT xe_pkey PRIMARY KEY (id)
);
CREATE TABLE public.tai_xe (
  id integer NOT NULL DEFAULT nextval('tai_xe_id_seq'::regclass),
  nguoi_dung_id integer NOT NULL UNIQUE,
  so_gplx character varying NOT NULL UNIQUE,
  han_gplx date NOT NULL,
  CONSTRAINT tai_xe_pkey PRIMARY KEY (id),
  CONSTRAINT tai_xe_nguoi_dung_id_fkey FOREIGN KEY (nguoi_dung_id) REFERENCES public.nguoi_dung(id)
);
CREATE TABLE public.bao_mau (
  id integer NOT NULL DEFAULT nextval('bao_mau_id_seq'::regclass),
  nguoi_dung_id integer NOT NULL UNIQUE,
  ghi_chu text,
  CONSTRAINT bao_mau_pkey PRIMARY KEY (id),
  CONSTRAINT bao_mau_nguoi_dung_id_fkey FOREIGN KEY (nguoi_dung_id) REFERENCES public.nguoi_dung(id)
);
CREATE TABLE public.tuyen (
  id integer NOT NULL DEFAULT nextval('tuyen_id_seq'::regclass),
  ten_tuyen character varying NOT NULL,
  xe_id integer NOT NULL,
  tai_xe_id integer NOT NULL,
  bao_mau_id integer,
  CONSTRAINT tuyen_pkey PRIMARY KEY (id),
  CONSTRAINT tuyen_xe_id_fkey FOREIGN KEY (xe_id) REFERENCES public.xe(id),
  CONSTRAINT tuyen_tai_xe_id_fkey FOREIGN KEY (tai_xe_id) REFERENCES public.tai_xe(id),
  CONSTRAINT tuyen_bao_mau_id_fkey FOREIGN KEY (bao_mau_id) REFERENCES public.bao_mau(id)
);
CREATE TABLE public.diem_dung (
  id integer NOT NULL DEFAULT nextval('diem_dung_id_seq'::regclass),
  tuyen_id integer NOT NULL,
  thu_tu integer NOT NULL,
  ten character varying NOT NULL,
  vi_do double precision NOT NULL,
  kinh_do double precision NOT NULL,
  gio_du_kien time without time zone NOT NULL,
  CONSTRAINT diem_dung_pkey PRIMARY KEY (id),
  CONSTRAINT diem_dung_tuyen_id_fkey FOREIGN KEY (tuyen_id) REFERENCES public.tuyen(id)
);
CREATE TABLE public.dang_ky_tuyen (
  id integer NOT NULL DEFAULT nextval('dang_ky_tuyen_id_seq'::regclass),
  hoc_sinh_id integer NOT NULL,
  tuyen_id integer NOT NULL,
  diem_dung_id integer NOT NULL,
  chieu character varying NOT NULL CHECK (chieu::text = ANY (ARRAY['DON'::character varying, 'TRA'::character varying]::text[])),
  CONSTRAINT dang_ky_tuyen_pkey PRIMARY KEY (id),
  CONSTRAINT dang_ky_tuyen_hoc_sinh_id_fkey FOREIGN KEY (hoc_sinh_id) REFERENCES public.hoc_sinh(id),
  CONSTRAINT dang_ky_tuyen_tuyen_id_fkey FOREIGN KEY (tuyen_id) REFERENCES public.tuyen(id),
  CONSTRAINT dang_ky_tuyen_diem_dung_id_fkey FOREIGN KEY (diem_dung_id) REFERENCES public.diem_dung(id)
);
CREATE TABLE public.chuyen_di (
  id integer NOT NULL DEFAULT nextval('chuyen_di_id_seq'::regclass),
  tuyen_id integer NOT NULL,
  ngay date NOT NULL DEFAULT CURRENT_DATE,
  chieu character varying NOT NULL CHECK (chieu::text = ANY (ARRAY['DON'::character varying, 'TRA'::character varying]::text[])),
  bat_dau_luc timestamp without time zone,
  ket_thuc_luc timestamp without time zone,
  trang_thai character varying NOT NULL DEFAULT 'CHUA_CHAY'::character varying CHECK (trang_thai::text = ANY (ARRAY['CHUA_CHAY'::character varying, 'DANG_CHAY'::character varying, 'HOAN_THANH'::character varying]::text[])),
  CONSTRAINT chuyen_di_pkey PRIMARY KEY (id),
  CONSTRAINT chuyen_di_tuyen_id_fkey FOREIGN KEY (tuyen_id) REFERENCES public.tuyen(id)
);
CREATE TABLE public.diem_danh (
  id integer NOT NULL DEFAULT nextval('diem_danh_id_seq'::regclass),
  chuyen_di_id integer NOT NULL,
  hoc_sinh_id integer NOT NULL,
  diem_dung_id integer NOT NULL,
  su_kien character varying NOT NULL CHECK (su_kien::text = ANY (ARRAY['LEN_XE'::character varying, 'XUONG_XE'::character varying]::text[])),
  thoi_diem timestamp without time zone NOT NULL DEFAULT now(),
  CONSTRAINT diem_danh_pkey PRIMARY KEY (id),
  CONSTRAINT diem_danh_chuyen_di_id_fkey FOREIGN KEY (chuyen_di_id) REFERENCES public.chuyen_di(id),
  CONSTRAINT diem_danh_hoc_sinh_id_fkey FOREIGN KEY (hoc_sinh_id) REFERENCES public.hoc_sinh(id),
  CONSTRAINT diem_danh_diem_dung_id_fkey FOREIGN KEY (diem_dung_id) REFERENCES public.diem_dung(id)
);
CREATE TABLE public.bao_nghi (
  id integer NOT NULL DEFAULT nextval('bao_nghi_id_seq'::regclass),
  hoc_sinh_id integer NOT NULL,
  ngay date NOT NULL,
  ly_do text NOT NULL,
  tao_boi integer NOT NULL,
  CONSTRAINT bao_nghi_pkey PRIMARY KEY (id),
  CONSTRAINT bao_nghi_hoc_sinh_id_fkey FOREIGN KEY (hoc_sinh_id) REFERENCES public.hoc_sinh(id),
  CONSTRAINT bao_nghi_tao_boi_fkey FOREIGN KEY (tao_boi) REFERENCES public.nguoi_dung(id)
);
CREATE TABLE public.vi_tri_xe (
  id integer NOT NULL DEFAULT nextval('vi_tri_xe_id_seq'::regclass),
  chuyen_di_id integer NOT NULL,
  vi_do double precision NOT NULL,
  kinh_do double precision NOT NULL,
  thoi_diem timestamp without time zone NOT NULL DEFAULT now(),
  CONSTRAINT vi_tri_xe_pkey PRIMARY KEY (id),
  CONSTRAINT vi_tri_xe_chuyen_di_id_fkey FOREIGN KEY (chuyen_di_id) REFERENCES public.chuyen_di(id)
);
CREATE TABLE public.schema_migrations (
  name text NOT NULL,
  applied_at timestamp without time zone NOT NULL DEFAULT now(),
  CONSTRAINT schema_migrations_pkey PRIMARY KEY (name)
);
CREATE TABLE public.thong_bao_cai_dat (
  nguoi_dung_id integer NOT NULL,
  loai_su_kien character varying NOT NULL CHECK (loai_su_kien::text = ANY (ARRAY['TRIP_STARTED'::character varying, 'STUDENT_BOARDED'::character varying, 'STUDENT_DROPPED_OFF'::character varying, 'TRIP_COMPLETED'::character varying]::text[])),
  bat boolean NOT NULL DEFAULT true,
  cap_nhat_luc timestamp without time zone NOT NULL DEFAULT now(),
  CONSTRAINT thong_bao_cai_dat_pkey PRIMARY KEY (nguoi_dung_id, loai_su_kien),
  CONSTRAINT thong_bao_cai_dat_nguoi_dung_id_fkey FOREIGN KEY (nguoi_dung_id) REFERENCES public.nguoi_dung(id)
);
CREATE TABLE public.thong_bao (
  id bigint NOT NULL DEFAULT nextval('thong_bao_id_seq'::regclass),
  nguoi_nhan_id integer NOT NULL,
  hoc_sinh_id integer NOT NULL,
  chuyen_di_id integer NOT NULL,
  loai_su_kien character varying NOT NULL CHECK (loai_su_kien::text = ANY (ARRAY['TRIP_STARTED'::character varying, 'STUDENT_BOARDED'::character varying, 'STUDENT_DROPPED_OFF'::character varying, 'TRIP_COMPLETED'::character varying]::text[])),
  tieu_de character varying NOT NULL,
  noi_dung text NOT NULL,
  khoa_chong_trung character varying NOT NULL UNIQUE,
  tao_luc timestamp without time zone NOT NULL DEFAULT now(),
  da_doc_luc timestamp without time zone,
  CONSTRAINT thong_bao_pkey PRIMARY KEY (id),
  CONSTRAINT thong_bao_nguoi_nhan_id_fkey FOREIGN KEY (nguoi_nhan_id) REFERENCES public.nguoi_dung(id),
  CONSTRAINT thong_bao_hoc_sinh_id_fkey FOREIGN KEY (hoc_sinh_id) REFERENCES public.hoc_sinh(id),
  CONSTRAINT thong_bao_chuyen_di_id_fkey FOREIGN KEY (chuyen_di_id) REFERENCES public.chuyen_di(id)
);