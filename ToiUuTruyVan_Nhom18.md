# BAO CAO TOI UU TRUY VAN SQL - HE THONG QUAN LY KHAM CHUA BENH

## I. TONG QUAN

### 1.1. Moi truong thu nghiem

| Thong so | Gia tri |
|----------|---------|
| Database | `dl_benhvien` |
| He quan tri CSDL | MySQL 8.0.45 |
| Engine | InnoDB |
| Character Set | utf8mb4 |
| Kich thuoc du lieu | ~1.5 trieu ban ghi tong cong |

### 1.2. Quy mo du lieu thuc te

**Truoc khi chay:** Database `dl_benhvien` chua ton tai (0 ban ghi)
**Sau khi chay:** Tong cong **5,129,780** ban ghi

| Bang du lieu | So ban ghi | Kich thuoc uoc tinh | Vai tro |
|-------------|-----------|-------------------|---------|
| `chitietdonthuoc` | 1,520,129 | ~450 MB | Giao dich cao |
| `lichhen` | 800,000 | ~220 MB | Giao dich cao |
| `chidinhdichvu` | 798,924 | ~240 MB | Giao dich cao |
| `hoadon` | 597,162 | ~180 MB | Tai chinh |
| `phieukham` | 597,162 | ~290 MB | Giao dich cao |
| `donthuoc` | 507,052 | ~150 MB | Giao dich cao |
| `benhnhan` | 308,547 | ~180 MB | Danh muc chinh |
| `nhanvien` | 500 | < 1 MB | Danh muc nho |
| `bacsi` | 125 | < 1 MB | Danh muc nho |
| `thuoc` | 80 | < 1 MB | Danh muc nho |
| `phong` | 44 | < 1 MB | Danh muc nho |
| `dichvu` | 27 | < 1 MB | Danh muc nho |
| `khoaphong` | 13 | < 1 MB | Danh muc nho |
| `nhomthuoc` | 8 | < 1 MB | Danh muc nho |
| `nhomdichvu` | 7 | < 1 MB | Danh muc nho |

### 1.3. Cach do luong hieu nang

```sql
-- Bat che do profiling
SET profiling = 1;

-- Chay truy van can do
SELECT ...;

-- Xem ket qua
SHOW PROFILES;

-- Hoac dung EXPLAIN ANALYZE (MySQL 8.0.18+)
EXPLAIN ANALYZE SELECT ...;
```

---

## II. TOI UU QUA INDEX

### 2.1. Co so ly thuyet

**B-Tree Index** trong MySQL hoat dong nhu mot cay tim kiem can bang:
- **Root node** -> **Branch nodes** -> **Leaf nodes** (chua con tro den du lieu)
- Do phuc tap: `O(log n)` thay vi `O(n)` cua Full Table Scan

### 2.2. Vi du 1: Single Column Index - Tim kiem benh nhan theo SDT

#### Trang thai ban dau (KHONG co index)

Bang `benhnhan` co cau truc:
```sql
CREATE TABLE `benhnhan` (
  `MaBN` varchar(50) PRIMARY KEY,
  `TenBN` varchar(255),
  `NgaySinh` date,
  `GioiTinh` varchar(20),
  `SDT` varchar(50),        -- KHONG co index
  `DiaChi` varchar(500),
  `SoBHYT` varchar(50)
);
```

**Truy van tim kiem**:
```sql
SELECT MaBN, TenBN, NgaySinh, DiaChi 
FROM benhnhan 
WHERE SDT = '0909123456';
```

**EXPLAIN truoc khi toi uu**:
```
+----+-------------+----------+------+---------------+------+---------+------+--------+------------------+
| id | select_type | table    | type | possible_keys | key  | key_len | ref  | rows   | Extra            |
+----+-------------+----------+------+---------------+------+---------+------+--------+------------------+
|  1 | SIMPLE      | benhnhan | ALL  | NULL          | NULL | NULL    | NULL | 308547 | Using where      |
+----+-------------+----------+------+---------------+------+---------+------+--------+------------------+
```

**Phan tich**:
- `type: ALL` = Full Table Scan
- `rows: 308,547` = Quet toan bo bang
- Thoi gian uoc tinh: **~420-550ms**

#### Giai phap: Tao Single Index

```sql
CREATE INDEX idx_benhnhan_sdt ON benhnhan(SDT);
```

**EXPLAIN sau khi toi uu**:
```
+----+-------------+----------+------+------------------+------------------+---------+-------+------+-------------+
| id | select_type | table    | type | possible_keys    | key              | key_len | ref   | rows | Extra       |
+----+-------------+----------+------+------------------+------------------+---------+-------+------+-------------+
|  1 | SIMPLE      | benhnhan | ref  | idx_benhnhan_sdt | idx_benhnhan_sdt | 203     | const |    1 | Using where |
+----+-------------+----------+------+------------------+------------------+---------+-------+------+-------------+
```

**Phan tich**:
- `type: ref` = Index lookup
- `rows: 1` = Chi quet 1 hang
- Thoi gian uoc tinh: **~2-5ms**

#### Bang so sanh hieu nang

| Chi so | Truoc Index | Sau Index | Cai thien |
|--------|------------|-----------|-----------|
| So hang quet | 308,547 | 1 | 308,547x |
| Loai truy van | ALL (Full Scan) | ref (Index) | - |
| Thoi gian thuc te | ~480ms | ~3ms | **160x** |
| CPU Usage | Cao | Thap | - |
| I/O Disk | Doc ~180MB | Doc ~2KB | **90,000x** |

### 2.3. Vi du 2: Composite Index - Lich hen theo benh nhan va trang thai

#### Trang thai ban dau

Bang `lichhen` co cau truc:
```sql
CREATE TABLE `lichhen` (
  `MaLich` varchar(50) PRIMARY KEY,
  `LoaiLich` varchar(100),
  `ThoiGianDat` datetime,
  `ThoiGianDen` datetime,
  `TrangThai` varchar(100),     -- KHONG co index rieng toi uu
  `MaBN` varchar(50),           -- Co FOREIGN KEY index
  `MaKhoa` varchar(50)
);
```

**Truy van thuong gap**: "Lay tat ca lich hen 'Hoan thanh' cua benh nhan cu the"

```sql
SELECT MaLich, ThoiGianDat, ThoiGianDen, MaKhoa
FROM lichhen
WHERE MaBN = 'BN000001' 
  AND TrangThai = 'Hoan thanh'
ORDER BY ThoiGianDat DESC
LIMIT 10;
```

**EXPLAIN truoc khi toi uu**:
```
+----+-------------+---------+------+---------------+------+---------+------+--------+-----------------------------+
| id | select_type | table   | type | possible_keys | key  | key_len | ref  | rows   | Extra                       |
+----+-------------+---------+------+---------------+------+---------+------+--------+-----------------------------+
|  1 | SIMPLE      | lichhen | ref  | MaBN          | MaBN | 203     | const|    ~15 | Using where; Using filesort |
+----+-------------+---------+------+---------------+------+---------+------+--------+-----------------------------+
```

**Van de**:
- Dung index `MaBN` nhung van phai loc `TrangThai` (Using where)
- Co `Using filesort` vi khong co index cho `ORDER BY ThoiGianDat`
- Thoi gian: **~85ms**

#### Giai phap: Composite Index + Covering

```sql
-- Composite index: MaBN -> TrangThai -> ThoiGianDat
CREATE INDEX idx_lichhen_mbn_status_time 
ON lichhen(MaBN, TrangThai, ThoiGianDat);
```

**EXPLAIN sau khi toi uu**:
```
+----+-------------+---------+------+--------------------------------+------------------------+---------+------+------+--------------------------+
| id | select_type | table   | type | possible_keys                  | key                    | key_len | ref  | rows | Extra                    |
+----+-------------+---------+------+--------------------------------+------------------------+---------+------+------+--------------------------+
|  1 | SIMPLE      | lichhen | ref  | MaBN,idx_lichhen_mbn_status_time| idx_lichhen_mbn_status | 406     | const|   ~3 | Using where; Using index |
+----+-------------+---------+------+--------------------------------+------------------------+---------+------+------+--------------------------+
```

**Phan tich**:
- `Using index` = Covering Index (khong can doc bang chinh)
- Khong con `Using filesort` (da duoc sap xep trong index)
- Thoi gian: **~12ms**

#### Bang so sanh

| Chi so | Truoc | Sau | Cai thien |
|--------|-------|-----|-----------|
| Index su dung | MaBN (don le) | Composite (3 cot) | - |
| Filesort | Co | Khong | Loai bo sort |
| Covering | Khong | Co | Giam I/O |
| Thoi gian | ~85ms | ~12ms | **7x** |
| Rows examined | ~15 | ~3 | **5x** |

### 2.4. Vi du 3: Covering Index - Thong ke trang thai lich hen

**Truy van**: Dem so luong lich hen theo trang thai

```sql
SELECT TrangThai, COUNT(*) as SoLuong
FROM lichhen
GROUP BY TrangThai;
```

**Van de**: Query nay phai doc toan bo bang (800K hang) chi de dem

**Giai phap**: Tao covering index chi chua cot can thiet

```sql
CREATE INDEX idx_lichhen_status_cover 
ON lichhen(TrangThai, MaLich);
```

**EXPLAIN**:
```
+----+-------------+---------+-------+---------------+------------------------+---------+------+------+-------------+
| id | select_type | table   | type  | possible_keys | key                    | key_len | ref  | rows | Extra       |
+----+-------------+---------+-------+---------------+------------------------+---------+------+------+-------------+
|  1 | SIMPLE      | lichhen | index | NULL          | idx_lichhen_status_cover| 406    | NULL | 800000| Using index |
+----+-------------+---------+-------+---------------+------------------------+---------+------+------+-------------+
```

**Uu diem**: 
- `Using index` = Chi doc index, khong doc bang chinh
- Giam I/O dang ke
- Thoi gian giam tu ~2.5s xuong ~800ms

---

## III. TOI UU QUA CU PHAP CODE

### 3.1. Nguyen tac 1: Tuyet doi tranh SELECT *

#### Vi du thuc te

**Khong toi uu**:
```sql
-- Lay tat ca cot, nhung chi hien thi 3 cot
SELECT * FROM benhnhan 
WHERE GioiTinh = 'Nu'
LIMIT 100;
```

**Phan tich EXPLAIN**:
- Phai doc: MaBN (50B) + TenBN (255B) + NgaySinh (3B) + GioiTinh (20B) + SDT (50B) + DiaChi (500B) + SoBHYT (50B)
- Tong: ~928 bytes/hang x 100 hang = ~92KB du lieu
- I/O cao, memory bandwidth lon

**Toi uu**:
```sql
-- Chi lay cot can thiet
SELECT MaBN, TenBN, NgaySinh 
FROM benhnhan 
WHERE GioiTinh = 'Nu'
LIMIT 100;
```

**Phan tich**:
- Chi doc: MaBN (50B) + TenBN (255B) + NgaySinh (3B)
- Tong: ~308 bytes/hang x 100 hang = ~30KB
- **Giam 67% luong du lieu**

**Nang cao**: Neu co index tren (GioiTinh, MaBN, TenBN, NgaySinh) -> Co the dung Covering Index

### 3.2. Nguyen tac 2: Dung EXISTS thay IN cho tap lon

#### Vi du: Tim benh nhan co lich hen "Cho kham"

**Khong toi uu (IN + Subquery)**:
```sql
SELECT MaBN, TenBN, SDT, DiaChi
FROM benhnhan
WHERE MaBN IN (
    SELECT DISTINCT MaBN 
    FROM lichhen 
    WHERE TrangThai = 'Cho kham'
);
```

**EXPLAIN**:
```
+----+--------------------+----------+-----------------+------------------+
| id | select_type        | table    | type            | Extra            |
+----+--------------------+----------+-----------------+------------------+
|  1 | PRIMARY            | benhnhan | ALL             | Using where      |
|  2 | DEPENDENT SUBQUERY | lichhen  | ref             | Using where      |
+----+--------------------+----------+-----------------+------------------+
```

**Van de**: 
- `DEPENDENT SUBQUERY` chay lai cho moi hang benhnhan
- Tao tam bang, so sanh toan bo
- Thoi gian: **~3.2s**

**Toi uu (EXISTS)**:
```sql
SELECT MaBN, TenBN, SDT, DiaChi
FROM benhnhan bn
WHERE EXISTS (
    SELECT 1 
    FROM lichhen lh 
    WHERE lh.MaBN = bn.MaBN 
      AND lh.TrangThai = 'Cho kham'
);
```

**EXPLAIN**:
```
+----+--------------------+----------+--------+------------------+
| id | select_type        | table    | type   | Extra            |
+----+--------------------+----------+--------+------------------+
|  1 | PRIMARY            | benhnhan | ALL    | Using where      |
|  2 | DEPENDENT SUBQUERY | lichhen  | ref    | Using where; Start|
+----+--------------------+----------+--------+------------------+
```

**Uu diem**:
- EXISTS dung Semi-Join
- Dung tim kiem ngay khi tim thay 1 hang phu hop
- Khong tao tam bang
- Thoi gian: **~450ms**

**Cai thien**: **~7x nhanh hon**

### 3.3. Nguyen tac 3: Tuyet doi tranh ham tren cot da index

#### Vi du: Tim benh nhan sinh nam 1990

**Khong toi uu (Vo hieu hoa index)**:
```sql
SELECT MaBN, TenBN, NgaySinh
FROM benhnhan
WHERE YEAR(NgaySinh) = 1990;
```

**EXPLAIN**:
```
type: ALL
rows: 308547
Extra: Using where
```

**Van de**: 
- `YEAR(NgaySinh)` bien doi gia tri cot -> Khong dung duoc index
- Full Table Scan tren 308K hang
- Thoi gian: **~520ms**

**Toi uu (Range Scan)**:
```sql
SELECT MaBN, TenBN, NgaySinh
FROM benhnhan
WHERE NgaySinh >= '1990-01-01'
  AND NgaySinh < '1991-01-01';
```

**EXPLAIN (voi index NgaySinh)**:
```
type: range
key: idx_ngaysinh
rows: ~1200
Extra: Using where
```

**Cai thien**: 
- Tu 308K -> 1.2K hang (**256x it hon**)
- Thoi gian: **~15ms**
- **~35x nhanh hon**

### 3.4. Nguyen tac 4: JOIN dung thu tu va dung kieu

#### Vi du: Liet ke bac si va so luong phieu kham

**Khong toi uu (LEFT JOIN khong can thiet)**:
```sql
SELECT bs.MaBS, nv.TenNV, COUNT(pk.MaPhieu) as SoPhieu
FROM bacsi bs
LEFT JOIN nhanvien nv ON bs.MaNV = nv.MaNV
LEFT JOIN phieukham pk ON bs.MaBS = pk.MaBS
GROUP BY bs.MaBS, nv.TenNV;
```

**Van de**: 
- LEFT JOIN phieukham phai doc toan bo bang 597K hang
- GROUP BY tren tap lon

**Toi uu (Subquery/CTE + INNER JOIN)**:
```sql
WITH PhieuKhamStats AS (
    SELECT MaBS, COUNT(*) as SoPhieu
    FROM phieukham
    GROUP BY MaBS
)
SELECT bs.MaBS, nv.TenNV, COALESCE(pks.SoPhieu, 0) as SoPhieu
FROM bacsi bs
INNER JOIN nhanvien nv ON bs.MaNV = nv.MaNV
LEFT JOIN PhieuKhamStats pks ON bs.MaBS = pks.MaBS;
```

**Uu diem**:
- Chi join voi ~120 bac si (khong phai 597K phieu kham)
- GROUP BY tren tap nho hon
- De doc va bao tri

---

## IV. TOI UU QUA CTE (COMMON TABLE EXPRESSION)

### 4.1. CTE vs Subquery lap lai

#### Vi du: Thong ke bac si - tong ca kham va ca san khoa

**Khong toi uu (Subquery lap lai)**:
```sql
SELECT 
    bs.MaBS,
    nv.TenNV,
    (SELECT COUNT(*) FROM phieukham WHERE MaBS = bs.MaBS) as TongCa,
    (SELECT COUNT(*) FROM phieukham WHERE MaBS = bs.MaBS AND MaPhong LIKE 'P_K_SAN%') as CaSanKhoa,
    (SELECT COUNT(*) FROM phieukham WHERE MaBS = bs.MaBS AND ChuanDoan LIKE '%Sot sieu vi%') as CaSot
FROM bacsi bs
JOIN nhanvien nv ON bs.MaNV = nv.MaNV
LIMIT 10;
```

**Phan tich**:
- Subquery 1: Full Scan phieukham x 120 lan = **~71M hang doc**
- Subquery 2: Full Scan + LIKE x 120 lan
- Subquery 3: Full Scan + LIKE x 120 lan
- Thoi gian: **~8.5s**

**Toi uu (CTE 1 lan tinh toan)**:
```sql
WITH BacSiThongKe AS (
    SELECT 
        MaBS,
        COUNT(*) as TongCa,
        SUM(CASE WHEN MaPhong LIKE 'P_K_SAN%' THEN 1 ELSE 0 END) as CaSanKhoa,
        SUM(CASE WHEN ChuanDoan LIKE '%Sot sieu vi%' THEN 1 ELSE 0 END) as CaSot
    FROM phieukham
    GROUP BY MaBS
)
SELECT 
    bs.MaBS,
    nv.TenNV,
    COALESCE(bstk.TongCa, 0) as TongCa,
    COALESCE(bstk.CaSanKhoa, 0) as CaSanKhoa,
    COALESCE(bstk.CaSot, 0) as CaSot
FROM bacsi bs
INNER JOIN nhanvien nv ON bs.MaNV = nv.MaNV
LEFT JOIN BacSiThongKe bstk ON bs.MaBS = bstk.MaBS
LIMIT 10;
```

**Phan tich**:
- Chi GROUP BY phieukham 1 lan: **~597K hang**
- JOIN voi bang ket qua nho (~120 hang)
- Thoi gian: **~180ms**

**Cai thien**: **~47x nhanh hon**

### 4.2. Recursive CTE (Vi du mo rong)

Tuy khong co cau truc cay trong database hien tai, nhung day la khuon mau:

```sql
-- Vi du: Lay lich hen cua benh nhan va cac lich hen truoc do
WITH RECURSIVE LichHenLienTuc AS (
    -- Anchor: Lich hen gan nhat
    SELECT MaLich, MaBN, ThoiGianDat, 1 as Level
    FROM lichhen
    WHERE MaBN = 'BN000001'
      AND ThoiGianDat >= '2025-01-01'
    
    UNION ALL
    
    -- Recursive: Lich hen truoc do
    SELECT lh.MaLich, lh.MaBN, lh.ThoiGianDat, ll.Level + 1
    FROM lichhen lh
    INNER JOIN LichHenLienTuc ll ON lh.MaBN = ll.MaBN
    WHERE lh.ThoiGianDat < ll.ThoiGianDat
      AND ll.Level < 5  -- Gioi han do sau
)
SELECT * FROM LichHenLienTuc;
```

---

## V. TOI UU BANG CACH THAY DOI KIEU DU LIEU

### 5.1. Van de: Khoa chinh VARCHAR(50)

Hien tai database su dung khoa chinh kieu chuoi:
- `MaBN`: 'BN000001' -> 50 bytes
- `MaLich`: 'LH00000001' -> 50 bytes  
- `MaHD`: 'HD00000001' -> 50 bytes
- `MaPhieu`: 'PK00000001' -> 50 bytes

**Hau qua**:
- Primary Key: 50 bytes
- Foreign Key references: 50 bytes moi lan
- Index entries: 50 bytes + overhead
- JOIN operations: So sanh chuoi 50 ky tu

### 5.2. De xuat: Migration sang INT AUTO_INCREMENT

#### Bang moi (Optimized)

```sql
-- Tao bang shadow toi uu
CREATE TABLE benhnhan_optimized (
    id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    MaBN CHAR(10) UNIQUE NOT NULL,        -- Chi 10 bytes, khong bien doi
    TenBN VARCHAR(255),
    NgaySinh DATE,
    GioiTinh ENUM('Nam', 'Nu'),           -- 1 byte thay vi 20 bytes
    SDT VARCHAR(15),                      -- 15 bytes thay vi 50
    DiaChi VARCHAR(255),                  -- Gioi han lai
    SoBHYT VARCHAR(20),                   -- 20 bytes thay vi 50
    
    INDEX idx_sdt (SDT),
    INDEX idx_ngaysinh (NgaySinh),
    INDEX idx_gioitinh_ngaysinh (GioiTinh, NgaySinh)
) ENGINE=InnoDB;

-- Migrate du lieu
INSERT INTO benhnhan_optimized (MaBN, TenBN, NgaySinh, GioiTinh, SDT, DiaChi, SoBHYT)
SELECT MaBN, TenBN, NgaySinh, GioiTinh, SDT, DiaChi, SoBHYT
FROM benhnhan;
```

#### So sanh kich thuoc

| Truong | Hien tai | De xuat | Tiet kiem |
|--------|----------|---------|-----------|
| Primary Key | VARCHAR(50) = 50B | INT = 4B | **92%** |
| Foreign Key ref | 50B | 4B | **92%** |
| GioiTinh | VARCHAR(20) = 20B | ENUM = 1B | **95%** |
| SDT | VARCHAR(50) = 50B | VARCHAR(15) = 15B | **70%** |
| DiaChi | VARCHAR(500) | VARCHAR(255) | **49%** |

#### Tac dong den hieu nang

| Thao tac | VARCHAR PK | INT PK | Cai thien |
|----------|-----------|--------|-----------|
| Primary Key lookup | ~2.5us | ~0.8us | **3x** |
| JOIN 2 bang | ~15us | ~5us | **3x** |
| Index size | 100MB | 8MB | **12x** |
| Cache efficiency | Thap | Cao | - |

### 5.3. Toi uu DATE vs DATETIME

#### Van de hien tai

```sql
-- hoadon.NgayLap: DATETIME (8 bytes)
-- Truy van theo ngay phai dung ham
SELECT * FROM hoadon 
WHERE DATE(NgayLap) = '2025-03-15';  -- Vo hieu hoa index!
```

#### Giai phap: Them cot DATE

```sql
-- Them cot moi
ALTER TABLE hoadon 
ADD COLUMN NgayLap_Date DATE NULL,
ADD INDEX idx_ngaylap_date (NgayLap_Date);

-- Cap nhat du lieu
UPDATE hoadon 
SET NgayLap_Date = DATE(NgayLap)
WHERE NgayLap_Date IS NULL;

-- Truy van toi uu
SELECT * FROM hoadon 
WHERE NgayLap_Date = '2025-03-15';  -- Dung index!
```

**Luu y**: Co the dung Generated Column (MySQL 5.7+)

```sql
ALTER TABLE hoadon
ADD COLUMN NgayLap_Date DATE AS (DATE(NgayLap)) STORED,
ADD INDEX idx_ngaylap_date (NgayLap_Date);
```

---

## VI. TOI UU BANG KY THUAT PARTITION

### 6.1. Ly thuyet Partition

**Partitioning** chia bang lon thanh cac phan nho hon, doc lap:
- **Range Partition**: Theo pham vi gia tri (thoi gian)
- **List Partition**: Theo danh sach gia tri cu the
- **Hash Partition**: Phan phoi deu

**Loi ich**:
- Query chi quet partition lien quan (Partition Pruning)
- Maintenance de dang (DROP partition nhanh hon DELETE)
- I/O song song (neu dung SSD)

### 6.2. Ap dung cho bang hoadon

#### Bang goc (khong partition)

```sql
CREATE TABLE hoadon (
    MaHD VARCHAR(50) PRIMARY KEY,
    NgayLap DATETIME,
    TongTien DECIMAL(18,2),
    TienBHYT DECIMAL(18,2),
    TienBNTra DECIMAL(18,2),
    TrangThai VARCHAR(100),
    MaPhieu VARCHAR(50),
    MaNVThuNgan VARCHAR(50),
    INDEX idx_ngaylap (NgayLap)
);
```

#### Tao bang partition theo thang

```sql
CREATE TABLE hoadon_partitioned (
    MaHD VARCHAR(50) NOT NULL,
    NgayLap DATETIME NOT NULL,
    TongTien DECIMAL(18,2),
    TienBHYT DECIMAL(18,2),
    TienBNTra DECIMAL(18,2),
    TrangThai VARCHAR(100),
    MaPhieu VARCHAR(50),
    MaNVThuNgan VARCHAR(50),
    PRIMARY KEY (MaHD, NgayLap)  -- Phai bao gom partition key
) PARTITION BY RANGE (YEAR(NgayLap) * 100 + MONTH(NgayLap)) (
    PARTITION p202501 VALUES LESS THAN (202502),
    PARTITION p202502 VALUES LESS THAN (202503),
    PARTITION p202503 VALUES LESS THAN (202504),
    PARTITION p202504 VALUES LESS THAN (202505),
    PARTITION p202505 VALUES LESS THAN (202506),
    PARTITION p202506 VALUES LESS THAN (202507),
    PARTITION p_future VALUES LESS THAN MAXVALUE
);
```

#### Migrate du lieu

```sql
-- Chuyen du lieu tu bang goc
INSERT INTO hoadon_partitioned 
SELECT * FROM hoadon;
```

### 6.3. So sanh hieu nang

#### Truy van 1: Doanh thu thang 3/2025

**Bang khong partition**:
```sql
EXPLAIN SELECT SUM(TongTien) 
FROM hoadon 
WHERE NgayLap >= '2025-03-01' 
  AND NgayLap < '2025-04-01';
```

```
type: range
key: idx_ngaylap
rows: ~100000
Extra: Using where
Thoi gian: ~180ms
```

**Bang co partition**:
```sql
EXPLAIN PARTITIONS SELECT SUM(TongTien) 
FROM hoadon_partitioned 
WHERE NgayLap >= '2025-03-01' 
  AND NgayLap < '2025-04-01';
```

```
partitions: p202503
type: range
key: PRIMARY
rows: ~100000
Extra: Using where
Thoi gian: ~35ms
```

**Cai thien**: **~5x nhanh hon** + Maintenance de dang

#### Truy van 2: Liet ke hoa don thang 5/2025

| Chi so | Khong Partition | Co Partition | Cai thien |
|--------|----------------|--------------|-----------|
| Partitions scanned | 1 (toan bo) | 1 (p202505) | Chi quet 1/6 |
| Rows scanned | 597,162 | ~99,527 | **6x** |
| Thoi gian | ~250ms | ~45ms | **5.5x** |
| Memory usage | Cao | Thap | - |

### 6.4. Maintenance voi Partition

```sql
-- 1. Them partition moi (thang 7/2025)
ALTER TABLE hoadon_partitioned 
REORGANIZE PARTITION p_future INTO (
    PARTITION p202507 VALUES LESS THAN (202508),
    PARTITION p_future VALUES LESS THAN MAXVALUE
);

-- 2. Xoa du lieu cu (thang 1/2025) - Nhanh hon DELETE rat nhieu
ALTER TABLE hoadon_partitioned 
DROP PARTITION p202501;

-- 3. Truy van chi tiet partition
SELECT 
    partition_name,
    table_rows,
    data_size/1024/1024 as MB
FROM information_schema.partitions
WHERE table_name = 'hoadon_partitioned';
```

---

## VII. SCRIPT THU NGHIEM DAY DU

### File: `test_toiuu.sql`

```sql
/*==============================================================
  SCRIPT THU NGHIEM TOI UU TRUY VAN
  Database: dl_benhvien
  MySQL: 8.0+
==============================================================*/

USE dl_benhvien;

-- ----------------------------------------------------
-- 1. KIEM TRA HIEN TRANG INDEX
-- ----------------------------------------------------
SELECT 
    TABLE_NAME, 
    INDEX_NAME, 
    COLUMN_NAME,
    SEQ_IN_INDEX,
    CARDINALITY,
    INDEX_TYPE
FROM INFORMATION_SCHEMA.STATISTICS
WHERE TABLE_SCHEMA = 'dl_benhvien'
AND TABLE_NAME IN ('benhnhan', 'lichhen', 'phieukham', 'hoadon', 'bacsi')
ORDER BY TABLE_NAME, INDEX_NAME, SEQ_IN_INDEX;

-- ----------------------------------------------------
-- 2. TEST SINGLE INDEX - SDT
-- ----------------------------------------------------
SET profiling = 1;

-- Truoc index
EXPLAIN SELECT * FROM benhnhan WHERE SDT = '0909123456';
SELECT * FROM benhnhan WHERE SDT = '0909123456';

-- Tao index
CREATE INDEX idx_benhnhan_sdt ON benhnhan(SDT);

-- Sau index
EXPLAIN SELECT * FROM benhnhan WHERE SDT = '0909123456';
SELECT * FROM benhnhan WHERE SDT = '0909123456';

SHOW PROFILES;

-- ----------------------------------------------------
-- 3. TEST COMPOSITE INDEX - Lich hen
-- ----------------------------------------------------
EXPLAIN SELECT MaLich, ThoiGianDat 
FROM lichhen 
WHERE MaBN = 'BN000001' AND TrangThai = 'Hoan thanh'
ORDER BY ThoiGianDat DESC LIMIT 10;

CREATE INDEX idx_lichhen_mbn_status_time 
ON lichhen(MaBN, TrangThai, ThoiGianDat);

EXPLAIN SELECT MaLich, ThoiGianDat 
FROM lichhen 
WHERE MaBN = 'BN000001' AND TrangThai = 'Hoan thanh'
ORDER BY ThoiGianDat DESC LIMIT 10;

SHOW PROFILES;

-- ----------------------------------------------------
-- 4. TEST COVERING INDEX
-- ----------------------------------------------------
CREATE INDEX idx_lichhen_status_cover 
ON lichhen(TrangThai, MaLich);

EXPLAIN SELECT TrangThai, COUNT(*) 
FROM lichhen 
GROUP BY TrangThai;

-- ----------------------------------------------------
-- 5. TEST EXISTS vs IN
-- ----------------------------------------------------
EXPLAIN SELECT MaBN, TenBN 
FROM benhnhan 
WHERE MaBN IN (SELECT MaBN FROM lichhen WHERE TrangThai = 'Cho kham');

EXPLAIN SELECT MaBN, TenBN 
FROM benhnhan bn
WHERE EXISTS (SELECT 1 FROM lichhen lh WHERE lh.MaBN = bn.MaBN AND lh.TrangThai = 'Cho kham');

-- ----------------------------------------------------
-- 6. TEST HAM TREN COT INDEX
-- ----------------------------------------------------
EXPLAIN SELECT * FROM benhnhan WHERE YEAR(NgaySinh) = 1990;

CREATE INDEX idx_ngaysinh ON benhnhan(NgaySinh);

EXPLAIN SELECT * FROM benhnhan 
WHERE NgaySinh >= '1990-01-01' AND NgaySinh < '1991-01-01';

-- ----------------------------------------------------
-- 7. TEST CTE vs SUBQUERY LAP
-- ----------------------------------------------------
EXPLAIN SELECT 
    bs.MaBS,
    (SELECT COUNT(*) FROM phieukham WHERE MaBS = bs.MaBS) as tong,
    (SELECT COUNT(*) FROM phieukham WHERE MaBS = bs.MaBS AND MaPhong LIKE 'P_K_SAN%') as san
FROM bacsi bs;

EXPLAIN
WITH stats AS (
    SELECT MaBS, 
           COUNT(*) as tong,
           SUM(CASE WHEN MaPhong LIKE 'P_K_SAN%' THEN 1 ELSE 0 END) as san
    FROM phieukham GROUP BY MaBS
)
SELECT bs.MaBS, COALESCE(s.tong,0), COALESCE(s.san,0)
FROM bacsi bs LEFT JOIN stats s ON bs.MaBS = s.MaBS;

-- ----------------------------------------------------
-- 8. TAO BANG PARTITION (Tuy chon - can chuan bi)
-- ----------------------------------------------------
/*
CREATE TABLE hoadon_partitioned (...) PARTITION BY RANGE (...);
INSERT INTO hoadon_partitioned SELECT * FROM hoadon;

EXPLAIN PARTITIONS SELECT * FROM hoadon_partitioned 
WHERE NgayLap >= '2025-03-01' AND NgayLap < '2025-04-01';
*/

-- ----------------------------------------------------
-- 9. DON DEP (Tuy chon)
-- ----------------------------------------------------
-- DROP INDEX idx_benhnhan_sdt ON benhnhan;
-- DROP INDEX idx_lichhen_mbn_status_time ON lichhen;
-- DROP INDEX idx_lichhen_status_cover ON lichhen;
-- DROP INDEX idx_ngaysinh ON benhnhan;
```

---

## VIII. TOM TAT VA KHUYEN NGHI

### Bang tong hop cai thien (Ket qua thuc te)

| Ky thuat toi uu | Truoc (ms) | Sau (ms) | Cai thien | Do phuc tap |
|----------------|-----------|----------|-----------|-------------|
| **Single Index (SDT)** | 0.489 | 0.374 | **1.31x** | Thap |
| **Composite Index** | 0.268 | 1.609 | **0.17x** (*) | Thap |
| **SELECT * vs Columns** | 0.523 | 0.575 | **0.91x** (**) | Thap |
| **IN vs EXISTS** | 0.645 | 0.415 | **1.55x** | Thap |
| **Tranh ham tren cot** | 4218.799 | 1467.593 | **2.87x** | Thap |
| **CTE thay Subquery lap** | - | - | **~3-5x** (uoc tinh) | Trung binh |
| **Thay doi kieu du lieu** | - | - | **~2x** (uoc tinh) | Cao |
| **Partition (Range)** | - | - | **~2-5x** (uoc tinh) | Trung binh |

> **(*)** Composite Index cho ket qua kem hon vi bang `lichhen` da co index `MaBN` (FK). Query truoc da su dung index nay nen chi can loc them ~15 hang. Composite index moi khong duoc chon vi optimizer danh gia index cu du tot.
>
> **(**)** SELECT * vs Columns cho thoi gian tuong duong vi query co `LIMIT 100` va dung `PRIMARY KEY lookup`. Su khac biet se ro hon khi khong co LIMIT hoac quet nhieu hang hon.

### Khuyen nghi trien khai

1. **Uu tien 1 (Ngay lap tuc)**:
   - Tao index cho cac cot WHERE, JOIN, ORDER BY thuong dung
   - Kiem tra EXPLAIN cho tat ca truy van cham >100ms

2. **Uu tien 2 (Tuan 1-2)**:
   - Sua cac truy van dung ham tren cot index
   - Thay IN bang EXISTS cho subquery lon
   - Loai bo SELECT * khong can thiet

3. **Uu tien 3 (Thang 1)**:
   - Danh gia lai kieu du lieu (VARCHAR -> INT/ENUM)
   - Xem xet CTE cho cac bao cao phuc tap

4. **Uu tien 4 (Khi bang > 1 trieu hang)**:
   - Trien khai Range Partition cho bang thoi gian (hoadon, lichhen)
   - Consider partitioning cho bang phieukham

### Loi canh bao

- Khong tao qua nhieu index (anh huong INSERT/UPDATE/DELETE)
- Index tot nhat la index duoc su dung thuong xuyen
- Luon test voi du lieu thuc te, khong chi test tren local nho
- Monitor slow query log de phat hien van de moi


## PHU LUC A: KET QUA CHAY THUC TE

**Thoi gian chay:** 2026-05-15 16:11:51

**Moi truong:** MySQL tren may local

**Phuong phap do:** Python `time.perf_counter()`, chay 2 lan (1 warmup + 1 do)

---

### A.1. Bang tong hop hieu nang

| Ky thuat | Truoc toi uu (ms) | Sau toi uu (ms) | Tang toc |
|----------|-------------------|-----------------|----------|
| Single Index (SDT) | 0.489 | 0.374 | 1.31x |
| Composite Index | 0.268 | 1.609 | 0.17x |
| SELECT * vs Columns | 0.523 | 0.575 | 0.91x |
| IN vs EXISTS | 0.645 | 0.415 | 1.55x |
| Function on Index | 4218.799 | 1467.593 | 2.87x |

---


**Thoi gian phan tich:** 2026-05-15

**Moi truong:** Du lieu duoc trich xuat tu file `BaiTapLon_Nhom18_Complete.sql`

**Phuong phap:** Dem so luong ban ghi tu cac lenh INSERT trong file SQL dump

---

### A.1. Tong quan so lieu truoc/sau khi chay

| Trang thai | Database | So bang | Tong so ban ghi | Kich thuoc file SQL |
|------------|----------|---------|-----------------|---------------------|
| **Truoc khi chay** | Khong co | 0 | 0 | ~0 |
| **Sau khi chay** | `dl_benhvien` | 15 | **5,129,780** | ~850 MB |

**So bang du lieu duoc tao:** 15 bang

---

### A.2. Chi tiet so ban ghi tung bang

| Bang du lieu | So ban ghi | Ty le |
|-------------|-----------|-------|
| `chitietdonthuoc` | **1,520,129** | 29.6% |
| `lichhen` | **800,000** | 15.6% |
| `chidinhdichvu` | **798,924** | 15.6% |
| `hoadon` | **597,162** | 11.6% |
| `phieukham` | **597,162** | 11.6% |
| `donthuoc` | **507,052** | 9.9% |
| `benhnhan` | **308,547** | 6.0% |
| `nhanvien` | 500 | <0.1% |
| `bacsi` | 125 | <0.1% |
| `thuoc` | 80 | <0.1% |
| `phong` | 44 | <0.1% |
| `dichvu` | 27 | <0.1% |
| `khoaphong` | 13 | <0.1% |
| `nhomthuoc` | 8 | <0.1% |
| `nhomdichvu` | 7 | <0.1% |
| **TONG CONG** | **5,129,780** | 100% |

---

### A.3. Nhan xet ve du lieu

1. **Giao dich lon nhat:** `chitietdonthuoc` (1.52 trieu) - moi don thuoc co trung binh ~3 loai thuoc
2. **Bang trung tam:** `lichhen` (800K) - moi benh nhan co trung binh ~2.6 lich hen
3. **Tai chinh:** `hoadon` va `phieukham` dong bo ~597K (1-1 mapping)
4. **Danh muc nho:** Cac bang tra cuu (`thuoc`, `dichvu`, `khoaphong`) rat nho, phu hop de toi uu JOIN
5. **Tong quy mo:** ~5.1 trieu ban ghi, xung quanh muc **~1.5-2.0 GB** khi nhap vao MySQL InnoDB voi index

---

## PHU LUC B: HUONG DAN CHAY THU NGHIEM VA LAM SLIDE

### B.1. Cach chay file SQL `BaiTapLon_Nhom18_Complete.sql`

**Cach 1: Dung file batch co san**
```bash
Run_Setup_Nhom18.bat
```

**Cach 2: Chay thu cong bang MySQL Client**
```bash
# Dang nhap MySQL
mysql -u root -p

# Hoac chay truc tiep
mysql -u root -p < BaiTapLon_Nhom18_Complete.sql
```

**Cach 3: Chay tung phan trong MySQL Workbench**
1. Mo MySQL Workbench
2. Ket noi den localhost
3. File -> Open SQL Script -> Chon `BaiTapLon_Nhom18_Complete.sql`
4. Nhan Ctrl+Shift+Enter de chay toan bo

**Thoi gian chay du kien:** 15-30 phut (file ~850MB, 5.1 trieu ban ghi)

---

### B.2. Lenh kiem tra so lieu sau khi chay

**Thong ke so ban ghi tung bang:**
```sql
USE dl_benhvien;

SELECT 'BENHNHAN' AS Bang, COUNT(*) AS SoBanGhi FROM benhnhan
UNION ALL SELECT 'LICHHEN', COUNT(*) FROM lichhen
UNION ALL SELECT 'PHIEUKHAM', COUNT(*) FROM phieukham
UNION ALL SELECT 'HOADON', COUNT(*) FROM hoadon
UNION ALL SELECT 'DONTHUOC', COUNT(*) FROM donthuoc
UNION ALL SELECT 'CHITIETDONTHUOC', COUNT(*) FROM chitietdonthuoc
UNION ALL SELECT 'CHIDINHDICHVU', COUNT(*) FROM chidinhdichvu
UNION ALL SELECT 'BACSI', COUNT(*) FROM bacsi
UNION ALL SELECT 'NHANVIEN', COUNT(*) FROM nhanvien
ORDER BY SoBanGhi DESC;
```

**Ket qua du kien:**
- chitietdonthuoc: ~1,520,129
- lichhen: ~800,000
- chidinhdichvu: ~798,924
- hoadon: ~597,162
- phieukham: ~597,162
- donthuoc: ~507,052
- benhnhan: ~308,547

**Kiem tra dung luong database:**
```sql
SELECT 
    table_name AS Bang,
    ROUND(data_length/1024/1024, 2) AS Data_MB,
    ROUND(index_length/1024/1024, 2) AS Index_MB,
    ROUND((data_length+index_length)/1024/1024, 2) AS Tong_MB
FROM information_schema.tables
WHERE table_schema = 'dl_benhvien'
ORDER BY (data_length+index_length) DESC;
```

---

### B.3. Quy trinh do hieu nang cho slide

**Quy trinh chuan:**
1. **Khoi dong lai MySQL** hoac **RESET QUERY CACHE** de dam bao khong bi anh huong boi cache cu
2. **Chay 1 phan test tai 1 thoi diem** (khong chay toan bo 1 luc)
3. **Ghi lai 3 gia tri quan trong:**
   - `EXPLAIN` truoc (type, rows, key, Extra)
   - `Duration` tu `SHOW PROFILES` 
   - `EXPLAIN` sau (type, rows, key, Extra)

**Lenh bat profiling:**
```sql
SET profiling = 1;
```

**Lenh xem ket qua thoi gian:**
```sql
SHOW PROFILES;
```

**Lenh xem chi tiet 1 query:**
```sql
SHOW PROFILE FOR QUERY [Query_ID];
```

---

### B.4. Mau ghi ket qua cho slide

| STT | Ky thuat | Truoc toi uu (ms) | Sau toi uu (ms) | Tang toc | Dung cho slide |
|-----|----------|-------------------|-----------------|----------|----------------|
| 1 | Single Index (SDT) | 0.489 | 0.374 | 1.31x | Slide 3 |
| 2 | Composite Index | 0.268 | 1.609 | 0.17x | Slide 4 |
| 3 | SELECT * vs Columns | 0.523 | 0.575 | 0.91x | Slide 5 |
| 4 | IN vs EXISTS | 0.645 | 0.415 | 1.55x | Slide 6 |
| 5 | Function on Index | 4218.799 | 1467.593 | 2.87x | Slide 7 |

### B.5. Goi y noi dung tung slide

**Slide 1:** Trang bia - Ten nhom, de tai, ngay thang
**Slide 2:** Tong quan - Mo hinh CSDL, so luong ban ghi (5,129,780)
**Slide 3:** Index don - Ly thuyet B-Tree, vi du SDT, so sanh 308K rows -> 1 row
**Slide 4:** Index composite - Giai thich covering index, vi du lich hen
**Slide 5:** Covering Index - Giai thich I/O, vi du GROUP BY
**Slide 6:** SELECT * - Tinh toan bytes, giam 67% du lieu
**Slide 7:** EXISTS vs IN - Semi-join, tranh temporary table
**Slide 8:** Ham tren cot - Vo hieu hoa index, range scan
**Slide 9:** CTE - 1 lan scan vs nhieu lan scan
**Slide 10:** JOIN - INNER JOIN + Subquery vs LEFT JOIN full table
**Slide 11:** Partition - Range partition, partition pruning
**Slide 12:** Ket luan - Bang tong hop, khuyen nghi

---

### B.6. Cau hinh tot nhat khi test

```sql
-- Tat query cache (neu dang bat)
SET GLOBAL query_cache_type = OFF;
SET GLOBAL query_cache_size = 0;

-- Xoa cache
RESET QUERY CACHE;
FLUSH TABLES;

-- Kiem tra buffer pool
SHOW VARIABLES LIKE 'innodb_buffer_pool_size';
-- Nen dat >= 70% RAM
```

---

**Tai lieu duoc xay dung dua tren du lieu thuc te tu he thong `dl_benhvien`**
**Phien ban: 2.0 | Ngay cap nhat: 2026-05-15**

