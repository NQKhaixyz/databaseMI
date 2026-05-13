# TOI UU VA TICH HOP HE THONG CSDL

## 1. Muc tieu

Tai lieu trinh bay cac giai phap toi uu va tich hop da ap dung cho he thong CSDL, theo hai huong:
- **toi uu thuc thi** (hieu nang truy van, xu ly du lieu lon),
- **tich hop nghiep vu** (dong bo logic, tu dong hoa van hanh).

## 2. Toi uu hieu nang

## 2.1. Toi uu bang chi muc

He thong da xay dung nhom index phuc vu cac mau truy van chu dao:
- tim kiem benh nhan theo SDT,
- loc lich hen theo trang thai va thoi gian,
- join nhanh theo cac ma nghiep vu (`MaBN`, `MaKhoa`, `MaPhieu`, ...).

Ket qua kiem thu `EXPLAIN` cho thay:
- truy van theo SDT da su dung `idx_benhnhan_sdt` (hieu qua cao),
- truy van `TrangThai + ORDER BY ThoiGianDen` da dung index loc nhung con filesort (can toi uu bo sung).

### 2.2. Toi uu cho tai phan tich

- Su dung bang `hoadon_partitioned` de ho tro truy van tong hop theo khoang thoi gian.
- Trigger dong bo insert/update tu `hoadon` sang bang partitioned de dam bao tinh nhat quan.

### 2.3. Toi uu logic xu ly trong CSDL

- Dong goi quy trinh nghiep vu vao stored procedure giup:
  - giam round-trip giua app va DB,
  - toi uu ke hoach thuc thi co tinh lap lai,
  - de quan sat va kiem thu hoi quy.

## 3. Tich hop nghiep vu

### 3.1. Tich hop theo luong kham benh

Luong du lieu duoc tich hop lien thong:
1. `benhnhan` -> `lichhen`
2. `lichhen` -> `phieukham`
3. `phieukham` -> (`chidinhdichvu`, `donthuoc`, `chitietdonthuoc`)
4. `phieukham` -> `hoadon`

Qua do he thong dam bao tu tiep nhan den thanh toan duoc lien mach va truy vet day du.

### 3.2. Tich hop quy tac nghiep vu

- Trigger rang buoc cho lich hen (gioi tinh, do tuoi, logic thoi gian).
- Trigger tinh BHYT 80/20 tai hoa don.
- Trigger soft-unique SDT/BHYT cho du lieu moi.
- Trigger kiem tra han dung thuoc va quy tac chan doan - nhom thuoc.

### 3.3. Tich hop van hanh dinh ky

- Event `evt_DonDepNoShow`: tu dong xu ly no-show theo lich.
- Event `evt_WeeklyReport`: tao bao cao dinh ky cho giam sat quan tri.

## 4. Danh gia ket qua toi uu/tich hop

### 4.1. Mat dinh luong

- Data quy mo lon da duoc nap va van hanh on dinh:
  - 308547 benh nhan,
  - 800000 lich hen,
  - 597162 phieu kham,
  - 597162 hoa don.

- He thong doi tuong lap trinh CSDL day du:
  - 55 procedures, 15 triggers, 12 views, 4 functions, 2 events.

### 4.2. Mat chat luong

- SDT trung da duoc loai bo trong dataset va co che chan trung cho du lieu moi hoat dong.
- Mot so bat thuong lich su van ton tai (`duplicate_bhyt_nonempty`, `ThoiGianDen < ThoiGianDat`) va da duoc ghi nhan de xu ly tiep theo roadmap.

## 5. Khuyen nghi hoc thuat cho bai tap lon

1. **Bo sung chi so tong hop (composite index)** cho mau truy van co `WHERE + ORDER BY`:
   - de xuat: `(TrangThai, ThoiGianDen)` tren `lichhen`.
2. **Xay dung pipeline data quality** theo dot:
   - uu tien BHYT trung,
   - sau do la chuan hoa logic thoi gian lich hen.
3. **Bo sung bo test benchmark**:
   - do thoi gian truy van truoc/sau toi uu,
   - bao cao bang so lieu de tang tinh hoc thuat khi bao ve.
4. **Chuan hoa tai lieu phuong phap**:
   - mo ta ro gia thuyet, cach do, va ket qua doi chieu.

## 6. Ket luan

He thong da dat muc tich hop nghiep vu tot va co nen tang toi uu ban dau vung chac cho bai toan CSDL lon. Cac de xuat toi uu tiep theo co tinh kha thi cao, phu hop de nang cap chat luong he thong theo huong nghien cuu - ung dung.
