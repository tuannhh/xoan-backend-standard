# Xoăn Backend Standard Skill

Bộ quy chuẩn giúp AI coding agent (Claude Code, Codex, Cursor, VS Code Copilot, Antigravity, Kiro...) viết/sửa code backend **đúng quy chuẩn Xoăn** khi phát triển ứng dụng trong hệ sinh thái Xoăn — áp dụng xuyên suốt vòng đời dự án, không chỉ lúc khởi tạo.

Khi được cài, AI sẽ tự động áp dụng:
- 6 nguyên tắc nền tảng (ưu tiên Bảo mật > Chịu lỗi > Hiệu năng > Tiện lợi, sửa đúng gốc rễ, không tự bịa, luôn backtest, bảo mật mặc định, module hoá sớm)
- Quy trình riêng cho 3 tình huống: khởi tạo dự án mới / vào 1 dự án cũ / thêm tính năng-sửa lỗi ở dự án đang chạy
- 13 file chuyên đề: bảo mật, xử lý lỗi, cấu trúc project, database, API design, testing, hiệu năng, vận hành, CI/CD
- Quy định bắt buộc về `memory-bank/` (tài liệu tri thức dự án) + bộ template đầy đủ để sao chép vào project mới
- Checklist kiểm tra trước khi báo cáo 1 nhiệm vụ là "đã hoàn thành"

## Cấu trúc

```
xoan-backend-standard/
├── SKILL.md                              # Chuẩn Agent Skills — Claude Code / Codex
├── AGENTS.md                             # Chuẩn AGENTS.md — Cursor, Antigravity, Copilot, Zed...
├── install.sh                            # Script cài tự động cho từng agent
└── references/
    ├── 01-core-principles.md             # 6 nguyên tắc nền tảng, kèm ví dụ code trước/sau
    ├── 02-security-baseline.md           # Auth/authz, chống injection, secrets, IDOR, SSRF, audit log
    ├── 03-error-handling-resilience.md   # Xử lý lỗi, log, khả năng chịu lỗi
    ├── 04-project-structure.md           # Cấu trúc thư mục mã nguồn + dữ liệu
    ├── 05-database-rules.md              # Thiết kế/thao tác DB, transaction, khoá dòng
    ├── 06-api-design.md                  # Thiết kế API, hình dạng response
    ├── 07-testing-strategy.md            # Chiến lược kiểm thử
    ├── 08-performance-scaling.md         # Cache, indexing, phân trang, hàng đợi, giới hạn payload
    ├── 09-operations-reliability.md      # Health-check, graceful shutdown, observability, DI
    ├── 10-phase-init-new-project.md      # Quy trình khởi tạo dự án mới
    ├── 11-phase-refactor-legacy.md       # Quy trình refactor dự án cũ
    ├── 12-phase-maintenance.md           # Quy trình duy trì/phát triển thường xuyên
    ├── 13-devops-lifecycle.md            # CI/CD, code review, rollback, backup/DR
    ├── 20-memory-bank-mandate.md         # Quy định bắt buộc về tài liệu tri thức dự án
    └── 21-memory-bank-template/          # Bộ khung file mẫu để sao chép khi khởi tạo memory-bank
```

## Cài đặt

Clone / copy repo về máy một lần, rồi chạy script cài cho agent bạn dùng:

```bash
cd ~/Xoan-backend-standard
```

| Agent | Lệnh cài | Cơ chế |
|---|---|---|
| **Claude Code** | `./install.sh claude` | Skill tại `~/.claude/skills/xoan-backend-standard` (toàn máy) |
| **Codex** | `./install.sh codex` | Skill tại `~/.codex/skills/xoan-backend-standard` (toàn máy) |
| **Cursor** | `./install.sh cursor /đường/dẫn/project` | Rule tại `.cursor/rules/` + docs trong project |
| **VS Code (Copilot)** | `./install.sh vscode /đường/dẫn/project` | Instructions tại `.github/instructions/` |
| **Kiro** | `./install.sh kiro /đường/dẫn/project` | Steering tại `.kiro/steering/` |
| **Antigravity / agent khác đọc AGENTS.md** | `./install.sh agents /đường/dẫn/project` | Nối/tạo `AGENTS.md` trong project |

Sau khi cài, agent sẽ tự đọc `references/` theo lĩnh vực đang động vào — xem bảng tra cứu trong [SKILL.md](SKILL.md) hoặc [AGENTS.md](AGENTS.md).

## Nguyên tắc khi dùng bộ quy chuẩn này

- Toàn bộ nội dung viết bằng tiếng Việt, kèm ví dụ code/pseudocode ở mục có logic phức tạp dễ hiểu sai — các đoạn này là mã giả/minh hoạ, cần điều chỉnh đúng cú pháp theo ngôn ngữ/framework thực tế của project, không phải chép nguyên văn.
- Không phải tài liệu đọc 1 lần rồi thôi — quay lại tra cứu mỗi khi cần, đặc biệt trước khi báo cáo 1 nhiệm vụ là "đã hoàn thành".
- Quy tắc riêng của 1 project cụ thể (ngoài bộ tổng quát này) thuộc về `memory-bank/11-coding-rules.md` của chính project đó — không sửa vào bộ quy chuẩn chung này.
