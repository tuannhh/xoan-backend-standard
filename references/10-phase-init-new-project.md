# 10 — Khởi tạo dự án mới (Phase: Init New Project)

> Áp dụng khi bắt đầu 1 dự án backend hoàn toàn từ đầu, chưa có dòng mã nào. Toàn bộ nguyên tắc ở nhóm file 01-09 vẫn áp dụng song song — file này chỉ bổ sung các bước và quyết định riêng có ở giai đoạn khởi tạo.

---

## 1. Xác định lựa chọn công nghệ trước khi viết dòng mã đầu tiên

Nếu người yêu cầu đã chỉ định rõ ngôn ngữ/framework/hệ quản trị cơ sở dữ liệu muốn dùng, tuân theo lựa chọn đó — không tự ý đổi sang lựa chọn khác dù bản thân cho rằng lựa chọn khác tốt hơn, trừ khi đã trao đổi và được xác nhận.

**Nếu người yêu cầu chưa chỉ định công nghệ cụ thể, mặc định đề xuất bộ công nghệ sau** (đã được kiểm chứng qua thực chiến, phù hợp phần lớn nhu cầu backend thông thường ở quy mô nhỏ và vừa):
- Ngôn ngữ/nền tảng chạy: Node.js phiên bản hỗ trợ dài hạn (LTS) mới nhất.
- Framework xử lý HTTP: Express (phiên bản ổn định mới nhất).
- Hệ quản trị cơ sở dữ liệu: MySQL (phiên bản 8.0 trở lên).
- Giao diện người dùng (nếu dự án có phần frontend đi kèm và không có yêu cầu đặc biệt về tương tác phức tạp): HTML/CSS/JavaScript thuần, không bắt buộc framework frontend phức tạp nếu nhu cầu giao diện đơn giản — chỉ cân nhắc framework frontend khi độ phức tạp giao diện thực sự cần tới (nhiều trạng thái tương tác phức tạp, cần quản lý state phức tạp).

Lý do đề xuất bộ công nghệ này làm mặc định: được kiểm chứng qua vận hành thực tế, hệ sinh thái thư viện phong phú giải quyết được phần lớn nhu cầu backend thông thường, và không đòi hỏi bước biên dịch phức tạp giúp rút ngắn thời gian từ viết mã tới chạy thử.

**Vẫn phải hỏi rõ trước khi quyết định thay vì tự ý áp mặc định** trong các trường hợp: dự án có yêu cầu đặc biệt về hiệu năng cực cao mà nền tảng mặc định khó đáp ứng, dự án cần tích hợp sâu với hệ sinh thái đã có sẵn của người yêu cầu (ví dụ toàn bộ hạ tầng công ty đã chuẩn hoá theo 1 nền tảng khác), hoặc người yêu cầu có kinh nghiệm/sở thích riêng với 1 công nghệ cụ thể.

## 2. Thứ tự các bước khởi tạo

1. **Xác nhận công nghệ** theo mục 1 ở trên.
2. **Dựng cấu trúc thư mục** theo [`04-project-structure.md`](04-project-structure.md) — bắt đầu với cấu trúc layer-based mặc định, không tổ chức theo module ngay từ đầu trừ khi đã biết chắc quy mô dự án sẽ lớn ngay từ ban đầu.
3. **Thiết lập 2 tầng cấu hình** (hiếm đổi/commit được, và hay đổi/nhạy cảm không commit) theo [`04-project-structure.md`](04-project-structure.md) mục 5 và [`02-security-baseline.md`](02-security-baseline.md) mục 4 — thiết lập đúng ngay từ đầu, tránh phải tách lại sau khi đã lỡ commit giá trị nhạy cảm vào lịch sử mã nguồn.
4. **Dựng khung xác thực và phân quyền cơ bản** trước khi viết bất kỳ nghiệp vụ nào khác — vì hầu hết mọi endpoint nghiệp vụ sau này đều cần dựa vào khung này, dựng sau sẽ phải quay lại sửa nhiều endpoint đã viết.
5. **Thiết lập lược đồ cơ sở dữ liệu ban đầu và cơ chế migration** theo [`05-database-rules.md`](05-database-rules.md) — kể cả khi mới chỉ có 1-2 bảng, thiết lập cơ chế migration ngay từ đầu để mọi thay đổi cấu trúc dữ liệu sau này đều theo cùng 1 quy trình nhất quán.
6. **Dựng khung kiểm thử** theo [`07-testing-strategy.md`](07-testing-strategy.md) — kể cả khi chưa có nhiều để kiểm thử, chuẩn bị sẵn cách chạy kiểm thử tự động và môi trường dữ liệu kiểm thử riêng biệt.
7. **Khởi tạo bộ tài liệu tri thức dự án (memory-bank)** theo [`20-memory-bank-mandate.md`](20-memory-bank-mandate.md) — dựng cấu trúc thư mục/tệp memory-bank ngay từ ngày đầu tiên, dù nội dung ban đầu còn sơ khai, để việc cập nhật tài liệu trở thành thói quen ngay từ lúc bắt đầu thay vì phải xây dựng lại từ số 0 khi dự án đã lớn.
8. **Viết tính năng nghiệp vụ đầu tiên**, áp dụng đầy đủ mọi nguyên tắc ở nhóm file 01-09, và cập nhật memory-bank song song ngay khi tính năng đó hoàn thành.

## 3. Những quyết định cần chốt sớm, khó đổi về sau

**Khi bắt đầu khởi tạo dự án, AI phải CHỦ ĐỘNG hỏi người phụ trách dự án về từng quyết định dưới đây — không đợi người dùng tự nhớ ra, không âm thầm chọn mặc định mà không thông báo.** Mỗi quyết định đều có chi phí thay đổi rất cao nếu để tới lúc dự án đã phát triển mới nhận ra cần đổi:

- **Cơ chế xác thực chính** (dựa trên phiên làm việc lưu phía server, hay dựa trên token không trạng thái) — ảnh hưởng tới toàn bộ cách thiết kế endpoint xác thực và cách frontend/client tương tác.
- **Chiến lược cách ly dữ liệu theo tổ chức/đơn vị** (nếu dự án phục vụ nhiều tổ chức độc lập dùng chung 1 hệ thống) — nên xác định ngay từ đầu cột/khoá phân biệt tổ chức trong lược đồ dữ liệu, đổi sau khi đã có nhiều bảng dữ liệu sẽ rất tốn công.
- **Chiến lược lưu trữ tệp** (lưu trên đĩa cục bộ máy chủ, hay dùng dịch vụ lưu trữ đối tượng của nền tảng đám mây ngay từ đầu) — nếu dự đoán trước sẽ vận hành trên nền tảng không có ổ đĩa cố định (điện toán đám mây dạng không trạng thái) hoặc sẽ mở rộng ra nhiều máy chủ, nên thiết kế tầng truy cập lưu trữ tệp theo hướng trừu tượng hoá ngay từ đầu (dễ đổi nơi lưu trữ thật phía sau mà không phải sửa lại toàn bộ nơi gọi).
- **Thiết kế sẵn sàng cho môi trường nhiều bản sao (multi-pod/cụm — Kubernetes hoặc tương tự):** Đây là 1 lựa chọn cần hỏi rõ người phụ trách dự án ngay từ đầu, không tự quyết định ngầm. Nếu dự án dự kiến sẽ triển khai trên nền tảng điều phối container với nhiều bản sao chạy song song (multi-pod), toàn bộ thiết kế từ đầu phải tuân theo nguyên tắc "không có trạng thái gắn cứng vào 1 tiến trình" (stateless). Cụ thể: mọi dữ liệu phiên làm việc người dùng không được lưu trong bộ nhớ tiến trình đơn lẻ mà phải qua kho lưu trữ chia sẻ (cơ sở dữ liệu, khoá-giá trị mạng như Redis); mọi tệp tải lên không được lưu trên ổ đĩa cục bộ của 1 pod riêng lẻ mà phải qua dịch vụ lưu trữ đối tượng dùng chung; mọi tác vụ nền/lập lịch định kỳ phải tính tới trường hợp nhiều bản sao cùng chạy đồng thời (cần cơ chế khoá/phân phối để không xử lý trùng); và phải có endpoint kiểm tra sức khoẻ cho hệ thống điều phối (đã nêu ở [`09-operations-reliability.md`](09-operations-reliability.md) mục 1). Nếu dự án chưa có kế hoạch multi-pod ngay từ đầu, có thể thiết kế đơn giản hơn (trạng thái trong bộ nhớ tiến trình, tệp trên đĩa cục bộ) — nhưng nên ghi chú rõ những chỗ đang phụ thuộc vào 1 tiến trình đơn lẻ để sau này dễ định vị khi cần nâng cấp lên multi-pod.

## 4. Không tự ý xây dựng tính năng vượt quá nhu cầu ban đầu

Khi khởi tạo dự án mới, dễ có xu hướng dựng sẵn nhiều thứ "phòng khi cần sau này" (nhiều lớp trừu tượng chưa có nhu cầu thật, cấu trúc thư mục phức tạp cho quy mô lớn dù dự án mới ở giai đoạn khởi đầu nhỏ). Điều này vi phạm nguyên tắc "phạm vi ảnh hưởng nhỏ nhất" đã nêu ở [`01-core-principles.md`](01-core-principles.md) mục 2 — chỉ dựng đúng mức cần thiết cho nhu cầu đã biết rõ, để lại các quyết định mở rộng cho khi thực sự có nhu cầu, tránh độ phức tạp không cần thiết cản trở việc hiểu và bảo trì dự án ngay từ giai đoạn đầu.

---

## Checklist nhanh — trước khi coi bước khởi tạo dự án là hoàn thành

- [ ] Công nghệ sử dụng đã được xác nhận rõ ràng (theo yêu cầu cụ thể, hoặc theo mặc định đã đề xuất) chưa?
- [ ] Cấu trúc thư mục, 2 tầng cấu hình, khung xác thực/phân quyền cơ bản đã dựng xong trước khi viết nghiệp vụ đầu tiên chưa?
- [ ] Cơ chế migration cơ sở dữ liệu đã thiết lập ngay từ đầu chưa?
- [ ] Bộ tài liệu tri thức dự án (memory-bank) đã được khởi tạo ngay từ ngày đầu tiên chưa?
- [ ] Có đang dựng sẵn cấu trúc/tính năng vượt quá nhu cầu đã biết rõ ở giai đoạn này không?

---

*Xem tiếp: [`11-phase-refactor-legacy.md`](11-phase-refactor-legacy.md) — quy tắc khi làm việc với dự án cũ có sẵn.*
