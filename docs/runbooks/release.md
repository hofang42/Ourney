# Runbook: Release `vX.Y.Z` (H5)

> Chủ: @hofang42 (admin). Chỉ admin được tạo tag `v*` (ruleset, xem [`scripts/github/setup-rulesets.sh`](../../scripts/github/setup-rulesets.sh)). Tag kích hoạt hai workflow **iOS (unsigned IPA)** và **Android (APK)**; mỗi workflow tự gắn file vào GitHub Release và sinh release notes theo [`.github/release.yml`](../../.github/release.yml).
> Release theo **ngày cố định**: chỉ bug Blocker/Critical chặn release, việc chưa xong chuyển sang bản sau.

## 1. Checklist

### T-3 ngày: freeze
- [ ] Thông báo freeze trong nhóm: chỉ merge PR sửa bug và tài liệu, không merge tính năng mới.
- [ ] Việc chưa xong chuyển sang milestone bản kế tiếp (vd. v0.1.1).
- [ ] [ADR 0002](../adr/0002-support-email-and-legal-text.md) đã chốt hoặc đã ghi rõ trong release notes là dùng bản nháp; secret `SUPPORT_EMAIL` đã đặt nếu có email thật.
- [ ] (Nếu có bản hosted) `SUPABASE_URL` / `SUPABASE_ANON_KEY` đã đặt, xem [hosted-supabase.md](hosted-supabase.md).
- [ ] Android public mirror cần `PUBLIC_RELEASE_TOKEN` có quyền ghi vào `hofang42/ourney-releases`.
- [ ] Để tự cập nhật chính sách phiên bản Android, tạo GitHub Environment `release` và giới hạn deployment cho tag `v*` trước khi thêm secret `SUPABASE_SERVICE_ROLE_KEY` (khóa `service_role` của project trong `SUPABASE_URL`). Giữ khóa trong environment này. Workflow báo và bỏ qua bước cập nhật chính sách nếu thiếu khóa.

### T-2 đến T-1: bug bash
- [ ] Cả nhóm chạy luồng chính trên máy thật (iPhone: @thydynh03, Android: @lken1514), ghi lỗi thành issue có label `area:*` và mức độ.
- [ ] **Chặn release** chỉ khi còn issue **Blocker** hoặc **Critical** đang mở. Major/Minor chuyển sang bản sau.
- [ ] CI trên `main` xanh (3 job bắt buộc + job `repo tooling`).

### Ngày release
1. [ ] Trong PR `chore/release-vX.Y.Z`, tăng `version: X.Y.Z+N` trong `apps/mobile/pubspec.yaml` và cập nhật `apps/mobile/release-meta.json`. Phần `X.Y.Z` phải khớp tag và `N` phải lớn hơn build của tag trước. Với mỗi platform, đặt `min_supported` ≤ `recommended` ≤ `X.Y.Z`, giữ `min_supported` nếu bản cũ vẫn tương thích, và điền 1–4 ghi chú mỗi ngôn ngữ VI/EN bằng văn bản, không emoji.
2. [ ] Chờ CI trên `main` (commit vừa merge) xanh. Áp dụng migration `0030_app_version_policy.sql` lên Supabase hosted trước lần đầu xuất bản chính sách phiên bản.
3. [ ] Trên máy admin, `git checkout main && git pull --ff-only`, rồi chạy preflight (cần Node.js 20+ và `gh auth login`):
   ```bash
   bash scripts/release/preflight.sh vX.Y.Z
   ```
   Preflight kiểm tra định dạng tag, version và build trong pubspec, ghi chú VI/EN, version tối thiểu từ các migration, cây làm việc sạch, `main` đúng với `origin/main`, CI thành công trên commit hiện tại và tag chưa tồn tại. Nếu mọi kiểm tra đều qua, preflight in lệnh tạo tag.
4. [ ] Admin tạo tag theo lệnh preflight in ra:
   ```bash
   git tag -a vX.Y.Z -m "Ourney vX.Y.Z"
   git push origin vX.Y.Z
   ```
5. [ ] Xác nhận cả hai workflow chạy xong (*Actions*: **iOS (unsigned IPA)** và **Android (APK)** cho tag đó) và trang *Releases → vX.Y.Z* có **cả hai** file (`Ourney-unsigned.ipa` và `Ourney.apk`). Job **Publish Android update policy** chạy sau khi upload mirror thành công và kiểm tra APK tại URL public của đúng tag trước khi cập nhật chính sách. Nếu một workflow lỗi, xem log rồi *Re-run* workflow đó.
6. [ ] Đọc lại release notes tự sinh (nhóm theo label `feat` / `fix` / `area:*`; PR không có label rơi vào "Khác"). Sửa tay phần mở đầu: điều đã biết lỗi, bản thảo pháp lý (ADR 0002), cách cài (mục 2). Đánh dấu *pre-release* nếu đây là bản dogfood.
7. [ ] Báo nhóm, bắt đầu dogfood 14 ngày (mục tiêu SRS §8: D14 ≥ 40%).

### Migration thay đổi tương thích

Thêm `-- @min_client_version: X.Y.Z` đầu migration khi migration cần client từ phiên bản đó. Preflight yêu cầu `min_supported` của Android và iOS đạt mọi mức đã khai báo. Xác nhận các migration mới chưa khai báo mức tối thiểu vẫn tương thích với client cũ khi preflight liệt kê chúng.

## 2. Hướng dẫn cài (dán vào release notes)

### iOS: IPA chưa ký, tự ký bằng Apple ID miễn phí
File `.ipa` **chưa ký**: iPhone không cài trực tiếp được, cần ký bằng Apple ID của bạn.

- **Công cụ**: [AltStore](https://altstore.io) (Windows/macOS) hoặc [Sideloadly](https://sideloadly.io) (Windows/macOS).
- **Sideloadly**: cắm iPhone, mở Sideloadly, kéo `Ourney-unsigned.ipa` vào, nhập Apple ID, bấm *Start*. Trên iPhone: *Cài đặt → Cài đặt chung → VPN & Quản lý thiết bị* → tin cậy chứng chỉ Apple ID của bạn. Nếu iOS 16+ yêu cầu, bật *Chế độ nhà phát triển* (*Cài đặt → Quyền riêng tư & Bảo mật → Chế độ nhà phát triển*, rồi khởi động lại).
- **AltStore**: cài AltServer trên máy tính, cài AltStore lên iPhone, rồi mở file `.ipa` bằng AltStore.
- **Giới hạn Apple ID miễn phí**: app **hết hạn sau 7 ngày** và phải ký lại (AltStore tự làm mới khi máy tính và iPhone cùng Wi-Fi; Sideloadly thì cài lại); tối đa 3 app tự ký cùng lúc; nên dùng Apple ID phụ nếu không muốn dùng ID chính. Dữ liệu trên máy được giữ khi cài đè cùng bundle id.

### Android: APK
1. Tải `Ourney.apk` trên điện thoại (hoặc chép từ máy tính).
2. Mở file; nếu được hỏi, cho phép *Cài đặt ứng dụng không rõ nguồn gốc* cho trình duyệt / trình quản lý file đang dùng.
3. Bấm *Cài đặt*. Nếu Play Protect cảnh báo (APK ký bằng khoá debug, chưa lên Play Store), chọn *Vẫn cài đặt*.
4. Cài bản mới đè bản cũ được nếu cùng khoá ký. Nếu sau này đổi sang khoá release (`ANDROID_KEYSTORE_BASE64`), phải gỡ bản cũ trước.

## 3. Sự cố thường gặp
| Hiện tượng | Xử lý |
|---|---|
| Preflight báo `CI run is for <sha khác>` | CI cho commit mới nhất chưa chạy xong hoặc chưa chạy; chờ rồi chạy lại preflight |
| Release thiếu IPA hoặc APK | Workflow tương ứng lỗi: xem log, sửa, *Re-run* |
| Android policy chưa được cập nhật | Kiểm tra APK ở public mirror đúng tag, secret `PUBLIC_RELEASE_TOKEN`, `SUPABASE_SERVICE_ROLE_KEY` trong environment `release` và migration `0030` trên hosted. Nếu mirror đã thành công và chỉ job **Publish Android update policy** lỗi, chạy lại job đó. |
| Push tag bị từ chối | Chỉ admin được tạo tag `v*`; kiểm tra quyền |
| Lỡ push tag sai | Chỉ admin xoá: `git push origin :refs/tags/vX.Y.Z`, xoá Release trên GitHub, tạo lại tag đúng commit |
