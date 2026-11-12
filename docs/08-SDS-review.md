# Ourney — Đánh giá hợp nhất SDS UI/UX v0.2 (bản phán quyết)

> Đối tượng: [07-SDS-ui-design.md](07-SDS-ui-design.md) v0.2 · Ngày: 2026-10-22
> Đầu vào: Review A (UX/luồng), Review B (visual/hệ thống/a11y), quyết định khách hàng vòng 2 (R2-01…R2-22, **có hiệu lực ràng buộc**), SRS §3.1, CLAUDE.md, 6 board trong `apps/mobile/assets/design_personas/` (đã mở xem từng board).
> Contrast: **tính lại toàn bộ** bằng công thức WCAG 2.x relative luminance (script Node), không lấy lại số của reviewer.
> Quy ước: **[ĐỀ XUẤT — chờ duyệt]** = giá trị do người phán quyết đề xuất (màu, font, prompt), khách hàng chưa duyệt. Mọi điểm cần quyết định sản phẩm mà D1–D25/R2-xx chưa trả lời đều nằm ở §10, **không tự chốt**.

---

## 1. Tóm tắt

**Kết luận: SDS v0.2 CHƯA sẵn sàng để đưa cho AI dựng giao diện.** Phần khung (nguyên tắc, token shell, component, danh sách màn) tốt và đủ chi tiết. Tuy vậy còn ba nhóm việc phải làm trước: (1) áp 21 quyết định vòng 2, vì nhiều quyết định xóa hoặc đổi hẳn màn (bỏ đăng đa hành trình, Squad cố định, Shelf vào Hub, nhịp linh hoạt, cổng tuổi); (2) sửa token màu, vì nhiều cặp chữ/nền trượt AA thật; (3) viết lại Phụ lục A và vẽ lại board. Nếu đưa ngay, AI sẽ sinh ra nút mờ chữ, emoji làm icon, dock sai và chép lại lỗi của board cũ. Làm xong danh sách P0 ở §9 là đủ điều kiện ra v0.3.

**5 vấn đề lớn nhất**
1. **Contrast trượt AA ở token cốt lõi** (F-01): chữ trắng trên `primaryAccent` trượt ở 8/10 phong cách (persona 1: 2.54, 2: 2.05, 4: 3.53, 5: 3.21, 6: 3.56, 7: 3.09, 8: 3.43, 9: 2.99). `streak`/bg sáng chỉ đạt 1.96, trắng/`brand` dark 2.98. Không có token `onAccent`/`accentInk`.
2. **Quyết định vòng 2 chưa có trong spec** và mâu thuẫn trực tiếp với các màn hiện tại (F-08, F-14, F-16, F-42…): SCR-10 chọn nhiều, SCR-12 `Also post to…`, tab Squad, SCR-27, giả định "hằng ngày" ở khắp nơi.
3. **Mô hình chuỗi ngày chưa khép kín** sau R2-01 + R2-05 (F-09, F-50, F-52): chuỗi chung của nhóm, freeze theo nhóm, nhịp tuần/tháng, giờ cảnh báo (20:00 hay 21:00) và ranh giới "ngày". Mấy điểm này cần khách hàng trả lời (§10 Q1–Q4).
4. **Cả 6 board đều có lỗi** (F-03): placeholder `...` và `3-tab`, lịch 5 cột, ngày nhảy lung tung, "His/Her", dock có bánh răng, chữ sai chính tả. Phụ lục A lại bảo AI "match exactly", nên lỗi sẽ bị chép tiếp (F-02).
5. **Riêng tư và an toàn trẻ em**: chưa có cổng tuổi, lý do báo cáo "Child safety", che widget/thông báo cho hành trình nhạy cảm, cảnh báo khi bật link (F-20, F-41, F-42). Các điểm này đã có quyết định R2-06/07/08 nhưng chưa vào spec. Riêng cổng tuổi còn vướng với chế độ không tài khoản (F-51).

---

## 2. Đánh giá hai bản review

### Review A (UX, luồng, IA)
- **Chất lượng: tốt.** Bao quát luồng thật (đếm chạm, đóng sheet, lỗi tải, chủ nhóm rời, mời khi chưa cài app), trích đúng vị trí. Các mâu thuẫn nội bộ (20:00 vs 21:00, D8→D16, §2.4 vs D20, 48dp vs 56×40) đều **đúng khi đối chiếu văn bản**.
- **Đúng:** A01 (đếm chạm đúng: dock → chọn dòng → chụp → Post = 4), A03 (SCR-13 tự chuyển 1.5s mâu thuẫn §5.8 nút `Next`), A17, A18, A19, A29 (sơ đồ thiếu SCR-14/15/56/71/72).
- **Chưa chuẩn:**
  - Đánh **High** hơi tay cho A06/A07: thiếu màn sửa check-in là lỗ hổng, nhưng không chặn việc dựng.
  - A07 đề xuất trạng thái "quota đầy → SCR-60", nay **trái R2-04** (miễn phí không giới hạn).
  - A10 đề xuất tạm "ẩn chuỗi ở 8–10", bị R2-05 thay thế.
  - A26 đề xuất 3 mức giọng, R2-13 chốt 2 mức.
  - A30 đề xuất "nhân bản ảnh", trái R2-10.
  - A20 bỏ sót là CLAUDE.md §4 **cho phép rõ** `Nudge 👋`.
- **Bỏ sót:** không xem board (không phát hiện lỗi board) và không kiểm contrast. Vì hạn chót, A cũng không thấy được các xung đột mới mà quyết định vòng 2 tạo ra (cổng tuổi vs chế độ khách, chuỗi chung vs tường nhóm).

### Review B (visual, hệ thống, a11y)
- **Chất lượng: rất tốt về số liệu.** **Mọi tỉ lệ contrast B đưa ra đều khớp** với lần tính lại của tôi (sai số 0.00–0.01). Phát hiện thiếu `onAccent`/`accentInk` là đúng và nặng nhất. Phần riêng tư (B-19/20/21) là đóng góp quan trọng, đều đã được khách chốt.
- **Sai hoặc thiếu:**
  - **B-02 bỏ sót persona 4**: trắng/`#E15B72` = **3.53**, cũng trượt.
  - **B-09 có 2 nhận định sai.** (a) "tab giữa ở camera persona_6 bị thiếu": board có nút chụp tròn ở giữa và đủ nhãn Journeys/Squad. (b) "contact sheet 15 khung trái spec 20": SDS §6.4-3 ghi "**tối đa** 20 khung", nên 15 khung không vi phạm. Ngoài ra **B chỉ xem board 3 và 6**, nên bỏ sót lỗi ở board 1, 2, 4, 5 (xem F-03).
  - **B-01 đề xuất `streakInk ≈ #B45309`**: trùng hệ màu `warning` (`#B45309`), làm chuỗi đang cháy trông như cảnh báo "sắp đứt". Đề xuất này bị loại.
  - B-22 áp cho persona 7, nhưng §6.2 ghi Glow Ritual **chỉ Solo**, nên chỉ đúng với persona 1.
  - B-13 đề xuất "ẩn nhãn dock ở 1.35×", trái §2.7 và CLAUDE.md §2 (icon điều hướng luôn có nhãn).
- **Nhìn chung:** B mạnh hơn ở tính kiểm chứng, A mạnh hơn ở luồng. Hai bản bổ sung nhau và ít trùng: chỉ trùng ở emoji (A20/B-18), touch target (A19/B-13/14) và link trẻ em (A17/B-20).

---

## 3. Bảng phát hiện đã hợp nhất

Mức: Critical / High / Medium / Low. Phán quyết: **Chấp nhận** · **Chấp nhận có sửa** · **Đã giải quyết bởi R2-xx** (thành lệnh sửa ở §5) · **→ Câu hỏi** (cần khách hàng, xem §10). Mức đã chấm lại được ghi "(từ X)".

| ID | Nguồn | Mức | Phán quyết | Vị trí | Vấn đề | Cách sửa |
|---|---|---|---|---|---|---|
| F-01 | B-01, B-02, B-03, B-04, B-05 + phán quyết | Critical | Chấp nhận có sửa (số đã tính lại; thêm persona 4; loại `streakInk=#B45309`) | §3.1, §6.3, CMP-01/02/06/07 | Không có token chữ-trên-accent và accent-làm-chữ. Trắng/accent trượt ở 1, 2, 4, 5, 6, 7, 8, 9. Accent làm chữ trên bg sáng trượt ở 1, 2, 4, 5, 6, 7, 8, 9. Dark: accent làm chữ trượt ở 3 (3.69) và 10 (3.64). Shell: `streak` 1.96, `plusGold` 2.91 (viền), trắng/`brand` L 3.48 (nhãn 17pt **không** phải chữ lớn theo WCAG, cần ≥18.66px đậm), D 2.98. `brandInk`/`surfaceSunken` 4.42 (**mới**, cả hai reviewer bỏ sót). Câu "đạt AA" ở §3.1 và §6.3 chưa đúng | Thêm token `onAccent`, `accentInk` cho mọi phong cách (L/D), cùng `onBrand`, `successInk`, `plusGoldInk`, `streak` (icon) cho shell. Giá trị và tỉ lệ: §6. Quy tắc: số chuỗi ngày luôn dùng `ink`. Accent không bao giờ làm chữ, chữ màu dùng `*Ink`. Đường/viền/vòng chỉ báo dùng `accentInk` khi accent/bg < 3:1 |
| F-02 | B-07, B-08 | High | Chấp nhận | Phụ lục A | Prompt bắt "match exactly" board có lỗi. Nút chụp "round coral" trên cả 3 màn trái CMP-01. Tiêu đề luôn serif. Emoji làm icon (`🔒` `🌽` `🔊` `✓`). Không có prompt dark | Thay toàn bộ Phụ lục A bằng §8.4 (chung) và §8.3 (dark) |
| F-03 | B-09 + phán quyết (đã xem 6 board) | High | Chấp nhận có sửa (bác 2 nhận định của B, thêm lỗi ở 1/2/4/5) | `design_personas/*.jpg`, §6.1 | **P1:** nút giữa dock tròn màu coral ở cả 3 màn (spec: viên 56×40 màu emerald ngoài camera). Camera thiếu hàng thư viện/lật. "DAY 01 ·" thừa dấu. **P2:** viên giữa dock ghi `...` (placeholder, màn 1 và 3). `📖` và cúp 🏆 dạng emoji. Viên màu coral thay vì vàng flame. **P3:** nhãn `3-tab` (màn 3), "CAMPFIRE 10GNT", camera không có dock. **P4:** "his cooked breakfast / her coffee", "HIS PHOTO", "Snap Her Half" (§6.4-4 cấm His/Her). Màn 3: tab phải `3-tab` icon danh sách thay Squad. Icon Journeys lúc bản đồ lúc la bàn. Tiêu đề "30-Day" nhưng poster "18 DAYS". **P5:** chỉ có bản dark. Màn 3 dock là 3 icon không nhãn (la bàn, `+`, bánh răng). Status bar 9:16. "Flim Strip". Heatmap phân biệt bằng đỏ/vàng/xanh (spec: ô đặc vs rỗng). **P6:** nhãn `3 tab` (màn 2, 3). Lịch 5 cột "MO TU WE TH FF". Số ngày lặp/nhảy (15, 14, 15…; ô ghi 01/22/24). "24/30 · 96%" sai toán | Vẽ lại cả 6 board theo R2-19 (prompt §8.2). Đến khi có board mới, §6.1 ghi danh sách "không chép" |
| F-04 | A20, B-18 | Medium | Chấp nhận có sửa | §2.8, CMP-19, §6.4-1/2/10, SCR-13/41 | Quy tắc emoji mơ hồ, ví dụ trong spec tự vi phạm (`❄ 3`, `📖`, `Done ✓`, `🔒`) | Viết lại §2.8: emoji **được** dùng trong *nội dung chữ* (copy, thông báo, ví dụ R2-11 "💪"), reaction, lửa 🔥, huy hiệu mẫu, sticker. Emoji **không bao giờ** làm icon trong chip, nút, HUD, dock. Ngoại lệ duy nhất là `Nudge 👋` (CLAUDE.md §4). Thay `❄`→"icon bông tuyết (vector)", `📖`→"icon sách", `✓`→"icon check", `🔒`→"icon khóa" |
| F-05 | A01 | High | Chấp nhận có sửa (phần chọn nhiều đã bị R2-10 bỏ) | §2.3, §8.1, SCR-10, CMP-01 | "3 chạm" sai với đường vào từ dock khi ≥2 hành trình chưa xong (4 chạm) | §2.3: "**≤3 chạm khi đã ở đúng hành trình** (mở app có 1 hành trình chưa xong, chạm vòng Today, widget). Từ dock khi ≥2 hành trình chưa xong: 4 chạm." Thêm bảng đếm chạm cho từng đường vào |
| F-06 | A02 | High | Đã giải quyết bởi R2-03 | D9, SCR-10, SCR-70 | Mỗi lần mở app bị sheet Today chặn. Chưa nói đóng sheet thì đi đâu | Xem §5 R2-03 |
| F-07 | A03 | High | → Câu hỏi Q5 | SCR-13 vs §5.8 | SCR-13 tự về camera sau 1.5s, trong khi §5.8 có nút `Next: Daily English` | Chờ khách chọn. Đến lúc đó §5.8 và SCR-13 phải ghi **một** cơ chế |
| F-08 | A04 | High | Đã giải quyết bởi R2-10 (xóa tính năng) | SCR-10, SCR-12, §5.8 | Đăng một ảnh vào nhiều hành trình gây rủi ro riêng tư | Xóa chế độ chọn nhiều, `Also post to…` và các dòng §5.8 tương ứng |
| F-09 | A05, A16 | High | Một phần giải quyết bởi R2-01, phần còn lại → Q1, Q3 | D22, SCR-10/22/24/26, NTF-02/09, CMP-19 | Freeze theo người hay theo hành trình. Lỡ nhiều ngày. Ba mốc cảnh báo 20:00/21:00/9 PM. Ranh giới ngày và múi giờ | Áp R2-01 (§5). Mốc cảnh báo, ranh giới ngày, phạm vi freeze solo và giới hạn freeze nhóm chờ Q1/Q3 |
| F-10 | A06 | Medium (từ High) | Chấp nhận | SCR-25, §14 | Không sửa được cảm xúc/sticker/chỉ số. Không có xác nhận xóa, xóa hàng loạt, lưới ngày | Thêm **SCR-25a Sửa check-in** (caption, cảm xúc, sticker, chỉ số), chế độ lưới và chọn nhiều trong album ngày, hộp thoại xóa. Hệ quả chuỗi khi xóa ảnh duy nhất của ngày chờ Q11 |
| F-11 | A07 | Medium (từ High) | Chấp nhận có sửa (R2-04) | CMP-12, §14, SCR-60, SCR-70 | Thiếu hàng đợi tải, lỗi vĩnh viễn, đầy bộ nhớ máy. Quyền lợi "More cloud storage" và thanh dung lượng nay vô nghĩa | Thêm sheet **Upload queue** (đang chờ, đang tải, lỗi, `Retry all`), trạng thái lỗi vĩnh viễn và "Bộ nhớ máy đầy". **Không** có trạng thái quota đầy. Sửa SCR-60/70 theo R2-04 |
| F-12 | A08 | High | Đã giải quyết bởi R2-12 | SCR-04, SCR-42/43, §13 | Mời khi chưa cài app/chưa đăng nhập không có luồng. `I was invited` trùng SCR-43 | Thêm WEB-04, tự dán mã. SCR-04 `I was invited` → SCR-43 (một điểm nhập mã duy nhất) |
| F-13 | A09 | High | Đã giải quyết bởi R2-09 + SRS §3.1. Couple → Q8 | SCR-26, §14 | Chủ nhóm rời, ảnh người rời, Couple chia tay, thiếu màn thành viên | Xem §5 R2-09. Kịch bản đối tác Couple rời chờ Q8 |
| F-14 | A10 | High | Đã giải quyết bởi R2-05, sinh câu hỏi mới Q2 | D22, §6, §7, §8, §10, SCR-22 | Mọi thứ giả định check-in hằng ngày | Thêm trường **Nhịp** vào SCR-22/26. Hiển thị chuỗi/lịch cho nhịp không hằng ngày chờ Q2 |
| F-15 | A11 | Medium | Chấp nhận có sửa | SCR-20 | Hub quá nhiều lớp. Import bị chôn | Ẩn lọc và sắp xếp sau một nút `Sort & filter` khi ≤6 hành trình. Đưa `Import a past journey` vào menu `+`. Thêm segment `Active | Shelf` (R2-02). Ghi chiều cao từng khối |
| F-16 | A12 | Medium | Đã giải quyết bởi R2-02 (bác phần "ẩn tab Squad") | CMP-01, SCR-20, SCR-40 | Vai trò Hub/Squad, viên chụp chạm ra gì, icon Journeys dễ nhầm với kiểu xem Map | Squad cố định. Giữ icon bản đồ gập cho Journeys (CLAUDE.md §2), đổi icon kiểu xem `Map` thành **ghim địa điểm**. Bỏ chip `Squad/Couple` khỏi bộ lọc Hub (trùng tab). Viên chụp khi 0 hành trình chưa xong chờ Q20 |
| F-17 | A13 | Medium | Chấp nhận | SCR-22 | 9 nhóm trường, chưa ghi mặc định, chậm tới ảnh đầu tiên (R2-05 còn thêm 1 trường) | Thêm **chế độ nhanh**: Tên + `Start journey`, các mục khác gập trong `More options` với giá trị mặc định ghi rõ. Thời lượng mặc định chờ Q21 |
| F-18 | A14 | Medium | Chấp nhận | SCR-11, §5.8 | Vuốt đổi hành trình trên khung ngắm: không thấy đích, dễ đăng nhầm | Thêm chỉ báo trang (chấm) và tên hành trình đích trượt vào trong 260ms. Vuốt được hai chiều. SCR-12 header luôn hiện **tên hành trình + nhãn riêng tư** cạnh `Post`. Ống kính giữ nguyên (R2-17) |
| F-19 | A15 | Low (từ Medium) | Chấp nhận | SCR-10, §5.8 | `Skip today` gợi ý tạm dừng | Đổi thành `Hide for today` / `Ẩn hôm nay` + phụ đề "Still counts as missed" / "Vẫn tính là lỡ" |
| F-20 | A17, B-20 | High | Đã giải quyết bởi R2-06 (giữ D20) | §2.4, §9.2, SCR-50, WEB-02 | §2.4 nói ảnh trẻ em mặc định ẩn, mâu thuẫn D20. Không có cảnh báo khi bật link. OG để lộ ảnh | Xem §5 R2-06. `noindex` và trạng thái mặc định của công tắc link chờ Q12 |
| F-21 | A18 | Medium | Chấp nhận (sửa tham chiếu). Phần ngày cũ → Q9 | §6.4-4, §9.3 | "theo cài đặt D8" là tham chiếu cũ. Không rõ che ảnh áp cho ngày cũ không | Đổi thành "theo D16 (§9.3)". Phạm vi ngày chờ Q9 |
| F-22 | A19, B-13, B-14 | Medium | Đã giải quyết bởi R2-14 (bác "ẩn nhãn dock") | §2.7, §3.2, CMP-01/03/04-07/17 | Viên 56×40 và CMP-03 36–40 nhỏ hơn 48. Chữ 12–13pt. Chưa có hành vi ở 1.35× | Xem §5 R2-14. Thêm cột "Ở 1.35×" cho CMP-04/05/06/07/17. Dock: cao tối thiểu 64 + safe area, nhãn được xuống 2 dòng, **không ẩn** |
| F-23 | A21 | Low | Chấp nhận có sửa | SCR-22 mục 2 | `With friends` không hợp với gia đình hay vợ chồng | [ĐỀ XUẤT] `Just me` · `With others` / `Cùng mọi người` (≤10). Couple giữ `With my person` |
| F-24 | A22 | Medium | Chấp nhận | SCR-11 (thư viện) | Chọn nhiều ảnh khác ngày thì hỏi lặp. Chưa xử lý ảnh thiếu EXIF và quyền "một phần" của iOS | Một **sheet gộp theo ngày** ("3 photos from today · 2 from Oct 18 → add to their days"). Ảnh không có ngày chụp: hỏi một lần, mặc định là hôm nay. Thêm trạng thái quyền ảnh giới hạn (`Select more photos`) |
| F-25 | A23 | Medium | Đã giải quyết bởi R2-11 + R2-09. Gia hạn sau khi kết thúc → Q10 | SCR-55, SCR-24, SCR-26 | Màn kết thúc luôn ăn mừng to. Season 2 kéo thành viên vào. Mâu thuẫn chỉ-đọc vs gia hạn | Xem §5 R2-11, R2-09 |
| F-26 | A24 | Medium | Chấp nhận. Dữ liệu khách → Q7 | SCR-02, SCR-70, §14 | Chế độ không tài khoản chưa có luồng nâng cấp. Chưa có lịch xin quyền | Thêm bảng "xin quyền lúc nào": camera ở SCR-04, thông báo sau check-in đầu tiên, ảnh khi chạm thư viện, vị trí khi bật `location & weather`. Mỗi quyền có sheet giải thích trước |
| F-27 | A25 | Low | Chấp nhận (ghi rủi ro) | §1.4, SCR-40/41 | v1 không có push từ bạn nên Squad v1 yếu | Ghi rủi ro ở §1.4. Thiết kế trạng thái Squad v1 không có nút Nudge (nút `[v2]` ở trạng thái "Coming soon") |
| F-28 | A26 | Medium (từ Low) | Đã giải quyết bởi R2-13 + sửa copy | §3.6, §10 | Tiếng lóng khó hiểu. "Hết cứu 😵" gây cảm giác tội lỗi, trái chính §3.6. Thiếu bản ấm | Thêm cột `Gentle` cho NTF-01…10 và các câu SCR-13/55. Viết lại "Hết cứu…" thành câu không gây tội lỗi ở cả hai tông. Phạm vi áp dụng tông chờ Q24 |
| F-29 | A27 | Low | Chấp nhận | §0, §3.6, toàn tài liệu | Nhiều màn chỉ có chuỗi EN | Thêm Phụ lục B "Bảng chuỗi EN/VI". Test độ dài với chuỗi VI dài nhất ở 1.35× (chip, dock) |
| F-30 | A28 | Medium | Chấp nhận | §0, §16 | Thiếu dữ liệu mẫu chung nên các màn dựng riêng sẽ lệch nhau | Thêm Phụ lục C "Bộ dữ liệu mẫu": 1 người dùng, 10 hành trình (mỗi phong cách 1), 4 thành viên nhóm, ngày cố định, số liệu khớp nhau |
| F-31 | A29 | Low | Chấp nhận | §4.1 | Sơ đồ thiếu màn và luồng | Cập nhật: SCR-14/15/56/71/72, WEB-04→SCR-43, Hub segment Shelf, Squad landing, dismiss Today→Hub, SCR-13→camera |
| F-32 | A30 | Low | Chấp nhận có sửa (bác "nhân bản", trái R2-10) | SCR-22, D3 | Chọn nhầm mẫu không có lối thoát | SCR-22 thêm dòng xác nhận "Style can't be changed later" cạnh `Start journey`. "Chuyển ảnh sang hành trình khác" chờ Q23 |
| F-33 | A31 | Low | Chấp nhận | SCR-28 | Nhập hàng trăm ảnh: không có tiến độ, trùng ảnh | Thêm thanh tiến độ, đánh dấu ảnh trùng ("Already added"), giới hạn hiển thị theo tháng |
| F-34 | B-06 | High | Đã giải quyết bởi R2-17 | §6.4-7, SCR-11 | Glow "camera trước mặc định" trái nguyên tắc không khởi động lại camera | Xem §5 R2-17 |
| F-35 | B-10 | Medium | Đã giải quyết bởi R2-15 | §6.3 | 7≈4 (ΔE76 = 20, bg lệch ΔE 1.4), 9≈2 (ΔE 19), 8≈10 (ΔE 32) | Bảng màu mới ở §6 [ĐỀ XUẤT] |
| F-36 | B-11 | Medium | Chấp nhận → Câu hỏi Q18 | §6.4-1/7/9 | Ba timeline trục dọc (1, 7, 9) chỉ khác trang trí | Chờ khách chọn phương án bố cục |
| F-37 | B-12 | Medium | Đã giải quyết bởi R2-18 | §3.2, §6.3 | Font trang trí chưa có tên, nhiều font kiểu máy đánh chữ không có dấu tiếng Việt | Font ở §7 [ĐỀ XUẤT]. Đã kiểm: Special Elite và Courier Prime **không** có subset vietnamese |
| F-38 | B-15 | Medium | Chấp nhận | CMP-10, §8.4 | Sticker trên ảnh bất kỳ chưa có quy tắc contrast | Sticker luôn có nền đặc, hoặc kính tối ≥72% (chữ trắng ≥7.56:1 kể cả trên ảnh trắng), kèm viền 1px và bóng. Cao tối thiểu 28pt. Tránh vùng an toàn Story (trên 250px, dưới 340px) |
| F-39 | B-16 | Medium | Chấp nhận | §3.4, §6.4-5/8 | Animation lặp (lửa, vòng nhấp nháy, glow neon) chưa có giới hạn | Không nhấp nháy >3 lần/giây. Lặp tối đa 3 chu kỳ rồi dừng. Khi bật Reduce Motion: trạng thái tĩnh + chữ ("Ends in 3h") |
| F-40 | B-17 | Medium | Đã giải quyết bởi R2-21 | §3.1, §6.3, SCR-11 | Không có token chrome trên camera | Thêm nhóm token `cameraChrome` (§6.4) |
| F-41 | B-19 | High | Đã giải quyết bởi R2-08 | §10, §11 | Widget/thông báo lộ ảnh và tên hành trình nhạy cảm | Xem §5 R2-08. Ghi rõ widget màn khóa là đơn sắc |
| F-42 | B-21 | High | Đã giải quyết bởi R2-07 | SCR-03, SCR-72 | Thiếu cổng tuổi và lý do "Child safety" | Xem §5 R2-07. Xung đột với chế độ khách: F-51 |
| F-43 | B-22 | Low (từ Medium) | Chấp nhận có sửa (chỉ persona 1) | SCR-22 bước 2/7 | Ảnh cơ thể hiện ngay trong nhóm | Persona 1 khi chọn `With others`: dòng nhắc một lần "Photos show to your group right away unless you turn on Hide until they post". Persona 7 chỉ Solo, không áp |
| F-44 | B-23 | Medium | Chấp nhận | §6.4-1/7/8/9/10, §8.4 | Chưa nói ghost overlay có in vào ảnh không. Chưa nói `Hide numbers` có áp lên sticker trong nhóm không | Ghi: ghost chỉ là lớp xem trước, **không bao giờ** lưu vào ảnh (khớp R2-20). Chỉ số bật `Hide from others` không hiện thành sticker cả trong nhóm lẫn khi chia sẻ |
| F-45 | B-24 | Medium | Chấp nhận | §12, §3.3 | Tablet thiếu số đo. "520dp ở giữa" mâu thuẫn với 2 cột | Bảng 600–839 / 840–1199 / ≥1200: rail 88dp, cột trái 360dp, cột phải co giãn. Ghi rõ 520dp chỉ áp cho màn 1 cột |
| F-46 | B-25 | Low | Chấp nhận | §11, §13 | Widget và web thiếu kích thước, trạng thái, dark mode | Bổ sung bảng cỡ WGT (S/M/L, tinted/clear iOS 18, Android Glance), trạng thái trống/offline/ảnh bị che. Web: breakpoint 600/1024, dark, lightbox dùng được bàn phím, alt text |
| F-47 | B-26 | Medium (từ Low) | Chấp nhận (đã tính: chữ trắng trên scrim 45% phủ ảnh trắng = **3.36**, trên 60% = 5.74) | §3.1 `scrim` | Scrim 45% không đủ cho chữ thường | `scrim` light = 60%. Chữ trên ảnh dùng gradient 0→60% hoặc chip theo `cameraChrome` |
| F-48 | B-27 | Low | Chấp nhận | §6.3 hàng 5 | Lime phụ của persona 5 trên bg sáng chỉ 1.45. Board chỉ có dark | Ghi rõ `secondaryAccent` chỉ dùng trang trí, cấm làm chữ (áp mọi persona). Board 5 cần bản light (§8.2) |
| F-49 | Phán quyết | Medium | Mới | §6.4-6, CLAUDE.md §4, board 6 | "24/30 days · 96% consistency" sai toán (24/30 = 80%) | Định nghĩa "consistency" chờ Q19. Dữ liệu mẫu phải khớp |
| F-50 | Phán quyết | High | Mới → Q2 | D22, CMP-06/07, §6.4-6, §7, SCR-10 | R2-05 (nhịp linh hoạt) xung đột với "lỡ một ngày", ô "ngày lỡ", chuỗi "Don't break the chain" nối từng ngày, "Streak ends in 3h", lưới 7 cột | Chờ Q2 |
| F-51 | Phán quyết | High | Mới → Q6 | SCR-02 `Try without an account`, R2-07 | R2-07 hỏi ngày sinh "khi đăng ký", nhưng chế độ khách không đăng ký | Chờ Q6 |
| F-52 | Phán quyết | Medium | Mới → Q4 | SCR-41, CMP-05, SRS FR-D3, R2-01 | R2-01 chuỗi chung theo hành trình, nhưng SCR-41 ô thành viên và SRS FR-D3 hiện "streak từng người" | Chờ Q4. R2-01 mới hơn SRS nên thắng ở phần chuỗi chung |
| F-53 | Phán quyết | Medium | Mới (R2-20) | SCR-11, §6.4-3/5, Phụ lục A | Spec chưa có câu "không bộ lọc". Board 3 có màu ảnh như film | SCR-11 + §6.1: "**Không có bộ lọc màu.** Camera hiển thị và lưu ảnh nguyên bản. 'Look' của phong cách (film, tem ngày, HUD) chỉ là **lớp nhãn phủ**, không chỉnh màu ảnh" |
| F-54 | Phán quyết | Low | Mới | §4.2 | Ghi "NTF-01…08" nhưng §10 có NTF-10 | Sửa thành NTF-01…10 (thêm NTF mới nếu có) |
| F-55 | Phán quyết | Medium | Mới (SRS §3.1) | SCR-26 | SRS: chỉ xóa được hành trình khi nhóm còn mỗi owner. Không còn ai thì lưu trữ. SCR-26 chưa phản ánh | SCR-26: `Delete journey` chỉ hiện khi còn mỗi owner. Còn người khác: chỉ `End journey` + chú thích |
| F-56 | Phán quyết | Low | Mới (R2-12) | SCR-43 | Tự dán mã từ clipboard kích hoạt banner "Allow Paste" của iOS | Thiết kế trạng thái: sheet giải thích → hộp thoại hệ thống → điền mã. Từ chối thì về ô nhập tay |
| F-57 | Phán quyết | Low | Mới (ngoài phạm vi file này) | CLAUDE.md §4 | CLAUDE.md chỉ có 6 persona, ghi "His & Her", "20-frame", "96%" | Đồng bộ CLAUDE.md sau khi SDS v0.3 được duyệt (việc riêng, không sửa ở đây) |
| F-58 | Phán quyết | Medium | Mới | §6.1, §16 | Persona 5: board chỉ có dark. §0 yêu cầu Light + Dark | Prompt bản light ở §8.2-P5 |

---

## 4. Phát hiện bị loại và lý do

| Nguồn | Nội dung bị loại | Lý do |
|---|---|---|
| A04 (đề xuất) | Đặc tả dữ liệu chung/riêng khi đăng đa hành trình, xem trước từng đích | Không còn đối tượng: R2-10 bỏ hẳn đăng đa hành trình |
| A07 (một phần) | Trạng thái "quota gần đầy/đầy → SCR-60" | Trái R2-04: miễn phí không giới hạn, không bao giờ chặn đăng |
| A10 (đề xuất tạm) | Ẩn chuỗi ở phong cách 8–10 | Bị R2-05 thay thế (nhịp linh hoạt cho mọi mẫu) |
| A12 (một phần) | Ẩn hoặc đổi tên tab Squad khi người dùng chưa có nhóm | Trái R2-02: tab phải luôn là Squad |
| A26 (một phần) | Ba mức giọng (cao/vừa/ấm) | R2-13 chốt hai mức Playful/Gentle, cộng tông ấm cố định cho mẫu nhạy cảm |
| A30 (một phần) | Nhân bản ảnh sang hành trình khác | Trái R2-10 ("một ảnh thuộc một hành trình") |
| B-01 (một phần) | `streakInk ≈ #B45309` | Trùng hex với `warning` nên lẫn ngữ nghĩa "sắp đứt". Thay bằng: số luôn `ink`, icon lửa `#D97706` (§6.4) |
| B-04 (một phần) | Persona 10 dark `≈#4C86F5` | Bị bảng màu mới thay thế (R2-15/16) |
| B-06 (phương án) | Mỗi hành trình có camera trước/sau mặc định | Trái R2-17 |
| B-09 (2 nhận định) | "Tab giữa ở camera persona_6 bị thiếu" · "15 khung trái spec 20" | Sai khi xem board: camera persona_6 có nút chụp ở giữa và đủ nhãn. SDS §6.4-3 ghi "tối đa 20", nên 15 khung không vi phạm. Prompt vẽ lại vẫn dùng 20 khung cho khớp CLAUDE.md |
| B-13 (một phần) | Ẩn nhãn dock ở 1.35× | Trái §2.7 và CLAUDE.md §2 (điều hướng chính luôn có nhãn). Thay bằng: nhãn được xuống 2 dòng, dock cao lên |
| B-22 (một phần) | Áp cho persona 7 | §6.2 ghi Glow Ritual chỉ Solo |
| B-10 (phương án gợi ý) | "Paw teal làm chính" | Không bác về nguyên tắc, nhưng bị bảng đề xuất mới thay thế (§6). Teal không còn chỗ vì cần tách khỏi emerald (1) và xanh trời (8) |

---

## 5. Thay đổi bắt buộc từ quyết định khách hàng (R2-xx → spec)

| R2 | Mục/màn bị ảnh hưởng | Thay đổi phải làm |
|---|---|---|
| **R2-01** Chuỗi chung | D22, §7, CMP-07, CMP-19, SCR-24, SCR-26, SCR-41, SCR-55, NTF-09/10 | §7 thêm: "Hành trình nhóm/cặp đôi có **một chuỗi chung**: ngày (kỳ) được tính khi ≥1 thành viên check-in. Cả nhóm check-in đủ 7 ngày liên tiếp: hành trình +1 freeze." Solo giữ D22. SCR-24 nhóm: khối thống kê hiện chuỗi chung + dòng "Kept alive by 3 of 5 today". SCR-26 freeze: hai bản giải thích (solo / nhóm). SCR-55 nhóm: thêm bảng **thống kê chuỗi từng thành viên**. NTF-10 bản nhóm: "Whole squad 7 days straight = +1 freeze". Giới hạn freeze nhóm và phạm vi solo chờ Q3. Ô thành viên SCR-41 chờ Q4 |
| **R2-02** Squad cố định, Shelf vào Hub | CMP-01, SCR-20, SCR-27, SCR-40, §4.1, §6.5 | CMP-01: phải luôn `Squad`, dock luôn 3 mục. SCR-20 thêm segment trên cùng `Active | Shelf` / `Đang chạy | Trên kệ`. Bỏ khối 6 "On the shelf". SCR-27 trở thành nội dung segment Shelf (giữ bố cục kệ). SCR-40 trạng thái chưa có nhóm thay bằng **trang mời gọi**: minh họa một tường Squad + 3 thẻ lớn `Bring a friend` (→ SCR-21, lọc mẫu cho nhóm, chọn sẵn `With others`) · `Bring your person` (→ SCR-22 mẫu Couple) · `Enter invite code` (→ SCR-43) |
| **R2-03** Mở app | D9, SCR-10, SCR-70, §4.1 | SCR-70 Appearance → thêm `Open app on`: `Today picker` (mặc định) · `Camera` · `Journeys`. SCR-10: đóng sheet mà không chọn thì vào Hub. Đưa `Open my journeys` lên header sheet (cạnh tiêu đề), không để cuối danh sách. Sơ đồ: thêm nhánh cài đặt và dismiss→Hub |
| **R2-04** Lưu trữ miễn phí | D10, SCR-60, SCR-70, CMP-12 | D10 ghi chú: "Miễn phí: không giới hạn ảnh, nén ~1080px. Plus: chất lượng gốc. Không bao giờ chặn đăng." SCR-60: bỏ dòng "More cloud storage…", giữ "Original-quality photos". Màn quản lý gói: bỏ thanh dung lượng. SCR-70 Storage & quality: hiện "Standard (~1080px)" hoặc "Original `[Plus]`" có ổ khóa CMP-14. Clip chờ Q13 |
| **R2-05** Nhịp linh hoạt | D22, SCR-22, SCR-26, CMP-06/07/17, §6.4 (mọi phong cách), §7, NTF-01/02, SCR-10 | SCR-22 thêm mục **Nhịp** ngay sau Thời lượng: `Daily` · `X times a week` (stepper 1–6) · `Weekly` · `Monthly`. Mặc định theo mẫu: Little Milestones Pregnancy = Weekly, Baby = Monthly, còn lại Daily (đây là giá trị gợi ý trong mô tả §6.4-8, khách cần xác nhận ở Q2). SCR-26 sửa được. CMP-17: "Week 6 of 12" khi nhịp tuần. §7 viết lại "chuỗi đếm theo kỳ của nhịp". Cách hiển thị ngày không bắt buộc, freeze theo kỳ, "At risk" chờ Q2 |
| **R2-06** Link nhạy cảm | §2.4, §9.2, SCR-22 mục 7, SCR-26, SCR-50 tab Link, WEB-02 | §2.4 sửa câu cuối: "Dữ liệu nhạy cảm (cân nặng, tiền, ảnh cơ thể) mặc định ẩn khi chia sẻ ra ngoài theo §9.2. Ảnh trẻ em theo D20 (như mọi hành trình)." Thêm **sheet cảnh báo** khi bật link cho Quiet Transformer, Glow Ritual, Little Milestones: tiêu đề "Anyone with the link can see this journey", 3 gạch đầu dòng (ai xem được, ảnh nào hiện, cách tắt), nút `Turn on link` + `Cancel`, giọng ấm. WEB-02: với 3 mẫu này, ảnh trong OG **tự làm mờ** (nhãn "Photos blurred in previews") |
| **R2-07** Tuổi & an toàn trẻ em | SCR-03, SCR-50, SCR-22/26 (link), SCR-72 | SCR-03 thêm `Date of birth` (bộ chọn ngày, giải thích "We use this to keep Ourney safe. Not shown to anyone."). <13: màn chặn ấm "Ourney is for people 13 and up". 13–17: công tắc link công khai ở SCR-22/26/50 **khóa** + chú thích "Public links are for 18+". SCR-72 thêm lý do `Child safety` (đặt lên đầu danh sách khi nội dung thuộc Little Milestones). Chế độ khách: Q6 |
| **R2-08** Widget/thông báo nhạy cảm | §10, §11, SCR-26, SCR-70/71 | Với Quiet Transformer, Glow Ritual, Little Milestones: widget hiện **ảnh mờ** (giữ "Day 12", không hiện số đo), thông báo **không có tên hành trình** ("Time for today's photo ✨"). Thêm công tắc `Show photos on widgets` và `Show journey name in notifications` (mặc định tắt cho 3 mẫu này). Vị trí đặt (từng hành trình hay toàn cục) chờ Q25. §11: widget màn khóa là **đơn sắc**, không dùng token phong cách |
| **R2-09** Vòng đời nhóm | SCR-26, SCR-41, SCR-55, §14 | Theo SRS §3.1. SCR-26 `Leave`: xác nhận "Your photos will be hidden from the group. Rejoin anytime to bring them back." Owner rời: thêm dòng "Ownership passes to {earliest member}". Thêm màn **Members** (danh sách, vai trò, ngày tham gia). SCR-55 `Start season 2`: tạo hành trình mới, thành viên cũ nhận **lời mời** (`Accept` / `Decline`), không tự thêm. Thêm trạng thái lời mời season 2 trong SCR-40. Couple: Q8 |
| **R2-10** Không đăng đa hành trình | SCR-10, SCR-12, §5.8 | Xóa: SCR-10 "Chế độ chọn nhiều…", SCR-12 câu "Bên cạnh có chip `Also post to…`…", §5.8 hàng SCR-12 và cụm "Chế độ chọn nhiều…" ở hàng SCR-10. §2.3: bỏ mọi nhắc tới đăng nhiều đích |
| **R2-11** Hoàn thành một phần | SCR-55, NTF-04 | Biến thể SCR-55 khi chưa đạt mục tiêu: không confetti lớn, số lớn "14 days", câu "14 days is still 14 days 💪" / "14 ngày vẫn là 14 ngày 💪", gợi ý `Start season 2` là thẻ đầu. NTF-04 bản tương ứng. Ngưỡng "một phần" = chưa đạt 100% số kỳ (khớp R2-11, không đặt ngưỡng % riêng) |
| **R2-12** Link mời v1 | §13, SCR-42/43, SCR-04 | Thêm **WEB-04 Trang lời mời**: tên hành trình, người mời (avatar + tên), mã 8 ký tự (chữ lớn + `Copy`), 2 nút store, dòng "Open Ourney and we'll fill in the code". SCR-43: sau khi cài, tự dán mã từ clipboard (+ F-56). SCR-04 `I was invited` → SCR-43 |
| **R2-13** Tông giọng | §3.6, §10, SCR-70 | SCR-70 thêm `Tone`: `Playful` (mặc định) · `Gentle`. §3.6 + §10: mỗi chuỗi có 2 bản. 3 mẫu nhạy cảm luôn dùng bản ấm dù đang chọn Playful |
| **R2-14** Vùng chạm/chữ nhỏ | §2.7, §3.2, CMP-01, CMP-03 | CMP-01: "Viên 56×40 hiển thị, **vùng chạm ≥56×48**". CMP-03: "Cao hiển thị 36–40, vùng chạm ≥48". §3.2: "Caption 13 / Overline 12 **chỉ** cho nhãn phụ (giờ, nhãn ô, đếm ký tự). Không dùng cho nội dung chính". §2.7 thêm câu ngoại lệ vùng chạm vượt hình |
| **R2-15** Bảng màu 4 persona mới | §6.3, Phụ lục A | Thay hàng 7–10 bằng bảng §6.2 [ĐỀ XUẤT, chờ duyệt] |
| **R2-16** Chữ trên nút accent | §3.1, §6.3, CMP-01/02 | Thêm cột `onAccent` + `accentInk` (§6.3) và token shell (§6.4) [ĐỀ XUẤT] |
| **R2-17** Ống kính | §3.4, §6.4-7, SCR-11 | SCR-11: "Đổi hành trình **giữ nguyên ống kính đang dùng**. Người dùng tự lật." §6.4-7: bỏ "Camera trước mặc định", thay bằng "Khi đang dùng camera sau, HUD hiện gợi ý `Use the front camera` / `Dùng camera trước` cạnh nút lật" |
| **R2-18** Font trang trí | §3.2, §6.3 cột Font | Theo §7 [ĐỀ XUẤT]. Thêm quy tắc kiểm "Ệ Ữ Ấ Ẩ Ở Ỹ đ" |
| **R2-19** Vẽ lại board | §6.1, Phụ lục A | §6.1: "Board 1–6 đang được vẽ lại. Trong lúc chờ, **không chép**: nhãn `3-tab`/`...`, lịch 5 cột, His/Her, dock có bánh răng, nút chụp tròn ở màn không phải camera." Phụ lục A thay bằng §8 |
| **R2-20** Không bộ lọc | SCR-11, §6.1, §6.4-3/5 | Thêm câu ở F-53. §6.4-5 `Film Strip`: chỉ là khung/nhãn |
| **R2-21** Chip HUD | §3.1/§6.3, SCR-11 | Thêm `cameraChrome` (§6.4): persona 3, 6 dùng chip sáng, còn lại kính tối. Luôn có viền + bóng |
| **R2-22** Giá Plus | D23, SCR-60 | Giữ giá giữ chỗ (Q22) |

---

## 6. Đề xuất bảng màu — **[ĐỀ XUẤT — chờ khách hàng duyệt]**

Công thức: WCAG 2.x, `L = 0.2126R + 0.7152G + 0.0722B` (kênh đã tuyến tính hóa), tỉ lệ `(L1+0.05)/(L2+0.05)`. Ngưỡng: chữ thường **4.5**, thành phần UI/icon **3.0**. Mọi số dưới đây là kết quả tính, không ước lượng.

### 6.1 Chẩn đoán bảng hiện tại (đã kiểm lại số của B)

| # | Trắng/accent | ink L/accent | accent/bg L (làm chữ) | Ink D (sáng)/accent | bg D/accent | accent/bg D · /surface D |
|---|---|---|---|---|---|---|
| 1 | 2.54 ✗ | 7.04 | 2.26 ✗ | 2.32 | 7.59 | 7.59 · 6.79 |
| 2 | 2.05 ✗ | 8.35 | 1.83 ✗ | 1.96 | 9.02 | 9.02 · 7.97 |
| 3 | **5.02** | 3.25 | 4.39 ✗ | 4.49 | 3.69 | 3.69 ✗ · 3.34 ✗ |
| 4 | 3.53 ✗ | 4.56 | 3.15 ✗ | 3.01 | 5.24 | 5.24 · 4.70 |
| 5 | 3.21 ✗ | 6.15 | 2.92 ✗ | 3.07 | 6.15 | 6.15 · 5.61 |
| 6 | 3.56 ✗ | 4.78 | 3.21 ✗ | 3.24 | 5.42 | 5.42 · 4.98 |
| 7 cũ | 3.09 ✗ | 5.23 | 2.82 ✗ | 2.69 | 6.15 | 6.15 · 5.59 |
| 8 cũ | 3.43 ✗ | 4.49 ✗ | 3.14 ✗ | 2.91 | 5.55 | 5.55 · 5.01 |
| 9 cũ | 2.99 ✗ | 5.27 | 2.81 ✗ | 2.69 | 6.34 | 6.34 · 5.71 |
| 10 cũ | **5.17** | 3.35 | 4.63 | 4.41 | 3.64 | 3.64 ✗ · 3.19 ✗ |

Khoảng cách màu (ΔE76 CIELAB) giữa các accent hiện tại: **9↔2 = 19**, **7↔4 = 20**, 7↔3 = 25, 8↔10 = 32. Đây là các cặp trùng cảm giác mà R2-15 yêu cầu tách.

### 6.2 Bảng màu mới cho 4 persona (7–10)

Bánh xe hue hiện có: 1 emerald 160° · 2 vàng lửa 35° · 3 terracotta 10° · 4 hồng 350° · 5 coral 349° · 6 cam 21°. Bốn phong cách mới được đặt vào các vùng còn trống: **7 orchid 283° · 8 xanh trời 199° · 9 xanh cỏ 89° · 10 cobalt 224°**.

| Persona | Mode | bg | surface | ink | inkMuted | primaryAccent | secondaryAccent (chỉ trang trí) | onAccent | accentInk |
|---|---|---|---|---|---|---|---|---|---|
| **7 Glow Ritual**: "Orchid Glow" | L | `#FBF5FC` | `#FFFFFF` | `#2A1630` | `#6B5872` | `#A13CC9` orchid | `#C9A15A` champagne | `#FFFFFF` | `#8A2DB0` |
| | D | `#130C16` | `#1F1623` | `#F7EEF9` | `#BBA9C1` | `#D08BEE` | `#D9B877` | `#22102B` | `#D08BEE` |
| **8 Little Milestones**: "Sky & Buttercup" | L | `#F1F8FC` | `#FFFFFF` | `#13293A` | `#4E6475` | `#2AA7E0` sky | `#F5C542` buttercup | `#0B2233` | `#0F6E9E` |
| | D | `#0A1319` | `#14212B` | `#EAF4FA` | `#9FB3C2` | `#5CC4F2` | `#F5C542` | `#062030` | `#5CC4F2` |
| **9 Paw Growth**: "Park Green & Biscuit" | L | `#F5F9EC` | `#FFFFFF` | `#1E2612` | `#58634A` | `#6CB021` park green | `#E39B4F` biscuit | `#172206` | `#3F7410` |
| | D | `#0E1209` | `#192012` | `#F1F6E6` | `#AAB59A` | `#8DCB43` | `#E9A866` | `#142004` | `#8DCB43` |
| **10 Blueprint Makeover**: "Cobalt & Safety Amber" | L | `#EEF3F8` | `#FFFFFF` | `#0E1B2C` | `#4A5A6E` | `#1D4ED8` cobalt | `#F59E0B` safety amber | `#FFFFFF` | `#1D4ED8` |
| | D | `#0A121C` | `#13202E` | `#E6EEF7` | `#9DB0C6` | `#6E9BFF` | `#FBBF24` | `#06142B` | `#8DB1FF` |

**Contrast đã tính (mọi cặp chữ ≥ 4.5):**

| Persona · mode | ink/bg | ink/surface | inkMuted/bg | inkMuted/surface | onAccent/accent | accentInk/bg | accentInk/surface | accent/bg (UI, ≥3) |
|---|---|---|---|---|---|---|---|---|
| 7 L | 15.58 | 16.72 | 6.00 | 6.43 | 5.24 | 6.35 | 6.81 | 4.89 |
| 7 D | 16.99 | 15.50 | 8.75 | 7.98 | 7.31 | 7.89 | 7.19 | 7.89 |
| 8 L | 13.92 | 14.94 | 5.75 | 6.17 | 5.97 | 5.23 | 5.61 | 2.54 ⚠ |
| 8 D | 16.80 | 14.68 | 8.66 | 7.57 | 8.46 | 9.49 | 8.29 | 9.49 |
| 9 L | 14.65 | 15.66 | 5.96 | 6.37 | 6.21 | 5.28 | 5.65 | 2.50 ⚠ |
| 9 D | 17.19 | 15.17 | 8.82 | 7.79 | 8.69 | 9.70 | 8.56 | 9.70 |
| 10 L | 15.52 | 17.33 | 6.32 | 7.05 | 6.70 | 6.00 | 6.70 | 6.00 |
| 10 D | 16.07 | 14.08 | 8.47 | 7.43 | 6.82 | 8.84 | 7.75 | 6.98 |

⚠ 8L/9L: accent sáng để giữ độ tươi (nút có chữ `onAccent` ≥5.97 là đạt). Nhưng **đường, viền, vòng, chấm chỉ báo** đứng một mình trên nền sáng phải dùng `accentInk` (≥5.23). `secondaryAccent` light của 7/8/9/10 (2.24 / 1.51 / 2.17 / 1.92) **chỉ dùng trang trí**, không làm chữ hay chỉ báo.

**Độ tách biệt (ΔE76, cặp accent gần nhất):**

| Persona mới | Gần nhất (light) | Gần nhất (dark) |
|---|---|---|
| 7 | 10 = 33 · 4 = 70 (violet phụ của 2 = 25, chỉ là màu phụ) | 10D = 33 · 4 = 56 |
| 8 | 10 = 67 · 1 = 68 | 10D = 39 · 7D = 61 |
| 9 | 1 = 44 · 2 = 72 | 1 = 44 · 2 = 70 |
| 10 | 7 = 33 · 8 = 67 | 7D = 33 · 8D = 39 |

So với bảng cũ (cặp gần nhất 19–20), khoảng cách tối thiểu giữa các màu chính tăng lên **33**. 8 (xanh trời sáng, chữ tối) và 10 (cobalt đậm, chữ trắng) khác nhau rõ về độ sáng dù cùng họ xanh.

### 6.3 `onAccent` và `accentInk` cho 6 persona hiện có (giữ nguyên accent)

| # | primaryAccent (giữ) | onAccent (L và D) | tỉ lệ | accentInk L | /bg · /surface | accentInk D | /bg D · /surface D |
|---|---|---|---|---|---|---|---|
| 1 | `#10B981` | `#0F172A` | 7.04 | `#047857` | 4.90 · 5.48 | `#10B981` | 7.59 · 6.79 |
| 2 | `#FF9F1C` | `#1E1B18` | 8.35 | `#A45A00` | 4.62 · 5.12 | `#FF9F1C` | 9.02 · 7.97 |
| 3 | `#C2452B` | `#FFFFFF` | 5.02 | `#A63A22` | 5.64 · 6.46 | `#E8846C` | 7.02 · 6.36 |
| 4 | `#E15B72` | `#170F12` | 5.34 | `#B42F4B` | 5.43 · 6.09 | `#E15B72` | 5.24 · 4.70 |
| 5 | `#FF4D6D` | `#090A0F` | 6.15 | `#D11A43` | 4.84 · 5.33 | `#FF4D6D` | 6.15 · 5.61 |
| 6 | `#EA580C` | `#111111` | 5.30 | `#B33A0A` | 5.37 · 5.96 | `#EA580C` | 5.42 · 4.98 |

- Không cần chỉnh hex accent nào. Phương án "chữ tối trên accent tươi" giữ được độ tươi mà R2-16 yêu cầu. Phương án thay thế (làm sậm accent để dùng chữ trắng) sẽ làm mất màu thương hiệu, xem Q15.
- `inkMuted` cho 1–6: dùng `inkMuted` của shell (`#5E5E66` / `#A1A1AA`), đạt 5.61–5.84 trên mọi bg sáng 1–6 và 6.39–7.72 trên mọi bg/surface tối 1–6.

### 6.4 Token shell cần sửa

| Token | Hiện tại | Đề xuất | Tỉ lệ sau sửa | Ghi chú |
|---|---|---|---|---|
| `brand` L + chữ trên nút | `#FF3B5C`, trắng 3.48 | **Phương án A:** `brand` L = `#E11D48`, `onBrand` = `#FFFFFF` · **Phương án B:** giữ `#FF3B5C`, `onBrand` L = `#111114` | A: 4.70 · B: 5.41 | Chọn ở Q14. Icon máy ảnh trắng trên `#FF3B5C` (3.48) vẫn đạt mức icon |
| `onBrand` D | trắng 2.98 | `#111114` | 6.33 | |
| `brandInk` L | `#D91C43` (4.42 trên `surfaceSunken`) | `#C81A3E` | 5.05 sunken · 5.47 bg · 5.72 surface | |
| `streak` L (icon) | `#FF9F1C` 1.96 | `#D97706` | 3.05 bg · 3.19 surface | Số chuỗi luôn `ink`. Dark giữ `#FFB547` (11.19) |
| `successInk` L (mới) | (dùng `success` 3.15) | `#15803D` | 4.80 bg · 5.02 surface | `success` `#16A34A` chỉ cho icon/viền (3.15). Chữ trên nền `success`: `#111114` (5.72) |
| `plusGold` L | `#C08A1E` viền 2.91 | viền/icon `#A87A14` | 3.68 | Nền huy hiệu giữ `#C08A1E` + chữ `#111114` (6.19) |
| `plusGoldInk` L (mới) | – | `#8F6410` | 5.02 bg · 5.25 surface | |
| `scrim` L | 45% (trắng/ảnh trắng 3.36) | 60% | 5.74 | |
| `cameraChrome.chipDark` (mới) | – | `#111114` 72% + viền `#FFFFFF` 24% + bóng `0 2 8 rgba(0,0,0,.35)` | chữ trắng ≥7.56 (trường hợp xấu nhất: ảnh trắng) | Persona 1, 2, 4, 5, 7, 8, 9, 10 (R2-21) |
| `cameraChrome.chipLight` (mới) | – | `#FFFFFF` 88% (persona 3: `#F5F2EB` 90%) + viền `#000000` 12% + bóng | chữ `ink` ≥11.70 (trường hợp xấu nhất: ảnh đen) | Persona 3, 6 (R2-21) |

---

## 7. Đề xuất font trang trí — **[ĐỀ XUẤT — chờ khách hàng duyệt]**

Đã kiểm trực tiếp qua Google Fonts CSS API (`fonts.googleapis.com/css2`) ngày 2026-10-22: cả 5 font dưới đây **đều trả về subset `vietnamese`**. Đối chứng: Special Elite và Courier Prime (kiểu máy đánh chữ) **không** có subset vietnamese, nên không dùng.

| # | Font (Google Fonts, OFL) | Kiểu | Dùng cho persona | Cách dùng |
|---|---|---|---|---|
| F1 | **Fraunces** (variable: wght, opsz, SOFT) | Serif tạp chí | 1 Quiet Transformer · 4 Couple Rituals · 7 Glow Ritual | 1: wght 500, SOFT 0 (sắc, kiểu phòng khám). 4: wght 500, SOFT 100 (mềm). 7: wght 300, opsz 144 (thanh mảnh). Ba cách chỉnh trục cho ba cảm giác khác nhau |
| F2 | **Baloo 2** | Rounded sans | 8 Little Milestones · 9 Paw Growth | 8: wght 500–600. 9: wght 800 (đậm, vui) |
| F3 | **Space Mono** | Mono, gần máy đánh chữ | 3 Memory Collectors (tem ngày, tem phim) · 10 Blueprint (số đo, nhãn bản vẽ) | Chỉ cho tem/số, không cho đoạn văn |
| F4 | **Barlow Condensed** | Grotesque hẹp | 5 Aesthetic Flexer (số HUD, km, pace) | wght 600–700. ⚠️ Cần kiểm số tabular (`tnum`) khi dựng. Nếu thiếu thì cố định độ rộng ô số |
| F5 *(tùy chọn)* | **Patrick Hand** | Chữ viết tay | 8 Little Milestones (nhãn sticker, chú thích vẽ tay) | Chỉ nhãn ngắn ≤ 24 ký tự |

- Persona 2 và 6 dùng **Bricolage Grotesque** (đã có trong shell, không tính vào giới hạn). Body mọi persona vẫn là Be Vietnam Pro (§3.2).
- Tổng font thêm: 4 (bắt buộc) + 1 (tùy chọn), nằm trong giới hạn 4–5 của R2-18.
- Quy tắc thêm vào §3.2: mọi font phải qua chuỗi kiểm "**Ệ Ữ Ấ Ẩ Ở Ỹ đ — Bé Na · Đà Lạt · Tuần 24**" ở mọi độ đậm đang dùng, line-height ≥1.3.
- ⚠️ Trước khi đóng gói app, cần xác minh lại bản file tải về (không chỉ CSS API) có đủ glyph tổ hợp dấu.

---

## 8. Prompt vẽ lại board, dark mode và Phụ lục A đã sửa

> Prompt có dùng màu 7–10 hoặc `onAccent` thì phụ thuộc §6 và §7 (chờ duyệt). Nếu khách đổi giá trị, chỉ cần thay hex/font trong khối biến.

### 8.1 Khối chung (dán trước MỌI prompt; thay các biến IN HOA)

```
Create a UI design reference board, 1376×768 landscape, background = BG (solid, subtle paper/noise texture allowed).
Three iPhone 15 Pro mockups side by side, status bar "9:41" on all three, a two-line title above each phone set in DISPLAY_FONT.
If a reference board is attached, use it ONLY for overall composition (three phones, title placement, spacing).
Do NOT copy any of its text, labels, icons, dock, numbers or mistakes.

App shell — identical on every phone:
- Bottom dock with exactly 3 items: left "Journeys" (folded-map line icon + text label), center snap button,
  right "Squad" (two-people line icon + text label). Labels always visible. No other dock items, no settings gear,
  no "3-tab", no "...", no placeholder text anywhere.
- Camera screen: center item is a 76pt round shutter filled ACCENT with a thin white ring.
  Every other screen: center item is a 56×40pt capsule filled ACCENT with a camera line icon in ON_ACCENT.
- Camera screen layout: near-black background; 3:4 viewfinder with 32pt rounded corners; below it a control row:
  photo-library thumbnail (left), shutter (center), flip-camera line icon (right); a small row above with flash,
  3s timer and grid line icons. The live photo is natural and UNFILTERED: no color grading, no film look, no filter.
  Style elements are flat overlay labels on top of the photo only.
- Camera HUD chips: CHIP_STYLE, each with a 1px border and soft shadow so they stay readable on any photo.
- Icons: thin vector line icons only. Never use emoji as icons, bullets, or inside chips/buttons/HUD.
  Emoji may appear only in a reaction bar, next to a streak number as the flame, and in the "Nudge 👋" button.
- Typography: titles in DISPLAY_FONT; all UI text in Be Vietnam Pro (body 16pt, small labels never below 13pt).
- Colors: bg BG, cards SURFACE, main text INK, secondary text INK_MUTED, accent fills ACCENT,
  text/icons on accent ON_ACCENT, colored text ACCENT_INK, decorative only SECONDARY (never text).
- Text: English, spelled correctly, no gibberish, no lorem ipsum. Numbers must be internally consistent across all phones.
- Photos: real, natural smartphone photos (not stock-perfect), no text baked into photos.
- Touch targets ≥ 48pt. No leaderboards, no follower counts, no public feed.
```

`CHIP_STYLE`: persona 3, 6: `light cream/white chips at ~90% opacity with dark text`. Các persona khác: `dark translucent chips (#111114 at 72%) with white text`.

### 8.2 (a) Prompt vẽ lại các board có lỗi (cả 6 đều có lỗi, đã xem trực tiếp)

Ưu tiên vẽ lại: **6, 3, 2, 4** (lỗi placeholder/slop dễ bị chép) → **5** (thiếu light, dock sai) → **1** (lỗi nhẹ).

**P1 Quiet Transformer** (lỗi: nút giữa tròn màu coral ở mọi màn, camera thiếu hàng điều khiển, "DAY 01 ·")
```
[COMMON BLOCK] BG #EFF3F0 · SURFACE #FFFFFF · INK #0F172A · INK_MUTED #5E5E66 · ACCENT #10B981 · ON_ACCENT #0F172A
ACCENT_INK #047857 · SECONDARY #FF4D6D · DISPLAY_FONT Fraunces (weight 500, sharp) · CHIP_STYLE dark translucent.
Mood: calm clinical studio, soft sage-white, thin 1px borders, gentle shadows.
Phone 1 "Ghost-Align Camera": standing woman in sports bra and leggings in a plain room, faint 30% ghost silhouette of
her Day 1 pose (preview overlay only), top chip [lock line icon] "Private Vault · Day 21", floating weight slider card at
the bottom of the viewfinder "62.0 kg  (−3.2 kg)". Full camera control row, round emerald shutter.
Phone 2 "Connected Weight Curve": header "30-DAY BODY ARCHIVE", a weight trend card 65.2 kg → 62.0 kg, below a vertical
emerald line with round nodes: "Day 01 · 65.2 kg", "Day 07 · −0.9 kg", "Day 14 · −2.1 kg", "Day 21 · Today · 62.0 kg",
each with a small thumbnail. Dock center = emerald 56×40 capsule with camera icon in dark ink.
Phone 3 "Side-by-Side Archive": "DAY 01 vs DAY 21" two photos side by side, toggle "Hide exact weight: ON" (the card
then shows only "−3.2 kg"), toggle "Blur body when sharing: ON", primary button "Export Progress Card".
Do not draw any round coral button.
```

**P2 Accountability Squad** (lỗi: `...` trong viên dock, emoji 📖/🏆, viên màu coral, camera thiếu điều khiển)
```
[COMMON BLOCK] BG #F7F1E5 · SURFACE #FFFDF9 · INK #1E1B18 · INK_MUTED #5E5E66 · ACCENT #FF9F1C · ON_ACCENT #1E1B18
ACCENT_INK #A45A00 · SECONDARY #6D4BF0 · DISPLAY_FONT Bricolage Grotesque Bold · CHIP_STYLE dark translucent.
Mood: warm study desk, ink outlines 2px with a 3px bottom lip on cards and buttons.
Phone 1 "Stepping-Stone Quest": cream S-curve path to a vector-illustrated gold trophy (drawn, not emoji) labeled
"Day 30 Goal"; tilted polaroids at "Day 01 · Start", "Day 07 · Week 1", "Day 14 · Week 2", and today's polaroid with
an orange tag "Day 21 · Today" plus flame 🔥. Header chip "IELTS 7.5 Squad · 30 days".
Phone 2 "Study Timer Snap" (camera): open book and coffee by a window at sunrise, top chip [book line icon]
"45 MIN STUDY · 🔥 21 STREAK", time stamp "06:15 AM" at the bottom of the viewfinder, small chip "Start timer",
full control row, round gold shutter.
Phone 3 "Squad Polaroid Wall": progress bar "4/5 checked in today", 2-column polaroid grid: "Linh [check icon] 06:10",
"Nam [check icon] 06:25", "Ha [check icon] 07:00", and a dashed tile "Minh · waiting" with violet button "Nudge 👋".
Dock center on phones 1 and 3 = gold 56×40 capsule with a camera icon (never "..." or any text).
```

**P3 Memory Collectors** (lỗi: `3-tab`, "CAMPFIRE 10GNT", camera không có dock)
```
[COMMON BLOCK] BG #F4EFE6 · SURFACE #FFFFFF · INK #231F1E · INK_MUTED #5E5E66 · ACCENT #C2452B · ON_ACCENT #FFFFFF
ACCENT_INK #A63A22 · SECONDARY #4A6B53 · DISPLAY_FONT Fraunces (titles) + Space Mono (date/film stamps)
CHIP_STYLE light cream chips.
Mood: paper scrapbook, washi tape, film-hole details — as decoration around photos, never as a photo filter.
Phone 1 "Scrapbook Trip Thread": header "Da Lat Trip · 5 days with friends", a stitched terracotta thread linking taped
polaroids: "Day 01 · Pine forest", "Day 02 · Cloud hunting", "Day 03 · Campfire night", "Day 04 · Today · Café";
one stamp "Đà Lạt · 18°C" with a cloud line icon.
Phone 2 "Disposable Film Camera": friends laughing at a café table, natural colors, top cream chip "FILM ROLL 24/36",
amber date-stamp overlay "16 OCT '26 · 15°C · DA LAT" in Space Mono at bottom-right (flat label, the photo itself is
not tinted), full control row, round terracotta shutter, dock labels "Journeys" and "Squad" visible.
Phone 3 "Film Contact Sheet": a dark 35mm contact sheet with exactly 20 numbered frames (4 columns × 5 rows),
title "5 Days of Youth · Da Lat", button "Share Trip Poster".
```

**P4 Couple Rituals** (lỗi: His/Her, `3-tab`, icon Journeys không thống nhất, tiêu đề lệch số)
```
[COMMON BLOCK] BG #F9F0EE · SURFACE #FFFFFF · INK #261F22 · INK_MUTED #5E5E66 · ACCENT #E15B72 · ON_ACCENT #170F12
ACCENT_INK #B42F4B · SECONDARY #9D174D · DISPLAY_FONT Fraunces (soft, weight 500) · CHIP_STYLE dark translucent.
Mood: soft blush paper, paired frames with 24pt corners. Use display names "Minh" and "Lan" — never "his/her".
Phone 1 "Duo Split Timeline": header "Our 30-day home cooking · 🔥 18", rows "Day 18 · Today", "Day 14", "Day 07",
"Day 01 · Start"; each row: Minh's photo (left) · heart node on a vertical line · Lan's photo (right); captions
"Minh · cooked breakfast", "Lan · coffee & toast"; one row has Lan's side as a dashed waiting tile.
Phone 2 "Half-Frame Duo Camera": left half = Minh's photo with label "Minh · 07:30 AM", right half = live viewfinder of
Lan pouring coffee; chip "Snap your half · Complete the pair"; full control row, round rose shutter.
Phone 3 "Couple Mosaic Poster": "18 DAYS TOGETHER · 36 MOMENTS", interleaved 4×4 grid alternating both people's photos
(varied meals, not the same dish), button "Share Our Story".
Board title for phone 3 must also say "18 days" (not 30).
```

**P5 Aesthetic Flexer** (lỗi: chỉ có dark, dock màn 3 sai, 9:16, "Flim", heatmap phân biệt chỉ bằng màu). Vẽ **hai bản**: light và dark.
```
[COMMON BLOCK] LIGHT: BG #F3F4F6 · SURFACE #FFFFFF · INK #090A0F · INK_MUTED #5E5E66
DARK: BG #090A0F · SURFACE #14161F · INK #F8FAFC · INK_MUTED #A1A1AA
ACCENT #FF4D6D · ON_ACCENT #090A0F · ACCENT_INK light #D11A43 / dark #FF4D6D · SECONDARY #3DE88C (dark mode only,
decorative) · DISPLAY_FONT Barlow Condensed SemiBold for numbers · CHIP_STYLE dark translucent.
Mood: athletic telemetry, frosted glass cards with 1px light edge.
Phone 1 "Athletic Telemetry": header "Morning Run Club · Day 21/30", glowing pace sparkline card
"92.4 km total · 5:04 avg pace", vertical run nodes: "Day 01 · 5.0 km", "Day 07 · Milestone", "Day 14 · Milestone",
"Day 21 · Today · 5.42 km".
Phone 2 "Sticker Studio" (camera, after capture): runner at sunset, overlay sticker "DAY 21 · 🔥 21 STREAK /
5.42 KM · 5:04 /KM", segmented chips "Bold HUD" (selected) · "Minimal Stamp" · "Film Strip"; the photo is not filtered.
Phone 3 "Story Sticker Export": 9:16 story preview with the sticker and a 21-bar activity heatmap where active days are
FILLED bars and rest days are HOLLOW outlined bars (same accent color, difference by shape not color),
label "21 days active", button "Share to Instagram Story". Dock: Journeys · capsule · Squad (with labels).
```

**P6 Minimalist Habit** (lỗi: `3 tab`, lịch 5 cột + "FF", số ngày sai, "96%" sai toán)
```
[COMMON BLOCK] BG #F5F3EE · SURFACE #FFFFFF · INK #1C1C1E · INK_MUTED #5E5E66 · ACCENT #EA580C · ON_ACCENT #111111
ACCENT_INK #B33A0A · SECONDARY #27272A · DISPLAY_FONT Bricolage Grotesque Medium · CHIP_STYLE light white chips.
Mood: Braun-like, sharp 1px grid, zero decoration.
Phone 1 "Zero-Text 3-Sec Snap": tea and open book on a wooden table, single chip "Daily Reading · Day 24", full control
row, round orange shutter, dock labels visible.
Phone 2 "Don't Break the Chain": header "October · 24-day streak", a 7-column calendar with headers
Mo Tu We Th Fr Sa Su, dates in correct sequence 1–31 starting on the correct weekday, photo squares for done days joined
by one continuous orange line through consecutive days, the line breaks at a missed day (dashed empty cell), future days
as light empty cells.
Phone 3 "Zen Summary Card": "24/30 DAYS" + a consistency percentage that matches the approved definition (sample:
"24 of 25 days so far · 96%"), one square photo, a small dot grid, button "Export Minimal Card".
```
> Câu mẫu "24 of 25 days so far · 96%" phụ thuộc Q19. Nếu khách định nghĩa khác thì sửa số.

### 8.2 (b) Mẫu prompt **dark mode** cho cả 10 persona

```
[COMMON BLOCK with the DARK values below]
Redraw the attached APPROVED LIGHT board of style "STYLE_NAME" in dark mode.
Keep every layout, text, photo and number identical to the light board; change colors only.
Dark rules: background BG_D, cards SURFACE_D (no drop shadows — separate layers by lighter surfaces and 1px
lines at 8% white), text INK_D / INK_MUTED_D, accent fills ACCENT_D with ON_ACCENT_D text/icons, colored text ACCENT_INK_D.
Keep the accent saturated; do not wash it out. Photos unchanged (no darkening, no filter).
The camera screen is already dark in both modes — keep it as is.
Board background is BG_D with the titles in INK_D.
```

| # | BG_D | SURFACE_D | INK_D | INK_MUTED_D | ACCENT_D | ON_ACCENT_D | ACCENT_INK_D |
|---|---|---|---|---|---|---|---|
| 1 | `#0B0F12` | `#151C21` | `#F1F5F9` | `#A1A1AA` | `#10B981` | `#0F172A` | `#10B981` |
| 2 | `#12131A` | `#1D1F2B` | `#F8FAFC` | `#A1A1AA` | `#FF9F1C` | `#1E1B18` | `#FF9F1C` |
| 3 | `#141312` | `#1F1D1B` | `#F5F2EB` | `#A1A1AA` | `#C2452B` | `#FFFFFF` | `#E8846C` |
| 4 | `#171215` | `#241C21` | `#FCE7F3` | `#A1A1AA` | `#E15B72` | `#170F12` | `#E15B72` |
| 5 | `#090A0F` | `#14161F` | `#F8FAFC` | `#A1A1AA` | `#FF4D6D` | `#090A0F` | `#FF4D6D` |
| 6 | `#0E0E10` | `#18181B` | `#F4F4F5` | `#A1A1AA` | `#EA580C` | `#111111` | `#EA580C` |
| 7 | `#130C16` | `#1F1623` | `#F7EEF9` | `#BBA9C1` | `#D08BEE` | `#22102B` | `#D08BEE` |
| 8 | `#0A1319` | `#14212B` | `#EAF4FA` | `#9FB3C2` | `#5CC4F2` | `#062030` | `#5CC4F2` |
| 9 | `#0E1209` | `#192012` | `#F1F6E6` | `#AAB59A` | `#8DCB43` | `#142004` | `#8DCB43` |
| 10 | `#0A121C` | `#13202E` | `#E6EEF7` | `#9DB0C6` | `#6E9BFF` | `#06142B` | `#8DB1FF` |

(Dòng 1–6 lấy dark từ §6.3 hiện hành, thêm onAccent/accentInk §6.3 mới. Dòng 7–10 là [ĐỀ XUẤT].)

### 8.2 (c) Phụ lục A đã sửa (4 phong cách mới, bản light)

Đã sửa: bỏ "match exactly", dock đúng CMP-01, không emoji làm icon, không bộ lọc (R2-20), Glow giữ ống kính và chỉ gợi ý (R2-17), chip theo R2-21, màu §6.2, font §7.

**A.1 Glow Ritual**
```
[COMMON BLOCK] BG #FBF5FC · SURFACE #FFFFFF · INK #2A1630 · INK_MUTED #6B5872 · ACCENT #A13CC9 · ON_ACCENT #FFFFFF
ACCENT_INK #8A2DB0 · SECONDARY #C9A15A · DISPLAY_FONT Fraunces Light (weight 300, high optical size)
CHIP_STYLE dark translucent.
Mood: early-morning bathroom light, dewy skin, premium clean-beauty brand; large 24pt corners, very soft light gradients
on UI surfaces only (never on photos).
Phone 1 "Face-Align Ring Camera": front-camera view of a young woman's bare, unretouched face in soft window light;
a dashed oval face guide; a faint 30% ghost of her Day 1 face (preview overlay only); chips [lock line icon]
"Private · Day 28" and [sun line icon] "Light: matches Day 1" [check line icon]; a small hint chip next to the flip
button "Tip: use the front camera" shown as a dismissible tip; full control row; round orchid shutter.
Phone 2 "Glow Strip Timeline": header "60-Day Skin Reset"; a vertical strip of face photos: large weekly slices
(Week 1, Week 2, Week 4) with small daily thumbnails between them; next to each photo a small light-condition dot
WITH a text label ("Same light", "A bit dark", "Too bright"); product chips "Retinol", "SPF 50".
Phone 3 "Before / After Glow Slider": header "Editorial Split"; one face photo split by a draggable vertical handle
(Day 01 left, Day 60 right); toggle "Blur background: ON"; primary button "Export Glow Card" (orchid, white text).
```

**A.2 Little Milestones**
```
[COMMON BLOCK] BG #F1F8FC · SURFACE #FFFFFF · INK #13293A · INK_MUTED #4E6475 · ACCENT #2AA7E0 · ON_ACCENT #0B2233
ACCENT_INK #0F6E9E (use for all lines, rings and dots) · SECONDARY #F5C542 (decor only) · DISPLAY_FONT Baloo 2
SemiBold; short hand-drawn labels in Patrick Hand · CHIP_STYLE dark translucent.
Mood: a paper baby album, sky blue and buttercup, hand-drawn strokes, polka dots, 24pt corners, warm and gentle.
Phone 1 "Milestone Frame Camera": pregnant belly in soft window light, faint ghost of last week's photo (overlay only),
large badge "Week 24" top-left, chip "Size of an ear of corn" (text only), chip [plus icon] "Milestone", full control
row, round sky-blue shutter.
Phone 2 "Month Bubbles Timeline": header "Baby's First Year"; big round photo bubbles of a baby growing (Month 1, 2, 3
… current Month 6 with a static highlighted ring), each with a large month number, connected by a dotted line;
small stickers "First smile", "First steps".
Phone 3 "Monthly Milestone Card": share card with a huge "6" and "MONTHS", round baby photo, "68 cm · 7.4 kg",
baby name "Bé Na", toggle "Cover face with sticker", button "Share Card".
```

**A.3 Paw Growth**
```
[COMMON BLOCK] BG #F5F9EC · SURFACE #FFFFFF · INK #1E2612 · INK_MUTED #58634A · ACCENT #6CB021 · ON_ACCENT #172206
ACCENT_INK #3F7410 (use for ruler ticks, lines, rings) · SECONDARY #E39B4F biscuit (decor only)
DISPLAY_FONT Baloo 2 ExtraBold · CHIP_STYLE dark translucent.
Mood: playful park day, thick 2px rounded outlines, paw-print motifs, biscuit accents.
Phone 1 "Same-Spot Squeak Camera": corgi puppy on the same rug, faint ghost of the previous photo (overlay only),
a round 48pt button [speaker line icon] "Squeak" beside the shutter, chip "Mochi · 4 months", full control row,
round green shutter.
Phone 2 "Growth Ruler Timeline": header "Mochi Growing Up"; a vertical ruler with tick marks by week; puppy photos
attached along the ruler getting bigger; weight labels "2.1 kg", "4.8 kg", "7.9 kg"; a paw-print trail linking
consecutive check-ins.
Phone 3 "Growth Flipbook Card": stacked flipbook pages from tiny puppy to now, text
"WATCH ME GROW · 8 WEEKS → 6 MONTHS", button "Make Video".
```

**A.4 Blueprint Makeover**
```
[COMMON BLOCK] BG #EEF3F8 · SURFACE #FFFFFF · INK #0E1B2C · INK_MUTED #4A5A6E · ACCENT #1D4ED8 · ON_ACCENT #FFFFFF
ACCENT_INK #1D4ED8 · SECONDARY #F59E0B safety amber (decor only) · DISPLAY_FONT Space Mono for numbers and labels,
Bricolage Grotesque for titles · CHIP_STYLE dark translucent.
Mood: technical blueprint paper, faint grid on backgrounds, dashed dimension lines, organized and calm.
Phone 1 "Grid-Align Blueprint Camera": half-renovated kitchen, technical grid overlay and faint ghost of the "Before"
photo (overlays only), chip at top "Kitchen" [chevron-down icon] plus chip [plus icon] "New area", chip "Day 23",
full control row, round cobalt shutter.
Phone 2 "Progress Board": header "Our Apartment Makeover", summary row "62% · Day 23 · Spent: hidden [eye-off icon]",
area cards (Kitchen 80%, Bedroom 45%, Balcony 20%) each with a small Before photo, latest photo and progress bar,
a dashed card [plus icon] "Add area".
Phone 3 "Before / After Drag Slider": one room photo split by a vertical drag handle (BEFORE left, AFTER right),
label "Kitchen · 23 days", toggle "Hide cost: ON", button "Export Makeover Card".
```

---

## 9. Danh sách thay đổi theo thứ tự ưu tiên cho SDS v0.3

**P0: bắt buộc trước khi đưa cho AI**

| # | Vị trí | Thay đổi chính xác |
|---|---|---|
| 1 | Header | "Phiên bản 0.3 (áp quyết định vòng 2 R2-01…R2-22)" |
| 2 | §1.5 | Thêm bảng "Quyết định vòng 2" với R2-01…R2-22 (tóm tắt 1 dòng mỗi mục như §5 của tài liệu này) |
| 3 | §15 | Thêm khối "Vòng 2 (2026-10-22)". "Còn mở" = D23 + các câu ở §10 |
| 4 | §2.3, §8.1 | Viết lại cam kết chạm theo F-05. Bỏ nhắc tới đăng đa hành trình |
| 5 | §2.4 | Sửa câu dữ liệu nhạy cảm theo R2-06 (§5) |
| 6 | §2.7, §3.2 | Thêm ngoại lệ vùng chạm và giới hạn Caption/Overline (R2-14) |
| 7 | §2.8 | Viết lại quy tắc emoji (F-04) |
| 8 | §3.1 | Thêm token `onBrand`, `successInk`, `plusGoldInk`, sửa `brandInk` L, `streak` L, `plusGold` L (viền), `scrim` L 60%, nhóm `cameraChrome` (§6.4). Sửa ghi chú AA. Phương án `brand` theo Q14 |
| 9 | §6.3 | Thay bảng bằng bảng đủ cột: bg/surface/ink/inkMuted/primaryAccent/secondaryAccent/onAccent/accentInk × L/D cho 10 persona (§6.2, §6.3). Ghi "secondaryAccent chỉ trang trí". Xóa câu "designer kiểm lại contrast, được chỉnh sắc độ" |
| 10 | §6.3 cột Font, §3.2 | Điền tên font §7 + chuỗi kiểm dấu |
| 11 | CMP-01 | Phải luôn `Squad`. Viên 56×40 vùng chạm ≥56×48. Màu viên = `primaryAccent`, icon = `onAccent`. Dock cao ≥64 + safe area, nhãn tối đa 2 dòng ở 1.35× |
| 12 | CMP-03 | Vùng chạm ≥48 |
| 13 | CMP-19, CMP-07, §6.4-1/2/10, SCR-13/41 | Thay ký tự/emoji bằng "icon … (vector)" theo F-04 |
| 14 | SCR-10 | Xóa chế độ chọn nhiều. `Skip today` → `Hide for today` + phụ đề. `Open my journeys` lên header. Dismiss → Hub. Mốc "At risk" chờ Q1 |
| 15 | SCR-11 | Thêm: không bộ lọc (F-53), giữ ống kính (R2-17), chip `cameraChrome` (R2-21), chỉ báo hành trình đích khi vuốt (F-18), sheet gộp ảnh thư viện theo ngày (F-24) |
| 16 | SCR-12 | Xóa `Also post to…`. Header hiện tên hành trình + nhãn riêng tư cạnh `Post` |
| 17 | SCR-13 + §5.8 | Thống nhất một cơ chế sau khi đăng (Q5). Xóa hàng SCR-12 ở §5.8, sửa hàng SCR-10 |
| 18 | SCR-20 | Segment `Active | Shelf`. Bỏ khối "On the shelf". `Import` vào menu `+`. `Sort & filter` gập khi ≤6. Bỏ chip `Squad`/`Couple` khỏi bộ lọc. Icon kiểu xem `Map` = ghim |
| 19 | SCR-27 | Đổi thành "Nội dung segment Shelf của SCR-20". Giữ bố cục kệ |
| 20 | SCR-40 | Trạng thái chưa có nhóm = trang mời gọi 3 thẻ (R2-02). Thêm thẻ lời mời season 2 |
| 21 | SCR-22 | Chế độ nhanh + `More options`. Mục Nhịp (R2-05). `With others`. Dòng "Style can't be changed later". Khóa link cho người dưới 18. Sheet cảnh báo link cho 3 mẫu nhạy cảm |
| 22 | SCR-26 | Nhịp. Link (cảnh báo, khóa dưới 18). Members + chuyển quyền. Xác nhận Leave (R2-09). `Delete journey` chỉ khi còn mỗi owner (F-55). Freeze 2 bản solo/nhóm (R2-01). Công tắc widget/thông báo (R2-08) |
| 23 | SCR-03 | Ngày sinh + màn chặn dưới 13 (R2-07). Chế độ khách theo Q6 |
| 24 | SCR-50, WEB-02 | Tab Link: sheet cảnh báo, khóa dưới 18. OG mờ cho 3 mẫu nhạy cảm (R2-06) |
| 25 | SCR-55 | Biến thể hoàn thành một phần (R2-11). Season 2 = lời mời (R2-09). Thống kê chuỗi từng thành viên (R2-01) |
| 26 | SCR-60, SCR-70 | Theo R2-04. SCR-70 thêm `Open app on`, `Tone`, quyền riêng tư widget/thông báo |
| 27 | SCR-72 | Thêm lý do `Child safety` |
| 28 | §6.4-7 | Bỏ "Camera trước mặc định", thay bằng gợi ý (R2-17) |
| 29 | §7, CMP-06/07/17, D22 | Viết lại quy tắc chuỗi theo R2-01, R2-05 + câu trả lời Q1–Q4 |
| 30 | §10, §11 | Bản `Gentle` (R2-13). Bản nhạy cảm không có tên hành trình (R2-08). Sửa "Hết cứu…". Widget mờ + ghi chú widget màn khóa đơn sắc |
| 31 | §13 | Thêm WEB-04 (R2-12) |
| 32 | §6.1 + Phụ lục A | Danh sách "không chép" từ board cũ. Thay Phụ lục A bằng §8 của tài liệu này (sau khi duyệt màu/font) |

**P1: nên làm trong v0.3**

| # | Vị trí | Thay đổi |
|---|---|---|
| 33 | SCR-25 (+ SCR-25a mới) | Sửa check-in, lưới/chọn nhiều, xóa hàng loạt, hộp thoại xóa (F-10) |
| 34 | CMP-12, §14 | Sheet Upload queue, lỗi vĩnh viễn, bộ nhớ máy đầy (F-11) |
| 35 | §14 + bảng mới | Lịch xin 4 quyền (F-26). Luồng nâng cấp từ chế độ khách (Q7) |
| 36 | SCR-41 | Ô thành viên theo Q4. Nudge `[v2]` "Coming soon" (F-27) |
| 37 | CMP-10, §8.4 | Quy tắc sticker trên ảnh (F-38) |
| 38 | §3.4 | Giới hạn nhấp nháy/lặp + Reduce Motion (F-39) |
| 39 | §6.4, §8.4 | Ghost overlay không lưu vào ảnh. Chỉ số ẩn không thành sticker (F-44) |
| 40 | §12 | Bảng breakpoint tablet (F-45) |
| 41 | SCR-22 (persona 1) | Dòng nhắc riêng tư khi chọn nhóm (F-43) |
| 42 | Phụ lục C mới | Bộ dữ liệu mẫu chung (F-30) |
| 43 | §4.1 | Cập nhật sơ đồ (F-31) |
| 44 | SCR-43 | Trạng thái quyền dán của iOS (F-56) |

**P2: hoàn thiện**

| # | Vị trí | Thay đổi |
|---|---|---|
| 45 | Phụ lục B mới | Bảng chuỗi EN/VI + test độ dài 1.35× (F-29) |
| 46 | §11, §13 | Cỡ và trạng thái widget/web (F-46) |
| 47 | SCR-28 | Tiến độ nhập, ảnh trùng (F-33) |
| 48 | §4.2 | NTF-01…10 (F-54) |
| 49 | §6.4-6 | Số liệu Zen khớp định nghĩa Q19 (F-49) |
| 50 | §1.4 | Ghi rủi ro Squad v1 không có push (F-27) |
| 51 | Ngoài SDS | Đồng bộ CLAUDE.md §4 (10 persona, bỏ His/Her, số liệu mẫu) sau khi duyệt (F-57) |

---

## 10. Câu hỏi còn mở cho khách hàng (đã trả lời — xem §11)

1. **Q1: Mốc cảnh báo chuỗi và ranh giới "ngày"** (F-09). (a) Mốc cảnh báo: 20:00 · 21:00 · người dùng tự chọn (mặc định 21:00)? (b) Một "ngày" kết thúc lúc: 00:00 giờ máy · 03:00 sáng hôm sau (cho người thức khuya)? (c) Khi đi du lịch đổi múi giờ: theo giờ máy hiện tại · theo múi giờ lúc tạo hành trình?
2. **Q2: Nhịp linh hoạt × chuỗi** (F-14, F-50). Với nhịp `X lần/tuần`, `Weekly`, `Monthly`: (a) chuỗi đếm theo **kỳ** (tuần/tháng đạt chỉ tiêu) hay theo số lần? (b) Freeze tự dùng khi lỡ **một kỳ** hay vẫn theo ngày? (c) Ngày không bắt buộc hiển thị ra sao trên lịch và trên "Don't break the chain": ô trung tính (không tính lỡ) · ẩn khỏi lịch · đổi sang lưới tuần? (d) Xác nhận nhịp mặc định theo mẫu: Pregnancy = Weekly, Baby = Monthly, còn lại = Daily?
3. **Q3: Phạm vi freeze** (F-09). (a) Solo: 2 lượt/tháng là **một quỹ chung cho người dùng** · **mỗi hành trình** 2 lượt? (b) Hành trình nhóm có thêm 2 lượt/tháng như solo không, hay chỉ có lượt thưởng 7 ngày của R2-01? (c) Giới hạn tối đa 3 lượt thưởng có áp cho nhóm không? (d) Lỡ nhiều ngày liên tiếp: dùng nhiều lượt liên tiếp · chỉ cứu ngày đầu?
4. **Q4: Hiển thị chuỗi trong nhóm khi đang chạy** (F-52). Ô thành viên trên SCR-41 hiện: chỉ ✓ + giờ (chuỗi cá nhân chỉ ở thống kê cuối, theo R2-01) · vẫn hiện chuỗi cá nhân nhỏ (theo SRS FR-D3)?
5. **Q5: Sau khi đăng** (F-07). (a) Bỏ tự chuyển, hiện nút `Next: {journey}` + `Done` · (b) tự chuyển sau đếm ngược 3s có nút `Stay` · (c) giữ 1.5s như hiện tại?
6. **Q6: Cổng tuổi với chế độ không tài khoản** (F-51). (a) Hỏi ngày sinh ngay lần mở đầu cho mọi người · (b) chỉ hỏi khi đăng ký (khách vốn không có link công khai nên không cần) · (c) bỏ chế độ khách?
7. **Q7: Nâng cấp từ chế độ khách** (F-26). Khi đăng nhập sau này: chuyển toàn bộ hành trình trên máy lên tài khoản · cho chọn hành trình nào chuyển · bắt đầu mới?
8. **Q8: Couple khi một người rời** (F-13). (a) Hành trình lưu trữ (chỉ đọc) · (b) tiếp tục như hành trình solo của người còn lại · (c) giữ chỗ chờ người kia quay lại hoặc mời người mới?
9. **Q9: "Hide until they post" với ngày cũ** (F-21). Chỉ che ảnh **hôm nay** · che mọi ngày mà người xem chưa check-in ngày đó?
10. **Q10: Hành trình đã kết thúc** (F-25). Có cho gia hạn hoặc mở lại không, hay chỉ `Start season 2`? (Cài đặt "gia hạn" ở SCR-26 chỉ áp khi chưa kết thúc?)
11. **Q11: Xóa ảnh duy nhất của một ngày** (F-10). Chuỗi của ngày đó: bị trừ (ngày thành lỡ, có thể tiêu freeze) · vẫn giữ?
12. **Q12: Link công khai** (F-20). (a) Trang link có `noindex` (không lên Google) cho mọi hành trình · chỉ mẫu nhạy cảm · không? (b) Công tắc `Allow share link` mặc định: tắt · bật?
13. **Q13: Clip với R2-04**. Clip của gói miễn phí cũng nén (ví dụ 720p/1080p) · giữ gốc như ảnh Plus?
14. **Q14: Màu `brand` sáng** (F-01, §6.4). Phương án A `#E11D48` + chữ trắng (4.70) · Phương án B giữ `#FF3B5C` + chữ `#111114` (5.41)?
15. **Q15: Chữ trên accent cho persona 1–6** (§6.3). Duyệt phương án chữ tối trên accent giữ nguyên hex · hay muốn làm sậm accent để dùng chữ trắng (màu sẽ kém tươi)?
16. **Q16: Duyệt bảng màu 7–10** (§6.2): Orchid Glow · Sky & Buttercup · Park Green & Biscuit · Cobalt & Safety Amber. Duyệt nguyên trạng · muốn đổi persona nào?
17. **Q17: Duyệt font** (§7): Fraunces, Baloo 2, Space Mono, Barlow Condensed (+ Patrick Hand tùy chọn). Duyệt · bỏ Patrick Hand · đổi font nào?
18. **Q18: Bố cục timeline 7 và 9** (F-36). (a) Giữ trục dọc, khác biệt bằng trang trí (như spec) · (b) Glow đổi sang lưới tuần 7 ô + cặp before/after ghim trên đầu · (c) Paw đổi sang thước ngang cuộn · (d) cả b và c?
19. **Q19: "Consistency" trên thiệp Zen** (F-49). (a) số ngày xong / số ngày đã qua · (b) số ngày xong / tổng số ngày mục tiêu (24/30 = 80%) · (c) bỏ % chỉ giữ "24/30"?
20. **Q20: Viên chụp ở dock khi mọi hành trình đã xong hôm nay** (F-16). (a) Mở camera của hành trình dùng gần nhất (`Add more`) · (b) mở SCR-10 với trạng thái "All done" + danh sách để chụp thêm · (c) mở Hub?
21. **Q21: Tạo nhanh** (F-17). Thời lượng mặc định khi người dùng bấm `Start journey` ngay: theo gợi ý của mẫu · 30 ngày · `No end date`?
22. **Q22: Giá Ourney Plus** (R2-22/D23). Vẫn mở, giữ giá giữ chỗ.
23. **Q23: Chuyển ảnh sang hành trình khác** (F-32). Cho phép **chuyển** (không phải nhân bản) một ảnh đăng nhầm · không cho?
24. **Q24: Phạm vi tông giọng** (R2-13). `Playful/Gentle` áp cho: chỉ thông báo · mọi chữ trong app (màn đã đăng, kết thúc, trạng thái rỗng)?
25. **Q25: Vị trí công tắc riêng tư widget/thông báo** (R2-08). Từng hành trình (SCR-26) · toàn cục (SCR-70/71) · cả hai?


---

## 11. Câu trả lời của khách hàng cho §10 (2026-10-22, có hiệu lực ràng buộc)

> Mục này **ghi đè** mọi đề xuất hoặc phương án ở §3–§9 nếu mâu thuẫn. Khi soạn SDS v0.3, áp dụng các câu trả lời dưới đây cùng R2-01…R2-22.

| Câu | Quyết định của khách hàng |
|---|---|
| Q1 | Giờ cảnh báo chuỗi sắp đứt do **người dùng tự chọn** (mặc định 21:00). Một ngày kết thúc lúc **00:00**. Múi giờ tính theo **giờ hiện tại của điện thoại** (đi du lịch thì theo giờ nơi đang ở) |
| Q2 | Chuỗi đếm **theo kỳ** của nhịp (ví dụ "🔥 5 tuần đạt 3/3"). Lịch **theo đơn vị của nhịp**: hằng ngày và X lần/tuần dùng lưới ngày (X lần/tuần có dấu "2/3 ✓" cuối mỗi hàng tuần, ngày không bắt buộc là ô xám trơn, không tính lỡ); hằng tuần dùng lưới tuần; hằng tháng dùng lưới tháng. Có nút đổi Ngày/Tuần/Tháng ở kiểu xem Calendar. Freeze cứu một kỳ bị lỡ. Mặc định: Mang thai = hằng tuần, Em bé = hằng tháng, còn lại = hằng ngày |
| Q3 | **Solo:** quỹ freeze chung của người dùng (2 lượt/tháng, Plus 5; +1 lượt thưởng cho mỗi 7 ngày liên tiếp, giữ tối đa 3 lượt thưởng). **Nhóm/cặp đôi:** quỹ riêng của hành trình, chỉ kiếm được khi cả nhóm đủ mặt 7 ngày liền, giữ tối đa 3. Lỡ nhiều ngày liền thì dùng liên tiếp đến khi hết. Cùng ngày lỡ nhiều hành trình thì **ưu tiên chuỗi dài nhất**. Mỗi lần dùng đều có thông báo |
| Q4 | Ô thành viên trên SCR-41 **hiện chuỗi cá nhân nhỏ** (✓ + giờ + 🔥 n). Chuỗi chung của nhóm nằm trên cùng |
| Q5 | SCR-13: **không tự chuyển màn**. Hiện nút `Next: {journey}` và `Done` |
| Q6 | **Bỏ chế độ khách.** Bắt buộc đăng nhập. Cổng tuổi (ngày sinh) ở bước đăng ký. Bỏ link `Try without an account` ở SCR-02 và mọi trạng thái "chế độ không tài khoản" (SCR-40…) |
| Q7 | Không còn áp dụng (đã bỏ chế độ khách) |
| Q8 | Cặp đôi có một người rời: **giữ chỗ**. Người còn lại vẫn chụp nửa của mình (nửa kia hiện ô chờ), có thể mời người kia quay lại |
| Q9 | "Hide until they post" che ảnh ở **mọi ngày** mà người xem không check-in ngày đó, không chỉ hôm nay |
| Q10 | Hành trình đã kết thúc được **mở lại hoặc gia hạn trong 7 ngày**. Sau 7 ngày chỉ còn `Start season 2`. SCR-55 và banner của SCR-24 thêm nút `Reopen` (đếm ngược số ngày còn lại) |
| Q11 | Xóa tấm ảnh duy nhất của một ngày: **vẫn giữ chuỗi** của ngày đó (không cần hộp cảnh báo về chuỗi) |
| Q12 | Trang link công khai **không lên Google** (`noindex`) với mọi hành trình. Công tắc `Allow share link` **mặc định tắt** |
| Q13 | Clip gói miễn phí nén **1080p**, Plus giữ chất lượng gốc |
| Q14–Q16 | **Màu sắc để Figma Make (AI) đề xuất sau.** Bảng màu ở §6 giữ làm điểm xuất phát và ràng buộc kỹ thuật (mọi cặp chữ/nền ≥ 4.5:1, có token `onAccent` và `accentInk`, 4 phong cách mới phải khác tông rõ với nhau và với 6 phong cách cũ), **chưa phải màu chốt**. Prompt ở §8 dùng các mã màu này như gợi ý, không bắt buộc |
| Q17 | **Duyệt cả 5 font:** Fraunces, Baloo 2, Space Mono, Barlow Condensed, Patrick Hand (theo bảng §7) |
| Q18 | **Đổi cả hai:** Glow Ritual dùng **lưới tuần 7 ô + cặp ảnh trước/sau ghim trên đầu**. Paw Growth dùng **thước đo nằm ngang, cuộn trái–phải** |
| Q19 | % trên thiệp Zen = số ngày xong / **tổng số ngày mục tiêu** (24/30 = 80%) |
| Q20 | Đã xong hết hôm nay mà bấm nút chụp ở dock: mở **SCR-10 với trạng thái "All done 🎉"** + danh sách hành trình để chụp thêm |
| Q21 | Bấm `Start journey` ngay: thời lượng **theo gợi ý của mẫu** (ví dụ Chuyến đi 7 ngày, Giảm cân 30 ngày, Em bé 12 tháng, Sửa nhà không có ngày kết thúc) |
| Q22 | Giá Ourney Plus **vẫn mở**, giữ giá giữ chỗ |
| Q23 | **Không cho chuyển** ảnh sang hành trình khác. Đăng nhầm thì xóa và đăng lại |
| Q24 | Cài đặt `Playful / Gentle` **chỉ áp cho thông báo**. Chữ trong app dùng một giọng (§3.6) |
| Q25 | Công tắc ẩn ảnh/tên trên màn khóa và widget có **ở cả hai nơi**: mặc định toàn cục trong Cài đặt (SCR-70/71), mỗi hành trình ghi đè được trong SCR-26 |

**Còn mở duy nhất:** giá Ourney Plus (Q22).

---

## Phụ lục — Quyết định khách hàng vòng 2 (R2-01…R2-22)

> Nguyên văn bảng quyết định đã đưa cho người phán quyết. R2-15, R2-16 (màu) sau đó được thay bằng Q14–Q16 ở §11: để Figma Make đề xuất.


| ID | Topic | Client decision |
|---|---|---|
| R2-01 | Streak model in group/couple [A05/A16] | Streak is **shared per journey**: the journey's streak survives as long as at least 1 member checks in that day. At journey end, show per-member streak statistics. If **the whole group checks in 7 consecutive days**, the journey earns **+1 freeze**. Solo journeys keep D22 (2/month, Plus 5/month, +1 per 7-day streak, max 3 bonus). |
| R2-02 | Right dock tab [A12] | Right tab is **always Squad** (stable navigation). With no groups, Squad is an inviting landing page: 3 big cards "Bring a friend" · "Bring your person (Couple)" · "Enter invite code" + illustration of a squad wall. **Shelf lives in Hub** as top segment `Active | Shelf`. Dock always 3 items. |
| R2-03 | App open screen [A02] | Default per D9, plus a **setting**: open on Today picker (default) / camera / Hub. Dismissing the Today sheet without choosing → Hub. |
| R2-04 | Free storage [A07] | **Unlimited photos for free** at compressed quality (~1080px). Plus = original quality. Never block posting. |
| R2-05 | Check-in cadence [A10] | **Flexible cadence for ALL templates**, chosen when creating a journey (editable): daily / X times per week / weekly / monthly. Streak counts by that cadence. Must be flexible. |
| R2-06 | Public link for sensitive journeys [A17/B-20] | Keep D20 (same rules as all journeys) **+ a warning sheet when enabling the link** for baby/weight/glow-up, and the link's OG preview image is **auto-blurred**. |
| R2-07 | Age gate & child safety [B-21] | Add both in v1: **date of birth at sign-up** (13+; under 18 restricted from public links) and report reason **"Child safety"**. |
| R2-08 | Lock screen/widgets [B-19] | For sensitive templates (weight loss, glow-up, baby): widgets show **blurred photo**, notifications **omit the journey name**. User can re-enable in settings. |
| R2-09 | Group lifecycle [A09/A23] | Follow SRS: owner leaves → ownership to earliest member; leaver's photos hidden (re-shown on rejoin). **Season 2 sends invitations**, members must accept. |
| R2-10 | Multi-journey posting [A04] | **NOT allowed.** One photo belongs to one journey ("each journey is different"). Remove SCR-10 multi-select "Snap for N journeys", SCR-12 "Also post to…", and related §5.8 rows. |
| R2-11 | Partial completion [A23] | Still celebrate, **different tone** (acknowledge effort, e.g. "14 days is still 14 days 💪"), no big confetti, suggest season 2. |
| R2-12 | Invite link in v1 [A08] | Link opens a **small web invite page**: journey name, inviter, 8-char code, download buttons. After install, app auto-pastes code from clipboard. |
| R2-13 | Tone choice [A26] | Setting: **Playful (default) / Gentle**. Sensitive templates always use the warm tone. |
| R2-14 | Small targets/text [A19] | Pill shutter **looks 56×40 but hit area is ≥ 56×48**. 12–13pt text only for secondary labels (timestamps etc.), never for main content. |
| R2-15 | Palette overlap [B-10/11] | **Change tones so the 4 new personas are clearly distinct** (from each other and from the 6 existing). Judge proposes hex values; client approves later. |
| R2-16 | Text on accent buttons [B-02/03] | Client asks: **research and propose the most suitable colors** (keep vivid, reach WCAG AA, distinct). Judge proposes concrete hex + `onAccent` + computed ratios; client approves. |
| R2-17 | Front/back lens on journey switch [B-06] | **Keep current lens**; user flips manually. Glow Ritual only shows a hint "Use the front camera". |
| R2-18 | Decorative fonts [B-12] | Allowed: **max 4–5 extra fonts, all with full Vietnamese diacritics support**, shared across personas. |
| R2-19 | Faulty old boards [B-09] | **Redraw with AI.** Judge writes prompts to redraw faulty boards, plus **dark-mode prompts for all 10 personas**. |
| R2-20 | Camera filters | **No camera filters at all.** Plain camera. Persona camera "looks" (film, etc.) are only overlay labels, never color-grading the photo. |
| R2-21 | HUD chips on camera [B-17] | **Per persona**: film/minimalist styles may use light chips, others dark translucent; always with border/shadow for legibility on any photo. |
| R2-22 | Price of Plus | Still open (D23). |
