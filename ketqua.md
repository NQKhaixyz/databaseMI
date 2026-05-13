# KET QUA KIEM THU HE THONG CSDL BENH VIEN NGOAI TRU

## 1. Muc tieu va pham vi

Tai lieu nay ghi nhan ket qua kiem thu sau khi:
- tai tao CSDL tu file `BaiTapLon_Nhom18_Complete.sql`,
- cap nhat dataset de SDT benh nhan khong con trung,
- thuc hien kiem thu chuc nang, toan ven, va hieu nang o muc smoke/regression.

## 2. Moi truong thuc nghiem

- He quan tri CSDL: MySQL Server 8.4
- Tep script tong hop: `BaiTapLon_Nhom18_Complete.sql`
- CSDL su dung: `dl_benhvien`
- Cach ket noi: MySQL CLI (`mysql.exe`) voi tai khoan `root`

## 3. Quy trinh kiem thu da thuc hien

1. **Khoi tao lai CSDL sach**: drop/create database `dl_benhvien`.
2. **Import toan bo script**: nap day du schema + data + SP/trigger/view/function/event.
3. **Kiem thu cau truc doi tuong**: dem so bang, index, routine, trigger, event.
4. **Kiem thu du lieu va quy tac**: kiem tra duplicate SDT/BHYT, rang buoc nghiep vu, logic thoi gian.
5. **Kiem thu smoke cho SP va function**.
6. **Kiem thu truy van hieu nang** bang `EXPLAIN`.

## 4. Ket qua tong hop

### 4.1. Quy mo du lieu

- `benhnhan`: **308547**
- `lichhen`: **800000**
- `phieukham`: **597162**
- `hoadon`: **597162**

### 4.2. So luong doi tuong CSDL

- Bang du lieu (base tables): **18**
- Khoa ngoai (FK): **20**
- Chi muc (khong tinh PK): **45**
- Stored procedures: **55**
- Views: **12**
- Triggers: **15**
- Functions: **4**
- Events: **2**

### 4.3. Kiem tra quy tac du lieu

- `male_in_phu_san`: **0** vi pham
- `under16_in_ngoai_nhi`: **0** vi pham
- `duplicate_sdt`: **0** (dat yeu cau sau khi xu ly du lieu)
- `duplicate_bhyt_nonempty`: **26** nhom trung
- `time_logic_invalid`: **134173** ban ghi co `ThoiGianDen < ThoiGianDat`

Nhan xet:
- Co che soft-unique cho SDT da duoc dap ung o du lieu hien tai.
- Du lieu BHYT va logic thoi gian con ton tai sai lech lich su, can lap ke hoach lam sach theo dot.

### 4.4. Kiem thu smoke stored procedures

- `sp_DieuPhoiLichHen('LH00000001', ...)`: goi thanh cong, tra ve thong diep khong co phong trong khung gio hien tai (hanh vi hop le theo nghiep vu).
- `sp_TaoHoaDon('PK00000001','NV0001', ...)`: thanh cong; tong tien, BHYT 80/20 va thong diep ket qua duoc sinh dung.
- `sp_DonDepNoShow(CURDATE(), ...)`: thanh cong; khong co ban ghi can huy tai thoi diem test.

### 4.5. Kiem thu function

- `fn_TinhTuoi('1990-01-01')` -> **36**
- `fn_FormatVND(1250000)` -> chuoi tien te hop le
- `fn_SinhMaBenhNhan()` -> sinh ma moi (`BN308548` tai thoi diem test)
- `fn_KiemTraLichHopLe(...)` -> tra thong diep hop le

### 4.6. Kiem thu hieu nang (EXPLAIN)

- Truy van theo SDT benh nhan su dung `idx_benhnhan_sdt` (kieu `ref`, so dong uoc tinh thap).
- Truy van loc theo trang thai lich hen su dung `idx_lichhen_trangthai`; tuy nhien van xuat hien `Using filesort` khi `ORDER BY ThoiGianDen`.

## 5. Danh gia ket luan

He thong dat muc tieu van hanh co ban va dap ung tot cac thanh phan:
- schema, du lieu lon, routine nghiep vu, trigger, event,
- co che chan trung SDT cho du lieu moi,
- kha nang tao bao cao va truy van phan tich.

Tuy nhien, tu goc nhin hoc thuat ve chat luong du lieu, can uu tien xu ly tiep:
1. Lam sach cac ban ghi `ThoiGianDen < ThoiGianDat`.
2. Lam sach cac nhom trung `SoBHYT` con ton dong.
3. Xem xet toi uu index phuc hop cho mau truy van `TrangThai + ThoiGianDen` de giam filesort.

## 6. De xuat buoc tiep theo

- Tao script migration rieng cho data cleansing BHYT va thoi gian lich hen.
- Bo sung bo test tu dong theo tung dot (regression SQL script).
- Chuan hoa bo ma test va bao cao theo mot mau thong nhat de nop bai tap lon.
