# 06 — Thiết kế API (API Design)

> Áp dụng khi thiết kế endpoint mới hoặc rà soát endpoint đã có. Nguyên tắc phân quyền/xác thực chi tiết đã nêu ở [`02-security-baseline.md`](02-security-baseline.md) — file này tập trung vào hình dạng và quy ước của bản thân API.

---

## 1. Quy ước đặt tên và cấu trúc đường dẫn

Đường dẫn API nên đặt tên theo danh từ số nhiều, phản ánh loại tài nguyên đang thao tác — không đặt tên theo động từ hành động (hành động đã được thể hiện qua phương thức HTTP tương ứng: lấy dữ liệu, tạo mới, cập nhật toàn phần, cập nhật một phần, hoặc xoá). Tài nguyên con thuộc về 1 tài nguyên cha nên lồng đường dẫn phản ánh đúng quan hệ đó, nhưng không lồng quá sâu nhiều cấp gây khó đọc — nếu quan hệ lồng nhau quá phức tạp, cân nhắc tách thành đường dẫn phẳng hơn kèm tham số lọc.

Toàn bộ đường dẫn API nên có 1 tiền tố chung nhất quán để dễ phân biệt với các route khác của ứng dụng (ví dụ phục vụ giao diện, tệp tĩnh) — và nên có phiên bản (versioning) nếu dự đoán trước API sẽ phải thay đổi không tương thích ngược trong tương lai, để không phá vỡ các bên đang tích hợp với phiên bản cũ.

## 2. Hình dạng phản hồi nhất quán

Toàn bộ API trong cùng 1 dự án nên trả về theo 1 cấu trúc phản hồi nhất quán — cả khi thành công lẫn khi có lỗi. Phía gọi API không nên phải đoán xem trường hợp này lỗi nằm ở khoá nào của đối tượng phản hồi, trường hợp khác lại nằm ở khoá khác. Sự nhất quán này giúp phía gọi API viết logic xử lý chung được cho mọi endpoint, thay vì phải viết riêng cho từng endpoint.

Khi trả về danh sách có phân trang, cấu trúc phản hồi nên bao gồm rõ ràng: dữ liệu của trang hiện tại, thông tin về tổng số bản ghi (hoặc còn dữ liệu tiếp theo hay không), và các tham số phân trang đã áp dụng — để phía gọi không phải tự suy đoán còn dữ liệu để tải thêm hay không.

Minh hoạ 1 khung cấu trúc phản hồi nhất quán có thể tham khảo (điều chỉnh tên khoá theo quy ước đã có sẵn của dự án nếu dự án đã có cấu trúc khác — điều quan trọng nhất là NHẤT QUÁN xuyên suốt, không phải đúng chính xác tên khoá dưới đây):
```
// Phản hồi thành công, có phân trang
{
  "data": [ ... danh sách bản ghi trang hiện tại ... ],
  "meta": { "tong_so_ban_ghi": 245, "trang_hien_tai": 2, "so_ban_ghi_moi_trang": 20 }
}

// Phản hồi thành công, đơn lẻ 1 bản ghi
{ "data": { ... nội dung bản ghi ... } }

// Phản hồi lỗi — luôn cùng 1 hình dạng dù lỗi nghiệp vụ hay lỗi hệ thống
{ "error": { "message": "Cần nhập họ và tên" } }
```
Phía gọi API chỉ cần viết 1 đoạn logic xử lý chung: kiểm tra có khoá `data` hay khoá `error` để biết thành công hay thất bại, không phải viết logic riêng đoán cấu trúc cho từng endpoint khác nhau.

## 3. Mã trạng thái HTTP phản ánh đúng bản chất kết quả

Mã trạng thái không nên mặc định là thành công (200) cho mọi trường hợp rồi để bên trong nội dung phản hồi ghi chú "có lỗi" — điều này phá vỡ cách phía gọi API (và các công cụ trung gian như bộ nhớ đệm, công cụ giám sát) hiểu đúng bản chất phản hồi.

Phân biệt rõ các nhóm mã trạng thái theo đúng ý nghĩa chuẩn: nhóm mã báo lỗi phía người gọi (dữ liệu gửi lên không hợp lệ, chưa xác thực, không đủ quyền, tài nguyên không tồn tại, xung đột dữ liệu như trùng lặp) khác hẳn với nhóm mã báo lỗi phía máy chủ (lỗi hệ thống không lường trước). Khi trả lỗi phía người gọi, thông điệp đi kèm nên đủ rõ ràng để người dùng cuối hoặc lập trình viên tích hợp hiểu được cần sửa gì. Khi trả lỗi phía máy chủ, không nên lộ chi tiết kỹ thuật nội bộ ra ngoài (đã nêu ở phần xử lý lỗi tổng, [`03-error-handling-resilience.md`](03-error-handling-resilience.md) mục 6).

## 4. Validate đầu vào ở tầng server — không tin tưởng riêng validate phía client

Mọi endpoint nhận dữ liệu ghi (tạo mới, cập nhật) phải tự validate lại toàn bộ dữ liệu đầu vào ở phía server, bất kể phía giao diện người dùng đã validate trước đó hay chưa — vì phía gọi API không nhất thiết phải là giao diện chính thức của ứng dụng (có thể gọi trực tiếp qua công cụ khác, bỏ qua hoàn toàn lớp validate phía giao diện).

Các khía cạnh cần validate: trường bắt buộc phải có giá trị, giá trị phải nằm trong tập hợp lệ đã định nghĩa trước (không phải giá trị tuỳ ý), độ dài dữ liệu văn bản không vượt giới hạn cho phép, định dạng dữ liệu (địa chỉ email, số điện thoại, ngày tháng) đúng cấu trúc mong đợi.

## 5. Phân trang, lọc, và sắp xếp cho danh sách

Bất kỳ endpoint trả về danh sách nào có khả năng phát triển lớn theo thời gian đều phải hỗ trợ phân trang ngay từ đầu — không trả về toàn bộ danh sách không giới hạn, vì khi dữ liệu tăng lên theo thời gian vận hành thật, việc trả về không giới hạn sẽ dần trở thành gánh nặng hiệu năng cả phía máy chủ lẫn phía mạng truyền tải, và rất khó bổ sung phân trang sau này mà không phá vỡ hợp đồng đã có với các bên đang tích hợp. Xem [`08-performance-scaling.md`](08-performance-scaling.md) mục 3 để chọn đúng chiến lược phân trang (offset-based hay cursor-based) phù hợp đặc điểm dữ liệu.

Tham số lọc và sắp xếp nên được giới hạn trong 1 danh sách trường được phép rõ ràng (không cho phép người gọi tuỳ ý chỉ định bất kỳ tên cột nào) — vừa tránh rò rỉ cấu trúc dữ liệu nội bộ không cần thiết, vừa tránh nguy cơ chèn lệnh nếu tham số đó vô tình được dùng trực tiếp trong câu truy vấn mà không qua tham số hoá.

## 6. Idempotency — hiểu đúng ngữ nghĩa của từng phương thức HTTP

Phương thức dùng để cập nhật toàn phần một tài nguyên nên có tính chất: gọi lại nhiều lần với cùng dữ liệu đầu vào cho ra cùng 1 kết quả cuối cùng, không tạo thêm bản ghi mới mỗi lần gọi. Phương thức dùng để tạo mới thì ngược lại, về bản chất mỗi lần gọi thường tạo ra 1 bản ghi mới — nếu nghiệp vụ yêu cầu "gọi lại không được tạo trùng" (ví dụ do phía gọi có thể gửi lại request do mất kết nối tưởng thất bại), cần có cơ chế riêng để nhận diện và ngăn tạo trùng (ví dụ một khoá duy nhất do phía gọi cung cấp để nhận diện đây là cùng 1 yêu cầu logic, hoặc dựa vào ràng buộc dữ liệu duy nhất đã có).

## 7. Endpoint công khai không yêu cầu xác thực

Nếu dự án có endpoint cố ý không yêu cầu xác thực (phục vụ mục đích công khai thật sự — ví dụ lấy hình ảnh cần nhúng vào email gửi ra ngoài, hoặc endpoint phục vụ tiện ích nhúng vào trang khác), mỗi endpoint dạng này cần được cân nhắc rõ ràng và ghi chú lại lý do công khai cùng những rủi ro đã được đánh giá và chấp nhận — không để lẫn lộn giữa "cố ý công khai có lý do" và "quên thêm kiểm tra xác thực". Với endpoint công khai chứa định danh nhạy cảm trong đường dẫn (ví dụ mã định danh để tải một tài nguyên cụ thể), định danh đó phải là chuỗi ngẫu nhiên đủ dài không đoán được — không dùng số thứ tự tuần tự dễ đoán.

## 8. Tài liệu hoá API

Danh sách endpoint, phương thức, và ý nghĩa từng tham số nên được ghi lại ở một nơi tập trung, dễ tra cứu — đây chính là một phần của tài liệu tri thức dự án bắt buộc (xem [`20-memory-bank-mandate.md`](20-memory-bank-mandate.md)). Tài liệu API phải được cập nhật ngay khi endpoint thay đổi, không để tài liệu lệch pha với API thật đang chạy.

---

## Checklist nhanh — khi thêm hoặc sửa 1 endpoint

- [ ] Đường dẫn và phương thức HTTP có đúng quy ước danh từ/động từ nhất quán với các endpoint khác trong dự án không?
- [ ] Hình dạng phản hồi (thành công lẫn lỗi) có nhất quán với các endpoint khác không?
- [ ] Mã trạng thái HTTP có phản ánh đúng bản chất kết quả, không mặc định trả thành công cho mọi trường hợp không?
- [ ] Đầu vào có được validate đầy đủ ở phía server, không chỉ dựa vào validate phía client không?
- [ ] Danh sách trả về có phân trang nếu có khả năng phát triển lớn theo thời gian không?
- [ ] Nếu endpoint cố ý công khai không yêu cầu xác thực, lý do và rủi ro đã được đánh giá rõ chưa?
- [ ] Tài liệu API đã được cập nhật khớp với thay đổi vừa thực hiện chưa?

---

*Xem tiếp: [`07-testing-strategy.md`](07-testing-strategy.md) — chiến lược kiểm thử.*
