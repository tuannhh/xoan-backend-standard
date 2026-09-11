# 🧠 Memory Bank — [Tên dự án]

Thư mục này chứa **toàn bộ tri thức về dự án**, được tổ chức thành các tệp chuyên đề. Mục tiêu: bất kỳ ai (con người hoặc AI) đọc hết các tệp trong thư mục này đều hiểu tường tận dự án và có thể làm việc tiếp mà không cần hỏi lại.

## Cách sử dụng

- **Trước khi code bất kỳ thay đổi nào (thêm mới hoặc sửa):** đọc `11-coding-rules.md` trước — đây là nguyên tắc bắt buộc, không phải tham khảo.
- **Lần đầu tiếp cận dự án:** đọc theo thứ tự số, từ `01` đến `11`.
- **Cần tra cứu nhanh:** nhảy thẳng vào tệp tương ứng với chủ đề.
- **Sau khi thay đổi code/kiến trúc:** cập nhật tệp tương ứng + `10-development-history.md` — xem quy tắc bắt buộc ở `../20-memory-bank-mandate.md` của bộ BackEnd.SKILL.

## Danh sách tệp

| Tệp | Chủ đề | Khi nào đọc |
|---|---|---|
| [01-project-overview.md](01-project-overview.md) | Tổng quan, mục tiêu, đối tượng sử dụng | Luôn đọc đầu tiên |
| [02-technology-stack.md](02-technology-stack.md) | Công nghệ & lý do chọn | Hiểu kiến trúc kỹ thuật |
| [03-database-schema.md](03-database-schema.md) | Toàn bộ lược đồ dữ liệu, migration, seed | Làm việc với cơ sở dữ liệu |
| [04-api-reference.md](04-api-reference.md) | Toàn bộ endpoint, request/response, phân quyền | Làm việc với backend |
| [05-business-logic.md](05-business-logic.md) | Luồng nghiệp vụ cốt lõi | Hiểu logic quan trọng nhất |
| [06-frontend-architecture.md](06-frontend-architecture.md) | Giao diện, routing, thành phần UI (nếu dự án có frontend) | Làm việc với giao diện |
| [07-deployment-infrastructure.md](07-deployment-infrastructure.md) | Triển khai, môi trường, biến cấu hình | Triển khai & vận hành |
| [08-security-model.md](08-security-model.md) | Xác thực, phân quyền, cách ly dữ liệu | Đảm bảo an toàn |
| [09-technical-traps.md](09-technical-traps.md) | Bẫy kỹ thuật, workaround, lỗi đã gặp | Tránh lặp sai lầm |
| [10-development-history.md](10-development-history.md) | Lịch sử phát triển, quyết định nghiệp vụ | Hiểu bối cảnh lịch sử |
| [11-coding-rules.md](11-coding-rules.md) | Nguyên tắc & quy tắc bắt buộc khi code | **Trước khi code bất kỳ thay đổi nào** |

## Ghi chú

- Viết theo ngôn ngữ mà người phụ trách dự án hiểu rõ nhất, giữ nhất quán 1 ngôn ngữ xuyên suốt.
- Sau khi code tính năng mới hoặc thay đổi quan trọng, **bắt buộc** cập nhật tệp tương ứng.
- `11-coding-rules.md` áp dụng cho **mọi** nhiệm vụ code, không chỉ khi được nhắc lại.
- Tất cả nội dung phải dựa trên đọc hiểu mã nguồn thật hoặc yêu cầu trực tiếp — không suy đoán/bịa nội dung.
