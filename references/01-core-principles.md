# 01 — Nguyên tắc nền tảng (Core Principles)

> File này áp dụng cho **MỌI** giai đoạn vòng đời dự án — khởi tạo mới, refactor code cũ, hay duy trì/thêm tính năng hàng ngày. Đọc file này TRƯỚC bất kỳ file chuyên đề nào khác trong bộ skill này.

Các nguyên tắc dưới đây không phải "gợi ý" — đây là **điều kiện bắt buộc** để 1 thay đổi code được coi là hoàn thành. Nếu 1 rule ở đây mâu thuẫn với yêu cầu tiện lợi/tốc độ tức thời, rule ở đây thắng — trừ khi chủ dự án xác nhận rõ ràng muốn đánh đổi.

---

## 1. Thứ tự ưu tiên khi các mục tiêu xung đột nhau

```
Bảo mật  >  Khả năng chịu lỗi (hệ thống không sập)  >  Hiệu năng & tối ưu tài nguyên  >  Tiện lợi/tốc độ code
```

Khi 1 giải pháp tối ưu hiệu năng làm giảm mức độ an toàn, hoặc 1 cách viết code gọn hơn bỏ qua kiểm tra lỗi — **không làm theo hướng đó**, tìm giải pháp khác không đánh đổi thứ hạng ưu tiên cao hơn.

**Ví dụ sai (đánh đổi bảo mật lấy tốc độ):**
```js
// SAI — bỏ qua check quyền vì "chắc chắn user đã login rồi, check lại làm gì cho chậm"
app.get('/api/admin/users', (req, res) => {
  return res.json(getAllUsers()); // Không có requireRole('admin')!
});
```

**Đúng:**
```js
app.get('/api/admin/users', requireLogin, requireRole('admin'), (req, res) => {
  return res.json(getAllUsers());
});
```

**Ví dụ sai (đánh đổi chịu lỗi lấy hiệu năng):**
```js
// SAI — Promise.all dừng NGAY khi 1 email lỗi, làm mất toàn bộ email còn lại chưa gửi
async function sendBulkEmails(recipients) {
  await Promise.all(recipients.map(r => sendEmail(r))); // 1 reject → cả lô coi như thất bại
}
```

**Đúng — chấp nhận chậm hơn 1 chút để không sập cả lô:**
```js
async function sendBulkEmails(recipients) {
  const errors = [];
  for (const r of recipients) {
    try { await sendEmail(r); }
    catch (e) { errors.push({ recipient: r.email, message: e.message }); }
  }
  return { sent: recipients.length - errors.length, errors };
}
```

**Khi nào được phép nới lỏng:** Chỉ khi chủ dự án đã được thông báo rõ đánh đổi cụ thể và xác nhận đồng ý — không tự ý quyết định thay.

---

## 2. Sửa code: đúng gốc rễ + phạm vi ảnh hưởng nhỏ nhất

Mọi lần sửa lỗi hoặc thay đổi hành vi phải đáp ứng **đồng thời cả 2 tiêu chí**, không được chỉ chọn 1:

1. **Đúng gốc rễ (root cause)** — không vá tạm (band-aid) chỉ để hết hiện tượng bên ngoài.
2. **Phạm vi nhỏ nhất** — không sửa lan sang code không liên quan, không tiện tay refactor/dọn dẹp phần khác nếu không được yêu cầu, không đổi hành vi ngoài phạm vi task.

**Ví dụ sai (vá triệu chứng, không phải gốc rễ):**
```js
// Bug: 2 request đồng thời cùng insert trùng email → lỗi UNIQUE constraint
// SAI — bọc try/catch nuốt lỗi, coi như "đã fix" nhưng dữ liệu request thứ 2 bị mất âm thầm
async function createAttendee(data) {
  try {
    return await db.run('INSERT INTO attendees (email) VALUES (?)', [data.email]);
  } catch (e) {
    return null; // Nuốt lỗi — user tưởng đã đăng ký thành công nhưng thực ra không có gì được lưu
  }
}
```

**Đúng (xử lý đúng nguyên nhân — race condition khi check-rồi-insert):**
```js
async function createAttendee(data) {
  return db.transaction(async (tx) => {
    const existing = await tx.get(
      'SELECT id FROM attendees WHERE event_id = ? AND email = ? FOR UPDATE',
      [data.eventId, data.email]
    );
    if (existing) {
      const err = new Error('Email đã tồn tại trong sự kiện này');
      err.status = 409;
      throw err;
    }
    return tx.run('INSERT INTO attendees (event_id, email) VALUES (?, ?)', [data.eventId, data.email]);
  });
}
```

**Khi 2 tiêu chí mâu thuẫn** (giải pháp đúng nhất đòi hỏi sửa nhiều file/nhiều tầng): vẫn ưu tiên đúng gốc rễ, nhưng **phải nói rõ phạm vi ảnh hưởng dự kiến cho chủ dự án trước khi thực hiện**, chờ xác nhận đồng ý — không tự ý mở rộng phạm vi âm thầm.

---

## 3. Không tự bịa, không tự suy diễn — mọi thay đổi phải có nguồn xác thực

Trước khi thêm/sửa code, phải xác định được lý do dựa trên 1 trong các nguồn đáng tin cậy:

- Yêu cầu trực tiếp của chủ dự án (trong hội thoại hiện tại)
- Bug/lỗi có thể tái hiện hoặc chứng minh được (log lỗi, hành vi sai quan sát được, exception cụ thể)
- Đọc code/tài liệu hiện có và trích dẫn được nguồn cụ thể (file:dòng, endpoint, bảng DB...)

**Không được:**
- Suy đoán "chắc user muốn vậy" rồi code theo mà không hỏi khi yêu cầu không rõ ràng — dùng câu hỏi làm rõ thay vì đoán.
- Bịa ra hành vi/API/tool/thư viện không có thật rồi code dựa trên giả định đó.
- Kết luận "chắc là do..." mà chưa đọc code/log để xác minh.
- Tự thêm tính năng/refactor "vì nghĩ sẽ tốt hơn" ngoài phạm vi được yêu cầu — nếu thấy cơ hội cải thiện, đề xuất và hỏi ý kiến, không tự làm luôn.

**Ví dụ sai (đoán tên field theo convention thay vì xác nhận):**
```js
// SAI — thấy tài liệu SDK bên thứ 3 chỉ mô tả chữ "trả về ID của privacy", tự đoán tên field
// theo convention camelCase thường gặp
const privacyId = callbackData.privacyID; // Đoán sai — field thật là PrivacyDetail.PrivacyId (PascalCase)
```

**Đúng — xác nhận qua nguồn thật (đọc source SDK, hỏi lại, hoặc test thử) trước khi dùng:**
```js
// Đã tải source thật của SDK (dù minified) và grep tìm literal string xác nhận tên field đúng
const privacyId = callbackData.PrivacyDetail?.PrivacyId;
```

**Khi không chắc chắn về 1 chi tiết** (API có tồn tại không, tool có sẵn không, hành vi hiện tại của hệ thống ra sao) → đi kiểm tra trực tiếp (đọc file, grep code, gọi thử) hoặc hỏi lại, không đoán rồi trình bày như thể chắc chắn.

---

## 4. Luôn backtest logic sau khi code xong (mới hoặc sửa)

Không coi 1 task là xong chỉ vì code chạy không lỗi cú pháp. Trước khi báo hoàn thành:

- Dò lại logic bằng tay qua từng nhánh, đặc biệt các hàm có nhiều nhánh trạng thái.
- Chạy thử thực tế (server local) và thao tác qua API/UI với kịch bản chính + kịch bản biên (edge case) liên quan đến thay đổi.
- Nếu dự án đã có bộ test tự động — chạy lại toàn bộ, không chỉ test case mới thêm (đảm bảo không phá vỡ hành vi cũ).
- Nếu không có điều kiện test đầy đủ (VD không dựng được UI để test bằng mắt) → nói rõ giới hạn đó, không khẳng định chắc chắn "đã hoạt động đúng" khi chưa kiểm chứng được.

**Ví dụ mức độ backtest cần thiết — sửa 1 hàm có nhiều nhánh trạng thái:**
```js
// Hàm scanQr() có 7 trạng thái trả về: checked_in, already_checked, booth_recorded,
// booth_already, valid, expired, invalid — sửa 1 nhánh phải verify LẠI cả 7 nhánh,
// không chỉ nhánh vừa sửa. 1 thay đổi tưởng vô hại ở điều kiện if có thể fall-through
// sang nhánh khác không mong muốn.
```

**Backtest dưới tải đồng thời** (khi thay đổi liên quan giao dịch nhiều người dùng cùng lúc — check-in, đặt chỗ, thanh toán...): test tuần tự 1 request luôn pass, race condition chỉ lộ ra khi có nhiều request chạy song song thật. Cần công cụ giả lập tải đồng thời (VD script gọi song song `N` request), không chỉ test tuần tự.

---

## 5. Bảo mật là mặc định, không phải tính năng thêm sau

Xuyên suốt mọi rule khác (chi tiết đầy đủ ở [`02-security-baseline.md`](02-security-baseline.md)):

- Không bỏ qua kiểm tra phân quyền để đổi lấy tốc độ hay code gọn hơn.
- Không tin dữ liệu client gửi lên cho các trường có ý nghĩa phân quyền/nghiệp vụ quan trọng (server luôn tự tính toán lại, không nhận nguyên giá trị client đưa).
- Escape/validate mọi dữ liệu user/DB trước khi nhúng vào ngữ cảnh khác (HTML, SQL, shell command...).

**Ví dụ minh hoạ nguyên tắc "không tin client" (áp dụng mọi stack):**
```js
// SAI — tin vào boothId client tự gửi lên, nhân viên có thể sửa request giả mạo vị trí
app.post('/scan', requireLogin, (req, res) => {
  const boothId = req.body.boothId; // Client tự khai — không tin được
  recordScan(req.user.id, boothId);
});

// ĐÚNG — server tự tra vị trí thật đã gán cho nhân viên này, bỏ qua giá trị client gửi
app.post('/scan', requireLogin, (req, res) => {
  const assignment = getStaffAssignment(req.user.id, req.body.eventId);
  const boothId = assignment.booth_id; // Nguồn duy nhất đáng tin — không đọc req.body.boothId
  recordScan(req.user.id, boothId);
});
```

---

## 6. Module hoá là mặc định, không đợi "đủ lớn mới tách"

Mục tiêu cuối: các thành phần **tách biệt trách nhiệm**, dễ bảo trì, dễ tái sử dụng — không quan trọng tách qua method hay class, miễn đạt mục tiêu. 1 hàm/method nên chỉ có 1 trách nhiệm rõ ràng, nhận input rõ ràng qua tham số, trả output rõ ràng qua return — tránh phụ thuộc ẩn vào biến toàn cục hoặc side effect khó lường khi không thật sự cần thiết.

**Logic được đánh giá có khả năng dùng lại ở nơi khác** (route khác, module khác, hoặc cả backend lẫn frontend) → tách ngay vào thư mục dùng chung (`common`/`shared`/`lib` tuỳ convention stack) ngay khi dùng tới **lần thứ 2**, không đợi "đủ lớn mới tách" — càng để lâu càng dễ bị copy-paste lặp lại ở nhiều chỗ, và khi phát hiện bug thì phải sửa rải rác nhiều nơi thay vì 1 chỗ duy nhất.

**Ví dụ sai (logic chống trùng dữ liệu bị copy-paste ở 3 nơi khác nhau):**
```js
// routes/attendee.js — nơi 1
if (data.phone === '') data.phone = null;
if (data.email === '') data.email = null;

// routes/import.js — nơi 2 (copy lại, quên chuẩn hoá y hệt)
const row = { phone: cols[2] || '', email: cols[3] || '' }; // BUG: quên đổi '' → null

// routes/open-api.js — nơi 3 (copy lại, lần này đúng nhưng khác cách viết)
const phone = payload.phone?.trim() || null;
```
Hậu quả thật: khi UNIQUE constraint coi `''` là giá trị trùng nhau (khác `NULL`), nơi 2 lỡ sót sẽ bị lỗi 500 mà nơi 1 và 3 không gặp — bug rải rác, khó dò hết vì logic không nằm ở 1 chỗ.

**Đúng — tách 1 hàm dùng chung ngay từ lần dùng thứ 2:**
```js
// common/normalize.js
function emptyToNull(value) {
  const v = typeof value === 'string' ? value.trim() : value;
  return v === '' || v === undefined ? null : v;
}
module.exports = { emptyToNull };

// Mọi nơi cần chuẩn hoá đều gọi lại đúng 1 hàm này — sửa 1 chỗ, áp dụng khắp nơi
const { emptyToNull } = require('../common/normalize');
data.phone = emptyToNull(data.phone);
```

**Khi tách code ra thư mục dùng chung:** tách cơ học trước (giữ nguyên hành vi 100%), tối ưu/cải tiến sau nếu thật sự cần — không gộp 2 việc "tách module" và "sửa logic" trong cùng 1 lần thay đổi (vi phạm nguyên tắc #2 — phạm vi ảnh hưởng nhỏ nhất, khó review, khó rollback nếu có lỗi).

---

## Checklist nhanh — áp dụng cho mọi lần code

- [ ] Có đánh đổi bảo mật/chịu lỗi lấy tốc độ/tiện lợi ở đâu không? Nếu có, đã hỏi ý kiến chủ dự án chưa?
- [ ] Giải pháp có đúng gốc rễ, và phạm vi sửa có ở mức nhỏ nhất cần thiết không?
- [ ] Lý do thực hiện thay đổi này có nguồn xác thực rõ ràng, hay đang tự suy diễn?
- [ ] Đã backtest lại logic (thủ công hoặc chạy thử thật), kể cả các nhánh edge case?
- [ ] Logic mới có tách thành method/hàm rõ trách nhiệm, tránh nhồi hết vào 1 chỗ không?
- [ ] Có phần nào dùng lại được ở nơi khác (lần thứ 2 trở lên) mà nên tách vào thư mục dùng chung ngay không?
- [ ] Nếu không chắc 1 chi tiết kỹ thuật — đã đi xác minh trực tiếp, hay đang giả định?

---

*Xem tiếp: [`02-security-baseline.md`](02-security-baseline.md) — chi tiết bảo mật, [`03-error-handling-resilience.md`](03-error-handling-resilience.md) — chi tiết chịu lỗi & log.*
