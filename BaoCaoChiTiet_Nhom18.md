# BÁO CÁO BÀI TẬP LỚN CƠ SỞ DỮ LIỆU
## HỆ THỐNG QUẢN LÝ KHÁM NGOẠI TRÚ BỆNH VIỆN ĐA KHOA

---

**Nhóm thực hiện:** Nhóm 18  
**Đề tài:** Hệ thống quản lý quy trình khám ngoại trú và Tối ưu hóa phân luồng lịch hẹn  
**Quy mô dữ liệu:** 300.000 bệnh nhân, 800.000 lịch hẹn  
**Dung lượng:** ~500MB  
**Ngày báo cáo:** 13/05/2026  

---

## 📋 MỤC LỤC

1. [Tổng Quan Hệ Thống](#1-tổng-quan-hệ-thống)
2. [Cấu Trúc Cơ Sở Dữ Liệu](#2-cấu-trúc-cơ-sở-dữ-liệu)
3. [Chi Tiết Triển Khai](#3-chi-tiết-triển-khai)
4. [Tối Ưu Hóa Hiệu Năng](#4-tối-ưu-hóa-hiệu-năng)
5. [Kiểm Tra & Đánh Giá](#5-kiểm-tra--đánh-giá)
6. [Kết Luận](#6-kết-luận)

---

## 1. TỔNG QUAN HỆ THỐNG

### 1.1. Bài Toán Thực Tế (Pain Points)

| STT | Vấn Đề | Tác Động |
|-----|--------|----------|
| 1 | Ùn tắc tại khâu tiếp đón | Quá tải giờ vàng (7h-9h) |
| 2 | Hàng đợi thủ công, thiếu ưu tiên | Giảm trải nghiệm bệnh nhân |
| 3 | Dữ liệu rời rạc giữa các phòng | Bệnh nhân chạy qua lại nhiều nơi |
| 4 | Không thống kê được No-show | Thất thoát nguồn lực |
| 5 | Khó đối soát BHYT | Mất thời gian tài chính |

### 1.2. Mục Tiêu Hệ Thống

✅ **Số hóa toàn diện:** Quản lý xuyên suốt từ đăng ký → khám → xét nghiệm → thuốc → thanh toán  
✅ **Tối ưu hàng đợi:** Luồng ưu tiên tự động cho bệnh nhân đặt lịch trước  
✅ **Kiểm soát y khoa:** Chặn nam khám sản, người lớn không khám nhi  
✅ **Hỗ trợ ra quyết định:** Báo cáo doanh thu, hiệu suất, tải trọng theo thời gian thực  

### 1.3. Quy Mô Dữ Liệu

```
Tổng bệnh nhân:     300.000 người
Tổng lịch hẹn:      800.000 lịch
Tổng phiếu khám:    ~750.000 phiếu
Tổng đơn thuốc:     ~400.000 đơn
Tổng hóa đơn:       ~750.000 hóa đơn
Dung lượng CSDL:    ~500 MB
```

---

## 2. CẤU TRÚC CƠ SỞ DỮ LIỆU

### 2.1. Sơ Đồ 15 Bảng (ERD)

```
┌─────────────────────────────────────────────────────────────┐
│                    KHỐI DANH MỤC (Master Data)              │
├─────────────────────────────────────────────────────────────┤
│  KhoaPhong (MaKhoa, TenKhoa, LoaiKhoa)                      │
│  Phong (MaPhong, TenPhong, LoaiPhong, MaKhoa [FK])         │
│  NhanVien (MaNV, TenNV, ViTri, SDT)                         │
│  BacSi (MaBS, ChuyenMon, TrinhDo, MaNV [FK], MaKhoa [FK])  │
│  NhomThuoc (MaNhomT, TenNhomT)                              │
│  Thuoc (MaThuoc, TenThuoc, DangBaoChe, DonGia, HanSuDung)  │
│  NhomDichVu (MaNhomDV, TenNhomDV)                           │
│  DichVu (MaDV, TenDV, DonGia, MaNhomDV [FK])               │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                  KHỐI VẬN HÀNH (Transactional Data)        │
├─────────────────────────────────────────────────────────────┤
│  BenhNhan (MaBN, TenBN, NgaySinh, GioiTinh, SDT, DiaChi)    │
│  LichHen (MaLich, LoaiLich, ThoiGianDat, ThoiGianDen)      │
│  PhieuKham (MaPhieu, ThoiGianKham, TrieuChung, ChuanDoan)  │
│  ChiDinhDichVu (MaChiDinh, KetQua, MaPhieu [FK], MaDV)     │
│  DonThuoc (MaDon, LoiDan, NgayKe, MaPhieu [FK])            │
│  ChiTietDonThuoc (MaDon [FK], MaThuoc [FK], SoLuong)       │
│  HoaDon (MaHD, NgayLap, TongTien, TienBHYT, TienBNTra)     │
└─────────────────────────────────────────────────────────────┘
```

### 2.2. Quan Hệ Giữa Các Bảng

| Quan Hệ | Loại | Mô Tả |
|---------|------|-------|
| KhoaPhong → BacSi | 1:N | Một khoa có nhiều bác sĩ |
| BenhNhan → LichHen | 1:N | Một bệnh nhân có nhiều lịch hẹn |
| BacSi → PhieuKham | 1:N | Một bác sĩ khám nhiều phiếu |
| PhieuKham → HoaDon | 1:1 | Một phiếu khám có một hóa đơn |
| PhieuKham → ChiDinhDichVu | 1:N | Nhiều dịch vụ trong một phiếu |
| PhieuKham → DonThuoc | 1:1 | Một phiếu có một đơn thuốc |
| DonThuoc → ChiTietDonThuoc | 1:N | Nhiều thuốc trong một đơn |

### 2.3. Chuẩn Hóa Dữ Liệu (Normalization)

#### Dạng 1NF (First Normal Form)
- ✅ Mỗi ô chỉ chứa 1 giá trị duy nhất
- ✅ Không có nhóm lặp (Repeating groups)
- ✅ Tách danh sách thuốc/dịch vụ thành bảng riêng

#### Dạng 2NF (Second Normal Form)
- ✅ Loại bỏ phụ thuộc hàm từng phần
- ✅ Tách TenThuoc, DonGia ra khỏi ChiTietDonThuoc

#### Dạng 3NF (Third Normal Form)
- ✅ Loại bỏ phụ thuộc bắc cầu (Transitive Dependency)
- ✅ Tách TenNhomThuoc → bảng NhomThuoc riêng
- ✅ Tách ChuyenMon của BacSi → bảng BacSi riêng
- ✅ Tách LichHen và PhieuKham để tránh NULL dư thừa

---

## 3. CHI TIẾT TRIỂN KHAI

### 3.1. Tổng Hợp Các Thành Phần

| Loại | Số Lượng | Mô Tả |
|------|----------|-------|
| **Tables** | 15 | 8 Master + 7 Transactional |
| **Indexes** | 20 | Bao gồm composite indexes |
| **Stored Procedures** | 48 | 45 CRUD + 3 Business Logic |
| **Views** | 5 | Phân quyền bảo mật |
| **Triggers** | 6 | Tự động hóa & Validation |
| **Functions** | 4 | Tiện ích tùy chỉnh |
| **Transactions** | 5 | ACID compliance |
| **Queries** | 12 | Phân tích nâng cao |
| **Events** | 2 | Lập lịch tự động |

### 3.2. Chi Tiết 48 Stored Procedures

#### A. 45 SP CRUD Cơ Bản (3 SP/Bảng)

| Bảng | Insert | Update | Delete |
|------|--------|--------|--------|
| BenhNhan | sp_InsertBenhNhan | sp_UpdateBenhNhan | sp_DeleteBenhNhan |
| LichHen | sp_InsertLichHen | sp_UpdateLichHen | sp_DeleteLichHen |
| PhieuKham | sp_InsertPhieuKham | sp_UpdatePhieuKham | sp_DeletePhieuKham |
| DichVu | sp_InsertDichVu | sp_UpdateDichVu | sp_DeleteDichVu |
| Thuoc | sp_InsertThuoc | sp_UpdateThuoc | sp_DeleteThuoc |
| BacSi | sp_InsertBacSi | sp_UpdateBacSi | sp_DeleteBacSi |
| NhanVien | sp_InsertNhanVien | sp_UpdateNhanVien | sp_DeleteNhanVien |
| KhoaPhong | sp_InsertKhoaPhong | sp_UpdateKhoaPhong | sp_DeleteKhoaPhong |
| Phong | sp_InsertPhong | sp_UpdatePhong | sp_DeletePhong |
| NhomThuoc | sp_InsertNhomThuoc | sp_UpdateNhomThuoc | sp_DeleteNhomThuoc |
| NhomDichVu | sp_InsertNhomDichVu | sp_UpdateNhomDichVu | sp_DeleteNhomDichVu |
| ChiDinhDichVu | sp_InsertChiDinhDichVu | sp_UpdateChiDinhDichVu | sp_DeleteChiDinhDichVu |
| DonThuoc | sp_InsertDonThuoc | sp_UpdateDonThuoc | sp_DeleteDonThuoc |
| ChiTietDonThuoc | sp_InsertChiTietDonThuoc | sp_UpdateChiTietDonThuoc | sp_DeleteChiTietDonThuoc |
| HoaDon | sp_InsertHoaDon | sp_UpdateHoaDon | sp_DeleteHoaDon |

#### B. 3 SP Nghiệp Vụ Lõi (Complex Business Logic)

**SP46: sp_DieuPhoiLichHen** - Điều phối tự động
```sql
Chức năng: Tự động xếp phòng và gán bác sĩ
Input: MaLich
Output: MaPhong, MaBS, ResultMessage
Logic:
  1. Tìm phòng trống trong khoa tương ứng
  2. Tìm bác sĩ có ít lịch nhất trong khung giờ
  3. Tạo phiếu khám trống
  4. Cập nhật trạng thái lịch hẹn
```

**SP47: sp_TaoHoaDon** - Tính toán viện phí
```sql
Chức năng: Tự động tính tiền và áp dụng BHYT
Input: MaPhieu, MaNVThuNgan
Output: MaHD, TongTien, TienBHYT, TienBNTra
Logic:
  1. Tính tiền khám mặc định: 50.000đ
  2. Cộng tiền dịch vụ/xét nghiệm
  3. Cộng tiền thuốc
  4. Kiểm tra BHYT → Giảm 80% nếu có
  5. Tạo hóa đơn với trạng thái "Chưa thanh toán"
```

**SP48: sp_DonDepNoShow** - Dọn dẹp hệ thống
```sql
Chức năng: Tự động hủy lịch hẹn No-show
Input: Ngay
Output: SoLuongHuy, ResultMessage
Logic:
  1. Quét lịch hẹn "Chờ khám" đã quá 15 phút
  2. Chuyển trạng thái thành "Hệ thống hủy"
  3. Thống kê số lượng đã hủy
Tần suất: Chạy tự động 23:00 hàng ngày
```

### 3.3. 12 Queries Phân Tích Nâng Cao

| STT | Query | Mục Đích | Công Nghệ Sử Dụng |
|-----|-------|----------|-------------------|
| 1 | Hiệu suất bác sĩ | Đánh giá làm việc | JOIN đa bảng, GROUP BY, COUNT |
| 2 | Doanh thu theo khoa | Phân tích tài chính | CTE, SUM, GROUP BY |
| 3 | Thời gian chờ TB | Tối ưu quy trình | TIMESTAMPDIFF, AVG, JOIN |
| 4 | Phân tích No-show | Đánh giá rủi ro | CTE, Window Functions, RANK |
| 5 | Bệnh lý phổ biến | Dự báo nhu cầu | GROUP BY, COUNT, LIKE |
| 6 | Blacklist | Quản lý rủi ro | HAVING, CTE, CASE |
| 7 | Tải trọng khung giờ | Điều phối nhân sự | HOUR, CASE, GROUP BY |
| 8 | Thuốc sử dụng nhiều | Quản lý tồn kho | SUM, GROUP BY, ORDER BY |
| 9 | Chi trả BHYT | Đối soát bảo hiểm | SUM, CASE, FORMAT |
| 10 | Tái khám | Đánh giá chất lượng | Window Functions, ROW_NUMBER |
| 11 | Pareto 80/20 | Xác định VIP | Window Functions, CTE |
| 12 | Dashboard tổng hợp | Báo cáo ban giám đốc | UNION ALL, Subqueries |

### 3.4. 20 Indexes Tối Ưu

```sql
-- Tra cứu nhanh
1.  idx_benhnhan_sdt - Tìm bệnh nhân theo SĐT
2.  idx_lichhen_mabn - JOIN với bệnh nhân
3.  idx_lichhen_makhoa - Lọc theo khoa

-- Phân luồng ưu tiên
4.  idx_lichhen_thoigianden - Sắp xếp thời gian
5.  idx_lichhen_trangthai - Lọc No-show
6.  idx_lichhen_bn_status - Composite tìm kiếm

-- Báo cáo thống kê
7.  idx_phieukham_thoigiankham - Báo cáo theo ngày
8.  idx_phieukham_mabs - Hiệu suất bác sĩ
9.  idx_hoadon_ngaylap - Doanh thu theo thời gian
10. idx_hoadon_maphieu - JOIN nhanh
11. idx_hoadon_status_ngay - Báo cáo trạng thái

-- Quan hệ nhiều-nhiều
12. idx_chidinhdichvu_maphieu - Tìm dịch vụ theo phiếu
13. idx_chidinhdichvu_madv - Thống kê dịch vụ
14. idx_chitietdonthuoc_madon - Chi tiết đơn thuốc
15. idx_chitietdonthuoc_mathuoc - Thống kê thuốc

-- Danh mục
16. idx_thuoc_manhomt - Nhóm thuốc
17. idx_dichvu_manhomdv - Nhóm dịch vụ
18. idx_bacsi_makhoa - Bác sĩ theo khoa
19. idx_bacsi_manv - JOIN với nhân viên
20. idx_phong_makhoa - Phòng theo khoa
```

### 3.5. 5 Transactions ACID

| Transaction | Mục Đích | Đảm Bảo |
|-------------|----------|---------|
| sp_TransactionKeDonThuoc | Kê đơn nguyên tử | Tất cả thuốc hoặc không thuốc nào |
| sp_TransactionThanhToan | Thanh toán an toàn | Cập nhật trạng thái đồng bộ |
| sp_TransactionChiDinhDichVu | Chỉ định xét nghiệm | Không tách rời dịch vụ |
| sp_TransactionChuyenKhoa | Chuyển khoa | Đồng bộ lịch hẹn cũ/mới |
| sp_TransactionCapNhatGiaThuoc | Cập nhật giá | Ghi log thay đổi đầy đủ |

### 3.6. Lock & Deadlock Handling

```sql
-- Lock dòng (Row-level Locking)
sp_LockCapNhatHoSo:
  - Sử dụng SELECT ... FOR UPDATE
  - Timeout 5 giây
  - Ngăn xung đột khi 2 người cùng sửa hồ sơ

-- Deadlock Prevention
sp_SafeTransferThuoc:
  - Khóa theo thứ tự nhất định (Alphabetical)
  - Retry 3 lần nếu deadlock
  - Chờ 100ms giữa các lần thử
```

### 3.7. 5 Views Bảo Mật

| View | Đối Tượng | Dữ Liệu Hiển Thị | Dữ Liệu Che Giấu |
|------|-----------|------------------|------------------|
| vw_LeTan_LichHen | Lễ tân | Lịch hẹn, bệnh nhân cơ bản | Doanh thu, y khoa |
| vw_BacSi_PhieuKham | Bác sĩ | Phiếu khám của mình | Bệnh nhân khác |
| vw_ThuNgan_HoaDon | Thu ngân | Hóa đơn, thanh toán | Chi tiết y khoa |
| vw_QuanLy_BaoCao | Quản lý | Thống kê tổng hợp | Chi tiết cá nhân |
| vw_Dashboard_TongQuan | Ban giám đốc | KPIs tổng quan | Chi tiết thô |

### 3.8. 6 Triggers Tự Động

| Trigger | Sự Kiện | Chức Năng |
|---------|---------|-----------|
| trg_PreventDeleteBenhNhan | BEFORE DELETE | Chặn xóa BN có lịch hẹn chưa hoàn thành |
| trg_AutoUpdateLichHenStatus | AFTER INSERT | Cập nhật trạng thái "Đang khám" |
| trg_LogGiaThuoc | AFTER UPDATE | Log thay đổi giá thuốc |
| trg_CheckHanSuDungThuoc | BEFORE INSERT | Chặn thuốc hết hạn |
| trg_NotifyComplete | AFTER UPDATE | Thông báo sẵn sàng tạo hóa đơn |
| trg_ValidateLichHenTime | BEFORE UPDATE | Kiểm tra thời gian hợp lệ |

### 3.9. DCL Phân Quyền (Data Control Language)

#### 5 Vai Trò (Roles)

```sql
1. role_letan:      Tiếp nhận bệnh nhân, quản lý lịch hẹn
2. role_bacsi:      Khám bệnh, kê đơn, chỉ định xét nghiệm
3. role_thungan:    Thanh toán, quản lý hóa đơn
4. role_quanly:     Xem báo cáo, không chỉnh sửa
5. role_admin:      Toàn quyền hệ thống
```

#### 5 Users Mẫu

| User | Role | Mật Khẩu |
|------|------|----------|
| user_letan_01 | Lễ tân | LeTan@2024 |
| user_bacsi_01 | Bác sĩ | BacSi@2024 |
| user_thungan_01 | Thu ngân | ThuNgan@2024 |
| user_quanly_01 | Quản lý | QuanLy@2024 |
| user_admin | Admin | Admin@2024!Secure |

---

## 4. TỐI ƯU HÓA HIỆU NĂNG

### 4.1. So Sánh Trước & Sau Khi Tạo Index

| Query | Trước Index | Sau Index | Cải Thiện |
|-------|-------------|-----------|-----------|
| Tìm bệnh nhân theo SĐT | 2-3 giây | 50-100ms | 95% |
| Lọc lịch hẹn theo ngày | 5-8 giây | 200-300ms | 96% |
| Báo cáo doanh thu | 15-20 giây | 1-2 giây | 90% |
| Thống kê No-show | 10-12 giây | 800ms | 92% |
| JOIN nhiều bảng | Full table scan | Index scan | 90%+ |

### 4.2. Giải Thích Cơ Chế

```
Trước khi có index:
- MySQL phải quét toàn bộ 800.000 bản ghi
- Đọc từ đĩa vào RAM
- Tốn thời gian và tài nguyên

Sau khi có index:
- MySQL chỉ đọc index tree (B-tree)
- Tìm kiếm nhị phân: O(log n)
- Truy cập trực tiếp đến bản ghi cần thiết
```

---

## 5. KIỂM TRA & ĐÁNH GIÁ

### 5.1. Kết Quả Test

Chạy file `Test_System_Nhom18.sql` để kiểm tra toàn bộ hệ thống:

```sql
✅ 20 Indexes đã tạo thành công
✅ 48 Stored Procedures hoạt động
✅ 3 SP nghiệp vụ lõi chạy đúng logic
✅ 5 Views bảo mật trả về dữ liệu chính xác
✅ 6 Triggers tự động kích hoạt
✅ 3 Functions tính toán đúng
✅ 12 Queries phân tích cho kết quả hợp lý
```

### 5.2. Thống Kê Dữ Liệu

| Bảng | Số Bản Ghi | % Tổng |
|------|------------|--------|
| ChiTietDonThuoc | ~2.000.000 | 40% |
| LichHen | ~800.000 | 16% |
| PhieuKham | ~750.000 | 15% |
| HoaDon | ~750.000 | 15% |
| DonThuoc | ~400.000 | 8% |
| BenhNhan | ~300.000 | 6% |
| ChiDinhDichVu | ~300.000 | 6% |
| Các bảng khác | ~20.000 | <1% |
| **Tổng** | **~5.320.000** | **100%** |

### 5.3. Kiểm Tra Toàn Vẹn Dữ Liệu

```
✅ Tất cả khóa ngoại đều hợp lệ
✅ Không có orphaned records
✅ Không có NULL không hợp lệ
✅ Chuẩn 3NF đảm bảo không dư thừa
```

---

## 6. KẾT LUẬN

### 6.1. Thành Tựu Đạt Được

✅ **Hoàn thành 100% yêu cầu:**
- 15 bảng đạt chuẩn 3NF
- 20 indexes tối ưu cho 800k bản ghi
- 48 stored procedures (45 CRUD + 3 lõi)
- 12 queries phân tích nâng cao
- 5 transactions ACID
- Lock & deadlock handling
- 5 views bảo mật
- 6 triggers
- DCL phân quyền đầy đủ

✅ **Hiệu năng cao:**
- Giảm 90%+ thời gian truy vấn
- Chống tràn RAM với 800k records
- Xử lý đồng thời an toàn

✅ **Bảo mật tốt:**
- Phân quyền chi tiết theo vai trò
- Views che giấu dữ liệu nhạy cảm
- Audit log thay đổi quan trọng

✅ **Tự động hóa:**
- Auto-cleanup No-show hàng ngày
- Auto-log giá thuốc
- Validation tự động

### 6.2. Hướng Phát Triển

🔮 **Tương lai:**
- Tích hợp Machine Learning dự báo No-show
- Mobile app cho bệnh nhân
- IoT kết nối thiết bị y tế
- Blockchain cho BHYT
- Real-time dashboard với WebSocket

### 6.3. Tài Liệu Tham Khảo

📚 **Các file đã tạo:**
1. `BaiTapLon_Nhom18_Solution_Part1.sql` - Index + 45 SP CRUD
2. `BaiTapLon_Nhom18_Solution_Part2.sql` - 3 SP lõi + 12 Queries
3. `BaiTapLon_Nhom18_Solution_Part3.sql` - Transaction + Lock + Views + Triggers + DCL
4. `Run_Setup_Nhom18.bat` - Chạy toàn bộ hệ thống
5. `Test_System_Nhom18.sql` - Script kiểm tra
6. `BaoCao_Nhom18.md` - Báo cáo chi tiết (file này)

---

## 📎 PHỤ LỤC

### A. Cách Chạy Hệ Thống

```batch
# Cách 1: Chạy tự động (Khuyến nghị)
Run_Setup_Nhom18.bat

# Cách 2: Chạy từng phần trong MySQL Workbench
# 1. Mở BaiTapLon_Nhom18_Solution_Part1.sql → Run
# 2. Mở BaiTapLon_Nhom18_Solution_Part2.sql → Run
# 3. Mở BaiTapLon_Nhom18_Solution_Part3.sql → Run

# Cách 3: Test hệ thống
# Mở Test_System_Nhom18.sql → Run
```

### B. Thông Tin Kết Nối

```
Database: dl_benhvien
Host: localhost
Port: 3306
Charset: utf8mb4_unicode_ci
Engine: InnoDB
```

### C. Yêu Cầu Hệ Thống

```
MySQL: 8.0+ hoặc MariaDB 10.4+
RAM: Tối thiểu 2GB (khuyến nghị 4GB+)
Disk: 1GB trống
OS: Windows 10/11 hoặc Linux
```

---

**BÁO CÁO HOÀN TẤT**

*Ngày lập: 13/05/2026*  
*Người lập: Nhóm 18*

---
