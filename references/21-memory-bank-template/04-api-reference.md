# 04 — Tham chiếu API

> Xem quy tắc thiết kế API ở [`../06-api-design.md`](../06-api-design.md).

## Nhóm endpoint: [tên nhóm, ví dụ "Xác thực"]

### `[PHƯƠNG THỨC] /đường-dẫn`

- **Yêu cầu quyền:** [vai trò nào được gọi]
- **Mục đích:** [mô tả ngắn]
- **Body/tham số:** [liệt kê trường, ý nghĩa, bắt buộc hay không]
- **Phản hồi:** [cấu trúc trả về khi thành công]
- **Lỗi có thể gặp:** [mã trạng thái + điều kiện gây lỗi]
- **Ghi chú đặc biệt:** [nếu có hành vi không hiển nhiên, giải thích rõ]

---

[Lặp lại cấu trúc trên cho từng nhóm endpoint. Nhóm theo tài nguyên hoặc theo tầng mount (ví dụ /api/auth, /api/business) — nhất quán với cách tổ chức route thật trong mã nguồn.]

---

## Ví dụ đã điền (tham khảo mức độ chi tiết mong muốn — xoá phần này sau khi đã điền nội dung thật của dự án)

## Nhóm endpoint: Xác thực

### `POST /api/auth/login`

- **Yêu cầu quyền:** Không cần đăng nhập (đây chính là endpoint đăng nhập)
- **Mục đích:** Đăng nhập bằng email/mật khẩu, cho mọi vai trò
- **Body/tham số:** `{ email, password }` — cả 2 bắt buộc
- **Phản hồi:** `{ id, name, email, role, unit_id }` + session cookie
- **Lỗi có thể gặp:** 401 nếu sai email/mật khẩu; 429 nếu vượt rate limit (5 lần thất bại/15 phút/IP)
- **Ghi chú đặc biệt:** Có `session.regenerate()` chống session fixation trước khi gán `session.user` — xem `../02-security-baseline.md` mục 1.

