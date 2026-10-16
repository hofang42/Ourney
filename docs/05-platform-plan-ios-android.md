# Ourney — Plan theo nền tảng: iOS (ưu tiên) + Android (song song)

> Bổ sung cho [04-implementation-plan-v1.md](04-implementation-plan-v1.md). Code Dart dùng chung một codebase. Tài liệu này quy định **phần riêng của từng nền tảng** và **thứ tự ưu tiên**.
> ✅ đã kiểm chứng · ⚠️ chốt ở spike · **TBD** chủ dự án quyết.

## 1. Nguyên tắc ưu tiên iOS

1. **Definition of Done của mọi tính năng = chạy đúng trên iPhone thật trước**, Android được verify trong cùng wave (chậm nhất là wave kế tiếp).
2. Bug chỉ có trên iOS được ưu tiên hơn bug chỉ có trên Android cùng mức độ.
3. Bug chỉ có trên Android **không chặn** bản beta iOS. Bug chỉ có trên iOS **chặn** bản beta.
4. Khi phải chọn plugin hoặc cách làm: chọn cái tốt cho iOS, miễn là Android vẫn chạy được.
5. Spike iOS (S1–S3) chạy **đầu tiên**, vì đây là rủi ro lớn nhất (không có Mac).

## 2. Hai agent nền tảng (thêm vào đội agent ở 04 §2)

| Vai trò | Agent type | Skill | Model | Sở hữu độc quyền |
|---|---|---|---|---|
| **iOS Platform Engineer** | `general-purpose` | `ci-cd-and-automation`, `source-driven-development`, `debugging-and-error-recovery` | sonnet | `apps/mobile/ios/**`, `builder.json`, `.github/workflows/ios.yml`, `scripts/ios/**`, `docs/platform/ios.md` |
| **Android Platform Engineer** | `general-purpose` | `ci-cd-and-automation`, `source-driven-development` | sonnet | `apps/mobile/android/**`, `.github/workflows/android.yml`, `scripts/android/**`, `docs/platform/android.md` |

- Feature agent (B1–C3) **không sửa** `ios/` và `android/`. Cần quyền mới, scheme hay cấu hình native thì mở issue `platform:ios` / `platform:android` giao cho agent nền tảng.
- Plugin native (nếu S3 cho thấy cần camera native): iOS Platform Engineer viết phần Swift, Android Platform Engineer viết phần Kotlin, Mobile UI B viết phần interface Dart.
- `pubspec.yaml` vẫn do A3 sở hữu (theo 04).

## 3. Lộ trình song song

| Tuần | iOS track (ưu tiên) | Android track | Đồng bộ |
|---|---|---|---|
| 1 (P0–P1) | Cài `builder` trên Windows, `builder auth github`, cài MobAI free, chuẩn bị Apple ID phụ (iCloud riêng) để ký | Android SDK + emulator trên Windows, thiết bị Android thật bật USB debugging | |
| 2 (P2–P3) | **S1** `.ipa` chưa ký → ký → chạy trên iPhone · **S2** hot reload qua MobAI free · **S3** camera iOS · **S4** upload nền iOS | S3 camera Android · S4 upload nền Android · build APK debug local | Kết quả spike ghi vào `docs/spikes/` |
| 3 (Wave A) | `ios/` scaffold: bundle ID, iOS tối thiểu, Info.plist, URL scheme, icon/launch · `ios.yml` CI | `android/` scaffold: applicationId, minSdk, manifest quyền, intent filter, keystore debug · `android.yml` CI | A3 tạo app với `flutter create --platforms=ios,android --org com.hofang42` |
| 4–5 (Wave B) | Mỗi PR tính năng: demo trên iPhone (video/screenshot đính kèm PR) · build `.ipa` mỗi lần merge `main` | Verify trên Android trong cùng PR nếu được, nếu không thì gom vào PR "android-verify" cuối tuần | |
| 6 (Wave C) | Share sheet iOS, notification iOS, deep link `ourney://` từ Safari/Zalo | Share intent, notification channel, deep link từ Chrome/Zalo | |
| 7 (Wave D + P6) | QA đầy đủ ma trận thiết bị iOS | QA ma trận Android | Bug bash chung |
| 8 (P8) | **Beta iOS `v0.1.0`**: `.ipa` chưa ký + hướng dẫn ký | **Android `v0.1.0`** cùng tag nếu không còn bug Blocker, nếu còn thì `v0.1.1` | |

## 4. iOS checklist (giao cho iOS Platform Engineer)

Mọi thay đổi trong `ios/` đều là file text (plist, xcconfig, pbxproj). Sửa trên Windows, build trên macOS runner. Không mở Xcode.

### 4.1 Cấu hình project
- [ ] Bundle ID `com.hofang42.ourney`, display name "Ourney", version lấy từ `pubspec.yaml` (`FLUTTER_BUILD_NAME/NUMBER`)
- [ ] iOS tối thiểu: **đề xuất iOS 16** ⚠️ (kiểm tra mức tối thiểu của Flutter stable và các plugin ở S1, rồi ghi vào ADR)
- [ ] Chỉ dọc (portrait), iPhone. iPad **TBD** (đề xuất tắt ở v1)
- [ ] Dependency native theo cơ chế Flutter đang dùng mặc định (SwiftPM hoặc CocoaPods) ⚠️ chốt ở S1. Runner macOS tự xử lý, máy Windows không cần

### 4.2 Info.plist
- [ ] `NSCameraUsageDescription`: "Ourney dùng camera để bạn chụp ảnh check-in hằng ngày."
- [ ] `NSPhotoLibraryUsageDescription`: cho chọn ảnh từ thư viện (có nhãn "từ thư viện")
- [ ] `NSPhotoLibraryAddUsageDescription`: lưu share card vào Ảnh
- [ ] `CFBundleURLTypes` với scheme `ourney` (link mời / mở journey)
- [ ] `LSApplicationQueriesSchemes` nếu cần kiểm tra app khác (để sau, IG Stories ở v0.2)
- [ ] `ITSAppUsesNonExemptEncryption = false` (chỉ dùng HTTPS)
- [ ] `UIBackgroundModes`: chỉ thêm nếu S4 chứng minh cần ⚠️
- [ ] Bản địa hoá chuỗi xin quyền: `vi`, `en` (`InfoPlist.strings`)

### 4.3 Giao diện hệ thống
- [ ] App icon: `flutter_launcher_icons` sinh `ios/Runner/Assets.xcassets` (actool chạy trên macOS runner nên không gặp lỗi actool như với xtool)
- [ ] Launch screen: `flutter_native_splash` (nền `bg`, logo)
- [ ] Status bar sáng/tối theo màn (camera luôn dark)
- [ ] Safe area / Dynamic Island cho màn camera

### 4.4 Hành vi riêng iOS cần xử lý trong code Dart (giao feature agent, iOS engineer review)
- [ ] Quyền ảnh "Limited Photos": vẫn chọn được ảnh, hiện nút mở lại picker
- [ ] Từ chối quyền camera: màn giải thích + nút mở Settings (`app-settings:`)
- [ ] Notification: xin quyền đúng ngữ cảnh (sau check-in đầu tiên), iOS giới hạn **64 local notification đang chờ** → lịch cuốn chiếu 14 ngày × số journey phải ≤ 64
- [ ] App bị kill khi đang upload: hàng đợi tiếp tục khi mở lại (theo kết quả S4)
- [ ] Haptic dùng `HapticFeedback` (iPhone có Taptic Engine)
- [ ] Cử chỉ vuốt từ mép để quay lại không xung đột với camera

### 4.5 Build, ký, cài
- [ ] `builder.json`: `ios.configuration = Release` cho bản phát hành, Debug cho dev
- [ ] `.github/workflows/ios.yml`: PR chỉ `flutter analyze` + `flutter test`. Merge `main`/tag thì build `.ipa` chưa ký → artifact/Release
- [ ] **Dự phòng** nếu ios-builder lỗi: workflow tự viết `flutter build ios --release --no-codesign` → nén `Payload/Runner.app` thành `.ipa`
- [ ] `docs/platform/ios.md`: hướng dẫn ký bằng Sideloadly/zsign/MobAI với Apple ID free. Giới hạn ⚠️: hết hạn 7 ngày, giới hạn số app/App ID mỗi tuần → nhắc ký lại hằng tuần
- [ ] Không commit Apple ID, mật khẩu, file `.p12`/`.mobileprovision`

### 4.6 Ma trận test iOS (P6) — **TBD**: liệt kê máy thật của team
| Máy | iOS | Vai trò |
|---|---|---|
| iPhone đời mới nhất team có | mới nhất | Luồng chính, hiệu năng |
| iPhone cũ nhất team có | thấp nhất được hỗ trợ | Cold start camera, bộ nhớ |

## 5. Android checklist (giao cho Android Platform Engineer)

### 5.1 Cấu hình
- [ ] `applicationId com.hofang42.ourney`, `minSdk` **đề xuất 26** ⚠️ (chốt theo plugin), `targetSdk` theo Flutter stable
- [ ] Chỉ dọc

### 5.2 Manifest & quyền
- [ ] `CAMERA`
- [ ] Chọn ảnh bằng **Photo Picker** hệ thống (không cần quyền đọc bộ nhớ trên Android 13+). Máy cũ hơn dùng fallback theo plugin ⚠️
- [ ] `POST_NOTIFICATIONS` (Android 13+), xin đúng ngữ cảnh
- [ ] Nhắc nhở: dùng alarm không chính xác (inexact), tránh quyền `SCHEDULE_EXACT_ALARM` trừ khi cần ⚠️
- [ ] Intent filter cho `ourney://`
- [ ] Notification channel "Nhắc check-in"

### 5.3 Build & phát hành
- [ ] Keystore release: chỉ nằm trong GitHub Secrets, không commit
- [ ] `.github/workflows/android.yml`: build APK (+ AAB để dành cho Play Store sau)
- [ ] Icon adaptive + splash (cùng tool với iOS)
- [ ] Ma trận test: 1 máy tầm trung (camera cold start), 1 máy Android 13+ (quyền mới) **TBD**

## 6. Cập nhật Definition of Done cho PR tính năng (ghi đè 04 §7)

```
✅ flutter analyze + test xanh
✅ Demo trên iPhone thật (video/screenshot trong PR)   ← bắt buộc
✅ Demo trên Android (hoặc ghi "android-verify pending" + issue)
✅ Không sửa ios/ hay android/ (nếu cần thì có issue platform tương ứng)
✅ code-reviewer agent → người review
```

## 7. Câu hỏi cho chủ dự án
1. Team có những iPhone và máy Android nào (model + phiên bản OS) để làm ma trận test?
2. Có hỗ trợ iPad ở v1 không? (đề xuất: không)
3. Ai trong team phụ trách verify iOS hằng ngày (người có iPhone và cài MobAI)?
