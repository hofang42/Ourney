# Ourney — Phân tích bài toán

> ⚠️ **Mục 4 (Phạm vi), 6 (Kiến trúc/growth loop) và 8 (Lộ trình) đã được thay bằng [02-requirements-v2.md](02-requirements-v2.md).** Mục 2, 3, 5, 7 vẫn còn hiệu lực.
>
> Ngày: 2026-10-16 · Phạm vi: sản phẩm, khả thi, techstack, kiến trúc, lộ trình MVP · Nền tảng đầu tiên: iOS, build bằng xtool (Linux/Windows), output `.ipa` chưa ký.

---

## 1. Bài toán trong 1 câu

"Strava cho mọi loại hành trình": người dùng tạo một **Journey** (giảm cân, học tiếng Anh, du lịch…), ghi **check-in** định kỳ (số liệu + ảnh + ghi chú + vị trí), app tự tổng hợp tiến độ và sinh **thẻ chia sẻ (share card)** đẹp để đăng lên mạng xã hội, kèm feed/kudos cho bạn bè.

## 2. Thị trường & đối thủ

| Mảng | Đối thủ mạnh | Họ giỏi ở đâu |
|---|---|---|
| Thể thao | Strava | Tự động lấy dữ liệu (GPS, đồng hồ), feed + kudos, thử thách, share card |
| Du lịch | Polarsteps, Day One | Tự dựng bản đồ hành trình, sách ảnh in |
| Giảm cân | MyFitnessPal, Happy Scale | Biểu đồ cân nặng, đồng bộ HealthKit |
| Học ngôn ngữ | Duolingo | Streak, gamification, share streak |
| Thói quen chung | Streaks, Habitica, 75 Hard apps | Check-in hằng ngày, streak |

**Nhận định:**
- Không đối thủ lớn nào làm **"hành trình đa năng + share đẹp"**, nhưng mỗi ngách đều có app chuyên sâu hơn. App "đa năng" dễ thành "không giỏi cái gì".
- Điểm mạnh của Strava **không phải** ghi chép, mà là (1) dữ liệu tự động, (2) mạng xã hội đã có sẵn bạn bè. App mới **không có** cả hai → phải bù bằng **share card ra ngoài** (Instagram/Facebook/Zalo/TikTok) làm vòng tăng trưởng, không phụ thuộc feed trong app.

**Định vị đề xuất:** *"Biến tiến độ của bạn thành câu chuyện để khoe"*. Giá trị cốt lõi = **share card + trang web công khai của hành trình**, social trong app là lớp thứ hai.

## 3. Phân tích khả thi

| Khía cạnh | Mức | Ghi chú |
|---|---|---|
| Kỹ thuật (app + backend) | **Cao** | CRUD + ảnh + biểu đồ + render ảnh; không có phần khó về thuật toán |
| Build iOS bằng xtool không Mac | **Trung bình–Cao** | Được, nhưng phải tránh một số tính năng của Xcode (mục 5) |
| Phát hành tới người dùng thật | **Trung bình** | Sideload chỉ dùng được để dev/test. Người dùng thật cần App Store → cần tài khoản Apple Developer trả phí và upload lên App Store Connect |
| Sản phẩm / thị trường | **Thấp–Trung bình** | Bài toán cold-start của mạng xã hội; giữ chân người dùng (retention) cho app tự ghi chép thường thấp |
| Một người làm MVP | **Khả thi** | ~8–10 tuần part-time nếu giữ đúng phạm vi |

**Kết luận:** Làm được. Rủi ro lớn nhất nằm ở **sản phẩm** (retention, cold-start), không phải kỹ thuật. Rủi ro kỹ thuật lớn nhất là **toolchain xtool** (macro/asset/entitlement), cần spike kiểm chứng ở tuần 1.

## 4. Phạm vi sản phẩm

### Mô hình dữ liệu tổng quát (một model dùng cho mọi loại hành trình)

```
Journey
  id, owner_id, title, type (weight|language|travel|custom),
  goal (metric, target_value, unit, deadline?), visibility (private|friends|public),
  cover_photo, started_at, ended_at?

Metric definition (theo template của type)
  weight:   weight_kg (số), body_photo
  language: minutes (số), words_learned (số), note
  travel:   location (lat/lng/place), photos[], note
  custom:   user tự định nghĩa 1–3 metric

CheckIn (= "activity" của Strava)
  id, journey_id, created_at, values{metric: number}, note, photos[], location?

Social: follow, kudos(checkin), comment(checkin), share_link(journey|checkin)
```

Mấu chốt: **type chỉ là template** (metric mặc định, biểu đồ, layout share card), còn backend chỉ lưu một bảng `check_ins` với `values jsonb`. Thêm loại hành trình mới không cần migration.

### MVP (v0.1) — chỉ làm những thứ này
1. Tạo Journey từ 3 template (giảm cân, tiếng Anh, du lịch) + custom.
2. Check-in: số liệu, ảnh, ghi chú, vị trí (tùy chọn).
3. Màn tiến độ: biểu đồ (Swift Charts), streak, % mục tiêu.
4. **Share card**: render ảnh 1080×1920 / 1080×1080 trên máy → share sheet / Instagram Stories.
5. **Link công khai** `journey.app/j/<slug>`: trang web read-only có OG image → ai bấm link cũng xem được, không cần cài app.
6. Đăng nhập email OTP; dữ liệu đồng bộ cloud.

### v0.2+
Feed bạn bè, kudos/comment, thử thách nhóm ("30 ngày nói tiếng Anh"), nhắc nhở (push), widget màn hình chính, nhập dữ liệu HealthKit (cân nặng), bản đồ du lịch nhiều điểm, Android/Web.

### Không làm trong MVP
Chat, thuật toán gợi ý, thanh toán, AI tóm tắt.

## 5. Techstack iOS với xtool

### Ràng buộc từ xtool → quyết định kỹ thuật

| Ràng buộc | Quyết định |
|---|---|
| Không storyboard/IB | 100% **SwiftUI**, launch screen khai báo `UILaunchScreen` trong Info.plist |
| actool (asset catalog) hay lỗi | **Không dùng `.xcassets`**. Ảnh/màu để trong `Resources/` (SwiftPM `.process`), load bằng `Bundle.module`. Màu định nghĩa bằng code |
| Macro của framework Apple đóng nguồn (SwiftData `@Model`, `#Preview`) chạy bằng plugin nằm trong Xcode cho macOS | **Không dùng SwiftData**, không dùng `#Preview`. `@Observable` (Observation là mã nguồn mở) thì dùng được. ⚠️ Cần verify ở spike |
| Không simulator | Test logic bằng `swift test` trên Linux (tách module thuần Swift, không import UIKit); test UI trên máy thật sau khi ký |
| SPM binary xcframework / ObjC/C++ nặng có thể gãy | Ưu tiên dependency **thuần Swift**. Tránh Firebase SDK |
| Entitlement (push, Sign in with Apple, HealthKit, App Groups) gắn với khâu ký | MVP **không cần entitlement** nào. Thêm sau khi có tài khoản trả phí |

### Stack đề xuất

| Lớp | Chọn | Lý do |
|---|---|---|
| UI | SwiftUI, iOS 17+ (target 17 để dùng `@Observable`, Swift Charts, `MapKit` SwiftUI mới) | Không cần IB |
| State | `@Observable` + MV/feature module | Đơn giản, không cần TCA |
| Lưu cục bộ | **GRDB.swift** (SQLite, thuần Swift) | Thay SwiftData, offline-first, chạy được `swift test` trên Linux |
| Mạng / backend SDK | **supabase-swift** (SPM, thuần Swift) | Auth + Postgres + Storage + Realtime trong 1 SDK |
| Biểu đồ | Swift Charts | Có sẵn trong SDK |
| Ảnh | `PhotosPicker`, nén JPEG/HEIC trước khi upload | |
| Share card | SwiftUI view → `ImageRenderer` → `ShareLink` / Instagram Stories (`instagram-stories://share`, cần Facebook App ID) | Render ngay trên máy, không tốn server |
| Bản đồ | MapKit (SwiftUI `Map`) | Free, không cần key |

### Backend

| Thành phần | Chọn |
|---|---|
| DB + Auth + Storage | **Supabase** (Postgres + Row Level Security). Free tier đủ cho MVP |
| Bảo mật | RLS theo `visibility`: private chỉ chủ xem; public ai cũng xem qua anon key |
| Trang web chia sẻ + OG image | Next.js (hoặc Astro) trên Vercel, `@vercel/og` để sinh ảnh preview cho link |
| Push (v0.2) | APNs qua Supabase Edge Function (cần tài khoản trả phí) |

Lý do không chọn Firebase: SDK iOS nặng (binary + ObjC/C++), rủi ro build với xtool cao hơn; Postgres hợp với feed/quan hệ follow hơn Firestore.

### Bố cục project (SwiftPM, nhiều module để test được trên Linux)

```
Ourney/
├── Package.swift
├── xtool.yml
├── Sources/
│   ├── Ourney/        # App target: SwiftUI views, @main
│   ├── OurneyCore/          # Model, tính streak/tiến độ — thuần Swift, KHÔNG import UIKit
│   ├── OurneyData/          # GRDB + supabase-swift, repository
│   └── ShareCard/            # View render share card
├── Resources/                # icon PNG, font, ảnh template
└── Tests/OurneyCoreTests/   # chạy `swift test` trên Linux
```

```yaml
# xtool.yml (key cần verify lại với bản xtool đang dùng)
version: 1
bundleID: com.yourname.ourney
product: Ourney
infoPath: Info.plist
iconPath: Resources/AppIcon.png
# entitlementsPath: App.entitlements   # bật khi thêm push/SIWA
```

```bash
xtool new Ourney --skip-setup
xtool dev build --ipa        # -> xtool/Ourney.ipa (chưa ký)
swift test --filter OurneyCoreTests   # logic test trên Linux, không cần SDK iOS
```

## 6. Kiến trúc tổng thể

```
iOS app (SwiftUI)
  ├─ GRDB (offline-first, hàng đợi sync)
  ├─ ImageRenderer → share card → IG/FB/Zalo
  └─ supabase-swift ──► Supabase (Auth, Postgres+RLS, Storage ảnh)
                              ▲
Web share page (Next.js/Vercel) ┘  /j/<slug>  + OG image
```

Luồng tăng trưởng: check-in → share card + link → người xem mở web → nút "Bắt đầu hành trình của bạn" → cài app.

## 7. Rủi ro & cách giảm

| Rủi ro | Mức | Giảm thiểu |
|---|---|---|
| Macro/framework nào đó không build được với xtool | Cao | **Spike tuần 1**: app Hello có `@Observable`, Swift Charts, MapKit, PhotosPicker, GRDB, supabase-swift, Bundle.module resource → build `.ipa`, ký, chạy trên máy thật |
| Không có simulator → vòng lặp UI chậm | Trung bình | Tách logic ra `OurneyCore` để test trên Linux; script build+ký+cài một lệnh; dựng UI theo design system đơn giản |
| Phát hành App Store không dùng Mac | Trung bình | Cần: tài khoản trả phí, ký bằng distribution cert (rcodesign làm được), upload bằng App Store Connect API / iTMSTransporter. Kiểm chứng sớm với một bản TestFlight |
| Cold-start mạng xã hội | Cao | Giá trị nằm ở share ra ngoài + trang web công khai, không phụ thuộc bạn bè trong app |
| Retention thấp | Cao | Nhắc nhở, streak, thử thách nhóm (v0.2); chọn 1 ngách để dogfood trước (gợi ý: học tiếng Anh hoặc giảm cân) |
| Ảnh body (giảm cân) là dữ liệu nhạy cảm | Trung bình | Mặc định private, làm mờ/ẩn ảnh trong share card, bucket Storage private + signed URL |

## 8. Lộ trình gợi ý (part-time)

| Tuần | Việc | Kết quả kiểm chứng được |
|---|---|---|
| 1 | Spike toolchain (mục 7) | `.ipa` chạy trên máy thật với đủ dependency |
| 2 | `OurneyCore`: model, streak, tiến độ + test | `swift test` xanh trên Linux |
| 3–4 | UI: danh sách journey, tạo journey, check-in, ảnh, GRDB | Dùng offline được |
| 5 | Biểu đồ + màn tiến độ | |
| 6 | Share card + share sheet / IG Stories | Đăng được story thật |
| 7 | Supabase: auth OTP, sync, Storage, RLS | Dữ liệu lên cloud |
| 8 | Trang web `/j/<slug>` + OG image | Link preview đẹp trên Messenger/Zalo |
| 9–10 | Dogfood, sửa lỗi, thử TestFlight | Bản beta cho 10–20 người |

## 9. Quyết định cần chủ dự án chốt

1. Ngách đầu tiên để dogfood (tiếng Anh / giảm cân / du lịch)?
2. Có mua tài khoản Apple Developer ($99/năm) trước tuần 9 không? Không có thì không TestFlight, không push, không SIWA.
3. Supabase hosted hay self-host?
4. Tên miền cho link chia sẻ.
