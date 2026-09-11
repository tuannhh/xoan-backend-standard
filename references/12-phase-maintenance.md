# 12 — Duy trì và phát triển thường xuyên (Phase: Maintenance)

> Giai đoạn áp dụng thường xuyên nhất trong vòng đời dự án — mọi lần thêm tính năng nhỏ, sửa lỗi, hoặc điều chỉnh nghiệp vụ sau khi dự án đã qua giai đoạn khởi tạo/refactor ban đầu. Đây là bản tổng hợp thao tác của toàn bộ nhóm file 01-07, trình bày dưới dạng quy trình làm việc lặp lại mỗi lần động vào mã nguồn.

---

## 1. Trước khi bắt đầu — xác định lý do và phạm vi

Theo đúng nguyên tắc "không tự bịa, không tự suy diễn" ở [`01-core-principles.md`](01-core-principles.md) mục 3: xác định rõ lý do thực hiện thay đổi này dựa trên yêu cầu trực tiếp, lỗi có thể chứng minh được, hoặc bằng chứng đọc trực tiếp từ mã nguồn/tài liệu. Nếu yêu cầu chưa đủ rõ ràng để xác định phạm vi cụ thể, làm rõ trước khi bắt đầu viết mã, không tự đoán ý định rồi triển khai.

Xác định trước phạm vi ảnh hưởng dự kiến của thay đổi — nếu giải pháp đúng đắn nhất đòi hỏi ảnh hưởng tới nhiều tệp/nhiều tầng hơn dự kiến ban đầu, thông báo rõ phạm vi mở rộng đó cho người phụ trách dự án trước khi tiếp tục, theo đúng nguyên tắc ở [`01-core-principles.md`](01-core-principles.md) mục 2.

## 2. Trong lúc viết mã — áp dụng đồng thời mọi nguyên tắc nền tảng

Không có nguyên tắc nào ở nhóm file 01-07 chỉ áp dụng "khi cần" — toàn bộ áp dụng mặc định cho mọi lần động vào mã nguồn, bất kể quy mô thay đổi lớn hay nhỏ:

- Kiểm tra phân quyền/xác thực đầy đủ ở mọi endpoint mới hoặc sửa đổi ([`02-security-baseline.md`](02-security-baseline.md)).
- Xử lý lỗi đúng cách cho vòng lặp/lệnh gọi bên ngoài, đặt log đúng chỗ ([`03-error-handling-resilience.md`](03-error-handling-resilience.md)).
- Đặt mã nguồn mới vào đúng vị trí theo cấu trúc thư mục đã thiết lập, tách logic dùng chung khi cần ([`04-project-structure.md`](04-project-structure.md), và nguyên tắc module hoá ở [`01-core-principles.md`](01-core-principles.md) mục 6).
- Tuân theo quy tắc dữ liệu khi thay đổi liên quan cơ sở dữ liệu ([`05-database-rules.md`](05-database-rules.md)).
- Tuân theo quy ước thiết kế API khi thêm/sửa endpoint ([`06-api-design.md`](06-api-design.md)).

## 3. Sau khi viết mã xong — không coi là hoàn thành nếu thiếu 1 trong các bước sau

**Backtest đầy đủ:** dò lại logic qua từng nhánh, chạy thử thực tế với kịch bản chính và kịch bản biên liên quan tới thay đổi, theo [`01-core-principles.md`](01-core-principles.md) mục 4.

**Viết/cập nhật kiểm thử tương ứng:** tính năng mới phải có kiểm thử mới, nghiệp vụ thay đổi phải cập nhật kiểm thử cũ cho khớp, và chạy lại toàn bộ bộ kiểm thử để xác nhận không phá vỡ hành vi khác — theo [`07-testing-strategy.md`](07-testing-strategy.md).

**Cập nhật tài liệu tri thức dự án (memory-bank) ngay trong cùng lượt làm việc:** đây không phải việc phụ làm sau, mà là 1 phần bắt buộc để coi 1 thay đổi mã nguồn là hoàn thành — chi tiết đầy đủ ở [`20-memory-bank-mandate.md`](20-memory-bank-mandate.md). Nếu thay đổi ảnh hưởng cấu trúc dữ liệu, phải cập nhật cả tệp migration tương ứng, không chỉ cập nhật tài liệu mô tả.

**Tự rà lại checklist của từng nhóm nguyên tắc liên quan tới thay đổi vừa thực hiện** (không cần rà toàn bộ mọi checklist của mọi file nếu thay đổi không liên quan tới lĩnh vực đó — ví dụ thay đổi không đụng tới cơ sở dữ liệu thì không cần rà checklist ở [`05-database-rules.md`](05-database-rules.md), nhưng phải tự xác định rõ ràng thay đổi này có thực sự không liên quan hay không, không mặc định bỏ qua).

## 4. Khi phát hiện vấn đề ngoài phạm vi nhiệm vụ đang làm

Trong lúc thực hiện 1 nhiệm vụ cụ thể, nếu phát hiện thêm vấn đề khác không thuộc phạm vi được giao (một lỗ hổng bảo mật, một đoạn mã có nguy cơ lỗi race condition, một chỗ tài liệu lệch pha với mã nguồn) — không tự ý mở rộng phạm vi để sửa luôn, cũng không im lặng bỏ qua. Cách xử lý đúng: báo cáo rõ phát hiện đó cho người phụ trách dự án, để họ quyết định có muốn xử lý ngay trong lượt này (mở rộng phạm vi có chủ đích, đã được xác nhận) hay xử lý ở 1 lượt riêng sau.

## 5. Khi được hỏi "đã xong/đã bao quát hết chưa"

Không trả lời theo quán tính rằng "đã xong" nếu chưa thực sự xác minh lại bằng cách đọc/đối chiếu thật (đếm số lượng endpoint thật so với tài liệu, kiểm tra thật có bao nhiêu trường hợp đã có kiểm thử so với tổng số cần có). Việc trả lời không chính xác ở câu hỏi dạng này, dù vô tình, có thể khiến người phụ trách dự án tin tưởng nhầm vào một mức độ hoàn thiện không có thật — kể cả khi việc kiểm chứng thật phát hiện ra vấn đề nằm ngoài phạm vi nhiệm vụ ban đầu, vẫn phải báo cáo trung thực.

---

## Checklist tổng hợp — trước khi báo cáo 1 nhiệm vụ duy trì/phát triển là hoàn thành

- [ ] Lý do thực hiện thay đổi có nguồn xác thực rõ ràng, không phải tự suy diễn?
- [ ] Có đánh đổi bảo mật/chịu lỗi lấy tốc độ/tiện lợi ở đâu không — nếu có, đã xác nhận với người phụ trách dự án chưa?
- [ ] Giải pháp có đúng gốc rễ và phạm vi ảnh hưởng ở mức nhỏ nhất cần thiết không?
- [ ] Đã backtest lại logic, kể cả các nhánh biên liên quan tới thay đổi?
- [ ] Đã viết/cập nhật kiểm thử tương ứng và chạy lại toàn bộ bộ kiểm thử, tất cả đều qua?
- [ ] Đã cập nhật đầy đủ tài liệu tri thức dự án (memory-bank) liên quan tới thay đổi này, trong cùng lượt làm việc?
- [ ] Nếu phát hiện vấn đề ngoài phạm vi nhiệm vụ, đã báo cáo thay vì tự ý mở rộng hoặc im lặng bỏ qua?
- [ ] Câu trả lời về mức độ hoàn thành có dựa trên xác minh thật, không phải trả lời theo quán tính?

---

*Xem tiếp: [`13-devops-lifecycle.md`](13-devops-lifecycle.md) — vòng đời vận hành phần mềm (CI/CD, code review, rollback, backup, ứng phó sự cố).*
