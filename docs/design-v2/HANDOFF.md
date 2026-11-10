# Prompt bàn giao sang session local (có Claude in Chrome)

Dán toàn bộ khối dưới đây vào một session Claude Code / Claude desktop **trên máy của bạn**, mở trong repo Ourney. Session đó cần có extension Claude in Chrome đã kết nối và đã đăng nhập Figma.
Trước khi dán, chép 3 file `docs/design-v2/README.md`, `figma-make-prompts.md` và `HANDOFF.md` từ cloud session vào cùng đường dẫn trong repo local (hoặc nhờ cloud session push lên một nhánh).

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
  Minimalist Habit); floating dock 3 mục (Hành trình · Chụp · Squad, nhấn giữ nút chụp để đổi hành trình);
  danh sách toàn bộ màn hình.
- docs/design-v2/figma-make-prompts.md: prompt 0 → 9 để chạy lần lượt trong Figma Make, kèm checklist.
- Ảnh tham chiếu 6 persona: docs/assets/design_personas/persona_*.jpg (đọc để nắm chất liệu từng skin).
- Ràng buộc gốc: docs/SRS.md, docs/06-adaptive-persona-ui-system.md (bảng màu persona đạt AA).

Quyết định đã chốt với mình:
1. Vỏ chung (Hub, tạo hành trình, onboarding, hồ sơ, squad) dùng neo-brutalism. Bên trong hành trình
   đổi hẳn sang skin riêng như ảnh mẫu, nhưng vẫn giữ "xương" brutal (viền, bóng cứng ở dock và nút chính).
2. Lúc tạo, mỗi hành trình phải ra một cá tính và phong cách riêng dựa trên nội dung của nó.
3. Không bắt buộc theo luật cũ (3 tab trong CLAUDE.md…). Ưu tiên UI hiện đại, bắt mắt nhất.
   Hiện đang đề xuất floating dock 3 mục.
4. Thiết kế lại TẤT CẢ màn hình, không dùng lại giao diện cũ.
5. Font: Space Grotesk (tiêu đề) + Be Vietnam Pro (nội dung). Không dùng Outfit vì không có dấu tiếng Việt.

Việc cần làm:
1. Dùng Claude in Chrome mở Figma Make. File đích: https://www.figma.com/design/nyvBJzr7XYlg7ZzhsJGoZx/Ourney-V2
   (nếu link /design không mở được Make, hãy tạo file Make mới tên "Ourney V2" rồi hỏi lại mình).
   Có thể mở bản V1 để tham khảo những gì KHÔNG nên làm:
   https://www.figma.com/make/z3B1WO8e7SUNG83jvaPotn/Ourney-V1.0
2. Dán lần lượt Prompt 0 → 9 từ figma-make-prompts.md. Sau mỗi prompt: chụp màn hình kết quả,
   kiểm tra theo checklist, nếu sai thì gửi prompt sửa ngắn rồi mới chạy prompt kế tiếp.
3. Cập nhật mục "Trạng thái" bên dưới sau mỗi prompt (prompt nào xong, có vấn đề gì).
4. Hỏi lại mình ngay nếu gặp chỗ chưa rõ hoặc Figma Make cho kết quả lệch hướng nhiều.
   Đừng tự đổi hướng thiết kế.
```

---

## Trạng thái (cập nhật 2026-11-04)

| Việc | Trạng thái |
|---|---|
| Đọc context repo (CLAUDE.md, SRS, docs/03, docs/06, templates, 6 ảnh persona) | ✅ Xong |
| Phân tích TripMate (nguồn cảm hứng neo-brutalism) | ✅ Xong |
| Chốt hướng với chủ dự án (vỏ chung + skin, tự do điều hướng, làm lại tất cả màn hình) | ✅ Xong |
| Đặc tả V2 (`README.md`) | ✅ Xong |
| Bộ prompt Figma Make 0 → 9 | ✅ Xong |
| File Make | 🔄 Dùng https://www.figma.com/make/XlPVftwSyACKWqj0m3FB0x/Ourney-Design-System (link `/design` không mở được Make nên đã tạo file mới; tên sẽ đổi thành "Ourney V2") |
| Prompt 0 trên Figma Make | 🔄 Đã chạy, chuyển thành khung app chạy được (FIX-1, FIX-3, FIX-4, FIX-5); đang kiểm tra mục Q |
| Prompt 1 → 9 trên Figma Make | ⏳ Chưa chạy |
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

Đã chạy kiểm tra Q cho Prompt 4 → 10 và sửa thêm (v21 dock Flexer ở Sáng, dấu phẩy thập phân, nút /create/4; v22 thẻ nhóm truy cập được bằng bàn phím). Báo cáo: `qa-make-v22.md`.
