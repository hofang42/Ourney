#!/usr/bin/env bash
# Bối cảnh cho skill pr-check: nhánh, task, độ lệch với origin/main, file đổi, vùng, chủ vùng,
# dependency mới, bảng mới, file nghi có secret, công cụ local.
# Chỉ đọc, không cần mạng (dùng ref origin/main đang có), luôn exit 0: một lệnh lỗi sẽ làm
# Claude Code huỷ cả skill.
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
echo "Người làm (git user.name): $(git config user.name 2>/dev/null)"

mb=""
if git rev-parse -q --verify origin/main >/dev/null 2>&1; then
  mb=$(git merge-base origin/main HEAD 2>/dev/null)
  git rev-list --left-right --count origin/main...HEAD 2>/dev/null |
    awk '{ print "So với origin/main (ref local, chưa fetch): sau " $1 " commit, trước " $2 " commit" }'
else
  echo "(không có ref origin/main)"
fi

# Mọi file khác merge-base: đã commit, staged, chưa stage, chưa track.
files=$({
  [ -n "$mb" ] && git diff --name-only "$mb" HEAD
  git diff --name-only --cached
  git diff --name-only
  git ls-files --others --exclude-standard
} 2>/dev/null | grep . | sort -u)
n=$(printf '%s\n' "$files" | grep -c .)
echo "--- File thay đổi: $n"
printf '%s\n' "$files" | head -60

if [ "$n" -gt 0 ]; then
  echo "--- Vùng bị đụng (số file)"
  printf '%s\n' "$files" | awk -F/ '
    { a = $1
      if (NF > 2 && ($1 == "apps" || $1 == "packages" || $1 == "docs" || $1 == ".github" || $1 == ".claude")) a = $1 "/" $2
      c[a]++ }
    END { for (k in c) print "  " k ": " c[k] }' | sort

  if [ -f .github/CODEOWNERS ]; then
    echo "--- Chủ vùng theo .github/CODEOWNERS (dòng khớp cuối cùng thắng; chỉ hiểu mẫu * và /đường-dẫn)"
    printf '%s\n' "$files" | awk '
      NR == FNR { if ($0 !~ /^[[:space:]]*(#|$)/) { k++; pat[k] = $1; $1 = ""; own[k] = substr($0, 2) } next }
      { f = "/" $0; o = "(không có chủ)"
        for (i = 1; i <= k; i++) {
          p = pat[i]
          if (p == "*" || f == p || (substr(p, length(p)) == "/" && index(f, p) == 1)) o = own[i]
        }
        print o "\t" $0 }' .github/CODEOWNERS - |
      sort | awk -F'\t' '$1 != prev { print "  " $1 ":"; prev = $1 } { print "    " $2 }'
  fi
fi

if [ -n "$mb" ]; then
  deps=$(git diff -U0 "$mb" -- '*pubspec.yaml' 2>/dev/null | grep -E '^\+[^+]' | grep -vE '^\+[[:space:]]*(#|$)')
  if [ -n "$deps" ]; then
    echo "--- Dòng thêm vào pubspec.yaml"
    printf '%s\n' "$deps" | head -20
  fi

  mig=$({
    git diff --name-only --diff-filter=A "$mb" -- supabase/migrations
    git ls-files --others --exclude-standard -- supabase/migrations
  } 2>/dev/null | grep '\.sql$' | sort -u)
  if [ -n "$mig" ]; then
    echo "--- Migration mới và bảng tạo trong đó"
    for m in $mig; do
      t=$(grep -hoiE 'create table( if not exists)? +[a-z0-9_."]+' "$m" 2>/dev/null | awk '{ print $NF }' | tr '\n' ' ')
      echo "  $m: ${t:-(không có create table)}"
    done
  fi

  # Chỉ in tên file và số dòng khớp, không in nội dung, để secret không lọt vào hội thoại.
  pat='service_role|PRIVATE KEY|eyJ[A-Za-z0-9_-]{20,}\.|SMTP_PASS|sk_live_|ANDROID_KEYSTORE'
  sus=$({
    git diff -U0 "$mb" 2>/dev/null |
      awk '/^\+\+\+ / { f = substr($0, 7); next } /^\+/ { print f "\t" substr($0, 2) }' |
      grep -E "$pat" | cut -f1
    git ls-files -z --others --exclude-standard 2>/dev/null | xargs -0 -r grep -lIE "$pat" 2>/dev/null
  } | grep -v '^\.claude/skills/pr-check/' | sort | uniq -c)
  if [ -n "$sus" ]; then
    echo "--- Nghi có secret (chỉ tên file; mở từng file xem lại)"
    printf '%s\n' "$sus"
  fi
fi

echo "--- Công cụ local"
echo "  CI: $(grep -oE 'FLUTTER_VERSION: *[0-9.]+' .github/workflows/ci.yml 2>/dev/null | head -1)"
for t in flutter dart supabase deno docker shellcheck; do
  if command -v "$t" >/dev/null 2>&1; then echo "  $t: có"; else echo "  $t: KHÔNG CÓ"; fi
done
if command -v flutter >/dev/null 2>&1; then echo "  local: $(flutter --version 2>/dev/null | head -1)"; fi
exit 0
