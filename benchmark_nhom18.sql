-- ============================================================
-- BENCHMARK SQL - TU DONG DO HIEN NANG TRONG MYSQL WORKBENCH
-- Nhom 18 - Toi Uu Truy Van
-- ============================================================
-- Cach dung: Chay tung phan mot, ghi lai thoi gian tu Workbench
-- ============================================================

USE dl_benhvien;

-- TAT PROFILING
SET profiling = 0;

-- ============================================================
-- PHAN 1: SINGLE INDEX (SDT)
-- Slide: 3
-- ============================================================

-- Truoc toi uu
SET profiling = 1;
EXPLAIN SELECT MaBN, TenBN, NgaySinh, DiaChi FROM benhnhan WHERE SDT = '0909123456';
SELECT MaBN, TenBN, NgaySinh, DiaChi FROM benhnhan WHERE SDT = '0909123456';
SHOW PROFILES;
-- Ghi lai: Duration Query_ID = ...

-- Tao index
CREATE INDEX idx_bench_sdt ON benhnhan(SDT);

-- Sau toi uu
EXPLAIN SELECT MaBN, TenBN, NgaySinh, DiaChi FROM benhnhan WHERE SDT = '0909123456';
SELECT MaBN, TenBN, NgaySinh, DiaChi FROM benhnhan WHERE SDT = '0909123456';
SHOW PROFILES;
-- Ghi lai: Duration Query_ID = ...

-- Don dep
DROP INDEX idx_bench_sdt ON benhnhan;
SET profiling = 0;

-- ============================================================
-- PHAN 2: COMPOSITE INDEX
-- Slide: 4
-- ============================================================

SET profiling = 1;

-- Truoc
EXPLAIN SELECT MaLich, ThoiGianDat FROM lichhen WHERE MaBN = 'BN000001' AND TrangThai = 'Hoàn thành' ORDER BY ThoiGianDat DESC LIMIT 10;
SELECT MaLich, ThoiGianDat FROM lichhen WHERE MaBN = 'BN000001' AND TrangThai = 'Hoàn thành' ORDER BY ThoiGianDat DESC LIMIT 10;
SHOW PROFILES;

-- Tao index
CREATE INDEX idx_bench_composite ON lichhen(MaBN, TrangThai, ThoiGianDat);

-- Sau
EXPLAIN SELECT MaLich, ThoiGianDat FROM lichhen WHERE MaBN = 'BN000001' AND TrangThai = 'Hoàn thành' ORDER BY ThoiGianDat DESC LIMIT 10;
SELECT MaLich, ThoiGianDat FROM lichhen WHERE MaBN = 'BN000001' AND TrangThai = 'Hoàn thành' ORDER BY ThoiGianDat DESC LIMIT 10;
SHOW PROFILES;

-- Don dep
DROP INDEX idx_bench_composite ON lichhen;
SET profiling = 0;

-- ============================================================
-- PHAN 3: COVERING INDEX
-- Slide: 5
-- ============================================================

SET profiling = 1;

-- Truoc
EXPLAIN SELECT TrangThai, COUNT(*) FROM lichhen GROUP BY TrangThai;
SELECT TrangThai, COUNT(*) FROM lichhen GROUP BY TrangThai;
SHOW PROFILES;

-- Tao covering index
CREATE INDEX idx_bench_covering ON lichhen(TrangThai, MaLich);

-- Sau
EXPLAIN SELECT TrangThai, COUNT(*) FROM lichhen GROUP BY TrangThai;
SELECT TrangThai, COUNT(*) FROM lichhen GROUP BY TrangThai;
SHOW PROFILES;

-- Don dep
DROP INDEX idx_bench_covering ON lichhen;
SET profiling = 0;

-- ============================================================
-- PHAN 4: SELECT * vs SELECT COLUMNS
-- Slide: 6
-- ============================================================

SET profiling = 1;

-- Truoc (SELECT *)
EXPLAIN SELECT * FROM benhnhan WHERE GioiTinh = 'Nữ' LIMIT 100;
SELECT * FROM benhnhan WHERE GioiTinh = 'Nữ' LIMIT 100;
SHOW PROFILES;

-- Sau (SELECT columns)
EXPLAIN SELECT MaBN, TenBN, NgaySinh FROM benhnhan WHERE GioiTinh = 'Nữ' LIMIT 100;
SELECT MaBN, TenBN, NgaySinh FROM benhnhan WHERE GioiTinh = 'Nữ' LIMIT 100;
SHOW PROFILES;

SET profiling = 0;

-- ============================================================
-- PHAN 5: IN vs EXISTS
-- Slide: 7
-- ============================================================

SET profiling = 1;

-- Truoc (IN)
EXPLAIN SELECT MaBN, TenBN FROM benhnhan WHERE MaBN IN (SELECT DISTINCT MaBN FROM lichhen WHERE TrangThai = 'Chờ khám') LIMIT 100;
SELECT MaBN, TenBN FROM benhnhan WHERE MaBN IN (SELECT DISTINCT MaBN FROM lichhen WHERE TrangThai = 'Chờ khám') LIMIT 100;
SHOW PROFILES;

-- Sau (EXISTS)
EXPLAIN SELECT MaBN, TenBN FROM benhnhan bn WHERE EXISTS (SELECT 1 FROM lichhen lh WHERE lh.MaBN = bn.MaBN AND lh.TrangThai = 'Chờ khám') LIMIT 100;
SELECT MaBN, TenBN FROM benhnhan bn WHERE EXISTS (SELECT 1 FROM lichhen lh WHERE lh.MaBN = bn.MaBN AND lh.TrangThai = 'Chờ khám') LIMIT 100;
SHOW PROFILES;

SET profiling = 0;

-- ============================================================
-- PHAN 6: FUNCTION ON INDEXED COLUMN
-- Slide: 8
-- ============================================================

SET profiling = 1;

-- Truoc (ham vo hieu hoa index)
EXPLAIN SELECT * FROM lichhen WHERE YEAR(ThoiGianDat) = 2025;
SELECT * FROM lichhen WHERE YEAR(ThoiGianDat) = 2025 LIMIT 100;
SHOW PROFILES;

-- Sau (range scan)
EXPLAIN SELECT * FROM lichhen WHERE ThoiGianDat >= '2025-01-01' AND ThoiGianDat < '2026-01-01';
SELECT * FROM lichhen WHERE ThoiGianDat >= '2025-01-01' AND ThoiGianDat < '2026-01-01' LIMIT 100;
SHOW PROFILES;

SET profiling = 0;

-- ============================================================
-- PHAN 7: CTE vs SUBQUERY LAP LAI
-- Slide: 9
-- ============================================================

SET profiling = 1;

-- Truoc (subquery lap)
EXPLAIN SELECT bs.MaBS, (SELECT COUNT(*) FROM phieukham WHERE MaBS = bs.MaBS) as tong FROM bacsi bs LIMIT 10;
SELECT bs.MaBS, (SELECT COUNT(*) FROM phieukham WHERE MaBS = bs.MaBS) as tong FROM bacsi bs LIMIT 10;
SHOW PROFILES;

-- Sau (CTE)
EXPLAIN WITH stats AS (SELECT MaBS, COUNT(*) as tong FROM phieukham GROUP BY MaBS) SELECT bs.MaBS, COALESCE(s.tong,0) FROM bacsi bs LEFT JOIN stats s ON bs.MaBS = s.MaBS LIMIT 10;
WITH stats AS (SELECT MaBS, COUNT(*) as tong FROM phieukham GROUP BY MaBS) SELECT bs.MaBS, COALESCE(s.tong,0) FROM bacsi bs LEFT JOIN stats s ON bs.MaBS = s.MaBS LIMIT 10;
SHOW PROFILES;

SET profiling = 0;

-- ============================================================
-- MAU BANG GHI KET QUA (Copy vao slide)
-- ============================================================

/*

| STT | Ky thuat | Truoc (ms) | Sau (ms) | Tang toc | Slide |
|-----|----------|------------|----------|----------|-------|
| 1 | Single Index (SDT) | ____ | ____ | ____x | 3 |
| 2 | Composite Index | ____ | ____ | ____x | 4 |
| 3 | Covering Index | ____ | ____ | ____x | 5 |
| 4 | SELECT * vs Columns | ____ | ____ | ____x | 6 |
| 5 | IN vs EXISTS | ____ | ____ | ____x | 7 |
| 6 | Function on Column | ____ | ____ | ____x | 8 |
| 7 | CTE vs Subquery | ____ | ____ | ____x | 9 |

*/

-- ============================================================
-- HUONG DAN DO HIEN NANG
-- ============================================================
/*

1. Mo MySQL Workbench
2. Ket noi den database dl_benhvien
3. Copy & Paste TUNG PHAN test (khong chay toan bo 1 luc)
4. Sau moi lenh SELECT, chay SHOW PROFILES;
5. Ghi lai cot "Duration" cua query SELECT vao bang tren
6. Nhap ket qua vao file ToiUuTruyVan_Nhom18.md (Phan B.3)

Luu y: 
- Nen restart MySQL truoc khi do de xoa cache
- Moi test chay 3 lan, lay gia tri TRUNG BINH
- Bo qua lan chay dau tien (warm-up)

*/
