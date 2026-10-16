# Ourney trên iOS: lấy bản build và cài lên iPhone

Không có Mac và không có tài khoản Apple trả phí. CI build ra file **`.ipa` chưa ký**, bạn tự ký bằng Apple ID miễn phí rồi cài lên iPhone. Quyết định kỹ thuật: [ADR 0001](../adr/0001-ios-min-version-and-build.md).

## 1. Lấy `.ipa`

- **Mỗi lần merge vào `main`**: vào tab **Actions** → workflow **iOS (unsigned IPA)** → chọn run mới nhất → mục **Artifacts** → tải `Ourney-unsigned-ipa` (file zip, giải nén ra `Ourney-unsigned.ipa`). Artifact giữ 30 ngày.
- **Mỗi tag `v*`** (vd `v0.1.0`): file `Ourney-unsigned.ipa` được đính kèm vào trang **Releases**.
- Build thủ công: Actions → iOS (unsigned IPA) → **Run workflow**.

Build cục bộ trên Windows là không thể (cần macOS/Xcode). Chỉ CI build iOS.

## 2. Ký và cài bằng Apple ID miễn phí

Dùng một **Apple ID phụ** (khuyến nghị) cho việc này. **Không bao giờ commit** Apple ID, mật khẩu, mã 2FA, file `.p12` hay `.mobileprovision` vào repo.

### Cách A: Sideloadly (Windows/macOS, dễ nhất)
1. Cài iTunes và iCloud bản tải từ apple.com (không dùng bản Microsoft Store) rồi cài Sideloadly.
2. Cắm iPhone, bấm "Trust this computer" trên máy.
3. Kéo `Ourney-unsigned.ipa` vào Sideloadly, nhập Apple ID, bấm **Start**.
4. Trên iPhone: Cài đặt → Cài đặt chung → **VPN & Quản lý thiết bị** → tin cậy hồ sơ của Apple ID đó. Bật **Chế độ nhà phát triển** (Cài đặt → Quyền riêng tư & Bảo mật) nếu iOS yêu cầu.

### Cách B: zsign (dòng lệnh)
Cần chứng chỉ phát triển và provisioning profile của Apple ID free (lấy qua Sideloadly hoặc công cụ tương đương). Ví dụ, chạy cục bộ (không đưa file vào repo):
```
zsign -k dev.p12 -p "<mật khẩu p12>" -m dev.mobileprovision -o Ourney-signed.ipa Ourney-unsigned.ipa
```
rồi cài bằng công cụ cài `.ipa` bạn dùng (Sideloadly hoặc `ideviceinstaller`).

### Cách C: MobAI re-sign
Theo hướng dẫn của MobAI (bản free có thể có giới hạn, chưa kiểm chứng ở dự án này).

### Hot reload trên iPhone thật từ Windows (MobAI + `builder`)
Cần: iTunes (driver Apple), app [MobAI](https://mobai.run) đang mở với iPhone cắm USB, [`builder`](https://github.com/MobAI-App/ios-builder) v0.11.0, Flutter 3.47.7 (trùng CI). Không dùng `builder init`/`builder ios build`: workflow của nó build ở gốc repo, còn app nằm ở `apps/mobile`.

1. Build bản **debug** một lần (chỉ cần lại khi đổi native: plugin, `Info.plist`, quyền):
   ```bash
   gh workflow run "iOS (unsigned IPA)" --repo hofang42/Ourney --ref main -f mode=debug
   gh run download <run-id> --repo hofang42/Ourney -n Ourney-debug-ipa --dir apps/mobile/dist
   ```
2. Trong `apps/mobile`: `builder dev flutter`. Lần đầu nó cài IPA qua MobAI và ký lại bằng iCloud (nên dùng Apple ID phụ); bundle ID mới có hậu tố team ID.
3. Các lần sau: `builder dev flutter --skip-install --bundle-id com.hofang42.ourney.<TEAMID>`. Lưu file `.dart` là app tự hot reload.

## 3. Giới hạn của Apple ID miễn phí

- **Hết hạn sau 7 ngày**: app ngừng mở được, cần **ký lại và cài đè** (dữ liệu giữ nguyên nếu cài đè cùng bundle ID `com.hofang42.ourney`). Nhắc nhau ký lại hằng tuần.
- Giới hạn số App ID và số app sideload mỗi tuần trên mỗi Apple ID.
- Không push notification từ server, không App Groups, không universal link. Thông báo **local** và URL scheme `ourney://` vẫn dùng được.

## 4. Cấu hình iOS hiện có (tóm tắt)

- Bundle ID `com.hofang42.ourney`, tên hiển thị "Ourney", chỉ iPhone, chỉ dọc, iOS tối thiểu 15.0.
- Quyền: camera, thư viện ảnh (chọn và lưu ảnh) với chuỗi tiếng Việt (mặc định) và tiếng Anh trong `Runner/vi.lproj` và `Runner/en.lproj/InfoPlist.strings`.
- URL scheme `ourney`, `ITSAppUsesNonExemptEncryption = false`.
- Quyền thông báo được xin lúc chạy bởi `flutter_local_notifications`.

## 5. Secrets tùy chọn trong CI

`SUPABASE_URL`, `SUPABASE_ANON_KEY` (Settings → Secrets and variables → Actions). Nếu có, workflow tạo file JSON tạm và truyền qua `--dart-define-from-file`; nếu không có, build vẫn chạy không có cấu hình. Chỉ dùng anon key, không bao giờ dùng service-role key.

## 6. Đóng gói thủ công

`scripts/ios/package_ipa.sh [đường-dẫn/Runner.app] [ra.ipa]` nén `Payload/Runner.app` thành `.ipa` (mặc định `apps/mobile/build/ios/iphoneos/Runner.app` → `Ourney-unsigned.ipa`).
