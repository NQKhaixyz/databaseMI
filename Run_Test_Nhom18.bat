@echo off
setlocal EnableExtensions EnableDelayedExpansion
chcp 65001 >nul
cls

echo =============================================================================
echo OUTPATIENT HOSPITAL DB - FULL VALIDATION
echo =============================================================================
echo.

if "%MYSQL_USER%"=="" set "MYSQL_USER=root"
if "%MYSQL_PASSWORD%"=="" set "MYSQL_PASSWORD=root"
if "%MYSQL_HOST%"=="" set "MYSQL_HOST=localhost"
if "%MYSQL_PORT%"=="" set "MYSQL_PORT=3306"
if "%MYSQL_DATABASE%"=="" set "MYSQL_DATABASE=dl_benhvien"

set "MYSQL_CMD=mysql -u%MYSQL_USER% -p%MYSQL_PASSWORD% -h%MYSQL_HOST% -P%MYSQL_PORT%"

echo [1/9] Checking MySQL connection...
%MYSQL_CMD% -e "SELECT 'connected' AS status;" >nul 2>&1
if errorlevel 1 (
    echo [ERROR] Cannot connect MySQL.
    pause
    exit /b 1
)

set "REPORT_FILE=Test_Report_Nhom18_%date:~-4,4%%date:~-10,2%%date:~-7,2%_%time:~0,2%%time:~3,2%%time:~6,2%.txt"
set "REPORT_FILE=%REPORT_FILE: =0%"

echo HOSPITAL DB TEST REPORT > "%REPORT_FILE%"
echo Date: %date% %time%>> "%REPORT_FILE%"
echo Database: %MYSQL_DATABASE%>> "%REPORT_FILE%"
echo ============================================================>> "%REPORT_FILE%"

echo [2/9] Counting core objects...
echo.>> "%REPORT_FILE%"
echo [OBJECT COUNTS]>> "%REPORT_FILE%"
%MYSQL_CMD% %MYSQL_DATABASE% -e "
SELECT 'indexes' AS metric, COUNT(*) AS value
FROM information_schema.statistics
WHERE table_schema='%MYSQL_DATABASE%' AND index_name <> 'PRIMARY'
UNION ALL
SELECT 'procedures', COUNT(*) FROM information_schema.routines WHERE routine_schema='%MYSQL_DATABASE%' AND routine_type='PROCEDURE'
UNION ALL
SELECT 'views', COUNT(*) FROM information_schema.views WHERE table_schema='%MYSQL_DATABASE%'
UNION ALL
SELECT 'triggers', COUNT(*) FROM information_schema.triggers WHERE trigger_schema='%MYSQL_DATABASE%'
UNION ALL
SELECT 'functions', COUNT(*) FROM information_schema.routines WHERE routine_schema='%MYSQL_DATABASE%' AND routine_type='FUNCTION'
UNION ALL
SELECT 'events', COUNT(*) FROM information_schema.events WHERE event_schema='%MYSQL_DATABASE%';
" >> "%REPORT_FILE%" 2>&1

echo [3/9] Data scale check...
echo.>> "%REPORT_FILE%"
echo [DATA SCALE]>> "%REPORT_FILE%"
%MYSQL_CMD% %MYSQL_DATABASE% -e "
SELECT 'benhnhan' AS table_name, COUNT(*) AS rows_count FROM benhnhan
UNION ALL SELECT 'lichhen', COUNT(*) FROM lichhen
UNION ALL SELECT 'phieukham', COUNT(*) FROM phieukham
UNION ALL SELECT 'hoadon', COUNT(*) FROM hoadon
UNION ALL SELECT 'chidinhdichvu', COUNT(*) FROM chidinhdichvu
UNION ALL SELECT 'donthuoc', COUNT(*) FROM donthuoc
UNION ALL SELECT 'chitietdonthuoc', COUNT(*) FROM chitietdonthuoc;
" >> "%REPORT_FILE%" 2>&1

echo [4/9] Rule compliance checks...
echo.>> "%REPORT_FILE%"
echo [RULE CHECKS]>> "%REPORT_FILE%"
%MYSQL_CMD% %MYSQL_DATABASE% -e "
SELECT 'male_in_phu_san' AS check_name, COUNT(*) AS violations
FROM lichhen lh
JOIN benhnhan bn ON bn.MaBN=lh.MaBN
JOIN khoaphong kp ON kp.MaKhoa=lh.MaKhoa
WHERE bn.GioiTinh='Nam' AND kp.TenKhoa LIKE '%Phụ Sản%'
UNION ALL
SELECT 'under16_in_ngoai_nhi', COUNT(*)
FROM lichhen lh
JOIN benhnhan bn ON bn.MaBN=lh.MaBN
JOIN khoaphong kp ON kp.MaKhoa=lh.MaKhoa
WHERE TIMESTAMPDIFF(YEAR,bn.NgaySinh,CURDATE()) < 16 AND kp.TenKhoa LIKE '%Ngoại Nhi%'
UNION ALL
SELECT 'time_logic_invalid', COUNT(*)
FROM lichhen
WHERE ThoiGianDen IS NOT NULL AND ThoiGianDat IS NOT NULL AND ThoiGianDen < ThoiGianDat
UNION ALL
SELECT 'duplicate_sdt', COUNT(*)
FROM (
  SELECT SDT FROM benhnhan WHERE SDT IS NOT NULL AND TRIM(SDT)<>'' GROUP BY SDT HAVING COUNT(*)>1
) x
UNION ALL
SELECT 'duplicate_bhyt_nonempty', COUNT(*)
FROM (
  SELECT SoBHYT FROM benhnhan WHERE SoBHYT IS NOT NULL AND TRIM(SoBHYT)<>'' GROUP BY SoBHYT HAVING COUNT(*)>1
) y;
" >> "%REPORT_FILE%" 2>&1

echo [5/9] Stored procedure smoke tests...
echo.>> "%REPORT_FILE%"
echo [SP SMOKE TESTS]>> "%REPORT_FILE%"
%MYSQL_CMD% %MYSQL_DATABASE% -e "
SET @maPhong='';
SET @maBS='';
SET @msg='';
CALL sp_DieuPhoiLichHen('LH00000001', @maPhong, @maBS, @msg);
SELECT 'sp_DieuPhoiLichHen' AS sp_name, @maPhong AS ma_phong, @maBS AS ma_bs, @msg AS result_message;
" >> "%REPORT_FILE%" 2>&1

%MYSQL_CMD% %MYSQL_DATABASE% -e "
SET @maHD='';
SET @tong=0;
SET @bhyt=0;
SET @bntra=0;
SET @msg='';
CALL sp_TaoHoaDon('PK00000001', 'NV0001', @maHD, @tong, @bhyt, @bntra, @msg);
SELECT 'sp_TaoHoaDon' AS sp_name, @maHD AS ma_hd, @tong AS tong_tien, @bhyt AS tien_bhyt, @bntra AS tien_bn_tra, @msg AS result_message;
" >> "%REPORT_FILE%" 2>&1

%MYSQL_CMD% %MYSQL_DATABASE% -e "
SET @sl=0;
SET @msg='';
CALL sp_DonDepNoShow(CURDATE(), @sl, @msg);
SELECT 'sp_DonDepNoShow' AS sp_name, @sl AS so_luong_huy, @msg AS result_message;
" >> "%REPORT_FILE%" 2>&1

echo [6/9] View/function checks...
echo.>> "%REPORT_FILE%"
echo [VIEW/FUNCTION CHECKS]>> "%REPORT_FILE%"
%MYSQL_CMD% %MYSQL_DATABASE% -e "
SELECT 'vw_LeTan_LichHen' AS object_name, COUNT(*) AS rows_count FROM vw_LeTan_LichHen
UNION ALL SELECT 'vw_BacSi_PhieuKham', COUNT(*) FROM vw_BacSi_PhieuKham
UNION ALL SELECT 'vw_ThuNgan_HoaDon', COUNT(*) FROM vw_ThuNgan_HoaDon
UNION ALL SELECT 'vw_QuanLy_BaoCao', COUNT(*) FROM vw_QuanLy_BaoCao
UNION ALL SELECT 'vw_Dashboard_TongQuan', COUNT(*) FROM vw_Dashboard_TongQuan
UNION ALL SELECT 'vw_ParetoNhomTuoiKham', COUNT(*) FROM vw_ParetoNhomTuoiKham;
SELECT 'fn_TinhTuoi' AS fn_name, fn_TinhTuoi('1990-01-01') AS result
UNION ALL SELECT 'fn_FormatVND', fn_FormatVND(1250000)
UNION ALL SELECT 'fn_SinhMaBenhNhan', fn_SinhMaBenhNhan()
UNION ALL SELECT 'fn_KiemTraLichHopLe', fn_KiemTraLichHopLe('BN000001','K_KHAM',DATE_ADD(NOW(), INTERVAL 1 DAY));
" >> "%REPORT_FILE%" 2>&1

echo [7/9] Partition mirror check...
echo.>> "%REPORT_FILE%"
echo [PARTITION CHECK]>> "%REPORT_FILE%"
%MYSQL_CMD% %MYSQL_DATABASE% -e "
SELECT 'hoadon_rows' AS metric, COUNT(*) AS value FROM hoadon
UNION ALL
SELECT 'hoadon_partitioned_rows', COUNT(*) FROM hoadon_partitioned;
" >> "%REPORT_FILE%" 2>&1

echo [8/9] Explain index usage sample...
echo.>> "%REPORT_FILE%"
echo [INDEX USAGE]>> "%REPORT_FILE%"
%MYSQL_CMD% %MYSQL_DATABASE% -e "
EXPLAIN SELECT * FROM benhnhan WHERE SDT='0909123456';
EXPLAIN SELECT * FROM lichhen WHERE TrangThai='Chờ khám' ORDER BY ThoiGianDen;
" >> "%REPORT_FILE%" 2>&1

echo [9/9] Final status snapshot...
echo.>> "%REPORT_FILE%"
echo [FINAL SNAPSHOT]>> "%REPORT_FILE%"
%MYSQL_CMD% %MYSQL_DATABASE% -e "
SELECT 'status' AS metric, 'test_completed' AS value
UNION ALL SELECT 'db_name', DATABASE()
UNION ALL SELECT 'event_scheduler', @@event_scheduler;
" >> "%REPORT_FILE%" 2>&1

echo.
echo =============================================================================
echo TEST COMPLETED
echo =============================================================================
echo Report: %REPORT_FILE%
echo.
pause
