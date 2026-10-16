# Skill của Ourney

Skill là quy trình mà Claude Code nạp khi được gọi (gõ `/<tên>`, hoặc Claude tự gọi nếu skill cho phép). Rule (`CLAUDE.md`, `.claude/rules/`) do thành viên khác phụ trách và không nằm ở đây.

## Skill viết cho Ourney

| Skill | Ai gọi | Việc |
|---|---|---|
| `/recall [task ID]` | user hoặc Claude | Đọc task trong `docs/TASKS.md`, việc còn dở trong nhật ký, bài học đã ghi, tài liệu liên quan |
| `/lesson [lỗi]` | user hoặc Claude | Truy vì sao Claude sai, ghi hoặc nâng cấp bài học, đề xuất test chặn loại lỗi đó |
| `/wrap-up` | chỉ user | Ghi nhật ký cuối phiên: task ID, commit SHA, mã FR, bằng chứng test, việc còn dở |
| `/pr-check [task ID]` | chỉ user | Chạy đúng các job CI mà thay đổi đụng tới, rà checklist PR template, soạn PR body |

Nhật ký và bài học nằm trong thư mục auto-memory local của từng người (`~/.claude/projects/<repo>/memory/`), không commit.

## Skill chép từ nguồn ngoài

Mỗi thư mục có `LICENSE` của nguồn và `NOTICE.md` ghi nguồn cùng các chỗ đã sửa.

| Skill | Nguồn | Sửa |
|---|---|---|
| `flutter-add-widget-test` | [flutter/agent-plugins](https://github.com/flutter/agent-plugins) (BSD-3-Clause) | Không |
| `dart-add-unit-test` | flutter/agent-plugins | Bỏ phần `mockito` |
| `dart-run-static-analysis` | flutter/agent-plugins | Bỏ bước `dart format .` |
| `dart-use-pattern-matching` | flutter/agent-plugins | Không |
| `dart-write-documentation` | flutter/agent-plugins | Không |
| `supabase-postgres-best-practices` | [supabase/agent-skills](https://github.com/supabase/agent-skills) (MIT) | Không |

Cập nhật: chép lại từ nguồn, rồi áp lại các chỗ sửa ghi trong `NOTICE.md`.

## Skill nguồn không thêm vào

| Skill nguồn | Lý do |
|---|---|
| `supabase` | Đổi schema bằng SQL chạy thẳng vào DB (MCP `execute_sql`) rồi mới sinh migration, đặt tên migration theo timestamp (`supabase migration new`), đòi tạo `.mcp.json`. Ourney viết tay migration `NNNN_name.sql` kèm pgTAP |
| `flutter-setup-localization` | Tạo `l10n.yaml` ở gốc. Ourney sinh l10n bằng `tool/gen_l10n.dart`, mỗi feature một bộ ARB |
| `flutter-setup-declarative-routing` | Ourney đã có `go_router` với registry theo feature (`apps/mobile/lib/features/README.md`, `route_registry_test`) |
| `flutter-apply-architecture-best-practices` | Dựng lại cấu trúc app; cấu trúc Ourney đã chốt ở `apps/mobile/lib/features/README.md` |
| `flutter-add-integration-test` | Dùng Flutter Driver và MCP; Ourney khai báo `integration_test` |
| `flutter-build-responsive-layout` | Layout tablet/desktop; ADR 0001 chỉ iPhone, màn dọc |
| `flutter-use-http-package` | Thêm package `http`; app gọi backend qua `supabase_flutter` |
| `dart-generate-test-mocks` | Dùng `mockito`; Ourney dùng `mocktail` |
| `dart-migrate-to-checks-package` | Chuyển test sang `package:checks`; test hiện có dùng `expect` |
| `dart-resolve-package-conflicts` | Chạy `pub upgrade --tighten`, sửa `pubspec.yaml`; đổi dependency đi PR riêng (`docs/SRS.md` §6.1) |
| `dart-use-primary-constructors` | Cần Dart ≥ 3.12; `packages/ourney_core` khai báo `sdk: ^3.5.0` |
| `dart-fix-runtime-errors`, `flutter-fix-layout-issues` | Cần Dart MCP server, không thêm |
| `flutter-implement-json-serialization`, `flutter-add-widget-preview` | Chưa có nhu cầu |
| `dart-build-cli-app`, `dart-setup-ffi-assets`, `dart-use-ffigen`, `dart-use-doc-examples`, `dart-collect-coverage`, `dart-use-path-package` | Không liên quan tới app |
