# BAO CAO DATABASE - HE THONG QUAN LY KHAM NGOAI TRU

## 1. Tong quan mo hinh du lieu

He thong duoc thiet ke theo huong **quan ly luong kham ngoai tru end-to-end**, bao gom:
- tiep nhan benh nhan,
- dat va dieu phoi lich hen,
- kham benh va chi dinh can lam sang,
- ke don, lap hoa don, doi soat thanh toan,
- bao cao quan tri va giam sat van hanh.

Co so du lieu sau khi khoi tao gom **18 bang du lieu** va **20 khoa ngoai**, dam bao lien ket logic giua cac thuc the chinh.

## 2. Danh sach bang trong schema `dl_benhvien`

1. `bacsi`
2. `benhnhan`
3. `chandoan_nhomthuoc_rule`
4. `chidinhdichvu`
5. `chitietdonthuoc`
6. `dichvu`
7. `donthuoc`
8. `hoadon`
9. `hoadon_partitioned`
10. `khoaphong`
11. `lichhen`
12. `log_thaydoigia`
13. `nhanvien`
14. `nhomdichvu`
15. `nhomthuoc`
16. `phieukham`
17. `phong`
18. `thuoc`

## 3. Cum nghiep vu va dong du lieu

### 3.1. Cum tiep nhan va lich hen

- `benhnhan` luu danh tinh va thong tin hanh chinh.
- `lichhen` luu yeu cau kham theo khoa/thoi diem/trang thai.
- `khoaphong`, `phong` cung cap cau truc to chuc va tai nguyen phong.

### 3.2. Cum kham benh va can lam sang

- `phieukham` la ban ghi trung tam cua lan kham.
- `chidinhdichvu` lien ket phieu kham voi `dichvu`.
- `donthuoc` va `chitietdonthuoc` ghi nhan phac do dieu tri.

### 3.3. Cum tai chinh va doi soat

- `hoadon` la bang hoa don nghiep vu.
- `hoadon_partitioned` la bang dong bo phuc vu chia phan vung va truy van phan tich lon.

### 3.4. Cum nhan su va tham chieu danh muc

- `nhanvien`, `bacsi` quan ly nhan su y te.
- `nhomthuoc`, `nhomdichvu`, `thuoc`, `dichvu` quan ly danh muc.

## 4. Quy mo du lieu thuc nghiem

- `benhnhan`: 308547
- `lichhen`: 800000
- `phieukham`: 597162
- `hoadon`: 597162

Quy mo nay phu hop boi canh bai toan lon (hieu nang, tinh toan ven, va bao cao tong hop).

## 5. Lap trinh trong CSDL

- Stored procedures: **55**
- Functions: **4**
- Views: **12**
- Triggers: **15**
- Events: **2**

He thong da trien khai dong bo logic nghiep vu o muc CSDL, giup:
- giam phu thuoc vao ung dung client,
- tang tinh nhat quan khi co nhieu diem truy cap,
- ho tro kha nang audit va giam sat quy tac.

## 6. Co che toan ven va rang buoc

### 6.1. Toan ven tham chieu

- 20 FK bao dam lien ket giua cac bang giao dich va bang danh muc.
- Han che tao ban ghi mo coi (orphan record) trong cac quan he chinh.

### 6.2. Toan ven nghiep vu

Thong qua trigger va SP:
- chan them/cap nhat SDT va SoBHYT trung cho du lieu moi (soft-unique),
- rang buoc gioi tinh/do tuoi theo khoa dac thu,
- tu dong tinh BHYT trong thanh toan,
- dong bo hoa don sang bang partitioned.

## 7. Nhan xet hoc thuat

Duoi goc nhin nghien cuu he thong thong tin y te, mo hinh nay co 3 diem manh:
1. **Tach lop nghiep vu ro rang**: tiep nhan - kham - can lam sang - tai chinh.
2. **Khong gian mo rong**: co bang quy tac (`chandoan_nhomthuoc_rule`) va event scheduler.
3. **San sang phan tich**: co views tong hop va bang hoa don phan vung.

Han che can cai thien:
- van con mot so bat thuong du lieu lich su (BHYT trung, moc thoi gian khong hop le),
- can bo sung chuan hoa chat luong du lieu dau vao theo batch migration.

## 8. Ket luan

Database dat muc do hoan chinh cao cho bai tap lon: co du mo hinh du lieu, logic nghiep vu, bao mat view, va thanh phan tu dong hoa. Nen tang hien tai phu hop de tiep tuc toi uu hieu nang va nang cao chat luong du lieu theo huong hoc thuat - thuc nghiem.
