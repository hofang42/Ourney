# Ourney — Requirement v2

> ⚠️ Stack đã đổi sang **Flutter (iOS + Android)**, xem [04-implementation-plan-v1.md](04-implementation-plan-v1.md) §0–1. Mục 7–8 (Swift/xtool) không còn hiệu lực. Phần sản phẩm, data model, vòng đời nhóm và §9–10 vẫn giữ (riêng clip đã bị cắt khỏi v1).
>
> 2026-10-16 · Thay thế mục 4 (Phạm vi sản phẩm) của [01-analysis.md](01-analysis.md). Techstack và toolchain xtool giữ nguyên, trừ phần bổ sung ở mục 7.
> Nguồn: 3 agent research (check-in kiểu Locket, journey nhóm/social, UI cho người dùng trẻ) + skill `ui-ux-pro-max`. Những điểm chưa kiểm chứng được đánh dấu ⚠️.

---

## 0. Bản v1 đã đáp ứng ý tưởng chưa?

| Ý tưởng | v1 | v2 |
|---|---|---|
| Journey cá nhân | ✅ | ✅ |
| **Journey nhóm** | ❌ chưa có | ✅ owner/member, mời bằng link/QR, xem "hôm nay ai đã check-in" |
| Template **hoặc** custom | ⚠️ chỉ có 3 template cố định | ✅ template có cấu trúc (nhịp, thời lượng, loại check-in, luật streak), custom dùng cùng schema |
| Check-in mỗi ngày bằng **ảnh/clip kiểu Locket** | ❌ v1 là form nhập số liệu | ✅ mở app vào thẳng camera, chụp một chạm, clip ≤ 5s |
| Share journey với bạn bè | ⚠️ chỉ có share card + link công khai | ✅ mời vào nhóm, quyền xem theo journey, share card theo mốc, link xem trước trên web |
| Giao diện trẻ trung, năng động | ❌ chưa có | ✅ Design system v0 ([03-design-system.md](03-design-system.md)) |
| An toàn nội dung (bắt buộc với App Store khi có UGC) | ❌ chưa có | ✅ report, block, EULA, xoá tài khoản |

## 1. Định vị

**"Locket cho mục tiêu"**: mỗi ngày một ảnh hoặc clip để chứng minh bạn vẫn đang đi tiếp, cùng bạn bè chung hành trình. Cuối mỗi chặng thì khoe như Strava.

Ba vòng lặp:
1. **Thói quen**: camera-first → check-in 3 giây → streak (chuỗi ngày liên tiếp) → nhắc nhở.
2. **Nhóm**: thấy bạn đã check-in → tự thấy cần check-in → nudge (chọc bạn) khi bạn quên.
3. **Lan truyền**: mốc ngày 7/30/hoàn thành → share card + collage → link mời → người mới tham gia journey.

## 2. Khái niệm & data model

```
Template        (hệ thống soạn sẵn hoặc do user lưu lại)
  title, emoji/cover, category
  cadence: daily | n_per_week(n) | weekdays[...]
  duration_days: 7|21|30|75|100|null (mở)
  checkin_kind: photo | clip | photo_or_clip            -- media luôn là chính
  metric?: {name, unit, kind: number|minutes|count}     -- tuỳ chọn, ví dụ cân nặng
  tasks?: ["Uống 3L nước", ...]                         -- checklist mỗi ngày (kiểu 75 Hard)
  streak_policy: strict | grace_per_week(1) | freeze_tokens(n)
  privacy_defaults: {hide_metric, blur_media}           -- bật sẵn cho giảm cân

Journey         (tạo ra từ template, hoặc custom với cùng schema)
  id, kind: solo | group, owner_id, template snapshot (copy, không tham chiếu)
  start_date, end_date?, timezone, visibility: private | group | link
  invite_code, max_members (MVP: 20)

Membership      journey_id, user_id, role: owner|member, joined_at, status: active|left
                 hide_metric, blur_media (từng người tự chỉnh)

CheckIn         id, journey_id, user_id, local_date, created_at
                 media: [{type, path, thumb_path, w, h, duration?}]   (1 media ở MVP)
                 caption?, metric_value?, tasks_done[]?, location? (tuỳ chọn)
                 UNIQUE(journey_id, user_id, local_date)               -- 1 check-in/ngày/journey

Reaction        checkin_id, user_id, emoji        Nudge  journey_id, from, to, date (giới hạn 1/ngày/cặp)
Friendship      user_a, user_b, status            Report / Block  (theo Guideline 1.2)
```

Quyết định quan trọng:
- **Template snapshot**: journey copy nội dung template, nên sửa template không làm hỏng journey đang chạy.
- **`local_date` + `timezone` của journey**: streak tính theo ngày địa phương. Nhóm khác múi giờ thì dùng múi giờ của journey.
- **Group journey = một journey có nhiều member**, không có bảng "group" riêng, mô hình đơn giản hơn.
- **Một check-in dùng cho một journey.** Muốn đăng một ảnh cho nhiều journey thì để v0.2 (chọn nhiều journey khi đăng).

## 3. Template khởi đầu (MVP: 7)

| Template | Nhịp | Thời lượng | Check-in | Metric | Mặc định riêng tư |
|---|---|---|---|---|---|
| Giảm cân | daily | 30/60/90 | ảnh | kg (tuỳ chọn) | **ẩn số kg, làm mờ ảnh khi share ra ngoài** |
| Học tiếng Anh mỗi ngày | daily | 30 | ảnh/clip (clip nói 5s) | phút | – |
| 30 ngày tập luyện | daily | 30 | ảnh/clip | – | – |
| Đọc sách | daily | 30 | ảnh | trang | – |
| Không đường 30 ngày | daily | 30 | ảnh bữa ăn | – | – |
| Chuyến đi | daily | theo ngày đi | ảnh/clip + vị trí | – | – |
| Custom | user chọn | user chọn | user chọn | user chọn | – |

## 4. Chức năng MVP (v0.1)

### A. Check-in kiểu Locket
- A1. Mở app vào thẳng **màn camera**. Phía trên có chip chọn journey (nhớ journey dùng gần nhất).
- A2. Chạm: chụp ảnh. Giữ: quay clip tối đa **5s**. Đổi camera trước/sau.
- A3. Sau khi chụp: caption ngắn, giá trị metric (nếu có), tích task. Bấm "Đăng" là xong, tổng cộng ≤ 3 lần chạm.
- A4. Chọn ảnh/clip từ thư viện được, nhưng gắn nhãn "từ thư viện" (giữ tính chân thực).
- A5. Nén trên máy: ảnh 1080px JPEG q0.7 (~250KB), clip 720p H.264 (~1–1.5MB/5s), thumbnail làm sẵn trên máy.
- A6. Upload qua **hàng đợi offline** (lưu file trên đĩa, `URLSession` background, thử lại khi có mạng). Chưa upload xong vẫn hiện ngay trên máy.
- A7. Animation "đóng dấu" khi check-in thành công, streak +1, haptic success.

### B. Journey
- B1. Tạo journey từ template hoặc custom, chọn solo hoặc nhóm.
- B2. Timeline của journey: lưới ảnh theo ngày (dạng lịch), ngày bỏ lỡ hiện ô trống.
- B3. Tiến độ: streak, % số ngày đã hoàn thành, biểu đồ metric (nếu có).
- B4. Lưu trữ (archive) hoặc kết thúc journey. Journey kết thúc tạo **recap** (collage + số liệu).

### C. Nhóm & bạn bè
- C1. Mời bằng **link/QR** (`ourney.app/i/<code>`). Người chưa cài app mở link thấy trang web xem trước, bấm thì sang App Store.
- C2. Vai trò: owner và member, tối đa 20 người. Owner có thể xoá thành viên và chuyển quyền owner.
- C3. Màn nhóm hôm nay: avatar ai đã/chưa check-in, ảnh mới nhất của từng người.
- C4. Reaction bằng emoji (không có comment trong MVP, giảm gánh moderation).
- C5. **Nudge** một chạm cho người chưa check-in (giới hạn 1 lần/ngày/người, gửi qua push, chưa có push thì dùng in-app).
- C6. **Không có bảng xếp hạng theo kết quả** (kg giảm…). Chỉ hiện mức độ đều đặn.
- C7. (Tuỳ chọn khi tạo nhóm) "Đăng mới được xem": phải check-in hôm nay mới mở xem ảnh của bạn trong nhóm, kiểu BeReal.

### D. Chia sẻ ra ngoài
- D1. Share card tự gợi ý ở mốc 7/30/hoàn thành, hoặc tạo thủ công. Có 2–3 theme, cỡ 1080×1920 (story) và 1080×1350 (feed).
- D2. Share qua share sheet hệ thống + Instagram Stories. Zalo/Messenger dùng link có OG image.
- D3. Visibility theo journey: `private` (chỉ mình), `group` (thành viên), `link` (ai có link đều xem được bản read-only). Chưa có `public`/discover.

### E. Tài khoản & an toàn (bắt buộc để qua review App Store)
- E1. Đăng nhập email OTP, dùng SMTP riêng (Resend/SES) ngay từ đầu vì SMTP mặc định của Supabase bị giới hạn rate rất chặt. Cần tài khoản demo để Apple review. Chỉ phải có Sign in with Apple khi thêm đăng nhập Google/Facebook (Guideline 4.8).
- E2. Report check-in/user, block user, ẩn nội dung đã report ngay trên máy người report.
- E3. EULA không dung thứ nội dung xấu, trang liên hệ, **xoá tài khoản trong app** (Guideline 5.1.1).
- E4. Bảng `moderation_queue` + trang admin tối thiểu (Supabase dashboard là đủ cho MVP).

### F. Nhắc nhở
- F1. Local notification theo giờ user chọn cho từng journey (không cần APNs, chạy được khi chưa có tài khoản trả phí).
- F2. Cảnh báo "streak sắp mất" lúc 21:00 nếu hôm nay chưa check-in.

## 5. Để sau

| v0.2 | v0.3+ |
|---|---|
| **Widget màn hình chính** hiện ảnh mới nhất của nhóm (WidgetKit push trên iOS 26, fallback silent push). Cần App Group + APNs, nên phải có tài khoản trả phí | Journey công khai + discover |
| Push thật (nudge, bạn vừa check-in) | Thử thách nhóm theo tuần, bảng xếp hạng opt-in |
| Comment, danh sách bạn bè | Year-in-review / Wrapped |
| Streak freeze token, admin role | HealthKit (cân nặng), bản đồ chuyến đi nhiều điểm |
| Đăng 1 check-in vào nhiều journey | Android / Web app, gói trả phí (clip dài hơn, theme share card) |
| Moderation ảnh tự động (Edge Function) | Chuyển video sang Cloudflare R2 khi > ~5k DAU |

## 6. Yêu cầu phi chức năng

| Mục | Mục tiêu |
|---|---|
| Từ mở app đến lúc camera sẵn sàng | < 1s (cold start < 2s) |
| Từ chụp đến đăng xong (trên máy) | ≤ 3 lần chạm, < 5s |
| Offline | Check-in được khi mất mạng, tự đồng bộ lại |
| Media | Lưu bản gốc đã nén **vĩnh viễn** (journey là kỷ niệm, không auto-xoá như Locket). Khi chi phí tăng thì chuyển bản cũ > 180 ngày sang lớp lưu trữ rẻ hơn |
| Riêng tư | Bucket private + signed URL ngắn hạn. RLS theo membership. Không lộ URL ảnh public |
| Tiếp cận (accessibility) | Dynamic Type đến AX3, Reduce Motion, contrast AA, VoiceOver cho nút chụp |
| Chi phí | 1k DAU dùng ảnh nằm trong Supabase Pro ($25/tháng). 10k DAU dùng clip khoảng $100–300/tháng egress → cache + R2 |

## 7. Tác động lên kỹ thuật (bổ sung cho 01-analysis)

| Hạng mục | Chi tiết |
|---|---|
| Camera | `AVCaptureSession` + `AVCapturePhotoOutput` + `AVCaptureMovieFileOutput`, bọc trong `UIViewRepresentable`. Info.plist cần `NSCameraUsageDescription`, `NSMicrophoneUsageDescription`, `NSPhotoLibraryUsageDescription` |
| Nén | `AVAssetExportSession` (720p H.264), `CGImageSource` để tạo thumbnail |
| Upload | Signed upload URL + background `URLSession`. TUS để sau (chỉ cần khi file > 6MB) |
| Deep link | Universal link cần file AASA trên domain + entitlement `associated-domains` (cần tài khoản trả phí). **MVP fallback**: custom URL scheme `ourney://` + trang web có nút mở app |
| Font | Be Vietnam Pro (body) + Bricolage Grotesque/Plus Jakarta Sans (display), OFL. Đăng ký lúc chạy bằng `CTFontManagerRegisterFontsForURL` từ `Bundle.module` |
| Thư viện thêm | ConfettiSwiftUI (MIT, thuần Swift). **Tránh Lottie** ở MVP (⚠️ chưa rõ có build được với xtool không) |
| Edge Functions | `on_checkin` (tính streak phía server, cập nhật tóm tắt nhóm), `og-image`, `delete-account` |

### Phụ thuộc vào tài khoản Apple Developer trả phí

| Tính năng | Cần entitlement | Free sideload |
|---|---|---|
| Camera, ảnh, local notification, share | Không | ✅ |
| Push (nudge, widget push) | `aps-environment` | ❌ |
| Widget đọc dữ liệu từ app | App Groups | ⚠️ cần verify |
| Universal link | `associated-domains` | ❌ |
| Sign in with Apple | `applesignin` | ❌ |

→ MVP được thiết kế để **chạy được hoàn toàn khi sideload free**. Các tính năng cần trả phí nằm ở v0.2.

## 8. Spike tuần 1 (cập nhật)

App Hello build bằng `xtool dev build --ipa`, ký rồi chạy trên máy thật, kiểm tra:
1. Camera chụp ảnh + quay clip 5s, export 720p.
2. `@Observable`, Swift Charts, PhotosPicker, `ImageRenderer`.
3. GRDB, supabase-swift (upload ảnh lên Storage bằng signed URL).
4. Font custom từ `Bundle.module`, icon từ PNG (không dùng asset catalog).
5. ConfettiSwiftUI.
6. ⚠️ `xtool.yml` `extensions` + widget target rỗng (chỉ để biết v0.2 có khả thi không).
7. ⚠️ Symbol iOS 26 (`glassEffect`) có trong SDK đã cài không.

## 9. Phản biện (agent review) & quyết định

> Mục này **ghi đè** các mục 2–8 ở những chỗ mâu thuẫn.

| # | Mức | Vấn đề | Quyết định |
|---|---|---|---|
| 1 | High | Sideload free hết hạn sau 7 ngày, bạn bè không tự cài `.ipa` được, nên tính năng nhóm vô nghĩa nếu không có TestFlight | **Mua Apple Developer ($99) ở tuần 1.** Spike phải upload được 1 bản TestFlight. Push và universal link vì vậy không còn bị chặn |
| 2 | High | `visibility: link` xung đột với RLS (người xem ẩn danh không phải member) và lộ ảnh của thành viên khác trong nhóm | `link` **chỉ cho journey solo**. Trang web lấy dữ liệu qua Edge Function + token thu hồi được, sinh signed URL ngắn hạn, làm mờ ảnh ở server. Journey nhóm chỉ có `group` |
| 3 | High | Streak tính ở client và server lệch nhau. `local_date` mơ hồ khi đổi múi giờ/giờ máy | **Không lưu streak.** Một hàm thuần trong `OurneyCore` tính từ tập `local_date`, dùng chung cho app và Edge Function. Server gán `local_date` từ `created_at` + timezone của journey. MVP chỉ có nhịp `daily` + `strict` |
| 4 | High | Vòng đời nhóm chưa định nghĩa | Xem bảng 9.1 |
| 5 | High | RLS: policy trên `memberships` tự query `memberships` gây đệ quy | Hàm `is_member(journey_id)` `SECURITY DEFINER`. Path storage `{journey_id}/{user_id}/{checkin_id}.jpg`. **Viết RLS + test policy ở tuần 2, trước khi làm UI** |
| 6 | High | Hàng đợi offline: chụp lại, xoá, 2 thiết bị, signed URL hết hạn trong hàng đợi. supabase-swift không hỗ trợ background session | Check-in = **upsert** theo `(journey, user, local_date)` với UUID sinh ở client (chụp lại thì thay thế). Xin upload URL lúc gửi. Background `URLSession` tự viết. Sync bằng cursor `updated_at` + soft delete |
| 7 | High | Hook của Locket chính là widget. Hoãn widget thì mất hook | Widget + push lên **đầu ưu tiên ngay sau MVP** (tuần 9–10). Spike tuần 1 vẫn thử widget rỗng. Đo thành công: **D14 retention ≥ 40%** trong nhóm dogfood |
| 8 | Med | Signed URL thay đổi mỗi lần nên cache ảnh luôn miss. Lưới 20 người × 30 ngày ≈ 600 thumbnail | Cache trên đĩa **theo storage path**, không theo URL. `createSignedUrls` theo lô. Thumbnail là object riêng |
| 9 | Med | Checklist App Store chưa đủ | Thêm: xoá tài khoản thì xoá cả media, App Privacy labels, age rating cho UGC, cam kết xử lý report trong 24h, tài khoản demo |
| 10 | Med | Thiếu flow cơ bản | Thêm: profile (tên, avatar, username), onboarding + xin quyền đúng ngữ cảnh, lần đầu chưa có journey thì camera dẫn sang tạo journey, empty state, nhập mã mời thủ công/dán từ clipboard |
| 11 | Med | Nudge không có push thì vô dụng. Local notification lặp lại không bỏ qua được 1 ngày | Nudge chuyển sang làm cùng push. Nhắc nhở: lên lịch cuốn chiếu 14 thông báo không lặp, nạp lại mỗi lần mở app |
| 12 | Med | 01 và 02 mâu thuẫn | Đã đánh dấu các mục cũ của 01 là superseded |
| 13 | Med | Ở nhiều journey thì phải đăng nhiều lần, phá mục tiêu "3 chạm" | MVP: tối đa **3 journey đang chạy** / user. Đăng một lần cho nhiều journey lên v0.2 |
| 14 | Low | Bảng `Friendship` không có tính năng nào dùng | Bỏ khỏi MVP, giữ `Block` |

### 9.1 Vòng đời journey nhóm

| Tình huống | Quy tắc |
|---|---|
| Tham gia muộn | Tiến độ cá nhân tính từ `joined_at`. Xem được toàn bộ lịch sử của nhóm |
| Rời nhóm | Check-in bị ẩn (soft delete). Tham gia lại thì hiện lại |
| Owner rời / xoá tài khoản | Tự chuyển owner cho thành viên tham gia sớm nhất. Không còn ai thì journey bị lưu trữ |
| Owner xoá journey | Chỉ được xoá khi nhóm còn mỗi owner. Nếu không thì chỉ "kết thúc" được |
| Journey kết thúc (`end_date` hoặc owner bấm kết thúc) | Read-only, sinh recap |
| Lộ mã mời | Owner đổi mã (rotate). Mã cũ hết hiệu lực |
| Block | Không join được nhóm có người đã block mình. Đã cùng nhóm thì ẩn nội dung của nhau |

## 10. MVP đã chốt (sau phản biện)

**Giữ:**
- Email OTP, profile, xoá tài khoản (kèm xoá media), onboarding, empty state.
- Camera-first: **ảnh** + **clip ≤ 5s** *(ý chính của chủ dự án, làm ở tuần 7; nếu trễ thì cắt trước tiên)*. Chọn từ thư viện được nhưng có nhãn.
- Hàng đợi offline kiểu upsert.
- Journey solo/nhóm từ **4 template** (Giảm cân, Tiếng Anh, Tập luyện 30 ngày, Chuyến đi) + custom. Nhịp daily, streak strict, thời lượng cố định. Tối đa 3 journey đang chạy.
- Timeline dạng lưới lịch + streak.
- Nhóm: link/mã mời, tối đa **10 người**, owner/member, màn "hôm nay", reaction emoji.
- Share card 1 theme, 2 cỡ, qua share sheet. Link read-only cho journey solo.
- Nhắc nhở local (cuốn chiếu 14 ngày).
- Report, block, EULA, checklist App Store.

**Hoãn:** "Đăng mới được xem", nudge (làm cùng push), checklist task, biểu đồ metric, vị trí, QR, Instagram Stories deep link, recap collage, streak grace/freeze, nhịp `n_per_week`/`weekdays`, `Friendship`.

## 11. Lộ trình (thay mục 8 của 01)

| Tuần | Việc | Kiểm chứng |
|---|---|---|
| 1 | Spike mục 8 + **mua tài khoản $99 + TestFlight** + background upload | 1 bản TestFlight cài được trên máy của người khác |
| 2 | `OurneyCore` (streak, local_date) + schema + **RLS và test policy** | `swift test` xanh; script test RLS pass |
| 3–5 | Camera ảnh, GRDB, check-in, hàng đợi offline, timeline, profile, onboarding | Dùng một mình được offline/online |
| 6 | Sync, journey nhóm, mã mời, màn hôm nay, reaction | 3 người dùng chung một journey |
| 7 | Clip 5s, share card, link solo (Edge Function) | Đăng story thật |
| 8 | Report/block/EULA/xoá tài khoản, checklist review | Đủ điều kiện nộp TestFlight external |
| 9–10 | Dogfood với **một nhóm có sẵn 10–15 người** + widget + push (nudge) | D14 retention ≥ 40% |

## 12. Câu hỏi còn mở (chủ dự án quyết)
1. Đồng ý mua tài khoản Apple Developer ngay ở tuần 1 không? (Không mua thì nhóm chỉ test được trong vòng bạn bè có thể tự ký .ipa.)
2. Clip 5s nằm trong MVP (tuần 7) hay để v0.2?
3. Nhóm dogfood có sẵn 10–15 người là nhóm nào, ngách gì?
4. Đăng ký tên miền cho link mời/link xem.
