# Huong dan chay one-go

## 1) Chay tat ca trong 1 lan

Chay file:

`RUN_ONE_GO_NHOM18.bat`

Script se:
- Kiem tra/cai dependency MySQL client
- Build day du DB tu file tong hop `BaiTapLon_Nhom18_Complete.sql`
- Test tong the va sinh report

## 2) Bien moi truong tuy chon

Mac dinh:
- `MYSQL_USER=root`
- `MYSQL_PASSWORD=root`
- `MYSQL_HOST=localhost`
- `MYSQL_PORT=3306`
- `MYSQL_DATABASE=dl_benhvien`

Neu muon doi, set truoc khi chay:

```bat
set MYSQL_USER=root
set MYSQL_PASSWORD=your_password
set MYSQL_HOST=localhost
set MYSQL_PORT=3306
set MYSQL_DATABASE=dl_benhvien
RUN_ONE_GO_NHOM18.bat
```

## 3) File report

Sau khi test xong, report o dang:

`Test_Report_Nhom18_YYYYMMDD_HHMMSS.txt`
