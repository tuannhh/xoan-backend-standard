# 13 — Vòng đời vận hành phần mềm (DevOps Lifecycle)

> Bổ sung cho nhóm quy trình theo giai đoạn ([`10`](10-phase-init-new-project.md), [`11`](11-phase-refactor-legacy.md), [`12`](12-phase-maintenance.md)) — file này tập trung vào các quy trình xoay quanh việc đưa mã nguồn từ máy phát triển ra môi trường thật và duy trì nó vận hành ổn định lâu dài, không phải bản thân logic nghiệp vụ. Áp dụng ở mức nguyên tắc chung, điều chỉnh chi tiết theo công cụ/nền tảng cụ thể mà từng dự án đang dùng.

---

## 1. Tích hợp và triển khai liên tục (CI/CD)

**Tích hợp liên tục (Continuous Integration):** mỗi khi có thay đổi mã nguồn được đề xuất, nên có một quy trình tự động chạy để xác minh chất lượng cơ bản trước khi thay đổi đó được chấp nhận hợp nhất vào nhánh chính — tối thiểu gồm: chạy toàn bộ bộ kiểm thử tự động ([`07-testing-strategy.md`](07-testing-strategy.md)), kiểm tra mã nguồn biên dịch/parse được không có lỗi cú pháp, và các bước kiểm tra chất lượng mã nguồn khác nếu dự án có áp dụng (kiểm tra định dạng, kiểm tra quy tắc viết mã). Không hợp nhất thay đổi vào nhánh chính khi quy trình này thất bại — đây là cổng chặn bắt buộc, không phải bước tham khảo.

**Triển khai liên tục (Continuous Deployment/Delivery):** quy trình đưa mã nguồn đã được xác minh từ nhánh chính ra môi trường vận hành thật, nên được tự động hoá càng nhiều càng tốt để giảm sai sót do thao tác thủ công lặp lại nhiều lần. Mức độ tự động hoá đầy đủ (tự động triển khai ngay khi hợp nhất vào nhánh chính) hay bán tự động (tự động chuẩn bị sẵn sàng nhưng cần một bước xác nhận thủ công trước khi thực sự đưa ra môi trường thật) tuỳ thuộc mức độ rủi ro chấp nhận được của từng dự án — với thay đổi có khả năng ảnh hưởng lớn hoặc khó hoàn tác, nên có bước xác nhận thủ công trước khi triển khai lên môi trường quan trọng nhất.

**Không bỏ qua các bước kiểm tra của quy trình CI/CD để triển khai gấp**, trừ khi đây là tình huống khẩn cấp thực sự (sự cố nghiêm trọng đang ảnh hưởng người dùng thật) và đã được người có thẩm quyền quyết định chấp nhận rủi ro đó một cách có ý thức — không âm thầm bỏ qua bước kiểm tra chỉ vì muốn nhanh.

## 2. Quy trình xem xét lại mã nguồn (Code Review)

Thay đổi mã nguồn quan trọng (đặc biệt liên quan bảo mật, thay đổi cấu trúc dữ liệu, hoặc ảnh hưởng luồng nghiệp vụ cốt lõi) nên được một người khác (hoặc một quy trình xem xét có cấu trúc) xem lại trước khi được chấp nhận, không chỉ dựa vào việc chính người viết ra tự xác nhận là đúng — góc nhìn độc lập của người khác thường phát hiện được những giả định ẩn hoặc trường hợp biên mà chính người viết mã nguồn (do đã quá quen thuộc với logic của mình) dễ bỏ sót.

**Những điều nên được chú trọng khi xem xét lại mã nguồn:** thay đổi có tuân theo các nguyên tắc đã nêu trong toàn bộ bộ quy tắc này không (đặc biệt bảo mật và xử lý lỗi), phạm vi thay đổi có ở mức cần thiết hay đang lan rộng không cần thiết, có kiểm thử tương ứng đầy đủ chưa, và tài liệu tri thức dự án đã được cập nhật cùng lượt chưa (theo [`20-memory-bank-mandate.md`](20-memory-bank-mandate.md)).

Khi làm việc với 1 dự án cỡ nhỏ chỉ có 1 người phụ trách kỹ thuật duy nhất (không có ai khác để xem xét lại), nguyên tắc "góc nhìn độc lập" vẫn có thể áp dụng bằng cách tự chủ động xem xét lại thay đổi của chính mình sau một khoảng thời gian tạm nghỉ (không xem xét lại ngay lập tức khi vừa viết xong, dễ bị chính tư duy vừa dùng để viết mã che khuất lỗi sai) — hoặc nhờ một AI khác/công cụ khác đóng vai trò người xem xét độc lập.

## 3. Chiến lược triển khai an toàn và khả năng quay lui (Rollback)

**Không triển khai thay đổi lớn đồng loạt tới 100% người dùng ngay lập tức nếu có thể tránh được.** Các chiến lược triển khai giảm thiểu rủi ro phổ biến:
- Triển khai dần theo tỷ lệ nhỏ trước (canary release) — đưa thay đổi mới ra cho một phần nhỏ traffic/người dùng trước, theo dõi các chỉ số sức khoẻ hệ thống (đã nêu ở [`09-operations-reliability.md`](09-operations-reliability.md) mục 4), rồi mới mở rộng dần ra toàn bộ nếu không phát hiện vấn đề.
- Triển khai song song 2 phiên bản (blue-green deployment) — giữ phiên bản cũ vẫn đang chạy song song trong lúc phiên bản mới được xác minh, cho phép chuyển lưu lượng truy cập tức thời sang phiên bản cũ nếu phiên bản mới có vấn đề, không cần chờ triển khai lại từ đầu.

**Khả năng quay lui (rollback) phải được chuẩn bị sẵn TRƯỚC khi triển khai, không phải nghĩ ra sau khi sự cố đã xảy ra.** Trước khi triển khai bất kỳ thay đổi nào có rủi ro đáng kể, tự hỏi rõ: nếu thay đổi này gây sự cố sau khi đã triển khai, quy trình quay lại phiên bản trước đó cụ thể là gì, mất bao lâu để thực hiện? Đặc biệt lưu ý thay đổi liên quan cấu trúc cơ sở dữ liệu — một migration đã áp dụng có thể không dễ dàng đảo ngược nếu đã có dữ liệu mới ghi vào cấu trúc mới đó; cần cân nhắc thiết kế migration theo hướng có thể triển khai thay đổi mã nguồn và thay đổi cấu trúc dữ liệu ở các bước tách rời nhau (thêm cấu trúc mới trước, chuyển đổi mã nguồn dùng cấu trúc mới sau, dọn cấu trúc cũ ở một bước riêng sau khi đã xác nhận ổn định) để giữ khả năng quay lui từng phần.

**Cờ tính năng (feature flag):** với những tính năng có rủi ro cao hoặc cần thử nghiệm dần, cân nhắc bọc tính năng đó trong 1 điều kiện có thể bật/tắt độc lập với việc triển khai mã nguồn — cho phép tắt ngay lập tức 1 tính năng có vấn đề mà không cần triển khai lại toàn bộ hoặc quay lui toàn bộ phiên bản mã nguồn, tách rời hoàn toàn "triển khai mã nguồn" khỏi "kích hoạt tính năng cho người dùng thấy".

## 4. Sao lưu và khôi phục sau thảm hoạ (Backup & Disaster Recovery)

**Sao lưu dữ liệu định kỳ là bắt buộc cho mọi dự án có dữ liệu quan trọng**, tần suất sao lưu phù hợp với mức độ chấp nhận được của việc mất dữ liệu nếu sự cố xảy ra ngay trước lần sao lưu tiếp theo (mất dữ liệu tối đa bao lâu thì chấp nhận được, quyết định tần suất sao lưu tương ứng).

**Bản sao lưu không có giá trị nếu chưa từng được xác minh có khôi phục lại được hay không.** Định kỳ thực hiện thử khôi phục thật từ bản sao lưu (không chỉ tin tưởng rằng quy trình sao lưu "chắc chắn đang chạy đúng") ở một môi trường tách biệt, xác nhận dữ liệu khôi phục ra đúng và đầy đủ như kỳ vọng — nhiều tổ chức chỉ phát hiện bản sao lưu của mình bị lỗi/không đầy đủ đúng vào lúc cần khôi phục thật sau sự cố, khi đã quá muộn.

**Xác định rõ 2 chỉ số mục tiêu khi lập kế hoạch sao lưu/khôi phục:** thời gian tối đa chấp nhận được để khôi phục lại hệ thống hoạt động sau sự cố (mục tiêu thời gian khôi phục), và lượng dữ liệu tối đa chấp nhận mất đi tính từ thời điểm sự cố xảy ra tới bản sao lưu gần nhất (mục tiêu điểm khôi phục). Hai chỉ số này nên được thống nhất rõ ràng với người phụ trách dự án, vì chúng quyết định trực tiếp tần suất sao lưu cần thiết và mức độ đầu tư vào hạ tầng dự phòng.

## 5. Ứng phó sự cố (Incident Response)

Khi có sự cố xảy ra ở môi trường vận hành thật, nên có một quy trình ứng phó rõ ràng thay vì xử lý ngẫu hứng từng lần: xác định mức độ nghiêm trọng của sự cố, người/nhóm chịu trách nhiệm xử lý chính, kênh liên lạc dùng để phối hợp trong lúc xử lý, và các bước ưu tiên xử lý (thường ưu tiên khôi phục dịch vụ hoạt động trở lại trước, điều tra nguyên nhân gốc rễ sâu sau khi đã ổn định).

**Sau khi sự cố được xử lý xong, nên có một bước tổng kết lại (không nhằm mục đích quy trách nhiệm cá nhân, mà nhằm mục đích học hỏi):** nguyên nhân gốc rễ thực sự là gì (đã xác minh, không suy đoán — đúng nguyên tắc ở [`01-core-principles.md`](01-core-principles.md) mục 3), quy trình phát hiện/xử lý sự cố có điểm nào có thể cải thiện, và hành động cụ thể nào cần thực hiện để giảm khả năng lặp lại sự cố tương tự. Bài học rút ra từ sự cố nên được ghi lại vào tài liệu tri thức dự án ở mục bẫy kỹ thuật đã biết ([`20-memory-bank-mandate.md`](20-memory-bank-mandate.md)), để không lặp lại đúng sai lầm đã từng xảy ra.

---

## Checklist nhanh — khi thiết lập hoặc rà soát quy trình vận hành

- [ ] Có quy trình tự động xác minh chất lượng (chạy kiểm thử, kiểm tra cú pháp) trước khi hợp nhất thay đổi vào nhánh chính không?
- [ ] Thay đổi quan trọng có được xem xét lại bởi góc nhìn độc lập (người khác, hoặc tự xem xét sau khoảng nghỉ) trước khi chấp nhận không?
- [ ] Trước khi triển khai thay đổi có rủi ro, đã xác định rõ quy trình quay lui cụ thể chưa?
- [ ] Dữ liệu quan trọng có được sao lưu định kỳ, và bản sao lưu có được xác minh khôi phục thử định kỳ không?
- [ ] Có quy trình ứng phó sự cố rõ ràng, và sau mỗi sự cố có tổng kết bài học rồi ghi lại vào tài liệu tri thức dự án không?

---

*Xem tiếp: [`20-memory-bank-mandate.md`](20-memory-bank-mandate.md) — quy định bắt buộc về tài liệu tri thức dự án.*
