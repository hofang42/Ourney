# Ourney V2: Bộ prompt Figma Make

Cách dùng: dán **lần lượt** 12 khối prompt (0, 1, 2, 3, 4, 5A, 5B, 6, 7, 8, 9, 10) vào **cùng một** file Figma Make. Prompt 0 dựng nền móng, các prompt sau tái sử dụng component đã có. Mỗi prompt xong thì kiểm tra lại (checklist cuối file) rồi mới chạy prompt tiếp theo. Mỗi khối nằm trong một hàng rào ``` và dưới 8000 ký tự; Prompt 5 đã chia sẵn thành 5A (Quiet Transformer) và 5B (Accountability Squad), mỗi khối tự nói rõ phải giữ nguyên những gì đã có. Prompt 10 bổ sung các phần còn thiếu: trang chủ Ngày 1 của 6 skin, trạng thái tải/lỗi/rỗng trong hành trình và Hội hôm nay, chụp lại khi hôm nay đã check-in, nội dung Điều khoản/Chính sách/Liên hệ, thông báo nhắc giờ và "chuỗi sắp đứt" (mô phỏng), chuỗi đứt, ngày lỡ của Quiet và Squad, ô ảnh ẩn, rời nhóm và bị xoá khỏi nhóm. Không có giới hạn số hành trình: Hub là danh sách cuộn với 6 hành trình mẫu (mỗi skin một hành trình). Nhãn tab phải dock hiển thị là "Hội" (UI không dùng chữ "Squad"; đó chỉ là tên skin nội bộ).

Đặc tả đầy đủ: [README.md](README.md).

---

## Prompt 0: Nền móng, design tokens và component

```
Project: "Ourney" — camera-first mobile app (iOS + Android), "Locket for goals": one check-in photo per day per "journey" (weight loss, English, workout, trip, couple, custom), streaks, groups max 10. ALL UI text is Vietnamese with diacritics; no English labels (brand "Ourney" only). Frame iPhone 390×844. Everything in Light AND Dark. Camera screens are always dark.
GOAL OF THIS STEP: tokens + components IN CODE (never a page) and a RUNNABLE APP SHELL: phone frame, router, store, dock, reviewer panel outside the frame. Do NOT render a style-guide/token/component page. Themes = Light/Dark × 6 skins × 3 variants as code tokens.

APP CONTRACT (every prompt obeys it): a RUNNING PROTOTYPE APP, not a landing page or design board.
- One 390×844 phone frame centered; ONE screen at a time, content scrolls inside it. No long scrolling page, hero/marketing section or style guide as a screen.
- Entry: first run /splash > onboarding > sign-in; signed in = /camera.
- Real router, route per screen, working Back. One global store (user, journeys[] {id,type,skin,variant,name,day,streak,checkins,members,status}, activeJourneyId, theme, offline, readOnly, draft); a check-in updates Ngày/streak on Hub, journey home and Hội. NO cap on journeys: creating more is always possible. Seed "Người cũ": 6 running journeys, one per skin ("30 ngày cơ thể" Quiet, "Hội IELTS 7.5" Squad, "Đà Lạt 5 ngày" Memory, "30 ngày nấu cho nhau" Couple, "Chạy sáng 30 ngày" Flexer, "Đọc 10 trang" Minimalist), so no separate demo mode; "Người mới": none.
- POST-CAPTURE RULE (all skins): every field is optional and pre-filled with a default; shutter > post-capture > send takes at most 3 taps.
- Every button, card, tab, chip navigates or changes state; no dead ends; every sheet closes (X, drag, scrim). Real transitions: push/slide, sheet slide-up, skin morph, capture > post-capture > celebration > journey home.
- Dock is in the app shell: on Hub, journey screens, Hội; hidden in create flow, sign-in, pushed pages. Left > /hub, shutter > active journey camera (none > /create/1), right > /squad.
- REVIEWER PANEL outside the frame, grey mono, collapsible: Người mới/cũ, Light/Dark, skin, states (offline, chỉ đọc, ngày lỡ, chữ 135%, giảm chuyển động), jump to any route.
- Later prompts ADD routes to this app and link into existing screens; never rebuild.

1) SHELL (Hub, create flow, onboarding, profile, group tab, settings) — "Soft Neo-Brutalism"
- Light: bg #FFF8EE, surface #FFFFFF, ink/border #1A1A1A, muted #5A544C. Dark: bg #121212, surface #1C1B19, ink/border #F5F0E6, muted #B8B0A4.
- Primary #FF8A3D; label on it is always #1A1A1A (both modes).
- Pastels per type, label on all = #1A1A1A: mint #7EE8A2 Giảm cân, yellow #FFD84D Tiếng Anh, peach #FFB347 Chuyến đi, coral #FF7E7E Cặp đôi, lilac #CF9FFF Tập luyện, sky #7EC8E3 Tự đặt.
- "Bone": border 2px ink, hard shadow 4px 4px 0 (no blur; Light #1A1A1A, Dark #000 with border #F5F0E6), radius chip 12 / card 16 / sheet 24 / button capsule. Pressed: shadow→0, element moves 4px,4px, 110ms.
- Fonts: titles Space Grotesk Bold, lowercase, ending with a period ("hành trình.", "tạo hành trình."); body/UI Be Vietnam Pro; big numbers Space Grotesk 700 56–96pt. NEVER Outfit. Test "ệ ữ ấ ề ố" on every font; if clipped, swap to Be Vietnam Pro. Line-height 1.3–1.45. Min text 12px.
- Icons: Phosphor Bold (Duotone for illustrative), 24px. Emoji only for type badges, 🔥 streak, reactions 🔥 💪 👏 ❤️ 😂; never for navigation.
- Art: hand-drawn thick-outline stickers; photos in Polaroid frames rotated −3°…3°.

2) SIX SKIN TOKEN SETS, code only (Light bg/surface/ink · Dark bg/surface/ink). Roles: Nhấn = lines/nodes/motifs/shadows; Nút = fill of shutter and primary button, with a fixed label color; Phụ = tags/secondary. First variant is default; each skin shows 3 swatches.
- Quiet Transformer (Giảm cân): #EFF3F0/#FFF/#0F172A · #0B0F12/#151C21/#F1F5F9. Clinical, hairline cards. Heading Fraunces Light. Variants (token name, UI label in brackets; Nhấn / Nút; label #0F172A on all): Emerald (Lục ngọc) #10B981 / #FF4D6D · Sage (Xanh sage) #6B9E8A / #D9694F · Mist (Sương mù) #6E9AC0 / #E8A25C.
- Accountability Squad (Tiếng Anh): #F7F1E5/#FFFDF9/#1E1B18 · #12131A/#1D1F2B/#F8FAFC. Cream notebook. Heading Space Grotesk. Shutter and primary button are ALWAYS flame orange with ink label; violet is ONLY for group actions (invite, "Nhắc", "Đổi mã"), label #FFFFFF, role "Nhóm". Flame (Lửa): Nhấn #FF9F1C, Nút #FF9F1C label #1E1B18, Nhóm #7556F8 · Violet (Tím): Nhấn #7556F8, Nút #FF9F1C label #1E1B18, Nhóm #7556F8 · Chalk (Phấn): Nhấn #4FA36B, Nút #E9B949 label #1E1B18.
- Memory Collectors (Chuyến đi): #F4EFE6/#FFF/#231F1E · #141312/#1F1D1B/#F5F2EB. Paper grain, tape, stitching, film sprockets. Heading Fraunces + Space Mono date stamps. Sương thông: Nhấn+Nút #CC4A2F label #FFFFFF, Phụ #4A6B53 · Biển muối: #2F6F8F label #FFFFFF, Phụ #D9A441 · Phố đêm: #7B5EA7 label #FFFFFF, Phụ #E0A43A.
- Couple Rituals (Cặp đôi): #F9F0EE/#FFF/#261F22 · #171215/#241C21/#FCE7F3. Radius 24, paired frames. Heading Playfair Display (caps letter-spaced, big italic numerals), captions Be Vietnam Pro. Rose (Hồng): Nút #E15B72 label #1A1316, Phụ #9D174D · Berry (Mâm xôi): Nút #9D174D label #FFFFFF, Phụ #E15B72 · Peach (Đào): Nút #F08A6B label #1A1316, Phụ #B4533A.
- Aesthetic Flexer (Tập luyện, dark-first): #F3F4F6/#FFF/#090A0F · #090A0F/#14161F/#F8FAFC. Frosted glass + 1.5px glow stroke. Numerals Barlow Condensed Bold. Neon Lime (Lime neon): Nhấn #3DE88C, Nút #FF4D6D · Electric Coral (San hô điện): Nhấn #FF4D6D, Nút #3DE88C · Ice (Băng): Nhấn #7DD3FC, Nút #C4B5FD. Label on all = #090A0F.
- Minimalist Habit (Tự đặt): #F5F3EE/#FFF/#1C1C1E · #0E0E10/#18181B/#F4F4F5. Content uses 1px grid, zero ornament. Heading Space Grotesk Light. Orange (Cam): Nút #EA580C label #1C1C1E · Charcoal (Than): Nút #27272A label #FFFFFF (Dark: Nút #F4F4F5 label #0E0E10) · Sky (Trời): Nút #0EA5E9 label #1C1C1E. Phụ #27272A.
BONE KEPT IN EVERY SKIN on dock, primary button and chip (hard shadow, no blur; only material and size change): Quiet 1.5px + 2px 2px 0 · Squad 2px + 3px bottom lip · Memory 2px + 3px 3px 0, "glued" look · Couple 2px + 3px 3px 0, radius 24 · Flexer 1.5px glow + 4px 4px 0 in Nhấn · Minimalist 2px ink + 3px 3px 0 on dock, primary button AND chip (cards/content stay 1px grid, no shadow; the shutter is not the only bordered element).
Safe text pairs (≥4.5:1; ink = the skin's ink): never use an accent as text except: Quiet Dark #10B981/#FF4D6D; Squad Dark #FF9F1C, Light #7556F8 only on surface; Memory Light #CC4A2F and #4A6B53 only on surface; Couple Light #9D174D, Dark #E15B72; Flexer Dark #FF4D6D/#3DE88C; Minimalist Light #27272A, Dark #EA580C. Every other accent is only fill, line, shadow or decoration. State is always shown by label or shape too, never color alone.

3) COMPONENTS in code (shell + 6 skin variants via theme modes; states default/pressed/disabled/focus)
- Button primary/secondary/ghost/destructive: 52pt (compact 44), label wraps to 2 lines, height grows.
- Card (cover sticker, title, "Ngày 12/30", streak, avatars, progress, next milestone); chip (≥44pt, selected = fill + check icon); input; OTP 6 boxes; big answer card; sheet (grab handle, close button, tap-outside); avatar; toast; empty; skeleton; streak badge; reaction bar; progress ring; milestone node (done ✓ / current ring / dashed); 6 departure tickets.
- FLOATING DOCK, identical position and behavior in every skin: capsule 358×64, 12 above safe area; left "Hành trình" (Phosphor MapTrifold), centre shutter 72pt circle raised 20pt (fill = active journey's Nút color, Phosphor Camera 32), right "Hội" (UsersThree). Tabs: icon 24 + label 12px, tap area 64×56; active = Fill weight + pill behind + bold label. Skin changes ONLY material (see BONE list above and the skin prompts).
- JOURNEY WHEEL: long-press shutter 400ms → scrim + a horizontal, scrollable arc (radius 110) of 56pt discs, ONE PER JOURNEY with no cap (type emoji + Nhấn fill + "Ngày 12"), and ALWAYS a dashed "+ mới" disc last (> /create/1). Choose by TAPPING a disc: it scales 1.15× with its title, sets activeJourneyId, the screen tints to it and the wheel closes. No drag-and-release selection. Scrim tap or X closes without change. Tappable "đổi hành trình" alternative for screen readers.

4) ACCESSIBILITY
- Dynamic Type 1.35× (panel toggle "chữ 135%"): hug layout, wrap instead of truncate, dock above the home indicator. Reduce Motion (panel toggle): every animation becomes a 150ms cross-fade. Contrast ≥4.5:1 text, ≥3:1 icons/borders, tap ≥44pt.

FORBIDDEN: long scrolling page, landing page, style guide as a screen; one long form; skins that only change color; 7-column photo grid outside Minimalist; text under 12px; mixed English/Vietnamese; dead-end buttons; two same-job primary buttons; pre-ticked share lists; stock photos; fixed shutter color; sheets that cannot close.
```

### Checklist kiểm tra Prompt 0
- [ ] Preview là khung điện thoại 390×844 chạy được, một màn mỗi lần; KHÔNG có trang style guide, trang token hay trang cuộn dài nào làm màn
- [ ] Bấm dock: "Hành trình" đổi route sang /hub, "Hội" sang /squad, nút chụp mở camera; bấm Back quay lại được; mọi nút đều làm gì đó
- [ ] Bảng duyệt nằm NGOÀI khung, thu gọn được; bấm đổi Sáng/Tối, skin, trạng thái (offline, chỉ đọc, ngày lỡ, chữ 135%) thì app trong khung đổi theo
- [ ] Token trong code đủ 6 skin, mỗi skin Light + Dark và 3 biến thể; nút có nhãn đúng màu đã ghi (nhãn trắng trên #7556F8 chỉ cho hành động nhóm, nút chụp Squad là cam #FF9F1C nhãn ink, nhãn #1A1A1A trên cam #FF8A3D)
- [ ] Tiêu đề shell là Space Grotesk chữ thường có dấu chấm cuối; không có Outfit; "ệ ữ ấ" không bị cắt
- [ ] Không có chữ nhỏ hơn 12px; chip và nút cao tối thiểu 44pt, chữ ngắt dòng ở khung 135%
- [ ] Dock đúng 3 mục (Hành trình / nút chụp 72pt nhô lên / Hội), cùng vị trí ở cả 7 chất liệu; chỉ chất liệu đổi
- [ ] Dock, nút chính và chip của Minimalist có viền 2px + bóng cứng 3px 3px 0 (không chỉ nút chụp)
- [ ] Vòng xoay đổi hành trình cuộn được, mỗi hành trình một đĩa ≥56pt, luôn có đĩa "+ mới" ở cuối; chọn bằng cách bấm một đĩa (không kéo thả), đĩa được chọn to hơn và hiện tên; có cách đổi không cần nhấn giữ
- [ ] Component có đủ trạng thái nhấn, vô hiệu, focus; bật "chữ 135%" ở bảng duyệt thì chữ không bị cắt
- [ ] Bật Giảm chuyển động ở bảng duyệt thì mọi hoạt ảnh thành cross-fade; nhấn giữ nút chụp 400ms mở vòng xoay, bấm một đĩa để chọn hành trình
- [ ] Chip chọn có dấu tích hoặc hình dạng, không chỉ đổi màu
- [ ] Icon điều hướng là Phosphor, không có emoji; emoji chỉ ở huy hiệu loại, 🔥 và reaction

---

---

## Prompt 1: Splash, onboarding, đăng nhập email OTP, xin quyền và vào thẳng camera

```
Using the existing Ourney design system from Prompt 0 (shell tokens, button, input, OTP input, answer card, sheet, toast, floating dock): KEEP everything built and ADD these screens to the same file. Do not rebuild the app or tokens.
All UI text Vietnamese with diacritics (only brand "ourney" stays). Frame 390x844, padding 24, light AND dark for all except camera (always dark #0B0B0B). Headings Space Grotesk Bold lowercase + period; body Be Vietnam Pro 16, nothing under 12px, line-height 1.3-1.45; never Outfit. Targets >= 44pt. Text on primary #FF8A3D is ink #1A1A1A. Errors: #B3261E (light) / #FF9C94 (dark) for text, border, icon; always a Phosphor WarningCircle + a sentence, never color alone. Tone: calm, clear, short, never blame ("Mã chưa đúng", not "Bạn nhập sai").
Connected flow: splash > onboarding 1/3-3/3 > đăng nhập > nhập mã > hồ sơ > camera. Returning user: splash > camera directly, no Hub. NO permission is asked before sign-in ends.

1. SPLASH (3 tagline frames + returning-user frame)
Bg #FFF8EE / #121212. Wordmark "ourney" Space Grotesk Bold 56 + solid 12px #FF8A3D dot, centered. Tagline Medium 18 muted, cross-fading: "chụp một tấm." > "giữ một chuỗi." > "đi cùng nhau." Six hand-drawn stickers (2px outline, rotated -8..8 deg) around, clear of the wordmark: cân mint #7EE8A2, sách yellow #FFD84D, quả tạ lilac #CF9FFF, vali peach #FFB347, hai trái tim coral #FF7E7E, bút chì sky #7EC8E3. Returning frame: wordmark + loader ring, no tagline, under 1s. Reduce Motion: static, first tagline.

2. ONBOARDING (exactly 3 screens)
Top: back 44pt (2-3), "Câu 1/3" SemiBold 14 + 3-segment bar (done filled, current thick border), ghost "Bỏ qua" 44pt right. Title 32. Bottom primary "Tiếp tục" 52; disabled = dashed border, not just faded.
Card: surface, 2px ink border, shadow 4px 4px 0, radius 16, sticker in 56px pastel circle. Selected = pastel fill, shadow 0 + shift 4px, 3px border, Phosphor Check badge.
Q1 "bạn đang muốn kiên trì điều gì?" 2x3 cards 165x132: Giảm cân (mint) / Học tiếng Anh (yellow) / Tập luyện (lilac) / Một chuyến đi (peach) / Nghi thức của hai đứa (coral) / Một thói quen nhỏ (sky).
Q2 "đi một mình hay có hội?" cards 342x88 + sub-line: Một mình "chỉ mình bạn thấy" / Rủ hội bạn "tối đa 10 người" / Chỉ hai đứa "ghép đôi, chỉ hai người".
Q3 "bạn hay quên vào lúc nào?" cards 342x72: Sáng sớm "gợi ý nhắc lúc 07:00" / Trưa "gợi ý nhắc lúc 12:00" / Tối muộn "gợi ý nhắc lúc 21:30". After a pick, a result block appears above the button (no 4th screen): "hành trình đầu tiên của bạn." + mini journey card in the Q1 pastel, Polaroid sticker rotated 2 deg, title "học tiếng anh.", chips "Rủ hội bạn", "Nhắc 21:30"; button becomes "Bắt đầu thôi". Q2 = Chỉ hai đứa gives the coral Couple look + hint "mình sẽ dùng phong cách Hai đứa mình". Answers only prefill the create flow.

3. ĐĂNG NHẬP
Envelope sticker (sky #7EC8E3, 120px). "đăng nhập." Sub "Nhập email, mình gửi mã 6 số để vào. Không cần mật khẩu." Label "Email", input 56 + Phosphor Envelope, placeholder "ten@email.com"; focus = 2px border + shadow 4px #FF8A3D. Primary "Gửi mã". Legal 13px: "Tiếp tục nghĩa là bạn đồng ý Điều khoản sử dụng và Chính sách quyền riêng tư." (2 links, 44pt rows).
States: "Email chưa đúng dạng. Ví dụ: ten@gmail.com" / đang gửi ("Đang gửi…", field locked) / offline banner "Chưa có mạng nên chưa gửi được mã. Bật mạng rồi thử lại." + "Thử lại" / server "Chưa gửi được mã. Thử lại sau ít phút."

4. NHẬP MÃ (number keyboard open)
Back 44pt. "nhập mã." Sub "Mã gồm 6 số vừa gửi tới linh.tran@gmail.com" (email bold) + text button "Đổi email". Six boxes 48x58, gap 8, 2px border, radius 12, digit Space Grotesk 28; active box shadow 4px #FF8A3D; paste/autofill 6 digits, auto-check at the 6th. Primary "Xác nhận" above keyboard. Resend: timer ring + "Gửi lại sau 30 giây" muted, at 0 becomes secondary "Gửi lại mã". Helper 13px "Không thấy thư? Xem mục thư rác hoặc quảng cáo."
States: "Đang kiểm tra…" (boxes locked) / "Mã chưa đúng. Kiểm tra lại 6 số trong email rồi nhập lại." (error boxes, no shake) / "Mã đã hết hạn. Gửi mã mới để tiếp tục." with "Gửi mã mới" primary / "Bạn đã thử nhiều lần. Chờ vài phút rồi thử lại." (boxes disabled) / toast "Đã gửi mã mới. Mã cũ không dùng được nữa." / offline banner / success: checks 0.4s then "Xong rồi. Chào bạn."

5. HỒ SƠ
"hồ sơ của bạn." 96px flat-cartoon avatar + row of 6 pastel options (48px). Inputs "Tên hiển thị" (Linh), "Tên người dùng" prefix "@", hint "3–20 ký tự: a–z, 0–9, _ ." Status icon + text: "Dùng được" / "Tên này đã có người dùng" / "Chỉ dùng a–z, 0–9, _ ." Primary "Xong".

6. XIN QUYỀN ĐÚNG NGỮ CẢNH (sheets radius 24 with sticker, X 44pt, drag-down + tap-outside close; primary "Cho phép", text "để sau vậy.")
a) Camera, on first arrival at camera: "cho ourney dùng camera." / "Để chụp tấm đầu tiên của hành trình. Ảnh chỉ hiện với người trong hành trình đó."
b) Thông báo, after the first check-in celebration: "để mình khẽ nhắc trước khi chuỗi đứt." / "Mỗi ngày một lần, đúng giờ bạn đặt. Tắt lúc nào cũng được trong cài đặt." Not asked again after "để sau vậy."
c) Camera cards instead of black: "camera chưa bật." + "Bật camera" + "Chọn ảnh từ thư viện"; denied: "camera đang tắt." / "Vào Cài đặt của máy, mục ourney, để bật lại." + "Mở cài đặt" + library button.

7. VÀO THẲNG CAMERA (dark, dock from Prompt 0)
Viewfinder: gradient #1A1A1A > #0B0B0B, 4 corner brackets, no stock photo. Top: journey chip 44 high in last journey's pastel, ink "Hội IELTS 7.5 · Ngày 21/30" + chevron; flash and flip 44pt right. Dock: "Hành trình", 72pt shutter in journey accent (example #FF9F1C, icon ink #1E1B18), "Hội"; labels >= 12px.
Frames: (1) ready; (2) offline pill "đang lưu trên máy, có mạng sẽ tự gửi"; (3) no journey yet: dimmed viewfinder, shutter disabled (dashed ring), card with sticker "chưa có hành trình nào." / "Mỗi tấm ảnh cần một hành trình để cất." / chip "gợi ý: Học tiếng Anh · rủ hội bạn" / the ONLY primary "Tạo hành trình đầu tiên"; (4) sheet 6a; (5) cards 6c; (6) sheet "phiên đăng nhập đã hết." / "Đăng nhập lại để đồng bộ. Ảnh trên máy vẫn còn nguyên." / "Gửi mã".

8. NAVIGATION & INTERACTION (Điều hướng & tương tác). Keep the existing app and wire these screens into it. Routes: /splash, /onboarding/1-3, /login, /otp, /profile-setup, /camera (permission sheets and empty/denied cards are overlays on /camera).
- Entry: first run /splash; returning user (panel "Người cũ") /splash > /camera in <1s, no Hub.
- Splash: taglines auto-advance, tap = skip > /onboarding/1. "Tiếp tục" pushes the next screen, back pops, "Bỏ qua" > /login. Q1-Q3 answers are saved to store.draft (type, who, reminder time) and later preselect /create/1 and step 4. Result block "Bắt đầu thôi" > /login.
- "Gửi mã" > /otp (shows the typed email; "Đổi email" pops back). Demo code 123456 > success > /profile-setup; other codes show the error states; panel can force expired/locked/offline. "Xong" saves store.user > /camera.
- /camera first arrival: camera sheet 6a; "Cho phép" > live viewfinder, "để sau vậy." > card 6c. No journey: ONLY CTA "Tạo hành trình đầu tiên" > /create/1 (prefilled by draft). With journeys: top chip opens the journey wheel (same as long-press), shutter > /j/:id/post (Prompts 5-7 build post-capture; until then it returns to /hub), dock "Hành trình" > /hub, "Hội" > /squad.
- Notification sheet 6b appears once, after the first celebration, then returns to /j/:id. Session sheet "Gửi mã" > /otp; closing it stays on /camera.
FORBIDDEN too: long scrolling page, landing page, style guide as a screen.

DO NOT: long form or name-only setup; skins that only recolor; text under 12px or targets under 44pt; mixed English/Vietnamese; blank black screens, dead ends, sheets that cannot close; two same-action primaries (shutter + card CTA); fixed-color shutter; stock photos; pre-ticked options; permission asks before sign-in; promising push notifications.
```

### Checklist Prompt 1
- [ ] Luồng nối được: splash, 3 màn onboarding, đăng nhập, nhập mã, hồ sơ, camera; người dùng cũ đi từ splash thẳng sang camera
- [ ] Mọi màn có light + dark (camera chỉ tối), chữ tiếng Việt đủ dấu, không nhãn tiếng Anh ngoài "ourney"
- [ ] Onboarding đúng 3 màn, có "Câu n/3" kèm thanh 3 đoạn, nút "Bỏ qua", thẻ chọn có dấu tick và bóng về 0
- [ ] Ô nhập mã có đúng 6 ô; có đủ trạng thái đang kiểm tra, sai, hết hạn, thử nhiều lần, không mạng, thành công, đã gửi lại
- [ ] "Gửi lại sau 30 giây" có vòng đếm, hết giờ thành nút "Gửi lại mã"
- [ ] Mọi lỗi có biểu tượng cảnh báo cộng một câu chữ, không chỉ đổi màu; câu lỗi không đổ lỗi cho người dùng
- [ ] Không có màn xin quyền nào trước khi đăng nhập xong; quyền camera hiện ở camera, thông báo hiện sau lần check-in đầu
- [ ] Mỗi sheet quyền có nút X, "để sau vậy." và đóng được bằng kéo xuống; từ chối thì camera vẫn có thẻ nội dung, không màn đen trống
- [ ] Camera chưa có hành trình chỉ có một nút chính; nút chụp mang màu hành trình, không cố định
- [ ] Không chữ nào dưới 12px, mọi nút và dòng link cao ít nhất 44pt, chữ trên nền cam là màu ink
- [ ] Bấm "Tiếp tục" qua 3 câu onboarding rồi "Bắt đầu thôi" → ra đăng nhập; bấm "Bỏ qua" ở bất kỳ câu nào cũng ra đăng nhập
- [ ] Gõ email, bấm "Gửi mã" → sang nhập mã; nhập 123456 → hồ sơ → bấm "Xong" vào camera; bấm "Đổi email" quay lại được
- [ ] Bảng duyệt chọn "Người cũ" → splash vào thẳng camera; chọn "Người mới" → camera chỉ có nút "Tạo hành trình đầu tiên", bấm → mở bước 1 tạo hành trình
- [ ] Bấm "để sau vậy." ở sheet quyền camera → hiện thẻ "camera chưa bật" có nút; đóng sheet bằng X, kéo xuống, chạm nền đều được
- [ ] Không có trang cuộn dài, landing page hay style guide làm màn

---

## Prompt 2: Hub, switcher và các trạng thái

```
KEEP everything already built in this Make file (design system, splash, onboarding, sign-in). Do NOT rebuild the app. ADD the Hub screens below on 390×844, each in light + dark, reusing existing components (journey card, dock, sheet, chip, skeleton, toast). All UI text Vietnamese with diacritics, min 12px, line-height 1.35, touch targets ≥44pt, Dynamic Type 1.35x must not clip. Status never relies on color alone (always icon/shape/label).

SCREEN 1 — Hub "hành trình." (shell Soft Neo-Brutalism, L bg #FFF8EE / D bg #121212; cards 2px ink border, 4px 4px 0 hard shadow, radius 16; dark shadow = #000 with border #F5F0E6). Top to bottom, side padding 20:
a) Row: Space Grotesk Bold 28 "chào Linh." + avatar button top-right, 44×44 circle, pastel #7EC8E3, 2px ink border, flat cartoon face (opens profile).
b) HERO card "Hôm nay", one action only, in the accent of the journey it concerns. Default: label "HÔM NAY" (12px caps chip), headline "Còn 3 tiếng để giữ 🔥 21 của IELTS 7.5" (Space Grotesk 22), timer row (Phosphor Timer icon + "03:12:40"), ONE button "Chụp ngay" 52pt capsule, fill #FF9F1C, label ink #1E1B18. Show 3 alt hero states as separate frames: done "Hôm nay xong hết rồi. Mai gặp lại." (sticker of a sleeping cat, no button); milestone "Mai là Ngày 30 — về đích!" (flag sticker, button "Chụp ngay"); hội "Nam & Hà đang chờ bạn." (2 avatars, button "Chụp ngay"). Button label colors: terracotta #CC4A2F → white; coral #FF4D6D or #EA580C → ink; lilac/pastel → ink.
c) Section title "hành trình của bạn." + chip "6 đang chạy" (icon + text, live count, no cap) and a vertically scrolling list of 6 seeded DNA journey cards, one per skin, in this order: Quiet, Squad, Memory, Couple, Flexer, Minimalist (358×176, 16 gap). Each card = hand-drawn sticker cover 80×80 on a type-pastel disc (rotated -3°..3°), emoji badge, title, "Ngày 12/30", flame icon + streak number, "40%", progress bar WITH segment ticks, avatar stack (flat avatars, +N), next-milestone line. Materials MUST differ:
 • "Đà Lạt 5 ngày" — Memory Collectors, pine-fog variant: paper #F4EFE6 with grain, strip of masking tape on top-left, stitched terracotta #CC4A2F line under title, Fraunces title, mono stamp "NGÀY 3/5 · 60%", film counter "12/24", cover peach #FFB347 pine-and-fog sticker, milestone "Mốc kế: Ngày 3 · Giữa chuyến". Dark: #1F1D1B paper.
 • "Hội IELTS 7.5" — Accountability Squad: cream #FFFDF9 notebook with ruled lines, 3px bottom lip, white polaroid tilted 2° holding a yellow #FFD84D trophy sticker, S-path mini preview, "Ngày 21/30 · 🔥 21 · 70%", stack of 5 avatars "3/5 đã điểm danh" (seed trước khi người dùng check-in; sau check-in hiển thị "4/5 đã điểm danh", khớp Prompt 5B), milestone "Mốc kế: Ngày 30 · Về đích".
 • "Chạy sáng 30 ngày" — Aesthetic Flexer: always dark glass #14161F, 1px lime #3DE88C glow stroke, hard neon shadow 4px 4px 0 #3DE88C, Barlow Condensed numerals "21/30", neon sparkline, lilac #CF9FFF cover sticker, milestone "★ Mốc kế: Ngày 30 · Về đích".
 • "30 ngày cơ thể" — Quiet Transformer: white card on #EFF3F0, 1px hairline, soft diffuse shadow, no rotation, Fraunces title, emerald curve with NO numbers and a blurred photo node, chip "🔒 Riêng tư", mint cover sticker, "Ngày 21/30 · 🔥 21 · 70%", milestone "Mốc kế: Ngày 30 · Về đích".
 • "30 ngày nấu cho nhau" — Couple Rituals: blush card radius 24, two photo halves joined by a rose heart, Playfair caps, avatars "Nam | Linh", coral cover sticker, "Ngày 18/30 · 🔥 18 · 60%", milestone "Mốc kế: Ngày 30 · Tròn 30 ngày".
 • "Đọc 10 trang" — Minimalist Habit: flat card, 1px grid, zero ornament, mini 7-column strip joined by one orange line, sky cover, "24/30 NGÀY · 80% ĐỀU ĐẶN", UPPERCASE labels, milestone "MỐC KẾ: NGÀY 30".
 Text on every card ≥4.5:1; accent colors are only fills/strokes, never small text on light.
d) After the last card: "+ hành trình mới" card (2px DASHED ink border, sticker of a paper plane, text "hành trình mới." / "chọn một thế giới để bắt đầu").
e) FLOATING DOCK 358×64 capsule (surface, 2px ink border, 4px hard shadow), 12 above safe area, list has 140 bottom padding. Left: Phosphor MapTrifold icon + "Hành trình" (active: Duotone icon + underline pill + bold). Center: raised 72pt round shutter, Phosphor Camera Bold 32, fill = active journey accent (here #FF9F1C, icon ink), 2px ink border. Right: Phosphor UsersThree + "Hội". VoiceOver: "Chụp ảnh cho IELTS 7.5. Nhấn giữ để đổi hành trình."

SCREEN 2 — States (frames):
• Empty: no cards; sticker "chưa có hành trình nào." + sub "một tấm mỗi ngày, giữ được cả chặng đường." + ONE CTA "Tạo hành trình đầu tiên"; shutter is shell primary orange #FF8A3D with ink icon; it opens create (no dead end).
• Loading: skeleton hero + 3 skeleton cards with real card shapes, shimmer (Reduce Motion: static).
• Error (no cached data): sticker + "không tải được. thử lại?" + button "Thử lại". If cache exists show it instead.
• Offline: sticky banner under greeting, #7EC8E3 fill, 2px ink border, Phosphor CloudSlash icon + "đang lưu trên máy, có mạng sẽ tự gửi". Everything still works. Card with an unsent photo shows chip (clock icon) "chờ gửi · 1 ảnh"; after sync a toast with sticker "đã gửi xong."
• NO LIMIT: there is never a locked card, a "đủ 3" state or a limit sheet. The list scrolls (dock floats over it, 140 bottom padding) and "+ hành trình mới" is always the last item. Show one frame scrolled to the last cards.

SCREEN 3 — Journey switcher: long-press (400ms) the shutter → scrim 60% and a horizontally scrollable arc of 56pt discs above the shutter, one per journey (emoji + accent fill + "Ngày 21"); a dashed "+ mới" disc is always last. TAP a disc to choose: it scales to 72pt with its name below ("Hội IELTS 7.5 · Ngày 21/30"), the Hub bg tint morphs to that journey (12% accent over bg, 320ms; Reduce Motion: instant), the shutter fill morphs to its accent and the wheel closes. No drag-and-release. Scrim tap/X = cancel. Show 3 frames: wheel open with 6 discs + "+ mới"; wheel scrolled to the last discs; after choosing Đà Lạt (shutter #CC4A2F icon white). Shutter accents: Quiet #FF4D6D, Squad #FF9F1C (ink), Memory #CC4A2F (white), Couple #E15B72, Flexer #FF4D6D, Minimalist #EA580C. Accessible alternative: a card's "đặt làm chính" menu does the same.

NAVIGATION & INTERACTION (Điều hướng & tương tác). Keep the existing app and wire the Hub into it. Route /hub; dock "Hành trình" active.
- Reached from: dock "Hành trình" on any screen, after the create flow closes (X), back from /me, /j/:id and /squad.
- Dock: "Hội" > /squad; shutter tap > /j/:activeId/camera (if today is done: "chụp lại" mode, Prompt 10); long-press 400ms or tap on the camera journey chip = wheel (tapping a disc sets activeJourneyId, screen stays on /hub, shutter and tint recolour; "+ mới" > /create/1; scrim/X = cancel; "đặt làm chính" in a card menu does the same).
- Avatar > /me (push). Hero "Chụp ngay" > /j/:id/camera of the journey it names; after a check-in the hero flips to the "done" state and the card's Ngày, streak, % and progress update from the store.
- Journey card tap > /j/:id (push; theme morphs to that skin 320ms). Chip "chờ gửi · 1 ảnh" shows a toast; after sync "đã gửi xong." toast.
- "+ hành trình mới" and every empty-state CTA > /create/1; always available, no limit. Ending a journey (/j/:id/edit) turns its card read-only (lock chip, stays in the list). Error "Thử lại" > normal list.
- Panel states (trống, đang tải, lỗi, offline) re-render this same route.
FORBIDDEN too: long scrolling page, landing page, style guide as a screen.

FORBIDDEN (V1 mistakes): flat list with one mold for all journeys; skin = color only; 7-column photo calendar on cards; text <12px or targets <44pt; mixing English UI text; black/empty screens, dead-end buttons; two primary buttons with the same job (no extra "Check In" FAB next to the shutter); stock photos (use stickers/polaroids); fixed-color shutter; sheet that cannot be closed; Outfit font; emoji as navigation icons.
```

### Checklist Prompt 2
- [ ] Greeting "chào Linh." và avatar 44×44 ở góc trên phải; không có chữ tiếng Anh nào
- [ ] Hero chỉ có MỘT nút "Chụp ngay"; đủ 4 trạng thái hero
- [ ] Hub có 6 thẻ, mỗi skin một thẻ, khác hẳn chất liệu (hồ sơ hairline phẳng / sổ polaroid / giấy + băng keo / đôi ảnh bo 24 + tim / kính tối neon / lưới 1px); mỗi thẻ có bìa sticker, Ngày N/M, streak (icon + số), %, thanh tiến độ; danh sách cuộn được
- [ ] Dock nổi 3 mục, nút chụp 72pt đúng màu hành trình đang chọn, không có nút Chụp thứ hai
- [ ] Đủ 4 trạng thái: trống, skeleton, lỗi, offline (banner + chip "chờ gửi"); không có giới hạn số hành trình
- [ ] Không có thẻ khoá, sheet giới hạn hay chữ "đủ 3" ở bất kỳ đâu; "+ hành trình mới" luôn ở cuối danh sách
- [ ] Vòng xoay nhấn giữ: cuộn được, mỗi hành trình một đĩa ≥56pt, luôn có đĩa "+ mới" cuối; bấm một đĩa để chọn, đĩa chọn to 72pt có tên, nền và nút chụp đổi màu theo
- [ ] Nhãn nút trên màu accent đúng quy định (trắng trên #CC4A2F, ink trên các màu còn lại), light + dark đều đủ
- [ ] Bấm thẻ hành trình → mở trang chủ hành trình đúng skin, bấm quay lại → về Hub
- [ ] Bấm "Chụp ngay" ở hero → mở camera đúng hành trình; bấm avatar → mở hồ sơ; bấm "Hội" ở dock → mở tab Hội
- [ ] Nhấn giữ nút chụp, bấm một đĩa khác → nút chụp và màu nền đổi, vẫn ở Hub; bấm "+ hành trình mới" → mở bước 1 tạo hành trình
- [ ] Kết thúc một hành trình ở trang cập nhật → thẻ đó thành chỉ đọc (có khoá), vẫn nằm trong danh sách; "+ hành trình mới" vẫn còn
- [ ] Không trang cuộn dài, không landing page, không style guide làm màn

---

## Prompt 3: Luồng tạo hành trình (phần chung)

```
Continue in the SAME Figma Make file. KEEP everything already built (Prompt 0 tokens and components, Prompt 1-2 screens). Do NOT rebuild the app or restyle old screens. ADD only the CREATE JOURNEY frames below: step 1, step 3, step 4, and the hand-off frame into step 5. Step 2 (type questions) and the 6 departure tickets come in the next prompt: do not design them here.
iPhone 390x844. Every frame in Light AND Dark. All UI text is Vietnamese with diacritics (no English labels, except the brand "Ourney"). Body Be Vietnam Pro 16 (min 12), line-height 1.35, never Outfit. Touch targets >= 44pt. A selected state is never colour-only: thick border + check icon + text "Đã chọn". Dynamic Type 1.35x: text wraps, cards grow, nothing clips. Reduce Motion: morph becomes a 150ms crossfade.

FLOW RULES
- 5 steps, one decision per screen, never one long form. Top bar: back button 44pt, text "bước 1/5" + 5 dots (current dot = wider pill), close X 44pt. X opens a sheet "thoát khỏi việc tạo?" / "Chưa lưu gì cả." / "Ở lại" / "Thoát"; every sheet closes by X, drag-down and tap outside.
- Titles: lowercase + period. Shell = Space Grotesk Bold. After a skin is chosen the whole screen MORPHS (320ms easeOutCubic): background, heading font, card material, chip shape, action bar and accent change together. Show it as a before/after frame pair.
- The floating dock is hidden during creation. Bottom = ONE capsule action bar 52pt in the chosen skin's dock material holding the ONLY primary button on the screen.
- Label colour on the primary button (same in Light and Dark): Quiet #0F172A on #FF4D6D; Squad #1E1B18 on #FF9F1C; Memory #FFFFFF on #CC4A2F; Couple #1A1316 on #E15B72; Flexer #090A0F on #FF4D6D; Minimal #1C1C1E on #EA580C; shell #1A1A1A on #FF8A3D. Accent colours are never used as text colour.
- Offline: banner "đang lưu trên máy, có mạng sẽ tự gửi"; the flow still works.

STEP 1 "tạo hành trình." (shell bg #FFF8EE / #121212)
Subtitle "vuốt để xem, chạm để chọn." Horizontal snap deck of 6 cards, focused card 300x460, neighbours peek at 0.88 scale. Page background cross-fades to the focused skin's bg while swiping; text stays that skin's ink. Each card is a LIVE PREVIEW (sticker art + sample data, NO stock photos) with a different layout and material: badge + name on top, mini timeline in the middle, camera HUD snippet at the bottom, then a tagline in that skin's voice:
1 Giảm cân ⚖️ Quiet Transformer: hairline 1px card, Fraunces; emerald weight curve with 3 blurred photo nodes, lock icon + "Riêng tư"; HUD = ghost body outline. "nhẹ nhàng, chỉ mình bạn thấy."
2 Học tiếng Anh 📚 Accountability Squad: cream notebook, 2px border + 3px lip; S-shaped stone path to a trophy; HUD pill "📖 45 PHÚT · 🔥 21". "điểm danh đủ hội nào!"
3 30 ngày tập luyện 💪 Flexer: dark frosted glass, glowing 1px stroke, Barlow Condensed; neon lime pace sparkline; HUD sticker "5,2 KM · 5:48". "km. pace. xong."
4 Chuyến đi ✈️ Memory: paper grain, masking tape, taped Polaroid, stitched terracotta thread, Space Mono stamp "CUỘN PHIM 12/24". "nhớ từng chặng đường."
5 Hai đứa mình 💞 Couple: 24px radius diptych, two photos side by side with a heart node. "mỗi ngày một cặp ảnh."
6 Tự đặt ✨ Minimal: 1px grid, zero ornament, 7-column mini calendar joined by one orange line, one round shutter. "chụp."
Under the deck: prev/next arrow buttons 44pt, label "2/6", and a screen-reader label "Thẻ 2 trên 6, Học tiếng Anh". Primary "Chọn kiểu này" in the focused skin's accent. Tapping the CTA or the card = morph into that skin and go to step 2.
Frames: Giảm cân focused (Light), Chuyến đi focused (Dark), Hai đứa mình (Light), 30 ngày tập luyện (Dark), Tự đặt (Light).

STEP 3 "đi cùng ai?" (already in the chosen skin)
Three big answer cards (min height 96): "Một mình" / "chỉ bạn và chiếc máy ảnh."; "Rủ hội" / "tối đa 10 người, mời bằng mã."; "Chỉ hai đứa" / "một cặp, một nhịp." Each has a sticker and a Phosphor icon; captions are rewritten in the skin's voice. Note under "Rủ hội": "Mã mời có sau khi khởi hành." Offline: add "Cần có mạng để tạo mã mời."
Picking "Chỉ hai đứa" from any other skin MORPHS to Couple Rituals (rose #E15B72, berry #9D174D, radius 24): toast "chuyển sang phong cách Hai đứa mình 💞" with 44pt "Hoàn tác" restoring the previous skin; re-picking Một mình or Rủ hội also restores it.
The switch KEEPS the step 2 answers and the old type's rules (e.g. Giảm cân still hides kg and blurs shared photos); only the skin changes. It then asks TWO extra screens inside step 3 (dots stay 3/5, chip "Thêm 1/2" and "Thêm 2/2", same layouts as Prompt 4 Couple Q2 and Q3): "tên hai người." (inputs "Tên bạn" / "Tên người ấy") and "ai chụp nửa nào?" ("Mình bên trái" / "Mình bên phải"). If Couple was chosen in step 1, these were already asked in step 2: never repeat them. "Hoàn tác" drops the two screens and restores the old skin and answers. Frames: Accountability Squad Light before + Couple Dark after (with toast), same for the opposite direction in one pair.

STEP 4 "đặt nhịp." three blocks only, never repeat anything asked in step 2:
a) Thời lượng, chips (min 44pt, text 14+) 7 / 14 / 21 / 30 / 66 ngày and "không hẹn ngày về". Per type: Giảm cân, Tiếng Anh, Hai đứa mình = chips, default 30. Tập luyện = default 30 preselected. Tự đặt = chips + "không hẹn ngày". Chuyến đi = NO chips (dates were chosen in step 2): read-only card "Đà Lạt · 16–20/10 · 5 ngày" with a text button "Sửa ngày".
b) Giờ nhắc: switch "Nhắc mình mỗi ngày" + time wheel (default 20:30), line "Mình sẽ khẽ nhắc lúc 20:30." Turning the switch on for the first time opens the Prompt 1 notification permission screen; never ask earlier.
c) Ai được xem, radio cards: Một mình = "Chỉ mình tôi" (default) or "Ai có link (chỉ đọc)". Rủ hội = "Cả nhóm" and Hai đứa = "Hai đứa", the link option is shown disabled with the reason "Hành trình nhóm không có link công khai." Giảm cân (also when it switched to Hai đứa mình) adds a locked note "Ảnh làm mờ và ẩn số kg khi chia sẻ, kể cả qua link chỉ đọc." (on, cannot be turned off here). Nothing ticked for sharing except the default.
Primary "Đúc hành trình". Frames: Giảm cân solo (Quiet Light), Chuyến đi rủ hội (Memory Dark), Hai đứa mình (Couple Light).

HAND-OFF TO STEP 5 (one frame per Light/Dark, in the chosen skin): dots show 5/5, centre shows a stamp shape and "đang đúc hành trình…", below a one-line summary of the choices (name, "Rủ hội", "30 ngày", "20:30"). The ticket itself is the next prompt.

NAVIGATION & INTERACTION (Điều hướng & tương tác). Keep the existing app and plug the flow into it. Routes: /create/1, /create/2/:n (Prompt 4; until then "Chọn kiểu này" goes straight to /create/3), /create/3 (+ /create/3/extra/1-2), /create/4, /create/5 (hand-off now; Prompt 4 adds the ticket on it).
- Entered from Hub "+ hành trình mới" and the empty-state CTAs on Hub and camera. No dock. X (any step) > exit sheet: "Thoát" > back to /hub or /camera, store.draft discarded; "Ở lại" closes. Back pops one step, keeps answers. There is no limit on journeys: /create/1 always opens.
- Step 1: swipe/arrows move the focused card (bg cross-fades); "Chọn kiểu này" or card tap = morph into the skin, set store.draft.type/skin, push /create/2/1. Onboarding answers preselect the matching card, never auto-advance.
- Step 3: pick a card, "Tiếp tục" > /create/4. "Chỉ hai đứa" from another type: morph + toast + two extra screens, then /create/4; "Hoàn tác" restores skin and answers and removes them. Back from step 3 = last step-2 screen.
- Step 4: "Sửa ngày" opens a calendar sheet editing store.draft dates. Reminder switch on for the first time > Prompt 1 notification sheet, closes back to step 4. "Đúc hành trình" > /create/5 (hand-off, then the ticket after 1.2s).
- Nothing enters store.journeys until Prompt 4's "Khởi hành".
FORBIDDEN too: long scrolling page, landing page, style guide as a screen.

DO NOT: one long form or a single-name "Quick setup"; skin = colour swap only; stock photos; text under 12px; mixed English/Vietnamese; blank or dead-end screens; two primary buttons; a fixed-colour shutter; a pre-ticked share list; an uncloseable sheet; a public link for any group journey.
```

### Checklist Prompt 3
- Step 1 có 6 thẻ khác bố cục và chất liệu (không chỉ khác màu), thẻ đang chọn to hơn, nền đổi theo thẻ, không có ảnh stock.
- Mọi bước có "bước N/5", 5 chấm, nút quay lại và nút đóng đều ≥ 44pt; chỉ một nút chính mỗi màn.
- Có cặp khung trước/sau khi đổi skin, và cặp khung Accountability Squad sang Couple kèm toast có nút "Hoàn tác".
- Chọn "Rủ hội" ghi "tối đa 10 người"; tùy chọn link bị mờ kèm lý do ở nhóm và ở "Hai đứa"; không có ô nào tick sẵn để chia sẻ.
- Bước 4 của Chuyến đi không có chip thời lượng, chỉ có thẻ ngày đã chọn; không câu hỏi nào lặp lại bước 2.
- Chọn "Chỉ hai đứa" từ loại khác: giữ câu trả lời và luật loại cũ (Giảm cân vẫn ẩn kg), hỏi thêm đúng hai màn (tên hai người, ai chụp nửa nào), không hỏi lại nếu đã chọn Cặp đôi ở bước 1.
- Giảm cân có ghi chú khoá "ảnh làm mờ, ẩn số kg"; xin quyền thông báo chỉ xuất hiện khi bật công tắc nhắc.
- Khung chuyển sang bước 5 hiện 5/5 và tóm tắt lựa chọn, không có vé.
- Chữ trên nút chính đọc rõ theo bảng màu nhãn; trạng thái chọn có icon dấu tích và chữ "Đã chọn".
- Có đủ Light + Dark, banner offline, sheet thoát; sheet đóng được bằng X, kéo xuống và chạm nền.
- Từ Hub bấm "+ hành trình mới" → bước 1; vuốt thẻ thì nền đổi; bấm "Chọn kiểu này" → màn đổi sang skin đó và sang bước tiếp theo.
- Bấm X ở bất kỳ bước nào → sheet "thoát khỏi việc tạo?"; "Thoát" về màn đã mở luồng, "Ở lại" đóng sheet; bấm quay lại giữ nguyên câu trả lời.
- Ở bước 3 bấm "Chỉ hai đứa" từ skin khác → đổi skin Couple, hiện hai màn thêm; bấm "Hoàn tác" → trả skin cũ và bỏ hai màn.
- Bấm "Đúc hành trình" ở bước 4 → sang khung bước 5 có tóm tắt lựa chọn; bật công tắc nhắc lần đầu → mở sheet quyền thông báo, đóng lại vẫn ở bước 4.
- Không trang cuộn dài, không landing page, không style guide làm màn.

---

## Prompt 4: Câu hỏi riêng cho từng loại và 6 tấm vé khởi hành

```
KEEP everything already built (Prompts 0–3: tokens, components, Hub, create steps 1/3/4). Do NOT rebuild
the app. ADD new screens: Step 2 (type-specific questions) and Step 5 (departure ticket) for all 6 types.
Each screen is already in its type's skin (the screen morphed when the type was picked): use that skin's
tokens by name from Prompt 0 (Nhấn / Nút / Phụ and the variant names), light + dark, 390×844. No dock inside this flow. Every UI string below is
Vietnamese with diacritics (line-height 1.35, never clipped). No English labels. Min text 12px,
touch targets ≥ 44pt, selected state = thick border + check icon (Phosphor), never color alone.

STEP 2 LAYOUT (all types): top bar back arrow + 5 progress dots (dot 2 active) + "Câu 1/3" chip;
big lowercase title with period; 2–3 BIG answer cards (full width, ≥ 96pt tall, sticker art left,
label 20pt bold, one-line hint 14pt); bottom primary "Tiếp tục" (52pt, disabled with hint line
"chọn một đáp án để tiếp tục"). One question per screen, never a form. At 1.35x text the cards stack 1 column.
Screens per type = one per question below, plus Step 5.

1) GIẢM CÂN (Quiet Transformer, calm, private tone, Fraunces titles, hairline borders)
 Q1 "mục tiêu của bạn?" Giảm cân / Giữ dáng / Thay đổi vóc dáng.
 Q2 "cân nặng hiện tại?" horizontal ruler slider 40–120 kg, big number; "Bỏ qua" ghost button
 (optional); lock row "🔒 Chỉ mình bạn thấy" as a pill; toggle "Ẩn số kg khi chia sẻ" ON by default.
 Q3 "chụp ảnh ngày 1 làm khung căn dáng?" preview of ghost silhouette at 30%; "Chụp ngay" (camera
 permission is asked only after this tap) / "Để sau vậy.".
 TICKET: private dossier card, tab-folder shape, paper #FFF, hairline border, big 🔒 stamp,
 "HỒ SƠ RIÊNG TƯ", "Hồ sơ riêng tư · 30 ngày", goal line, cover sticker, milestones "Tuần đầu · Nửa chặng ·
 Về đích", vow "Chỉ mình mình thấy. Từng chút một." The kg number appears NOWHERE on the ticket.
 Button label color: ink #0F172A on coral #FF4D6D (primary, shutter) and on emerald #10B981 fills, same in Light and Dark.

2) HỌC TIẾNG ANH (Accountability Squad, rallying tone, 2px ink border + 3px lip)
 Q1 "mục tiêu?" IELTS / Giao tiếp / Đọc sách. Q2 "mỗi ngày bao nhiêu phút?" 4 cards 15 / 30 / 45 / 60 phút.
 Q3 "đặt tên chiếc cúp ở đích." input with counter 0/24, placeholder "Cúp 7.5", live trophy sticker.
 TICKET: quest card with gold header "NHIỆM VỤ 30 NGÀY", S-path preview ending at a trophy named by
 the user, 5 chỗ của hội (filled avatars + dashed "còn trống"), vow "Điểm danh mỗi ngày, cả hội cùng lên!".
 Labels: ink #1E1B18 on flame #FF9F1C (shutter, primary); #FFFFFF on violet #7556F8 (group actions only, e.g. invite).

3) 30 NGÀY TẬP LUYỆN (Aesthetic Flexer, dark-first, terse numeric tone, frosted glass)
 Q1 "môn gì?" Chạy / Gym / Pilates / Yoga / Khác (chips grid 2 columns).
 Q2 "đo bằng gì?" km / phút / buổi. Q3 "kiểu HUD?" 3 cards with live preview: "HUD đậm" / "Tem tối giản" /
 "Dải phim" (Vietnamese names, not English).
 TICKET: race bib, white (dark: #14161F) with 1px neon lime #3DE88C edge and hard offset shadow 4px 4px 0
 lime, huge Barlow Condensed number "30", "NGÀY", sport name, 4 safety-pin dots, tear tab "SỐ ĐEO 001",
 vow "Ra khỏi giường. Chạy tiếp." Labels: ink #090A0F on coral #FF4D6D and lime.

4) CHUYẾN ĐI (Memory Collectors, nostalgic tone, serif + mono stamps)
 Q1 "đi đâu?" search input with suggestion rows; picking "Đà Lạt" instantly shows a cover sticker
 (pine and fog) with caption "Rừng thông và sương". Q2 "ngày đi – ngày về" month calendar with range
 selection + ghost option "chưa hẹn ngày về". Q3 "cuộn phim mấy tấm?" 2 cards: 24 tấm / 36 tấm.
 TICKET: vintage bus/plane ticket on paper grain, perforation + notches, round terracotta stamp,
 mono "SGN → ĐÀ LẠT", "16 THG 10 – 20 THG 10", "CUỘN PHIM 24 TẤM", crew avatars, fake barcode,
 vow "Mang về thật nhiều khung hình." Labels: white on terracotta #CC4A2F and olive #4A6B53.

5) HAI ĐỨA MÌNH (Couple Rituals, Playfair Display, sweet tone, radius 24; Q2 and Q3 are reused as the two extra screens when "Chỉ hai đứa" is picked from another type, see Prompt 3)
 Q1 "nghi thức của hai đứa?" Nấu ăn / Tiết kiệm / Yêu xa / Tự đặt.
 Q2 "tên hai người." two inputs side by side (stack at 1.35x), placeholders "Tên bạn" / "Tên người ấy".
 Q3 "ai chụp nửa nào?" 2 cards with split-frame preview: "Mình bên trái" / "Mình bên phải".
 TICKET: tear-in-half couple ticket, dashed tear line, left half one name, right half the other,
 heart at the seam, "30 NGÀY NẤU CHO NHAU", halves drawn 8px apart, vow "Mỗi ngày một nửa, ghép lại
 thành một." Labels: ink #1A1316 on rose #E15B72; #FFFFFF on berry #9D174D (same in Light and Dark).

6) TỰ ĐẶT (Minimalist Habit, near-wordless, 1px grid): ONE screen only, no "Câu x/3".
 "thói quen của bạn." input (max 40) + "vì sao?" single-line input (max 80). Button "Tiếp tục".
 TICKET: minimal index card, mono type, 1px grid lines, one Braun-orange line, "ĐỌC 10 TRANG",
 "vì: để ngủ ngon hơn", "NGÀY 01 / 30". No decoration. Label: ink #1C1C1E on #EA580C (both modes).

STEP 5 "đúc hành trình." (after Steps 3–4, same skin):
 a) Stamping frame "đang đúc DNA…" 1.2s; Reduce Motion version = static ticket crossfade + text.
 b) Ticket reveal, centered, width 342, slight rotation ≤ 2°. Below: tab switch "Màu" | "Bìa".
 "Màu": 3 swatch chips with Vietnamese names: Quiet Lục ngọc/Xanh sage/Sương mù; Squad Lửa/Tím/Phấn;
 Memory Sương thông/Biển muối/Phố đêm; Couple Hồng/Mâm xôi/Đào; Flexer Lime neon/San hô điện/Băng;
 Minimal Cam/Than/Trời. "Bìa": 3 sticker covers. Selecting updates the ticket live (ring + check).
 c) Primary "Khởi hành" opens the Day 1 camera (always dark). Secondary "Sửa lại" ghost.
 d) Group journeys (Rủ hội, Hai đứa mình): invite bottom sheet (radius 24) over the dimmed Day 1
 camera: handle, close X (44pt), title "mời hội của bạn." 8-char code in 8 boxes "K7Q2-M9XA", button
 "Sao chép mã", link "ourney://join/K7Q2M9XA" + "Sao chép link", QR 160pt, "Chia sẻ", note "Chỉ ai có mã
 hoặc link này mới vào được. Hành trình nhóm không có link công khai.", "Đã mời 1/10". Closes by X,
 drag down, tap backdrop, "Để sau vậy.". Solo journeys skip the sheet.

NAVIGATION & INTERACTION (Điều hướng & tương tác). Keep the existing app and plug these screens into Prompt 3's flow. Routes: /create/2/1, /create/2/2, /create/2/3 (Tự đặt has only /create/2/1), /create/5 (stamp, then ticket).
- /create/2/1 opens from step 1 "Chọn kiểu này". "Tiếp tục" pushes the next question; back pops (Q1 back > /create/1, skin stays until another card is chosen). The last question > /create/3. Answers go to store.draft.answers and appear on the ticket (cúp name, Đà Lạt, 24/36 tấm, two names, môn, thói quen).
- Giảm cân Q3 "Chụp ngay" > camera sheet > Day-1 ghost capture, returns to /create/3 with the photo stored as the ghost; "Để sau vậy." > /create/3. Couple Q2/Q3 are the same screens Prompt 3 reuses for "Chỉ hai đứa".
- "Đúc hành trình" (step 4) > /create/5: stamping 1.2s > ticket. Tabs Màu | Bìa edit store.draft.variant/cover live. "Sửa lại" > /create/4.
- "Khởi hành" ADDS the journey to store.journeys (Ngày 1, streak 0), sets activeJourneyId, then > /j/:newId/camera in Ngày 1 mode (always dark, dock visible; reuses the Prompt 1 camera until Prompts 5A-7 give each skin its HUD). Group: the invite sheet opens over this camera; X/drag/scrim/"Để sau vậy." reveal the camera; "Sao chép" = toast, "Chia sẻ" = share-sheet mock. Solo has no sheet.
- Shutter > /j/:newId/post > /j/:newId/done > /j/:newId (journey home showing Ngày 1), all built per skin in Prompts 5A-7 (until then the shutter returns to /hub). Hub now lists the new card first.
FORBIDDEN too: long scrolling page, landing page, style guide as a screen.

CẤM (do not do): one long form or one-field "quick setup"; skin differing only by color; 7-column photo
calendar (Minimalist home only); text under 12px; English labels or mixed languages; blank/dead-end
screens; two primary buttons with the same job; stock photos (use stickers + tilted Polaroids); a public
link for group journeys; the kg number on any ticket; the Outfit font; a sheet that cannot be closed.
```

### Checklist Prompt 4
- [ ] Có 6 loại, mỗi câu một màn (Giảm cân 3, Tiếng Anh 3, Tập luyện 3, Chuyến đi 3, Cặp đôi 3, Tự đặt 1), đáp án là thẻ to ≥ 96pt
- [ ] Mỗi màn có light + dark, đúng skin, không có dock, không có chữ tiếng Anh
- [ ] Giảm cân: nhãn "Chỉ mình bạn thấy", công tắc "Ẩn số kg khi chia sẻ" bật sẵn, vé không hiện số kg
- [ ] 6 vé khác hẳn nhau: hồ sơ 🔒, thẻ nhiệm vụ có cúp, vé xe/máy bay, vé xé đôi, số đeo, thẻ chỉ mục
- [ ] Chọn Đà Lạt thì ảnh bìa gợi ý hiện ngay; chọn 24/36 hiện trên vé
- [ ] Cặp đôi: Q2 và Q3 dùng lại được cho luồng "Chỉ hai đứa" từ loại khác (Prompt 3)
- [ ] Bước 5 đổi được 3 biến thể màu và 3 ảnh bìa, ô đang chọn có vòng + dấu tick
- [ ] "Khởi hành" mở camera Ngày 1 nền tối; nhóm hiện sheet mời có mã 8 ký tự, link, QR, nút đóng
- [ ] Sheet mời ghi rõ không có link công khai; nhãn nút trên màu accent đúng ink/trắng đã nêu
- [ ] Từ bước 1 chọn một loại → bấm "Tiếp tục" qua từng câu → bấm quay lại giữ đáp án; câu cuối dẫn sang bước 3
- [ ] Bấm "Đúc hành trình" → màn đúc rồi hiện vé; bấm tab "Màu"/"Bìa" và chọn ô khác → vé đổi ngay; bấm "Sửa lại" → về bước 4
- [ ] Bấm "Khởi hành" → mở camera Ngày 1; hành trình mới xuất hiện đầu danh sách ở Hub (kiểm tra bằng dock "Hành trình")
- [ ] Hành trình nhóm: sheet mời hiện trên camera; đóng bằng X, kéo xuống, chạm nền hoặc "Để sau vậy." đều thấy camera; hành trình một mình không có sheet
- [ ] Không trang cuộn dài, không landing page, không style guide làm màn

---

## Prompt 5A: Bên trong hành trình, Quiet Transformer

```
CONTINUE in the SAME file. KEEP everything already built (Prompt 0 tokens/components, Prompts 1-4 screens); do NOT rebuild the app, restyle old screens or touch tokens. ADD one new section of frames: "Trong hành trình · Quiet Transformer" (Prompt 5B adds Accountability Squad after it). Reuse Prompt 0 variables (skin modes, Light/Dark) by name. Frame 390x844. Every screen in Light + Dark, except camera (always dark). All UI text Vietnamese with diacritics, min 12px, line-height 1.35, touch targets >= 44pt, states shown by label/shape/icon never by color alone, contrast >= 4.5:1. Every animation below also has a static end state for Reduce Motion (150ms cross-fade). Check Dynamic Type 1.35x on the home screen.
Quiet = clinical editorial magazine: flat, airy, hairline, no rotation. Dock labels: "Hành trình" and "Hội".

=== A) QUIET TRANSFORMER, journey "30 ngày cơ thể" ===
Voice: soft, private, calm; never frames weight loss as winning.
Material: flat, airy, lots of whitespace, 1px hairline borders, soft diffuse shadow (0 8 24 rgba(15,23,42,.08)), NO rotation, NO thick borders. Radius: card 20, photo 10, pills full.
Type: titles Fraunces Light 28 sentence case; labels Be Vietnam Pro 12 medium UPPERCASE tracking +8%; numbers Be Vietnam Pro 700 tabular.
Colors: Light bg #EFF3F0, surface #FFFFFF, ink #0F172A. Dark bg #0B0F12, surface #151C21, ink #F1F5F9. Emerald #10B981 only as curve/node/toggle/progress fill (never as text in Light). Shutter coral #FF4D6D. Text/icon placed ON emerald or coral fill = ink #0F172A in both modes, never white. Variants Emerald / Sage / Mist swap via variable mode.
Dock (material swap, same position and behaviour): frosted capsule (Dark #151C21 at 80%), 1.5px border + 2px hard shadow, left "Hành trình" (MapTrifold), right "Hội" (UsersThree), centre 72pt coral shutter with white ring, soft coral halo, camera icon. Selected item: Fill icon, pill behind, bold label (as Prompt 0).
1. Home. Top bar: back, "30 NGÀY CƠ THỂ", chip "🔒 Riêng tư". Below: "Ngày 21/30 · 🔥 21". Chart card: smooth emerald 2pt curve, fading emerald gradient below, solid start/end nodes. Weight numbers are HIDDEN by default: axis labels show blurred "•• ,• KG"; button "Giữ để xem" (eye icon, 48pt) reveals "65,2 KG" and "62,0 KG" only while pressed. Under the card: vertical 2pt emerald spine, white-ringed nodes right of 48x56 photo thumbs (radius 10). Row: small label "NGÀY 07 ★ TUẦN ĐẦU", big value 18 bold (delta, hidden "••" until hold). Milestones: NGÀY 07 "Tuần đầu", NGÀY 14 "Nửa chặng", NGÀY 30 "Về đích" (outlined star until reached). Today row "NGÀY 21 · HÔM NAY". Missed row: hollow dashed circle, no photo, "NGÀY 9 · NGHỈ", grey line "Một ngày nghỉ không xóa hành trình." (not red).
2. Camera (dark). Ghost-align: Day-1 silhouette white at 30% opacity, soft edge, no grid, no frame. Top pill black 70% + blur: "🔒 Riêng tư · Ngày 21", white 13pt. Chip "Bóng ngày 1" with on/off state to hide the ghost. Dock same as above, no text inputs.
3. Post-capture. Photo top. Black #111 ruler panel (radius 12): "62,0 KG" white bold 15 + "(-3,2 KG)" emerald; track grey, emerald fill, white 20pt knob, tick ruler; field label "Cân nặng (không bắt buộc)", note "Chỉ mình bạn thấy". Caption "Hôm nay bạn cảm thấy thế nào?" with mood chips (Nhẹ nhõm, Bình thường, Hơi mệt), counter "0/140". ONE primary "Đăng"; ghost "Chụp lại". Max 3 taps total.
4. Celebration. Emerald seal stamp "NGÀY 21 ✓", "Chuỗi 21 ngày", line "Đã lưu. Chỉ mình bạn thấy." Milestone 7 / 30: seal gets a star ring + name "Tuần đầu" / "Về đích" and sparse soft emerald dots (12, slow fade, no rainbow confetti).
5. Hội hôm nay (only when journey is shared). Rows sorted A-Z, never by result. Each row: avatar, name, "Đã chụp 06:10" or "Chưa chụp" (icon + text), 7 dots "đều đặn 5/7". Photos blurred by default, tap "Xem ảnh". NO kg, NO delta, NO ranking. Footer: "Không ai bị so cân. Chỉ đếm sự đều đặn."
6. Share card 9:16 (1080x1920, keep top/bottom 250px safe zone) and 4:5 (1080x1350), tab switch. Two 2:3 photos side by side, 6pt gap, radius 8, not rotated, labels "NGÀY 01" and "NGÀY 21". Below, a gray row radius 12 with two toggles, both ON by default: "Ẩn số kg" and "Làm mờ ảnh" (faces/body blurred, shown blurred in the frame). With "Ẩn số kg" ON no number or delta appears anywhere; subline "21 ngày đều đặn". Turning OFF opens a sheet "Hiện số kg trên thẻ?" / "Ai xem thẻ đều thấy số này." buttons "Giữ ẩn" (primary) and "Vẫn hiện". Full-width ink #111827 button "Xuất thẻ" 44pt, white text. Small "Ourney" mark, no link.
7. States. Offline: top chip "Đang lưu trên máy · sẽ đồng bộ sau" (cloud-slash icon), thumbs with clock badge "Chờ đồng bộ"; posting still works. Read-only: banner "Hành trình đã kết thúc · chỉ xem" (lock icon), shutter replaced by disabled grey circle with lock and label "Đã lưu trữ".

NAVIGATION & INTERACTION (Điều hướng & tương tác). Keep the existing app and wire these screens into it. Shared journey routes (the same ones serve all 6 skins in 5B-7; the screen is picked by journey.skin): /j/:id (home), /j/:id/camera, /j/:id/post, /j/:id/done, /j/:id/squad (only if shared), /j/:id/share. Later prompts add /j/:id/day/:n, /j/:id/edit, /j/:id/wrapped (Prompt 8).
- Entered from: Hub card, Prompt 4 "Khởi hành" (Ngày 1), profile shelf, join. The theme morphs 320ms. Top-left back > /hub.
- Home: dock shutter > /j/:id/camera; dock "Hành trình" > /hub, "Hội" > /squad; gear icon (44pt, top right) > /j/:id/edit; any timeline node > /j/:id/day/:n; "Giữ để xem" works only while pressed; shared journey: button "Hội hôm nay" > /j/:id/squad; "Tạo thiệp" > /j/:id/share.
- Camera: shutter freezes the frame > /j/:id/post; chip "Bóng ngày 1" toggles the ghost; X/back > /j/:id.
- Post-capture: "Đăng" writes the check-in to the store (photo, weight stays hidden, caption): day +1, streak +1, todayDone, then replaces to /j/:id/done; "Chụp lại" > camera. Max 3 taps from shutter.
- Done: tap or auto 1.8s > /j/:id with the new node on top (Hub card also updates); milestone 7/30 shows "Tạo thiệp" > /j/:id/share. The first ever check-in opens the Prompt 1 notification sheet once.
- Share: tabs 9:16 | 4:5; "Xuất thẻ" = toast "Đã lưu thẻ."; back > previous screen. Panel states (ngày lỡ, offline, chỉ đọc) re-render these routes; the read-only banner > /j/:id/wrapped.
FORBIDDEN too: long scrolling page, landing page, style guide as a screen.

DO NOT: one long form or one-field quick setup; skin that only changes colors (layout, motif, HUD, progress must differ); 7-column photo calendar grid in either skin; text under 12px; mixed English/Vietnamese on one screen; black empty screens, empty stats tabs, dead-end buttons; two primary buttons with the same function (no floating "Check In" next to the shutter, no "Đăng" next to "Đăng khoảnh khắc"); pre-ticked friends when sharing; repeated stock photos (use hand-drawn stickers and tilted polaroid placeholders); flat same-mold lists; a fixed-color shutter; sheets that cannot be closed (always X button, drag down, tap outside); emoji as navigation icons; body-result ranking in any group view; kg shown on any shared card by default; Outfit font.
```

### Checklist Prompt 5A
- [ ] Quiet phẳng, nhiều khoảng trắng, không xoay, không viền dày; timeline là đường dọc có node ảnh
- [ ] Mọi số kg và chênh lệch bị mờ hoặc ẩn cho đến khi giữ "Giữ để xem"
- [ ] Thiệp 9:16 và 4:5 có "Ẩn số kg" và "Làm mờ ảnh" cùng bật sẵn, không có số nào trên thẻ
- [ ] Hội hôm nay không có kg, không xếp theo kết quả
- [ ] Đủ 7 nhóm màn: trang chủ, camera, sau khi chụp, ăn mừng (kèm mốc 7 và 30), hội hôm nay, thiệp, trạng thái (ngày lỡ, offline, chỉ đọc); Light + Dark, camera nền tối
- [ ] Dock đúng vị trí, nút chụp 72pt san hô có icon máy ảnh, tab "Hành trình" và "Hội"; chữ trên nút san hô và lục là ink #0F172A
- [ ] Chữ tiếng Việt có dấu không bị cắt ở 1.35x, không chữ dưới 12px, vùng chạm >= 44pt
- [ ] Bấm thẻ "30 ngày cơ thể" ở Hub → trang chủ Quiet; bấm nút chụp → camera; chụp → sau khi chụp → "Đăng" → ăn mừng → trở về trang chủ, node mới ở trên cùng và Ngày/chuỗi tăng 1
- [ ] Quay lại Hub bằng dock "Hành trình" → thẻ hành trình hiện Ngày/chuỗi mới; bấm lại vào được
- [ ] Bấm "Giữ để xem" chỉ hiện kg khi đang giữ; bấm "Tạo thiệp" → thiệp, đổi tab 9:16 | 4:5 được, "Xuất thẻ" ra toast
- [ ] Bấm biểu tượng bánh răng → màn cập nhật hành trình; bấm một node → màn xem một ngày; quay lại về đúng trang chủ
- [ ] Không trang cuộn dài, không landing page, không style guide làm màn

---

## Prompt 5B: Bên trong hành trình, Accountability Squad

```
CONTINUE in the SAME file. KEEP everything already built (Prompt 0 tokens/components, Prompts 1-4 screens, and the whole Quiet Transformer section from Prompt 5A); do NOT rebuild the app, restyle old screens or touch tokens. ADD one new section of frames: "Trong hành trình · Accountability Squad". Reuse Prompt 0 variables (skin modes, Light/Dark) by name. Frame 390x844. Every screen in Light + Dark, except camera (always dark). All UI text Vietnamese with diacritics, min 12px, line-height 1.35, touch targets >= 44pt, states shown by label/shape/icon never by color alone, contrast >= 4.5:1. Every animation below also has a static end state for Reduce Motion (150ms cross-fade). Check Dynamic Type 1.35x on the home screen.
Accountability Squad = tactile cream paper notebook: it must look nothing like Quiet (different material, font, timeline, dock). Dock labels: "Hành trình" and "Hội".

=== B) ACCOUNTABILITY SQUAD, journey "Hội IELTS 7.5" (5 members) ===
Voice: rallying, short, friendly pressure.
Material: warm cream paper, 2px ink border + 3px solid bottom lip on cards/buttons/chips/dock, NO glass, NO gradient, NO soft shadows. Polaroids rotated +-3..5deg. Radius 14, pills full.
Type: titles Space Grotesk Bold lowercase with period; chips/labels Be Vietnam Pro 12 bold UPPERCASE separated by "·"; numbers Space Grotesk 700.
Colors: Light bg #F7F1E5, surface #FFFDF9, ink/border #1E1B18. Dark bg #12131A, surface #1D1F2B, ink/border #F8FAFC. Flame #FF9F1C for progress/today/shutter fill (never as text in Light; text/icon on it = #1E1B18). Violet #7556F8 ONLY for group action buttons (label #FFFFFF, bold 14); never as text on bg. Variants Flame / Violet / Chalk.
Dock: cream capsule 2px ink + 3px lip, left MapTrifold "Hành trình", right UsersThree "Hội", centre 72pt round flame shutter with 2px ink border + lip and ink camera icon (never "..." dots).
1. Home. Full-width chip "🔥 HỘI IELTS 7.5 · 30 NGÀY" + 5 avatar stack "4/5 HÔM NAY". Centre: winding S-shaped paper ribbon, 28px wide, cream with ink border, drawn bottom to top; the stretch Day 21 to 30 is solid flame. Stepping stones = polaroids alternating left/right: "NGÀY 01 · XUẤT PHÁT", "NGÀY 07 ⭐ TUẦN 1", "NGÀY 14 ⭐ TUẦN 2", "NGÀY 21 · HÔM NAY 🔥" (larger, flame tag, ink text). Future stones: empty dashed polaroids. Top: flat gold trophy "CÚP 7.5" + "NGÀY 30". Missed stone: dashed empty polaroid "NGÀY 9 · LỠ" + "Lỡ một hôm thôi. Mai về lại đường nào!".
2. Camera (dark). Cream pill top "📖 45 PHÚT · 🔥 21", dark translucent pill "06:15" bottom centre. No slider, no text input.
3. Post-capture. Minutes dial chips 15 / 30 / 45 / 60 / "Khác" (stepper), unit "PHÚT". Caption "Hôm nay bạn học được gì?" counter "0/140". ONE primary "Đăng", ghost "Chụp lại".
4. Celebration. Ink stamp "ĐÃ ĐIỂM DANH" rotated -6deg in flame, "Ngày 21 · chuỗi 21", "4/5 đứa đã điểm danh" with mini avatars. Milestone 7: stamp "TUẦN 1 XONG" + paper confetti (flame, violet, cream rectangles). Day 30: trophy rises, "CÚP 7.5 VỀ TAY".
5. Hội hôm nay. Top full-width bar, ink 2px, 80% flame fill, centred "4/5 ĐÃ ĐIỂM DANH". 2-column grid of unrotated polaroids: square photo, "LINH ✓ 06:10" (check icon + text), reactions row (🔥 4 · 👏 3; choices 🔥 💪 👏 ❤️ 😂, NO comments). Last tile: dashed empty, "MINH · ĐANG CHỜ", violet lip button "Nhắc Minh 👋" (44pt). It is UI only: tap shows toast "Đã nhắc Minh"; no promise of any notification. No leaderboard.
6. Share card 9:16 and 4:5: cream poster, rotated polaroid wall, header "4/5 ĐÃ ĐIỂM DANH · NGÀY 21", trophy stamp, "Ourney" mark. Image only: no link, no QR (group journeys never have a public link).
7. States. Offline: cream pill "CHỜ ĐỒNG BỘ · ĐÃ LƯU TRÊN MÁY" (cloud-slash icon); wall shows "Cập nhật lúc 06:12", "Nhắc Minh" disabled with label "Cần mạng". Read-only: ink stamp "ĐÃ KẾT THÚC · CHỈ XEM", shutter disabled grey with lock, label "Đã lưu trữ".

NAVIGATION & INTERACTION (Điều hướng & tương tác). Keep the existing app (including 5A) and wire these screens into it. Same routes as 5A (/j/:id, /camera, /post, /done, /squad, /share; the screen is picked by journey.skin); this skin is the "Hội IELTS 7.5" card on the Hub.
- Hub card tap > /j/:id. Shutter > /j/:id/camera > shutter > /j/:id/post (minutes chip + caption) > "Đăng" writes the check-in to the store (day +1, streak +1, minutes, "x/5 đã điểm danh" +1, your own polaroid joins the wall; seed = 3/5 before your check-in, the designed 4/5 frames show the state after it) > /j/:id/done > /j/:id.
- Home: avatar stack / chip "4/5 HÔM NAY" > /j/:id/squad; a stone polaroid > /j/:id/day/:n; gear > /j/:id/edit; "Tạo thiệp" (milestone and trophy) > /j/:id/share; the trophy at Day 30 > /j/:id/wrapped when finished.
- Celebration: "4/5 đứa đã điểm danh" > /j/:id/squad. Hội hôm nay: tapping a polaroid > /j/:id/day/:n; reaction chips toggle one at a time and the count updates; "Nhắc Minh 👋" (violet) = toast "Đã nhắc Minh", then disabled; dock "Hội" > /squad (the tab of all groups, Prompt 9) and back from /j/:id/squad returns to where it was opened.
- Share: tabs 9:16 | 4:5, "Chia sẻ" = share-sheet mock, no link.
FORBIDDEN too: long scrolling page, landing page, style guide as a screen.

DO NOT: one long form or one-field quick setup; skin that only changes colors (layout, motif, HUD, progress must differ); 7-column photo calendar grid in either skin; text under 12px; mixed English/Vietnamese on one screen; black empty screens, empty stats tabs, dead-end buttons; two primary buttons with the same function (no floating "Check In" next to the shutter, no "Đăng" next to "Đăng khoảnh khắc"); pre-ticked friends when sharing; repeated stock photos (use hand-drawn stickers and tilted polaroid placeholders); flat same-mold lists; a fixed-color shutter; sheets that cannot be closed (always X button, drag down, tap outside); emoji as navigation icons; body-result ranking in any group view; kg shown on any shared card by default; Outfit font.
```

### Checklist Prompt 5B
- [ ] Accountability Squad nhìn khác hẳn Quiet: viền 2px + lip 3px, polaroid xoay; timeline là con đường chữ S, đoạn Ngày 21 đến 30 tô cam
- [ ] Dock đúng vị trí, nút chụp 72pt cam lửa #FF9F1C chữ ink, có icon máy ảnh, không có dấu "..."; tab "Hành trình" và "Hội"
- [ ] Hội hôm nay: thanh "4/5 ĐÃ ĐIỂM DANH", ô trống nét đứt "MINH · ĐANG CHỜ", nút "Nhắc Minh 👋" màu tím chữ trắng, không bảng xếp hạng
- [ ] Đủ 7 nhóm màn (trang chủ, camera, sau khi chụp, ăn mừng kèm mốc 7 và 30, hội hôm nay, thiệp 9:16 và 4:5, trạng thái ngày lỡ/offline/chỉ đọc); Light + Dark, camera nền tối
- [ ] Thiệp Accountability Squad không có link hoặc mã QR; "Nhắc" chỉ hiện toast
- [ ] Chữ tiếng Việt có dấu không bị cắt ở 1.35x, không chữ dưới 12px, vùng chạm >= 44pt
- [ ] Bấm thẻ "Hội IELTS 7.5" ở Hub → con đường chữ S; bấm nút chụp → camera → chụp → "Đăng" → ăn mừng → trang chủ; "3/5" thành "4/5" và Hub đổi Ngày/chuỗi
- [ ] Bấm chip "4/5 HÔM NAY" → Hội hôm nay; bấm "Nhắc Minh 👋" → toast "Đã nhắc Minh", nút mờ; bấm một reaction → đổi số, chỉ một lựa chọn
- [ ] Bấm một polaroid → xem một ngày; bấm "Hội" ở dock → tab Hội; bấm thẻ nhóm ở đó → quay lại đúng Hội hôm nay của hành trình
- [ ] Không trang cuộn dài, không landing page, không style guide làm màn

---

## Prompt 6: Bên trong hành trình, Memory Collectors và Couple Rituals

```
Same Make file. KEEP all existing work (Prompt 0 tokens/components, Hub, create flow, Prompts 1-5); do NOT rebuild. ADD frames 390x844, Light + Dark (camera always dark). Reuse the floating dock (left "Hành trình", raised 72pt shutter in skin accent, right "Hội", long-press = journey wheel); only its material changes. All text Vietnamese, min 12px, line-height 1.3-1.45, touch >=44pt, states never colour-only, Dynamic Type 1.35x no clipping, Reduce Motion = crossfade. The two skins are different WORLDS (material, font, timeline), not a recolor.

A) MEMORY COLLECTORS — "Đà Lạt 5 ngày", 5 friends, "Sương thông". Voice: nostalgic, short.
Matte cream paper, linen grain, no glass/gradient/neon. L bg #F4EFE6 paper #FFF ink #231F1E muted #6A625A; D bg #141312 paper #1F1D1B text #F5F2EB. Fonts: Fraunces serif titles + Space Mono UPPERCASE for stamps/labels. Terracotta #CC4A2F = shutter, thread, dock button (fill/line only, never text; label white 4.58:1). Olive #4A6B53 = share button (label white L / #F5F2EB D).
Dock: paper capsule, 2px ink border, 3px 3px 0 hard shadow ("glued" look), washi tape on both ends; active item = Fill icon + pill behind + bold label, with a thread stitch under it. Chips = paper tags, 2px border.
1. Home: mono caps header "ĐÀ LẠT · 5 NGÀY CÙNG BẠN BÈ" + 1px rule, chip "CUỘN PHIM 12/24". ONE terracotta thread in an S-curve, knotted into each photo; taped polaroids alternate LEFT/RIGHT, rotated -4° to +5°, mono caption "NGÀY 01 · RỪNG THÔNG", each a different sticker scene. Today = empty taped slot "HÔM NAY · chạm để chụp". No grid, calendar or FAB.
2. Camera: cream pill "CUỘN PHIM 12/24"; 3:4 viewfinder, vignette, grain; amber LED mono stamp bottom-left "18 THG 10 '26 · 15°C" / "ĐÀ LẠT" (#FFB347); shutter terracotta core, thick cream ring, no label; flash/flip as 44pt corner icons only.
3. Post-capture: taped photo; Fraunces "Hôm nay cả bọn lạc ở đâu?"; caption "0/140"; pin-icon place chip "Đồi chè Cầu Đất" (editable); ONE primary "Dán vào sổ"; link "chụp lại". Max 3 taps.
4. Celebration: photo develops blank to image, tape sticks, rotated stamp "ĐÃ DÁN · KHUNG 12/24", "tấm thứ 12 rồi đó.". Milestone Ngày 7 "Tuần đầu trên đường" / "Hết cuộn": punched-paper and film-scrap confetti, button "Tạo poster".
5. Hội hôm nay "HÔM NAY · 4/5 ĐÃ CÓ KHUNG": vertical 35mm strip, one frame each with sprockets and "MINH · 07:42"; missing = black dashed frame "CHƯA CÓ KHUNG" + button "Nhắc Hà" (UI only, toast "Đã nhắc Hà."). Reactions 🔥 💪 👏 ❤️ 😂; no comments, no ranking.
6. Share "9:16 | 4:5": cream, Fraunces caps "5 NGÀY THANH XUÂN · ĐÀ LẠT", black 35mm contact sheet with sprockets and frame numbers (9:16 = 4x6 for 24 frames; 4:5 = 4x5; unshot = black numbered). Olive button "Chia sẻ poster chuyến đi". Image only, no public link.
7. Missed day: loose thread tail + empty dashed slot, "NGÀY 3 · KHUNG TRỐNG", "ngày này chưa có ảnh. cuộn vẫn quay tiếp.".
8. Read-only: thread tied in a bow, stamp "ĐÃ ĐÓNG SỔ", shutter = lock icon disabled "Đã khép lại", link "Xem tổng kết" (Prompt 8).
9. Offline: kraft strip "Đang lưu trên máy. Có mạng sẽ tự gửi."; polaroid dog-ear tag + clock icon "CHỜ GỬI".
---
B) COUPLE RITUALS — "30 ngày nấu cho nhau", Nam & Linh. Voice: sweet, soft.
Blush editorial: NO thick borders, NO hard shadows in content (soft diffuse only), frames radius 24, thumbs 12; no paper/tape/mono. Brutal skeleton ONLY on dock, chips, primary button. L bg #F9F0EE card #FFF ink #261F22; D bg #171215 card #241C21 text #FCE7F3. Fonts: Playfair Display (caps letter-spaced, big italic numerals) + Be Vietnam Pro captions. Rose #E15B72 = shutter, hearts, axis, CTA fill (never text in Light; label #1A1316 both modes). Berry #9D174D = dock shadow, secondary buttons (label #FFFFFF).
Dock: blush-white capsule radius 32, 2px ink border, 3px 3px 0 berry hard shadow.
1. Home: Playfair caps "30 NGÀY NẤU CHO NHAU · 🔥 18" + thin rule. Strict symmetry around ONE vertical rose axis; node per day (heart normal, flame streak milestone); label above "NGÀY 18 · HÔM NAY", milestone "NGÀY 14 · ★ NỬA CHẶNG". Left card Nam, right card Linh, white radius 24, photo 3:4, caption "bữa sáng của Nam". Newest on top, "NGÀY 01 · BẮT ĐẦU" at bottom. Incomplete pair: dashed half "đang chờ Linh" + hollow heart. No grid or calendar.
2. Camera: near-square viewfinder split 50/50 by a white hairline; LEFT Nam's photo dimmed, white strip "ẢNH CỦA NAM · 07:30"; RIGHT live view + slim vertical slider; dark pill "Chụp nửa của Linh" / "Ghép đủ đôi"; shutter white ring, rose core. If Nam not shot: dashed left "Nam chưa chụp. Bạn chụp trước nhé.".
3. Post-capture (own screen): the two halves joined in one radius-24 diptych (or half + dashed half); Playfair "Hôm nay hai đứa nấu gì?"; caption "0/140"; field "Món hôm nay"; chips "Ai nấu?" Nam / Linh (selected = fill + check); "Bữa này mấy tim?" 1-5 hearts (shared, never a score between two). ONE primary "Gửi cho cả hai" (incomplete pair: "Gửi nửa của mình", then "đang chờ Nam"); link "chụp lại". ALL fields optional with defaults (Món: empty, Ai nấu: whoever shot, tim: 3): after the shot, "Gửi cho cả hai" alone is enough, max 3 taps.
4. Celebration: halves click together, heart seal, "Ngày 18 · đủ đôi", "đủ đôi rồi nè.". Milestone Ngày 7 "Tuần đầu bên nhau" / Ngày 30 "Tròn 30 ngày": petals + hearts, button "Tạo thiệp".
5. Hội hôm nay "Hôm nay của hai đứa": two vertical halves; Nam "đã chụp 07:30" with photo; Linh dashed "chưa chụp" + chip "Nhắc Linh" (UI only, toast "Đã nhắc Linh."); "🔥 18 ngày bên nhau"; reactions on partner photo. No scores.
6. Share "9:16 | 4:5": Playfair caps "18 NGÀY BÊN NHAU · 36 KHOẢNH KHẮC"; 9:16 = 6x6 portrait tiles (3:4, radius 6, 4px gaps, no borders/text, each day's pair adjacent); 4:5 = 4x4 best 16. Rose capsule "Chia sẻ câu chuyện của mình". No public link.
7. Missed day: one half = dashed "đang chờ Linh" + half-hollow heart; both = two dashed halves, broken heart, "NGÀY 9 · CẢ HAI ĐỀU NGHỈ", "mai mình gặp lại nhé.".
8. Read-only: banner "Hai đứa đã về đích", solid hearts, shutter locked "Đã khép lại", link "Xem tổng kết" (Prompt 8).
9. Offline: Nam's half skeleton "ảnh của Nam chưa tải được"; yours tagged clock icon "CHỜ GỬI · đã lưu trên máy"; banner "Đang lưu trên máy. Có mạng sẽ tự gửi.".

NAVIGATION & INTERACTION (Điều hướng & tương tác). Keep the existing app and wire both skins into the shared routes of 5A (/j/:id, /camera, /post, /done, /squad, /share; the screen is picked by journey.skin). Memory = Hub card "Đà Lạt 5 ngày"; Couple = Hub card "30 ngày nấu cho nhau" (seeded) or created via Prompt 4.
- Hub card tap > /j/:id (theme morphs). Home: the "HÔM NAY · chạm để chụp" slot (Memory) or the empty half (Couple) and the dock shutter > /j/:id/camera; a polaroid/node > /j/:id/day/:n; gear > /j/:id/edit; "Hội hôm nay" button > /j/:id/squad; dock "Hành trình" > /hub, "Hội" > /squad.
- Camera shutter > /j/:id/post. Memory "Dán vào sổ" / Couple "Gửi cho cả hai" write the check-in (Memory: frame 12/24 +1, place; Couple: your half, "đủ đôi" only when the partner's half exists, else "đang chờ Nam") > /j/:id/done > /j/:id with the new polaroid/pair on top; Hub card day/streak update. Incomplete pair: "Nhắc Linh/Nhắc Hà" = toast only, then disabled. "chụp lại" > camera.
- Celebration milestone buttons: Memory "Tạo poster", Couple "Tạo thiệp" > /j/:id/share (tabs 9:16 | 4:5, share button = share-sheet mock, no link).
- Read-only: "Xem tổng kết" > /j/:id/wrapped. Missed-day, read-only and offline are panel states re-rendering the same routes.
FORBIDDEN too: long scrolling page, landing page, style guide as a screen.

FORBIDDEN: one long form or one-field setup; recolor-only skins; 7-column photo calendar (Minimalist only); text <12px; mixed English/Vietnamese; blank black screens, empty tabs, dead-end buttons; duplicate primary actions (no FAB beside shutter); pre-ticked friends when sharing; repeated stock photos; flat identical lists; fixed-colour shutter; sheets without close button, drag-down and scrim tap; ranking by body results; public links on group journeys; promising push for "Nhắc".
```

### Checklist Prompt 6
- [ ] 2 skin x 9 khung (home, camera, sau khi chụp, ăn mừng, hội hôm nay, thiệp 9:16 + 4:5, ngày lỡ, chỉ đọc, offline), đủ Light + Dark, camera nền tối
- [ ] Memory: giấy kem có vân, sợi chỉ terracotta chữ S, polaroid so le trái/phải có băng keo; Fraunces + mono in hoa
- [ ] Couple: một trục tim dọc, hai thẻ Nam | Linh đối xứng, không viền dày, không băng keo, không mono; Playfair
- [ ] Đặt hai skin cạnh nhau: khác rõ về chất liệu, font, timeline
- [ ] Couple có màn sau khi chụp riêng (ảnh ghép đôi, "Món hôm nay", "Ai nấu?", tim) với 1 nút chính; mọi ô tuỳ chọn có sẵn mặc định, chụp rồi "Gửi cho cả hai" là đủ (≤3 chạm)
- [ ] Camera Memory có "CUỘN PHIM 12/24" và dấu ngày hổ phách; camera Couple nửa trái là ảnh của Nam, nửa phải xem trực tiếp
- [ ] Nút chụp 72pt: terracotta (Memory), rose (Couple); dock đổi chất liệu, giữ vị trí
- [ ] Thiệp có công tắc 9:16 | 4:5, không link công khai; "Nhắc" chỉ là toast
- [ ] Không chữ dưới 12px, nhãn trên nút accent đúng màu đã nêu, dấu tiếng Việt không bị cắt
- [ ] Bấm thẻ "Đà Lạt 5 ngày" ở Hub → sổ dán; bấm ô "HÔM NAY" → camera → chụp → "Dán vào sổ" → ăn mừng → trang chủ có polaroid mới và "CUỘN PHIM" tăng 1
- [ ] Couple: bấm nút chụp → camera nửa khung → chụp → "Gửi cho cả hai" → ăn mừng → trang chủ; nửa của Linh còn trống thì bấm "Nhắc Linh" ra toast rồi nút mờ
- [ ] Bấm "Hội hôm nay" ở mỗi skin → màn hội hôm nay; bấm "Tạo poster"/"Tạo thiệp" → thiệp có công tắc 9:16 | 4:5; quay lại về trang chủ
- [ ] Panel chọn "chỉ đọc" → bấm "Xem tổng kết" mở được màn về đích
- [ ] Không trang cuộn dài, không landing page, không style guide làm màn

---

## Prompt 7: Bên trong hành trình, Aesthetic Flexer và Minimalist Habit

```
Continue in the SAME Figma Make file. KEEP everything built so far (Prompt 0 tokens/components, shell, Hub, create flow, skins from Prompts 5-6). ADD screens for the last 2 skins; do not rebuild the app. Light + dark for each (camera always dark). All UI text Vietnamese with diacritics, line-height 1.3-1.45, no text under 12px, touch targets >= 44pt, states shown by icon/label/shape, not color alone. Reduce Motion: every animation gets a static fallback. Dynamic Type 1.35x must not clip.
The two skins must look like different apps: A = glowing dark glass + condensed numerals + vertical axis; B = flat paper-white grid + light uppercase sans + horizontal calendar. No polaroid, tape, stickers or tilt in either.

A) AESTHETIC FLEXER — "Chạy sáng 30 ngày" (workout, group of 4)
Material: frosted dark glass (#14161F at 70%, blur 24, 1px stroke white 18%) + neon glow. Light mode: bg #F3F4F6, but summary card, HUD and sheets stay dark glass; text on light = #090A0F or gray #4B5563. Lime #3DE88C and coral #FF4D6D are text ONLY on dark surfaces. Fonts: Barlow Condensed 700 ALL CAPS for numbers (72-120pt, unit "KM" at 40% size, tight to the number); labels Be Vietnam Pro 12px ALL CAPS, tracking +12%, gray #9CA3AF. Voice: shouting, clipped ("21 NGÀY LIỀN. TIẾP.").
Dock (inside journey): frosted glass capsule, 1.5px glow stroke (Nhấn #3DE88C) + hard shadow 4px 4px 0 #3DE88C; left "Hành trình" (MapTrifold, selected = Fill icon + pill + bold label), center 72pt coral #FF4D6D shutter with white ring, right "Hội" (UsersThree).
Primary button: coral #FF4D6D, label #090A0F, 1.5px glow stroke, hard shadow 4px 4px 0 #3DE88C. Chips: same bone, 44pt high.
1. Home (telemetry): centered label "CHẠY SÁNG · NGÀY 21/30"; glass card with full-width lime sparkline (glow), under it "92,4 KM TỔNG · 5:04 /KM NHỊP TB". Below: thin glowing lime vertical axis with round nodes (lime; milestone = pale-yellow #F5F7A8 star). Each row: 56x56 photo thumbnail radius 12 LEFT of the axis, label RIGHT "NGÀY 01 · 5,0 KM"; milestones add "★ CỘT MỐC · TUẦN ĐẦU" (ngày 7), "★ CỘT MỐC · NỬA CHẶNG" (ngày 14). Today row: "NGÀY 21 · HÔM NAY" + "5,42" 96pt white + "KM". No extra check-in button besides the dock shutter.
2. Camera sticker studio: live photo full-bleed; top glass sticker (black 60%, radius 8): "NGÀY 21 · 🔥 21 LIỀN" then "5,42 KM · 5:04 /KM". Chip row: "HUD đậm" (selected: white fill, dark text), "Dấu tối giản", "Dải phim", last chip cut off. Shutter: coral core, white ring, black gap. Bottom scrim so labels pass 4.5:1.
3. After capture: photo on top, big "5,42 KM" and "5:04 /KM" fields (prefilled from yesterday), custom numeric keypad, caption "Hôm nay chạy thế nào?" with counter "0/140", primary "Đăng". Shutter to posted <= 3 taps.
4. Celebration: neon pulse ring, numbers count up, "NGÀY 21. 21 NGÀY LIỀN." Milestones add lime/coral/white confetti: ngày 7 "TUẦN ĐẦU XONG", ngày 30 "VỀ ĐÍCH. 30/30".
5. Hội hôm nay: header "3/4 ĐÃ CHẠY"; glass rows (avatar, name, check-in time, photo thumb, reactions 🔥 💪 👏 ❤️ 😂). Order by check-in time; NO km or pace of other members side by side anywhere, no rank numbers, no medals: only who has or has not checked in and when. Km and pace show only for yourself. Waiting member row dashed with "Nhắc Minh"; tap shows toast "Đã nhắc Minh." (UI only).
6. Share card: 9:16 (IG safe zones: top 13%, bottom 18% empty) and 4:5, switch chips "9:16" / "4:5". Photo full-bleed, small HUD, 21 rounded vertical bars: reached days lime and tall, weak days red/orange/yellow AND shorter; caption "21 NGÀY HOẠT ĐỘNG". Button "Chia sẻ lên Story" (coral).
7. States: missed day = hollow dashed ring node, dashed axis gap, row "NGÀY 9 · NGHỈ"; read-only = glass banner with lock "ĐÃ VỀ ĐÍCH · CHỈ ĐỌC", shutter disabled, label "Đã khép lại"; offline = cloud-slash chip "CHỜ ĐỒNG BỘ" on camera and on unsynced rows, and under "Đăng": "Đã lưu trên máy, sẽ đồng bộ sau."

B) MINIMALIST HABIT — "Đọc 10 trang" (custom)
Material: flat, no gradient, no soft shadow. Light bg #F5F3EE, surface #FFF, ink #1C1C1E; dark bg #0E0E10, surface #18181B, ink #F4F4F5. Accent Braun orange #EA580C as line/fill/bar; as TEXT only in dark. Fonts: Space Grotesk Light for headings and numerals (as Prompt 0), Be Vietnam Pro regular/medium for ALL CAPS labels, tracking +6%; no bold, serif or mono. Voice: almost no words ("XONG.").
Brutal bones stay ONLY on dock, primary button, chips: 2px border (light #1C1C1E, dark #F4F4F5), radius 8, hard shadow 3px 3px 0 (light #27272A, dark #EA580C). Dock: flat capsule, left "Hành trình", right "Hội", center 72pt orange shutter with 2px ring. Primary button: orange fill, label #1C1C1E (both modes).
1. Home: "THÁNG 10 · CHUỖI 24 NGÀY" (charcoal text, short orange bar before the streak; in dark the streak text may be orange). Weekday row T2 T3 T4 T5 T6 T7 CN: exactly 7 columns. Grid of 44pt squares, radius 6, gap 6, day number (12px) directly ABOVE each square. Done = square photo; ONE continuous 1.5px orange line runs behind the photos through cell centers across consecutive days, stepping down the gutter at row ends. Ngày 24 is today and has a photo; ngày 25-30 = 1px dashed gray squares with the number inside; 1 Oct is a Thursday.
2. Camera: full-screen viewfinder, no grid, no HUD. ONLY text: top pill (2px white border, white 90% fill, charcoal text) "ĐỌC 10 TRANG · NGÀY 24". Bottom: dark scrim, "Hành trình" and "Hội" 12px white, 72pt shutter orange core with thin white ring. No flash/timer/filter/text input.
3. After capture: photo, circular 3-2-1 countdown ring, primary "Đăng ngay", ghost "Thêm ghi chú" (opens caption, counter 0/140). Auto-posts at 0; any tap stops the timer. Reduce Motion: static text "Tự đăng sau 3 giây".
4. Celebration: one orange dot grows to fill today's calendar cell, word "XONG." Milestones: ngày 7 "7 NGÀY LIỀN", ngày 30 "ĐỦ 30 NGÀY", tiny orange square confetti.
5. Hội hôm nay: header "3/4 ĐÃ XONG"; rows split by 1px lines (avatar, name, time or "CHƯA", square thumb, reactions); pending row dashed with "Nhắc Hà" (same UI-only toast).
6. Share card: 9:16 (IG safe zones) and 4:5. Centered 3-line "24/30 NGÀY · 80% ĐỀU ĐẶN", one portrait photo radius 8, charcoal button "Xuất thẻ tối giản" (white label), lots of whitespace.
7. States: missed day = dashed square, orange line breaks and restarts, header "CHUỖI 15 NGÀY"; read-only = line ends at last day, banner "ĐÃ KẾT THÚC · CHỈ ĐỌC", shutter disabled; offline = clock icon + "CHỜ ĐỒNG BỘ" on the pill and on unsynced cells.

NAVIGATION & INTERACTION (Điều hướng & tương tác). Keep the existing app and wire both skins into the shared routes of 5A (/j/:id, /camera, /post, /done, /squad, /share; the screen is picked by journey.skin). Flexer = Hub card "Chạy sáng 30 ngày"; Minimalist = Hub card "Đọc 10 trang" (seeded) or created via Prompt 4.
- Hub card > /j/:id. Dock shutter or today's cell/row > /j/:id/camera; node/cell > /j/:id/day/:n; gear > /j/:id/edit; "3/4" chip (Flexer, Minimalist) > /j/:id/squad; dock "Hành trình" > /hub, "Hội" > /squad.
- Flexer camera: HUD chips (Đậm / Tối giản / Dải phim) change store.hud and the sticker on the viewfinder live; shutter > /j/:id/post: keypad edits km/pace, "Đăng" writes the check-in (km total, sparkline point, day +1, streak +1) > /j/:id/done > /j/:id; Hub card numerals and sparkline update.
- Minimalist camera: shutter > /j/:id/post, 3-2-1 ring auto-posts (any tap stops it; "Đăng ngay" posts at once, "Thêm ghi chú" opens the caption) > /j/:id/done "XONG." > /j/:id where today's cell fills and the orange line extends; Hub card updates.
- Hội hôm nay: pending row "Nhắc Minh/Nhắc Hà" = toast only, then disabled; reactions toggle one at a time. Milestone 7/30 button "Tạo thiệp" > /j/:id/share (tabs 9:16 | 4:5; Flexer "Chia sẻ lên Story" and Minimalist "Xuất thẻ tối giản" = toast/share mock).
- Read-only banner > /j/:id/wrapped.
FORBIDDEN too: long scrolling page, landing page, style guide as a screen.

DO NOT: skins that only change color; a 7-column photo grid for Flexer; 5 columns for Minimalist; text under 12px; English UI labels; pre-ticked share lists; two same-function primary buttons or a floating "Check In" FAB; a fixed-color shutter; ranking by km or body results; dead-end or non-dismissable sheets; repeated stock photos as main content; promising real push notifications.
```

**Checklist Prompt 7**
- [ ] Flexer và Minimalist nhìn là hai app khác nhau: kính tối + số condensed + trục dọc phát sáng so với giấy phẳng + sans nhẹ + lịch ngang.
- [ ] Lịch Minimalist có đúng 7 cột T2..CN, số ngày nằm trên ô, một đường cam xuyên các ô liên tiếp, ô chưa tới nét đứt xám.
- [ ] Dock, nút chính, chip của Minimalist vẫn viền 2px + bóng cứng; phần còn lại phẳng, không bóng mềm.
- [ ] Dock Flexer là kính mờ viền 2px + bóng cứng lime, nút chụp coral; nút chụp Minimalist màu cam.
- [ ] Camera Flexer có sticker HUD và 3 chip; camera Minimalist chỉ có một chip chữ "ĐỌC 10 TRANG · NGÀY 24".
- [ ] Chữ cam/lime/coral chỉ nằm trên nền tối; nhãn trên nút cam/coral là màu ink tối.
- [ ] Heatmap 21 thanh phân biệt bằng chiều cao, không chỉ bằng màu; Hội hôm nay của Flexer không hiện km/pace của người khác cạnh nhau, chỉ ai đã/chưa chạy và giờ
- [ ] Có thiệp 9:16 và 4:5 cho cả hai skin; mốc ngày 7 và ngày 30 có confetti và nhãn riêng.
- [ ] Có đủ ngày lỡ, chỉ đọc, offline; nút "Nhắc" chỉ hiện toast, không hứa thông báo.
- [ ] Mọi chữ tiếng Việt có dấu, không chữ nhỏ hơn 12px, không có nút Check In nổi thứ hai.
- [ ] Bấm thẻ "Chạy sáng 30 ngày" ở Hub → telemetry; bấm một chip HUD ở camera → sticker đổi; chụp → nhập km → "Đăng" → ăn mừng → trang chủ có hàng mới, Hub cập nhật số km
- [ ] Minimalist: bấm nút chụp → chụp → vòng 3-2-1 tự đăng, chạm vào thì dừng; "XONG." → trang chủ, ô hôm nay có ảnh và đường cam dài thêm
- [ ] Bấm chip "3/4 ĐÃ CHẠY"/"3/4 ĐÃ XONG" → Hội hôm nay; bấm "Nhắc Minh" → toast rồi nút mờ; bấm "Tạo thiệp" → thiệp có công tắc 9:16 | 4:5
- [ ] Không trang cuộn dài, không landing page, không style guide làm màn

---

## Prompt 8: Cập nhật hành trình, xem một ngày, về đích (dùng cho cả 6 skin)

```
Continue in the SAME Figma Make file. KEEP everything already built (design system, Hub, creation flow,
in-journey screens of Prompts 0-7). Do NOT rebuild the app; ADD 18 new screens = 3 screens x 6 skins,
each in light + dark (Flexer dark-first). Use each skin's tokens from Prompt 0 and its own materials;
the three screens must look different per skin (layout, material, type), not just recolored.
All UI text Vietnamese with diacritics, min 12px, line-height 1.35, tap targets >= 44pt.
Pushed pages with a back button (no dock). Text on accent buttons: Quiet ink #0F172A on coral and emerald fills, Flexer ink #090A0F on
coral and lime; Squad ink on flame #FF9F1C (white on violet #7556F8 only for group actions); Memory white on terracotta
and olive; Couple ink #1A1316 on rose, white on berry; Minimal ink #1C1C1E on Braun orange, white on
charcoal. Never use an accent as small text on the background. States use label + shape, not color only.
Reduce Motion: replace confetti/stamp animation with a static final state.

THREE SCREEN TYPES (per skin)
A) XEM MỘT NGÀY: full photo, caption, metric, small label "từ thư viện" if imported, reaction bar
   🔥 💪 👏 ❤️ 😂 (chosen reaction = outline + count, one at a time). NO comment box anywhere.
   Overflow "⋯" (Phosphor DotsThree) menu shows "Báo cáo" and "Chặn" ONLY in group journeys; in solo
   it shows "Xoá ảnh". Report sheet: title "Báo cáo ảnh này", calm line "Chỉ đội ngũ Ourney xem báo cáo
   này. Ảnh sẽ ẩn với bạn ngay.", reasons Spam / Khoả thân / Quấy rối / Tự hại / Khác, button
   "Gửi báo cáo". Block confirm: "Chặn [tên]?" + "Hai bên sẽ không thấy nội dung của nhau." + "Chặn" / "Thôi".
B) CẬP NHẬT HÀNH TRÌNH "cập nhật hành trình.": sectioned list (not one long form): Tên · Bìa · Màu
   (3 variants) · Giờ nhắc · Ai được xem. GROUP owner state adds: Thành viên (<=10, row "Xoá" per member,
   owner badge) and Mã mời 8 ký tự + "Đổi mã" with note "Mã cũ sẽ hết hiệu lực." Group "Ai được xem" is a
   locked row "Chỉ thành viên · hành trình nhóm không có link công khai" (no link, no public toggle).
   Solo shows "Chỉ mình tôi / Có link xem (thu hồi được)"; Giảm cân: the read-only link page also hides kg and blurs photos by default. Bottom: destructive "Kết thúc hành trình" ->
   confirm sheet "Kết thúc hành trình?" / "Bạn vẫn xem lại được, nhưng không chụp thêm." / "Kết thúc" / "Thôi".
   Sheets close via X, drag down, tap backdrop. Show unsaved state: button "Lưu" enabled only after a change.
C) VỀ ĐÍCH (WRAPPED): entered from the read-only banner "Hành trình đã về đích" on journey home (chỉ đọc).
   A story of 4 swipeable pages (progress dots + labels, tap right to advance) then the summary card with
   "Tạo thiệp": 9:16 and 4:5 previews, buttons "Chia sẻ" (system share sheet only) and "Lưu ảnh".
   Group journeys: no "Sao chép link" anywhere.

PER SKIN
1) QUIET TRANSFORMER, "30 ngày cơ thể", voice calm/private. Fraunces titles, hairline 1px, white cards
   on #EFF3F0. A: 3:4 photo on a white card, label "NGÀY 14 · NỬA CHẶNG", weight shown "••• kg" with
   "Giữ để xem"; caption answer to "Hôm nay bạn cảm thấy thế nào?". B: hairline rows, lock chip
   "🔒 Riêng tư", toggle "Ẩn số kg khi chia sẻ" ON by default. C: pages "30 ngày, 27 lần có mặt" ·
   Day1/Day30 photos blurred · emerald curve with NO numbers · "Bạn đã về đích." Card: "NGÀY 01 vs NGÀY 30"
   split, "Ẩn số kg" ON and "Làm mờ ảnh" ON by default, no kg anywhere unless user turns it off.
2) ACCOUNTABILITY SQUAD, "Hội IELTS 7.5", voice hype. Cream #F7F1E5, Space Grotesk titles, ink 2px + 3px lip, polaroid -2°.
   A: tag "NGÀY 21 · HÔM NAY", chip "📖 45 PHÚT", chunky reaction chips with counts. B: lip cards, trophy name
   field "Cúp 7.5", violet "Đổi mã" (white text). C: full S-path, lit gold trophy, "CẢ HỘI VỀ ĐÍCH 5/5",
   copy "Về đích rồi, cả hội!" Card: polaroid wall "5/5 ĐÃ VỀ ĐÍCH", no ranking, only who has or hasn't checked in, never score.
3) MEMORY COLLECTORS, "Đà Lạt 5 ngày", voice nostalgic. Paper grain, Fraunces + Space Mono, taped polaroid.
   A: mono "NGÀY 03 · ĐÊM LỬA TRẠI", amber stamp "18 THG 10 '26 · 15°C · ĐÀ LẠT". B: scrapbook page, variants
   "Sương thông / Biển muối / Phố đêm", film roll shown read-only "Cuộn phim 24". C: pages số ngày · số khung
   hình · nơi đã qua · ảnh đẹp nhất, then 35mm contact sheet "5 NGÀY THANH XUÂN · ĐÀ LẠT", olive button
   "Chia sẻ poster chuyến đi", line "Cuộn phim đã hết. Mang đi in thôi."
4) COUPLE RITUALS, "30 ngày nấu cho nhau", voice sweet. Playfair Display caps + italic numerals, blush, radius 24, diptych, heart nodes.
   A: two halves "Nam | Linh" joined by a heart, a caption under each half; incomplete half dashed
   "đang chờ Linh". B: two name fields, ritual name, variants Rose/Berry/Peach, member row for partner.
   C: halves click into a heart-sealed frame, pages "Hai đứa mình về đích rồi." · 60 khoảnh khắc · bữa
   ăn đáng nhớ nhất. Card mosaic "30 NGÀY BÊN NHAU · 60 KHOẢNH KHẮC", rose capsule "Chia sẻ câu chuyện".
5) AESTHETIC FLEXER, "Chạy sáng 30 ngày", voice terse numbers. Frosted glass, 1px glow, Barlow Condensed caps.
   A: full-bleed photo + HUD "5,42 KM · 5:04 /KM" (own photos only; others' photos show no km/pace), glass panel vs your own average, glass reaction chips.
   B: glass rows, HUD style chips (Đậm / Tối giản / Dải phim), lime 4px offset shadow on "Lưu".
   C: pages "30 NGÀY" · "142,6 KM" · pace sparkline · 30-bar heatmap; copy "ĐÃ VỀ ĐÍCH." Cards 9:16 + 4:5,
   coral glow "Chia sẻ lên Story".
6) MINIMALIST HABIT, "Đọc 10 trang", almost no text. #F5F3EE, 1px grid, UPPERCASE regular sans.
   A: square photo, tiny chip "24 / 30", five reaction icons with accessible labels. B: 1px rows
   "TÊN · GIỜ NHẮC · KẾT THÚC", orange line only under the focused row. C: one page, the 30-day chain with
   the orange line complete; card "24/30 NGÀY · 80% ĐỀU ĐẶN", charcoal button "Xuất thẻ".

NAVIGATION & INTERACTION (Điều hướng & tương tác). Keep the existing app and add 3 routes under the shared journey routes: /j/:id/day/:n, /j/:id/edit, /j/:id/wrapped (pushed, no dock, back pops; the screen is picked by journey.skin).
- /day/:n opens from any timeline node, polaroid, cell, row or Hội hôm nay photo, and from the profile shelf. Reaction chips toggle one at a time and update the count in the store. "⋯": group = "Báo cáo" (report sheet > "Gửi báo cáo" > confirmation, photo hidden for you) and "Chặn" (confirm > adds to store.blocked, shown in Settings "Người bị chặn" and hidden from Hội); solo = "Xoá ảnh" > confirm > removes the check-in (day/streak recomputed) and pops.
- /edit opens from the gear on journey home. "Lưu" (enabled only after a change) writes name/cover/variant/reminder to the store: Hub card and journey home update at once (the variant recolours the skin live) and it pops. Owner group: "Xoá" a member updates the avatar stacks; "Đổi mã" > confirm > new code + toast, old code invalid. "Kết thúc hành trình" > confirm > status archived, replace to /j/:id read-only, whose banner "Hành trình đã về đích" > /j/:id/wrapped; Hub card gets the lock chip.
- /wrapped opens from that banner and "Xem tổng kết". 4 story pages (tap right/left or swipe; progress dots) > summary card > "Tạo thiệp" 9:16 | 4:5 > "Chia sẻ" (system share-sheet mock) / "Lưu ảnh" (toast); X or back > /j/:id. Group: no link anywhere.
FORBIDDEN too: long scrolling page, landing page, style guide as a screen.

DO NOT: one long identical form; skin = recolor only; 7-column photo calendar outside Minimal; text under
12px; mixed English/Vietnamese on a screen (kg, km, Ourney excepted); empty or dead-end screens;
two duplicate primary buttons; pre-ticked friends; repeated stock photos (use sticker art + tilted
polaroids); unclosable sheets; fixed-color shutter; ranking by body results; public link for groups;
comments; showing kg in Wrapped by default.
```

### Checklist Prompt 8
- [ ] Có đủ 18 màn (6 skin x xem một ngày, cập nhật hành trình, về đích), mỗi màn có light + dark
- [ ] Mỗi skin có bố cục, chất liệu và font khác hẳn nhau ở cả ba màn, không chỉ đổi màu
- [ ] Xem một ngày có đủ 5 reaction 🔥 💪 👏 ❤️ 😂, không có ô bình luận
- [ ] Menu "Báo cáo" / "Chặn" chỉ ở hành trình nhóm; sheet báo cáo có 5 lý do và câu chữ bình tĩnh
- [ ] Cập nhật hành trình có tên, bìa, 3 biến thể màu, giờ nhắc, thành viên, "Đổi mã", "Kết thúc hành trình" kèm sheet xác nhận
- [ ] Hành trình nhóm không có công tắc hoặc nút link công khai nào, kể cả ở Wrapped
- [ ] Giảm cân: Wrapped và thiệp không hiện kg, "Ẩn số kg" và "Làm mờ ảnh" đang bật
- [ ] Wrapped có đủ 4 trang story, thiệp 9:16 và 4:5, nút "Chia sẻ" và "Lưu ảnh"
- [ ] Giọng văn từng skin đúng (dịu / hô hào / hoài niệm / ngọt / số liệu cụt / gần như không chữ)
- [ ] Mọi chữ tiếng Việt có dấu, không dưới 12px, vùng chạm >= 44pt, chữ trên nút accent đúng màu đã nêu
- [ ] Mọi sheet có nút đóng, kéo xuống và chạm nền để thoát
- [ ] Từ trang chủ hành trình bấm một node → xem một ngày; bấm 🔥 → số tăng, bấm 💪 → 🔥 trở lại như cũ; quay lại về trang chủ
- [ ] Bấm bánh răng → cập nhật hành trình; đổi tên, chọn biến thể màu → nút "Lưu" mới bật; bấm "Lưu" → tên mới hiện ở Hub và màu skin đổi
- [ ] Bấm "Kết thúc hành trình" → "Kết thúc" → trang chủ thành chỉ đọc, bấm banner → Wrapped 4 trang → thiệp → "Chia sẻ" mở sheet giả lập; Hub thấy thẻ chỉ đọc
- [ ] Ở hành trình nhóm bấm "⋯" → "Chặn" → xác nhận; người đó xuất hiện trong Cài đặt → "Người bị chặn"
- [ ] Không trang cuộn dài, không landing page, không style guide làm màn

---

## Prompt 9: Hội, hồ sơ và cài đặt (vỏ chung)

```
CONTINUE in the same Make file. KEEP all frames, components and tokens of Prompts 0-8 untouched
(shell cards, dock, ticket, sheet, avatar, toast, empty state). ADD new frames only; never rebuild
the app. Reference tokens by name. UI text Vietnamese with diacritics (only "Ourney" in English).
Each screen light + dark. Titles Space Grotesk Bold lowercase + period; body Be Vietnam Pro 14-16,
line-height 1.4, nothing under 12px; Phosphor Bold icons; touch >= 44pt. Text on primary #FF8A3D is
ink #1A1A1A. Destructive: light fill #B3261E + white text; dark fill #FF8A80 + ink text; always icon +
word. Orange/pastels only as fills/borders, never small text. Tone: clear, calm, short, no jokes.
Every sheet: close X, drag handle, tap scrim to close.

1) TAB HỘI "hội." (dock visible, Hội item active = filled icon + label + pill, not color only)
- Top: title; below it a join field: label "nhập mã mời", 8-char input shown as "K7Q2-M9XA"
  (2 groups of 4, uppercase, mono), paste icon button, primary "Tham gia" (disabled until 8 chars).
- Section "hôm nay": one card per group journey: pastel type badge (mint Giảm cân, yellow Tiếng Anh,
  peach Chuyến đi, coral Cặp đôi, lilac Tập luyện, sky Tự đặt) + emoji badge, journey name,
  "3/5 đã check-in", avatar row (max 5 + "+3"). Avatar states by shape+label: checked = solid
  ring + check icon + time "07:12"; waiting = dashed ring + clock icon + "chưa". Avatars ordered
  by join order, NEVER by results or streak. Under a waiting avatar: small text button
  "Nhắc Minh" (hand-wave icon). After tap: "Đã nhắc Minh" + check, disabled. Nudge is UI only:
  no promise of a notification in any copy.
  Tap card -> that journey's own "Hội hôm nay" screen (already designed in Prompts 5-7).
- Section "lời mời đang chờ": card "Hà mời bạn vào Hội IELTS 7.5", buttons "Tham gia" / "Bỏ qua".
- States: empty (sticker, "chưa có hội nào.", "Nhập mã mời để vào nhóm hoặc tạo hành trình nhóm."
  one CTA "Nhập mã mời"); skeleton; offline ("Đang xem bản đã lưu. Cần có mạng để tham gia
  hoặc nhắc người khác."); signed-out/local-only (groups locked, lock icon, "Đăng nhập để dùng nhóm.").
  Dynamic Type 1.35x: rows wrap.

2) JOIN BY CODE / LINK (full screen, back chevron; link ourney://join/<code> opens it prefilled)
- Title "vào nhóm." 8 big boxes (2x4), keyboard A-Z 0-9. When valid: ticket preview in the journey's
  own skin (reuse ticket component): name, owner, "5/10 người", duration, "Ngày 21/30", then line
  "Tiến độ của bạn tính từ ngày bạn vào. Bạn vẫn xem được lịch sử nhóm." and
  "Nhóm này không có link công khai. Chỉ người có mã mới vào được."
  Giảm cân groups add "Số kg và ảnh dáng chỉ mình bạn thấy." CTA "Tham gia", secondary "Để sau".
- Error cards (icon + text): "Mã chưa đúng. Kiểm tra lại đủ 8 ký tự nhé." / "Mã này đã hết hiệu lực.
  Nhờ chủ nhóm gửi mã mới." / "Nhóm đã đủ 10 người." / "Không thể tham gia nhóm này." (no reason) / "Cần có mạng để tham gia."

3) REPORT AND BLOCK (member sheet opened from any avatar)
- Member sheet: avatar, name, @username, rows "Báo cáo người dùng" and "Chặn".
- Report sheet "báo cáo." radio rows with icon + label: Spam / Khoả thân / Quấy rối / Tự hại / Khác;
  optional note; primary "Gửi báo cáo". Tự hại adds: "Nếu ai đó đang gặp nguy hiểm, hãy liên hệ
  người thân hoặc dịch vụ khẩn cấp ở nơi bạn sống." Done: "Đã nhận báo cáo. Nội dung này đã được
  ẩn với bạn." + "Xong".
- Block confirm: "Chặn Minh?" "Bạn và Minh sẽ không thấy nội dung của nhau. Bạn có thể bỏ chặn
  trong cài đặt." Buttons "Chặn" (destructive) / "Huỷ".

4) PROFILE "hồ sơ." (pushed from top-right avatar on Hub; gear icon -> settings; no dock)
- Header: avatar in pastel circle, display name, @username, "Sửa hồ sơ" (sheet: avatar picker,
  name, username hint "3-20 ký tự: a-z, 0-9, _ ." error "Tên này đã có người dùng.").
- 3 stat cards, big Space Grotesk numbers: "tổng ngày check-in" 148, "chuỗi dài nhất" 41, "hành trình đã xong" 3.
- "huy hiệu đều đặn.": badges with shape + label, based ONLY on consistency: "Đều 7 ngày",
  "Đều 30 ngày", "Về đích đầu tiên", "Đủ 100 ngày". Locked = dashed outline + lock icon + rule text.
- "kệ hành trình đã xong.": shelf with finished-journey tickets in their own skin, tilted -3..3deg,
  tap -> read-only journey. Empty: "Kệ còn trống. Hành trình xong sẽ về đây."

5) SETTINGS "cài đặt." (grouped cards, 56pt rows, switches with check icon inside the thumb)
- "tài khoản": email (read-only), "Đăng xuất".
- "nhắc nhở": one row per active journey (badge, name, time "20:30", switch); row
  "Báo trước khi chuỗi sắp đứt (21:00)". Permission denied: "Thông báo đang tắt. Bật trong
  cài đặt của máy." + "Mở cài đặt máy".
- "giao diện": segmented Sáng / Tối / Theo máy (icons + check).
- "riêng tư": "Ẩn số kg khi chia sẻ" ON, "Làm mờ ảnh khi chia sẻ" ON, "Người bị chặn" (avatar,
  name, "Bỏ chặn"; empty "Bạn chưa chặn ai.").
- "thông tin": "Điều khoản sử dụng (EULA)", "Chính sách riêng tư", "Liên hệ", "Phiên bản 1.0".
- Danger zone card (dashed destructive border, warning icon): "Xoá tài khoản".

6) DELETE ACCOUNT (3 steps, then done)
- Step 1 "xoá tài khoản." "Toàn bộ dữ liệu và ảnh trên máy chủ sẽ bị xoá vĩnh viễn. Không thể khôi phục."
  List with icons: hồ sơ của bạn / mọi hành trình và ảnh / tư cách thành viên trong các nhóm.
  Note: "Nếu bạn là chủ nhóm, quyền chủ nhóm chuyển cho người vào sớm nhất." Checkbox "Tôi hiểu việc
  này không thể hoàn tác." Buttons "Tiếp tục" (destructive, disabled until ticked, label still
  readable) / "Giữ tài khoản" (secondary, first in focus order).
- Step 2 "xác nhận bằng mã." 6 OTP boxes, "Mã gồm 6 số vừa gửi tới {email}", resend "Gửi lại sau 30s",
  button "Xoá vĩnh viễn".
- Step 3 "đang xoá…". Done: sticker, "Đã xoá tài khoản.", "Cảm ơn bạn đã dùng Ourney.", "Về màn đầu".
  Errors: "Chưa xoá được. Dữ liệu của bạn vẫn nguyên. Thử lại sau nhé." / "Cần có mạng để xoá tài khoản."

7) NAVIGATION & INTERACTION (Điều hướng & tương tác). Keep the existing app and add routes: /squad (dock "Hội"), /join/:code, /me (+ edit sheet), /settings, /settings/delete/1-3, member sheet (overlay).
- /squad: dock "Hội" from anywhere. Group card > /j/:id/squad (back returns to /squad). "Nhắc Minh" = UI toast, stored in store.nudged, then "Đã nhắc Minh" disabled. Avatar > member sheet > report sheet / block confirm (block updates store.blocked and hides that member). Invite card "Tham gia" > /join/:code with the code prefilled; "Bỏ qua" removes the card. Empty-state CTA "Nhập mã mời" focuses the field.
- Join: field "Tham gia" (8 chars) > /join/:code. Demo codes: K7Q2M9XA valid (ticket preview in the journey's skin), AAAAAAAA wrong, EXPIRED1 expired, FULL0010 full, NOJOIN01 refused; also reachable from the panel as the link ourney://join/K7Q2M9XA. "Tham gia" adds the journey to store.journeys (no limit) > /j/:id; "Để sau" > /squad. Signed out (panel "mở link khi chưa đăng nhập"): ourney://join/K7Q2M9XA > /splash > /login > /otp > /profile-setup if new > /join/K7Q2M9XA prefilled (code kept in store.pendingJoin) > "Tham gia".
- /me: Hub avatar (push); gear > /settings; "Sửa hồ sơ" sheet saves name and updates the Hub greeting; badge tap shows its rule; a ticket on the shelf > /j/:id read-only.
- /settings: "Sáng/Tối/Theo máy" switches store.theme live; reminder switches write per journey; "Người bị chặn" > "Bỏ chặn" updates the list; "Đăng xuất" > /login; "Xoá tài khoản" > /settings/delete/1 > tick > /2 (OTP 123456) > /3 > "Về màn đầu" resets the store > /splash. "Giữ tài khoản" pops back.
FORBIDDEN too: long scrolling page, landing page, style guide as a screen.

DO NOT: one long form for all types; color-only skins; text under 12px or touch under 44pt; English
mixed into Vietnamese UI; blank black screens, empty tabs, dead-end buttons; two primary buttons with
the same job; everything pre-ticked; stock photos; leaderboard, ranking or comparison by body results;
comments; public links for group journeys; a sheet that cannot close; a fixed-color shutter; Outfit.
```

## Checklist Prompt 9 (kiểm tra bằng mắt trên ảnh chụp)
- [ ] Tab Hội: ô nhập mã hiện đúng 8 ký tự dạng "K7Q2-M9XA", nút "Tham gia" mờ khi chưa đủ 8
- [ ] Mỗi hàng nhóm có huy hiệu pastel đúng loại, "X/Y đã check-in", avatar đã chụp (vòng liền + dấu ✓ + giờ) khác avatar chưa chụp (vòng đứt + đồng hồ + "chưa")
- [ ] Avatar sắp theo thứ tự vào nhóm; không có số hạng, cúp xếp hạng, kg hay so sánh người với người
- [ ] Nút "Nhắc Minh" dùng icon (không emoji), sau khi nhấn đổi thành "Đã nhắc Minh"; không có câu hứa gửi thông báo
- [ ] Có đủ trạng thái của tab Hội: trống, đang tải, ngoại tuyến, chưa đăng nhập; lời mời đang chờ có 2 nút
- [ ] Màn vào nhóm: bản xem trước vé đúng skin của hành trình, có dòng "không có link công khai" và dòng tiến độ tính từ ngày vào
- [ ] Đủ 5 thông báo lỗi vào nhóm (sai mã, hết hiệu lực, đủ 10 người, không thể tham gia, ngoại tuyến), mỗi thông báo có icon + chữ
- [ ] Báo cáo có đủ 5 lý do (Spam / Khoả thân / Quấy rối / Tự hại / Khác), màn xác nhận chặn nêu rõ hậu quả và có "Huỷ"
- [ ] Hồ sơ: 3 thẻ số, huy hiệu chỉ về sự đều đặn (khoá = viền đứt + ổ khoá + điều kiện), kệ vé nghiêng ±3° và trạng thái kệ trống
- [ ] Cài đặt có đủ: tài khoản, nhắc nhở theo từng hành trình, giao diện Sáng/Tối/Theo máy (không có công tắc ngôn ngữ), riêng tư (Ẩn kg, Làm mờ ảnh bật sẵn), Người bị chặn, EULA/Chính sách/Liên hệ; công tắc có dấu ✓ khi bật
- [ ] Xoá tài khoản: câu "Toàn bộ dữ liệu và ảnh trên máy chủ sẽ bị xoá vĩnh viễn." hiện nguyên văn; nút "Giữ tài khoản" hiện cạnh nút xoá; nút xoá mờ cho tới khi tick; có bước nhập mã 6 số và màn hoàn tất
- [ ] Nút nguy hiểm luôn có icon + chữ; chữ trên nền cam là màu mực; đọc rõ ở cả sáng và tối
- [ ] Mọi sheet có nút X, thanh kéo; không chữ dưới 12px, không vùng chạm dưới 44pt; không trộn tiếng Anh (trừ tên "Ourney")
- [ ] Bấm "Hội" ở dock → tab Hội; bấm thẻ nhóm → Hội hôm nay của hành trình đó, bấm quay lại → về tab Hội; bấm "Nhắc Minh" → đổi thành "Đã nhắc Minh" và mờ
- [ ] Gõ K7Q2M9XA → "Tham gia" → xem trước vé → "Tham gia" → mở trang chủ hành trình mới; gõ AAAAAAAA hoặc EXPIRED1 → thẻ lỗi có icon + chữ
- [ ] Bấm avatar ở Hub → hồ sơ → bánh răng → cài đặt; chọn "Tối" → toàn app đổi tối; bấm "Xoá tài khoản" → tick → mã 123456 → màn hoàn tất → "Về màn đầu" ra splash
- [ ] Mở link mời khi chưa đăng nhập → đăng nhập xong quay lại màn vào nhóm với mã đã điền, bấm "Tham gia" vào được nhóm
- [ ] Không trang cuộn dài, không landing page, không style guide làm màn

---

## Prompt 10: Phần còn thiếu — Ngày 1, tải/lỗi/rỗng, chụp lại, nội dung hệ thống, thông báo, chuỗi đứt, ảnh ẩn, rời nhóm

```
CONTINUE in the SAME Figma Make file. KEEP everything built in Prompts 0-9 (tokens, shell, dock, Hub, create flow, six in-journey skins, Prompt 8 screens, Hội, profile, settings). Do NOT rebuild the app: ADD frames and wire them into the existing routes. 390x844, Light + Dark (camera always dark). Vietnamese with diacritics, min 12px, line-height 1.35, touch >=44pt, Dynamic Type 1.35x, Reduce Motion = static or 150ms cross-fade, state never by color alone (icon + text). Skin screens use that skin's material, font and voice (Quiet calm · Squad hype · Memory nostalgic · Couple sweet · Flexer terse numbers · Minimalist near-wordless). SYSTEM text (legal, errors, leaving a group) is plain, calm, never blaming, in every skin.

1) NGÀY 1 HOME (0 check-ins, right after "Khởi hành"; /j/:id, one frame per skin; streak 0, never an error look)
Quiet: empty axis, one hollow start node, "NGÀY 1/30", "Bắt đầu từ hôm nay. Một tấm là đủ." · Squad: S-path with one dashed polaroid "NGÀY 01 · XUẤT PHÁT", grey trophy, chip "0/5 HÔM NAY", "Chụp tấm đầu tiên nào!" · Memory: taped slot "HÔM NAY · chạm để chụp", "CUỘN PHIM 0/24", "cuộn phim còn trống." · Couple: rose axis, two dashed halves "Nam | Linh", hollow heart, "Ngày 1 · hai đứa bắt đầu nhé." · Flexer: flat dashed sparkline, "0,0 KM", "NGÀY 01/30 · XUẤT PHÁT." · Minimalist: calendar with only today's cell empty, "CHUỖI 0 NGÀY". Group journeys show chip "Mời bạn" reopening the invite sheet.

2) LOADING, ERROR, EMPTY inside a journey and Hội hôm nay (6 skins)
- Loading: skeleton in the skin's own shape (Quiet hairline curve + grey thumbs · Squad grey S-path + empty polaroids · Memory blank taped slots · Couple two grey halves · Flexer dim glass rows · Minimalist 1px cells).
- Error (sticker + line + "Thử lại"; cached data shown instead with "Đang xem bản đã lưu"): Quiet "Chưa tải được. Dữ liệu của bạn vẫn an toàn." · Squad "Chưa tải được. Thử lại nha!" · Memory "Cuộn phim chưa tải được. Thử lại nhé." · Couple "Chưa tải được hai nửa. Thử lại nhé." · Flexer "KHÔNG TẢI ĐƯỢC. THỬ LẠI." · Minimalist "LỖI. THỬ LẠI."
- Hội hôm nay with only you: your tile + dashed tile "Mời bạn": Quiet "Mới có mình bạn. Ở đây chỉ đếm sự đều đặn." · Squad "Hội chưa có ai. Gửi mã mời đi!" · Memory "Cuộn phim này mới có mình bạn." · Couple "Linh chưa vào. Mời Linh nhé." · Flexer "MỘT MÌNH. MỜI THÊM." · Minimalist "MỘT MÌNH."

3) CHỤP KHI HÔM NAY ĐÃ CHECK-IN
One photo per day. When today is done, the dock shutter and the hero open the same camera in "chụp lại" mode: top pill in the skin's style "ĐÃ CÓ ẢNH HÔM NAY · CHỤP LẠI SẼ THAY ẢNH" (Quiet: "Đã có ảnh hôm nay. Chụp lại sẽ thay ảnh."). Post-capture has ONE primary "Thay ảnh" + ghost "Giữ ảnh cũ"; fields prefilled from the old check-in; day, streak and counters do NOT change; no celebration; toast "Đã thay ảnh hôm nay." then /j/:id with the new photo. Couple replaces only your half. At most 3 taps.

4) CHUỖI ĐỨT và NGÀY LỠ của Quiet, Squad
- Streak broken (panel): streak shows 0, "chuỗi dài nhất 21" stays; calm line, never red or shaming: Quiet "Chuỗi bắt đầu lại. Hành trình vẫn ở đây." · Squad "Chuỗi về 0. Hôm nay bắt đầu lại, cả hội đợi!" · Memory "Cuộn phim vẫn quay tiếp." · Couple "Chuỗi chung về 0. Hai đứa bắt đầu lại nhé." · Flexer "CHUỖI 0. TIẾP." · Minimalist "CHUỖI 0."
- Missed-day frames: Quiet hollow dashed node "NGÀY 9 · NGHỈ" opens a small sheet "ngày nghỉ." / "Một ngày nghỉ không xóa hành trình."; Squad dashed polaroid "NGÀY 9 · LỠ" opens a sheet "Lỡ một hôm thôi. Mai về lại đường nào!". Both close by X, drag, scrim; no other action.

5) Ô ẢNH ẨN (reported or blocked), in each skin's tile shape (Quiet thumb, Squad polaroid, Memory film frame, Couple half, Flexer glass row, Minimalist cell): Phosphor EyeSlash + "Ảnh đã ẩn" + "Bạn đã báo cáo ảnh này." or "Bạn đã chặn người này."; tap = toast with that reason, no /day page; avatar and check-in time still show.

6) RỜI NHÓM / BỊ XOÁ KHỎI NHÓM
- Non-owner /j/:id/edit: members read-only (no "Xoá", no "Đổi mã"), destructive "Rời nhóm" > sheet "Rời nhóm?" / "Bạn sẽ không thấy hành trình này nữa. Muốn vào lại cần mã mời." / "Rời nhóm" / "Thôi". Owner sees the note "Quyền chủ nhóm chuyển cho người vào sớm nhất."
- Removed (panel): opening the journey shows a calm full card in the skin's material: "Bạn không còn trong nhóm này." / "Chủ nhóm đã bỏ bạn khỏi nhóm. Bạn có thể vào lại nếu được mời lại." + button "Về hành trình".

7) ĐIỀU KHOẢN, CHÍNH SÁCH, LIÊN HỆ (shell pages, no dock, back; title Space Grotesk, body 16, bold section headings, scroll inside; "Cập nhật lần cuối: 01/11/2026"; sample copy, short and plain)
- "điều khoản sử dụng.": Dùng Ourney · Nội dung của bạn (ảnh của bạn, chỉ người trong hành trình thấy) · Điều không được đăng (khoả thân, quấy rối, tự hại, spam) · Báo cáo và chặn (có thể gỡ nội dung hoặc khoá tài khoản) · Xoá tài khoản (bất cứ lúc nào) · Thay đổi điều khoản.
- "chính sách riêng tư.": Mình lưu gì (email, ảnh, caption, chỉ số bạn nhập) · Ai thấy ảnh (người trong hành trình; nhóm không có link công khai) · Giảm cân (kg chỉ mình bạn thấy, ảnh chia sẻ mờ mặc định) · Máy ảnh và thông báo (xin đúng lúc, tắt được) · Xoá dữ liệu (xoá tài khoản là xoá toàn bộ).
- "liên hệ.": rows with icons "Gửi email hỗ trợ" (hotro@ourney.example, toast "Đã mở ứng dụng thư") and "Báo lỗi" (toast).

8) THÔNG BÁO NHẮC (in-app simulation; promise only what Settings has: a daily reminder at the user's time and one heads-up at 21:00 before the streak breaks)
Reviewer panel (outside the frame) lists "Nhắc giờ" and "Chuỗi sắp đứt 21:00" per journey. Choosing one slides a lock-screen style banner from the top of the frame (icon, "Ourney", "bây giờ", title = journey name, body). Giảm cân: title "Ourney", no journey name or weight. Tap opens the camera of that journey; swipe up or X dismisses. If today is done, the item is greyed in the panel with the reason.
Nhắc giờ: Quiet "Đến giờ của bạn rồi. Một tấm là đủ." · Squad "Tới giờ điểm danh! Cả hội đang chờ." · Memory "Thêm một khung hình cho cuộn phim?" · Couple "Hai đứa ơi, đến giờ rồi." · Flexer "ĐẾN GIỜ. CHẠY ĐI." · Minimalist "NGÀY 24."
Sắp đứt: Quiet "Chuỗi 21 ngày còn đến 21:00. Vẫn kịp." · Squad "🔥 21 sắp đứt lúc 21:00. Chụp ngay nào!" · Memory "Cuộn phim còn mở đến 21:00." · Couple "Chuỗi 18 ngày sắp đứt lúc 21:00." · Flexer "CHUỖI 21. CÒN ĐẾN 21:00." · Minimalist "CHUỖI 24. 21:00."

NAVIGATION & INTERACTION (Điều hướng & tương tác). Keep the existing app. New routes: /settings/terms, /settings/privacy, /settings/contact. The rest are panel states re-rendering existing routes: đang tải, lỗi, chỉ có mình bạn, chuỗi đứt, Ngày 1, bị xoá khỏi nhóm, Thông báo.
- Settings "thông tin" rows and the sign-in legal links (Prompt 1) > the three pages; back pops.
- Dock shutter/hero when today is done > /j/:id/camera "chụp lại" > /j/:id/post "Thay ảnh" > toast > /j/:id. "Giữ ảnh cũ" > /j/:id.
- Ngày 1 chip "Mời bạn" > invite sheet; "Thử lại" > normal screen; hidden tile tap > toast; missed node > sheet.
- "Rời nhóm" > confirm > journey removed from store and Hub, toast "Đã rời nhóm.", > /hub. Removed card "Về hành trình" > /hub with the journey gone.
- Banner tap > /j/:id/camera of its journey; panel also offers the ourney://join link while signed out (Prompt 9).
FORBIDDEN too: long scrolling page, landing page, style guide as a screen; shaming copy for broken streaks; promising more notifications than the two above; ranking; comments; dead ends.
```

### Checklist Prompt 10
- [ ] Trang chủ Ngày 1 có đủ 6 skin, mỗi skin khác hẳn nhau, streak 0 nhưng không giống màn lỗi; nhóm có chip "Mời bạn"
- [ ] Mỗi skin có skeleton đúng hình dạng của skin, thẻ lỗi có "Thử lại", và Hội hôm nay khi chỉ có mình bạn có ô "Mời bạn"; giọng văn khác nhau theo skin
- [ ] Hôm nay đã check-in: bấm nút chụp mở camera "chụp lại" (có dòng báo ảnh sẽ được thay), "Thay ảnh" không làm ngày/chuỗi tăng và không có ăn mừng; Couple chỉ thay nửa của mình
- [ ] Ba trang Điều khoản, Chính sách, Liên hệ có nội dung thật, mở được từ Cài đặt và từ liên kết ở màn đăng nhập
- [ ] Thông báo: chọn ở bảng duyệt thì banner trượt xuống trong khung điện thoại, bấm vào mở camera đúng hành trình; Giảm cân không lộ tên hành trình hay cân nặng; không hứa gì ngoài nhắc giờ và nhắc 21:00
- [ ] Chuỗi đứt về 0 với lời động viên bình tĩnh theo skin, không đỏ, không trách; "chuỗi dài nhất" giữ nguyên
- [ ] Quiet và Squad có khung ngày lỡ riêng (bấm vào mở sheet đóng được)
- [ ] Ô ảnh ẩn có icon + chữ lý do, đúng hình dạng từng skin, bấm chỉ hiện toast
- [ ] Rời nhóm có sheet xác nhận, rời xong hành trình biến khỏi Hub; bị xoá khỏi nhóm hiện thẻ bình tĩnh và nút "Về hành trình"
- [ ] Không trang cuộn dài, không landing page, không style guide làm màn

---

## Checklist kiểm tra sau mỗi prompt
- [ ] Có đủ light + dark, màn camera luôn tối
- [ ] Tiếng Việt có dấu không bị cắt, line-height ≥ 1.3
- [ ] Contrast chữ ≥ 4.5:1, vùng chạm ≥ 44pt
- [ ] Không dùng emoji làm icon điều hướng
- [ ] Mỗi skin nhìn khác hẳn nhau (chất liệu, font, timeline), không chỉ đổi màu
- [ ] Dock nổi giữ đúng vị trí và hành vi ở mọi skin; nhãn tab phải là "Hội", không có chữ "Squad" trong UI
- [ ] Nút chụp Accountability Squad màu cam lửa #FF9F1C chữ ink; tím chỉ cho hành động nhóm
- [ ] Giảm cân: số kg mặc định ẩn/mờ khi chia sẻ, kể cả khi đã đổi sang "Chỉ hai đứa"
- [ ] Hành trình nhóm không có link công khai
- [ ] Không có giới hạn số hành trình: không thẻ khoá, không sheet "đủ 3", "+ hành trình mới" luôn còn
- [ ] Giảm cân: link chỉ đọc của hành trình một mình cũng ẩn kg và làm mờ ảnh
- [ ] Flexer Hội hôm nay không hiện km/pace của từng người cạnh nhau
- [ ] Thẻ Minimalist ghi "24/30 NGÀY · 80% ĐỀU ĐẶN"
