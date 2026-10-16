# Nguồn

Chép từ [flutter/agent-plugins / skills/dart-run-static-analysis](https://github.com/flutter/agent-plugins/tree/0ef3972f93e2baa4156ba1cbb1e515cd53079c68/skills/dart-run-static-analysis) ngày 16/10/2026. Giấy phép BSD-3-Clause, xem `LICENSE` cùng thư mục.

Sửa so với bản gốc: bỏ bước `dart format .`, vì lệnh này format cả file sinh tự động (build_runner, l10n) mà CI so bằng `git diff`, và format lại toàn repo.
