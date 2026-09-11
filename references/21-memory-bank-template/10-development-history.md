# 10 — Lịch sử phát triển (Development History / Changelog)

> Ghi lại theo trình tự thời gian mỗi lần hoàn thành 1 tính năng/thay đổi kiến trúc đáng chú ý. Không chỉ ghi "cái gì đã đổi" mà bắt buộc kèm "vì sao đổi" (why).

---

### [Số thứ tự]. [Tên thay đổi] ([ngày tháng])

**Vấn đề/yêu cầu:** [Bối cảnh dẫn tới thay đổi này]

**Đã làm:** [Mô tả cụ thể thay đổi — tệp nào, thành phần nào bị ảnh hưởng]

**Tài liệu đã cập nhật kèm theo:** [Liệt kê các tệp memory-bank khác đã cập nhật cùng lượt — theo đúng nguyên tắc map 1:1 ở `../20-memory-bank-mandate.md`]

**Why:** [Lý do thực hiện — yêu cầu trực tiếp / bug đã xác minh / quyết định nghiệp vụ qua trao đổi]

---

## Quy tắc cập nhật tệp này

1. Sau khi hoàn thành 1 tính năng/thay đổi kiến trúc → thêm mục mới vào phần trên, ghi rõ *cái gì thay đổi* và *why*.
2. Thay đổi lược đồ cơ sở dữ liệu → đồng bộ với tệp migration chính thức trong mã nguồn, không chỉ ghi ở đây.
3. Quyết định nghiệp vụ quan trọng qua trao đổi (dù chưa code) → vẫn ghi vào đây hoặc mục "việc còn treo" liên quan, để người/AI sau không hỏi lại câu đã có câu trả lời.
4. Giữ tệp này ngắn gọn, có cấu trúc rõ ràng, cùng ngôn ngữ với phần còn lại của memory-bank.
