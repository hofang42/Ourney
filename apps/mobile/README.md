# Ourney mobile app (Flutter, iOS + Android)

```bash
flutter pub get
# Local-only mode (FR-A5): no backend, solo journeys only.
flutter run
# With Supabase: copy env.example.json to env.json (gitignored) and fill it.
flutter run --dart-define-from-file=env.json
```

Code generation (output is committed):

```bash
dart run tool/gen_l10n.dart      # localizations (one ARB set per feature)
dart run build_runner build      # Riverpod / drift codegen
```

Checks: `flutter analyze`, `dart analyze` (also runs riverpod_lint), `flutter test`.

Layout: `lib/app/` (bootstrap, router, theme, providers), `lib/shared/`
(design-system widgets), `lib/l10n/` (shared strings), `lib/features/<f>/`
(one folder per feature), `lib/data/` (drift, repositories, sync).
Conventions for feature work: [lib/features/README.md](lib/features/README.md).
