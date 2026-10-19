---
name: recall
description: Gọi lại trí nhớ trước khi làm việc trên Ourney — task trong docs/TASKS.md, việc còn dở từ nhật ký, bài học đã ghi, và tài liệu áp cho task (trỏ tới nguồn, không chép). Dùng khi bắt đầu một task có ID trong docs/TASKS.md, khi user nói "tiếp tục", "lần trước", "nhớ lại", hoặc gõ /recall.
argument-hint: "[task ID hoặc chủ đề]"
allowed-tools:
  - Bash(bash ${CLAUDE_SKILL_DIR}/scripts/context.sh *)
---

# Recall — nhớ lại trước khi làm (Ourney)

Chủ đề: $ARGUMENTS (trống thì lấy task ID từ tên nhánh bên dưới).

**Skill khác rule.** Skill này chỉ chứa quy trình gọi lại trí nhớ. Rule của repo (`CLAUDE.md`, `.claude/rules/`) do thành viên khác phụ trách. Có rule thì Claude Code tự nạp, và rule thắng nếu mâu thuẫn với skill. Skill không chép, không viết, không sửa rule.

MEM = thư mục memory của phiên (mục Memory trong system prompt). Nhật ký nằm ở `MEM/journal/YYYY-MM.md`, do skill `wrap-up` ghi. Bài học do skill `lesson` ghi.

## Bối cảnh tự nạp

!`bash ${CLAUDE_SKILL_DIR}/scripts/context.sh`

## Quy trình

1. **Task:** task nằm ở `docs/TASKS.md`. Đọc dòng của task (cột "Xong khi", "Phụ thuộc") và mã FR/NFR liên quan trong `docs/SRS.md`. Nhánh không chứa task ID và user không nêu thì hỏi user đang làm task nào.
2. **Việc còn dở:** đọc mục nhật ký gần nhất của task này trong `MEM/journal/` (file mới nhất trước), lấy dòng "Còn dở".
3. **Rule và tài liệu áp cho task:** rule không có `paths` được Claude Code nạp sẵn, rule có `paths` chỉ nạp khi đụng file khớp; chỉ cần nêu rule nào áp cho phần sắp sửa. Tài liệu dự án thì tra theo vùng sắp đụng: `supabase/` → `docs/SRS.md` §6.4 và `docs/contracts/schema.md`; `lib/features/` → `apps/mobile/lib/features/README.md`; sửa ngoài vùng mình → `docs/TASKS.md` §1. Chỉ ghi tên rule hoặc file + số mục, không chép nội dung.
4. **Bài học của mình:** `grep -ril -E "<kw1>|<kw2>|<kw3>" MEM` với từ khoá là task ID, tên feature, plugin, bảng DB, loại lỗi. Đọc trọn tối đa 5 file khớp nhất, vì file memory không tự nạp.
5. **Đã chốt:** `docs/adr/`, `docs/runbooks/`, và quyết định ghi trong nhật ký.
6. **Kiểm memory còn đúng:** memory nhắc file, nhánh, PR, commit SHA thì kiểm còn tồn tại (`ls`, `git branch -a`, `git cat-file -t <sha>`, `gh pr view`) trước khi dựa vào. Sai thì nói ra và sửa memory.
7. **Trả lời ngắn**, tối đa khoảng 14 dòng, theo 6 mục (mục nào trống thì bỏ):
   - **Task:** ID, "Xong khi", phụ thuộc
   - **Lần trước dừng ở:** ...
   - **Rule, tài liệu áp cho việc này:** tên rule, hoặc file + số mục
   - **Bài học của mình:** mỗi dòng một bài học, kèm link file memory
   - **Đã chốt, đừng lật lại:** ADR, runbook, nhật ký
   - **Bẫy đã gặp:** chuyện gì, ở đâu

   Không tìm thấy gì thì nói thẳng "chưa có ghi chú nào về <chủ đề>".
8. Bài học mâu thuẫn với rule hoặc tài liệu dự án thì **rule và tài liệu thắng**: báo user và sửa memory.
9. Giữ những gì vừa tìm được suốt task, không chỉ đọc cho biết.
