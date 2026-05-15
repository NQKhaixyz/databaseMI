# Script chạy benchmark và tự động điền kết quả vào file MD
# Yêu cầu: pip install mysql-connector-python

import mysql.connector
import time
import re
from datetime import datetime

# Cấu hình MySQL - SỬA LẠI CHO ĐÚNG MÁY BẠN
CONFIG = {
    "host": "localhost",
    "user": "root",
    "password": "root",  # <-- SỬA MẬT KHẨU MYSQL CỦA BẠN
    "database": "dl_benhvien",
    "charset": "utf8mb4",
}

# Các test case: (tên, query_truoc, query_sau, index_can_tao, index_can_xoa)
TESTS = [
    (
        "Single Index (SDT)",
        "SELECT MaBN, TenBN, NgaySinh, DiaChi FROM benhnhan WHERE SDT = '0909123456'",
        "SELECT MaBN, TenBN, NgaySinh, DiaChi FROM benhnhan WHERE SDT = '0909123456'",
        "CREATE INDEX idx_test_sdt ON benhnhan(SDT)",
        "DROP INDEX idx_test_sdt ON benhnhan",
    ),
    (
        "Composite Index",
        "SELECT MaLich, ThoiGianDat FROM lichhen WHERE MaBN = 'BN000001' AND TrangThai = 'Hoàn thành' ORDER BY ThoiGianDat DESC LIMIT 10",
        "SELECT MaLich, ThoiGianDat FROM lichhen WHERE MaBN = 'BN000001' AND TrangThai = 'Hoàn thành' ORDER BY ThoiGianDat DESC LIMIT 10",
        "CREATE INDEX idx_test_composite ON lichhen(MaBN, TrangThai, ThoiGianDat)",
        "DROP INDEX idx_test_composite ON lichhen",
    ),
    (
        "SELECT * vs Columns",
        "SELECT * FROM benhnhan WHERE MaBN = 'BN000001'",
        "SELECT MaBN, TenBN, NgaySinh FROM benhnhan WHERE MaBN = 'BN000001'",
        None,
        None,
    ),
    (
        "IN vs EXISTS",
        "SELECT MaBN, TenBN FROM benhnhan WHERE MaBN IN (SELECT DISTINCT MaBN FROM lichhen WHERE TrangThai = 'Chờ khám') LIMIT 100",
        "SELECT MaBN, TenBN FROM benhnhan bn WHERE EXISTS (SELECT 1 FROM lichhen lh WHERE lh.MaBN = bn.MaBN AND lh.TrangThai = 'Chờ khám') LIMIT 100",
        None,
        None,
    ),
    (
        "Function on Index",
        "SELECT * FROM lichhen WHERE YEAR(ThoiGianDat) = 2025",
        "SELECT * FROM lichhen WHERE ThoiGianDat >= '2025-01-01' AND ThoiGianDat < '2026-01-01'",
        None,
        None,
    ),
]


def run_query(cursor, query, warmup=True):
    """Chạy query và đo thời gian"""
    # Warm-up
    if warmup:
        cursor.execute(query)
        cursor.fetchall()

    # Đo thực tế
    start = time.perf_counter()
    cursor.execute(query)
    cursor.fetchall()
    end = time.perf_counter()

    return (end - start) * 1000  # Convert to ms


def explain_query(cursor, query):
    """Lấy EXPLAIN cho query"""
    cursor.execute(f"EXPLAIN {query}")
    return cursor.fetchall()


def run_benchmark():
    results = []

    try:
        conn = mysql.connector.connect(**CONFIG)
        cursor = conn.cursor()

        print("=" * 60)
        print("BENCHMARK TOI UU TRUY VAN - NHOM 18")
        print("=" * 60)

        # Xóa cache (MySQL 8.0 không còn query cache, chỉ flush tables)
        try:
            cursor.execute("FLUSH TABLES")
        except:
            pass

        for i, (name, query_truoc, query_sau, idx_create, idx_drop) in enumerate(
            TESTS, 1
        ):
            print(f"\n[{i}/{len(TESTS)}] Testing: {name}")
            print("-" * 60)

            # Chạy trước tối ưu
            print("  -> Chay TRUOC toi uu...")
            time_truoc = run_query(cursor, query_truoc)
            print(f"     Thoi gian: {time_truoc:.3f} ms")

            explain_truoc = explain_query(cursor, query_truoc)

            # Tạo index nếu cần
            if idx_create:
                print(f"  -> Tao index...")
                cursor.execute(idx_create)
                conn.commit()

            # Chạy sau tối ưu
            print("  -> Chay SAU toi uu...")
            time_sau = run_query(cursor, query_sau)
            print(f"     Thoi gian: {time_sau:.3f} ms")

            explain_sau = explain_query(cursor, query_sau)

            # Xóa index nếu đã tạo
            if idx_drop:
                try:
                    cursor.execute(idx_drop)
                    conn.commit()
                except:
                    pass

            speedup = time_truoc / time_sau if time_sau > 0 else 0
            print(f"  -> Tang toc: {speedup:.2f}x")

            results.append(
                {
                    "name": name,
                    "truoc": time_truoc,
                    "sau": time_sau,
                    "speedup": speedup,
                    "explain_truoc": explain_truoc,
                    "explain_sau": explain_sau,
                }
            )

        cursor.close()
        conn.close()

        return results

    except Exception as e:
        print(f"LOI: {e}")
        print("\nHay kiem tra lai:")
        print("1. MySQL da bat chua?")
        print("2. Database 'dl_benhvien' da duoc tao chua?")
        print("3. Username/password trong CONFIG co dung khong?")
        return None


def update_md_file(results):
    """Cập nhật kết quả vào file MD"""
    with open("ToiUuTruyVan_Nhom18.md", "r", encoding="utf-8") as f:
        content = f.read()

    # Tạo bảng kết quả
    table_lines = [
        "| STT | Ky thuat | Truoc toi uu (ms) | Sau toi uu (ms) | Tang toc | Dung cho slide |",
        "|-----|----------|-------------------|-----------------|----------|----------------|",
    ]

    for i, r in enumerate(results, 1):
        slide = f"Slide {i + 2}"
        table_lines.append(
            f"| {i} | {r['name']} | {r['truoc']:.3f} | {r['sau']:.3f} | {r['speedup']:.2f}x | {slide} |"
        )

    table_text = "\n".join(table_lines)

    # Tìm và thay thế phần bảng B.4 trong file
    pattern = r"(### B\.4\. Mau ghi ket qua cho slide\n\n)(.*?)(\n\n### B\.5\.)"

    if re.search(pattern, content, re.DOTALL):
        content = re.sub(pattern, r"\1" + table_text + r"\3", content, flags=re.DOTALL)

    # Tạo phần kết quả chi tiết cho Phụ lục A
    appendix = []
    appendix.append("\n## PHU LUC A: KET QUA CHAY THUC TE")
    appendix.append(
        f"\n**Thoi gian chay:** {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}"
    )
    appendix.append(f"\n**Moi truong:** MySQL tren may local")
    appendix.append(
        f"\n**Phuong phap do:** Python `time.perf_counter()`, chay 2 lan (1 warmup + 1 do)"
    )
    appendix.append("\n---\n")
    appendix.append("### A.1. Bang tong hop hieu nang\n")
    appendix.append("| Ky thuat | Truoc toi uu (ms) | Sau toi uu (ms) | Tang toc |")
    appendix.append("|----------|-------------------|-----------------|----------|")

    for r in results:
        appendix.append(
            f"| {r['name']} | {r['truoc']:.3f} | {r['sau']:.3f} | {r['speedup']:.2f}x |"
        )

    appendix.append("\n---\n")

    # Chèn vào trước Phụ lục B
    appendix_text = "\n".join(appendix)

    if "## PHU LUC B" in content:
        content = content.replace("## PHU LUC B", appendix_text + "\n\n## PHU LUC B", 1)

    # Ghi file
    with open("ToiUuTruyVan_Nhom18.md", "w", encoding="utf-8") as f:
        f.write(content)

    print(f"\n✅ Da cap nhat ket qua vao ToiUuTruyVan_Nhom18.md")


def main():
    print("Script Benchmark - Nhom 18")
    print("=" * 60)
    print(f"Database: {CONFIG['database']}")
    print(f"Host: {CONFIG['host']}")
    print(f"User: {CONFIG['user']}")
    print("=" * 60)
    print("\nDang ket noi MySQL...")

    results = run_benchmark()

    if results:
        print("\n" + "=" * 60)
        print("TOM TAT KET QUA")
        print("=" * 60)
        for r in results:
            print(
                f"{r['name']}: {r['truoc']:.3f}ms -> {r['sau']:.3f}ms ({r['speedup']:.2f}x)"
            )

        update_md_file(results)

        # Xuất ra file riêng để backup
        with open("ket_qua_benchmark.txt", "w", encoding="utf-8") as f:
            f.write("KET QUA BENCHMARK - NHOM 18\n")
            f.write(f"Thoi gian: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}\n\n")
            for r in results:
                f.write(f"{r['name']}:\n")
                f.write(f"  Truoc: {r['truoc']:.3f} ms\n")
                f.write(f"  Sau: {r['sau']:.3f} ms\n")
                f.write(f"  Tang toc: {r['speedup']:.2f}x\n\n")

        print(f"\n✅ Da luu ket qua chi tiet vao: ket_qua_benchmark.txt")


if __name__ == "__main__":
    main()
