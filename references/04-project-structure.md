# 04 — Cấu trúc thư mục dự án (Project Structure)

> Áp dụng chính khi khởi tạo dự án mới ([`10-phase-init-new-project.md`](10-phase-init-new-project.md)) hoặc khi tổ chức lại dự án cũ ([`11-phase-refactor-legacy.md`](11-phase-refactor-legacy.md)). Nguyên tắc module hoá (khi nào tách 1 hàm/class riêng) đã nêu ở [`01-core-principles.md`](01-core-principles.md) mục 6 — file này chỉ tập trung vào cách sắp xếp thư mục.

---

## 1. Nguyên tắc chọn cách tổ chức thư mục

**Tách theo trách nhiệm kỹ thuật (layer) là mặc định cho dự án nhỏ và vừa.** Chỉ chuyển sang tách theo tính năng/nghiệp vụ (module/feature-based) khi dự án đã đủ lớn — không module hoá thư mục ngay từ đầu nếu chưa cần, vì làm vậy tạo ra nhiều thư mục con rỗng hoặc chỉ có 1-2 file, gây khó tìm hơn là dễ tìm.

**Tên thư mục nên phản ánh vai trò kỹ thuật, không phản ánh tên công nghệ/framework cụ thể.** Mục đích: đổi framework hoặc ngôn ngữ lập trình sau này không bắt buộc đổi tư duy tổ chức thư mục, người mới vào dự án ở bất kỳ stack nào cũng đoán được vai trò của từng thư mục qua tên gọi.

**Hướng phụ thuộc giữa các layer chỉ được chảy một chiều:** tầng tiếp nhận request → tầng xử lý nghiệp vụ → tầng truy cập dữ liệu. Tầng ở dưới không được phép biết tới hoặc gọi ngược lại tầng ở trên. Vi phạm nguyên tắc này (ví dụ tầng truy cập dữ liệu tự gọi thẳng vào tầng xử lý request) sẽ tạo ra phụ thuộc vòng, khó kiểm thử riêng từng tầng, và khó thay thế 1 tầng mà không ảnh hưởng tầng khác.

---

## 2. Cấu trúc mặc định — layer-based (dự án nhỏ và vừa)

Thư mục mã nguồn nên tách thành các vai trò rõ ràng:

- **Điểm khởi động (entry point):** nơi duy nhất chịu trách nhiệm khởi động ứng dụng — nạp cấu hình, kết nối cơ sở dữ liệu, đăng ký các tầng xử lý, và bắt đầu lắng nghe kết nối. Không chứa logic nghiệp vụ.
- **Tầng cấu hình:** đọc biến môi trường và file cấu hình, cung cấp một cách truy xuất thống nhất cho phần còn lại của ứng dụng — không rải rác việc đọc biến môi trường trực tiếp ở nhiều nơi khác nhau trong mã nguồn.
- **Tầng tiếp nhận request (route/controller):** chỉ chịu trách nhiệm nhận request, đọc/validate tham số đầu vào ở mức cơ bản, gọi xuống tầng xử lý nghiệp vụ, và định dạng phản hồi trả về. Không chứa logic nghiệp vụ phức tạp hay câu truy vấn cơ sở dữ liệu trực tiếp trong tầng này.
- **Tầng xử lý nghiệp vụ (service):** chứa toàn bộ quy tắc và luồng xử lý nghiệp vụ thật sự — không biết gì về chi tiết giao thức HTTP (không đọc trực tiếp từ request/response) và không biết chi tiết câu lệnh truy vấn cơ sở dữ liệu cụ thể (gọi xuống tầng truy cập dữ liệu thông qua các hàm có tên nghiệp vụ rõ ràng).
- **Tầng truy cập dữ liệu (repository/data access):** chứa toàn bộ câu truy vấn/thao tác với cơ sở dữ liệu hoặc nguồn lưu trữ khác. Đây là tầng duy nhất được phép biết cấu trúc bảng/schema cụ thể.
- **Tầng xử lý xuyên suốt (middleware):** các thao tác áp dụng chung cho nhiều/mọi request — xác thực, ghi log truy cập, xử lý lỗi tổng, giới hạn tốc độ gọi.
- **Thư mục dùng chung (common/shared/lib):** chứa các hàm/tiện ích được nhiều tầng hoặc nhiều tính năng cùng dùng — theo đúng nguyên tắc module hoá đã nêu ở file 01.
- **Tầng xử lý nền (job/scheduler, nếu có):** tác vụ chạy định kỳ hoặc xử lý hàng đợi, tách riêng khỏi vòng đời xử lý 1 request thông thường vì có đặc điểm vận hành khác hẳn (chạy nền, không có người đang chờ phản hồi trực tiếp).

Song song với mã nguồn ứng dụng, dự án nên có các thư mục cấp cao khác:

- **Thư mục quản lý phiên bản schema cơ sở dữ liệu (migration):** mỗi thay đổi cấu trúc dữ liệu là 1 tệp riêng, có thứ tự thời gian rõ ràng, và có khả năng chạy lại nhiều lần mà không gây lỗi (idempotent) — không có thao tác phá huỷ dữ liệu không kiểm soát trong tệp migration.
- **Thư mục kiểm thử (test):** nên phản chiếu lại cấu trúc thư mục mã nguồn, để dễ dàng biết 1 tệp mã nguồn tương ứng với tệp kiểm thử nào. Phân tách rõ kiểm thử đơn vị (kiểm tra 1 đơn vị logic độc lập, không phụ thuộc cơ sở dữ liệu/mạng thật) và kiểm thử tích hợp (kiểm tra nhiều thành phần phối hợp với nhau, có thể cần cơ sở dữ liệu thật ở môi trường kiểm thử riêng).
- **Thư mục công cụ vận hành (scripts):** các thao tác thực hiện thủ công không thuộc vòng đời request thông thường — triển khai, tạo dữ liệu mẫu ban đầu, chạy migration.
- **Thư mục tài liệu kiến trúc (docs):** tài liệu tổng quan kiến trúc, khác với thư mục tri thức dự án bắt buộc (memory-bank) — xem [`20-memory-bank-mandate.md`](20-memory-bank-mandate.md) để phân biệt rõ vai trò của 2 thư mục này.
- **Thư mục tri thức dự án (memory-bank):** bắt buộc có ở mọi dự án áp dụng bộ quy tắc này — chi tiết đầy đủ ở nhóm file 20.

---

## 3. Ngưỡng chuyển sang cấu trúc theo module (dự án lớn)

Không chuyển đổi cấu trúc chỉ vì "cảm thấy" dự án lớn — cần dấu hiệu cụ thể để quyết định:

- Một tầng kỹ thuật (ví dụ tầng xử lý nghiệp vụ) chứa quá nhiều tệp không cùng chung 1 nhóm nghiệp vụ rõ ràng, tới mức việc tìm đúng tệp cần sửa trở nên mất thời gian.
- Có từ 3 nhóm nghiệp vụ độc lập trở lên, gần như không chia sẻ logic với nhau, mỗi nhóm có thể phát triển/thay đổi độc lập mà không ảnh hưởng nhóm khác.

Khi đã đạt ngưỡng này, tổ chức lại theo từng nhóm nghiệp vụ (module), và bên trong mỗi module vẫn giữ nguyên các tầng kỹ thuật con (tiếp nhận request, xử lý nghiệp vụ, truy cập dữ liệu) — chỉ khác là mỗi module có bản sao riêng của các tầng con này thay vì dùng chung 1 tầng cho toàn bộ ứng dụng. Thư mục dùng chung giữa các module (`common`/`shared`) vẫn giữ nguyên vai trò riêng biệt, không thuộc về module nào cụ thể.

**Việc chuyển đổi cấu trúc thư mục là một thay đổi lớn về tổ chức, không phải thay đổi hành vi** — áp dụng đúng nguyên tắc đã nêu ở file 01: tách cơ học trước (di chuyển tệp, giữ nguyên logic bên trong), tối ưu/cải tiến logic sau nếu cần, không gộp 2 việc "tổ chức lại thư mục" và "sửa logic nghiệp vụ" trong cùng 1 lần thay đổi.

---

## 4. Cấu trúc thư mục dữ liệu tĩnh (storage)

Tách hẳn khỏi thư mục mã nguồn — đây là nơi chứa dữ liệu do người dùng tải lên hoặc dữ liệu tĩnh phục vụ ứng dụng, không phải mã nguồn.

**Nguyên tắc cốt lõi: ranh giới công khai/riêng tư phải được đặt ở cấp thư mục cao nhất, dễ nhận biết ngay khi nhìn vào cây thư mục** — không trộn lẫn dữ liệu công khai và dữ liệu nhạy cảm trong cùng 1 thư mục rồi dựa vào tên file để phân biệt.

- **Thư mục dữ liệu công khai:** được phép phục vụ trực tiếp qua cơ chế phục vụ tệp tĩnh tự động (static file serving) hoặc mạng phân phối nội dung (CDN) — không cần kiểm tra quyền khi truy cập. Bên trong tách thêm 2 loại: tài nguyên tĩnh có sẵn từ lúc xây dựng ứng dụng (hình ảnh giao diện, biểu tượng, mã nguồn giao diện đã biên dịch), và tệp do người dùng tải lên nhưng có chủ đích công khai (ví dụ hình ảnh mã QR cần nhúng vào email, ảnh đại diện công khai). Với loại thứ hai, vì không có kiểm tra quyền, an toàn phải dựa vào việc đặt tên tệp bằng chuỗi ngẫu nhiên đủ dài, không đoán được — không dùng số thứ tự tuần tự hay giữ nguyên tên gốc người dùng đặt.

- **Thư mục dữ liệu riêng tư:** tuyệt đối không được cấu hình cơ chế phục vụ tệp tĩnh tự động trỏ vào thư mục này. Mọi truy cập tới dữ liệu bên trong chỉ được thực hiện thông qua một đoạn mã do ứng dụng tự viết, có kiểm tra xác thực và phân quyền đầy đủ (đúng chủ sở hữu, đúng vai trò được phép xem) trước khi trả nội dung tệp về.

- **Thư mục dữ liệu tạm thời:** tách biệt hẳn khỏi cả 2 nhóm trên, vì có đặc điểm vòng đời hoàn toàn khác — dữ liệu ở đây sinh ra để phục vụ 1 lần dùng ngắn hạn (kết quả xuất báo cáo chờ tải xuống, tệp trung gian trong quá trình xử lý) rồi nên bị xoá đi, không phải dữ liệu nghiệp vụ cần giữ lâu dài. Mọi tệp trong thư mục này bắt buộc có thời gian sống giới hạn rõ ràng và có cơ chế tự động dọn dẹp định kỳ — không có tệp nào được phép tồn tại vô thời hạn ở đây. Nếu một dữ liệu tạm thời sau này được một bản ghi lâu dài khác tham chiếu tới (ví dụ 1 dòng dữ liệu trong cơ sở dữ liệu trỏ tới tệp này), bản chất của tệp đó đã không còn là "tạm thời" nữa và phải được chuyển sang thư mục dữ liệu riêng tư (hoặc công khai, tuỳ tính chất).

  Với dữ liệu tạm thời có vòng đời ngắn và không cần tồn tại qua việc khởi động lại ứng dụng (phiên xử lý nhập liệu tạm thời, mã xác thực dùng 1 lần), nên ưu tiên lưu trong bộ nhớ tiến trình (kèm cơ chế tự hết hạn) thay vì ghi ra tệp trên đĩa — cách này tránh được việc phải tự xây dựng cơ chế dọn dẹp tệp trên đĩa, và tự động biến mất khi tiến trình khởi động lại. **Cảnh báo quan trọng:** cách này chỉ đúng khi ứng dụng chạy trên 1 tiến trình duy nhất. Nếu dự án được thiết kế để chạy nhiều bản sao song song (multi-pod/Kubernetes), dữ liệu lưu trong bộ nhớ của pod này sẽ không nhìn thấy được từ pod khác — xem [`10-phase-init-new-project.md`](10-phase-init-new-project.md) mục 3 để chọn đúng chiến lược ngay từ đầu, tránh phải sửa lại toàn bộ khi mở rộng quy mô.

**Khi vận hành ở quy mô lớn hơn 1 máy chủ duy nhất (nhiều máy chủ chạy song song hoặc trên nền tảng điện toán đám mây không có ổ đĩa cố định):** dữ liệu công khai nên chuyển sang dịch vụ lưu trữ đối tượng của nhà cung cấp đám mây kết hợp mạng phân phối nội dung, với quyền đọc công khai được cấu hình ở chính dịch vụ lưu trữ đó. Dữ liệu riêng tư nên chuyển sang dịch vụ lưu trữ đối tượng riêng tư, và ứng dụng backend cấp phát đường dẫn truy cập có chữ ký kèm thời hạn ngắn (thay vì tự đóng vai trò trung gian truyền tải toàn bộ nội dung tệp qua chính máy chủ ứng dụng, gây tốn băng thông không cần thiết).

---

## 5. Tách 2 tầng cấu hình

Đúng nguyên tắc đã bàn ở phần bảo mật ([`02-security-baseline.md`](02-security-baseline.md) mục 4): tầng cấu hình hiếm khi đổi (được phép commit cùng mã nguồn, không chứa giá trị nhạy cảm thật) và tầng cấu hình hay đổi/nhạy cảm (không commit, nạp lúc chạy từ nguồn bên ngoài mã nguồn — biến môi trường, dịch vụ quản lý bí mật của nền tảng, hoặc tệp cấu hình được mount riêng).

Nên có duy nhất 1 module trong mã nguồn chịu trách nhiệm đọc cấu hình (dù nguồn là biến môi trường hay tệp cấu hình ngoài), cung cấp một cách truy xuất thống nhất cho toàn bộ ứng dụng — tránh việc mỗi nơi trong mã nguồn tự đọc biến môi trường trực tiếp theo cách khác nhau, gây khó kiểm soát khi cần đổi nguồn cấu hình sau này.

---

## Checklist nhanh — khi thiết lập hoặc rà soát cấu trúc thư mục

- [ ] Các tầng kỹ thuật có tách rõ ràng, hướng phụ thuộc chỉ chảy 1 chiều không?
- [ ] Đã đạt ngưỡng cần chuyển sang tổ chức theo module chưa, hay đang tổ chức theo module khi chưa thật sự cần?
- [ ] Dữ liệu công khai và riêng tư có tách thư mục rõ ràng ở cấp cao nhất không?
- [ ] Cơ chế phục vụ tệp tĩnh tự động có đang vô tình trỏ vào thư mục riêng tư không?
- [ ] Dữ liệu tạm thời có tách riêng khỏi dữ liệu nghiệp vụ lâu dài, có cơ chế tự dọn theo thời gian sống không?
- [ ] Cấu hình nhạy cảm có tách khỏi mã nguồn commit vào git không?

---

*Xem tiếp: [`05-database-rules.md`](05-database-rules.md) — quy tắc thiết kế và thao tác cơ sở dữ liệu.*
