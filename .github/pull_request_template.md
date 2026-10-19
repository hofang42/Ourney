## Làm gì
<!-- Task ID trong docs/TASKS.md (vd. Q1) và mã yêu cầu SRS (vd. FR-C6) -->

## Vì sao

## Bằng chứng test
- [ ] `flutter analyze` + `dart analyze` sạch (apps/mobile)
- [ ] `flutter test` / `dart test` / `supabase test db` xanh (phần liên quan)
- [ ] UI: ảnh/video trên iPhone (hoặc ghi "ios-verify pending")
- [ ] UI: Android (hoặc ghi "android-verify pending")

## Checklist
- [ ] Chỉ sửa trong vùng sở hữu (docs/TASKS.md §1), hoặc đã nhờ chủ vùng review
- [ ] Không có secret trong diff
- [ ] Thư viện/API mới có link docs
- [ ] Bảng mới có RLS + pgTAP test (nếu đụng `supabase/`)
