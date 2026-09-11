---
name: xoan-backend-standard
description: >-
  Bộ quy chuẩn backend áp dụng cho MỌI ứng dụng Xoăn — không chỉ lúc khởi tạo dự án mà cho MỌI lần
  thêm/sửa code sau này (bug fix, feature nhỏ, refactor, maintenance). BẮT BUỘC dùng skill này khi
  viết/sửa code backend (API, service, database, xử lý lỗi, bảo mật, hiệu năng, devops) cho bất kỳ
  ứng dụng nào trong hệ sinh thái Xoăn — kể cả khi người dùng không nhắc đến "quy chuẩn" hay "backend
  skill". Trigger khi thấy: Xoăn, tạo endpoint/API mới, sửa logic database, thêm middleware, xử lý
  transaction, thiết kế lỗi/exception, chuẩn bị triển khai/deploy, viết test, tối ưu hiệu năng, bắt
  đầu dự án backend mới, refactor code cũ, hoặc bảo trì hệ thống đang chạy.
---

# Quy chuẩn Backend Xoăn

Bộ quy tắc backend áp dụng xuyên suốt vòng đời phát triển của MỌI ứng dụng trong hệ sinh thái Xoăn — tổng quát hoá cho nhiều ngôn ngữ/framework, mặc định đề xuất Node.js/Express/MySQL nếu dự án chưa chọn công nghệ cụ thể. Tổng hợp từ kinh nghiệm thực chiến kết hợp chuẩn thực hành phổ biến trong ngành (OWASP, thiết kế API REST, xử lý lỗi/giao dịch cơ sở dữ liệu).

Các nguyên tắc dưới đây không phải "gợi ý" — là **điều kiện bắt buộc** để 1 thay đổi code được coi là hoàn thành. Nếu 1 rule mâu thuẫn với yêu cầu tiện lợi/tốc độ tức thời, rule thắng — trừ khi chủ dự án xác nhận rõ ràng muốn đánh đổi.

## Chọn nhánh làm việc theo tình huống

**Tình huống 1 — Dự án hoàn toàn mới (chưa có dòng mã nào):**
1. Áp dụng "6 nguyên tắc nền tảng" bên dưới.
2. Đọc [references/10-phase-init-new-project.md](references/10-phase-init-new-project.md) — quy trình khởi tạo cụ thể.
3. Tham chiếu chéo các file chuyên đề khi cần (bảng bên dưới).
4. Đọc [references/13-devops-lifecycle.md](references/13-devops-lifecycle.md) — thiết lập CI/CD, code review, backup ngay từ đầu.
5. Đọc [references/20-memory-bank-mandate.md](references/20-memory-bank-mandate.md) + sao chép toàn bộ [references/21-memory-bank-template/](references/21-memory-bank-template/) vào thư mục `memory-bank/` của dự án mới, điền nội dung thật vào từng file mẫu.

**Tình huống 2 — Được giao vào 1 dự án cũ đã có sẵn:**
1. Áp dụng "6 nguyên tắc nền tảng", đặc biệt mục 3 (không tự bịa/suy diễn) — cực kỳ quan trọng khi tiếp cận mã nguồn người khác viết.
2. Đọc [references/11-phase-refactor-legacy.md](references/11-phase-refactor-legacy.md) — quy trình đọc hiểu, đánh giá, refactor có kỷ luật.
3. Đọc `memory-bank/` của dự án đó (nếu đã có) trước khi đọc mã nguồn — nếu chưa có, xem mục 6 của `11-phase-refactor-legacy.md` để bắt đầu dựng.
4. Tham chiếu file chuyên đề tương ứng với phần mã nguồn đang xử lý.

**Tình huống 3 — Thêm tính năng nhỏ/sửa lỗi ở dự án đang chạy (phổ biến nhất):**
1. Đọc [references/12-phase-maintenance.md](references/12-phase-maintenance.md) — quy trình tổng hợp.
2. Rà lại nhanh "6 nguyên tắc nền tảng" bên dưới.
3. File chuyên đề tương ứng lĩnh vực đang động vào (bảng bên dưới).
4. Kết thúc: rà checklist cuối `12-phase-maintenance.md`, đặc biệt bước cập nhật `memory-bank/` của chính dự án (không phải template ở đây).

## 6 nguyên tắc nền tảng (áp dụng MỌI lúc, MỌI tình huống)

**1. Thứ tự ưu tiên khi mục tiêu xung đột:** `Bảo mật > Chịu lỗi (hệ thống không sập) > Hiệu năng & tối ưu tài nguyên > Tiện lợi/tốc độ code`. Khi 1 giải pháp tối ưu hiệu năng làm giảm an toàn, hoặc 1 cách viết gọn hơn bỏ qua kiểm tra lỗi — không làm theo hướng đó, tìm giải pháp khác không đánh đổi thứ hạng cao hơn. Chỉ được nới lỏng khi chủ dự án đã được thông báo rõ đánh đổi cụ thể và xác nhận đồng ý.

**2. Sửa code đúng gốc rễ + phạm vi ảnh hưởng nhỏ nhất** — cả 2 tiêu chí đồng thời, không chọn 1: không vá tạm (band-aid) chỉ để hết hiện tượng bên ngoài; không sửa lan sang code không liên quan, không tiện tay refactor/dọn dẹp phần khác nếu không được yêu cầu. Khi 2 tiêu chí mâu thuẫn (giải pháp đúng nhất đòi sửa nhiều file/tầng): vẫn ưu tiên đúng gốc rễ, nhưng phải nói rõ phạm vi ảnh hưởng dự kiến cho chủ dự án trước khi thực hiện, chờ xác nhận — không tự ý mở rộng phạm vi âm thầm.

**3. Không tự bịa, không tự suy diễn — mọi thay đổi phải có nguồn xác thực:** yêu cầu trực tiếp của chủ dự án, bug tái hiện/chứng minh được, hoặc đọc code/tài liệu hiện có và trích dẫn cụ thể (file:dòng, endpoint, bảng DB...). Không suy đoán "chắc user muốn vậy" rồi code theo khi yêu cầu không rõ — hỏi lại thay vì đoán. Không bịa hành vi/API/tool/thư viện không có thật. Không kết luận "chắc là do..." mà chưa đọc code/log xác minh. Khi không chắc 1 chi tiết kỹ thuật → đi kiểm tra trực tiếp (đọc file, grep code, gọi thử) hoặc hỏi lại, không đoán rồi trình bày như chắc chắn.

**4. Luôn backtest logic sau khi code xong (mới hoặc sửa):** dò lại logic bằng tay qua từng nhánh, đặc biệt hàm nhiều nhánh trạng thái (sửa 1 nhánh phải verify lại TẤT CẢ các nhánh, không chỉ nhánh vừa sửa). Chạy thử thực tế (server local), thao tác qua API/UI với kịch bản chính + edge case. Nếu dự án có bộ test tự động — chạy lại toàn bộ, không chỉ test mới. Nếu thay đổi liên quan giao dịch nhiều người dùng cùng lúc (check-in, đặt chỗ, thanh toán) → backtest dưới tải đồng thời thật (script gọi song song N request), race condition không lộ ra khi test tuần tự. Nếu không có điều kiện test đầy đủ → nói rõ giới hạn đó, không khẳng định chắc chắn "đã hoạt động đúng" khi chưa kiểm chứng.

**5. Bảo mật là mặc định, không phải tính năng thêm sau:** không bỏ qua kiểm tra phân quyền để đổi lấy tốc độ/code gọn hơn. Không tin dữ liệu client gửi lên cho các trường có ý nghĩa phân quyền/nghiệp vụ quan trọng — server luôn tự tính toán lại. Escape/validate mọi dữ liệu user/DB trước khi nhúng vào ngữ cảnh khác (HTML, SQL, shell command...). Chi tiết đầy đủ ở [references/02-security-baseline.md](references/02-security-baseline.md).

**6. Module hoá là mặc định, không đợi "đủ lớn mới tách":** 1 hàm/method nên chỉ có 1 trách nhiệm rõ ràng, input/output rõ ràng qua tham số/return, tránh phụ thuộc ẩn vào biến toàn cục. Logic được đánh giá dùng lại được ở nơi khác → tách ngay vào thư mục dùng chung (`common`/`shared`/`lib`) ngay khi dùng tới **lần thứ 2**, không đợi "đủ lớn mới tách". Khi tách: tách cơ học trước (giữ nguyên hành vi 100%), tối ưu/cải tiến sau nếu cần — không gộp 2 việc "tách module" và "sửa logic" trong cùng 1 lần thay đổi.

Ví dụ minh hoạ đầy đủ (code trước/sau) cho cả 6 nguyên tắc: [references/01-core-principles.md](references/01-core-principles.md) — đọc khi cần dẫn chứng cụ thể để giải thích cho chủ dự án hoặc khi phân vân 1 tình huống biên.

## Tra cứu theo lĩnh vực đang động vào

| Đang làm gì | Đọc file |
|---|---|
| Auth/authz, chống injection, secrets, IDOR, SSRF, audit log, supply-chain | [references/02-security-baseline.md](references/02-security-baseline.md) |
| Xử lý lỗi, log, khả năng chịu lỗi | [references/03-error-handling-resilience.md](references/03-error-handling-resilience.md) |
| Cấu trúc thư mục mã nguồn + dữ liệu (public/private/temp) | [references/04-project-structure.md](references/04-project-structure.md) |
| Thiết kế/thao tác cơ sở dữ liệu, transaction, khoá dòng | [references/05-database-rules.md](references/05-database-rules.md) |
| Thiết kế API, hình dạng response | [references/06-api-design.md](references/06-api-design.md) |
| Chiến lược kiểm thử | [references/07-testing-strategy.md](references/07-testing-strategy.md) |
| Hiệu năng: cache, indexing, phân trang, hàng đợi, giới hạn payload | [references/08-performance-scaling.md](references/08-performance-scaling.md) |
| Vận hành: health-check, graceful shutdown, fail-fast config, observability, DI | [references/09-operations-reliability.md](references/09-operations-reliability.md) |
| Khởi tạo dự án mới | [references/10-phase-init-new-project.md](references/10-phase-init-new-project.md) |
| Refactor dự án cũ | [references/11-phase-refactor-legacy.md](references/11-phase-refactor-legacy.md) |
| Thêm tính năng nhỏ/sửa lỗi ở dự án đang chạy | [references/12-phase-maintenance.md](references/12-phase-maintenance.md) |
| CI/CD, code review, rollback, backup/DR, ứng phó sự cố | [references/13-devops-lifecycle.md](references/13-devops-lifecycle.md) |
| Quy định bắt buộc về tài liệu tri thức dự án (`memory-bank/`) | [references/20-memory-bank-mandate.md](references/20-memory-bank-mandate.md) + [references/21-memory-bank-template/](references/21-memory-bank-template/) |

## Checklist nhanh — áp dụng cho mọi lần code

- [ ] Có đánh đổi bảo mật/chịu lỗi lấy tốc độ/tiện lợi ở đâu không? Nếu có, đã hỏi ý kiến chủ dự án chưa?
- [ ] Giải pháp có đúng gốc rễ, và phạm vi sửa có ở mức nhỏ nhất cần thiết không?
- [ ] Lý do thực hiện thay đổi này có nguồn xác thực rõ ràng, hay đang tự suy diễn?
- [ ] Đã backtest lại logic (thủ công hoặc chạy thử thật), kể cả các nhánh edge case?
- [ ] Logic mới có tách thành method/hàm rõ trách nhiệm, tránh nhồi hết vào 1 chỗ không?
- [ ] Có phần nào dùng lại được ở nơi khác (lần thứ 2 trở lên) mà nên tách vào thư mục dùng chung ngay không?
- [ ] Nếu không chắc 1 chi tiết kỹ thuật — đã đi xác minh trực tiếp, hay đang giả định?

## Nguyên tắc tổng quát khi dùng skill này

- Nội dung `references/` viết bằng tiếng Việt, kèm ví dụ code/pseudocode ở mục có logic phức tạp dễ hiểu sai — các đoạn này là mã giả/minh hoạ, cần điều chỉnh đúng cú pháp theo ngôn ngữ/framework thực tế của project, không phải chép nguyên văn.
- Không coi đây là tài liệu đọc 1 lần rồi thôi — quay lại tra cứu mỗi khi cần, đặc biệt trước khi báo cáo 1 nhiệm vụ là "đã hoàn thành".
- Nếu 1 dự án cụ thể có quy tắc riêng bổ sung ngoài bộ tổng quát này, quy tắc riêng đó thuộc về `memory-bank/11-coding-rules.md` của chính dự án đó, **không sửa vào skill này** — skill này là quy chuẩn chung dùng chung cho mọi ứng dụng Xoăn.
