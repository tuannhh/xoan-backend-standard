# 06 — Kiến trúc giao diện (Frontend)

> Chỉ áp dụng nếu dự án có phần giao diện đi kèm. Nếu backend thuần (không có frontend), ghi rõ "Không áp dụng" và bỏ qua các mục còn lại.

## Cách tổ chức

[Mô tả cách chia trang/route/thành phần giao diện, công nghệ dùng.]

## Các thành phần/khuôn mẫu lặp lại (pattern)

[Ví dụ: cách tạo phần tử DOM động, cách gọi API từ giao diện, cách xử lý escape dữ liệu trước khi hiển thị — tham chiếu [`../02-security-baseline.md`](../02-security-baseline.md) mục 3 phần chống XSS.]

## Danh sách trang/tab chính

| Trang/Tab | Mục đích | Vai trò được xem |
|---|---|---|
| | | |

---

## Ví dụ đã điền (tham khảo mức độ chi tiết mong muốn — xoá phần này sau khi đã điền nội dung thật của dự án)

### Cách tổ chức

SPA vanilla JavaScript, không build step. `app.js` (route qua hash `#`, mỗi tab 1 hàm độc lập như `tabAttendees()`, `tabScan()`) load sau `common.js` (chứa hàm tiện ích dùng chung: `api()` gọi fetch, `esc()` escape XSS — xem `../02-security-baseline.md` mục 3, `el()` tạo phần tử qua `<template>` để tránh bẫy innerHTML phá cấu trúc bảng).

### Các thành phần/khuôn mẫu lặp lại (pattern)

- Gọi API: luôn qua hàm `api(method, path, body)` dùng chung, tự thêm header, tự parse JSON, tự xử lý lỗi 401 (redirect về trang đăng nhập).
- Escape dữ liệu: mọi giá trị user/DB nhúng vào HTML template string PHẢI qua `esc()` trước — xem `../02-security-baseline.md` mục 3.
- Tạo `<tr>` động: dùng `el(html)` (qua `<template>` element), không gán trực tiếp `innerHTML` vào biến rồi `appendChild` — trình duyệt tự "sửa" cấu trúc bảng nếu làm sai cách này.

### Danh sách trang/tab chính

| Trang/Tab | Mục đích | Vai trò được xem |
|---|---|---|
| Đăng nhập | SSO hoặc mật khẩu | Mọi vai trò |
| Sự kiện | Danh sách/tạo/sửa sự kiện | super_admin, admin |
| Quét QR | Check-in tại cổng/booth | checkin, reception |

