# 07 — Chiến lược kiểm thử (Testing Strategy)

> Đào sâu nguyên tắc backtest đã nêu ở [`01-core-principles.md`](01-core-principles.md) mục 4. Áp dụng cho mọi giai đoạn — khởi tạo dự án nên dựng khung kiểm thử ngay từ đầu, duy trì thường xuyên phải giữ bộ kiểm thử luôn phản ánh đúng nghiệp vụ hiện tại.

---

## 1. Phân tầng kiểm thử theo mục đích

**Kiểm thử đơn vị (unit test):** kiểm tra 1 đơn vị logic nhỏ nhất, độc lập, không phụ thuộc vào cơ sở dữ liệu thật, mạng thật, hay dịch vụ bên ngoài thật. Các phụ thuộc bên ngoài được thay thế bằng phiên bản giả lập (mock/stub) trong phạm vi bài kiểm thử. Chạy nhanh, phù hợp để kiểm tra logic nghiệp vụ thuần tuý và các trường hợp biên (edge case) mà không cần dựng toàn bộ môi trường.

**Kiểm thử tích hợp (integration test):** kiểm tra nhiều thành phần phối hợp với nhau, thường cần một cơ sở dữ liệu thật (ở môi trường kiểm thử riêng biệt, tách khỏi dữ liệu vận hành thật) hoặc gọi thật tới các tầng bên trong ứng dụng (route thật, không giả lập). Chạy chậm hơn kiểm thử đơn vị nhưng phát hiện được lỗi ở ranh giới giữa các thành phần mà kiểm thử đơn vị không thấy được (ví dụ câu truy vấn sai cú pháp thật, luồng xác thực thật).

**Kiểm thử hiệu năng dưới tải đồng thời (load/concurrency test):** giả lập nhiều luồng xử lý hoặc nhiều người dùng gọi đồng thời vào cùng 1 tài nguyên. Bắt buộc có riêng, không thể thay thế bằng kiểm thử tuần tự thông thường — vì các lỗi liên quan tới giao dịch/khoá dữ liệu (đã nêu ở [`05-database-rules.md`](05-database-rules.md) mục 3) chỉ lộ ra dưới tải đồng thời thật, kiểm thử tuần tự luôn cho kết quả đúng dù logic có lỗi race condition tiềm ẩn.

Không nhất thiết dự án nào cũng cần đủ cả 3 tầng ngay từ đầu — nhưng khi 1 luồng nghiệp vụ có đặc điểm phù hợp với 1 tầng cụ thể (ví dụ luồng có khả năng bị nhiều người dùng thao tác đồng thời trong thực tế), tầng kiểm thử tương ứng là bắt buộc, không phải tuỳ chọn.

## 2. Khi nào bắt buộc phải có kiểm thử

**Thêm tính năng mới (đặc biệt endpoint mới):** phải có kiểm thử cho luồng chính (dữ liệu đầu vào hợp lệ, kết quả đúng mong đợi) và các trường hợp biên liên quan trực tiếp (dữ liệu đầu vào không hợp lệ, thiếu quyền truy cập, dữ liệu trùng lặp). Không coi 1 tính năng là hoàn thành nếu chưa có kiểm thử tương ứng.

**Sửa đổi hành vi nghiệp vụ đã có** (thay đổi cách một API xử lý, đổi quy tắc validate, thêm một trạng thái mới vào luồng xử lý nhiều trạng thái): phải cập nhật lại các trường hợp kiểm thử cũ cho khớp với hành vi mới. Kiểm thử cũ vẫn chạy qua (pass) với mã nguồn mới không đồng nghĩa với việc hành vi mới là đúng — có khả năng kiểm thử cũ đang kiểm tra một kỳ vọng đã lỗi thời, cần xác nhận lại hành vi mới thật sự đúng theo yêu cầu trước khi coi kết quả kiểm thử là đáng tin.

**Xoá bỏ một tính năng:** xoá luôn các trường hợp kiểm thử tương ứng với tính năng đó — không để lại kiểm thử mồ côi (kiểm thử một thứ không còn tồn tại trong hệ thống), vì điều này gây nhiễu khi đọc bộ kiểm thử sau này và có thể khiến người đọc lầm tưởng tính năng đó vẫn còn.

## 3. Chạy lại toàn bộ kiểm thử sau mỗi lần thay đổi, không chỉ kiểm thử mới thêm

Sau khi hoàn thành 1 thay đổi, phải chạy lại toàn bộ bộ kiểm thử hiện có của dự án, không chỉ chạy riêng phần kiểm thử vừa viết/sửa — mục đích là xác nhận thay đổi vừa thực hiện không vô tình phá vỡ hành vi khác đã đúng trước đó (regression). Nếu có kiểm thử thất bại, phải dừng lại và xử lý ngay, không dồn lại xử lý sau (dồn lại càng lâu càng khó xác định thay đổi nào gây ra lỗi).

Nếu một thay đổi nghiệp vụ làm nhiều kiểm thử thất bại cùng lúc, đó là dấu hiệu tốt cho thấy bộ kiểm thử đang làm đúng vai trò bảo vệ mã nguồn của nó — cần xử lý từng trường hợp thất bại một cách cẩn trọng, xác nhận rõ hành vi mới là đúng theo yêu cầu trước khi sửa lại nội dung kiểm tra (assertion) cho khớp, không sửa nội dung kiểm tra một cách vội vàng chỉ để kiểm thử chạy qua.

## 4. Dữ liệu kiểm thử phải tách biệt hoàn toàn khỏi dữ liệu vận hành thật

Môi trường chạy kiểm thử tích hợp nên dùng một cơ sở dữ liệu hoàn toàn riêng biệt, không chạm vào dữ liệu vận hành thật dưới bất kỳ hình thức nào — không có trường hợp ngoại lệ "chạy thử một lần trên dữ liệu thật cho nhanh". Dữ liệu kiểm thử nên được thiết lập lại từ đầu (hoặc dọn sạch) trước/sau mỗi lần chạy, để đảm bảo kết quả kiểm thử không phụ thuộc vào trạng thái dữ liệu còn sót lại từ lần chạy trước.

Nếu cần một cơ chế cho phép kiểm thử tự động thực hiện các thao tác đặc biệt (ví dụ tạo phiên đăng nhập giả lập mà không cần gọi thật tới dịch vụ xác thực bên ngoài), cơ chế này phải được khoá bằng một cờ môi trường riêng biệt chỉ được đặt bởi chính bộ công cụ kiểm thử tự động — không dùng chung với cờ xác định môi trường tổng quát của ứng dụng, vì điều này có thể vô tình mở một đường vòng qua xác thực trên môi trường vận hành thật nếu giá trị cờ trùng lặp (xem chi tiết nguyên nhân ở [`02-security-baseline.md`](02-security-baseline.md) mục 1).

## 5. Kiểm thử là lưới an toàn — phải phản ánh đúng nghiệp vụ thật, không phải hình thức

Một bộ kiểm thử chỉ có giá trị khi nó thật sự phản ánh đúng nghiệp vụ mong đợi. Viết kiểm thử chỉ để đạt một con số tỷ lệ bao phủ (coverage) mà không thật sự kiểm tra đúng logic quan trọng là vô nghĩa — tệ hơn, nó tạo cảm giác an toàn giả, khiến người sau tin tưởng nhầm vào một lưới bảo vệ không thực sự vững.

Khi viết kiểm thử cho một hàm/luồng có nhiều nhánh trạng thái khác nhau, phải bao quát đủ toàn bộ các nhánh đó, không chỉ kiểm thử nhánh dễ nhất hoặc nhánh hay xảy ra nhất — các nhánh ít gặp (trường hợp biên, trường hợp lỗi) thường chính là nơi lỗi thật sự ẩn náu.

## 6. Xác minh thủ công khi không có điều kiện kiểm thử tự động

Không phải mọi khía cạnh của một hệ thống đều dễ dàng viết kiểm thử tự động (ví dụ tương tác giao diện phức tạp, hành vi phụ thuộc thiết bị phần cứng cụ thể, widget nhúng chạy trên môi trường trình duyệt của bên thứ ba). Trong những trường hợp này:

- Xác minh thủ công có chủ đích (thao tác qua giao diện thật với kịch bản chính và kịch bản biên liên quan tới thay đổi) vẫn là bắt buộc, không được bỏ qua chỉ vì khó tự động hoá.
- Nếu điều kiện không cho phép xác minh đầy đủ (ví dụ không dựng được đúng môi trường để quan sát bằng mắt), phải nói rõ giới hạn đó khi báo cáo hoàn thành — không khẳng định chắc chắn "đã hoạt động đúng" khi chưa thực sự kiểm chứng được.
- Với những thành phần đặc biệt khó kiểm thử tự động nhưng cần độ tin cậy cao hơn mức "đọc mắt", có thể cân nhắc xây dựng một công cụ xác minh tạm thời chạy thật đoạn mã nguồn đó trong một môi trường giả lập tối thiểu (không phải toàn bộ trình duyệt thật) để bắt được các lỗi liên quan tới thời gian/thứ tự thực thi mà việc đọc mã tĩnh dễ bỏ sót — công cụ xác minh tạm thời này nên được dọn bỏ sau khi hoàn thành xác minh, không để lại như một phần thường trực của mã nguồn nếu nó không phải một bài kiểm thử chính thức được duy trì lâu dài.

---

## Checklist nhanh — trước khi coi 1 thay đổi là đã kiểm thử đầy đủ

- [ ] Tính năng mới có kiểm thử cho luồng chính và các trường hợp biên liên quan chưa?
- [ ] Thay đổi hành vi nghiệp vụ có cập nhật lại kiểm thử cũ cho khớp, đã xác nhận hành vi mới thật sự đúng chưa?
- [ ] Đã chạy lại toàn bộ bộ kiểm thử (không chỉ phần mới) và toàn bộ đều qua chưa?
- [ ] Luồng nghiệp vụ có khả năng bị thao tác đồng thời có được kiểm thử dưới tải đồng thời thật chưa?
- [ ] Nếu không có điều kiện kiểm thử tự động đầy đủ, giới hạn đó có được nói rõ khi báo cáo hoàn thành không?

---

*Xem tiếp: [`08-performance-scaling.md`](08-performance-scaling.md) — hiệu năng và khả năng mở rộng.*
