# 07 — Triển khai & Hạ tầng

## Tổng quan môi trường

| Môi trường | Trạng thái | Cơ sở dữ liệu | Ghi chú |
|---|---|---|---|
| | | | |

## Biến môi trường / Cấu hình

> Tách 2 tầng theo [`../04-project-structure.md`](../04-project-structure.md) mục 5 và [`../02-security-baseline.md`](../02-security-baseline.md) mục 4 — tầng hiếm đổi commit được, tầng hay đổi/nhạy cảm không commit.

**Biến hiếm đổi (commit được):**

| Biến | Ý nghĩa | Giá trị mặc định |
|---|---|---|
| | | |

**Cấu hình hay đổi/nhạy cảm (không commit, nạp lúc chạy):**

| Khoá cấu hình | Ý nghĩa | Bắt buộc? |
|---|---|---|
| | | |

## Quy trình khởi động môi trường phát triển cục bộ

[Các bước cụ thể — lệnh chạy, điều kiện tiên quyết.]

## Quy trình triển khai lên môi trường thật

[Các bước cụ thể, kèm cảnh báo nếu có thao tác không thể hoàn tác hoặc cần xác nhận trước khi thực hiện.]

## Việc còn treo (rủi ro/nợ kỹ thuật đã biết nhưng chưa xử lý)

[Liệt kê rõ — ví dụ cấu hình tạm thời chưa được thay bằng giải pháp gốc rễ, thông tin nhạy cảm đã lỡ lộ cần thu hồi/đổi mới.]

---

## Ví dụ đã điền (tham khảo mức độ chi tiết mong muốn — xoá phần này sau khi đã điền nội dung thật của dự án)

### Tổng quan môi trường

| Môi trường | Trạng thái | Cơ sở dữ liệu | Ghi chú |
|---|---|---|---|
| Development (máy host) | Dev | MySQL/Redis local | `config.Development.json`, HTTP |
| TestLocal (k8s nội bộ) | Kiểm thử | MySQL/Redis riêng | `config.TestLocal.json`, K8s local cluster |
| TestOnline (k8s online) | Kiểm thử | MySQL/Redis riêng | `config.TestOnline.json`, K8s online cluster |
| Production (k8s production) | Chính thức | MySQL/Redis riêng | `config.Production.json`, K8s production cluster, HTTPS |

> Tên môi trường viết hoa chữ cái đầu mỗi từ (PascalCase). Mọi config (kết nối DB, logLevel, secret, config app) dồn vào file `config.{APP_ENVIRONMENT}.json`. File `.env` duy nhất chỉ chứa các biến phải biết TRƯỚC khi load file JSON.

### Nguyên tắc: duy nhất 1 file `.env` (không có `.env.example`)

Toàn bộ project chỉ duy nhất 1 file `.env` (không tạo `.env.example`). File này chỉ chứa **các config hiếm khi đổi kể cả khi thay đổi môi trường** (ví dụ `APP_ENVIRONMENT`, `PORT`, `CONFIG_DIR`) — những biến cần biết TRƯỚC khi load file JSON (gà-trứng). Tất cả config khác dồn vào file `config.{APP_ENVIRONMENT}.json`.

**Production (k8s):** file `.env` không cần tồn tại trong container. k8s set các biến này trực tiếp qua `env` của Deployment. Scripts dùng `--env-file-if-exists=.env` (Node 22.9+) — có file thì load (dev), không có thì dùng env ngoài (k8s).

### Biến hiếm đổi (commit được)

| Biến | Ý nghĩa | Giá trị mặc định |
|---|---|---|
| `APP_ENVIRONMENT` | Development / TestLocal / TestOnline / Production — chọn file config tương ứng | Development |
| `PORT` | Cổng server | — |
| `CONFIG_DIR` | (Optional) Thư mục chứa file config JSON | thư mục `config/` ở gốc project |

> 3 biến trên nằm trong `.env` (không commit) vì cần biết trước khi load file JSON (gà-trứng). Tất cả config khác nằm trong file `config.{APP_ENVIRONMENT}.json`.

### Cấu hình hay đổi/nhạy cảm (không commit, nạp lúc chạy)

| Khoá cấu hình | Ý nghĩa | Bắt buộc? |
|---|---|---|
| `database:password` | Mật khẩu MySQL | Có |
| `session:secret` | Ký session cookie | Có (production phải khác giá trị mặc định dev) |

### Việc còn treo (ví dụ)

- `session:cookie_secure_override: false` đang bật tạm ở TestLocal vì ingress chưa forward đúng header `X-Forwarded-Proto` — chờ đội hạ tầng sửa ingress rồi gỡ override này (workaround, không phải fix gốc rễ).

