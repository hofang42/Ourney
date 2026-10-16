# Ourney — Design System v0

> ⚠️ Stack đã đổi sang Flutter: màu, font, motion, share card vẫn giữ. Code SwiftUI và các skill SwiftUI không còn áp dụng; dùng `ui-ux-pro-max` (stack `flutter`).
>
> Phong cách: **Vibrant & Block-based + Motion-Driven** (profile "Social Media App" và "Habit Tracker" của skill `ui-ux-pro-max`), lấy cảm hứng từ Locket (camera-first), Duolingo (nút chunky, ăn mừng streak), Strava/Wrapped (share card một con số lớn).
> Ràng buộc xtool: không asset catalog, màu định nghĩa bằng code, font/PNG nằm trong SwiftPM resources, không có `#Preview`.

## Skill dùng khi code UI
| Skill | Dùng lúc |
|---|---|
| `ui-ux-pro-max` | Chọn style/màu/font, checklist accessibility trước khi giao. *Script `search.py` cần Python, máy hiện chưa cài; data CSV đọc trực tiếp được* |
| `swiftui-ui-patterns` | Cấu trúc màn hình, tab, navigation, state |
| `swiftui-liquid-glass` | Control nổi trên ảnh/camera (iOS 26, có fallback) |
| `swiftui-pro` | Review code SwiftUI (API hiện đại, hiệu năng) |

## Màu (light / dark)
```
bg           #FFF8F0 / #0F0F14
surface      #FFFFFF / #1C1C24
ink          #1A1A22 / #F5F5FA
inkMuted     #5C5C6B / #A8A8B8
primary      #FF4D6D / #FF6B88   coral: nút chính, nút chụp
primaryDeep  #E11D48 / #FB7185   dùng khi cần chữ trắng trên nền (contrast ≥ 4.5:1)
accent       #7C5CFF / #9D85FF   violet: nhóm, social
streak       #FF9F1C / #FFB547   lửa streak
success      #2BD97C / #3DE88C   check-in xong
sun          #FFD93D             chỉ trang trí; chữ trên nền này phải là ink
gradientHero #FF4D6D → #7C5CFF (135°)    gradientWarm #FF9F1C → #FF4D6D
```
Quy tắc: chữ trắng trên `primary`/gradient chỉ dùng cho chữ đậm ≥ 18pt (3:1). Chữ body trên màu thì dùng `primaryDeep`, hoặc thêm lớp scrim. Màu camera/media luôn ở dark.

```swift
extension Color {
    static func dyn(_ light: UInt32, _ dark: UInt32) -> Color {
        Color(UIColor { $0.userInterfaceStyle == .dark ? UIColor(hex: dark) : UIColor(hex: light) })
    }
    static let jsPrimary = dyn(0xFF4D6D, 0xFF6B88)
}
```

## Typography (OFL, hỗ trợ tiếng Việt, ⚠️ kiểm tra dấu chồng ệ/ữ/ấ ở weight đậm nhất)
- Display: **Bricolage Grotesque** hoặc Plus Jakarta Sans ExtraBold, 34/28/22pt (`relativeTo: .largeTitle/.title/.title2`)
- Body: **Be Vietnam Pro** Regular/Medium/SemiBold, 16/14/12pt (`relativeTo: .body`)
- Số liệu lớn (streak, share card): Display 800, 72–120pt
- Đăng ký font lúc chạy: `CTFontManagerRegisterFontsForURL(Bundle.module.url(...), .process, nil)`

## Hình khối & khoảng cách
- Bo góc: chip 12 · card 20 · sheet 28 · media 32 · nút dạng capsule
- Spacing: 4/8/12/16/24/32, lề màn hình 20
- Vùng chạm ≥ 44pt, nút chụp 76pt
- Nút chunky: viền dưới đậm hơn 4pt, nhấn thì lún 3pt

## Chuyển động & haptic
| Sự kiện | Animation | Haptic |
|---|---|---|
| Chạm | scale 0.96, 0.12s easeOut | – |
| Chuyển màn | `.spring(duration: 0.4, bounce: 0.3)`, `matchedTransitionSource` ảnh → chi tiết | `.selection` khi đổi tab |
| Chụp | flash trắng 0.1s | `.impact(.medium)` |
| Check-in xong | `keyframeAnimator` đóng dấu 0.6s, overshoot 1.15, streak +1 | `.success` |
| Mốc 7/30/hoàn thành | ConfettiSwiftUI 1.5–2s | `.success` |
| Streak sắp mất | lửa `phaseAnimator` nhấp nháy | `.warning` |
| Reduce Motion | thay toàn bộ bằng fade 0.2s, không confetti | giữ nguyên |

## Bố cục chính
- Thanh dưới tự làm, 3 mục: **Journeys · [Chụp] · Nhóm**. Nút giữa to, màu `primary`. App mở mặc định vào Chụp.
- Màn chụp: preview hình vuông bo 32, nền đen, chip journey ở trên, control nổi dùng glass (iOS 26) hoặc `.ultraThinMaterial` + viền 0.5pt.
- Timeline journey: lưới lịch 7 cột, ô ảnh bo 12, ngày lỡ hiện ô nét đứt.

## Share card
- Story 1080×1920: chừa 250px trên và 340px dưới cho UI của IG, nội dung chính nằm trong vùng 1080×1350 ở giữa
- Feed 1080×1350, dự phòng 1080×1080
- Render: view 360×640pt, `ImageRenderer.scale = 3`
- Bố cục: một con số lớn + ảnh/collage + logo nhỏ + handle/QR, 3 theme (Hero gradient, Warm, Mono đen)

## Checklist trước khi giao một màn
Contrast AA · Dynamic Type AX3 không vỡ layout · Reduce Motion · VoiceOver label cho nút chỉ có icon · trạng thái streak không chỉ dựa vào màu · haptic tắt được · không dùng emoji thay icon trong UI hệ thống (emoji chỉ dùng cho reaction/sticker).
