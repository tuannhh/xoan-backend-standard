# 03 — Lược đồ cơ sở dữ liệu

> Xem quy tắc bắt buộc khi thiết kế/thay đổi lược đồ ở [`../05-database-rules.md`](../05-database-rules.md).

## Danh sách bảng

Với mỗi bảng, ghi rõ:
- Tên bảng, mục đích.
- Danh sách cột: tên, kiểu dữ liệu, ràng buộc (bắt buộc/cho phép rỗng, giá trị mặc định), ý nghĩa.
- Khoá chính, khoá ngoại, ràng buộc duy nhất (unique) — với ràng buộc duy nhất trên cột cho phép "chưa nhập", ghi rõ đã dùng NULL thay vì chuỗi rỗng (xem [`../05-database-rules.md`](../05-database-rules.md) mục 2).
- Chỉ mục (index) quan trọng phục vụ hiệu năng truy vấn.

### Bảng: [tên bảng]

| Cột | Kiểu | Ràng buộc | Ý nghĩa |
|---|---|---|---|
| | | | |

## Quan hệ giữa các bảng

[Mô tả hoặc vẽ sơ đồ quan hệ — bảng nào tham chiếu bảng nào, quan hệ 1-nhiều/nhiều-nhiều.]

## Lịch sử thay đổi lược đồ đáng chú ý

[Ghi lại các lần thay đổi cấu trúc quan trọng, kèm lý do — đồng bộ với tệp migration chính thức trong mã nguồn, và với `10-development-history.md`.]
