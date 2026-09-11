#!/usr/bin/env bash
# Cài quy chuẩn Xoăn Backend Standard cho coding agent.
#
# Cách dùng:
#   ./install.sh <agent> [thư-mục-project]
#
#   <agent>: claude | codex | cursor | vscode | kiro | antigravity | agents
#   [thư-mục-project]: bắt buộc với cursor/vscode/kiro/antigravity/agents
#                      (mặc định: thư mục hiện tại)
#
# Ví dụ:
#   ./install.sh claude                    # cài toàn máy cho Claude Code
#   ./install.sh cursor ~/projects/my-app  # cài cho Cursor trong project my-app

set -euo pipefail

SKILL_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
AGENT="${1:-}"
PROJECT="${2:-$(pwd)}"

if [ -z "$AGENT" ]; then
  grep '^#' "$0" | sed 's/^# \{0,1\}//' | head -12
  exit 1
fi

# Copy toàn bộ quy chuẩn vào project (docs/xoan-backend-standard) để agent đọc references
copy_docs() {
  local dest="$PROJECT/docs/xoan-backend-standard"
  mkdir -p "$dest"
  cp "$SKILL_DIR/AGENTS.md" "$dest/xoan-backend-rules.md"
  cp -R "$SKILL_DIR/references" "$dest/"
  echo "→ Đã copy quy chuẩn vào $dest"
}

# Tạo file rule trỏ tới bộ quy chuẩn, kèm quy tắc cốt lõi inline
rule_body() {
  cat <<'EOF'
Mọi code backend cho ứng dụng Xoăn phải tuân theo quy chuẩn Xoăn Backend Standard.

TRƯỚC KHI viết/sửa bất kỳ code backend nào, đọc: docs/xoan-backend-standard/xoan-backend-rules.md
và file chuyên đề tương ứng trong docs/xoan-backend-standard/references/ (bảng tra cứu ở cuối file rules).

6 nguyên tắc nền tảng không được vi phạm:
- Ưu tiên khi xung đột: Bảo mật > Chịu lỗi (hệ thống không sập) > Hiệu năng > Tiện lợi/tốc độ code.
- Sửa code đúng gốc rễ (root cause) VÀ phạm vi ảnh hưởng nhỏ nhất — cả 2 tiêu chí đồng thời.
- Không tự bịa/suy diễn — mọi thay đổi phải có nguồn xác thực (yêu cầu trực tiếp, bug tái hiện được,
  hoặc đọc code/tài liệu trích dẫn cụ thể). Không chắc → đi xác minh hoặc hỏi lại, không đoán.
- Luôn backtest logic sau khi code xong — dò lại MỌI nhánh trạng thái bị ảnh hưởng, không chỉ nhánh
  vừa sửa; backtest dưới tải đồng thời thật nếu liên quan giao dịch nhiều người dùng.
- Bảo mật mặc định — không tin dữ liệu client cho trường có ý nghĩa phân quyền, server luôn tự tính lại.
- Module hoá ngay từ lần dùng thứ 2, không đợi "đủ lớn mới tách"; tách cơ học trước, tối ưu sau.

Mỗi project phải có memory-bank/ riêng (xem references/20-memory-bank-mandate.md); quy tắc riêng của
project ghi vào memory-bank/11-coding-rules.md của chính project đó, không sửa vào bộ quy chuẩn chung.
EOF
}

# cp trên macOS có thể in lỗi từng file nhưng vẫn trả mã thành công khi copy nhiều nguồn.
# Xác minh lại để không báo cài đặt thành công khi skill toàn máy đang cũ hoặc thiếu file.
verify_global_install() {
  local dest="$1"
  local source target
  for source in SKILL.md references; do
    target="$dest/$source"
    if ! diff -qr "$SKILL_DIR/$source" "$target" >/dev/null; then
      echo "✗ Cài đặt chưa hoàn tất: $target không khớp với bản nguồn"
      return 1
    fi
  done
}

case "$AGENT" in
  claude)
    DEST="$HOME/.claude/skills/xoan-backend-standard"
    mkdir -p "$DEST"
    cp -R "$SKILL_DIR/SKILL.md" "$SKILL_DIR/references" "$DEST/"
    verify_global_install "$DEST"
    echo "✓ Claude Code: đã cài skill vào $DEST"
    ;;
  codex)
    DEST="$HOME/.codex/skills/xoan-backend-standard"
    mkdir -p "$DEST"
    cp -R "$SKILL_DIR/SKILL.md" "$SKILL_DIR/references" "$DEST/"
    verify_global_install "$DEST"
    echo "✓ Codex: đã cài skill vào $DEST"
    ;;
  cursor)
    copy_docs
    mkdir -p "$PROJECT/.cursor/rules"
    {
      echo "---"
      echo "description: Quy chuẩn Backend Xoăn — áp dụng khi viết/sửa code backend"
      echo "alwaysApply: true"
      echo "---"
      rule_body
    } > "$PROJECT/.cursor/rules/xoan-backend-standard.mdc"
    echo "✓ Cursor: đã tạo .cursor/rules/xoan-backend-standard.mdc"
    ;;
  vscode)
    copy_docs
    mkdir -p "$PROJECT/.github/instructions"
    {
      echo "---"
      echo "applyTo: \"**\""
      echo "---"
      rule_body
    } > "$PROJECT/.github/instructions/xoan-backend-standard.instructions.md"
    echo "✓ VS Code (Copilot): đã tạo .github/instructions/xoan-backend-standard.instructions.md"
    ;;
  kiro)
    copy_docs
    mkdir -p "$PROJECT/.kiro/steering"
    rule_body > "$PROJECT/.kiro/steering/xoan-backend-standard.md"
    echo "✓ Kiro: đã tạo .kiro/steering/xoan-backend-standard.md"
    ;;
  antigravity|agents)
    copy_docs
    if [ -f "$PROJECT/AGENTS.md" ]; then
      if ! grep -q "Xoăn Backend Standard" "$PROJECT/AGENTS.md"; then
        { echo ""; echo "## Quy chuẩn Backend Xoăn"; echo ""; rule_body; } >> "$PROJECT/AGENTS.md"
        echo "✓ Đã nối quy chuẩn vào AGENTS.md có sẵn"
      else
        echo "✓ AGENTS.md đã có quy chuẩn Xoăn — bỏ qua"
      fi
    else
      { echo "# AGENTS.md"; echo ""; echo "## Quy chuẩn Backend Xoăn"; echo ""; rule_body; } > "$PROJECT/AGENTS.md"
      echo "✓ Đã tạo AGENTS.md (Antigravity/Codex/Zed... đọc file này)"
    fi
    ;;
  *)
    echo "Agent không hỗ trợ: $AGENT (dùng: claude | codex | cursor | vscode | kiro | antigravity | agents)"
    exit 1
    ;;
esac
