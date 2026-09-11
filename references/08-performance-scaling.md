# 08 — Hiệu năng & Khả năng mở rộng (Performance & Scaling)

> Đào sâu và mở rộng phần hiệu năng ở [`01-core-principles.md`](01-core-principles.md) mục 1 và [`05-database-rules.md`](05-database-rules.md) mục 6 (N+1, giới hạn tài nguyên). Áp dụng khi thiết kế tính năng mới có khả năng chịu tải lớn, hoặc khi tối ưu 1 phần hệ thống đã xác định là điểm nghẽn (bottleneck) qua đo lường thật.

---

## 1. Chỉ tối ưu khi có bằng chứng, không tối ưu theo cảm tính

Trước khi bỏ công sức tối ưu 1 phần hệ thống, phải có bằng chứng đo lường thật cho thấy đây thực sự là điểm nghẽn (thời gian phản hồi chậm quan sát được, tài nguyên tiêu tốn cao đo được) — không tối ưu dựa trên suy đoán "chắc chỗ này chậm". Tối ưu sai chỗ vừa tốn công sức, vừa có thể làm tăng độ phức tạp mã nguồn ở nơi không thực sự cần thiết, vi phạm nguyên tắc "phạm vi ảnh hưởng nhỏ nhất" ở [`01-core-principles.md`](01-core-principles.md) mục 2.

Khi nghi ngờ 1 thay đổi mới sẽ làm tăng tải đáng kể, cần nêu rõ đánh đổi đó cho người phụ trách dự án biết trước, không âm thầm chấp nhận rủi ro — đây là nhắc lại nguyên tắc đã có ở [`05-database-rules.md`](05-database-rules.md) mục 6, áp dụng rộng hơn cho mọi loại tài nguyên, không chỉ cơ sở dữ liệu.

## 2. Chiến lược lưu đệm (Caching)

**Khi nào nên cache:** dữ liệu được đọc nhiều lần hơn hẳn so với số lần thay đổi, và việc tính toán/truy vấn lại dữ liệu đó có chi phí đáng kể (câu truy vấn nặng, gọi dịch vụ bên ngoài chậm, phép tính phức tạp). Không cache dữ liệu thay đổi liên tục hoặc dữ liệu chỉ được đọc 1 lần duy nhất — chi phí duy trì cache trong trường hợp này lớn hơn lợi ích mang lại.

**Các tầng có thể đặt cache, chọn theo đặc điểm dữ liệu:**
- Cache ở tầng ứng dụng (bộ nhớ tiến trình hoặc kho lưu trữ khoá-giá trị riêng biệt như Redis) — phù hợp dữ liệu cần tính toán lại tốn kém, cần kiểm soát chi tiết thời điểm cập nhật.
- Cache ở tầng giao thức HTTP (header điều khiển cache của trình duyệt/máy chủ trung gian) — phù hợp dữ liệu công khai, ít nhạy cảm, có thể chấp nhận độ trễ cập nhật nhất định.
- Cache ở tầng mạng phân phối nội dung (CDN) — phù hợp tài nguyên tĩnh hoặc nội dung công khai được truy cập từ nhiều vị trí địa lý khác nhau.

**Cache invalidation (làm mất hiệu lực cache khi dữ liệu gốc thay đổi) là phần khó nhất, phải thiết kế có chủ đích, không phải để mặc định:**
- Chiến lược theo thời gian sống (TTL) — đơn giản nhất, chấp nhận dữ liệu có thể cũ trong một khoảng thời gian ngắn nhất định trước khi tự hết hạn. Phù hợp khi độ trễ cập nhật ở mức chấp nhận được là hợp lý với nghiệp vụ.
- Chiến lược chủ động xoá cache khi dữ liệu gốc thay đổi (invalidate ngay tại thời điểm ghi dữ liệu mới) — đảm bảo dữ liệu luôn mới nhất nhưng đòi hỏi mọi đường ghi dữ liệu đều phải nhớ xoá đúng khoá cache liên quan, dễ sót nếu có nhiều đường ghi khác nhau tới cùng 1 dữ liệu.

**Cache stampede (nhiều yêu cầu đồng thời cùng lúc dữ liệu cache vừa hết hạn):** khi cache hết hạn đúng lúc có nhiều yêu cầu đồng thời truy cập cùng 1 khoá, tất cả có thể cùng lúc dội xuống tính toán lại/truy vấn lại nguồn dữ liệu gốc, gây tải đột biến. Cân nhắc cơ chế khoá tính toán lại (chỉ 1 yêu cầu được phép tính lại, các yêu cầu khác chờ hoặc dùng tạm giá trị cũ) khi dữ liệu có tần suất truy cập cao và chi phí tính toán lại lớn.

## 3. Chiến lược phân trang: offset-based vs cursor-based

**Phân trang theo offset** (bỏ qua N bản ghi đầu, lấy tiếp M bản ghi) — đơn giản để triển khai và để phía gọi API hiểu (có thể nhảy thẳng tới trang bất kỳ), nhưng có 2 nhược điểm quan trọng: hiệu năng giảm dần khi offset càng lớn (cơ sở dữ liệu vẫn phải duyệt qua toàn bộ bản ghi bị bỏ qua), và kết quả có thể không ổn định nếu dữ liệu bị thêm/xoá giữa các lần gọi trang (1 bản ghi có thể xuất hiện lặp lại ở 2 trang, hoặc bị bỏ sót hoàn toàn).

**Phân trang theo con trỏ (cursor-based)** — dùng giá trị của bản ghi cuối cùng ở trang hiện tại (thường là khoá chính hoặc một cột có thứ tự rõ ràng) làm điểm bắt đầu cho trang tiếp theo, thay vì đếm offset. Hiệu năng ổn định không phụ thuộc vị trí trang, và kết quả ổn định hơn khi dữ liệu thay đổi liên tục. Đánh đổi: không cho phép nhảy thẳng tới trang bất kỳ (chỉ đi tuần tự tiến/lùi), phức tạp hơn khi triển khai.

**Chọn chiến lược nào:** offset-based phù hợp danh sách có kích thước vừa phải, ít thay đổi, cần hỗ trợ nhảy trang tuỳ ý (giao diện quản trị thông thường). Cursor-based phù hợp danh sách lớn, thay đổi liên tục theo thời gian thực, hoặc luồng dữ liệu dạng cuộn vô hạn (infinite scroll). Quyết định này nên được cân nhắc ngay khi thiết kế endpoint, không phải thay đổi dễ dàng sau khi phía gọi đã tích hợp theo 1 kiểu.

## 4. Chiến lược đánh chỉ mục (Indexing)

Không thêm chỉ mục một cách tuỳ tiện cho mọi cột — mỗi chỉ mục tăng tốc độ đọc nhưng đồng thời làm chậm tốc độ ghi (mọi lần thêm/sửa/xoá bản ghi đều phải cập nhật lại toàn bộ chỉ mục liên quan) và tốn thêm dung lượng lưu trữ. Cần cân bằng giữa 2 yếu tố này dựa trên đặc điểm sử dụng thật của bảng dữ liệu (đọc nhiều hay ghi nhiều hơn).

**Ưu tiên đánh chỉ mục cho:** cột thường xuyên xuất hiện trong điều kiện lọc (mệnh đề tìm kiếm theo điều kiện), cột dùng để sắp xếp kết quả, cột dùng để nối bảng (join). Với điều kiện lọc kết hợp nhiều cột cùng lúc, cân nhắc chỉ mục kết hợp (composite index) thay vì nhiều chỉ mục đơn lẻ riêng biệt — thứ tự các cột trong chỉ mục kết hợp cần khớp với thứ tự thường dùng trong điều kiện lọc thật để phát huy hiệu quả.

**Không suy đoán chỉ mục cần thiết — xác minh bằng công cụ phân tích câu truy vấn thật** (lệnh giải thích kế hoạch thực thi mà hầu hết hệ quản trị cơ sở dữ liệu đều cung cấp) trước khi quyết định thêm chỉ mục mới, đặc biệt với bảng dữ liệu đã lớn — thêm sai chỉ mục không giúp ích gì mà còn làm chậm ghi dữ liệu một cách vô ích.

## 5. Đẩy tác vụ nặng ra xử lý bất đồng bộ (Async/Queue)

**Nhận diện tác vụ nên đẩy ra xử lý nền thay vì xử lý ngay trong vòng đời của 1 request:** tác vụ có thời gian xử lý dài (gửi email, xử lý/chuyển đổi tệp lớn, tạo báo cáo tổng hợp phức tạp), tác vụ không cần phản hồi kết quả ngay lập tức cho người dùng, hoặc tác vụ có thể chấp nhận độ trễ nhất định trước khi hoàn thành.

**Mô hình hàng đợi (message queue):** thay vì xử lý tác vụ ngay trong request, đẩy 1 thông điệp mô tả công việc cần làm vào hàng đợi, trả phản hồi ngay cho người dùng (xác nhận đã tiếp nhận yêu cầu), rồi một tiến trình xử lý riêng (worker/consumer) lấy thông điệp ra khỏi hàng đợi và thực hiện công việc thực sự. Việc này tách rời thời gian phản hồi cho người dùng khỏi thời gian xử lý thực tế của tác vụ nặng.

**Idempotency của consumer là bắt buộc, không phải tuỳ chọn:** một thông điệp trong hàng đợi có thể bị xử lý nhiều hơn 1 lần trong một số tình huống hạ tầng (mất kết nối giữa chừng, cơ chế đảm bảo phân phối lại thông điệp chưa được xác nhận xử lý xong) — do đó logic xử lý thông điệp phải được viết theo cách chạy lại nhiều lần không gây hậu quả xấu (đúng tinh thần nguyên tắc idempotent đã nêu ở [`03-error-handling-resilience.md`](03-error-handling-resilience.md) mục 2 về việc retry hành động không idempotent).

**Hàng đợi chết (dead-letter queue):** khi 1 thông điệp xử lý thất bại nhiều lần liên tiếp vượt quá ngưỡng cho phép, nên được chuyển sang một hàng đợi riêng dành cho các thông điệp lỗi (thay vì lặp lại vô hạn hoặc bị mất hoàn toàn), để người vận hành có thể xem xét và xử lý thủ công sau — tránh tình trạng 1 thông điệp lỗi liên tục chiếm giữ tài nguyên xử lý mà không bao giờ thành công.

**Không bắt buộc mọi dự án phải có hệ thống hàng đợi phức tạp ngay từ đầu.** Với dự án nhỏ, tác vụ nền đơn giản có thể xử lý bằng cơ chế lập lịch định kỳ trong chính tiến trình ứng dụng (đã đề cập ở [`04-project-structure.md`](04-project-structure.md) mục 2, tầng xử lý nền). Chỉ chuyển sang hệ thống hàng đợi chuyên dụng khi khối lượng công việc hoặc yêu cầu độ tin cậy vượt quá khả năng của cơ chế đơn giản này.

## 6. Giới hạn kích thước dữ liệu trao đổi

**Giới hạn kích thước toàn bộ nội dung request** (không chỉ giới hạn độ dài từng trường văn bản riêng lẻ đã nêu ở [`02-security-baseline.md`](02-security-baseline.md) mục 3) — phải được cấu hình ở tầng nhận request, để chặn sớm các request có kích thước bất thường lớn trước khi chúng được xử lý sâu hơn, vừa bảo vệ hiệu năng vừa là một lớp phòng thủ chống tấn công từ chối dịch vụ bằng payload khổng lồ.

**Nén nội dung phản hồi (response compression):** với phản hồi có kích thước lớn (đặc biệt dữ liệu dạng văn bản như JSON, HTML), bật cơ chế nén trước khi truyền qua mạng giúp giảm đáng kể thời gian truyền tải, đặc biệt quan trọng khi phía nhận có băng thông hạn chế. Cân nhắc chi phí xử lý nén (tốn thêm CPU) so với lợi ích giảm băng thông — với phản hồi nhỏ, chi phí nén có thể lớn hơn lợi ích mang lại.

## 7. Mạng phân phối nội dung (CDN) cho tài nguyên tĩnh

Tài nguyên tĩnh không đổi hoặc ít đổi (tệp giao diện đã biên dịch, hình ảnh, phông chữ) nên được phục vụ qua mạng phân phối nội dung thay vì trực tiếp từ máy chủ ứng dụng — giảm tải cho máy chủ ứng dụng (chỉ tập trung xử lý logic động), và giảm độ trễ cho người dùng ở xa vị trí đặt máy chủ gốc (CDN có nhiều điểm phân phối theo vị trí địa lý). Đây là điểm nối tiếp với nguyên tắc tách thư mục dữ liệu công khai đã nêu ở [`04-project-structure.md`](04-project-structure.md) mục 4 — dữ liệu trong thư mục công khai chính là ứng viên phù hợp để đẩy lên CDN khi vận hành ở quy mô lớn hơn.

---

## Checklist nhanh — khi cân nhắc tối ưu hiệu năng hoặc thiết kế cho khả năng mở rộng

- [ ] Có bằng chứng đo lường thật cho thấy đây là điểm nghẽn, hay đang tối ưu theo cảm tính?
- [ ] Nếu dùng cache, chiến lược làm mất hiệu lực cache (invalidation) đã được thiết kế rõ ràng chưa, hay chỉ dựa vào thời gian hết hạn mặc định mà chưa cân nhắc độ trễ chấp nhận được?
- [ ] Danh sách có khả năng phát triển lớn/thay đổi liên tục đã chọn đúng chiến lược phân trang (offset hay cursor) phù hợp đặc điểm dữ liệu chưa?
- [ ] Chỉ mục cơ sở dữ liệu có được thêm dựa trên phân tích kế hoạch thực thi thật, không suy đoán tuỳ tiện?
- [ ] Tác vụ nặng/dài có được đẩy ra xử lý nền, và nếu dùng hàng đợi, logic xử lý có idempotent không?
- [ ] Kích thước request/response có được giới hạn/nén hợp lý chưa?

---

*Xem tiếp: [`09-operations-reliability.md`](09-operations-reliability.md) — vận hành và độ tin cậy ở tầng hạ tầng.*
