# 02 — Công nghệ & Kiến trúc

## Kiến trúc tổng thể

[Vẽ sơ đồ dạng khối đơn giản: Frontend (nếu có) → API → Tầng nghiệp vụ → Cơ sở dữ liệu, ghi rõ công nghệ ở mỗi tầng.]

## Backend

| Công nghệ | Phiên bản | Vai trò | Ghi chú |
|---|---|---|---|
| | | | |

### Modules nội bộ dùng chung

| Module | Vai trò |
|---|---|
| | |

### Vì sao chọn công nghệ này?

[Ghi lại lý do thật (không suy đoán) — quyết định của người phụ trách dự án, hoặc ràng buộc kỹ thuật cụ thể.]

## Frontend (nếu dự án có)

| Công nghệ | Vai trò |
|---|---|
| | |

## Lưu trữ

| Thành phần | Công nghệ | Ghi chú |
|---|---|---|
| Cơ sở dữ liệu | | |
| Tệp tĩnh/upload | | Xem [`../04-project-structure.md`](../04-project-structure.md) mục 4 để phân biệt public/private/temp |
| Lược đồ dữ liệu | | |

## Hạ tầng

| Thành phần | Công nghệ | Ghi chú |
|---|---|---|
| | | |

---

## Ví dụ đã điền (tham khảo mức độ chi tiết mong muốn — xoá phần này sau khi đã điền nội dung thật của dự án)

### Kiến trúc tổng thể

```
Frontend (SPA vanilla JS) → REST API (Express) → Tầng nghiệp vụ (routes/*.js gọi common/*.js) → MySQL 8.0 (connection pool)
```

### Backend

| Công nghệ | Phiên bản | Vai trò | Ghi chú |
|---|---|---|---|
| Node.js | 20 LTS | Runtime | CommonJS |
| Express | 5.2.1 | Web framework | API-only, không server-side render |
| mysql2 | 3.22.5 | Driver cơ sở dữ liệu | Promise API, prepared statement |
| bcryptjs | 3.0.3 | Hash mật khẩu | 10 rounds |

### Vì sao chọn công nghệ này?

Chủ dự án không có nền tảng kỹ thuật, cần bên kỹ thuật tự quyết theo đề xuất mặc định ở `../10-phase-init-new-project.md` mục 1 (Node/Express/MySQL) — không có ràng buộc đặc biệt nào khác từ phía chủ dự án. Xác nhận qua trao đổi trực tiếp ngày khởi tạo dự án, không suy đoán.

