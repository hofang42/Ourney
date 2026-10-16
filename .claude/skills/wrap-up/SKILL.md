---
name: wrap-up
description: Tổng kết cuối phiên làm Ourney — ghi nhật ký theo task ID và commit SHA, bằng chứng test, quyết định, chỗ Claude sai và việc còn dở vào memory local. Chạy khi user gõ /wrap-up trước khi rời phiên.
argument-hint: "[ghi chú thêm]"
disable-model-invocation: true
allowed-tools:
  - Bash(bash ${CLAUDE_SKILL_DIR}/scripts/context.sh *)
---

# Wrap-up — tổng kết phiên (Ourney)

Ghi chú thêm: $ARGUMENTS

MEM = thư mục memory của phiên (mục Memory trong system prompt). Auto memory đang tắt thì dừng và báo user.

**Skill khác rule.** Skill này chỉ chứa quy trình ghi ghi chú vào MEM (local, không commit). Rule của repo (`CLAUDE.md`, `.claude/rules/`) do thành viên khác phụ trách. Có rule thì Claude Code tự nạp, và rule thắng nếu mâu thuẫn với skill. Skill không chép, không viết, không sửa rule. Không ghi secret vào MEM (`docs/SRS.md` §6.4).

## Bối cảnh tự nạp

!`bash ${CLAUDE_SKILL_DIR}/scripts/context.sh`

## Các bước

1. **Rà lại toàn bộ phiên**, gom 5 nhóm: việc đã làm (commit SHA, PR, file), bằng chứng test đã CHẠY THẬT, quyết định đã chốt (kèm lý do), chỗ Claude sai (user phản bác "sai", "không phải", "đã bảo rồi", hoặc phải hỏi lại một ý), việc còn dở.
2. **Nhật ký:** thêm 1 mục vào `MEM/journal/YYYY-MM.md` (chưa có thì tạo) theo mẫu bên dưới. Luôn ghi, kể cả phiên ngắn. Lần đầu tạo `journal/` thì thêm vào `MEM/MEMORY.md` dòng `- [Nhật ký công việc](journal/) — /wrap-up ghi, /recall đọc dòng "Còn dở"`, để phiên không gọi `/recall` vẫn biết nhật ký có ở đó.
3. **Bài học:** mỗi chỗ sai ở nhóm 4 xử lý theo mục "Quy trình" trong `.claude/skills/lesson/SKILL.md`. Lỗi khác bản chất thì tách file.
4. **Memory khác:** điều user mới dặn → `feedback`; trạng thái task, bẫy kỹ thuật, link → `project` hoặc `reference`.
   - Grep trước (`grep -ril "<từ khoá>" MEM`). Có file cùng chủ đề thì cập nhật file đó và thêm mốc ngày, không tạo bản trùng.
   - Memory nào phiên này chứng minh là sai hoặc lỗi thời → sửa hoặc xoá, sửa luôn dòng index.
   - Không ghi thứ git, code hay `docs/` đã ghi, và không chép rule vào memory.
5. **Thứ cả nhóm cần biết thì ĐỀ XUẤT, không tự sửa:** quyết định kiến trúc → nháp ADR trong `docs/adr/`; đổi bảng, RPC → `docs/contracts/schema.md`; task xong hoặc đổi phạm vi → `docs/TASKS.md`; thấy repo nên có rule mới → đề xuất cho người phụ trách rule. Chủ vùng phải review xem TASKS §2.
6. **MEMORY.md:** mỗi file mới thêm đúng 1 dòng `- [Tiêu đề](file.md) — móc nhớ ≤ 150 ký tự`. Ghi xong chạy `wc -l -c MEM/MEMORY.md`; quá 170 dòng hoặc 20KB thì đề xuất gộp, bỏ dòng cũ (Claude Code chỉ nạp 200 dòng hoặc 25KB đầu).
7. **Báo cáo:** bảng `| Loại | File | Mới/Cập nhật | Nội dung một dòng |`, rồi một câu "Phiên sau bắt đầu từ: ...". User bảo bỏ dòng nào thì xoá ngay.

## Mẫu nhật ký

```markdown
## 2026-10-16 · L2 · Upload nền bằng background_downloader
- Làm: ...
- Yêu cầu: FR-C6
- Commit: `a1b2c3d` feat(sync): ... · PR #12
- Bằng chứng: `flutter analyze` ✅ · `flutter test` ✅ · Android máy thật ✅ · ios-verify pending
- Quyết định: <chốt gì> vì <lý do>
- Sai & sửa: <sai gì> → [[<slug của bài học>]]
- Còn dở: <bước tiếp theo cụ thể, đủ để phiên sau làm tiếp không cần hỏi lại>
```

Dòng nào không có nội dung thì bỏ hẳn, không viết "không có".

## Định dạng ghi

- Ngày tuyệt đối (16/10/2026), không dùng "hôm nay", "tuần trước".
- Commit SHA lấy từ output `git log` ở trên, không gõ tay. Chưa commit thì ghi "chưa commit (đang staged)" hoặc "chưa commit (chưa stage)".
- Chỉ đánh ✅ cho lệnh đã chạy và thấy output. Chưa chạy thì ghi "chưa verify". Chưa test máy thật thì ghi `ios-verify pending` hoặc `android-verify pending` như PR template.
- Memory `feedback`/`project` phải có `**Why:**` và `**How to apply:**`. Link file liên quan bằng `[[slug]]`, slug là giá trị `name:`, không kèm `.md`.
- Tiếng Việt, câu ngắn, mỗi câu một ý.
