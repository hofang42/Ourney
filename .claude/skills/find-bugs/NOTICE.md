# Nguồn

Chép từ [getsentry/skills / skills/find-bugs](https://github.com/getsentry/skills/tree/a582c51ee29d0f35e6ac321340796f77d43da733/skills/find-bugs) ngày 21/11/2026 (commit cuối sửa file: `24361e7`). Giấy phép Apache-2.0, xem `LICENSE` cùng thư mục. Theo Apache-2.0 §4(b), `SKILL.md` có dòng ghi chú đã sửa ở đầu.

Sửa so với bản gốc:

- `description`: thêm lời gọi "scan for bugs", "quét bug", "tìm lỗi", phạm vi lỗi logic, và trỏ sang `ui-bug-scan`, `flutter-accessibility`. Thêm `argument-hint`.
- Phạm vi: so với `main` (Ourney PR vào `main`) thay cho nhánh mặc định lấy bằng `gh`; thêm chế độ quét cả thư mục hoặc feature, không chỉ diff.
- Phase 1: đọc `docs/bug.md`, `docs/bugs.md` và test có sẵn để không báo lại lỗi đã biết.
- Phase 2: viết lại danh mục bề mặt cho Flutter, Riverpod, drift, Supabase (thêm ranh giới async và phép tính ngày giờ).
- Phase 3: thêm nhóm mục kiểm tra lỗi logic và vòng đời (chi tiết ở `references/dart-flutter-checklist.md`, viết mới cho Ourney); giữ nhóm bảo mật của bản gốc, bỏ XSS và CSRF (app mobile, không có template HTML), diễn đạt lại cho RLS và Edge Functions.
- Phase 4: thêm bước chứng minh bằng test tạm trong `apps/mobile/test/zz_bugscan/` dùng helper có sẵn, và thang "độ chắc" như `docs/bug.md`.
- Output: thêm "Confidence", "Scenario", test chặn hồi quy; viết báo cáo theo ngôn ngữ của user; bỏ qua lỗi đã có trong `docs/bug.md`.
- `references/dart-flutter-checklist.md` là file mới của Ourney, không thuộc bản gốc.
