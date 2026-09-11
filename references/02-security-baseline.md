# 02 — Bảo mật nền tảng (Security Baseline)

> Đào sâu nguyên tắc #1 và #5 ở [`01-core-principles.md`](01-core-principles.md). Áp dụng cho mọi giai đoạn vòng đời — khởi tạo, refactor, duy trì.

Bảo mật không phải 1 tính năng thêm vào cuối, mà là điều kiện có mặt ngay từ dòng code đầu tiên. Một hệ thống "chạy đúng nhưng không an toàn" không được coi là hoàn thành task.

---

## 1. Xác thực (Authentication)

**Không tự phát minh cơ chế hash mật khẩu.** Luôn dùng thư viện đã được kiểm chứng rộng rãi (bcrypt, argon2, scrypt) với số vòng lặp (rounds/cost factor) đủ cao theo khuyến nghị hiện hành của thư viện đó — không tự viết hàm hash bằng MD5/SHA đơn thuần, không tự nghĩ ra cách "trộn muối" riêng.

**Session vs Token — chọn theo đặc điểm hệ thống, không theo thói quen:**
- Session (cookie phía server lưu trạng thái) phù hợp khi hệ thống có 1 backend duy nhất hoặc ít instance, không cần chia sẻ trạng thái đăng nhập qua nhiều domain khác nhau.
- Token (JWT hoặc tương tự, stateless) phù hợp khi có nhiều service độc lập cùng cần xác thực, hoặc client là mobile app/SPA tách biệt hoàn toàn khỏi domain backend.
- Nếu dùng cookie session: bắt buộc gắn cờ `secure` (chỉ gửi qua HTTPS) trên môi trường production, `httpOnly` (chặn JavaScript phía client đọc được, chống XSS đánh cắp session), và `sameSite` phù hợp (tối thiểu `lax`) để giảm rủi ro CSRF.
- Nếu dùng token: không bao giờ lưu token nhạy cảm (access token, refresh token) vào `localStorage` nếu có thể tránh — `localStorage` đọc được bởi bất kỳ đoạn JavaScript nào chạy trên trang, kể cả script độc hại chèn qua XSS. Ưu tiên cookie `httpOnly` để lưu token nếu kiến trúc cho phép.

**Chống session fixation:** Ngay sau khi xác thực thành công (dù qua mật khẩu hay SSO/OAuth), phải cấp lại một phiên làm việc hoàn toàn mới (regenerate session ID) trước khi gán thông tin người dùng vào phiên đó. Nếu không, một phiên đã được kẻ tấn công biết trước ID (gài sẵn trước khi nạn nhân đăng nhập) vẫn có thể tiếp tục dùng được sau khi nạn nhân đăng nhập thành công.

**Khi tích hợp SSO/OAuth2/OIDC của bên thứ ba:**
- Toàn bộ thông tin nhạy cảm (client secret, access token, id token thô) chỉ được xử lý ở phía server — phía client (trình duyệt) không bao giờ nhận trực tiếp các giá trị này, chỉ nhận lại một phiên đăng nhập (cookie) sau khi server đã xử lý xong.
- Giá trị `state` và `code_verifier` (nếu dùng PKCE) phải lưu tạm ở phía server (session), không lưu ở `localStorage`/`sessionStorage` phía trình duyệt — tránh bị đọc trộm qua XSS.
- Token định danh (id token) nhận về phải được xác minh chữ ký thật (qua khóa công khai của bên phát hành) trước khi tin bất kỳ thông tin nào bên trong — không được đọc thẳng nội dung token mà bỏ qua bước xác minh chữ ký, vì nội dung token base64 ai cũng giải mã đọc được, chỉ chữ ký mới chứng minh được tính xác thực.
- Nếu bên phát hành cung cấp nhiều host khác nhau cho mục đích khác nhau (ví dụ 1 host để chuyển hướng trình duyệt, 1 host khác để server gọi trực tiếp lấy token) — phải tách đúng theo tài liệu tích hợp, không mặc định dùng chung 1 địa chỉ cho cả hai mục đích.

**Không có backdoor đăng nhập nào được phép tồn tại ở môi trường thật.** Nếu cần một cơ chế bỏ qua xác thực phục vụ test tự động, cơ chế đó phải được khoá bằng một cờ môi trường RIÊNG BIỆT, không dùng chung với cờ xác định môi trường tổng quát (ví dụ không dùng "APP_ENVIRONMENT=Test" để mở route bypass, vì giá trị này có thể trùng với một môi trường thật đang chạy). Cờ riêng đó chỉ được đặt bởi chính bộ công cụ test tự động, không bao giờ được set thủ công trên môi trường vận hành thật.

**Khi dùng token (JWT hoặc tương tự), cần lưu ý các chi tiết sau — sai 1 trong số này có thể vô hiệu hoá toàn bộ giá trị bảo mật của cơ chế token:**
- Ép cứng thuật toán ký mong đợi khi xác minh token (ví dụ chỉ chấp nhận `RS256` hoặc chỉ chấp nhận `HS256`, tuỳ thiết kế) — không đọc thuật toán từ chính token rồi tin theo, vì kẻ tấn công có thể tạo token khai báo thuật toán `none` (không ký) hoặc đổi từ thuật toán bất đối xứng sang đối xứng để lừa hệ thống xác minh sai cách. Đây là lỗ hổng đã từng gây hậu quả thực tế nghiêm trọng trên nhiều hệ thống dùng JWT.
- Access token nên có thời hạn sống ngắn (tính bằng phút tới vài giờ tuỳ độ nhạy cảm), refresh token có thời hạn dài hơn nhưng phải lưu ở nơi an toàn hơn (cookie `httpOnly`, không phải `localStorage`) và có cơ chế thu hồi riêng.
- Cần có cơ chế thu hồi/vô hiệu hoá token trước khi hết hạn tự nhiên (khi người dùng chủ động đăng xuất, khi mật khẩu bị đổi, khi phát hiện token bị lộ) — bản chất token stateless không tự động hỗ trợ thu hồi, nên cần một danh sách token đã bị vô hiệu (blacklist) hoặc cơ chế đối chiếu phiên bản (versioning) lưu phía server để kiểm tra thêm ngoài việc chỉ xác minh chữ ký.

**CSRF (Cross-Site Request Forgery) — thuộc tính `sameSite` của cookie chỉ là một lớp phòng thủ, không phải giải pháp toàn diện duy nhất:** với các hành động làm thay đổi trạng thái hệ thống (tạo/sửa/xoá dữ liệu) khi dùng xác thực dựa trên cookie, nên có thêm cơ chế CSRF token riêng (một giá trị ngẫu nhiên gắn theo phiên làm việc, phía client phải gửi kèm trong request và server đối chiếu khớp trước khi xử lý) — không chỉ dựa hoàn toàn vào `sameSite`, vì một số tình huống đặc thù của trình duyệt hoặc cấu hình mạng vẫn có thể khiến lớp phòng thủ này không đủ.

---

## 2. Phân quyền (Authorization)

**Luôn kiểm tra quyền ở phía server, không bao giờ tin việc kiểm tra ở phía client là đủ.** Giao diện có thể ẩn nút bấm, ẩn menu — nhưng đó chỉ là trải nghiệm người dùng, không phải hàng rào bảo mật. Mọi endpoint xử lý dữ liệu đều phải tự kiểm tra lại quyền, bất kể client đã lọc hiển thị đúng hay chưa.

**Mô hình phân quyền phổ biến — chọn theo độ phức tạp nghiệp vụ thật, không phức tạp hoá không cần thiết:**
- Phân quyền theo vai trò (RBAC — Role-Based Access Control): mỗi người dùng gắn 1 hoặc vài vai trò cố định, mỗi vai trò có tập quyền cố định. Phù hợp khi số lượng vai trò ít và ổn định.
- Phân quyền theo thuộc tính (ABAC): quyền được tính toán động dựa trên nhiều thuộc tính (vai trò, đơn vị, trạng thái tài nguyên...). Chỉ nên dùng khi RBAC không đủ biểu đạt nghiệp vụ thật, vì độ phức tạp triển khai và kiểm thử cao hơn nhiều.

**Cách ly dữ liệu theo tổ chức/đơn vị (data isolation, hay gọi là multi-tenancy ở mức nhẹ):** Nếu hệ thống phục vụ nhiều đơn vị/tổ chức độc lập dùng chung 1 cơ sở dữ liệu, mọi câu truy vấn trả về danh sách đều phải áp điều kiện lọc theo đơn vị của người dùng đang đăng nhập — không có ngoại lệ "quên lọc vì nghĩ ít dữ liệu". Cách an toàn nhất là viết một hàm/helper dùng chung sinh ra điều kiện lọc này, gọi lại ở mọi nơi cần, thay vì mỗi endpoint tự viết điều kiện lọc riêng (dễ sót một chỗ).

**Nguyên tắc "không tin trường có ý nghĩa phân quyền do client gửi lên":** Bất kỳ giá trị nào ảnh hưởng tới việc ghi dữ liệu vào đâu, gán cho ai, hay xác định vị trí/vai trò của người thực hiện hành động — server phải tự tính toán lại dựa trên thông tin đã xác thực (ví dụ tra cứu lại từ bảng phân công đã lưu sẵn), không nhận nguyên giá trị client tự khai trong request. Đây là phòng thủ chống giả mạo hành vi (ví dụ nhân viên gửi sai vị trí công tác để đánh lừa báo cáo).

**Endpoint quản lý danh mục dùng chung toàn hệ thống** (ví dụ danh sách đơn vị, danh sách vai trò, cấu hình toàn cục) nên giới hạn quyền ghi (tạo/sửa/xoá) ở cấp cao nhất (super admin), kể cả khi cấp quản trị thấp hơn được phép đọc — vì các danh mục này ảnh hưởng trực tiếp tới ranh giới phân quyền của các cấp thấp hơn, không nên để cấp thấp hơn tự thao túng.

**IDOR (Insecure Direct Object Reference) — kiểm tra quyền SỞ HỮU, không chỉ kiểm tra quyền ĐĂNG NHẬP:** Đây là lỗ hổng phổ biến bậc nhất trong thực tế, dễ mắc phải nhất khi endpoint nhận trực tiếp 1 định danh bản ghi (ví dụ số thứ tự hoá đơn, mã hồ sơ) từ đường dẫn hoặc tham số request. Chỉ kiểm tra "người gọi đã đăng nhập" là chưa đủ — phải kiểm tra thêm "người gọi có quyền với ĐÚNG bản ghi này hay không" trước khi trả về hoặc cho phép sửa/xoá. Cách kiểm tra đúng: khi truy vấn bản ghi theo định danh nhận từ request, điều kiện truy vấn phải kèm theo cả điều kiện quyền sở hữu/phạm vi (ví dụ định danh bản ghi VÀ định danh người sở hữu đang đăng nhập phải khớp cùng lúc trong 1 câu truy vấn, hoặc sau khi lấy được bản ghi phải đối chiếu lại trường sở hữu trước khi trả về) — không truy vấn chỉ theo định danh bản ghi rồi mặc định trả về cho bất kỳ ai đã đăng nhập gọi tới. Rủi ro cụ thể nếu bỏ sót: người dùng A chỉ cần đổi số định danh trong đường dẫn request (từ hồ sơ của chính mình sang số định danh của người khác) là xem/sửa được dữ liệu không thuộc về mình, dù đã đăng nhập hợp lệ bằng chính tài khoản của họ.

**Mass Assignment — không tự động gán nguyên toàn bộ dữ liệu client gửi lên vào bản ghi mà không lọc:** Khi tạo mới hoặc cập nhật một bản ghi, nếu mã nguồn dùng cách gán tự động toàn bộ trường từ dữ liệu request vào đối tượng lưu trữ (thường gặp khi dùng các hàm gán hàng loạt tiện lợi của ngôn ngữ/ORM), kẻ tấn công có thể gửi kèm thêm các trường mà giao diện hợp lệ không hề hiển thị hoặc không có ý định cho phép sửa (ví dụ gửi kèm trường xác định vai trò/quyền hạn, trường trạng thái đã duyệt, trường số dư tài khoản) — nếu mã nguồn gán mù quáng toàn bộ, các trường nhạy cảm này bị ghi đè theo ý kẻ tấn công. Cách phòng chống: luôn định nghĩa rõ ràng danh sách trường được phép nhận từ client cho từng endpoint (danh sách cho phép — allowlist), chỉ trích xuất đúng các trường đó từ dữ liệu request trước khi đưa vào thao tác ghi, không gán nguyên toàn bộ đối tượng request vào bản ghi lưu trữ.

---

## 3. Chống các lỗ hổng tiêm nhiễm (Injection)

**Không bao giờ nối chuỗi trực tiếp giá trị từ người dùng vào câu truy vấn cơ sở dữ liệu.** Luôn dùng câu lệnh tham số hoá (parameterized query/prepared statement) — driver/ORM sẽ tự xử lý escape đúng cách, tránh SQL Injection. Việc này áp dụng cho mọi loại cơ sở dữ liệu (SQL và cả NoSQL nếu cú pháp truy vấn có thể bị chèn lệnh).

**Không nối chuỗi trực tiếp giá trị người dùng vào lệnh hệ điều hành (shell command).** Nếu bắt buộc phải gọi lệnh hệ thống với tham số động, dùng cơ chế truyền tham số dạng mảng (không qua shell interpreter), hoặc validate nghiêm ngặt giá trị đầu vào theo whitelist ký tự cho phép trước khi dùng.

**Chống XSS (Cross-Site Scripting):** Mọi dữ liệu có nguồn gốc từ người dùng hoặc từ cơ sở dữ liệu (vốn cũng bắt nguồn từ input người dùng ở một thời điểm nào đó) đều phải được escape đúng ngữ cảnh trước khi nhúng vào nơi khác:
- Nhúng vào HTML → escape ký tự đặc biệt HTML (`<`, `>`, `&`, `"`, `'`).
- Nhúng vào thuộc tính HTML → escape riêng cho ngữ cảnh thuộc tính (khác ngữ cảnh nội dung thẻ).
- Nhúng vào JavaScript (ví dụ gán giá trị vào biến JS ngay trong trang) → escape riêng cho ngữ cảnh JavaScript string, không dùng chung escape HTML.
- Nhúng vào URL query string → encode URL đúng chuẩn.

Không có ngoại lệ "dữ liệu này chắc chắn an toàn nên bỏ qua escape" — kể cả dữ liệu tưởng như vô hại (tên người, ghi chú ngắn) đều phải escape, vì không thể lường trước người dùng sẽ nhập gì.

Minh hoạ nguyên tắc escape đúng ngữ cảnh HTML (mã giả, cú pháp thật tuỳ ngôn ngữ/framework đang dùng — nhiều framework hiện đại tự động escape khi render qua template engine, cần xác nhận rõ framework của dự án có tự làm việc này không trước khi tự viết tay):
```
// SAI — nối chuỗi trực tiếp, dữ liệu chứa thẻ script sẽ được trình duyệt thực thi
noi_dung_trang = "<div>Xin chào " + ten_khach_hang_nhap_tu_form + "</div>"

// ĐÚNG — escape ký tự đặc biệt trước khi nối chuỗi
noi_dung_trang = "<div>Xin chào " + ham_escape_html(ten_khach_hang_nhap_tu_form) + "</div>"
// ham_escape_html thay: & → &amp;   < → &lt;   > → &gt;   " → &quot;   ' → &#39;
```

**SSRF (Server-Side Request Forgery) — không tin tưởng URL do client cung cấp khi server tự thực hiện request tới đó:** Nếu mã nguồn có bất kỳ chỗ nào server tự gọi ra một địa chỉ mạng dựa trên giá trị do client gửi lên (ví dụ tính năng "tải ảnh từ URL", webhook callback cấu hình được, proxy chuyển tiếp request), kẻ tấn công có thể lợi dụng để buộc server gọi tới các địa chỉ nội bộ mà lẽ ra không thể truy cập từ bên ngoài (địa chỉ mạng nội bộ, dịch vụ metadata của nền tảng đám mây thường chứa thông tin xác thực nhạy cảm, cổng quản trị nội bộ khác). Đây là lỗ hổng dễ bị bỏ sót vì bản thân request "trông có vẻ hợp lệ" ở tầng mã nguồn (chỉ là gọi HTTP bình thường), nhưng đích đến request lại nằm ngoài ý định thiết kế.

**Cách phòng chống SSRF:** nếu tính năng cần server tự gọi ra URL bên ngoài theo giá trị do client cung cấp, phải giới hạn nghiêm ngặt: chỉ chấp nhận địa chỉ thuộc danh sách miền/địa chỉ IP đã được cho phép trước (allowlist), từ chối rõ ràng các dải địa chỉ mạng nội bộ/riêng tư và địa chỉ loopback, và xác thực lại địa chỉ IP thật sự được phân giải ra (không chỉ kiểm tra tên miền hiển thị, vì tên miền có thể được cấu hình trỏ tới địa chỉ nội bộ). Nếu tính năng không thực sự cần thiết phải để client tự do chỉ định địa chỉ đích, cân nhắc loại bỏ khả năng này hoàn toàn thay vì cố gắng lọc an toàn một tính năng vốn có rủi ro cao.

**Giới hạn kích thước và định dạng input ở tầng server**, không chỉ dựa vào validate phía client (client có thể bị bỏ qua bằng cách gọi API trực tiếp):
- Giới hạn độ dài tối đa cho mọi trường văn bản (chống tấn công làm phình dữ liệu hoặc tràn bộ nhớ).
- Với file upload: kiểm tra định dạng thật của file bằng cách đọc vài byte đầu tiên (magic bytes) để xác nhận đúng loại file được khai báo, không chỉ tin vào phần mở rộng tên file hay Content-Type do client tự khai (cả hai đều dễ giả mạo). Giới hạn kích thước file tối đa.

**Deserialization không an toàn:** Khi ứng dụng nhận dữ liệu đã được tuần tự hoá (serialized) từ nguồn không tin cậy rồi chuyển ngược lại thành đối tượng trong bộ nhớ (deserialize), một số định dạng/thư viện deserialize cho phép dữ liệu đầu vào điều khiển việc khởi tạo đối tượng tuỳ ý hoặc thực thi mã không mong muốn nếu không được cấu hình an toàn. Nguyên tắc chung: chỉ deserialize dữ liệu từ nguồn tin cậy hoặc đã được ký/xác thực toàn vẹn; với dữ liệu từ client, ưu tiên định dạng dữ liệu thuần (như JSON tiêu chuẩn, vốn không tự thực thi mã khi parse) hơn các cơ chế serialize đặc thù ngôn ngữ có khả năng khôi phục logic thực thi; nếu thư viện deserialize đang dùng có tuỳ chọn chế độ an toàn (giới hạn kiểu dữ liệu được phép khôi phục), luôn bật tuỳ chọn đó.

---

## 4. Quản lý cấu hình nhạy cảm (Secrets Management)

**Không bao giờ commit giá trị bí mật thật vào mã nguồn** (mật khẩu database, khoá API, secret ký token). Tách cấu hình thành 2 tầng theo đúng tinh thần đã bàn ở phần cấu trúc thư mục:
- Tầng hiếm đổi, có thể commit (tên biến môi trường cần có, giá trị mặc định không nhạy cảm) — versioned cùng mã nguồn.
- Tầng hay đổi và nhạy cảm (mật khẩu thật, khoá API thật) — không commit, nạp lúc chạy qua biến môi trường hoặc file cấu hình được mount riêng ngoài mã nguồn (secret manager của nền tảng cloud, hoặc file cấu hình được quản lý tách biệt khỏi git).

**Giá trị bí mật mặc định dùng cho môi trường phát triển local không bao giờ được phép trùng với giá trị dùng ở môi trường thật.** Nếu code phát hiện đang chạy ở môi trường sản xuất mà giá trị bí mật vẫn là giá trị mặc định dùng cho dev — hệ thống nên từ chối khởi động thay vì âm thầm chạy với cấu hình không an toàn.

**Không log giá trị bí mật ra bất kỳ đâu** — kể cả log phục vụ debug tạm thời. Khi cần log toàn bộ cấu hình để debug, phải có cơ chế tự động che các trường nhạy cảm (theo tên trường khớp mẫu như chứa "secret", "password", "key", "token") trước khi ghi log.

**Đã lỡ lộ 1 giá trị bí mật ra ngoài (commit nhầm vào git, ghi vào tài liệu chia sẻ, log ra console công khai) → phải coi giá trị đó là đã bị xâm phạm và thay mới (rotate) ngay, không chỉ xoá dòng đã lộ khỏi lịch sử — vì lịch sử git/log có thể đã được ai đó sao lưu trước khi xoá.**

**Rotate định kỳ chủ động, không chỉ đợi sự cố xảy ra mới đổi:** với các giá trị bí mật có mức độ nhạy cảm cao (khoá truy cập dịch vụ đám mây, khoá ký token phiên đăng nhập), nên có kế hoạch thay mới định kỳ theo chu kỳ hợp lý ngay cả khi không có dấu hiệu bị lộ, để giảm thời gian hữu dụng của một giá trị bí mật nếu nó đã bị đánh cắp mà chưa được phát hiện. Khi thiết kế cơ chế thay mới bí mật, cân nhắc khả năng thay đổi không gây gián đoạn dịch vụ (ví dụ hỗ trợ tạm thời chấp nhận cả giá trị cũ và giá trị mới trong một khoảng thời gian chuyển tiếp ngắn, thay vì đổi đột ngột khiến mọi phiên đang hoạt động với giá trị cũ bị từ chối ngay lập tức).

---

## 5. Cấu hình sai an toàn (Security Misconfiguration)

Đây là nhóm lỗ hổng phát sinh không phải vì thiếu cơ chế bảo vệ, mà vì cơ chế đã có nhưng bị cấu hình sai hoặc bị bỏ sót khi chuyển từ môi trường phát triển sang môi trường vận hành thật.

- **Không để lộ chi tiết lỗi kỹ thuật (stack trace, câu truy vấn cơ sở dữ liệu, đường dẫn tệp nội bộ) ra phản hồi ở môi trường vận hành thật** — chế độ hiển thị lỗi chi tiết (thường hữu ích khi phát triển) phải được tắt hoàn toàn khi triển khai thật, đúng nguyên tắc đã nêu ở [`03-error-handling-resilience.md`](03-error-handling-resilience.md) mục 6.
- **Không để công cụ quản trị nội bộ, giao diện gỡ lỗi, hoặc bảng điều khiển quản lý cơ sở dữ liệu có thể truy cập được từ mạng công khai** — các công cụ này chỉ nên truy cập được từ mạng nội bộ hoặc qua kênh riêng biệt có xác thực mạnh, không mở song song với ứng dụng chính ra ngoài internet.
- **Không để lại tài khoản mẫu/dữ liệu mẫu có thông tin đăng nhập mặc định** khi triển khai lên môi trường thật — bất kỳ tài khoản khởi tạo sẵn nào (ví dụ tài khoản quản trị đầu tiên do hệ thống tự tạo) phải bắt buộc đổi mật khẩu ở lần đăng nhập đầu tiên, hoặc được cấp một mật khẩu ngẫu nhiên duy nhất không phải giá trị mặc định cố định.
- **Vô hiệu hoá phương thức HTTP không cần thiết** — nếu framework/máy chủ mặc định hỗ trợ các phương thức không được dùng tới trong thiết kế API (ví dụ TRACE), nên tắt hẳn nếu có thể, giảm bề mặt có thể bị lợi dụng.
- **Rà soát định kỳ cấu hình mặc định của mọi thư viện/framework mới thêm vào dự án** — nhiều thư viện có cấu hình mặc định ưu tiên sự tiện lợi khi phát triển hơn là an toàn khi vận hành thật (ví dụ bật công cụ debug, hiển thị đầy đủ thông tin phiên bản trong header phản hồi) — không mặc định tin rằng "cấu hình có sẵn từ thư viện chắc chắn đã an toàn".
- **Dockerfile phải khớp cấu trúc thư mục thật** — mỗi khi refactor xóa/thêm thư mục, rà soát lại các lệnh `COPY` trong Dockerfile. `COPY` thư mục không tồn tại làm `docker build` gãy. Đặc biệt chú ý khi tách migration sang pattern `schema.sql` + `changelogs/` (xem [`05-database-rules.md`](05-database-rules.md)) — thư mục migration cũ có thể đã xóa nhưng Dockerfile vẫn COPY.
- **Dockerfile phải pin phiên bản phụ thuộc khi build** — `COPY package.json package-lock.json` (cả 2 file) + dùng `npm ci` (không `npm install`) để cài đặt đúng phiên bản theo lock file, đảm bảo reproducible build và tránh vô tình cài phiên bản mới có mã độc (supply chain attack). Cờ `--production` đã deprecated từ npm 7+, dùng `--omit=dev` thay thế. Giữ `--ignore-scripts` để chặn postinstall script độc hại.

## 6. Bảo mật chuỗi cung ứng phần mềm (Supply Chain / Dependency Security)

Rủi ro bảo mật không chỉ tới từ mã nguồn tự viết, mà còn từ các thư viện/gói phụ thuộc bên ngoài mà dự án sử dụng — đặc biệt với hệ sinh thái quản lý gói có cộng đồng đóng góp mở, nơi bất kỳ ai cũng có thể xuất bản gói mới.

- **Quét lỗ hổng đã biết trong các thư viện phụ thuộc định kỳ** (dùng công cụ quét lỗ hổng phù hợp với hệ sinh thái đang dùng) — không chỉ cài đặt xong rồi không bao giờ kiểm tra lại, vì lỗ hổng mới trong thư viện đã cài có thể được công bố sau thời điểm cài đặt ban đầu.
- **Khoá phiên bản chính xác của thư viện phụ thuộc** (thông qua tệp khoá phiên bản mà hầu hết trình quản lý gói hiện đại đều hỗ trợ) — đảm bảo mọi môi trường (phát triển, kiểm thử, sản xuất) cài đặt đúng cùng 1 phiên bản thư viện, tránh tình trạng "chạy đúng ở máy này nhưng lỗi ở máy khác" do phiên bản phụ thuộc khác nhau, đồng thời tránh việc vô tình nâng cấp lên một phiên bản mới có chứa mã độc đã bị chèn vào (một hình thức tấn công chuỗi cung ứng đã từng xảy ra thực tế).
- **Cẩn trọng khi thêm thư viện mới** — kiểm tra mức độ phổ biến, tần suất bảo trì, và uy tín của thư viện trước khi thêm vào dự án, đặc biệt tránh nhầm lẫn tên gói với các gói giả mạo có tên gần giống gói phổ biến (một hình thức tấn công được biết tới rộng rãi trong hệ sinh thái quản lý gói mã nguồn mở).
- **Không tự ý nâng cấp phiên bản lớn (major version) của thư viện quan trọng mà không xem lại nhật ký thay đổi** — một số bản nâng cấp có thể thay đổi hành vi mặc định liên quan bảo mật, cần xác nhận rõ trước khi áp dụng.

## 7. Ghi nhật ký kiểm toán bảo mật (Audit Logging)

Đây là loại nhật ký khác hẳn với nhật ký phục vụ gỡ lỗi kỹ thuật đã nêu ở [`03-error-handling-resilience.md`](03-error-handling-resilience.md) mục 5 — nhật ký kiểm toán bảo mật phục vụ mục đích trả lời câu hỏi "ai đã làm gì, khi nào" khi cần điều tra sự cố hoặc đáp ứng yêu cầu tuân thủ, không phải để tìm nguyên nhân lỗi kỹ thuật.

**Các sự kiện nên được ghi vào nhật ký kiểm toán:** đăng nhập thành công/thất bại, thay đổi mật khẩu, thay đổi vai trò/quyền hạn của một tài khoản, truy cập hoặc xuất dữ liệu nhạy cảm hàng loạt, xoá dữ liệu quan trọng, thay đổi cấu hình hệ thống có ảnh hưởng bảo mật.

**Nội dung mỗi bản ghi kiểm toán nên có:** thời điểm xảy ra, định danh người/tài khoản thực hiện hành động, hành động cụ thể là gì, đối tượng bị tác động (ví dụ định danh bản ghi bị sửa/xoá), và kết quả (thành công hay thất bại). Nhật ký kiểm toán nên được lưu trữ tách biệt hoặc có cơ chế chống sửa đổi/xoá bởi chính người dùng thông thường (kể cả quản trị viên cấp thấp) — vì giá trị của nhật ký kiểm toán nằm ở việc không thể bị chính đối tượng đang bị điều tra tự ý xoá dấu vết.

**Không nhầm lẫn nhật ký kiểm toán với nhật ký gỡ lỗi thông thường** — nhật ký kiểm toán nên có thời gian lưu trữ dài hơn (theo yêu cầu tuân thủ hoặc chính sách nội bộ), và không nên bị dọn dẹp tự động theo cùng chu kỳ với nhật ký gỡ lỗi kỹ thuật thông thường.

---

## 8. Security Headers và các lớp bảo vệ tầng HTTP

Các header phòng thủ nên có mặt mặc định (có thể thêm thủ công nếu framework không tự hỗ trợ), không cần đợi yêu cầu riêng mới thêm:
- Chặn trình duyệt tự đoán loại nội dung khác với khai báo (chống một số kiểu tấn công dựa vào MIME sniffing).
- Chặn trang bị nhúng vào iframe của domain khác (chống clickjacking).
- Hạn chế thông tin rò rỉ qua header Referrer khi điều hướng sang domain khác.
- Bắt buộc kết nối HTTPS cho các lần truy cập sau (chỉ bật khi chạy ở môi trường có HTTPS thật, không bật ở môi trường dev chạy HTTP thuần).

**CORS (Cross-Origin Resource Sharing):** Chỉ mở cho phép truy cập chéo domain đối với các endpoint thực sự cần được gọi từ domain khác (ví dụ API công khai phục vụ widget nhúng). Không mở CORS toàn cục cho mọi endpoint nếu không có nhu cầu thật — mở rộng không cần thiết làm tăng bề mặt tấn công.

**Giới hạn tốc độ gọi (Rate Limiting):** Bắt buộc áp dụng cho các endpoint xác thực (đăng nhập, xác thực callback từ bên thứ ba) để chống dò mật khẩu bằng brute-force. **Bao gồm cả endpoint validate credential server-to-server** (ví dụ webhook nhận `x-clientid`/`x-clientsecret` để xác thực request từ platform bên thứ ba) — credential tĩnh vẫn bị brute-force được nếu không giới hạn tần suất. Đếm số lần thất bại theo địa chỉ IP (hoặc theo tài khoản, tuỳ chiến lược), khoá tạm sau một ngưỡng nhất định trong một khoảng thời gian, và tự động reset bộ đếm khi có lần thành công. Cơ chế đếm phải tự dọn dữ liệu cũ để không rò rỉ bộ nhớ theo thời gian nếu lưu trong bộ nhớ tiến trình.

**Rate-limit trên môi trường nhiều bản sao (multi-pod/Kubernetes):** nếu store đếm nằm trong bộ nhớ tiến trình (memory store), mỗi pod đếm riêng — attacker phân phối request qua nhiều pod có thể vượt giới hạn tổng. Khi cần giới hạn chặt trên multi-pod, dùng store chia sẻ (Redis) để đồng bộ bộ đếm giữa các pod. Memory store chỉ chấp nhận được khi endpoint chỉ nhận traffic từ 1 nguồn tin cậy (ví dụ platform gọi webhook, không phải attacker).

---

## 9. Nguyên tắc phân loại dữ liệu nhạy cảm (PII)

Trước khi xây dựng một tính năng mới xử lý dữ liệu người dùng, cần tự hỏi rõ: dữ liệu này có chứa thông tin định danh cá nhân không (tên, email, số điện thoại, địa chỉ, thông tin thiết bị...)? Nếu có, áp dụng các nguyên tắc:
- Chỉ những vai trò thực sự cần thiết cho công việc mới được xem đầy đủ — phân biệt rõ giữa "xem từng bản ghi lẻ khi cần liên hệ" và "xem/xuất toàn bộ danh sách" là hai mức độ rủi ro khác nhau, có thể cấp quyền khác nhau cho cùng 1 vai trò.
- Endpoint xuất dữ liệu hàng loạt (export Excel, báo cáo tổng hợp có PII) nên được giới hạn chặt hơn endpoint xem từng bản ghi đơn lẻ.
- Khi xây dựng object dữ liệu nội bộ phục vụ nhiều mục đích khác nhau (vừa lưu tạm để xử lý sau, vừa trả về client hiển thị tiến độ), phải tự hỏi từng nơi dùng có thực sự cần toàn bộ trường dữ liệu hay không — không mặc định trả nguyên object gốc ra ngoài chỉ vì tiện, đặc biệt khi object đó có thể chứa nhiều dữ liệu hơn mức cần thiết cho nơi nhận.

---

## Checklist nhanh — trước khi coi 1 thay đổi liên quan bảo mật là xong

- [ ] Mọi endpoint mới có kiểm tra xác thực + phân quyền ở phía server, không chỉ dựa vào client?
- [ ] Endpoint nhận định danh bản ghi từ request có kiểm tra quyền SỞ HỮU đúng bản ghi đó (chống IDOR), không chỉ kiểm tra đã đăng nhập?
- [ ] Thao tác tạo/cập nhật có dùng danh sách trường được phép rõ ràng (allowlist), không gán mù quáng toàn bộ dữ liệu client gửi lên (chống mass assignment)?
- [ ] Có trường nào từ client ảnh hưởng tới phân quyền/nghiệp vụ quan trọng mà server đang tin nguyên giá trị đó không?
- [ ] Dữ liệu nhúng vào HTML/SQL/shell/URL có escape đúng ngữ cảnh chưa?
- [ ] Có chỗ nào server tự gọi ra URL do client cung cấp (SSRF) mà chưa giới hạn allowlist đích đến chưa?
- [ ] Nếu dùng JWT, thuật toán ký có được ép cứng khi xác minh, không đọc theo khai báo trong chính token không?
- [ ] Giá trị bí mật có đang nằm trong mã nguồn commit vào git không?
- [ ] Endpoint xác thực có rate limit chống brute-force chưa?
- [ ] Dữ liệu PII trả về có đúng mức cần thiết cho từng vai trò/mục đích, không thừa không thiếu?
- [ ] Các hành động nhạy cảm (đổi quyền, xoá dữ liệu, xuất hàng loạt) có được ghi vào nhật ký kiểm toán riêng biệt với log gỡ lỗi không?
- [ ] Thư viện phụ thuộc mới thêm vào có được kiểm tra uy tín/lỗ hổng đã biết trước khi dùng không?

---

*Xem tiếp: [`03-error-handling-resilience.md`](03-error-handling-resilience.md) — chi tiết xử lý lỗi & khả năng chịu lỗi.*
