# 11 — Refactor dự án cũ có sẵn (Phase: Refactor Legacy Project)

> Áp dụng khi được giao làm việc với 1 dự án backend đã tồn tại, có thể đã có lịch sử phát triển lâu dài, có thể chưa có tài liệu tri thức đầy đủ. Toàn bộ nguyên tắc ở nhóm file 01-07 vẫn áp dụng song song — file này bổ sung quy trình riêng khi bắt tay vào 1 mã nguồn không phải do mình viết ra từ đầu.

---

## 1. Đọc hiểu trước khi sửa bất kỳ điều gì

**Không được sửa code khi chưa hiểu rõ vì sao code hiện tại được viết như vậy.** Một đoạn mã nhìn có vẻ kỳ lạ hoặc dư thừa ở góc nhìn ban đầu rất có thể đang xử lý một trường hợp biên hoặc một bài học từ sự cố thực tế đã từng xảy ra — xoá bỏ hoặc sửa đổi mà không hiểu rõ có thể vô tình làm sống lại đúng lỗi đã từng được fix.

Trước khi thực hiện bất kỳ thay đổi nào trên dự án cũ, cần đọc qua theo thứ tự: tài liệu tổng quan kiến trúc nếu có, tài liệu tri thức dự án (memory-bank) nếu đã tồn tại, và đọc trực tiếp mã nguồn ở khu vực liên quan tới nhiệm vụ được giao. Nếu dự án cũ chưa có bất kỳ tài liệu nào, cần tự đọc mã nguồn kỹ hơn để tự xây dựng hiểu biết trước khi động vào.

## 2. Kiểm tra tài liệu có khớp với mã nguồn thật hay không — không tin tài liệu mù quáng

Tài liệu cũ (nếu có) có thể đã lệch pha với mã nguồn thật theo thời gian, do việc cập nhật tài liệu bị bỏ sót ở một số lần thay đổi trước đó. Bất kỳ khẳng định nào trong tài liệu cũ liên quan trực tiếp tới nhiệm vụ đang làm đều nên được đối chiếu lại với mã nguồn thật trước khi tin tưởng hoàn toàn — đặc biệt các khẳng định về hành vi bảo mật/phân quyền, vì đây là nơi lệch pha tài liệu có hậu quả nghiêm trọng nhất nếu tin nhầm.

Nếu phát hiện tài liệu cũ không khớp với mã nguồn thật, không tự ý sửa mã nguồn theo tài liệu cũ (vì có thể tài liệu mới là phần lỗi thời, không phải mã nguồn sai) — cần xác minh xem đâu là hành vi đúng thực tế đang mong muốn (thông qua việc hỏi người yêu cầu, hoặc dựa vào bằng chứng khác như lịch sử thay đổi mã nguồn), rồi cập nhật lại bên còn sai (tài liệu hoặc mã nguồn) cho khớp với ý định thật.

## 3. Đánh giá khoảng cách (gap) giữa hiện trạng và bộ quy tắc này

Khi lần đầu tiếp nhận 1 dự án cũ để áp dụng bộ quy tắc này, cần thực hiện một lượt đánh giá tổng thể xem hiện trạng dự án đang thiếu/lệch những gì so với các nguyên tắc đã nêu ở nhóm file 01-07 (bảo mật, xử lý lỗi, cấu trúc thư mục, quy tắc dữ liệu, thiết kế API, kiểm thử). Kết quả đánh giá nên được trình bày rõ ràng cho người phụ trách dự án biết, không tự ý sửa hàng loạt ngay khi phát hiện — vì sửa hàng loạt vi phạm nguyên tắc "phạm vi ảnh hưởng nhỏ nhất" và có thể phá vỡ hành vi đang vận hành ổn định mà không ai yêu cầu thay đổi.

Đặc biệt lưu ý phát hiện các rủi ro bảo mật đang tồn tại (dù không nằm trong phạm vi nhiệm vụ được giao ban đầu) — nếu phát hiện, phải báo ngay cho người phụ trách dự án biết, không im lặng bỏ qua chỉ vì "không phải việc mình đang làm".

## 4. Tách cơ học trước — tối ưu/sửa logic sau, không gộp chung 1 lần thay đổi

Khi cần tổ chức lại cấu trúc mã nguồn cũ (di chuyển tệp vào đúng vai trò layer, tách logic dùng chung ra thư mục riêng), thực hiện theo 2 bước tách biệt hoàn toàn:

1. **Bước tách cơ học:** di chuyển mã nguồn tới vị trí mới, giữ nguyên 100% hành vi hiện có — không sửa bất kỳ logic nào trong bước này, kể cả khi nhìn thấy cơ hội cải thiện rõ ràng.
2. **Bước tối ưu/cải tiến (nếu cần):** thực hiện sau, ở 1 lần thay đổi riêng biệt, sau khi bước 1 đã được xác nhận không phá vỡ hành vi cũ (đã backtest theo [`01-core-principles.md`](01-core-principles.md) mục 4).

Gộp chung 2 việc "tổ chức lại mã nguồn" và "sửa logic" trong cùng 1 lần thay đổi khiến việc xem xét lại (review) trở nên khó khăn (không phân biệt được thay đổi nào chỉ là di chuyển vị trí, thay đổi nào thực sự đổi hành vi), và khó rollback nếu phát hiện có lỗi phát sinh sau đó.

## 5. Không đổi hành vi ngoài phạm vi được yêu cầu

Khi refactor, mục tiêu là cải thiện cách tổ chức/chất lượng mã nguồn mà **không làm thay đổi hành vi quan sát được từ bên ngoài** (trừ khi thay đổi hành vi chính là mục tiêu được yêu cầu). Nếu trong quá trình refactor phát hiện một hành vi hiện tại có vẻ là lỗi hoặc chưa tối ưu, không tự ý sửa luôn trong cùng lần refactor — ghi nhận lại phát hiện đó, báo cho người phụ trách dự án, và xử lý ở một thay đđổi riêng sau khi được xác nhận đây thực sự là điều cần sửa (có thể hành vi đó là chủ đích, chỉ là chưa được ghi tài liệu rõ).

## 6. Dựng bộ tài liệu tri thức dự án (memory-bank) cho dự án chưa có

Nếu dự án cũ chưa có bộ tài liệu tri thức theo đúng chuẩn ở [`20-memory-bank-mandate.md`](20-memory-bank-mandate.md), cần dựng ngay khi bắt đầu làm việc lâu dài với dự án đó — không đợi tới khi dự án "đủ ổn định" mới bắt đầu ghi tài liệu. Nội dung ban đầu của bộ tài liệu nên được xây dựng dựa trên việc đọc hiểu mã nguồn hiện có (không suy đoán), phản ánh đúng hiện trạng thật của dự án tại thời điểm bắt đầu, kể cả những phần chưa hoàn thiện hoặc có vấn đề đã biết.

## 7. Bổ sung kiểm thử cho phần mã nguồn chưa có kiểm thử, ưu tiên theo rủi ro

Dự án cũ có thể có nhiều phần chưa được kiểm thử tự động. Không cần viết kiểm thử phủ toàn bộ mã nguồn cũ ngay lập tức trong 1 lần (khối lượng công việc quá lớn, không tương xứng với phạm vi nhiệm vụ thông thường) — nhưng bất kỳ phần mã nguồn nào bị chạm tới trong lúc thực hiện nhiệm vụ hiện tại (sửa lỗi, thêm tính năng liên quan) đều nên được bổ sung kiểm thử cho phần đó, theo đúng nguyên tắc ở [`07-testing-strategy.md`](07-testing-strategy.md).

Khi cần ưu tiên, nên tập trung bổ sung kiểm thử trước cho các phần có rủi ro cao nhất nếu xảy ra lỗi (luồng liên quan bảo mật/phân quyền, luồng xử lý giao dịch/dữ liệu tài chính, luồng có khả năng bị nhiều người dùng thao tác đồng thời).

---

## Checklist nhanh — trước khi coi 1 lần refactor là hoàn thành

- [ ] Đã đọc hiểu rõ lý do đoạn mã hiện tại được viết như vậy trước khi sửa, chưa phải chỉ dựa vào cảm giác "có vẻ dư thừa/kỳ lạ"?
- [ ] Tài liệu cũ (nếu có) có được đối chiếu lại với mã nguồn thật trước khi tin tưởng không?
- [ ] Đã có đánh giá khoảng cách tổng thể và báo cáo cho người phụ trách dự án trước khi sửa hàng loạt không?
- [ ] Việc tổ chức lại mã nguồn có tách riêng khỏi việc sửa logic (không gộp chung 1 lần thay đổi) không?
- [ ] Có phát hiện hành vi nào cần sửa nhưng ngoài phạm vi yêu cầu — đã báo cáo thay vì tự ý sửa luôn không?
- [ ] Nếu dự án chưa có bộ tài liệu tri thức, đã bắt đầu dựng ngay khi tiếp nhận công việc chưa?

---

*Xem tiếp: [`12-phase-maintenance.md`](12-phase-maintenance.md) — quy tắc duy trì và phát triển thường xuyên.*
