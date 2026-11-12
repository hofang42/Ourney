# Bug và yêu cầu sửa của prototype Ourney V2

File duy nhất ghi lỗi của prototype Figma Make (`design/ourney-v2-app`). Lỗi đang mở có nguyên nhân, cách sửa và prompt gửi Make; lỗi đã sửa ghi theo bản Make. Cập nhật 2026-11-12, code ở Make bản 42 (commit `a099558`). Make đang hết credit: các prompt dưới đây **chưa gửi**.

## A. Lỗi và yêu cầu đang mở

| # | Mức | Vấn đề | Trạng thái |
|---|---|---|---|
| A1 | Cao | Tên hành trình trên camera bị cắt "...", quá nhiều chữ | Có thiết kế + prompt, chưa gửi Make |
| A2 | Cao | Hành trình nhập ảnh cũ kéo dài vô tận vì hiện mọi ngày trống | Có thiết kế + prompt, chưa gửi Make |
| A3 | Tính năng | Tuỳ biến avatar, nền, tem/huy chương (có mở khoá) | SRS FR-B8–B11 + SDS 8.7 trên nhánh `docs/journey-customization`; prompt chưa gửi |
| A4 | Trung bình | 20 lỗi logic/trợ năng trong code prototype do cubic review PR #34 chỉ ra (2026-11-12), đã kiểm lại trong code | Có prompt, chưa gửi Make |
| A5 | Trung bình | Bỏ "Đăng thêm vào…" (R2-10); gợi ý ghim từ hành trình thứ 5 | Chủ dự án chốt 2026-11-12, có prompt, chưa gửi Make |
| A6 | Thấp | Liquid glass còn thiếu ở nút camera nổi của Squad, Memory, Couple | Chủ dự án chốt 2026-11-12, có prompt, chưa gửi Make |

### A1. Tên hành trình trên camera bị cắt, rối mắt

#### Tái hiện và nguyên nhân
- `routes.tsx` (~dòng 8411–8483), mỗi đĩa `.journey-disc` rộng ~64–70px nhưng chứa tới 4 lớp chữ: "Ngày 21" (`.journey-disc-day`), tên hành trình (`<small>`, `text-overflow: ellipsis`), "Đã ghim" (`.journey-disc-pin`) hoặc "2/4 đã điểm danh" (`.journey-disc-status`). Trên đầu còn chip HUD "Hôm nay · 3 ảnh".
- Tên dài ("Ảnh gia đình mỗi ngày", "15 phút tiếng Nhật", "30 ngày nấu cho nhau") luôn bị cắt; 5 đĩa × 3–4 dòng = ~18 mẩu chữ cùng lúc trên nền camera tối, rối mắt.

#### Tham khảo
- Chọn chế độ trong camera iOS, carousel lens của Snapchat, khay story Instagram: mục trong dải chỉ là **hình** (hoặc một chữ ngắn), **tên đầy đủ chỉ hiện một lần** cho mục đang chọn/đang ở giữa. Đây là cách giảm số chữ cùng lúc mà vẫn rõ đang chọn gì (Hick's Law: ít lựa chọn và ít thông tin cạnh tranh thì quyết định nhanh hơn — [Laws of UX](https://lawsofux.com/hicks-law/index.md)).
- NN/g: icon nên có nhãn, nhưng nhãn có thể đặt ở một chỗ cố định thay vì lặp ở mọi icon ([NN/g](https://www.nngroup.com/articles/icon-usability/)).

#### Thiết kế lại
1. **Đĩa chỉ còn hình**: avatar hành trình (mặc định `TypeBadge`, sau này là avatar tự đặt — mục 2) cỡ 48px, không chữ bên dưới.
   - Trạng thái bằng hình nhỏ ở góc đĩa (không chữ): chấm ghim (icon `map-pin` 14px) góc trên trái; tick "đã chụp hôm nay" góc dưới phải; vòng cung tiến độ quanh đĩa cho nhóm (3/5 thành viên).
   - Đĩa đang chọn to hơn (56px) + viền bế sticker.
2. **Một dòng tiêu đề duy nhất** phía trên dải đĩa, cho đĩa đang chọn (hoặc đang chạm giữ):
   - Dòng 1: tên đầy đủ, tối đa 2 dòng, **không cắt "..."** (font 16px đậm; tên dài hơn 2 dòng thì giảm xuống 14px).
   - Dòng 2 (nhỏ, 13px): "Ngày 21/30 · chưa chụp hôm nay" hoặc "Ngày 21/30 · 3/5 đã điểm danh" hoặc "Đã ghim".
   - Đổi đĩa → tiêu đề cross-fade 120ms.
3. **Đĩa "Tất cả"**: icon lưới + số "12" trong đĩa, không chữ dưới; tiêu đề khi chạm: "Tất cả hành trình".
4. **Chip trên đầu camera** chỉ còn tên hành trình đang chọn (1 dòng, co chữ tới 13px trước khi cắt; nếu vẫn dài thì cuộn chậm kiểu marquee 1 lần rồi dừng). "Hôm nay · 3 ảnh" chuyển xuống thành số nhỏ trên thumbnail ảnh gần nhất ở góc dưới trái.
5. **Trợ năng**: mỗi đĩa có `aria-label` đầy đủ "Ảnh gia đình mỗi ngày, ngày 14 trên 30, 2 trên 4 đã điểm danh, đã ghim"; chữ 135% vẫn chỉ có tiêu đề 2 dòng.
6. **Kiểm tra**: reviewer "Kiểm tra camera" đếm số phần tử chữ hiển thị trên camera (mục tiêu ≤ 4: chip tên, tiêu đề 2 dòng, số ảnh), và báo mọi chữ có `text-overflow: ellipsis` đang bị cắt.


### A2. Hành trình nhập ảnh cũ kéo dài vô tận

#### Tái hiện và nguyên nhân
- `ImportedJourneyHome` (`routes.tsx` ~dòng 9258–9320) lặp `Array.from({ length: totalDays })` từ ngày bắt đầu tới ngày kết thúc và vẽ **mọi** ngày; ngày không có ảnh vẫn thành một hàng "Ngày N · Chưa có ảnh". `journeyLength` tính từ ảnh sớm nhất tới ảnh muộn nhất, nên ảnh rải rác 2 năm ra ~700 hàng, phần lớn trống. Màn xem lại khi nhập, Wrapped và lưới lịch dùng cùng độ dài nên cũng dài theo.
- Hậu quả: cuộn rất lâu, ảnh thật chìm giữa các hàng trống, "Ngày 412" vô nghĩa với ảnh cũ.

#### Tham khảo
- Google Photos: dòng ảnh chỉ gồm những ngày có ảnh, nhóm theo ngày/tháng, có **thanh kéo ngày (date scrubber)** ở mép để nhảy tới tháng/năm ([Android Authority](https://www.androidauthority.com/android-photo-picker-date-scrubber-voice-search-3607570), [Google Watch Blog](https://www.googlewatchblog.de/2025/08/google-fotos-mit-dem-scrolltrick-koennt-ihr-sehr-schnell-zu-jedem-beliebigen-datum-im-fotostream-springen/)); Google còn cho tắt nhãn ngày để dòng ảnh gọn hơn ([iPhone in Canada](https://www.iphoneincanada.ca/2026/07/31/google-photos-fixes-annoying-timeline-details-in-new-ios-and-android-update/)).
- Dòng thời gian không nên hiện khoảng ngày ngoài lúc thật sự có ảnh ([Launchpad](https://bugs.launchpad.net/bugs/1221174)); ngày trên ảnh cũ hay sai nên cho sửa/bỏ ngày ([UX Collective](https://uxdesign.cc/the-intelligence-gap-the-simple-ux-tweak-that-google-photos-needs-to-help-preserve-your-familys-1ab7ded151c5)).
- Chưa tìm được tài liệu về cách Day One hiển thị lịch thưa.

#### Thiết kế lại
1. **Chỉ vẽ ngày có ảnh.** Chuỗi ngày trống liên tiếp gộp thành **một hàng khoảng trống** mảnh "· · · 23 ngày không có ảnh" (nét đứt + icon, cao 28px). Xem bình thường không bung từng ngày trống.
2. **Nhóm theo tháng**, tiêu đề dính đầu: "Tháng 4, 2024 · 9 ngày có ảnh · 14 ảnh". Tháng không có ảnh gộp vào hàng khoảng trống ("3 tháng không có ảnh").
3. **Nhãn theo ngày thật** cho ảnh nhập ("12 THG 4, 2024"); "Ngày 37" chỉ là dòng phụ nhỏ.
4. **Thanh kéo tháng/năm** ở mép phải khi khoảng > 60 ngày, nhãn nổi "THG 4 · 2024".
5. **Lưới tháng** (mặc định khi > 60 ngày): mỗi tháng một lịch nhỏ, ô có ảnh là ảnh bìa + số, ô trống là chấm mờ; nút đổi "Theo ngày / Lưới tháng".
6. **Lúc nhập (màn xem lại):** khoảng > 90 ngày và < 30% ngày có ảnh thì gợi ý một lần: "Cắt bớt đầu/cuối" (hai mốc trên thanh thời gian, mặc định cắt đoạn ≥ 30 ngày trống ở hai đầu), "Tách thành nhiều hành trình" (tách ở khoảng trống ≥ 30 ngày, ví dụ "Đà Lạt 4/2024", "Đà Lạt 12/2024"), hoặc "Giữ dạng album" (không đếm ngày, chỉ nhóm theo tháng).
7. **Số liệu:** Hub, Wrapped, thiệp ghi "14 ngày có ảnh trong 2 năm" thay vì "Ngày 730/730"; không hiện % hoàn thành cho hành trình nhập.
8. **Hiệu năng:** danh sách ảo hoá, cuộn mượt với 700 ngày.

### A3. Tuỳ biến hành trình: avatar, nền, tem/huy chương

#### Phạm vi
- **Avatar hành trình**: ảnh tròn đại diện hành trình (dùng ở đĩa camera, thẻ Hub, đầu trang hành trình, Hội). Nguồn: chọn từ ảnh đã chụp trong hành trình, tải ảnh lên, hoặc chọn sticker trong bộ của app. Mặc định là `TypeBadge`.
- **Nền hành trình**: ảnh hoặc hoạ tiết nền cho trang hành trình và thẻ Hub. Nguồn: bộ hoạ tiết theo giao diện (giấy kraft, lưới, neon…), ảnh trong hành trình, hoặc tải lên. Có lớp phủ tự động để chữ luôn đạt tương phản 4.5:1.
- **Tem / huy chương dán góc**: người dùng tải ảnh lên làm sticker (tự tách nền nếu máy hỗ trợ, có viền bế trắng như logo), hoặc chọn từ bộ có sẵn; dán ở 4 góc thẻ hành trình, ảnh ngày, thiệp chia sẻ. Tối đa 4 sticker mỗi chỗ; kéo để xoay ±15°, co giãn 0.6–1.4×.
- Huy chương mốc (7/30/về đích) tự mở khoá và dán được như sticker.

#### Mở khoá (để làm tính năng trả phí hoặc phần thưởng sau này)
| Mục | Miễn phí | Mở khoá |
|---|---|---|
| Avatar | Chọn TypeBadge hoặc ảnh trong hành trình | Tải ảnh ngoài lên: đạt chuỗi 7 ngày (đề xuất) hoặc gói trả phí |
| Nền | Hoạ tiết mặc định của giao diện | Bộ hoạ tiết thêm, ảnh trong hành trình, tải lên: theo mốc hoặc gói trả phí |
| Sticker | Huy chương mốc đã đạt | Tải sticker riêng, bộ sticker theo mùa: gói trả phí hoặc sự kiện |

Chưa chốt mô hình kiếm tiền (câu 12 trong `docs/client-questions.md` vẫn mở), nên prototype dùng cờ `unlocks` và ghi "Mở khoá khi đạt chuỗi 7 ngày" thay vì giá.

#### Ràng buộc
- **Riêng tư** (chủ dự án chốt 2026-11-12): trong Hội, avatar/nền dùng ảnh cơ thể của hành trình Giảm cân được phép, vì thành viên vốn đã thấy ảnh check-in của nhau. Khi chia sẻ ra ngoài (thiệp, link, story): mặc định không dùng ảnh cơ thể làm avatar/nền, thiệp dùng lại quy tắc làm mờ; và mỗi thành viên có cài đặt riêng "Ẩn ảnh của tôi khi chia sẻ ra ngoài" (ẩn hoặc làm mờ avatar/ảnh của mình) để bảo vệ riêng tư.
- **Nhóm**: chỉ chủ nhóm đổi avatar/nền của hành trình nhóm; sticker cá nhân chỉ hiện trên ảnh của chính người đó.
- **An toàn**: ảnh tải lên đi qua kiểm duyệt như ảnh check-in (báo cáo, ẩn khi bị báo cáo); giới hạn 2MB, PNG/JPEG/WebP, tối đa 20 sticker tải lên mỗi tài khoản.
- **Không dùng emoji** làm sticker hệ thống (CLAUDE.md mục 1.3); sticker tải lên là nội dung người dùng.
- Dark mode: lớp phủ nền tự đổi để giữ tương phản.


#### Ảnh hưởng tài liệu và dữ liệu
- SRS: thêm FR-B (tuỳ biến avatar/nền/sticker, mở khoá) — nhánh `docs/journey-customization`.
- SDS: thêm mục tuỳ biến và sửa SCR-10 (camera) theo mục 1.
- Contract dữ liệu (đề xuất, chưa migrate): `journeys.avatar_path`, `journeys.background_kind` (`preset|photo|upload`) + `background_ref`; bảng `journey_stickers(id, journey_id, owner_id, target (card|day|photo|share), local_date null, checkin_id null, share_card_id null, corner, rotation, scale, asset_path, created_at)` với ràng buộc theo loại đích: `card` (thẻ hành trình) không cần khoá thêm; `day` bắt buộc `local_date`; `photo` bắt buộc `checkin_id`; `share` bắt buộc `share_card_id`; các khoá không thuộc loại đó phải null; bảng `user_unlocks(user_id, key, unlocked_at, source)`.
- Quyền và kiểm duyệt cho `journey_stickers` (theo ràng buộc "An toàn" ở trên): RLS chỉ cho `owner_id = auth.uid()` thêm/sửa/xoá; ai đọc được đích (thẻ, ngày, ảnh, thiệp) thì đọc được sticker trên đó; sticker cá nhân chỉ gắn lên ảnh của chính mình. Thêm `moderation_state (visible|hidden|removed)`, sticker tải lên báo cáo được như ảnh check-in (bảng `reports` thêm loại đích `sticker`), bị báo cáo thì ẩn với người báo cáo. File ở storage `stickers/{owner_id}/{id}.{ext}`, chỉ chủ ghi. Cần pgTAP cho RLS, ràng buộc khoá đích và báo cáo trước khi dùng contract này.
- Cài đặt riêng tư mới: `memberships.hide_my_media_external boolean default false` cho "Ẩn ảnh của tôi khi chia sẻ ra ngoài".


### Prompt gửi Make cho A1 + A3

```
FIX + NEW. 1) Camera journey names are cut with "..." and the wheel shows too much text: each disc (~64-70px) stacks "Ngày 21", the name (ellipsis), "Đã ghim" or "2/4 đã điểm danh", plus the top chip "Hôm nay · 3 ảnh". Redesign (routes.tsx journey-disc-strip + app.css):
- Discs are image-only: journey avatar (default TypeBadge) 48px, selected 56px with die-cut sticker border. No text under discs. Status as small shapes on the disc: pin icon top-left if pinned, check bottom-right if shot today, progress arc around the disc for group attendance.
- One title block above the strip for the selected/pressed disc: full name, max 2 lines, never ellipsis (16px bold, 14px if longer than 2 lines), second line 13px "Ngày 21/30 · chưa chụp hôm nay" / "· 3/5 đã điểm danh" / "Đã ghim". Cross-fade 120ms when the disc changes.
- "Tất cả" disc: grid icon + count inside the disc; title "Tất cả hành trình".
- Top camera chip shows only the selected journey name (1 line, shrink to 13px; if still too long, marquee once then stop). Move "Hôm nay · N ảnh" to a small count on the latest-photo thumbnail bottom-left.
- Every disc keeps a full aria-label (name, day, attendance, pinned). At 135% type only the title grows.
- Reviewer "Kiểm tra camera": count visible text nodes on the camera (target ≤ 4) and list any truncated text.

2) NEW journey customization (unlockable). In /j/:id/edit add section "Tuỳ biến":
- Avatar: choose TypeBadge (default), a photo from this journey, upload (simulated picker), or an app sticker. Used in camera discs, Hub card, journey header, Squad.
- Background: preset patterns per skin, a journey photo, or upload; auto overlay keeps text contrast ≥ 4.5:1 in light/dark.
- Stickers: user-uploaded sticker (simulated, white die-cut border like the logo) or earned milestone medals; place on the 4 corners of the journey card, day photo, share card; max 4 per surface; drag to rotate ±15° and scale 0.6–1.4.
- Locks: upload avatar/background/sticker show a lock with "Mở khoá khi đạt chuỗi 7 ngày" (store.unlocks flags; reviewer toggle "Mở khoá tất cả"). Milestone medals are free once earned.
- Rules: group journeys only the owner changes avatar/background, personal stickers show only on the user's own photos; Quiet (weight loss): body photos may be the avatar/background inside the group, but never on anything shared outside; every member gets a setting "Ẩn ảnh của tôi khi chia sẻ ra ngoài" (hide or blur my avatar/photos on outside shares). uploaded items can be reported like check-ins.
- No emoji; use OIcon. Light/dark, 135% type. Run tsc and build.
```

### Prompt gửi Make cho A2

```
FIX (imported past journey renders every day, endless scroll). ImportedJourneyHome (routes.tsx) loops Array.from({length: totalDays}) from the earliest to the latest photo date and draws an "Ngày N · Chưa có ảnh" row for every empty day; photos spread over 2 years give ~700 rows. The import review screen, Wrapped and calendar use the same length. Redesign:
1. Render only days that have photos. Consecutive empty days collapse into ONE thin gap row "· · · 23 ngày không có ảnh" (dashed line + icon, 28px); never expand empty days in normal viewing.
2. Group by month with sticky headers "Tháng 4, 2024 · 9 ngày có ảnh · 14 ảnh"; whole empty months merge into the gap row ("3 tháng không có ảnh").
3. Imported days are labelled by real date ("12 THG 4, 2024"); "Ngày 37" becomes a small secondary label.
4. If the span is > 60 days show a month/year scrubber on the right edge (drag to jump, floating label "THG 4 · 2024").
5. Add a "Theo ngày / Lưới tháng" toggle; default to month grid when span > 60 days: one mini calendar per month, photo days = cover + count, empty days = faint dot; tap opens the day.
6. Import review: when span > 90 days and < 30% of days have photos, show a one-time suggestion card with "Cắt bớt đầu/cuối" (two handles on a time bar, default trims empty edges ≥ 30 days), "Tách thành nhiều hành trình" (split at gaps ≥ 30 days, preview names like "Đà Lạt 4/2024", "Đà Lạt 12/2024"), "Giữ dạng album" (no day counting, month groups only).
7. Hub card, Wrapped, share card: "14 ngày có ảnh trong 2 năm" instead of "Ngày 730/730"; no completion % for imported journeys.
8. Virtualise the list so 700-day spans scroll smoothly. Demo data: add an imported journey with 14 photo days spread over 2 years.
Keep OIcon only, light/dark, 135% type. Run tsc and build.
```

### A4. Lỗi trong code prototype (cubic review PR #34, 2026-11-12)

Đã đối chiếu từng lỗi với code bản 42 trong `design/ourney-v2-app`; cả 20 lỗi đều tái hiện được trong code. Prototype do Figma Make sinh ra nên sửa qua Make (prompt bên dưới), không sửa tay trong repo.

| # | File | Lỗi | Cần đạt |
|---|---|---|---|
| 1 | `app/create.tsx` `InlineDateRange` | `start`/`end` hardcode 16 và 20, không đọc `value` | Mở lại lịch hiện đúng khoảng đã lưu |
| 2 | `app/create.tsx` chọn "Ai cùng đi" | Chọn kiểu khác toast vẫn hiện; "Hoàn tác" đặt `skin` thành `undefined` | Ẩn toast khi chọn lại; hoàn tác về skin trước đó |
| 3 | `app/flow.tsx` đăng nhập | Ô trống báo "Không tìm thấy tên người dùng" thay vì "Nhập email hoặc tên người dùng." | Ô trống báo đúng câu nhắc nhập |
| 4 | `app/flow.tsx` đăng nhập offline | "Thử lại" chỉ xoá lỗi, banner offline và nút gửi vẫn bị chặn | "Thử lại" tắt offline như ở màn mã OTP |
| 5 | `app/flow.tsx` OTP | Gửi mã mới khi mã hết hạn vẫn không nhập được (`otpMode` vẫn `expired`) | Gửi lại đưa về trạng thái bình thường |
| 6 | `app/flow.tsx` OTP | Lỗi mã luôn ghi "trong email" kể cả đăng nhập bằng số điện thoại | "Kiểm tra lại 6 số vừa gửi" |
| 7 | `app/flow.tsx` thiết lập hồ sơ | Màu avatar đã chọn không được lưu vào hồ sơ | Hồ sơ giữ màu avatar đã chọn |
| 8 | `app/store.tsx` `setDraft` | Dùng `draft` của lần render, gọi nhiều lần trong một thao tác thì ghi đè nhau; nháp lưu vào localStorage có thể thiếu | Cập nhật theo kiểu hàm, lưu nháp trong cùng lần cập nhật |
| 9 | `app/store.tsx` `deleteLatestCheckIn` | Không xoá ảnh khỏi `days`; giảm ngày/streak cả khi hôm nay chưa chụp | Xoá ảnh khỏi ngày; chỉ giảm khi hôm nay đã chụp; xoá ảnh duy nhất vẫn giữ ngày (Q11) |
| 10 | `app/store.tsx` reaction trên ảnh | Đổi reaction không trừ reaction cũ, số đếm tăng dồn | Mỗi người một reaction mỗi ảnh |
| 11 | `app/store.tsx` `resetAccount` | Sau khi xoá tài khoản `user` vẫn là "old", Splash tự mở camera | Xoá tài khoản xong về trạng thái người mới |
| 12 | `app/store.tsx` tạo hành trình | Gọi `setCameraPinHint` bên trong updater của `setJourneys` | Tính điều kiện ngoài updater |
| 13 | `app/icons.tsx` | `oIconNames` lặp lại union `OIconName`, thêm icon mà quên mảng thì góc nghiêng thành `undefineddeg` | Suy kiểu từ mảng `as const` |
| 14 | `index.css` Giảm chuyển động | `.reduce-motion *` đặt `transform: none`, làm lệch nút chụp, nút đổi hành trình, toast | Chỉ tắt animation/transition, giữ transform bố cục |
| 15 | `StyleGuide.tsx` sheet | `aria-modal` nhưng không đóng bằng Escape, không chuyển focus vào sheet | Escape đóng, focus vào sheet khi mở |
| 16 | `StyleGuide.tsx` vé khởi hành | Luôn dùng màu Light dù đang ở Dark | Vé đổi theo chế độ màu |
| 17 | `StyleGuide.tsx` proof icon | Class `icon-proof-*` không có CSS, phần hai theme và lưới cỡ không hiển thị | Thêm style cho phần proof icon |
| 18 | `StyleGuide.tsx` dock mẫu | Chỉ có Hành trình, Hội, nút chụp; thiếu Hoạt động, Hồ sơ | Dock mẫu đủ 5 tab |
| 19 | `StyleGuide.tsx` dock mẫu | Vòng chọn mở ngay khi chạm thay vì nhấn giữ 400ms | Nhấn giữ 400ms mới mở, chạm thường không mở |
| 20 | `StyleGuide.tsx` toast | Timer cũ không bị huỷ, toast lần hai tắt sớm | Huỷ timer cũ trước khi đặt timer mới |

Các comment về tài liệu trong cùng đợt review đã sửa trực tiếp trong docs.

#### Prompt gửi Make cho A4

```
FIX (code review findings, no visual redesign). Keep OIcon only, light/dark, 135% type, 5-tab dock.
1. create.tsx InlineDateRange: init start/end by parsing `value` ("a–b/10"), not hardcoded 16/20.
2. create.tsx "who" step: hide the undo toast when another option is picked; undo restores `previousSkin ?? store.draft.skin`.
3. flow.tsx login: empty input shows "Nhập email hoặc tên người dùng." (check empty before the username lookup).
4. flow.tsx login offline banner: "Thử lại" calls store.setOffline(false) like OtpFlow.
5. flow.tsx OTP resend: set store.setOtpMode("normal") so a new code can be entered after "expired".
6. flow.tsx OTP error text: "Mã chưa đúng. Kiểm tra lại 6 số vừa gửi rồi nhập lại." (works for email and phone).
7. flow.tsx profile setup: save the chosen avatar colour with setProfile.
8. store.tsx setDraft: functional update (setDraftState(prev => ...)) and save createProgress from the same next value.
9. store.tsx deleteLatestCheckIn: remove the latest photo from days[]; only decrement day/streak when todayDone; deleting the only photo of a day keeps the day (Q11).
10. store.tsx photo reactions: one reaction per user per photo; switching subtracts the previous one.
11. store.tsx resetAccount: also set user to "new" so Splash does not open the camera.
12. store.tsx create journey: compute the camera pin hint outside the setJourneys updater.
13. icons.tsx: `export const oIconNames = [...] as const; export type OIconName = typeof oIconNames[number]`.
14. index.css .reduce-motion: drop `transform: none`; only disable animations and limit transitions.
15. StyleGuide sheet: Escape closes it, focus moves into the dialog on open and back on close.
16. StyleGuide tickets: use item[mode].surface / item[mode].ink.
17. StyleGuide icon proof: add CSS for icon-proof-* (two themes side by side, size grid).
18. StyleGuide dock preview: all 5 tabs (Hành trình, Hội, shutter, Hoạt động, Hồ sơ).
19. StyleGuide dock preview: wheel opens after a 400ms hold, cancel on pointer up/cancel, plain tap does nothing.
20. StyleGuide toast: keep the timer id in a ref and clear it before setting a new one.
Run tsc and build.
```

### A5. Bỏ đăng nhiều hành trình, sửa mốc gợi ý ghim (chủ dự án chốt 2026-11-12)

- **Bỏ "Đăng thêm vào…"**: màn đăng (`routes.tsx` ~dòng 1546–1565, nút `compose-add-more`) đang cho chọn thêm hành trình để đăng cùng một ảnh, dùng `crossPostJourneyIds` / `toggleCrossPostJourney` trong `store.tsx`. Trái SDS R2-10 ("một ảnh chỉ thuộc một hành trình", tránh ảnh riêng lọt sang hành trình nhóm). Giữ chip "Đăng vào" để **đổi** sang đúng một hành trình khác; bỏ nút "Đăng thêm vào…", danh sách chọn nhiều và state cross-post. SRS FR-C9 đã chuyển sang "Bỏ".
- **Mốc gợi ý ghim**: vòng xoay có 5 đĩa gồm cả "Tất cả", nên chỉ có 4 chỗ cho hành trình. `store.tsx` đang bật `cameraPinHint` khi tạo hành trình thứ 6 (đếm 5 hành trình chưa lưu trữ trước khi thêm); phải bật khi tạo hành trình thứ **5**. Câu gợi ý: "Ghim tối đa 3 hành trình hay chụp lên camera."

#### Prompt gửi Make cho A5

```
CHANGE (owner decision, no redesign). 1) Post screen: remove the "Đăng thêm vào…" button (compose-add-more), its journey checklist, and crossPostJourneyIds / toggleCrossPostJourney / clearCrossPostJourneys from the store. One photo belongs to exactly one journey: keep the "Đăng vào <journey>" chip, which only switches to ONE other journey. 2) Camera wheel keeps 5 discs = up to 4 journeys + "Tất cả (N)". Show the one-time pin hint ("Ghim tối đa 3 hành trình hay chụp lên camera.") when the user creates their 5th active journey (not the 6th); compute it outside the setJourneys updater. Keep OIcon only, light/dark, 135% type. Run tsc and build.
```

### A6. Liquid glass còn thiếu (chủ dự án chốt 2026-11-12: chỗ nào làm được thì làm)

Đã rà `app.css` bản 42. Đã có kính mờ: dock mọi skin, viên chọn trên dock, nền vòng chọn, chip hành trình đang chọn, thanh trên khi cuộn (`adaptive-topbar`), HUD camera chung, nút camera nổi của Quiet, Flexer, Minimalist, sheet, và thẻ nội dung của Flexer (ô số liệu, thẻ tóm tắt, thẻ hội, Wrapped). Chế độ Giảm trong suốt đã có nền đặc thay thế.

Còn thiếu:
- **Nút camera nổi (`*-camera-pill`) của Squad, Memory, Couple** đang nền đặc (`background: … !important`, không `backdrop-filter`). Đây là lớp điều hướng nổi nên được dùng kính: giữ tông màu của skin (kem giấy Squad, giấy kraft Memory, đen 68% Couple) ở độ đục ~70–80% + blur 14–18px, viền 2px + bóng cứng giữ nguyên, nền đặc khi bật Giảm trong suốt.

Thẻ, timeline, thiệp chia sẻ và nút chính của các skin khác vẫn nền đặc theo `CLAUDE.md` §2.

#### Prompt gửi Make cho A6

```
POLISH (owner decision, no layout change). Liquid glass on the floating camera pills of Squad, Memory and Couple (.squad-camera-pill, .memory-camera-pill, .couple-camera-pill): keep each skin tint at 70-80% opacity (Squad cream #F7F1E5, Memory kraft #F4EFE6, Couple dark rgb(0 0 0)) with backdrop-filter blur(16px) saturate(140%), keep the 2px border and hard shadow, keep text contrast >= 4.5:1, and add them to the .app-reduce-transparency solid fallback list. Do not add glass to cards, timelines, share cards or primary buttons outside the Flexer skin. Keep OIcon only, light/dark, 135% type. Run tsc and build.
```

## B. Lỗi đã sửa

| Bản Make | Lỗi | Cách sửa |
|---|---|---|
| 18–22 | Tương phản nút nguy hiểm/chip ở Tối, vùng chạm < 44pt, reaction +2, mã /join không cập nhật, không vào được "Rời nhóm", thẻ nhóm không bấm bằng bàn phím | Xem "Kiểm tra Q" bên dưới |
| 24–25 | Phản hồi chủ dự án 2026-11-11: onboarding không mang sang tạo hành trình, chip camera bo elip, vòng xoay không vuốt ngang, HUD Squad, polaroid đè nút, nhãn cao thấp | Xem bảng tái hiện bên dưới |
| 26 | Nhập ảnh cũ: ngày dạng ISO, đánh số ngày, khay "Chưa có ngày", Wrapped, trạng thái Hub; chữ 9px ở chip Squad | Ngày "12 THG 4, 2024", đánh số theo ngày chụp, gán/bỏ ảnh chưa có ngày |
| 29 | Đổi giao diện hiện nội dung hành trình mẫu khác (IELTS sang Flexer ra "CHẠY SÁNG", "92,4 KM") | Mọi giao diện lấy dữ liệu từ chính hành trình |
| 30–31 | Trạng thái chọn trên dock xấu | Viên thuốc trượt bao icon + nhãn, nhãn giữ độ đậm 700 |
| 32–33 | Người mới đăng nhập xong không tiếp tục bước đã chọn, hỏi quyền camera sớm, chữ đè ở thẻ camera trống, gợi ý không bấm được; xoá tài khoản 2 ô mã | Tiếp tục tạo hành trình từ câu trả lời, lưu bản nháp, hỏi quyền trước ảnh đầu; còn 6 ô mã |
| 34–35 | Còn emoji/ký tự làm icon; icon lửa nhỏ thành khối đen | Bộ icon tự vẽ; icon < 24px màu đặc + viền mảnh |
| 36, 38 | Chụp thêm thay ảnh cũ; xoá ảnh duy nhất huỷ ngày | Nhiều ảnh mỗi ngày; xoá ảnh vẫn giữ ngày (SDS §7.1, Q11) |
| 37, 41 | Tick lệch tâm; tick đè chữ/icon ở Cài đặt | Căn tâm; tick trước chữ trong nút phân đoạn, góc riêng trong ô lưới |
| 39–40 | Icon nét mảnh không hợp logo, icon đen khi chưa chọn; "Sửa hồ sơ" để lại lớp đen | Icon sticker theo logo, luôn có màu; sheet render trong khung điện thoại |
| 41 | Dock khác màu giữa các tab khi hành trình chính là Flexer | Tab chung dùng dock vỏ chung |
| 42 | Vòng chọn hành trình dài khi có nhiều hành trình | Tối đa 5 đĩa: ghim + chưa chụp hôm nay + "Tất cả" có tìm |

### Phản hồi chủ dự án 2026-11-11 (đã sửa ở bản 24–25)

| # | Phản hồi | Tái hiện | Nguyên nhân / vị trí |
|---|---|---|---|
| 1 | Onboarding đã chọn loại hành trình, vào Tạo hành trình bị hỏi lại | Có | `store.beginCreate()` đặt `draft = {}`; onboarding lưu `type`, `who`, `reminder` vào chính `draft` nên bị xoá. `CreateStepOne` luôn mở bước 1 |
| 2a | Vòng xoay đổi hành trình trên camera | Có | Chip tên đĩa đang chọn ("Chạy sáng") nằm dưới nút chụp; chip tên lúc 1 dòng lúc 2 dòng ("30 ngày nấu cho nhau", "Đọc 10 trang"); đĩa ở hai mép bị cắt thẳng, không có lớp mờ; dấu tick chọn nằm đè lên viền đĩa, sát nhãn "Ngày 21" |
| 2b | HUD camera Squad | Có | `.active-journey-chip` có `border-radius: 50%` trên khối 236×44 nên thành elip; nội dung "📖 45 PHÚT · 🔥 18 LIỀN" (phải là "18 LIÊN TIẾP"); nền kem #F7F1E5 trên camera tối |
| 3 | Nút đổi hành trình trên camera elip; bấm xong không vuốt trái/phải được | Có | Nút chính là `.active-journey-chip` (lỗi elip như 2b). `.journey-disc-strip` có `touch-action: pan-y`, nên trên màn cảm ứng chỉ cuộn dọc, không vuốt ngang được |
| 4 | Bấm Cài đặt ở màn hành trình lỗi | Bỏ qua | Chủ dự án báo đã được sửa |

Rà các màn còn lại (6 skin × 9 route + 14 màn vỏ chung, đo DOM):
- Bo elip: chip trên camera của cả 5 skin còn lại cũng elip: Quiet "Riêng tư · Ngày 21", Memory "CUỘN PHIM 12/24", Couple "Chụp nửa của Linh", Minimalist "ĐỌC 10 TRANG · NGÀY 24".
- Đè nhau: `/j/ielts` polaroid "NGÀY 01 · XUẤT PHÁT" đè nút "Tạo thiệp".
- Chiều cao không đều: nhãn polaroid Squad lúc 1 dòng lúc 2 dòng ("NGÀY 14 · ⭐ TUẦN 2", "NGÀY 21 · HÔM NAY 🔥"); chip tên trong vòng xoay.
- Mép bị cắt: đĩa vòng xoay; đường cam ở đầu `/j/ielts` chạm mép trên; băng chuyền `/create/1` (thẻ lấp ló là chủ ý nhưng cần lớp mờ).
- Trạng thái kẹt: vòng xoay đang mở vẫn hiện khi chuyển sang route khác.
- Không thấy chữ bị cắt bằng overflow; các chỗ "đè" còn lại là nút phủ cả thẻ (chủ ý) hoặc nội dung cuộn sau dock nổi (vùng cuộn đã có đệm đáy 116px).


### Kiểm tra Q sau bản 20–22

Cách kiểm: mở thẳng preview `*.makeproxy-c.figma.site` để đọc DOM trong `.phone-frame`, chạy script đo trên 14 route vỏ chung và 6 skin × 8 route (`''`, `/camera`, `/post`, `/squad`, `/share`, `/day/3`, `/edit`, `/wrapped`) ở cả Sáng và Tối, rồi bấm thử luồng bằng click DOM. Q-ref so ảnh chụp với `apps/mobile/assets/design_personas/`. Mẫu báo cáo theo `orchestration/q-rules.md`.

Lưu ý khi đọc số đo tương phản: trình duyệt trả một số màu dạng `color(srgb 0–1)`; script đọc nhầm thành thang 0–255 nên báo nhầm ở Hub, /squad, /create/4, /settings/delete/1, /j/quiet/share. Đo lại thủ công các chỗ đó đều đạt.

| Tiêu chí | Kết quả | Ghi chú |
| --- | --- | --- |
| Q-a11y: chữ ≥ 12px | ĐẠT | Không còn chữ < 12px ở cả hai chế độ |
| Q-a11y: vùng chạm ≥ 44pt | ĐẠT | Đã sửa: công tắc /j/quiet/share (v18), nút /create/4 ở Tối (v21) |
| Q-a11y: tương phản | ĐẠT | Đã sửa: nút nguy hiểm ở Tối (v18), chip Squad ở Tối (v18), nhãn camera Squad/Memory/Minimalist (v19), dock Flexer ở Sáng (v21) |
| Q-a11y: bàn phím | ĐẠT | Đã sửa (v22): thẻ nhóm ở /squad là nút có aria-label, focus được, Enter mở |
| Q-vi: tiếng Việt, không lẫn tiếng Anh | ĐẠT | Chỉ còn "Email", "Ourney", "kg", "km"; dấu phẩy thập phân (v21) |
| Q-mode: Sáng / Tối | ĐẠT | Mọi route ở cả hai chế độ đều đã đo |
| Q-skin: 6 skin khác thế giới | ĐẠT | Bố cục, chất liệu và font khác nhau ở trang chủ, camera, thiệp |
| Q-ref: bảng persona | ĐẠT | Đã sửa (v19): ảnh tường polaroid Squad, ảnh dòng thời gian Quiet, HUD camera Flexer, khung ngắm Minimalist; (v20) bỏ chip số trùng ở camera Flexer |
| Q-rules: không xếp hạng, không link công khai nhóm, Nhắc chỉ là toast | ĐẠT | Hội hôm nay chỉ có ai đã/chưa và giờ; vào nhóm có dòng "không có link công khai" |

Bấm thử trên version 21–22 (đều ĐẠT):
- Hội: "Tham gia" tắt khi trống; "Nhắc Minh" → "Đã nhắc Minh" và tắt; bấm thẻ nhóm → /j/ielts/squad; có lời mời đang chờ.
- Vào nhóm: AAAAAAAA, EXPIRED1, FULL0010, NOJOIN01 đều có thẻ lỗi riêng, đổi mã thì màn đổi theo; K7Q2M9XA hiện vé xem trước, "Tham gia" mở hành trình.
- Prompt 8: reaction +1 (2 → 3); "Lưu" tắt khi chưa sửa; chủ nhóm "Kết thúc hành trình" → chỉ đọc → Wrapped; thành viên không có nút kết thúc.
- Prompt 10: Ngày 1, Lỗi (có "Đang xem bản đã lưu"), Bị xoá khỏi nhóm; thành viên có "Rời nhóm", không có "Đổi mã"; ba trang điều khoản, chính sách, liên hệ.
- Nút chụp: chạm nhanh mở camera; giữ 600ms mở vòng xoay (bằng pointer event giả lập).

CHƯA KIỂM ĐƯỢC: nhấn giữ trên máy thật và Dynamic Type 1.35x, vì server điều khiển thiết bị (mobai) không kết nối được.
