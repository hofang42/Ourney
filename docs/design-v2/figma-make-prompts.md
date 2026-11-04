# Ourney V2: Bộ prompt Figma Make

Cách dùng: dán **lần lượt** từng prompt vào **cùng một** file Figma Make. Prompt 0 dựng nền móng, các prompt sau tái sử dụng component đã có. Mỗi prompt xong thì kiểm tra lại (checklist cuối file) rồi mới chạy prompt tiếp theo. Nếu Figma Make báo prompt quá dài, tách theo các dấu `---` bên trong prompt.

Đặc tả đầy đủ: [README.md](README.md).

---

## Prompt 0: Nền móng, design tokens và component

```
Project: "Ourney" — a camera-first iOS app (Flutter) for keeping any personal goal ("journey":
weight loss, daily English, 30-day workout, a trip, a couple ritual, or a custom habit).
Every day the user snaps ONE check-in photo; days chain into a streak; friends can join a journey
as a small squad (max 10). Think "Locket for goals" + Strava-style share cards. Vietnamese UI copy.
Frame: iPhone 390×844, light AND dark mode for everything.

This first step: build the DESIGN SYSTEM only (no full screens yet).

1) GLOBAL SHELL STYLE — "Soft Neo-Brutalism", playful & warm
- Light: bg #FFF8EE, surface #FFFFFF, ink/border #1A1A1A, muted text #5A544C.
- Dark: bg #121212, surface #1C1B19, ink/border #F5F0E6, muted #B8B0A4.
- Primary #FF8A3D (text on it is always ink #1A1A1A).
- Cards: 2px solid ink border, hard offset shadow 4px 4px 0 (no blur), radius 16.
  Pressed: shadow → 0 and element translates 4px,4px.
- Persona accent pastels (one per journey type, used for badges/cards in the shell):
  mint #7EE8A2 (Weight), yellow #FFD84D (English/Squad), peach #FFB347 (Trip),
  coral #FF7E7E (Couple), lilac #CF9FFF (Workout), sky #7EC8E3 (Custom habit).
- Type: headings Space Grotesk Bold, tight tracking, screen titles lowercase with a period
  ("hành trình.", "tạo hành trình."). Body/UI: Be Vietnam Pro (must render Vietnamese diacritics
  ệ ữ ấ cleanly, line-height 1.35). Big numbers (streak, day count): Space Grotesk 700, 56–96pt.
- Icons: Phosphor Bold / Duotone, 24px. Never emoji as navigation icons
  (emoji allowed only for journey badges, 🔥 streak and reactions 🔥 💪 👏 ❤️ 😂).
- Illustration: hand-drawn sticker style, thick outlines, warm colors (covers, empty states).

2) SIX JOURNEY SKINS — create a token page per skin, each with Light + Dark:
- Quiet Transformer (weight loss): calm clinical. L bg #EFF3F0 surface #FFF ink #0F172A /
  D bg #0B0F12 surface #151C21 ink #F1F5F9. Accent emerald #10B981, shutter coral #FF4D6D.
  Hairline 1px borders, soft elevation; keep 1.5px border + 2px hard shadow on dock & primary button.
  Heading: light serif (Fraunces). Variants: Emerald / Sage / Mist.
- Accountability Squad (study/English): cream notebook. L #F7F1E5/#FFFDF9/#1E1B18,
  D #12131A/#1D1F2B/#F8FAFC. Accent flame gold #FF9F1C, violet #7556F8. 2px ink border +
  3px bottom lip on every card, polaroids. Heading Space Grotesk. Variants: Flame / Violet / Chalk.
- Memory Collectors (trip): paper scrapbook. L #F4EFE6/#FFF/#231F1E, D #141312/#1F1D1B/#F5F2EB.
  Accent terracotta #CC4A2F, olive sage #4A6B53. Masking tape, stitched thread, film sprockets,
  paper grain. Heading classic serif (Fraunces) + monospace date stamps.
  Variants: "Sương thông" (pine fog) / "Biển muối" (salt sea) / "Phố đêm" (night city).
- Couple Rituals: blush, soft. L #F9F0EE/#FFF/#261F22, D #171215/#241C21/#FCE7F3.
  Accent rose #E15B72, deep berry #9D174D. 24px radius paired (diptych) frames, heart nodes.
  Variants: Rose / Berry / Peach.
- Aesthetic Flexer (workout): dark-first athletic. L #F3F4F6/#FFF/#090A0F, D #090A0F/#14161F/#F8FAFC.
  Accent electric coral #FF4D6D, neon lime #3DE88C. Frosted glass + 1px glowing stroke,
  hard neon offset shadow 4px 4px 0 #3DE88C on primary button. Condensed bold numerals
  (Barlow Condensed). Variants: Neon Lime / Electric Coral / Ice.
- Minimalist Habit (custom): Braun minimal. L #F5F3EE/#FFF/#1C1C1E, D #0E0E10/#18181B/#F4F4F5.
  Accent Braun orange #EA580C, charcoal #27272A. Crisp 1px grid, zero ornament; only the shutter
  keeps a 2px border. Variants: Orange / Charcoal / Sky.
All text pairs ≥ 4.5:1 contrast. Camera screens are always dark.

3) COMPONENTS (each with shell version + per-skin variants via variables/modes):
button (primary / secondary / ghost / destructive, 52pt, capsule, pressed state),
journey card (cover sticker, emoji badge, title, Day N/M, 🔥 streak, squad avatar stack, progress),
chip / tag, text input, OTP input (6 boxes), big answer card (for quiz), bottom sheet (24 radius),
FLOATING DOCK: capsule bar with left "Hành trình", center raised 72pt shutter (color = active journey
accent), right "Squad"; long-press shutter reveals a journey switcher wheel,
avatar (flat cartoon in pastel circle), avatar stack, toast with sticker, empty state
(sticker + one line + one CTA), skeleton loader, streak flame badge, reaction bar
(🔥 💪 👏 ❤️ 😂), progress ring, milestone node, "departure ticket" card frame (6 skin versions:
private dossier card / quest card / bus-or-plane ticket / tear-in-half couple ticket /
race bib / minimal index card).
Touch targets ≥ 44pt. Use auto layout and variables (Light/Dark modes, 6 skin modes).
```

---

## Prompt 1: Splash, onboarding quiz và đăng nhập

```
Using the existing Ourney design system (global Soft Neo-Brutalism shell), design:
1. Splash: logo wordmark "ourney" + rotating taglines "chụp một tấm." / "giữ một chuỗi." /
   "đi cùng nhau." on cream bg with floating sticker illustrations of the 6 journey types.
2. Onboarding quiz, 3 screens, progress "Câu 1/3", big tappable answer cards with sticker art:
   Q1 "bạn đang muốn kiên trì điều gì?" → Giảm cân / Học tiếng Anh / Tập luyện / Một chuyến đi /
       Nghi thức của hai đứa / Một thói quen nhỏ
   Q2 "đi một mình hay có hội?" → Một mình / Rủ hội bạn / Chỉ hai đứa
   Q3 "bạn hay quên vào lúc nào?" → Sáng sớm / Trưa / Tối muộn
   Result screen: "hành trình đầu tiên của bạn." showing the matching journey card preview
   in its skin colors + CTA "Bắt đầu thôi".
3. Sign in: "đăng nhập." email field + CTA "Gửi mã". Then OTP: "nhập mã." 6 boxes,
   "Mã gồm 6 số vừa gửi tới {email}", resend countdown "Gửi lại sau 30s". Calm, clear copy.
4. Profile setup: avatar picker (flat cartoon avatars in pastel circles), username
   (rule hint "3–20 ký tự: a–z, 0–9, _ ."), display name.
5. Contextual permission screens (shown later, design now): camera ("để chụp tấm đầu tiên
   của hành trình.") and notifications ("để mình khẽ nhắc trước khi chuỗi đứt."), each with
   sticker, primary "Cho phép" and secondary "để sau vậy.".
Light + dark for all.
```

---

## Prompt 2: Hub, switcher và các trạng thái

```
Design the global Hub "hành trình." (shell style, floating dock visible) — light + dark:
- Top: greeting "chào Linh." + avatar button (top-right → profile).
- HERO "Hôm nay" card: the single most important next action, e.g.
  "Còn 3 tiếng để giữ 🔥 12 của IELTS 7.5" with countdown + CTA "Chụp ngay" in that journey's accent.
  Alternative hero states: all done today ("Hôm nay xong hết rồi. Mai gặp lại."),
  milestone tomorrow ("Mai là Ngày 30 — về đích!"), squad waiting ("Nam & Hà đang chờ bạn").
- Journey cards list: each card carries its own Journey DNA — sticker cover art, skin accent,
  emoji badge, title, "Ngày 12/30", streak, squad avatar stack, progress bar, next milestone name.
  Show 3 sample journeys of DIFFERENT skins: "Đà Lạt 5 ngày" (Memory Collectors, pine fog variant),
  "IELTS 7.5 squad" (Accountability Squad), "Chạy sáng 30 ngày" (Aesthetic Flexer) —
  each card visibly different in material (paper+tape / notebook polaroid / dark glass neon).
- "+ hành trình mới" card (dashed ink border, sticker).
- States: empty (sticker "chưa có hành trình nào." + CTA "Tạo hành trình đầu tiên"),
  skeleton loading, error ("không tải được. thử lại?"), offline banner
  ("đang lưu trên máy, có mạng sẽ tự gửi"), and limit reached (3 active journeys):
  sheet "bạn đang chạy 3 hành trình rồi." + options "Kết thúc một hành trình" / "Để sau".
- Journey switcher: long-press the dock shutter → arc/wheel of journey discs
  (emoji + accent color + day count), the screen tint morphs live to the focused journey.
```

---

## Prompt 3: Luồng tạo hành trình (phần chung)

```
Design the CREATE JOURNEY flow. Key idea: the screen MORPHS into the chosen journey's skin as
soon as a type is picked (background, fonts, dock material, accent). 5 steps, progress dots,
back button, every step one decision. Light + dark.

Step 1 "tạo hành trình." — horizontal swipe deck of 6 large cards, each a LIVE PREVIEW of its skin
(mini timeline + camera HUD snippet): Giảm cân ⚖️, Học tiếng Anh 📚, 30 ngày tập luyện 💪,
Chuyến đi ✈️, Hai đứa mình 💞, Tự đặt ✨. Focused card enlarges; background tint follows it.

Step 2: type-specific questions (see Prompt 4 — design one example now: Chuyến đi).

Step 3 "đi cùng ai?": Một mình / Rủ hội (tối đa 10) / Chỉ hai đứa. Picking "Chỉ hai đứa" shows a
small morph toast "chuyển sang phong cách Hai đứa mình 💞".

Step 4 "đặt nhịp.": duration chips (7 / 14 / 21 / 30 / 66 ngày / "không hẹn ngày về" for trip &
custom), daily reminder time wheel, visibility (Chỉ mình tôi / Nhóm / Có link — group journeys
never have public links, show disabled with reason).

Step 5 "đúc hành trình.": a stamping animation frame ("đang đúc DNA…"), then the DEPARTURE TICKET
reveal: a skin-specific ticket containing title, emoji, cover sticker, dates, crew avatars,
milestone names, and a short vow line. Under it: swap color variant (3 swatches) and cover (3 options).
CTA "Khởi hành" → opens camera for Day 1. For group journeys, then show invite sheet:
8-char code "K7Q2-M9XA", copy link, QR, share.
```

---

## Prompt 4: Câu hỏi riêng cho từng loại và 6 tấm vé khởi hành

```
Design Step 2 (type-specific questions) and the Step 5 departure ticket for EACH of the 6 types,
each fully in its own skin (light + dark). Big answer cards, one question per screen.

1. Giảm cân (Quiet Transformer): "mục tiêu của bạn?" Giảm cân / Giữ dáng / Thay đổi vóc dáng →
   "cân nặng hiện tại?" (optional, ruler slider, lock label "Chỉ mình bạn thấy", toggle
   "Ẩn số kg khi chia sẻ" ON by default) → "chụp ảnh ngày 1 làm khung căn dáng?" .
   Ticket = private dossier card with 🔒, "Hồ sơ riêng tư · 30 ngày", no weight number shown.
2. Học tiếng Anh (Accountability Squad): "mục tiêu?" IELTS band / Giao tiếp / Đọc sách →
   "mỗi ngày bao nhiêu phút?" 15/30/45/60 → "đặt tên chiếc cúp ở đích" input ("Cúp 7.5").
   Ticket = quest card with trophy, path preview, squad slots.
3. 30 ngày tập luyện (Aesthetic Flexer, dark-first): "môn gì?" Chạy / Gym / Pilates / Yoga / Khác →
   "đo bằng gì?" km / phút / buổi → "kiểu HUD?" Bold HUD / Minimal Stamp / Film Strip (previews).
   Ticket = race bib with big number, neon edge.
4. Chuyến đi (Memory Collectors): "đi đâu?" destination search with instant cover sticker
   suggestions (Đà Lạt → pine & fog) → "ngày đi – ngày về" calendar → "cuộn phim mấy tấm?" 24 / 36.
   Ticket = vintage bus/plane ticket with perforation, stamp "SGN → ĐÀ LẠT".
5. Hai đứa mình (Couple Rituals): "nghi thức của hai đứa?" Nấu ăn / Tiết kiệm / Yêu xa / Tự đặt →
   "tên hai người" (two inputs side by side) → "ai chụp nửa nào?" left/right preview.
   Ticket = tear-in-half couple ticket, each half one name.
6. Tự đặt (Minimalist Habit): ONE screen only: habit name + "vì sao?" one line. No more questions.
   Ticket = minimal index card, mono type, single orange line.
```

---

## Prompt 5: Bên trong hành trình, Quiet Transformer và Accountability Squad

```
Design the in-journey screens for 2 skins (light + dark each). Floating dock adopts skin material.

A) QUIET TRANSFORMER — "30 ngày cơ thể" (weight loss, private by default)
1. Journey home: header with DNA cover + "Ngày 21/30 · 🔥 21", weight trend curve card
   (numbers blurred until tap-and-hold "giữ để xem"), vertical photo nodes timeline with
   milestone stars (Ngày 7 "Tuần đầu", Ngày 14 "Nửa chặng", Ngày 30 "Về đích").
2. Camera HUD "Ghost-align": Day-1 silhouette overlay at 30% opacity, pill "🔒 Riêng tư · Ngày 21",
   weight ruler slider after capture.
3. Post-capture: caption "Hôm nay bạn cảm thấy thế nào?" + mood chips, weight input, "Đăng".
4. Check-in celebration: soft emerald seal stamp "Ngày 21 ✓", streak +1, gentle haptic note.
5. Share card: side-by-side "NGÀY 01 vs NGÀY 21", toggle "Ẩn số kg" ON, faces blur option.
6. Missed day node: hollow dashed circle "Ngày 9 · nghỉ".

B) ACCOUNTABILITY SQUAD — "IELTS 7.5 squad" (5 members)
1. Journey home: winding stepping-stone S-path of polaroids to the Day-30 trophy ("Cúp 7.5"),
   today's stone highlighted with 🔥, week badges.
2. Camera HUD: pill "📖 45 PHÚT · 🔥 21", live timestamp stamp.
3. Post-capture: minutes dial (15/30/45/60/custom), caption "Hôm nay bạn học được gì?".
4. Celebration: notebook stamp + "4/5 đứa đã điểm danh".
5. Squad today: 2×2 polaroid wall with name ✓ time + reactions, waiting slot dashed with
   "Nhắc Minh 👋" button; header bar "4/5 ĐÃ ĐIỂM DANH".
6. Share card: squad polaroid wall poster.
```

---

## Prompt 6: Bên trong hành trình, Memory Collectors và Couple Rituals

```
Design in-journey screens for 2 more skins (light + dark).

A) MEMORY COLLECTORS — "Đà Lạt 5 ngày" (5 friends, variant "Sương thông")
1. Journey home: scrapbook thread — stitched terracotta line, taped polaroids rotated -3°..3°,
   handwritten-style day labels ("Ngày 1 · Rừng thông"), paper grain, film counter "12/24".
2. Camera HUD: disposable film camera look, "CUỘN PHIM 12/24", orange LCD date stamp
   "16 THG 10 '26 · 15°C · ĐÀ LẠT".
3. Post-capture: caption "Hôm nay cả bọn lạc ở đâu?" + place tag.
4. Celebration: photo "developing" from blank to image, tape sticks on.
5. Squad today: everyone's frame of the day as a contact strip.
6. Trip end Wrapped: 4-page story (số ngày · số khung hình · nơi đã qua · ảnh đẹp nhất) then
   35mm contact sheet poster "5 NGÀY THANH XUÂN · ĐÀ LẠT" + "Chia sẻ poster".

B) COUPLE RITUALS — "30 ngày nấu cho nhau" (2 people)
1. Journey home: duo split timeline, each day a pair of photos (left: Nam, right: Linh) joined by a
   heart node; incomplete pair shows dashed half "đang chờ Linh".
2. Camera HUD: half-frame duo — left shows partner's photo of today, right is live viewfinder,
   label "Chụp nửa của bạn".
3. Celebration: two halves click together into one heart-sealed frame "Ngày 18 · đủ đôi".
4. Share card: "18 NGÀY BÊN NHAU · 36 KHOẢNH KHẮC" diptych mosaic.
```

---

## Prompt 7: Bên trong hành trình, Aesthetic Flexer và Minimalist Habit

```
Design in-journey screens for the last 2 skins (light + dark; Flexer is dark-first).

A) AESTHETIC FLEXER — "Chạy sáng 30 ngày"
1. Journey home: frosted glass header with neon sparkline "92.4 KM · 5:04 /KM TB",
   vertical glowing run nodes timeline, milestones "★ MILESTONE".
2. Camera HUD sticker studio: big condensed overlay "NGÀY 21 · 🔥 21 / 5.42 KM · 5:04 /KM",
   style chips Bold HUD / Minimal Stamp / Film Strip.
3. Post-capture: numeric keypad for km + pace, "Đăng".
4. Celebration: neon pulse ring + count-up numbers.
5. Share: 9:16 transparent story sticker + 21-bar activity heatmap, "Chia sẻ lên Story".

B) MINIMALIST HABIT — "Đọc 10 trang"
1. Journey home: "THÁNG 10 · CHUỖI 24 NGÀY" 7-column photo calendar connected by one continuous
   Braun-orange line; missed days dashed squares.
2. Camera: zero text, one tap, tiny pill "ĐỌC SÁCH · NGÀY 24".
3. Post-capture: optional — auto-posts after 3s countdown ring unless tapped to add caption.
4. Celebration: single orange dot fills the calendar cell.
5. Share: zen card "24/30 NGÀY · 96% ĐỀU ĐẶN".
```

---

## Prompt 8: Cập nhật hành trình, xem một ngày, về đích (dùng cho cả 6 skin)

```
Design shared journey-management screens, rendered in ONE example skin each but built from
skin-variable components so they work for all 6 (light + dark):
1. Day viewer (Memory Collectors example): full photo, caption, metric, "từ thư viện" label if
   imported, reactions 🔥 💪 👏 ❤️ 😂, report/block in overflow menu.
2. Edit journey "cập nhật hành trình." (Squad example): change title, emoji, cover sticker,
   color variant, reminder time, visibility; members list (owner can remove), invite code with
   "Đổi mã" (old code stops working), "Kết thúc hành trình" (destructive, confirmation sheet).
3. Milestone celebration Day 7 / Day 30 (Flexer example) with skin confetti + "Tạo thiệp".
4. Finished journey (read-only) state (Quiet Transformer example): banner "đã về đích" + Wrapped CTA.
5. Report sheet: reasons Spam / Khoả thân / Quấy rối / Tự hại / Khác; block confirmation.
```

---

## Prompt 9: Squad, hồ sơ và cài đặt (vỏ chung)

```
Design remaining shell screens (Soft Neo-Brutalism, light + dark):
1. Squad hub "squad.": per-group "Hôm nay" rows (journey accent, X/Y checked in, avatars ✓ or
   waiting), "Nhập mã mời" field (8 chars), pending invites, empty state "chưa có hội nào.".
2. Join by code: big code input, preview of the journey's ticket before "Tham gia".
3. Profile "hồ sơ.": avatar, username, stats (tổng ngày check-in, chuỗi dài nhất, hành trình đã xong),
   consistency badges (no ranking by body results), archive shelf of finished journeys showing
   their tickets.
4. Settings "cài đặt.": per-journey reminders, language vi/en, appearance light/dark/system,
   privacy, blocked users, EULA & privacy policy, danger zone "Xoá tài khoản" with clear calm copy
   "Toàn bộ dữ liệu và ảnh trên máy chủ sẽ bị xoá vĩnh viễn."
```

---

## Checklist kiểm tra sau mỗi prompt
- [ ] Có đủ light + dark, màn camera luôn tối
- [ ] Tiếng Việt có dấu không bị cắt, line-height ≥ 1.3
- [ ] Contrast chữ ≥ 4.5:1, vùng chạm ≥ 44pt
- [ ] Không dùng emoji làm icon điều hướng
- [ ] Mỗi skin nhìn khác hẳn nhau (chất liệu, font, timeline), không chỉ đổi màu
- [ ] Dock nổi giữ đúng vị trí và hành vi ở mọi skin
- [ ] Giảm cân: số kg mặc định ẩn/mờ khi chia sẻ
- [ ] Hành trình nhóm không có link công khai
