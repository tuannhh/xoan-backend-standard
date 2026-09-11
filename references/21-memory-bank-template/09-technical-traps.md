# 09 — Bẫy kỹ thuật (Technical Traps)

> Danh sách các vấn đề khó phát hiện, dễ lặp lại sai lầm nếu không biết trước. Đây là tệp quan trọng bậc nhất để không lặp lại đúng lỗi đã từng tốn thời gian điều tra.

Mỗi mục nên có cấu trúc: **Triệu chứng** (dấu hiệu nhận biết) → **Nguyên nhân gốc rễ** (đã xác minh thật, không suy đoán) → **Cách xử lý/tránh** → **Bài học rút ra** (áp dụng được cho tình huống tương tự sau này).

---

## 1. [Tên bẫy kỹ thuật]

**Triệu chứng:** [Hiện tượng quan sát được]

**Nguyên nhân gốc rễ:** [Giải thích đã xác minh, kèm tham chiếu file:dòng nếu có]

**Cách xử lý/tránh:** [Giải pháp đã áp dụng]

**Bài học:** [Nguyên tắc tổng quát rút ra được, áp dụng cho tình huống tương tự]

---

[Thêm mục mới mỗi khi phát hiện 1 bẫy kỹ thuật mới trong quá trình phát triển/refactor dự án.]

---

## Ví dụ đã điền (tham khảo mức độ chi tiết mong muốn — xoá phần này sau khi đã điền nội dung thật của dự án)

## X. UNIQUE constraint trên cột `NOT NULL DEFAULT ''` — chuỗi rỗng bị coi là trùng nhau

**Triệu chứng:** Import Excel danh sách khách không có số điện thoại (2+ dòng cùng sự kiện, cột số điện thoại để trống) → lỗi 500 `Duplicate entry '3-' for key 'attendees.uq_event_phone'`.

**Nguyên nhân gốc rễ:** Cột `attendees.phone` là `VARCHAR(50) DEFAULT NULL` (đúng), nhưng code import Excel tự viết SQL riêng (không qua module dùng chung `attendee-helper.js`) và insert thẳng `phone = ''` thay vì `NULL` khi cột trống trong Excel. MySQL UNIQUE constraint coi `''` là 1 giá trị thật — 2 dòng cùng `event_id` + `phone=''` bị tính là trùng, khác hẳn `NULL` (MySQL bỏ qua NULL khi enforce UNIQUE).

**Cách xử lý/tránh:** Đổi `phone` (biến rỗng) thành `phone || null` trước khi đưa vào tham số INSERT ở route import Excel.

**Bài học:** Bất kỳ cột nào có UNIQUE constraint và cho phép "chưa nhập" phải dùng NULL để biểu diễn "chưa có giá trị" — không dùng chuỗi rỗng. Khi thêm 1 đường ghi dữ liệu mới vào bảng đã có UNIQUE constraint, phải kiểm tra đã chuẩn hoá rỗng→NULL giống các đường ghi khác chưa, không tự viết SQL riêng mà bỏ qua quy tắc này. Xem thêm `../05-database-rules.md` mục 2.

