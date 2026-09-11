# 09 — Vận hành & Độ tin cậy (Operations & Reliability)

> Đào sâu khía cạnh vận hành thực tế của ứng dụng sau khi đã triển khai — bổ sung cho [`03-error-handling-resilience.md`](03-error-handling-resilience.md) (xử lý lỗi ở mức logic) và [`04-project-structure.md`](04-project-structure.md) (cấu trúc). Áp dụng đặc biệt quan trọng khi ứng dụng chạy trên hạ tầng container/điều phối tự động (Kubernetes, Cloud Run, hoặc tương tự), nhưng nguyên tắc vẫn có giá trị ngay cả khi chạy trên 1 máy chủ đơn giản.

---

## 1. Kiểm tra sức khoẻ ứng dụng (Health Check)

Ứng dụng nên cung cấp 1 hoặc nhiều endpoint riêng biệt phục vụ mục đích kiểm tra tình trạng hoạt động, tách biệt hoàn toàn khỏi các endpoint nghiệp vụ thông thường — không dùng chung 1 endpoint nghiệp vụ để suy luận gián tiếp "ứng dụng có đang chạy không".

**Phân biệt 2 loại kiểm tra thường gặp (tên gọi có thể khác nhau tuỳ nền tảng điều phối, nhưng ý nghĩa tương tự):**
- **Kiểm tra tiến trình còn sống (liveness):** chỉ xác nhận tiến trình ứng dụng vẫn đang chạy, không bị treo hoàn toàn — không nên kiểm tra các phụ thuộc bên ngoài (cơ sở dữ liệu, dịch vụ khác) trong bài kiểm tra này, vì nếu 1 phụ thuộc bên ngoài tạm thời gặp sự cố, hệ thống điều phối có thể hiểu nhầm là chính tiến trình ứng dụng đã chết và khởi động lại nó một cách không cần thiết, trong khi vấn đề thực sự nằm ở phụ thuộc bên ngoài.
- **Kiểm tra sẵn sàng phục vụ (readiness):** xác nhận ứng dụng đã sẵn sàng nhận và xử lý request thật (đã kết nối được cơ sở dữ liệu, đã nạp xong cấu hình cần thiết) — bài kiểm tra này nên kiểm tra các phụ thuộc quan trọng, và hệ thống điều phối dùng kết quả này để quyết định có nên định tuyến traffic tới instance này hay chưa (ví dụ trong lúc khởi động, hoặc trong lúc phụ thuộc tạm thời gián đoạn).

Không lạm dụng health check để trả về quá nhiều thông tin chi tiết nội bộ ra ngoài (tránh rò rỉ thông tin hạ tầng cho bất kỳ ai gọi được endpoint này) — chỉ cần đủ để hệ thống điều phối/giám sát biết trạng thái tổng quát.

## 2. Tắt (shutdown) có kiểm soát

Khi tiến trình ứng dụng nhận tín hiệu yêu cầu dừng (thường xảy ra khi triển khai phiên bản mới, khi hệ thống điều phối chủ động luân chuyển tải, hoặc khi thu hẹp quy mô), ứng dụng không nên dừng đột ngột ngay lập tức. Cần có 1 quy trình dừng có trật tự:

1. Ngừng nhận request/công việc mới (thông báo cho hệ thống điều phối/cân bằng tải biết instance này sắp không còn khả dụng, thường qua việc bài kiểm tra sẵn sàng bắt đầu trả về trạng thái không sẵn sàng).
2. Cho phép các request/công việc đang xử lý dở hoàn tất trong một khoảng thời gian hợp lý (không cắt ngang đột ngột, tránh dữ liệu ở trạng thái nửa vời).
3. Đóng các kết nối tài nguyên đang giữ (kết nối cơ sở dữ liệu, kết nối hàng đợi, tiến trình nền định kỳ) một cách rõ ràng, không để lại kết nối treo.
4. Sau khi hoàn tất các bước trên (hoặc hết thời gian chờ tối đa cho phép), tiến trình mới thực sự kết thúc.

Nếu bỏ qua quy trình này, hậu quả có thể là: request đang xử lý dở bị ngắt giữa chừng gây dữ liệu không nhất quán, kết nối cơ sở dữ liệu không được đóng đúng cách gây rò rỉ tài nguyên phía cơ sở dữ liệu, hoặc tác vụ nền đang chạy dở bị dừng đột ngột không rõ trạng thái.

## 3. Xác thực cấu hình lúc khởi động — thất bại sớm (Fail-Fast)

Ngay khi tiến trình ứng dụng khởi động, trước khi bắt đầu nhận bất kỳ request nào, phải kiểm tra đầy đủ mọi cấu hình bắt buộc đã có giá trị hợp lệ hay chưa (biến môi trường bắt buộc, giá trị bí mật bắt buộc theo môi trường vận hành thật đã nêu ở [`02-security-baseline.md`](02-security-baseline.md) mục 4). Nếu thiếu bất kỳ cấu hình bắt buộc nào, ứng dụng nên từ chối khởi động ngay lập tức kèm thông báo lỗi rõ ràng chỉ đúng cấu hình nào đang thiếu — không để ứng dụng khởi động "có vẻ thành công" rồi mới gặp lỗi giữa chừng khi thực sự cần dùng tới cấu hình đó ở một request bất kỳ sau này.

Nguyên tắc "thất bại sớm" này giúp phát hiện lỗi cấu hình ngay tại thời điểm triển khai (dễ phát hiện, dễ khắc phục ngay) thay vì để lỗi âm thầm tồn tại và chỉ lộ ra khi một luồng nghiệp vụ cụ thể chạm tới cấu hình bị thiếu, có thể là rất lâu sau khi triển khai và khó truy ngược lại nguyên nhân.

## 4. Khả năng quan sát hệ thống (Observability) — vượt ra ngoài log

Ghi log (đã nêu chi tiết ở [`03-error-handling-resilience.md`](03-error-handling-resilience.md) mục 5) là một trong ba trụ cột của khả năng quan sát hệ thống, nhưng không phải là tất cả. Với hệ thống có độ phức tạp tăng lên (nhiều dịch vụ phối hợp, tải lớn), cần thêm:

- **Số liệu đo lường (metrics):** các con số định lượng theo thời gian phản ánh sức khoẻ vận hành — số lượng request mỗi giây, thời gian phản hồi trung bình/phân vị, tỷ lệ lỗi, mức sử dụng tài nguyên (CPU, bộ nhớ, số kết nối cơ sở dữ liệu đang dùng). Khác với log (ghi lại từng sự kiện rời rạc), metrics là dữ liệu tổng hợp theo thời gian, phù hợp để phát hiện xu hướng bất thường và cấu hình cảnh báo tự động khi vượt ngưỡng.
- **Dấu vết phân tán (distributed tracing):** khi 1 request đi qua nhiều dịch vụ/thành phần khác nhau trước khi hoàn tất, tracing giúp theo dõi được toàn bộ hành trình của request đó qua từng thành phần, xác định chính xác thành phần nào gây ra độ trễ hoặc lỗi trong toàn bộ chuỗi xử lý — điều mà log ở từng thành phần riêng lẻ khó ghép lại được nếu không có 1 định danh xuyên suốt (trace ID) gắn theo request từ đầu tới cuối.

Không bắt buộc mọi dự án phải có đầy đủ hệ thống metrics/tracing phức tạp ngay từ đầu — quy mô công cụ quan sát nên tương xứng với độ phức tạp thật của hệ thống. Nhưng ngay cả ở quy mô nhỏ, nên có ý thức gắn 1 định danh duy nhất cho mỗi request (request ID) xuyên suốt các dòng log liên quan tới request đó, để dễ dàng lọc và ghép log lại khi cần điều tra 1 sự cố cụ thể.

## 5. Tiêm phụ thuộc (Dependency Injection) và khả năng kiểm thử

Các thành phần phụ thuộc lẫn nhau (ví dụ tầng xử lý nghiệp vụ cần dùng tới tầng truy cập dữ liệu) nên nhận phụ thuộc của mình thông qua tham số truyền vào hoặc cơ chế đăng ký/khởi tạo tường minh, thay vì tự ý khởi tạo trực tiếp phụ thuộc đó ngay bên trong chính mình hoặc dựa vào biến toàn cục.

**Lý do nguyên tắc này quan trọng, không chỉ là sở thích phong cách viết mã:**
- Cho phép thay thế phụ thuộc bằng phiên bản giả lập khi viết kiểm thử đơn vị (đã nêu ở [`07-testing-strategy.md`](07-testing-strategy.md) mục 1) — nếu 1 thành phần tự khởi tạo cứng phụ thuộc cơ sở dữ liệu thật bên trong chính nó, không thể kiểm thử đơn vị thành phần đó mà không có cơ sở dữ liệu thật đi kèm.
- Làm rõ ràng, tường minh mối quan hệ phụ thuộc giữa các thành phần — chỉ cần đọc tham số đầu vào của 1 thành phần là biết nó cần gì để hoạt động, không phải đọc sâu vào bên trong mới phát hiện phụ thuộc ẩn.
- Với các ngôn ngữ/framework có hỗ trợ container tiêm phụ thuộc sẵn có (phổ biến ở hệ sinh thái .NET, Java Spring, hoặc các framework Node.js hướng kiến trúc theo mô-đun), nên tận dụng cơ chế có sẵn đó thay vì tự xây dựng lại. Với các framework tối giản không có cơ chế này sẵn (ví dụ Express thuần), vẫn áp dụng được nguyên tắc tương tự một cách thủ công — truyền phụ thuộc qua tham số hàm khởi tạo route/service thay vì gọi trực tiếp module phụ thuộc từ bên trong.

---

## Checklist nhanh — khi triển khai hoặc rà soát khía cạnh vận hành

- [ ] Ứng dụng có endpoint kiểm tra sức khoẻ riêng biệt, phân biệt rõ "còn sống" và "sẵn sàng phục vụ" chưa?
- [ ] Ứng dụng có xử lý tín hiệu dừng có kiểm soát (đóng kết nối, chờ request dở hoàn tất) thay vì dừng đột ngột không?
- [ ] Cấu hình bắt buộc có được xác thực ngay lúc khởi động, từ chối chạy nếu thiếu, thay vì lỗi giữa chừng khi dùng tới không?
- [ ] Log có gắn định danh xuyên suốt theo từng request để dễ ghép lại khi điều tra sự cố không?
- [ ] Các thành phần có nhận phụ thuộc qua tham số/cơ chế tường minh, hay đang tự khởi tạo cứng phụ thuộc bên trong khiến khó kiểm thử riêng lẻ?

---

*Xem tiếp: [`10-phase-init-new-project.md`](10-phase-init-new-project.md) — quy tắc khởi tạo dự án mới.*
