#!/usr/bin/env bash
# Bối cảnh cho skill recall: nhánh, dòng task trong docs/TASKS.md, commit gần nhất, file đang sửa.
# Chỉ đọc, không cần mạng, luôn exit 0: một lệnh lỗi sẽ làm Claude Code huỷ cả skill.
here=$(cd "$(dirname "$0")" && pwd)
R=$(git -C "$here" rev-parse --show-toplevel 2>/dev/null)
[ -f "$R/docs/TASKS.md" ] || R="${CLAUDE_PROJECT_DIR:-$PWD}"
cd "$R" 2>/dev/null || exit 0

b=$(git branch --show-current 2>/dev/null)
echo "Nhánh: ${b:-(không rõ)}"
id=$(printf '%s' "$b" | sed -nE 's#^(feat|fix|chore)/([A-Za-z][0-9]+)-.*#\2#p' | tr 'a-z' 'A-Z')
if [ -n "$id" ]; then
  grep -E "^\| $id \|" docs/TASKS.md 2>/dev/null || echo "(không thấy $id trong docs/TASKS.md)"
fi
echo "--- 5 commit gần nhất"
git log --oneline -5 2>/dev/null
echo "--- File đang sửa"
git status --short 2>/dev/null | head -15
exit 0
