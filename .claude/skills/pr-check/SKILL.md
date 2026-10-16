---
name: pr-check
description: Kiểm một nhánh Ourney trước khi mở PR — chạy đúng các job CI mà thay đổi đụng tới (đọc từ .github/workflows/ci.yml), rà checklist của PR template, xem chủ vùng theo CODEOWNERS, rồi soạn sẵn PR body và commit message. Chạy khi user gõ /pr-check trước khi push hoặc mở PR.
argument-hint: "[task ID]"
disable-model-invocation: true
allowed-tools:
  - Bash(bash ${CLAUDE_SKILL_DIR}/scripts/context.sh *)
  - Bash(git fetch origin *)
  - Bash(git rev-list *)
  - Bash(flutter pub get *)
  - Bash(flutter analyze *)
  - Bash(flutter test *)
  - Bash(dart pub get *)
  - Bash(dart analyze *)
  - Bash(dart test *)
  - Bash(dart run build_runner build *)
  - Bash(dart run tool/gen_l10n.dart *)
  - Bash(deno run --allow-read supabase/scripts/check-streak-vectors.ts *)
  - Bash(deno check *)
  - Bash(supabase test db *)
  - Bash(bash scripts/tests/run.sh *)
---

# PR check — kiểm trước khi mở PR (Ourney)

Task: $ARGUMENTS (trống thì lấy task ID từ tên nhánh bên dưới).

**Skill khác rule.** Skill này chỉ chứa quy trình kiểm. Rule của repo (`CLAUDE.md`, `.claude/rules/`) do thành viên khác phụ trách. Có rule thì Claude Code tự nạp, và rule thắng nếu mâu thuẫn với skill. Skill không chép, không viết, không sửa rule.

**Nguồn chuẩn đọc lúc chạy, không chép vào skill:** lệnh CI ở `.github/workflows/ci.yml`, các mục PR ở `.github/pull_request_template.md`, chủ vùng ở `.github/CODEOWNERS`. Các file đó đổi thì skill vẫn đúng.

## Bối cảnh tự nạp

!`bash ${CLAUDE_SKILL_DIR}/scripts/context.sh`

## Quy trình

1. **Điều kiện trước:**
   - Đang ở `main` → dừng, nhờ user tạo nhánh (đặt tên theo `docs/TASKS.md` hoặc `docs/SRS.md` §6.2). `main` không nhận push thẳng (TASKS §6).
   - Chạy `git fetch origin main`, rồi `git rev-list --left-right --count origin/main...HEAD` để biết nhánh có tụt sau `main` không.
   - Tụt sau `main` thì HỎI user có rebase không (SRS §6.2 bước 5). Có thay đổi chưa commit thì không rebase, báo user. Không bao giờ tự force-push.
2. **Chọn job CI:** đọc `ci.yml`, chọn job theo vùng bị đụng ở bối cảnh trên. Gợi ý ánh xạ, kiểm lại với `ci.yml` và `pubspec.yaml` trước khi dùng:

   | Vùng đụng | Job |
   |---|---|
   | `packages/ourney_core/` | core, **và** mobile (`apps/mobile` dùng `ourney_core` qua `path:`) |
   | `docs/contracts/` | supabase (kiểm streak vectors) và core (`streak_vectors_test`) |
   | `supabase/` | supabase |
   | `apps/mobile/` | mobile |
   | `scripts/`, `.github/workflows/` | repo tooling |
   | Chỉ `docs/` khác, `.claude/` | không job code nào; vẫn làm bước 4–6 |

   CI chạy mọi job ở mọi PR. Job không chạy local thì ghi rõ "không chạy local" trong báo cáo, đừng coi là xanh.
3. **Chạy từng step** của job đã chọn đúng như các dòng `run:` trong `ci.yml`, trong `working-directory` của job:
   - `FLUTTER_VERSION` trong `ci.yml` khác bản Flutter local → vẫn chạy, nhưng ghi "local X ≠ CI Y" vì kết quả analyze và codegen có thể khác.
   - Step codegen hoặc l10n làm đổi file (`git status` có file mới hoặc đổi) → đó là file phải commit. Liệt kê cho user, không tự commit.
   - Thiếu công cụ (flutter, dart, deno, supabase, docker) → không bỏ qua im lặng, ghi "⚠ chưa chạy: thiếu <công cụ>".
   - Step cần Docker (`supabase start`, actionlint) → hỏi user trước khi khởi động. Chạy xong thì dừng lại như CI (`supabase stop --no-backup`).
   - Một step đỏ → dừng job đó, đọc lỗi, đề xuất sửa. Sửa xong chạy lại cả job từ đầu.
4. **Rà checklist PR template:** đọc template lúc chạy. Với từng mục, tìm bằng chứng thật:
   - Vùng sở hữu: so nhóm file theo CODEOWNERS ở bối cảnh với người làm (git user.name chưa chắc là GitHub handle, chưa chắc thì hỏi). File ngoài vùng → ghi "cần <chủ vùng> review". Phần dò chủ vùng là ước lượng; mẫu CODEOWNERS khác `*` và `/đường-dẫn` thì đọc thẳng file.
   - Secret: mở từng file trong mục "Nghi có secret". Anon key Supabase là public theo SRS §2.3; các loại key khác thì phải gỡ khỏi diff.
   - Thư viện mới: dòng thêm vào `pubspec.yaml` → PR cần link docs (pub.dev) cho từng thư viện.
   - Bảng mới: với từng bảng trong "Migration mới", tìm `enable row level security` cho bảng đó và test nhắc tới bảng đó trong `supabase/tests/`.
   - UI: diff đụng màn hình hoặc widget → cần ảnh/video, hoặc ghi `ios-verify pending` / `android-verify pending`.
5. **Soạn PR body** theo đúng các mục của template, ghi vào `$(git rev-parse --git-dir)/PR_BODY.md` (nằm trong `.git` nên không bị commit):
   - "Làm gì": task ID và mã FR/NFR (từ `docs/TASKS.md`, `docs/SRS.md`).
   - "Bằng chứng test": chỉ tick ô có lệnh đã chạy xanh, ghi lệnh và kết quả ngắn (vd. "`flutter test`: 214 passed"). Ô chưa chạy được thì để trống, ghi lý do.
6. **Commit message** dạng Conventional Commits (SRS §6.2 bước 5): `<type>(<scope>): <subject>`, body ghi đủ chi tiết kỹ thuật. Skill **không** tự commit, push hay tạo PR. Chỉ đưa lệnh để user chạy:

   ```bash
   git push -u origin <nhánh>
   gh pr create --base main --title "<tiêu đề>" --body-file "$(git rev-parse --git-dir)/PR_BODY.md"
   ```

   User nói rõ "commit", "push" hoặc "tạo PR giúp" thì mới làm.
7. **Báo cáo** bằng bảng `| Job / Mục | Lệnh | Kết quả | Ghi chú |`: ✅ đã chạy xanh, ❌ đỏ, ⚠ chưa chạy được (kèm lý do), ⏭ không liên quan. Chỉ kết luận "sẵn sàng mở PR" khi các job liên quan không có ❌ hay ⚠; ngược lại nói rõ còn thiếu gì. Bảng này dùng lại được cho dòng "Bằng chứng" của `/wrap-up`.
