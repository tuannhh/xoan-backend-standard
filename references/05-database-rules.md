# 05 — Quy tắc cơ sở dữ liệu (Database Rules)

> Áp dụng cho mọi thay đổi liên quan tới lược đồ dữ liệu, câu truy vấn, hoặc giao dịch (transaction). Nhiều bài học ở đây rút ra từ các sự cố thật đã xảy ra khi chuyển đổi hệ quản trị cơ sở dữ liệu — cùng loại sai lầm rất dễ lặp lại nếu không biết trước.

---

## 1. Migration phải idempotent — chạy lại nhiều lần không gây lỗi

Mọi thay đổi cấu trúc dữ liệu (thêm bảng, thêm cột, thêm ràng buộc) nên được viết theo cách kiểm tra sự tồn tại trước khi tạo mới, thay vì luôn giả định đang chạy trên một cơ sở dữ liệu hoàn toàn trống. Điều này cho phép cùng 1 tệp migration chạy được nhiều lần (ví dụ khi khởi động lại ứng dụng, hoặc khi có nhiều môi trường ở các trạng thái khác nhau) mà không gây lỗi do cố tạo lại thứ đã tồn tại.

Migration không nên chứa thao tác phá huỷ dữ liệu không kiểm soát (xoá bảng, xoá dữ liệu hàng loạt) trừ khi đó chính xác là mục đích của migration đó và đã được xác nhận rõ ràng. Khi cần dọn dữ liệu cũ trước khi áp đặt một ràng buộc mới (ví dụ chuẩn hoá giá trị rỗng thành giá trị null trước khi thêm ràng buộc duy nhất), bước dọn dữ liệu phải chạy trước bước thêm ràng buộc, không được đảo ngược thứ tự — nếu không, dữ liệu cũ vi phạm ràng buộc mới sẽ khiến chính bước thêm ràng buộc thất bại.

**Thứ tự khi thay ràng buộc duy nhất (unique constraint) từ cột này sang cột khác:** thêm ràng buộc mới trước, xoá ràng buộc cũ sau — không làm ngược lại. Lý do: nếu cột đang chịu ràng buộc cũ đồng thời cũng đang phục vụ vai trò hỗ trợ một ràng buộc khoá ngoại (foreign key) hoặc mục đích khác, xoá ràng buộc cũ trước khi có ràng buộc mới thay thế có thể khiến hệ quản trị cơ sở dữ liệu từ chối thao tác xoá vì đang thiếu chỉ mục cần thiết cho ràng buộc khác. Luôn xác nhận thực tế trên môi trường kiểm thử trước khi cho rằng thứ tự nào là an toàn, không suy đoán suông.

**Mỗi thay đổi cấu trúc dữ liệu nên đi kèm một tệp migration riêng biệt, có đánh dấu thời điểm rõ ràng** — để có thể áp dụng đúng thứ tự trên các môi trường khác nhau, và để người vận hành không có nền tảng kỹ thuật sâu vẫn có thể chạy đúng đoạn cần thiết mà không phải tự trích xuất từ một tệp lược đồ đầy đủ.

### Pattern chuẩn: `schema.sql` baseline + `changelogs/` delta

Tổ chức file migration theo 2 thành phần tách biệt:

- **`startup/database/schema.sql`** — file **baseline đầy đủ nhất**: tạo database + toàn bộ bảng + stored procedure hỗ trợ migration inline (ví dụ `add_column_if_missing`) + migration inline idempotent. File này luôn giữ ở trạng thái **bản đầy đủ mới nhất** — khi thay đổi schema, phải cập nhật cả file này. Mục đích: khởi tạo DB mới từ con số 0 một cách đầy đủ, không cần chạy lần lượt mọi changelog từ đầu.
- **`startup/database/changelogs/changelog_database_YYYYMMDD_HHMMSS.sql`** — mỗi thay đổi schema **sau** baseline ghi vào 1 file riêng, chạy theo thứ tự tên file (sort theo tên = thứ tự thời gian). Mỗi file PHẢI idempotent: dùng `add_column_if_missing` + `IF EXISTS`/`IF NOT EXISTS` check `INFORMATION_SCHEMA` cho index/constraint.
- **`startup/database/seed.sql`** — dữ liệu mẫu (tách riêng khỏi schema).

**Quy tắc khi thay đổi schema:**
1. Tạo file mới trong `changelogs/` (mỗi thay đổi 1 file, đánh dấu thời điểm).
2. **ĐỒNG THỜI** cập nhật `schema.sql` — baseline phải luôn là bản đầy đủ mới nhất.
3. Mỗi changelog PHẢI idempotent (chạy lại nhiều lần không lỗi).
4. Cập nhật tài liệu lược đồ (memory-bank) + lịch sử phát triển.

**Áp dụng thủ công (không có runner tự động):** việc apply `schema.sql` + `changelogs/` làm **thủ công** qua `mysql` CLI (`mysql -u root -p < startup/database/schema.sql` lần đầu, `mysql -u root -p <db> < changelogs/<file>.sql` mỗi changelog mới) — không có script tự động migrate, không chạy lúc app khởi động. Tách bạch khỏi vòng đời app tránh nguy cơ app tự ALTER database ở mọi lần khởi động (đặc biệt nguy hiểm khi multi-pod cùng khởi động).

**Ứng dụng không tự chạy schema.sql lúc khởi động** — chỉ `verifyTables()` kiểm tra các bảng bắt buộc đã tồn tại, fail với thông báo "Chạy schema.sql trước" nếu thiếu.

## 2. Phân biệt rõ "chưa có giá trị" (NULL) và "giá trị rỗng" (chuỗi rỗng)

Đây là một trong những sai lầm dễ lặp lại nhất khi thiết kế ràng buộc duy nhất (unique constraint) trên một cột cho phép "chưa nhập":

Nếu một cột được định nghĩa không cho phép giá trị null nhưng có giá trị mặc định là chuỗi rỗng, và cột đó đồng thời tham gia vào một ràng buộc duy nhất — nhiều bản ghi khác nhau cùng "chưa nhập" giá trị cho cột này sẽ đều mang chuỗi rỗng, và hầu hết hệ quản trị cơ sở dữ liệu coi 2 chuỗi rỗng là bằng nhau khi kiểm tra ràng buộc duy nhất, dẫn tới báo lỗi trùng lặp dù về mặt nghiệp vụ đây là 2 bản ghi hoàn toàn khác nhau, chỉ đơn giản là cùng chưa điền thông tin.

**Quy tắc bắt buộc:** bất kỳ cột nào cho phép trạng thái "chưa nhập" và đồng thời tham gia ràng buộc duy nhất (dù ràng buộc đơn hay ràng buộc kết hợp nhiều cột) phải cho phép giá trị null, và mọi đường ghi dữ liệu vào cột đó phải chuẩn hoá chuỗi rỗng thành null trước khi lưu — không dùng chuỗi rỗng để biểu diễn "chưa có giá trị". Đa số hệ quản trị cơ sở dữ liệu coi nhiều giá trị null là không trùng nhau khi kiểm tra ràng buộc duy nhất (khác hẳn cách xử lý chuỗi rỗng), nên đây chính là cách biểu diễn đúng.

**Khi thêm một đường ghi dữ liệu mới vào một bảng đã có ràng buộc kiểu này** (ví dụ thêm chức năng nhập liệu hàng loạt cho một bảng vốn đã có ràng buộc duy nhất trên cột cho phép để trống), phải rà lại xem đường ghi mới có tuân theo đúng quy tắc chuẩn hoá rỗng thành null như các đường ghi khác đã có hay không — dễ sót nếu đường ghi mới tự viết logic riêng thay vì tái sử dụng logic chuẩn hoá đã có.

## 3. Transaction phải bọc đúng phạm vi — không chỉ bọc "phần ghi"

Một lỗi phổ biến khi thêm giao dịch (transaction) để đảm bảo tính nguyên vẹn của nhiều bước ghi liên tiếp: chỉ bọc các câu lệnh ghi (thêm mới, cập nhật) trong giao dịch, nhưng câu lệnh đọc dùng để **quyết định sẽ ghi gì** lại nằm ngoài giao dịch, chạy trước khi giao dịch được mở.

Với 1 request chạy tại 1 thời điểm, cách làm này không có vấn đề gì. Nhưng khi có nhiều request chạy đồng thời trên cùng 1 tài nguyên, nhiều request có thể cùng đọc trúng cùng 1 kết quả (vì câu đọc quyết định không có cơ chế khoá), rồi mỗi request đều dựa trên kết quả đọc y hệt đó để ghi tiếp — dẫn tới dữ liệu xung đột nhau, hoặc tệ hơn, 1 trong các giao dịch "thua" trong cuộc đua bị bỏ qua âm thầm nhưng phía sau đó vẫn cố gắng đọc lại kết quả tưởng đã ghi thành công và gặp lỗi vì dữ liệu không tồn tại như mong đợi.

**Quy tắc:** nếu một câu lệnh đọc dùng để quyết định bước ghi tiếp theo trong cùng 1 luồng nghiệp vụ, câu lệnh đọc đó phải nằm **trong cùng giao dịch** với các bước ghi, và phải sử dụng cơ chế khoá dòng dữ liệu đang đọc (khoá đọc-để-ghi, thường được hỗ trợ qua cú pháp riêng của từng hệ quản trị cơ sở dữ liệu) để không cho request khác đọc trúng cùng kết quả cho tới khi giao dịch hiện tại hoàn tất (commit hoặc rollback). Không đủ để chỉ bọc "phần ghi" — phải bọc từ bước đọc quyết định trở đi.

Minh hoạ cấu trúc đúng (mã giả, cú pháp khoá dòng thật tuỳ hệ quản trị cơ sở dữ liệu — ví dụ `FOR UPDATE` là cú pháp phổ biến ở nhiều hệ quản trị quan hệ, cần xác nhận đúng cú pháp của hệ quản trị đang dùng):
```
// SAI — câu đọc quyết định nằm NGOÀI giao dịch, không khoá dòng
cho_du_lieu = TRUY_VAN("SELECT cho_trong FROM danh_sach_cho WHERE su_kien_id = ?", su_kien_id)
BAT_DAU_GIAO_DICH:
  GHI("UPDATE danh_sach_cho SET nguoi_dat = ? WHERE id = ?", nguoi_dung_id, cho_du_lieu.id)
KET_THUC_GIAO_DICH
// Nhiều request đồng thời có thể cùng đọc trúng "cho_du_lieu" giống nhau trước khi bất kỳ ai kịp ghi

// ĐÚNG — câu đọc quyết định nằm TRONG giao dịch, có khoá dòng đang đọc
BAT_DAU_GIAO_DICH:
  cho_du_lieu = TRUY_VAN_TRONG_GIAO_DICH(
    "SELECT cho_trong FROM danh_sach_cho WHERE su_kien_id = ? FOR UPDATE", su_kien_id
  )
  // Request khác cố đọc cùng dòng này sẽ phải CHỜ tới khi giao dịch hiện tại commit/rollback xong
  GHI_TRONG_GIAO_DICH("UPDATE danh_sach_cho SET nguoi_dat = ? WHERE id = ?", nguoi_dung_id, cho_du_lieu.id)
KET_THUC_GIAO_DICH
```

**Cách phát hiện lỗi loại này:** kiểm thử tuần tự với 1 luồng xử lý duy nhất sẽ luôn cho kết quả đúng — lỗi chỉ lộ ra khi có tải đồng thời thật (nhiều luồng xử lý cùng thao tác trên cùng tài nguyên trong cùng khoảng thời gian). Đây là lý do bắt buộc phải có công cụ kiểm thử hiệu năng giả lập nhiều người dùng đồng thời (không chỉ kiểm thử tuần tự từng trường hợp) đối với bất kỳ luồng nghiệp vụ nào có khả năng bị nhiều người cùng thao tác đồng thời trong thực tế (ví dụ: gán một tài nguyên duy nhất, đăng ký một suất giới hạn số lượng, xác nhận thanh toán).

## 4. Cú pháp SQL khác biệt giữa các hệ quản trị cơ sở dữ liệu

Không giả định cú pháp của 1 hệ quản trị cơ sở dữ liệu áp dụng được cho hệ quản trị khác, đặc biệt khi chuyển đổi hệ quản trị giữa các giai đoạn phát triển dự án (ví dụ từ cơ sở dữ liệu nhúng đơn giản sang hệ quản trị đầy đủ hơn phục vụ sản xuất). Những khác biệt thường gặp cần lưu ý: cú pháp "chèn nhưng bỏ qua nếu trùng" khác nhau giữa các hệ quản trị; hàm lấy thời gian hiện tại có tên và cách gọi khác nhau; định dạng chuỗi ngày giờ trả về khi truy vấn có thể khác nhau (có hay không có ký tự phân tách chuẩn theo định dạng quốc tế).

**Khi dự án có một tầng trung gian tự động dịch cú pháp giữa các hệ quản trị** (để mã nguồn viết theo 1 cú pháp chung rồi tự động chuyển đổi khi thực thi thật), cần lưu ý: không phải mọi đường gọi tới cơ sở dữ liệu đều đi qua tầng dịch này. Nếu có một cách gọi trực tiếp khác (ví dụ gọi trực tiếp bên trong khối giao dịch mà không qua hàm trung gian đã dịch cú pháp), đường gọi đó phải tự viết đúng cú pháp thật của hệ quản trị đang dùng, không dựa vào việc tầng trung gian sẽ tự động xử lý — vì đường gọi trực tiếp không đi qua tầng đó.

## 5. Xử lý ngày giờ với dữ liệu từ cơ sở dữ liệu

Khi cấu hình kết nối cơ sở dữ liệu trả về giá trị ngày giờ dưới dạng chuỗi ký tự (thay vì đối tượng ngày giờ đã được ngôn ngữ lập trình xử lý sẵn), cần đặc biệt cẩn trọng khi chuyển đổi chuỗi đó sang đối tượng ngày giờ để xử lý tiếp:

- Luôn lưu trữ thời gian trong cơ sở dữ liệu theo múi giờ chuẩn quốc tế (UTC), và chỉ chuyển đổi sang múi giờ địa phương ở tầng hiển thị cho người dùng cuối — không lưu trữ thời gian theo múi giờ địa phương trực tiếp trong cơ sở dữ liệu, vì máy chủ vận hành có thể chạy ở múi giờ khác với người dùng.
- Định dạng chuỗi ngày giờ trả về từ cơ sở dữ liệu (thường có dấu cách phân tách ngày và giờ) không phải lúc nào cũng đúng theo chuẩn định dạng quốc tế mà các thư viện xử lý ngày giờ trong ngôn ngữ lập trình mong đợi (chuẩn quốc tế thường dùng ký tự phân tách khác và có ký hiệu múi giờ rõ ràng ở cuối). Nếu chuyển đổi sai định dạng, các nền tảng/trình duyệt khác nhau có thể hiểu chuỗi đó theo cách khác nhau, dẫn tới kết quả không nhất quán tuỳ nơi chạy. Luôn chuyển đổi chuỗi về đúng định dạng chuẩn quốc tế trước khi đưa vào hàm xử lý ngày giờ của ngôn ngữ lập trình, không nối chuỗi một cách tuỳ tiện rồi hy vọng mọi nền tảng đều hiểu đúng như nhau.
- Khi cần so sánh "có phải hôm nay không" hoặc hiển thị ngày theo góc nhìn của người dùng ở một múi giờ cụ thể, luôn tính toán dựa trên múi giờ đó một cách tường minh — không dựa vào múi giờ mặc định của máy chủ đang chạy ứng dụng, vì máy chủ (đặc biệt khi chạy trên nền tảng điện toán đám mây) thường mặc định chạy theo múi giờ quốc tế, khác với múi giờ người dùng thực tế đang ở.

## 6. Tối ưu truy vấn — tránh N+1, tránh SELECT thừa

**Vấn đề N+1** xảy ra khi cần lấy dữ liệu liên quan cho một danh sách bản ghi, nhưng lại thực hiện 1 câu truy vấn riêng cho từng bản ghi trong danh sách đó bên trong một vòng lặp — dẫn tới số lượng câu truy vấn tăng tuyến tính theo kích thước danh sách. Cách đúng là gom toàn bộ nhu cầu dữ liệu liên quan vào 1 câu truy vấn duy nhất (dùng phép nối bảng, hoặc 1 câu truy vấn theo danh sách định danh), sau đó nhóm kết quả lại theo bản ghi gốc bằng logic ở tầng ứng dụng — chỉ cần 1 hoặc 2 câu truy vấn thay vì hàng chục/hàng trăm câu.

**Không lấy về những cột dữ liệu nặng khi không cần thiết**, đặc biệt cột lưu trữ dữ liệu nhị phân lớn (hình ảnh, tệp đính kèm lưu trực tiếp trong cơ sở dữ liệu) — chỉ truy vấn lấy cột đó khi thực sự cần trả về nội dung, không lấy kèm trong các câu truy vấn liệt kê/tổng hợp thông thường.

**Giữ nguyên các giới hạn tài nguyên đã có** (kích thước hồ kết nối cơ sở dữ liệu, giới hạn số bản ghi xử lý mỗi lần chạy tác vụ định kỳ) trừ khi có lý do rõ ràng cần điều chỉnh — không nới lỏng tuỳ tiện. Khi nghi ngờ một thay đổi mới sẽ làm tăng tải đáng kể lên cơ sở dữ liệu (một câu truy vấn nặng chạy trên mỗi request, một vòng lặp lồng nhau trên tập dữ liệu lớn), cần nêu rõ đánh đổi này cho người phụ trách dự án biết trước, không âm thầm chấp nhận rủi ro.

---

## Checklist nhanh — khi thay đổi lược đồ dữ liệu hoặc câu truy vấn

- [ ] Migration có kiểm tra tồn tại trước khi tạo mới (chạy lại nhiều lần không lỗi) không?
- [ ] Cột cho phép "chưa nhập" và tham gia ràng buộc duy nhất có dùng null thay vì chuỗi rỗng không, và mọi đường ghi dữ liệu vào cột đó có chuẩn hoá nhất quán không?
- [ ] Nếu đổi ràng buộc duy nhất từ cột này sang cột khác, có thêm ràng buộc mới trước rồi mới xoá ràng buộc cũ không?
- [ ] Câu lệnh đọc dùng để quyết định bước ghi tiếp theo có nằm trong cùng giao dịch và có khoá dòng đang đọc không?
- [ ] Cú pháp SQL có đúng với hệ quản trị đang dùng thật, không giả định theo hệ quản trị khác?
- [ ] Có vòng lặp nào đang truy vấn cơ sở dữ liệu nhiều lần cho từng phần tử (N+1) mà lẽ ra gom được thành 1 câu không?

---

*Xem tiếp: [`06-api-design.md`](06-api-design.md) — thiết kế API.*
