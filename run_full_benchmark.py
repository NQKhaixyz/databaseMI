import mysql.connector
import time
import json
from datetime import datetime

CONFIG = {
    "host": "localhost",
    "user": "root",
    "password": "root",
    "database": "dl_benhvien",
    "charset": "utf8mb4",
}


def run_query(cursor, query, warmup=True, runs=3):
    if warmup:
        cursor.execute(query)
        cursor.fetchall()

    times = []
    for _ in range(runs):
        start = time.perf_counter()
        cursor.execute(query)
        cursor.fetchall()
        end = time.perf_counter()
        times.append((end - start) * 1000)

    return sum(times) / len(times)


def explain_query(cursor, query):
    cursor.execute(f"EXPLAIN {query}")
    cols = [d[0] for d in cursor.description]
    rows = cursor.fetchall()
    return [dict(zip(cols, row)) for row in rows]


def get_explain_str(cursor, query):
    rows = explain_query(cursor, query)
    if not rows:
        return "N/A"
    r = rows[0]
    parts = []
    for k in ["select_type", "table", "type", "possible_keys", "key", "rows", "Extra"]:
        if k in r:
            parts.append(f"{k}={r[k]}")
    return " | ".join(parts)


def main():
    conn = mysql.connector.connect(**CONFIG)
    cursor = conn.cursor()

    # Kiểm tra SDT tồn tại
    cursor.execute(
        "SELECT SDT FROM benhnhan WHERE SDT IS NOT NULL AND SDT != '' LIMIT 1"
    )
    sdt_val = cursor.fetchone()[0]

    # Kiểm tra MaBN tồn tại trong lichhen
    cursor.execute("SELECT MaBN, TrangThai FROM lichhen LIMIT 1")
    row = cursor.fetchone()
    mabn_val = row[0]
    trangthai_val = row[1]

    results = []

    # =====================
    # 1. Single Index (SDT)
    # =====================
    print("\n[1/7] Single Index (SDT)...")
    cursor.execute("FLUSH TABLES")

    query1_truoc = (
        f"SELECT MaBN, TenBN, NgaySinh, DiaChi FROM benhnhan WHERE SDT = '{sdt_val}'"
    )
    time1_truoc = run_query(cursor, query1_truoc)
    explain1_truoc = get_explain_str(cursor, query1_truoc)

    cursor.execute("CREATE INDEX idx_bench_sdt ON benhnhan(SDT)")
    cursor.execute("FLUSH TABLES")

    query1_sau = (
        f"SELECT MaBN, TenBN, NgaySinh, DiaChi FROM benhnhan WHERE SDT = '{sdt_val}'"
    )
    time1_sau = run_query(cursor, query1_sau)
    explain1_sau = get_explain_str(cursor, query1_sau)

    cursor.execute("DROP INDEX idx_bench_sdt ON benhnhan")

    results.append(
        {
            "name": "Single Index (SDT)",
            "truoc": time1_truoc,
            "sau": time1_sau,
            "speedup": time1_truoc / time1_sau if time1_sau > 0 else 0,
            "explain_truoc": explain1_truoc,
            "explain_sau": explain1_sau,
        }
    )
    print(
        f"  Truoc: {time1_truoc:.3f}ms | Sau: {time1_sau:.3f}ms | Speedup: {time1_truoc / time1_sau:.2f}x"
    )

    # =====================
    # 2. Composite Index
    # =====================
    print("\n[2/7] Composite Index...")
    cursor.execute("FLUSH TABLES")

    query2_truoc = f"SELECT MaLich, ThoiGianDat FROM lichhen WHERE MaBN = '{mabn_val}' AND TrangThai = '{trangthai_val}' ORDER BY ThoiGianDat DESC LIMIT 10"
    time2_truoc = run_query(cursor, query2_truoc)
    explain2_truoc = get_explain_str(cursor, query2_truoc)

    cursor.execute(
        "CREATE INDEX idx_bench_composite ON lichhen(MaBN, TrangThai, ThoiGianDat)"
    )
    cursor.execute("FLUSH TABLES")

    time2_sau = run_query(cursor, query2_truoc)
    explain2_sau = get_explain_str(cursor, query2_truoc)

    cursor.execute("DROP INDEX idx_bench_composite ON lichhen")

    results.append(
        {
            "name": "Composite Index",
            "truoc": time2_truoc,
            "sau": time2_sau,
            "speedup": time2_truoc / time2_sau if time2_sau > 0 else 0,
            "explain_truoc": explain2_truoc,
            "explain_sau": explain2_sau,
        }
    )
    print(
        f"  Truoc: {time2_truoc:.3f}ms | Sau: {time2_sau:.3f}ms | Speedup: {time2_truoc / time2_sau:.2f}x"
    )

    # =====================
    # 3. Covering Index
    # =====================
    print("\n[3/7] Covering Index...")
    cursor.execute("FLUSH TABLES")

    query3 = "SELECT TrangThai, COUNT(*) FROM lichhen GROUP BY TrangThai"
    time3_truoc = run_query(cursor, query3)
    explain3_truoc = get_explain_str(cursor, query3)

    cursor.execute("CREATE INDEX idx_bench_covering ON lichhen(TrangThai, MaLich)")
    cursor.execute("FLUSH TABLES")

    time3_sau = run_query(cursor, query3)
    explain3_sau = get_explain_str(cursor, query3)

    cursor.execute("DROP INDEX idx_bench_covering ON lichhen")

    results.append(
        {
            "name": "Covering Index",
            "truoc": time3_truoc,
            "sau": time3_sau,
            "speedup": time3_truoc / time3_sau if time3_sau > 0 else 0,
            "explain_truoc": explain3_truoc,
            "explain_sau": explain3_sau,
        }
    )
    print(
        f"  Truoc: {time3_truoc:.3f}ms | Sau: {time3_sau:.3f}ms | Speedup: {time3_truoc / time3_sau:.2f}x"
    )

    # =====================
    # 4. SELECT * vs Columns
    # =====================
    print("\n[4/7] SELECT * vs Columns...")
    cursor.execute("FLUSH TABLES")

    # Tìm một GioiTinh phổ biến
    cursor.execute("SELECT GioiTinh FROM benhnhan WHERE GioiTinh IS NOT NULL LIMIT 1")
    gt_val = cursor.fetchone()[0]

    query4_truoc = f"SELECT * FROM benhnhan WHERE GioiTinh = '{gt_val}' LIMIT 100"
    time4_truoc = run_query(cursor, query4_truoc)
    explain4_truoc = get_explain_str(cursor, query4_truoc)

    query4_sau = f"SELECT MaBN, TenBN, NgaySinh FROM benhnhan WHERE GioiTinh = '{gt_val}' LIMIT 100"
    time4_sau = run_query(cursor, query4_sau)
    explain4_sau = get_explain_str(cursor, query4_sau)

    results.append(
        {
            "name": "SELECT * vs Columns",
            "truoc": time4_truoc,
            "sau": time4_sau,
            "speedup": time4_truoc / time4_sau if time4_sau > 0 else 0,
            "explain_truoc": explain4_truoc,
            "explain_sau": explain4_sau,
        }
    )
    print(
        f"  Truoc (*): {time4_truoc:.3f}ms | Sau (cols): {time4_sau:.3f}ms | Speedup: {time4_truoc / time4_sau:.2f}x"
    )

    # =====================
    # 5. IN vs EXISTS
    # =====================
    print("\n[5/7] IN vs EXISTS...")
    cursor.execute("FLUSH TABLES")

    # Tìm TrangThai có nhiều bản ghi
    cursor.execute(
        "SELECT TrangThai FROM lichhen GROUP BY TrangThai ORDER BY COUNT(*) DESC LIMIT 1"
    )
    tt_val = cursor.fetchone()[0]

    query5_truoc = f"SELECT MaBN, TenBN FROM benhnhan WHERE MaBN IN (SELECT DISTINCT MaBN FROM lichhen WHERE TrangThai = '{tt_val}') LIMIT 100"
    time5_truoc = run_query(cursor, query5_truoc)
    explain5_truoc = get_explain_str(cursor, query5_truoc)

    query5_sau = f"SELECT MaBN, TenBN FROM benhnhan bn WHERE EXISTS (SELECT 1 FROM lichhen lh WHERE lh.MaBN = bn.MaBN AND lh.TrangThai = '{tt_val}') LIMIT 100"
    time5_sau = run_query(cursor, query5_sau)
    explain5_sau = get_explain_str(cursor, query5_sau)

    results.append(
        {
            "name": "IN vs EXISTS",
            "truoc": time5_truoc,
            "sau": time5_sau,
            "speedup": time5_truoc / time5_sau if time5_sau > 0 else 0,
            "explain_truoc": explain5_truoc,
            "explain_sau": explain5_sau,
        }
    )
    print(
        f"  Truoc (IN): {time5_truoc:.3f}ms | Sau (EXISTS): {time5_sau:.3f}ms | Speedup: {time5_truoc / time5_sau:.2f}x"
    )

    # =====================
    # 6. Function on Index
    # =====================
    print("\n[6/7] Function on Index...")
    cursor.execute("FLUSH TABLES")

    query6_truoc = "SELECT * FROM lichhen WHERE YEAR(ThoiGianDat) = 2025 LIMIT 100"
    time6_truoc = run_query(cursor, query6_truoc)
    explain6_truoc = get_explain_str(cursor, query6_truoc)

    query6_sau = "SELECT * FROM lichhen WHERE ThoiGianDat >= '2025-01-01' AND ThoiGianDat < '2026-01-01' LIMIT 100"
    time6_sau = run_query(cursor, query6_sau)
    explain6_sau = get_explain_str(cursor, query6_sau)

    results.append(
        {
            "name": "Function on Index",
            "truoc": time6_truoc,
            "sau": time6_sau,
            "speedup": time6_truoc / time6_sau if time6_sau > 0 else 0,
            "explain_truoc": explain6_truoc,
            "explain_sau": explain6_sau,
        }
    )
    print(
        f"  Truoc (YEAR): {time6_truoc:.3f}ms | Sau (range): {time6_sau:.3f}ms | Speedup: {time6_truoc / time6_sau:.2f}x"
    )

    # =====================
    # 7. CTE vs Subquery
    # =====================
    print("\n[7/7] CTE vs Subquery...")
    cursor.execute("FLUSH TABLES")

    query7_truoc = "SELECT bs.MaBS, (SELECT COUNT(*) FROM phieukham WHERE MaBS = bs.MaBS) as tong FROM bacsi bs LIMIT 10"
    time7_truoc = run_query(cursor, query7_truoc)
    explain7_truoc = get_explain_str(cursor, query7_truoc)

    query7_sau = "WITH stats AS (SELECT MaBS, COUNT(*) as tong FROM phieukham GROUP BY MaBS) SELECT bs.MaBS, COALESCE(s.tong,0) FROM bacsi bs LEFT JOIN stats s ON bs.MaBS = s.MaBS LIMIT 10"
    time7_sau = run_query(cursor, query7_sau)
    explain7_sau = get_explain_str(cursor, query7_sau)

    results.append(
        {
            "name": "CTE vs Subquery",
            "truoc": time7_truoc,
            "sau": time7_sau,
            "speedup": time7_truoc / time7_sau if time7_sau > 0 else 0,
            "explain_truoc": explain7_truoc,
            "explain_sau": explain7_sau,
        }
    )
    print(
        f"  Truoc (Sub): {time7_truoc:.3f}ms | Sau (CTE): {time7_sau:.3f}ms | Speedup: {time7_truoc / time7_sau:.2f}x"
    )

    cursor.close()
    conn.close()

    # Save results
    output = {
        "timestamp": datetime.now().strftime("%Y-%m-%d %H:%M:%S"),
        "database": "dl_benhvien",
        "results": results,
    }

    with open("benchmark_results.json", "w", encoding="utf-8") as f:
        json.dump(output, f, ensure_ascii=False, indent=2)

    print("\n" + "=" * 60)
    print("TOM TAT KET QUA")
    print("=" * 60)
    for r in results:
        print(
            f"{r['name']}: {r['truoc']:.3f}ms -> {r['sau']:.3f}ms ({r['speedup']:.2f}x)"
        )
    print("=" * 60)
    print("\nDa luu ket qua vao: benchmark_results.json")

    return results


if __name__ == "__main__":
    main()
