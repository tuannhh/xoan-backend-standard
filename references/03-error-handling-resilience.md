# 03 — Xử lý lỗi & Khả năng chịu lỗi (Error Handling & Resilience)

> Đào sâu nguyên tắc chịu lỗi và log đúng chỗ đã nêu ở [`01-core-principles.md`](01-core-principles.md). Áp dụng cho mọi giai đoạn vòng đời.

Một hệ thống phục vụ người dùng thật — lỗi ở 1 phần tử/1 thao tác đơn lẻ không được phép làm sập cả request, cả vòng lặp, hay cả tiến trình server. Hậu quả của việc sập giữa lúc đang vận hành thật luôn nghiêm trọng hơn nhiều so với 1 thao tác lẻ bị lỗi và được báo cáo rõ ràng.

---

## 1. Vòng lặp xử lý nhiều bản ghi — không để 1 lỗi làm dừng cả lô

Khi xử lý một danh sách nhiều bản ghi trong 1 lần (nhập dữ liệu hàng loạt, gửi email hàng loạt, tác vụ định kỳ chạy nền xử lý nhiều đối tượng): mỗi phần tử phải được xử lý trong khối bắt lỗi riêng của chính nó. Nếu 1 phần tử gặp lỗi, ghi nhận lỗi đó vào danh sách kết quả (kèm đủ thông tin để biết phần tử nào, lý do gì) và tiếp tục xử lý các phần tử còn lại — không để lỗi ở 1 phần tử làm dừng toàn bộ vòng lặp giữa chừng.

Kết thúc vòng lặp, trả về kết quả tổng hợp gồm cả số lượng thành công và danh sách chi tiết các phần tử thất bại — không nên trả một lỗi chung chung "thao tác thất bại" khiến người dùng hiểu lầm toàn bộ đã không có gì được xử lý trong khi thực tế phần lớn đã thành công.

## 2. Thao tác gọi dịch vụ bên ngoài (external call)

Mọi lệnh gọi tới dịch vụ ngoài tiến trình hiện tại (gọi API bên thứ ba, gửi email qua nhà cung cấp, gọi dịch vụ lưu trữ đám mây, kết nối cơ sở dữ liệu) đều phải được bọc trong khối bắt lỗi. Không để 1 lần gọi dịch vụ ngoài bị lỗi (mất mạng, dịch vụ đang bảo trì, timeout) kéo theo việc toàn bộ tiến trình dừng hoạt động.

**Timeout là bắt buộc, không phải tuỳ chọn.** Mọi lệnh gọi ra bên ngoài phải có giới hạn thời gian chờ hợp lý — không để một lệnh gọi treo vô thời hạn chiếm giữ tài nguyên (kết nối, luồng xử lý) khi phía đối tác không phản hồi.

**Không tự động lặp lại (retry) một cách mù quáng đối với hành động có tác dụng phụ không thể lặp lại an toàn (không idempotent).** Trước khi thêm cơ chế retry tự động cho bất kỳ hành động nào, phải tự hỏi rõ: nếu lệnh này chạy 2 lần liên tiếp (vì lần 1 tưởng thất bại nhưng thực ra đã thành công phía server, chỉ là phản hồi bị mất), hậu quả có chấp nhận được không? Nếu hành động đó có thể gây trùng lặp dữ liệu hay tác dụng phụ nghiêm trọng khi chạy nhiều lần (ví dụ: gán một tài nguyên duy nhất, trừ tiền, gửi thông báo quan trọng) — không nên tự động retry, mà để con người xác nhận lại và chủ động thử lại thủ công sau khi thấy lỗi rõ ràng.

**Gửi hàng loạt tới cùng 1 nhà cung cấp dịch vụ ngoài nên giữ tuần tự, không mặc định chuyển sang song song ồ ạt.** Đa số nhà cung cấp dịch vụ (email, SMS, thanh toán) đều áp giới hạn tốc độ gọi theo thời gian (rate limit) — gọi song song không kiểm soát dễ khiến toàn bộ lô bị nhà cung cấp từ chối hoặc khoá tạm. Nếu cần tăng tốc độ xử lý, phải đo giới hạn thực tế của nhà cung cấp trước và thêm cơ chế giới hạn tốc độ (throttle) có kiểm soát, không đổi ngầm từ tuần tự sang song song mà không đánh giá rủi ro.

## 3. Input không tin cậy — validate trước khi dùng, có giá trị mặc định hợp lý

Bất kỳ dữ liệu nào đến từ bên ngoài tiến trình hiện tại (file người dùng tải lên, nội dung body của request, tham số query string, dữ liệu đọc từ một hệ thống khác) đều phải được xem là không tin cậy cho tới khi được validate.

Khi parse một cấu trúc dữ liệu có khả năng sai định dạng (ví dụ chuỗi JSON được lưu trong 1 cột văn bản, dữ liệu Excel người dùng tải lên), luôn bọc thao tác parse trong khối bắt lỗi và có giá trị mặc định hợp lý khi việc parse thất bại — không để việc parse lỗi làm crash toàn bộ luồng xử lý đang chạy.

**Không dùng khối bắt lỗi để che giấu lỗi cần được biết.** Bắt lỗi để tránh crash không đồng nghĩa với việc bỏ qua lỗi hoàn toàn — luôn ghi log lại lỗi đã xảy ra (xem mục 5 bên dưới), để không mất dấu vết khi cần truy vết nguyên nhân sau này. Một khối bắt lỗi rỗng (không làm gì cả) gần như luôn là dấu hiệu của việc "nuốt lỗi" âm thầm, cần tránh.

## 4. Fail gracefully hơn fail loudly ở tầng phục vụ người dùng cuối

Ưu tiên chung: khi 1 phần nhỏ của 1 thao tác lớn hơn gặp lỗi, nên báo lỗi đó ở đúng phạm vi của nó (ví dụ trong danh sách kết quả chi tiết) thay vì làm cả thao tác lớn hơn trả về lỗi toàn phần khiến người dùng cuối hiểu lầm mọi thứ đã thất bại.

Ngược lại, lỗi hệ thống nghiêm trọng thật sự (không lường trước, có khả năng ảnh hưởng tính đúng đắn dữ liệu) không nên bị nuốt để "trông có vẻ mọi thứ ổn" — phải phản ánh đúng mức độ nghiêm trọng, chỉ khác là cách phản ánh (thông báo cụ thể tới đúng nơi cần biết) nên được thiết kế có chủ đích, không phải mặc định gây gián đoạn toàn bộ hệ thống.

## 5. Đặt log đúng chỗ để debug chính xác

**Vị trí nên đặt log:**
- Khối bắt lỗi của thao tác bất đồng bộ/gọi mạng (gửi email, gọi API bên ngoài).
- Nhánh lỗi quan trọng trong luồng nghiệp vụ (một điều kiện logic không đạt được như kỳ vọng, dẫn tới việc từ chối xử lý tiếp).
- Thao tác chạy nền không có người dùng trực tiếp theo dõi (tác vụ định kỳ, hàng đợi xử lý nền) — vì đây là những chỗ lỗi dễ bị bỏ sót nhất nếu không log, do không ai đang nhìn màn hình chờ kết quả ngay lúc đó.

**Nội dung log cần đủ ngữ cảnh để truy vết:** định danh liên quan tới bản ghi/đối tượng đang xử lý, hành động đang thực hiện là gì, và thông điệp lỗi gốc (không chỉ ghi chung chung "có lỗi xảy ra").

**Không log:**
- Dữ liệu bí mật (mật khẩu, token phiên đăng nhập, khoá API) — xem thêm mục secrets ở [`02-security-baseline.md`](02-security-baseline.md).
- Toàn bộ dữ liệu cá nhân không cần thiết cho việc debug cụ thể đang cần.
- Tràn lan ở vòng lặp chạy nhiều lần trong thời gian ngắn hoặc mỗi request bình thường không có gì bất thường — log quá nhiều làm loãng log, khiến log quan trọng khi có sự cố thật trở nên khó tìm giữa hàng loạt log không cần thiết.

**Request log không ghi nguyên URL đầy đủ (`req.originalUrl`)** — URL đầy đủ chứa query string, mà query string thường mang token tạm (`sid`, `code` OAuth) hoặc định danh nhạy cảm (`session_id`, `tenant_id`, `user_id` truyền qua webhook). Log chỉ ghi `req.path` (phần path, không query string) để trace đủ mà không rò rỉ token/PII vào log.

**Error log URL dịch vụ ngoài chỉ ghi host+path** — khi log lỗi gọi API bên thứ ba (ví dụ "Timeout gọi Payment Gateway tại {url}"), không log nguyên URL đầy đủ vì URL chứa query string mang token/PII (sid, tenantId, apiKey). Dùng helper rút gọn chỉ `host + pathname`, bỏ query string.

**Phân cấp mức độ log (log level)** nên được dùng nhất quán — mức lỗi nghiêm trọng (error) dành cho sự cố cần chú ý ngay, mức cảnh báo (warn) cho tình huống bất thường nhưng chưa gây hại, mức thông tin (info) cho các mốc quan trọng trong luồng xử lý bình thường, và mức chi tiết (debug) chỉ nên bật khi đang chủ động điều tra vấn đề cụ thể (không bật mặc định ở môi trường sản xuất vì tạo quá nhiều dữ liệu log).

## 6. Bộ xử lý lỗi tổng (Global Error Handler)

Nên có một điểm xử lý lỗi tổng ở tầng cao nhất của ứng dụng (bắt mọi lỗi không được xử lý riêng ở đâu khác), để đảm bảo:
- Không có lỗi nào rơi ra ngoài dưới dạng trang lỗi mặc định không có cấu trúc nhất quán (gây khó khăn cho phía gọi API khi cố gắng phân tích phản hồi).
- Mọi lỗi không lường trước đều được ghi log lại đầy đủ ngữ cảnh trước khi trả về phản hồi cho phía gọi.
- Phân biệt rõ giữa lỗi nghiệp vụ có chủ đích (đã có thông điệp rõ ràng dành cho người dùng đọc được, ví dụ "thiếu trường bắt buộc") và lỗi hệ thống thật sự không lường trước — chỉ lỗi nghiệp vụ có chủ đích mới nên trả nguyên thông điệp gốc cho phía gọi; lỗi hệ thống nghiêm trọng nên trả một thông điệp chung chung an toàn, không lộ chi tiết kỹ thuật/stack trace ra ngoài (tránh rò rỉ thông tin có thể bị lợi dụng), chi tiết thật chỉ nằm trong log phía server.
- Bộ xử lý lỗi tổng phải tôn trọng mã trạng thái lỗi đã được gán sẵn từ nơi phát sinh lỗi (nếu route/hàm nghiệp vụ đã tự gán rõ đây là lỗi thuộc loại nào) — không mặc định gán cứng cùng 1 mã trạng thái cho mọi loại lỗi, vì điều đó sẽ phá vỡ hành vi phân biệt lỗi nghiệp vụ (ví dụ lỗi do người dùng nhập thiếu thông tin) với lỗi hệ thống nghiêm trọng.
- **Lỗi 5xx có nguồn gốc từ dịch vụ ngoài (upstream API trả 502/504)** — kể cả khi error handler tự bọc thành AppError có chủ đích, **không trả `err.message` gốc ra response** vì message có thể là `body.ErrorMessage` của dịch vụ ngoài, lộ thông tin nội bộ của bên thứ ba. Trả message generic an toàn, log đầy đủ message gốc + stack phía server. Chỉ lỗi 4xx nghiệp vụ (message do chính dự án viết, dành user đọc) mới trả `err.message` gốc.

Minh hoạ cấu trúc bộ xử lý lỗi tổng (mã giả, cú pháp đăng ký middleware xử lý lỗi thật tuỳ framework — nhiều framework web hiện đại có cơ chế riêng để đánh dấu 1 hàm là "xử lý lỗi tổng", cần xác nhận đúng cách đăng ký của framework đang dùng):
```
DANG_KY_XU_LY_LOI_TONG(function(loi, request, phan_hoi) {
  ma_trang_thai = loi.ma_trang_thai_da_gan || 500   // tôn trọng mã đã gán, mặc định 500 nếu chưa có
  GHI_LOG_LOI("Lỗi không lường trước", {
    duong_dan: request.duong_dan,
    ma_trang_thai: ma_trang_thai,
    thong_diep_goc: loi.thong_diep,
    // ghi kèm stack trace vào log server — KHÔNG trả stack trace ra response
  })

  neu (ma_trang_thai < 500) {
    // Lỗi nghiệp vụ có chủ đích, thông điệp đã viết sẵn để người dùng đọc được
    phan_hoi.gui(ma_trang_thai, { loi: loi.thong_diep })
  } khac {
    // Lỗi hệ thống thật sự — không lộ chi tiết kỹ thuật ra ngoài
    phan_hoi.gui(500, { loi: "Có lỗi xảy ra ở máy chủ. Vui lòng thử lại." })
  }
})
```

## 7. Giới hạn tài nguyên có chủ đích

Mọi cấu trúc dữ liệu lưu tạm trong bộ nhớ tiến trình (không phải cơ sở dữ liệu lâu dài) — dùng để theo dõi trạng thái phiên làm việc tạm thời, hàng đợi xử lý, hay bộ đếm giới hạn tốc độ — đều phải có cơ chế tự giới hạn kích thước hoặc tự dọn dẹp theo thời gian sống (TTL). Nếu không, cấu trúc này sẽ phình to vô hạn theo thời gian vận hành của tiến trình, dẫn tới rò rỉ bộ nhớ âm thầm không có dấu hiệu rõ ràng cho tới khi tiến trình sập vì hết bộ nhớ.

Các giới hạn tài nguyên hiện có trong hệ thống (kích thước file tải lên tối đa, số lượng bản ghi xử lý mỗi lần chạy tác vụ định kỳ, số kết nối đồng thời tối đa) nên được giữ nguyên trừ khi có lý do rõ ràng cần nới lỏng — không nới lỏng tuỳ tiện chỉ vì "chưa thấy vấn đề gì".

---

## Checklist nhanh — trước khi coi 1 thay đổi liên quan xử lý lỗi/tài nguyên là xong

- [ ] Vòng lặp xử lý nhiều bản ghi có bắt lỗi riêng từng phần tử, không để 1 lỗi dừng cả lô?
- [ ] Lệnh gọi dịch vụ bên ngoài có bọc bắt lỗi + có timeout hợp lý?
- [ ] Có đang tự động retry một hành động không idempotent không — nếu có, đã đánh giá rủi ro trùng lặp chưa?
- [ ] Input không tin cậy đã được validate/có giá trị mặc định hợp lý khi sai định dạng chưa?
- [ ] Log đã đặt đúng chỗ, đủ ngữ cảnh, và không lộ dữ liệu nhạy cảm?
- [ ] Cấu trúc dữ liệu lưu tạm trong bộ nhớ có cơ chế tự giới hạn/tự dọn theo thời gian không?

---

*Xem tiếp: [`04-project-structure.md`](04-project-structure.md) — cấu trúc thư mục dự án.*
