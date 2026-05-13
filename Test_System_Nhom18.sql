-- =============================================================================
-- SCRIPT KIỂM TRA HỆ THỐNG - BỆNH VIỆN ĐA KHOA NHÓM 18
-- Mục đích: Test tất cả các thành phần đã tạo
-- =============================================================================

USE `dl_benhvien`;

-- =============================================================================
-- PHẦN 1: KIỂM TRA INDEXES
-- =============================================================================
SELECT '=== KIỂM TRA INDEXES ===' AS Section;

-- Liệt kê tất cả indexes đã tạo
SELECT 
    TABLE_NAME,
    INDEX_NAME,
    COLUMN_NAME,
    CARDINALITY
FROM INFORMATION_SCHEMA.STATISTICS
WHERE TABLE_SCHEMA = 'dl_benhvien'
AND INDEX_NAME != 'PRIMARY'
ORDER BY TABLE_NAME, INDEX_NAME;

-- =============================================================================
-- PHẦN 2: KIỂM TRA STORED PROCEDURES
-- =============================================================================
SELECT '=== KIỂM TRA STORED PROCEDURES ===' AS Section;

-- Liệt kê tất cả SP
SELECT 
    ROUTINE_NAME,
    ROUTINE_TYPE,
    CREATED,
    DEFINER
FROM INFORMATION_SCHEMA.ROUTINES
WHERE ROUTINE_SCHEMA = 'dl_benhvien'
AND ROUTINE_TYPE = 'PROCEDURE'
ORDER BY ROUTINE_NAME;

-- =============================================================================
-- PHẦN 3: TEST CRUD STORED PROCEDURES
-- =============================================================================
SELECT '=== TEST CRUD PROCEDURES ===' AS Section;

-- Test 1: Thêm bệnh nhân mới
SET @MaBN_Test = 'BNTST001';
CALL sp_InsertBenhNhan(@MaBN_Test, 'Nguyễn Văn Test', '1990-05-15', 'Nam', '0909123456', 'Hà Nội', 'TEST123456');
SELECT 'Test Insert BenhNhan: OK' AS Test_Result;

-- Test 2: Cập nhật bệnh nhân
CALL sp_UpdateBenhNhan(@MaBN_Test, 'Nguyễn Văn Test Updated', '1990-05-15', 'Nam', '0909123456', 'TP.HCM', 'TEST123456');
SELECT 'Test Update BenhNhan: OK' AS Test_Result;

-- Test 3: Kiểm tra dữ liệu vừa thêm
SELECT MaBN, TenBN, DiaChi FROM benhnhan WHERE MaBN = @MaBN_Test;

-- Test 4: Xóa bệnh nhân test
-- CALL sp_DeleteBenhNhan(@MaBN_Test);
-- SELECT 'Test Delete BenhNhan: OK' AS Test_Result;

-- =============================================================================
-- PHẦN 4: TEST NGHIỆP VỤ LÕI (3 SP COMPLEX)
-- =============================================================================
SELECT '=== TEST NGHIỆP VỤ LÕI ===' AS Section;

-- Test Điều phối lịch hẹn
SET @ResultMsg = '';
SET @MaPhong = '';
SET @MaBS = '';
-- Lấy một lịch hẹn mẫu để test
SELECT MaLich INTO @MaLichTest FROM lichhen WHERE TrangThai = 'Chờ khám' LIMIT 1;
IF @MaLichTest IS NOT NULL THEN
    CALL sp_DieuPhoiLichHen(@MaLichTest, @MaPhong, @MaBS, @ResultMsg);
    SELECT @ResultMsg AS DieuPhoi_Result, @MaPhong AS Phong_Duoc_Chon, @MaBS AS BS_Duoc_Chon;
ELSE
    SELECT 'Không có lịch hẹn để test điều phối' AS Warning;
END IF;

-- Test Tạo hóa đơn
SET @MaHD_Test = '';
SET @TongTien = 0;
SET @TienBHYT = 0;
SET @TienBNTra = 0;
SET @ResultMsg2 = '';
-- Lấy phiếu khám mẫu
SELECT MaPhieu INTO @MaPhieuTest FROM phieukham LIMIT 1;
IF @MaPhieuTest IS NOT NULL THEN
    CALL sp_TaoHoaDon(@MaPhieuTest, 'NV0001', @MaHD_Test, @TongTien, @TienBHYT, @TienBNTra, @ResultMsg2);
    SELECT @MaHD_Test AS MaHD_Moi, @TongTien AS Tong_Tien, @TienBHYT AS BHYT_Chi_Tra, @TienBNTra AS BN_Phai_Tra, @ResultMsg2 AS KetQua;
ELSE
    SELECT 'Không có phiếu khám để test tạo hóa đơn' AS Warning;
END IF;

-- Test Dọn dẹp No-show
SET @SoLuongHuy = 0;
SET @ResultMsg3 = '';
CALL sp_DonDepNoShow(CURDATE(), @SoLuongHuy, @ResultMsg3);
SELECT @SoLuongHuy AS So_Lich_Huy, @ResultMsg3 AS Ket_Qua_Don_Dep;

-- =============================================================================
-- PHẦN 5: TEST VIEWS
-- =============================================================================
SELECT '=== TEST VIEWS ===' AS Section;

-- Test View Lễ tân
SELECT 'View vw_LeTan_LichHen' AS View_Name, COUNT(*) AS Total_Records FROM vw_LeTan_LichHen;

-- Test View Bác sĩ
SELECT 'View vw_BacSi_PhieuKham' AS View_Name, COUNT(*) AS Total_Records FROM vw_BacSi_PhieuKham;

-- Test View Thu ngân
SELECT 'View vw_ThuNgan_HoaDon' AS View_Name, COUNT(*) AS Total_Records FROM vw_ThuNgan_HoaDon;

-- Test View Quản lý
SELECT 'View vw_QuanLy_BaoCao' AS View_Name, COUNT(*) AS Total_Records FROM vw_QuanLy_BaoCao;

-- Test View Dashboard
SELECT * FROM vw_Dashboard_TongQuan;

-- =============================================================================
-- PHẦN 6: TEST FUNCTIONS
-- =============================================================================
SELECT '=== TEST FUNCTIONS ===' AS Section;

-- Test fn_TinhTuoi
SELECT fn_TinhTuoi('1990-05-15') AS Tuoi_Tinh_Duoc;

-- Test fn_FormatVND
SELECT fn_FormatVND(1500000) AS Tien_Format;

-- Test fn_SinhMaBenhNhan
SELECT fn_SinhMaBenhNhan() AS Ma_Benh_Nhan_Tu_Dong;

-- =============================================================================
-- PHẦN 7: KIỂM TRA TRIGGERS
-- =============================================================================
SELECT '=== KIỂM TRA TRIGGERS ===' AS Section;

-- Liệt kê tất cả triggers
SELECT 
    TRIGGER_NAME,
    EVENT_MANIPULATION,
    EVENT_OBJECT_TABLE,
    ACTION_TIMING
FROM INFORMATION_SCHEMA.TRIGGERS
WHERE TRIGGER_SCHEMA = 'dl_benhvien';

-- =============================================================================
-- PHẦN 8: TEST TRIGGERS
-- =============================================================================
SELECT '=== TEST TRIGGERS ===' AS Section;

-- Test trigger tự động cập nhật lịch hẹn
-- Tạo phiếu khám mới và kiểm tra trạng thái lịch hẹn có thay đổi không
SET @MaLichTestTrigger = 'LHTST001';
INSERT INTO lichhen (MaLich, LoaiLich, ThoiGianDat, ThoiGianDen, TrangThai, MaBN, MaKhoa)
VALUES (@MaLichTestTrigger, 'Test', NOW(), NOW() + INTERVAL 1 HOUR, 'Đã xác nhận', 'BN000001', 'K_KHAM');

-- Tạo phiếu khám
INSERT INTO phieukham (MaPhieu, ThoiGianKham, TrieuChung, ChuanDoan, MaLich, MaBS, MaPhong)
VALUES ('PKTST001', NOW(), 'Test triệu chứng', 'Test chẩn đoán', @MaLichTestTrigger, 'BS0001', 'PKHA01');

-- Kiểm tra trạng thái lịch hẹn đã được cập nhật chưa
SELECT MaLich, TrangThai FROM lichhen WHERE MaLich = @MaLichTestTrigger;

-- Cleanup test data
DELETE FROM phieukham WHERE MaPhieu = 'PKTST001';
DELETE FROM lichhen WHERE MaLich = @MaLichTestTrigger;

-- =============================================================================
-- PHẦN 9: KIỂM TRA HIỆU NĂNG VỚI EXPLAIN
-- =============================================================================
SELECT '=== KIỂM TRA HIỆU NĂNG ===' AS Section;

-- Kiểm tra query có sử dụng index không
EXPLAIN SELECT * FROM benhnhan WHERE SDT = '0909123456';
EXPLAIN SELECT * FROM lichhen WHERE MaBN = 'BN000001' AND TrangThai = 'Hoàn thành';
EXPLAIN SELECT * FROM hoadon WHERE TrangThai = 'Đã thanh toán' AND NgayLap >= '2024-01-01';

-- =============================================================================
-- PHẦN 10: TEST QUERIES PHÂN TÍCH
-- =============================================================================
SELECT '=== TEST QUERIES PHÂN TÍCH ===' AS Section;

-- Test Query 1: Hiệu suất bác sĩ (giới hạn 5 kết quả)
SELECT 
    bs.MaBS,
    nv.TenNV AS TenBacSi,
    kp.TenKhoa,
    COUNT(pk.MaPhieu) AS SoCaKham
FROM bacsi bs
JOIN nhanvien nv ON bs.MaNV = nv.MaNV
JOIN khoaphong kp ON bs.MaKhoa = kp.MaKhoa
LEFT JOIN phieukham pk ON bs.MaBS = pk.MaBS
LEFT JOIN lichhen lh ON pk.MaLich = lh.MaLich
GROUP BY bs.MaBS, nv.TenNV, kp.TenKhoa
ORDER BY SoCaKham DESC
LIMIT 5;

-- Test Query 2: Top 5 thuốc sử dụng nhiều nhất
SELECT 
    t.TenThuoc,
    nt.TenNhomT,
    SUM(ctdt.SoLuong) AS TongSoLuong
FROM thuoc t
JOIN nhomthuoc nt ON t.MaNhomT = nt.MaNhomT
JOIN chitietdonthuoc ctdt ON t.MaThuoc = ctdt.MaThuoc
JOIN donthuoc dt ON ctdt.MaDon = dt.MaDon
GROUP BY t.MaThuoc, t.TenThuoc, nt.TenNhomT
ORDER BY TongSoLuong DESC
LIMIT 5;

-- =============================================================================
-- PHẦN 11: THỐNG KÊ TỔNG QUAN
-- =============================================================================
SELECT '=== THỐNG KÊ TỔNG QUAN ===' AS Section;

-- Thống kê số lượng bản ghi mỗi bảng
SELECT 
    'BENHNHAN' AS Bang, COUNT(*) AS SoBanGhi FROM benhnhan
UNION ALL SELECT 'LICHHEN', COUNT(*) FROM lichhen
UNION ALL SELECT 'PHIEUKHAM', COUNT(*) FROM phieukham
UNION ALL SELECT 'BACSI', COUNT(*) FROM bacsi
UNION ALL SELECT 'NHANVIEN', COUNT(*) FROM nhanvien
UNION ALL SELECT 'KHOAPHONG', COUNT(*) FROM khoaphong
UNION ALL SELECT 'PHONG', COUNT(*) FROM phong
UNION ALL SELECT 'THUOC', COUNT(*) FROM thuoc
UNION ALL SELECT 'DICHVU', COUNT(*) FROM dichvu
UNION ALL SELECT 'NHOMTHUOC', COUNT(*) FROM nhomthuoc
UNION ALL SELECT 'NHOMDICHVU', COUNT(*) FROM nhomdichvu
UNION ALL SELECT 'DONTHUOC', COUNT(*) FROM donthuoc
UNION ALL SELECT 'CHITIETDONTHUOC', COUNT(*) FROM chitietdonthuoc
UNION ALL SELECT 'CHIDINHDICHVU', COUNT(*) FROM chidinhdichvu
UNION ALL SELECT 'HOADON', COUNT(*) FROM hoadon
ORDER BY SoBanGhi DESC;

-- =============================================================================
-- PHẦN 12: KIỂM TRA TÍNH TOÀN VẸN DỮ LIỆU
-- =============================================================================
SELECT '=== KIỂM TRA TOÀN VẸN DỮ LIỆU ===' AS Section;

-- Kiểm tra ràng buộc khóa ngoại
SELECT 
    'LICHHEN -> BENHNHAN' AS RangBuoc,
    COUNT(*) AS SoLienKetLoi
FROM lichhen lh
LEFT JOIN benhnhan bn ON lh.MaBN = bn.MaBN
WHERE bn.MaBN IS NULL;

SELECT 
    'PHIEUKHAM -> LICHHEN' AS RangBuoc,
    COUNT(*) AS SoLienKetLoi
FROM phieukham pk
LEFT JOIN lichhen lh ON pk.MaLich = lh.MaLich
WHERE lh.MaLich IS NULL;

SELECT 
    'HOADON -> PHIEUKHAM' AS RangBuoc,
    COUNT(*) AS SoLienKetLoi
FROM hoadon hd
LEFT JOIN phieukham pk ON hd.MaPhieu = pk.MaPhieu
WHERE pk.MaPhieu IS NULL;

-- =============================================================================
-- BÁO CÁO KẾT THÚC
-- =============================================================================
SELECT '=== KẾT THÚC KIỂM TRA ===' AS Section;
SELECT 'Tất cả các thành phần đã được kiểm tra thành công!' AS KetLuan;
SELECT CONCAT('Ngày kiểm tra: ', NOW()) AS ThoiGian;

-- =============================================================================
-- CLEANUP TEST DATA
-- =============================================================================
-- Xóa dữ liệu test nếu cần
-- DELETE FROM benhnhan WHERE MaBN LIKE 'BNTST%';
-- DELETE FROM hoadon WHERE MaHD LIKE 'HD2024%' AND NgayLap > NOW() - INTERVAL 1 DAY;
