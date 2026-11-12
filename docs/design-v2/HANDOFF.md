# Prompt bàn giao sang session local (có Claude in Chrome)

Dán toàn bộ khối dưới đây vào một session Claude Code / Claude desktop **trên máy của bạn**, mở trong repo Ourney. Session đó cần có extension Claude in Chrome đã kết nối và đã đăng nhập Figma.
Trước khi dán, chép **cả thư mục** `docs/design-v2/` (README, prompts, HANDOFF, `bugs.md`, các spec và `orchestration/`) cùng `docs/client-questions.md` vào cùng đường dẫn trong repo local, hoặc checkout nhánh `design/v2-spec`.

---

```
Bối cảnh: Mình đang thiết kế lại toàn bộ UI/UX app Ourney (Flutter, "Locket cho mục tiêu":
mỗi ngày chụp 1 ảnh check-in cho một hành trình, đi một mình hoặc theo squad ≤10 người,
có streak, mốc 7/30/về đích và thiệp chia sẻ). Bản V1 trên Figma Make bị chê là không đẹp,
và các hành trình chưa có cá tính riêng.

Đã xong ở cloud session (đọc trước khi làm):
- docs/design-v2/README.md: đặc tả V2, gồm vỏ chung "Soft Neo-Brutalism"; "Journey DNA"
  (mỗi hành trình được đúc ra skin, biến thể màu, ảnh bìa sticker, motif, tên mốc, câu hỏi caption,
  kiểu camera và vé khởi hành riêng, dựa trên nội dung trả lời lúc tạo); 6 skin persona
  (Quiet Transformer / Accountability Squad / Memory Collectors / Couple Rituals / Aesthetic Flexer /
  Minimalist Habit); floating dock 5 tab (Hành trình · Hội · Chụp · Hoạt động · Hồ sơ, UI ghi "Hội", nhấn giữ nút chụp để đổi hành trình; cập nhật 2026-11-11);
  danh sách toàn bộ màn hình.
- docs/design-v2/figma-make-prompts.md: 12 khối prompt (0, 1, 2, 3, 4, 5A, 5B, 6, 7, 8, 9, 10) để chạy lần lượt trong Figma Make, kèm checklist.
- Ảnh tham chiếu 6 persona: docs/assets/design_personas/persona_*.jpg (đọc để nắm chất liệu từng skin).
- Ràng buộc gốc: docs/SRS.md, docs/06-adaptive-persona-ui-system.md (bảng màu persona đạt AA).

Quyết định đã chốt với mình:
1. Vỏ chung (Hub, tạo hành trình, onboarding, hồ sơ, squad) dùng neo-brutalism. Bên trong hành trình
   đổi hẳn sang skin riêng như ảnh mẫu, nhưng vẫn giữ "xương" brutal (viền, bóng cứng ở dock và nút chính).
2. Lúc tạo, mỗi hành trình phải ra một cá tính và phong cách riêng dựa trên nội dung của nó.
3. Không bắt buộc theo luật cũ (3 tab trong CLAUDE.md…). Ưu tiên UI hiện đại, bắt mắt nhất.
   (Lúc đầu đề xuất floating dock 3 mục; chủ dự án đã chốt dock 5 tab ngày 2026-11-11, xem `CLAUDE.md` §2.)
4. Thiết kế lại TẤT CẢ màn hình, không dùng lại giao diện cũ.
5. Font: Space Grotesk (tiêu đề) + Be Vietnam Pro (nội dung). Không dùng Outfit vì không có dấu tiếng Việt.

Việc cần làm:
1. Dùng Claude in Chrome mở Figma Make. File đích: https://www.figma.com/make/XlPVftwSyACKWqj0m3FB0x/Ourney-Design-System
   (link `/design` cũ không mở được Make nên đã bỏ; không tạo file mới).
   Có thể mở bản V1 để tham khảo những gì KHÔNG nên làm:
   https://www.figma.com/make/z3B1WO8e7SUNG83jvaPotn/Ourney-V1.0
2. Dán lần lượt 12 khối 0, 1, 2, 3, 4, 5A, 5B, 6, 7, 8, 9, 10 từ figma-make-prompts.md (không bỏ Prompt 10). Sau mỗi prompt: chụp màn hình kết quả,
   kiểm tra theo checklist, nếu sai thì gửi prompt sửa ngắn rồi mới chạy prompt kế tiếp.
3. Cập nhật mục "Trạng thái" bên dưới sau mỗi prompt (prompt nào xong, có vấn đề gì).
4. Hỏi lại mình ngay nếu gặp chỗ chưa rõ hoặc Figma Make cho kết quả lệch hướng nhiều.
   Đừng tự đổi hướng thiết kế.
```

---

## Trạng thái (cập nhật 2026-11-11)

| Việc | Trạng thái |
|---|---|
| Make version 25 (tài khoản Make mới) | ✅ Prompt "FIX 2026-11-11" xong ở version 24, lượt sửa onboarding + nhãn polaroid ở version 25. Đo lại trên preview: chip camera 6 skin dạng viên thuốc nền tối, "18 LIÊN TIẾP" đủ chữ; vòng xoay vuốt ngang được (`touch-action: pan-x`), mờ mép, chip tên cao đều 44, không đè nút chụp, tự đóng khi đổi màn; polaroid không đè "Tạo thiệp", nhãn cao đều; onboarding "Học tiếng Anh · Rủ hội" → /create/1 chọn sẵn đúng thẻ, nút "Tiếp tục", bước 3 chọn sẵn "Rủ hội"; `/j/:id/edit` có mục "Giao diện" lọc theo dữ liệu; có "Nhập hành trình đã qua" và "Nhập ảnh cũ" |
| Make version 26 | ✅ Đã bấm thử và sửa: luồng nhập ảnh cũ (chỉ hiện giao diện hợp lệ, ngày dạng "12 THG 4, 2024", đánh số theo ngày chụp Ngày 1/7/9 kèm ô trống, khay "Chưa có ngày" với "Gán ngày"/"Bỏ" và Lưu khoá tới khi xử lý xong, Wrapped "9 ngày" đúng dữ liệu, thẻ Hub một trạng thái "Đã kết thúc"); đổi giao diện có xem trước toàn màn, áp dụng và đổi lại được, bố cục mới dùng dữ liệu của chính hành trình ("30 NGÀY CƠ THỂ · NGÀY 21/30"); chữ 135% trên các màn mới không bị cắt (chỉ có thẻ băng chuyền/đĩa vòng xoay nằm ngoài khung, đã có lớp mờ); chip camera Squad hết chữ 9px |
| Make version 29 | ✅ Sửa lỗi đổi giao diện hiện nội dung của hành trình mẫu khác (Hội IELTS đổi sang Flexer hiện "CHẠY SÁNG", "92,4 KM"). Đo lại: IELTS sang Flexer/Memory/Minimalist/Squad và Đọc 10 trang sang Memory đều giữ tên, ngày, "3/5 ĐÃ HỌC", phút của chính hành trình; hành trình không phải chủ nhóm (Chạy sáng, Đà Lạt) không có mục đổi giao diện, đúng spec |
| Make version 30–31 (dock) | ✅ Trạng thái được chọn của dock đổi sang một viên thuốc trượt giữa các tab (kiểu iOS 26 / Material 3 Expressive) bao cả icon và nhãn, viền 1.5px + bóng cứng 2px, icon dạng fill màu mực, nhãn giữ độ đậm 700. Đo: viên thuốc 68×52, nhãn cách viền 6–7px, đúng tab ở /hub, /squad, /activity, /me, /j/running, /j/dalat |
| Make version 32 (luồng người mới, xoá tài khoản, đăng nhập) | ✅ Đã chạy thử: onboarding → đăng nhập → OTP → hồ sơ vào thẳng /create/1 với thẻ "Từ câu trả lời của bạn"; các màn trên đường có dòng "Sau bước này: tạo hành trình …"; Hub có thẻ "Tiếp tục tạo hành trình"; camera khi chưa có hành trình không hỏi quyền. Màn xoá tài khoản chỉ còn 6 ô mã. Đăng nhập có Google, tab Email/Số điện thoại, "Dùng mật khẩu". ✅ Dòng phụ ở thẻ camera trống đã nằm gọn trong thẻ (bản 33) |
| Make version 33: icon riêng + logo sticker | ✅ Bộ icon `OIcon` (`icons.tsx`, 50 icon nét 2px, bản active có viền bế như sticker) thay toàn bộ Phosphor: đo /hub, /settings, /j/ielts, /camera, /login không còn icon Phosphor. Wordmark sticker (`brand.tsx`) ở splash, Hub, đăng nhập; font logo nạp từ Google Fonts có bộ tiếng Việt. Đánh giá logo: `logo-sticker-review.md` (logo/icon 6/10, thiệp chia sẻ 8/10). Chưa xem kỹ thiệp chia sẻ và mục chọn icon ứng dụng |
| Make version 34: bỏ toàn bộ emoji/icon mặc định | ✅ Thêm icon loại hành trình (`type-*`), `TypeBadge`, lửa streak, cúp, sao mốc, 6 reaction tự vẽ, cây thông, mây, chấm thành viên; thay 145 chỗ emoji/ký tự biểu tượng. Quét 52 màn trên preview: 0 emoji; quét mã nguồn: 0. CLAUDE.md mục 1.3 đổi thành "không dùng icon mặc định". ✅ Bản 35: icon nhỏ dưới 24px (lửa, sách, cúp, sao, khoá, reaction, loại hành trình) dùng màu đặc + viền mực mảnh, viền bế sticker chỉ từ 24px; lửa streak cam #FF8A3D có lõi vàng |
| Make version 36: nhiều ảnh mỗi ngày | ✅ Spec `multi-photo-day.md` (trả lời câu 10 `client-questions.md`). Đã thử: /j/ielts/day/21 có dải 3 ảnh + "Đặt làm ảnh đại diện", "Xoá ảnh này", "1 ảnh / Ghép 2–4 ảnh"; chụp thêm từ camera → ngày 21 thành 4 ảnh, HUD "Hôm nay · 4 ảnh", streak giữ 18, ngày giữ 21. Chưa thử: nhóm ảnh trên timeline 6 giao diện, Couple nhiều nửa, Memory hết cuộn, thiệp ghép, Hoạt động gộp |
| Make version 37–40 | ✅ Bản 37: căn icon trong huy hiệu đúng tâm, tick góc thẻ 28×28 cách viền 10px, chip trên ảnh cách mép ≥ 8px. Bản 38: xoá ảnh duy nhất của ngày vẫn giữ ngày cho streak (SDS §7.1, Q11). Bản 39–40: bộ icon làm lại theo kiểu logo sticker (khối đặc, viền mực, bảng 6 màu logo, viền bế + nghiêng khi được chọn), icon luôn có màu kể cả khi chưa chọn; hộp "Sửa hồ sơ" và mọi sheet render trong khung điện thoại (`overlay.tsx`), đã thử mở/đóng 2 lần. Chưa đo lại căn tick sau khi đổi bộ icon |
| Make version 41 | ✅ Dock ở các màn chung (Hub, Hội, Hoạt động, Hồ sơ) luôn dùng vỏ chung (kem 78% + viền mực), không theo hành trình chính; chỉ trong /j/:id mới theo giao diện hành trình (đo với Chạy sáng là hành trình chính). Tick chọn không đè chữ/icon: nút phân đoạn dùng tick đứng trước chữ, ô lưới đặt tick ở góc riêng; Cài đặt: 11 tick, 0 chồng lấn |
| Make version 42: chọn hành trình trên camera | ✅ Theo `camera-journey-picker.md`: vòng xoay tối đa 5 đĩa (ghim tối đa 3 + tự điền hành trình chưa chụp hôm nay + "Tất cả (N)"), sheet "Tất cả" có ô tìm và nhóm, ghim/bỏ ghim, "Đăng thêm vào…" nhiều hành trình, dữ liệu mẫu 12 hành trình. Đã thử bằng cú bấm thật: sheet mở đúng. ⏳ Lỗi tên hành trình bị cắt "..." trên camera: xem `bugs.md` (A1–A3) (Make hết credit, chưa gửi) |
| Danh sách lỗi | 📄 Gộp mọi lỗi vào `bugs.md`: đang mở A1 (tên hành trình trên camera bị cắt), A2 (hành trình nhập ảnh cũ kéo dài vô tận), A3 (tuỳ biến avatar/nền/sticker), kèm prompt Make chưa gửi; mục B là lỗi đã sửa bản 18–42 |
| Code ở `design/ourney-v2-app` | ✅ Đã chép và commit nguồn version 42; version 33 thêm `icons.tsx`, `brand.tsx`, `index.css`); trước đó version 29 (routes, app.css, store, create, flow đọc lại qua Figma MCP). Typecheck đạt |
| Phản hồi chủ dự án (onboarding mang sang Tạo hành trình, vòng xoay đổi hành trình, HUD Squad, nút đổi hành trình trên camera, rà lỗi bo elip/chữ cắt/đè/chiều cao/mép) | 🔄 Đã tái hiện đủ, ghi nguyên nhân trong `feedback-2026-11-11.md`; ✅ Đã sửa trên Make version 24–25 (xem dòng Make version 25) |
| Lỗi "bấm Cài đặt ở màn hành trình" | ✅ Chủ dự án báo đã được sửa |
| Đề xuất dock 5 nút + chỗ dùng liquid glass | ✅ Chủ dự án đã duyệt (2026-11-11); đã gửi Make (kèm màn /activity và công tắc "giảm trong suốt"); CLAUDE.md mục 2 đã đổi sang dock 5 nút |
| Spec A (đổi bố cục trong hành trình), spec B (nhập hành trình đã qua) | 🔄 Đã viết (`feedback-2026-11-11.md` mục 2, 3; coi là câu trả lời câu 3 và 25 trong `docs/client-questions.md`), đã gửi Make trong cùng prompt FIX |
| Prompt 0 → 10 và các lượt FIX trước | ✅ Xong tới version 22 (xem các mục bên dưới và `bugs.md` (mục B)) |
| Đọc context repo (CLAUDE.md, SRS, docs/03, docs/06, templates, 6 ảnh persona) | ✅ Xong |
| Phân tích TripMate (nguồn cảm hứng neo-brutalism) | ✅ Xong |
| Chốt hướng với chủ dự án (vỏ chung + skin, tự do điều hướng, làm lại tất cả màn hình) | ✅ Xong |
| Đặc tả V2 (`README.md`) | ✅ Xong |
| Bộ prompt Figma Make 0 → 9 | ✅ Xong |
| File Make | 🔄 Dùng https://www.figma.com/make/XlPVftwSyACKWqj0m3FB0x/Ourney-Design-System (link `/design` không mở được Make nên đã tạo file mới; tên sẽ đổi thành "Ourney V2") |
| Prompt 0 trên Figma Make | 🔄 Đã chạy, chuyển thành khung app chạy được (FIX-1, FIX-3, FIX-4, FIX-5); đang kiểm tra mục Q |
| Prompt 1 → 10 trên Figma Make | ✅ Đã chạy hết (xem các dòng "Make version" bên dưới) |
| Quyết định mới: UI dùng nhãn "Hội" | ✅ Đã chốt |
| Quyết định mới: thẻ Minimalist hiển thị "24/30 NGÀY · 80% ĐỀU ĐẶN" | ✅ Đã chốt |
| Quyết định mới: nút chụp của Accountability Squad dùng `#FF9F1C` | ✅ Đã chốt |
| Quyết định mới: luật "chỉ hai đứa" giữ theo luật loại cũ; hỏi thêm hai màn hình | ⏳ Chờ chủ dự án trả lời về hai màn hình |
| Quyết định mới: bỏ giới hạn 3 hành trình | ✅ Đã chốt |
| Quyết định mới: prompt chỉ đối soát với đặc tả V2 | ✅ Đã chốt |
| Quyết định mới: kết quả phải là app có màn hình và tương tác thật | ✅ Đã chốt |
| Đổi contract dữ liệu cho Journey DNA (`journey.dna`, trường theo loại) | ⏳ Cần một PR contract riêng sau khi chốt thiết kế |
| Cập nhật CLAUDE.md / docs/06 theo hướng V2 (dock nổi, Journey DNA) | ⏳ Làm sau khi thiết kế được duyệt |

## Điểm dừng mới nhất (2026-11-04)

Làm tiếp theo quy trình trong `orchestration/` (brief, hợp đồng app, quy tắc F và Q). Thư mục SP trong các file đó là scratchpad cũ, có thể không còn; dùng scratchpad mới.

- File Make: https://www.figma.com/make/XlPVftwSyACKWqj0m3FB0x/Ourney-Design-System (chưa đổi tên thành "Ourney V2").
- Bộ prompt có 12 khối: 0, 1, 2, 3, 4, 5A, 5B, 6, 7, 8, 9, 10. Bảng trên ghi "1 → 9" là thiếu Prompt 10.
- Đang dừng ở: Giai đoạn 5 của Prompt 0. Prompt 1–10 chưa chạy.
- Đã chạy được: khung app, dock, vòng xoay chọn được hành trình, đĩa "+ mới" mở sheet, 6 hành trình mẫu.

Lỗi cần sửa trong một prompt FIX trước Prompt 1:
1. /hub và /squad: dock phải dùng chất liệu vỏ chung, chỉ nút Chụp mang màu hành trình; thẻ Hub giữ viền 2px, bóng cứng 4px theo vỏ chung (đang bị Minimalist bỏ bóng, Flexer thêm viền phát sáng).
2. /squad dark: nền đang xám, phải là #121212, surface #1C1B19; dock đặc, nhãn không nằm trong hộp đen.
3. Vòng xoay trên /hub light: không thấy hình tròn đĩa; đĩa và nhãn phải rõ trên lớp phủ ở cả light và dark.
4. Nút "đổi hành trình" đè tên đĩa và thẻ cuối: tách khỏi nội dung, ẩn khi vòng xoay mở, vùng chạm ít nhất 44pt; danh sách có đệm đáy.
5. Chữ tối thiểu 12px (nút đổi hành trình, nhãn đĩa, nhãn dock); vùng kéo sheet ít nhất 44pt.
6. Hub lần đầu chỉ hiện 3 thẻ: phải luôn đủ 6 hành trình mẫu, kể cả khi còn trạng thái cũ.

Không tính là lỗi của Prompt 0: sheet tạo là chỗ giữ chỗ (Prompt 3); HUD camera và thẻ theo DNA (Prompt 2, 5A–7). Q-vi và Q-ref của lượt này chưa có kết quả: chạy lại sau FIX.

Nội dung subagent tự đặt, chờ duyệt: quy tắc chụp lại, câu chữ rời nhóm, nội dung mẫu Điều khoản/Chính sách/Liên hệ (email giữ chỗ), mã hex biến thể màu, màu lỗi. SRS vẫn ghi giới hạn 3 hành trình.

## Điểm dừng cập nhật (2026-11-05): hết AI credit của Figma Make

Mục này thay cho "Điểm dừng mới nhất" ở trên.

- File Make: https://www.figma.com/make/XlPVftwSyACKWqj0m3FB0x/Ourney-V2 (đã đổi tên, preview chạy được).
- Figma Make báo: "You're out of AI credits in Phan Le Thanh Hoang (K18 DN)'s team Education plan until they reset on Dec 1."

| Prompt | Trạng thái |
| --- | --- |
| 0 khung app | Xong, đã kiểm tra Q |
| 1 đăng nhập, onboarding | Xong, đã kiểm tra Q; lỗi đã gửi kèm prompt sau |
| 2 Hub | Xong, đã kiểm tra một phần Q |
| 3 luồng tạo | Xong, đã kiểm tra một phần Q |
| 4 câu hỏi, 6 vé | Xong, chỉ bấm thử, chưa Q |
| 5A Quiet Transformer | Xong, chỉ bấm thử, chưa Q |
| 5B Accountability Squad | Xong, chỉ bấm thử, chưa Q |
| 6 Memory, Couple | DỞ: đã gửi, Make chỉ sửa routes và dữ liệu; /j/dalat và /j/couple còn "sắp có". Khi có credit, gửi lại toàn bộ Prompt 6 |
| 7, 8, 9, 10 | Chưa chạy |

Việc khi có credit lại: gửi lại Prompt 6, chạy 7 → 10 và gửi kèm lỗi còn lại, rồi chạy Q cho Prompt 4 → 10.

Lỗi còn lại cần gửi kèm:
- Chuỗi "chữ S" và màn đã thấy chưa kiểm tra light/dark, 1.35x.
- Giảm cân Q3 "Chụp ngay" về /create/3, chưa có màn chụp ghost.
- /j/:id của Squad: offline chưa hiện "Cần mạng" trên tường.
- Dock các skin cần khác hình khối rõ hơn (Q-skin).
- Avatar, nút X và kéo sheet mời chưa thử.
- Backlog5 đã gửi nhưng chưa kiểm tra lại: reset nháp tạo, sheet mời trong khung, biến thể màu vé, icon nửa khung.
- Nút chụp phải mở bằng nhấn giữ 400ms: công cụ tự động chưa thử được, cần thử tay.

## Điểm dừng cập nhật (2026-11-10): hết credit lần hai giữa Prompt 9

Mục này thay cho hai mục điểm dừng ở trên.

- Đã đổi sang tài khoản Figma khác (có quyền sửa file), nhưng credit AI vẫn tính vào team chứa file: Make lại báo "You're out of AI credits in Phan Le Thanh Hoang (K18 DN)'s team Education plan until they reset on Dec 1." Muốn chạy tiếp cần chuyển file sang team còn credit, hoặc chờ ngày 1/12.
- Route để kiểm tra (gõ vào ô địa chỉ của preview): id hành trình là `quiet`, `ielts`, `dalat`, `couple`, `running`, `minimal`.

| Prompt | Trạng thái |
| --- | --- |
| 0 → 5B | Xong (như bảng trên) |
| 6 Memory, Couple | Xong, Make version 13. /j/dalat và /j/couple chạy được (ghi chú "sắp có" trước đây là sai) |
| 7 Flexer, Minimalist | Xong, Make version 14, kèm sửa ảnh Couple và tiêu đề lặp |
| 8 xem một ngày, cập nhật, về đích | Xong, Make version 15 |
| 9 Hội, hồ sơ, cài đặt | DỞ: Make đã sửa routes.tsx (Hội, vào nhóm, hồ sơ, một phần cài đặt/xoá tài khoản; +1004 −29) rồi hết credit, chưa tạo version, chưa có CSS. Khi có credit: gửi lại toàn bộ Prompt 9 cùng các lỗi bên dưới |
| 10 | Chưa chạy |

Lỗi đã thấy, cần gửi kèm prompt sau:
- Minimalist /j/minimal: đường cam vẫn là các vạch rời trong từng ô (đã yêu cầu 2 lần); ô đã xong vẫn là ô trắng như icon, chưa có ảnh. Prompt 9 đã ghi cách vẽ cụ thể (một svg polyline phủ lưới), nhưng chưa chạy xong.
- /j/ielts/day/21: polaroid trắng, không có ảnh.
- /j/:id/edit phần "Bìa": ba ô đánh số "1 2 3", chưa phải bìa sticker.
- Flexer: dock ở Light đã được yêu cầu hiện nhãn, ảnh mỗi ngày khác nhau, dấu phẩy thập phân (gửi kèm Prompt 8, chưa kiểm tra lại).
- Các lỗi còn lại của mục 2026-11-05 vẫn còn nguyên (chưa kiểm tra lại).

## Điểm dừng cập nhật (2026-11-11): đã chạy hết Prompt 0 → 10

Mục này thay cho các mục điểm dừng ở trên.

- Chạy bằng tài khoản Figma có seat còn 3.000 credit trong team của file.
- Prompt 9: Make version 16 (làm nốt phần dở của lần hết credit). Prompt 10: Make version 17.
- Đã xem nhanh trên preview: /squad, /settings, /me, /settings/terms, /j/minimal. Chưa bấm thử từng luồng theo checklist của Prompt 8–10, chưa chạy Q (skin, mode, a11y, vi, rules, ref) cho Prompt 4–10.

Lỗi còn lại:
- /j/minimal: đường cam liền chỉ hiện ở hàng 3–4, chưa xuyên qua hàng 1–2 (đã yêu cầu 3 lần, Make vẫn lệch; nên sửa tay trong code hoặc mô tả lại khác đi). Số "25" vẫn đè cạnh ô nét đứt.
- Các lỗi của mục 2026-11-05 và 2026-11-10 chưa kiểm tra lại sau version 17.
- Đã kiểm tra lại sau version 17 và thấy đã sửa: polaroid /j/ielts/day/21 có ảnh; "Bìa" ở /j/:id/edit là bìa sticker; /join/K7Q2M9XA hiện vé xem trước, hai dòng "tiến độ tính từ ngày vào" và "không có link công khai".

## Kiểm tra tự động sau version 17 (2026-11-11)

Cách làm: mở thẳng URL preview `*.makeproxy-c.figma.site` (lấy từ iframe của trang Make) để đọc được DOM, rồi chạy script đo trong khung `.phone-frame` ở cả Sáng và Tối: cỡ chữ < 12px, vùng chạm < 44pt, chữ tiếng Anh, màn trống, tương phản chữ; và bấm thử luồng bằng click DOM.

Kết quả đo (13 route vỏ chung + 6 skin × 9 route):
- Cỡ chữ, vùng chạm, tiếng Anh: sạch, trừ công tắc ở /j/quiet/share cao 28px.
- Tương phản ở Tối: nút nguy hiểm "Xoá" / "Kết thúc hành trình" ~2,3:1 (chữ #9F1239 trên nền tối); chip đầu trang Squad 1,96:1; chữ "CƠM/CANH" trong minh hoạ Couple 1,14:1. (Số đo ở Sáng phần lớn là báo nhầm vì script lấy nền viền khung máy.)

Bấm thử:
- Prompt 8: reaction đổi một lúc một (nhưng 🔥 tăng 2 thay vì 1); menu "⋯" nhóm có Báo cáo/Chặn; "Lưu" chỉ bật sau khi sửa, tên mới hiện ở Hub; "Kết thúc hành trình" → chỉ đọc → Wrapped.
- Prompt 9: "Tham gia" tắt khi trống; mã sai, hết hạn có thẻ lỗi; mã hợp lệ → /j/ielts; "Nhắc Minh" → "Đã nhắc Minh" và tắt; cài đặt "Tối" đổi theme; xoá tài khoản 1 → 2 → 3. Lỗi: /join/:code giữ trạng thái mã đầu tiên khi đổi mã.
- Prompt 10: panel Ngày 1, Đang tải, Lỗi, Chỉ có mình bạn, Chuỗi đứt, Ảnh ẩn, Bị xoá khỏi nhóm đều hiện đúng câu chữ. Lỗi: "Rời nhóm" không vào được (người dùng luôn là chủ nhóm); Couple "Ảnh ẩn" hiện tên Minh; "Lỗi" không hiện bản đã lưu.

Đã gửi một lượt FIX gồm 11 mục trên (kèm lần thứ ba cho đường cam Minimalist).

## Sau lượt FIX (Make version 18, 2026-11-11)

Đo lại trên preview, cả 11 mục đã sửa:
- Nút nguy hiểm ở Tối: chữ #1A1A1A trên nền #FF8A80. Chip đầu trang Squad ở Tối: chữ #1A1A1A. Minh hoạ Couple không còn chữ.
- Reaction 🔥 2 → 3. /join/:code đổi đúng theo mã (NOJOIN01, K7Q2M9XA).
- Panel có "vai trò: Chủ nhóm | Thành viên"; thành viên ở /j/dalat/edit không có "Đổi mã", có "Rời nhóm" → sheet → về /hub, Đà Lạt biến khỏi Hub.
- Couple "Ảnh ẩn" hiện Nam; "Lỗi" hiện "Đang xem bản đã lưu"; Couple "Chuỗi đứt" ghi chuỗi dài nhất 18.
- Minimalist: một polyline 36 điểm đi qua ngày 1–24 ở cả 4 hàng; số ngày 25–30 nằm trong ô nét đứt.

Còn lại: chưa thử tay nhấn giữ 400ms ở nút chụp; chưa so ảnh với bảng thiết kế persona (Q-ref) cho Prompt 4–10.

## Q-ref và nút chụp (Make version 19, 2026-11-11)

- Nhấn giữ nút chụp (thử bằng pointer event): chạm 120ms → /j/ielts/camera; giữ ~550ms → mở vòng xoay hành trình, có nút đóng.
- Q-ref: đã so trang chủ, camera, thiệp của 6 skin với `apps/mobile/assets/design_personas/`. Bố cục đúng tinh thần từng bảng (đường cong + trục dọc, đường chữ S + cúp, sợi chỉ + polaroid, trục tim đôi, telemetry kính tối, lịch 7 cột). Đã gửi lượt FIX 2 và đo lại sau version 19:
  - Nhãn trên camera của Squad, Memory, Minimalist: trước là chữ trắng trên nền kem, giờ là chữ #1A1A1A; Squad đọc "📖 45 PHÚT · 🔥 18 LIỀN".
  - Tường polaroid Squad có tranh minh hoạ bàn học; dòng thời gian Quiet có ảnh minh hoạ theo ngày.
  - Camera Flexer có sticker HUD lớn ở đầu khung ngắm; camera Minimalist có cảnh sách và tách trà.
- Make version 20: chip góc trên camera Flexer chỉ còn "CHẠY SÁNG · NGÀY 21"; số km/nhịp chỉ còn trong sticker HUD (đã đo: "5,42 KM" xuất hiện 1 lần).
- Push: tài khoản `gh` đang đăng nhập (hofang42-xbrain) bị từ chối quyền với hofang42/Ourney (403); cần push bằng tài khoản hofang42.

## Make version 22 (2026-11-11)

Đã chạy kiểm tra Q cho Prompt 4 → 10 và sửa thêm (v21 dock Flexer ở Sáng, dấu phẩy thập phân, nút /create/4; v22 thẻ nhóm truy cập được bằng bàn phím). Báo cáo: `bugs.md` (mục B).

## Dock 5 nút + liquid glass (Make version 27–28, 2026-11-11)

- Chủ dự án duyệt đề xuất ở `feedback-2026-11-11.md` mục 4; chọn bỏ qua thử trên thiết bị thật (chỉ có kết quả giả lập trong trình duyệt).
- Đo trên preview: dock 5 nút (Hành trình · Hội · Chụp 72×72 · Hoạt động · Hồ sơ, mỗi mục 68×56) ở Hub, Couple, Flexer, camera; dock kính `blur(20px) saturate(1.6)` giữ viền; công tắc "giảm trong suốt" tắt kính. Màn `/activity` có nhóm Hôm nay / Tuần này; mỗi dòng là nút ≥ 44pt và mở đúng chỗ (điểm danh → `/j/ielts/squad`). Tab Hồ sơ mở `/me`.
- Đã bấm thử đủ 5 dòng ở `/activity` (version 29): điểm danh → `/j/ielts/squad`, reaction → `/j/ielts/day/21`, mốc → `/j/quiet`, lời mời → `/join/K7Q2M9XA`, nhắc giờ → `/j/minimal`.
- `CLAUDE.md` mục 2 đã đổi sang dock 5 nút và quy tắc liquid glass.
- Code ở `design/ourney-v2-app` đã chép tới version 42 (xem dòng "Code ở `design/ourney-v2-app`" trong bảng trạng thái).
