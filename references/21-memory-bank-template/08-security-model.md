# 08 — Mô hình bảo mật & Phân quyền

> Xem nguyên tắc tổng quát ở [`../02-security-baseline.md`](../02-security-baseline.md). Tệp này ghi lại cách áp dụng CỤ THỂ cho dự án này.

## Xác thực (Authentication)

[Cơ chế đang dùng — phiên làm việc phía server hay token, có tích hợp SSO/OAuth không, chi tiết luồng nếu có.]

## Phân quyền (Authorization)

### Danh sách vai trò hệ thống

| Vai trò | Phạm vi dữ liệu | Quyền chính |
|---|---|---|
| | | |

### Cách ly dữ liệu (nếu có nhiều tổ chức/đơn vị dùng chung hệ thống)

[Mô tả cơ chế lọc dữ liệu theo đơn vị/tổ chức của người dùng đang đăng nhập.]

## Quyết định bảo mật có chủ đích cần lưu ý

> Ghi lại các trường hợp trông có vẻ là lỗ hổng nhưng thực ra là thiết kế cố ý — kèm lý do rõ ràng, để người sau không hiểu lầm rồi tự ý "sửa" thành sai.

- [Ví dụ: endpoint X không yêu cầu xác thực vì mục đích công khai — lý do, rủi ro đã đánh giá.]

## Endpoint công khai (không yêu cầu xác thực)

| Endpoint | Lý do công khai | Rủi ro đã cân nhắc |
|---|---|---|
| | | |

## Thông tin nhạy cảm cần lưu ý khi làm việc

[Ghi rõ nếu có bất kỳ thông tin nhạy cảm nào đang tồn tại ở trạng thái chưa lý tưởng (ví dụ đã lỡ commit vào lịch sử git, cần thu hồi/đổi mới) — để không ai vô tình xem đây là "bình thường".]
