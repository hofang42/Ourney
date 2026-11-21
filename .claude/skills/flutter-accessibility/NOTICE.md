# Nguồn

Chép từ [verygoodopensource/vgv-ai-flutter-plugin / plugin/skills/accessibility](https://github.com/verygoodopensource/vgv-ai-flutter-plugin/tree/316390b5d95f54e692db76f2b73140324ecd79d7/plugin/skills/accessibility) ngày 21/11/2026. Giấy phép MIT (Copyright (c) 2026 Very Good Ventures), xem `LICENSE` cùng thư mục.

Sửa so với bản gốc:

- `SKILL.md`: đổi `name` thành `flutter-accessibility` (tránh trùng tên chung `accessibility`), viết lại `description` để gọi được bằng "scan for bugs", "quét bug", "a11y", "trợ năng" và review UI/UX; đổi `argument-hint`.
- `SKILL.md`: thêm mục "Ourney overrides" (chốt WCAG 2.2 AA, iOS + Android theo ADR 0001; vùng chạm 48dp theo `CLAUDE.md`; sửa bằng component trong `apps/mobile/lib/ui/` thay cho Material; cấm `Icons.*`; tương phản theo token `context.ui` và skin; cỡ chữ 1.0/1.35/2.0 theo `OurneyTextScaleClamp`; test theo `test/app/test_helpers.dart`). Sửa hai dòng "Conformance Level" và "Platform Selection" để không hỏi lại.
- Bỏ `references/platforms/web.md`, `macos.md`, `windows.md`, `linux.md` và các link tới chúng.
- Các file trong `references/` còn lại giữ nguyên. Ví dụ trong đó dùng `IconButton`, `Icons.*`, Bloc: chỉ để minh họa, mục "Ourney overrides" quy định cách sửa thật.
