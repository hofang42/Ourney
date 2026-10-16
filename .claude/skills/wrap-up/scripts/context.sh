#!/usr/bin/env bash
# Bối cảnh cho skill wrap-up: ngày, nhánh, dòng task, commit hôm nay (SHA ngắn), khác biệt với origin/main.
# Chỉ đọc, không cần mạng, luôn exit 0: một lệnh lỗi sẽ làm Claude Code huỷ cả skill.
here=$(cd "$(dirname "$0")" && pwd)
R=$(git -C "$here" rev-parse --show-toplevel 2>/dev/null)
[ -f "$R/docs/TASKS.md" ] || R="${CLAUDE_PROJECT_DIR:-$PWD}"
cd "$R" 2>/dev/null || exit 0

echo "Ngày: $(date '+%Y-%m-%d %H:%M %Z')"
b=$(git branch --show-current 2>/dev/null)
echo "Nhánh: ${b:-(không rõ)}"
id=$(printf '%s' "$b" | sed -nE 's#^(feat|fix|chore)/([A-Za-z][0-9]+)-.*#\2#p' | tr 'a-z' 'A-Z')
if [ -n "$id" ]; then
  grep -E "^\| $id \|" docs/TASKS.md 2>/dev/null || echo "(không thấy $id trong docs/TASKS.md)"
fi
echo "--- Commit hôm nay (SHA ngắn)"
git log --format='%h %s' --since=midnight 2>/dev/null | head -20
echo "--- Khác origin/main"
git diff --stat origin/main...HEAD 2>/dev/null | tail -15
echo "--- Chưa commit"
git status --short 2>/dev/null | head -20
exit 0
