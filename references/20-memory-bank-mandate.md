# 20 — Quy định bắt buộc về tài liệu tri thức dự án (Memory-Bank Mandate)

> Bắt buộc áp dụng cho MỌI dự án tuân theo bộ quy tắc này, ở mọi giai đoạn vòng đời — khởi tạo, refactor, và duy trì. Đây không phải khuyến nghị tuỳ chọn.

---

## 1. Vì sao bắt buộc

Tri thức về một dự án không chỉ nằm ở mã nguồn — nó còn bao gồm lý do vì sao một quyết định kiến trúc được chọn, những bài học rút ra từ sự cố đã từng xảy ra, và bối cảnh nghiệp vụ đằng sau mỗi tính năng. Nếu tri thức này chỉ tồn tại trong đầu người từng làm việc trực tiếp (hoặc trong lịch sử hội thoại không được lưu lại có cấu trúc), nó sẽ mất đi khi người đó rời dự án hoặc khi một phiên làm việc mới bắt đầu mà không có ngữ cảnh trước đó.

Mục tiêu cuối cùng: bất kỳ ai (con người hoặc AI) đọc hết bộ tài liệu tri thức dự án đều hiểu tường tận dự án và có thể tiếp tục làm việc mà không cần hỏi lại những điều đã có câu trả lời.

## 2. Cấu trúc thư mục chuẩn

Thư mục `memory-bank/` đặt ở thư mục gốc của dự án, gồm các tệp chuyên đề sau (điều chỉnh số lượng/tên gọi theo đặc thù từng dự án, nhưng phải bao phủ đủ các chủ đề dưới đây):

- **Tệp điều hướng (README hoặc tương đương):** giải thích mục đích của thư mục này, cách sử dụng (khi nào đọc toàn bộ, khi nào tra cứu nhanh 1 chủ đề), và mục lục các tệp còn lại.
- **Tổng quan dự án:** dự án là gì, phục vụ ai, đối tượng sử dụng chính, các môi trường đang vận hành (phát triển, kiểm thử, sản xuất) và đặc điểm riêng của từng môi trường.
- **Công nghệ & kiến trúc:** ngôn ngữ/framework/hệ quản trị cơ sở dữ liệu đang dùng và lý do chọn, sơ đồ kiến trúc tổng thể ở mức cao.
- **Lược đồ cơ sở dữ liệu:** toàn bộ bảng, cột, quan hệ, ràng buộc quan trọng, và lịch sử các lần thay đổi lược đồ đáng chú ý.
- **Tham chiếu API:** danh sách endpoint, phương thức, yêu cầu phân quyền, ý nghĩa tham số đầu vào/đầu ra.
- **Luồng nghiệp vụ cốt lõi:** các quy trình nghiệp vụ quan trọng nhất của dự án, diễn giải bằng ngôn ngữ dễ hiểu, không chỉ liệt kê tên hàm.
- **Kiến trúc giao diện (nếu dự án có phần frontend):** cách tổ chức giao diện, các thành phần/khuôn mẫu lặp lại.
- **Triển khai & hạ tầng:** cách chạy dự án ở môi trường phát triển cục bộ, cách triển khai lên môi trường thật, các biến môi trường/cấu hình cần thiết.
- **Mô hình bảo mật & phân quyền:** cơ chế xác thực đang dùng, các vai trò/quyền hạn, các quyết định bảo mật có chủ đích cần lưu ý (đặc biệt các trường hợp trông có vẻ là lỗ hổng nhưng thực ra là thiết kế cố ý, kèm lý do).
- **Bẫy kỹ thuật đã biết:** danh sách các vấn đề khó phát hiện, dễ lặp lại sai lầm nếu không biết trước — đây là tệp quan trọng bậc nhất để tránh lặp lại đúng những lỗi đã từng xảy ra.
- **Lịch sử phát triển (changelog):** ghi lại theo trình tự thời gian mỗi lần hoàn thành 1 tính năng/thay đổi kiến trúc đáng chú ý, kèm lý do (why) — không chỉ ghi "cái gì đã đổi" mà còn "vì sao đổi".
- **Nguyên tắc & quy tắc bắt buộc khi code:** nếu dự án có những quy tắc riêng bổ sung ngoài bộ quy tắc tổng quát này (do đặc thù nghiệp vụ hoặc yêu cầu riêng của người phụ trách dự án), ghi lại ở đây.

## 3. Nguyên tắc "map 1:1" giữa tài liệu và mã nguồn thật

Tri thức trong `memory-bank/` phải phản ánh đúng những gì đang thực sự chạy trong mã nguồn — không được để tài liệu lệch pha với thực tế. Đây là nguyên tắc quan trọng nhất của toàn bộ file này:

- Sau khi hoàn thành bất kỳ thay đổi mã nguồn nào (không chỉ khi "xong hẳn 1 tính năng lớn"), phải tự hỏi rõ ràng: thay đổi này có ảnh hưởng tới nội dung nào trong `memory-bank/` không? Nếu có, cập nhật ngay trong cùng lượt làm việc — không để dồn lại "làm sau", vì càng để lâu càng dễ quên chi tiết và càng nhiều thay đổi bị bỏ sót.
- Việc cập nhật tài liệu là **một phần của định nghĩa "hoàn thành"** cho 1 nhiệm vụ code, không phải việc phụ làm thêm sau khi đã "xong". Một thay đổi mã nguồn chưa cập nhật tài liệu liên quan không được coi là hoàn thành.
- Nếu thay đổi liên quan tới cấu trúc cơ sở dữ liệu, phải cập nhật cả tài liệu lược đồ VÀ tệp migration chính thức tương ứng (không chỉ mô tả bằng lời trong tài liệu) — nếu không, mã nguồn dựa trên cấu trúc mới sẽ gặp lỗi khi triển khai lên một môi trường chưa có cấu trúc đó.
- Bất kỳ thay đổi nào, dù nhỏ, đủ đáng chú ý để ảnh hưởng tới cách hiểu dự án trong tương lai đều nên được thêm 1 dòng vào tệp lịch sử phát triển (changelog), kèm lý do vì sao.

## 4. Bản đồ nhanh: loại thay đổi → tệp cần cập nhật

Khi hoàn thành 1 thay đổi mã nguồn, đối chiếu nhanh loại thay đổi với tệp tương ứng cần rà soát:

- Thêm/sửa cột, bảng, ràng buộc trong cơ sở dữ liệu → tệp lược đồ cơ sở dữ liệu + tệp migration chính thức.
- Thêm/sửa endpoint API → tệp tham chiếu API.
- Thay đổi luồng nghiệp vụ (quy trình xử lý, quy tắc điều kiện) → tệp luồng nghiệp vụ cốt lõi.
- Thay đổi cấu trúc/thành phần giao diện → tệp kiến trúc giao diện (nếu có).
- Thay đổi cách triển khai/biến môi trường/hạ tầng vận hành → tệp triển khai & hạ tầng.
- Thay đổi cơ chế phân quyền/bảo mật → tệp mô hình bảo mật & phân quyền.
- Phát hiện 1 bẫy kỹ thuật mới (vấn đề khó phát hiện, đã tốn thời gian điều tra mới hiểu rõ nguyên nhân) → tệp bẫy kỹ thuật đã biết.
- Bất kỳ thay đổi nào ở trên, dù nhỏ → thêm 1 dòng vào tệp lịch sử phát triển kèm lý do (why).

Nếu 1 nhiệm vụ chỉ sửa lỗi nhỏ không đổi kiến trúc/API/lược đồ/nghiệp vụ, có thể không cần sửa tài liệu — nhưng vẫn phải tự đặt câu hỏi rõ ràng "thay đổi này có ảnh hưởng tài liệu nào không" trước khi kết luận là không cần, không mặc định bỏ qua bước tự hỏi này.

## 5. Không tự bịa nội dung tài liệu

Khi khởi tạo hoặc cập nhật nội dung `memory-bank/` cho một dự án (đặc biệt khi tiếp nhận 1 dự án cũ chưa có tài liệu, xem [`11-phase-refactor-legacy.md`](11-phase-refactor-legacy.md) mục 6), nội dung phải dựa trên việc đọc hiểu mã nguồn thật hoặc yêu cầu trực tiếp — không suy đoán hoặc bịa ra chi tiết chưa xác minh, đúng theo nguyên tắc chung ở [`01-core-principles.md`](01-core-principles.md) mục 3.

## 6. Phân biệt với tài liệu kiến trúc thông thường (docs)

Thư mục tài liệu kiến trúc thông thường (`docs/`, nếu có ở dự án, xem [`04-project-structure.md`](04-project-structure.md)) thường phục vụ mục đích trình bày tổng quan cho người đọc bên ngoài (ví dụ tài liệu giới thiệu dự án, sơ đồ kiến trúc trực quan) — có thể ít được cập nhật ở mức chi tiết. Thư mục `memory-bank/` có vai trò khác hẳn: đây là tri thức làm việc bắt buộc phải map 1:1 với mã nguồn, phục vụ chính người/AI đang trực tiếp phát triển tiếp dự án, cập nhật thường xuyên theo từng thay đổi mã nguồn. Hai thư mục này có thể cùng tồn tại song song, không thay thế cho nhau.

## 7. Ngôn ngữ và định dạng viết tài liệu

Viết theo ngôn ngữ mà người phụ trách dự án hiểu được và cảm thấy dễ đọc nhất — nếu người phụ trách không có nền tảng kỹ thuật, giải thích bằng ngôn ngữ đơn giản, tránh thuật ngữ khó hiểu không cần thiết. Giữ nhất quán 1 ngôn ngữ xuyên suốt toàn bộ `memory-bank/` của cùng 1 dự án, không trộn lẫn nhiều ngôn ngữ gây khó tra cứu.

---

## Checklist nhanh — khi khởi tạo hoặc cập nhật memory-bank

- [ ] Dự án đã có đủ cấu trúc thư mục `memory-bank/` theo các chủ đề chuẩn ở mục 2 chưa (điều chỉnh theo đặc thù dự án nếu cần, không cứng nhắc phải giống hệt)?
- [ ] Thay đổi mã nguồn vừa hoàn thành đã được rà soát xem ảnh hưởng tệp nào trong memory-bank chưa, và đã cập nhật ngay trong cùng lượt làm việc chưa?
- [ ] Nếu thay đổi liên quan cơ sở dữ liệu, tệp migration chính thức đã được cập nhật song song với tài liệu lược đồ chưa?
- [ ] Tệp lịch sử phát triển đã có dòng ghi lại thay đổi này kèm lý do (why) chưa?
- [ ] Nội dung tài liệu có dựa trên xác minh thật (đọc mã nguồn/yêu cầu trực tiếp), không phải suy đoán không?

---

*Xem thêm: [`21-memory-bank-template/`](21-memory-bank-template/) — bộ khung tệp mẫu rỗng để sao chép khi khởi tạo memory-bank cho dự án mới.*
