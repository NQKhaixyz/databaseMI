# THIET KE CSDL CHO HE THONG QUAN LY KHAM NGOAI TRU

## 1. Muc tieu thiet ke

Thiet ke CSDL huong toi 4 muc tieu hoc thuat va thuc tien:
- **Dung nghiep vu**: phan anh day du chu trinh kham ngoai tru.
- **Toan ven**: giam toi da du lieu sai lech, mo coi, va xung dot.
- **Hieu nang**: dap ung khoi luong du lieu lon (hang tram nghin den hang trieu ban ghi).
- **Mo rong**: cho phep bo sung quy tac va bao cao trong tuong lai.

## 2. Phan tich thuc the va quan he

### 2.1. Thuc the cot loi

- **Benh nhan** (`benhnhan`): danh tinh y te va thong tin lien he.
- **Lich hen** (`lichhen`): diem vao cua quy trinh tiep nhan.
- **Phieu kham** (`phieukham`): ket qua kham va chan doan.
- **Hoa don** (`hoadon`): tong hop chi phi va thanh toan.

### 2.2. Thuc the bo tro

- **Nhan su**: `nhanvien`, `bacsi`.
- **To chuc**: `khoaphong`, `phong`.
- **Danh muc dich vu/thuoc**: `dichvu`, `nhomdichvu`, `thuoc`, `nhomthuoc`.
- **Chi tiet can lam sang va don thuoc**: `chidinhdichvu`, `donthuoc`, `chitietdonthuoc`.
- **Bang phan vung va log**: `hoadon_partitioned`, `log_thaydoigia`.

## 3. Nguyen tac chuan hoa du lieu

### 3.1. Chuan hoa den 3NF

- Thuoc tinh khong khoa phu thuoc day du vao khoa chinh.
- Loai bo phu thuoc bac cau boi cach tach bang danh muc (`nhomthuoc`, `nhomdichvu`).
- Tach nhan su va vai tro bac si de tranh lap du lieu.

### 3.2. Quan ly ma dinh danh

- Cac bang chinh dung ma chuoi co tien to (`MaBN`, `MaLich`, `MaPhieu`, `MaHD`) de thuan tien truy vet nghiep vu va xuat bao cao.

## 4. Rang buoc va toan ven

## 4.1. Rang buoc cau truc

- PK cho moi bang.
- FK cho cac quan he 1-n giua giao dich va danh muc.
- Index phu tro join va filter tren cac cot truy van cao tan suat.

### 4.2. Rang buoc nghiep vu

Duoc thuc thi bang trigger/procedure:
- Soft-unique voi `SDT` va `SoBHYT` tren du lieu moi.
- Rang buoc gioi tinh/do tuoi theo khoa dac thu khi tao/cap nhat lich hen.
- Tinh toan BHYT 80/20 tu dong tren hoa don.
- Chan thuoc het han hoac sai nhom theo chan doan (rule-based).

## 5. Kien truc lap trinh CSDL

### 5.1. Stored procedures

He thong dung 55 SP cho:
- CRUD theo bang,
- nghiep vu dieu phoi lich,
- tao hoa don,
- don dep no-show,
- xu ly transaction va lock.

### 5.2. Triggers

15 trigger chia theo nhom:
- toan ven du lieu benh nhan,
- kiem soat lich hen,
- dong bo hoa don phan vung,
- kiem soat thuoc va ghi nhat ky thay doi gia.

### 5.3. Views va bao mat

12 view ho tro:
- phan quyen theo vai tro (le tan, bac si, thu ngan, quan ly),
- dashboard KPI,
- bao cao duplicate va quy tac du lieu.

## 6. Dinh huong hieu nang

- Dung index tren cac cot loc/chuyen tiep: `SDT`, `TrangThai`, `ThoiGianDen`, `MaBN`, `MaKhoa`.
- Dung bang `hoadon_partitioned` de giam tai cho truy van tong hop theo thoi gian.
- Co event scheduler de tu dong hoa cong viec batch.

## 7. Danh gia chat luong thiet ke

### 7.1. Diem manh

1. Mo hinh phu hop dong nghiep vu y te ngoai tru.
2. Logic CSDL dam bao tinh dong nhat cao giua nhieu module.
3. Co kha nang mo rong cho phan tich va khai pha du lieu.

### 7.2. Diem can hoan thien

1. Lam sach du lieu lich su cho cac bat thuong da phat hien.
2. Bo sung bo quy tac chuan hoa dau vao manh hon o lop ETL/import.
3. Toi uu tiep cho cac truy van co `ORDER BY` tan suat cao.

## 8. Ket luan

Thiet ke CSDL dat muc tieu cua mot bai tap lon theo dinh huong hoc thuat: co mo hinh du lieu ro rang, rang buoc nghiep vu co he thong, va kha nang van hanh tren quy mo lon. Nen tang nay phu hop cho cac buoc nghien cuu tiep theo ve toi uu hoa va quan tri chat luong du lieu.
