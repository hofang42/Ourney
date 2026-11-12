# Ourney V2: Đặc tả thiết kế lại UI/UX

> Trạng thái: bản đặc tả, chưa vẽ trên Figma. Bộ prompt dùng cho Figma Make nằm trong [figma-make-prompts.md](figma-make-prompts.md); prompt bàn giao sang session local nằm trong [HANDOFF.md](HANDOFF.md).
> File Figma đích: `Ourney-V2` (https://www.figma.com/design/nyvBJzr7XYlg7ZzhsJGoZx/Ourney-V2). Bản V1 bị chê, không dùng lại: https://www.figma.com/make/z3B1WO8e7SUNG83jvaPotn/Ourney-V1.0

## 0. Vấn đề của V1 và mục tiêu của V2

**V1:** mọi hành trình đi qua cùng một form dài (tiêu đề, emoji, solo/nhóm, thời lượng, metric, hiển thị, múi giờ). Vào hành trình nào cũng là cùng một lưới lịch. Skin chỉ đổi màu, nên hành trình không có cá tính.

**V2 có 3 nguyên tắc:**
1. **Tạo hành trình là "đúc" ra một hành trình.** Mỗi loại hành trình có câu hỏi riêng. Câu trả lời sinh ra *Journey DNA* (ảnh bìa, motif, màu nhấn, tên các mốc, giọng văn, kiểu camera). Kết thúc luồng tạo là một **tấm vé khởi hành** riêng của hành trình đó.
2. **Mỗi hành trình là một thế giới riêng.** Bước vào hành trình là đổi hẳn chất liệu: sổ dán ảnh, đường chạy neon, con đường quest… Không còn một lưới lịch dùng chung.
3. **Vỏ chung neo-brutalism.** Hub, tạo hành trình, onboarding, hồ sơ và Hội dùng chung ngôn ngữ "Soft Neo-Brutalism" (nền kem, viền mực 2px, bóng cứng). Khi vào hành trình, phần "xương" neo-brutalism vẫn còn (dock, nút chính, chip), còn "da" là của persona.

## 1. Kiến trúc điều hướng V2

Mình giữ vòng lặp camera-first (≤ 3 chạm để check-in), nhưng làm lại thành **floating dock** cho hiện đại hơn:

Cập nhật 2026-11-11 (`feedback-2026-11-11.md`, `CLAUDE.md` §2): dock **5 tab**, thay cho dock 3 mục của bản đầu (bản đầu còn trong `figma-make-prompts.md` để làm lịch sử).

```
┌────────────────────────────────────────────────────┐
│ [Hành trình] [Hội] (  CHỤP  ) [Hoạt động] [Hồ sơ] │  ← dock nổi, capsule, viền 2px + bóng cứng
└────────────────────────────────────────────────────┘
```
- **Hành trình:** Hub, gồm tất cả hành trình và nút "+ Hành trình mới".
- **Hội:** "Hôm nay" của mọi nhóm, mời bạn, nhập mã. UI luôn ghi "Hội"; "Squad" chỉ là tên nội bộ.
- **Giữa, Chụp:** Hero Shutter **76×76pt** trên màn camera, viên chụp nhanh hiển thị 56×40pt ở Hub/timeline/Hội nhưng vùng chạm tối thiểu 56×48dp (≥ 44pt); mang màu của hành trình đang chọn. Nhấn giữ để mở vòng chọn hành trình (tối đa 5 đĩa: đã ghim + chưa chụp hôm nay + "Tất cả" có tìm kiếm, xem `camera-journey-picker.md`).
- **Hoạt động:** thông báo, reaction, lời mời.
- **Hồ sơ:** hồ sơ, cài đặt, tuỳ biến.
- **Số hành trình:** không giới hạn (chủ dự án chốt 2026-11-12, SRS FR-B3). Server và app Flutter hiện vẫn chặn 3; việc bỏ chặn nằm trong migration/contract tiếp theo (`docs/contracts/schema.md`).
- Liquid glass chỉ ở lớp điều hướng nổi (dock, nút camera nổi, thanh trên khi cuộn, nền vòng chọn), luôn giữ viền 2px + bóng cứng (riêng skin Quiet Transformer: viền 1.5px + bóng 2px, chủ dự án chốt 2026-11-12) và nền đặc khi bật Giảm trong suốt.
- Trong một hành trình, dock đổi chất liệu theo skin (kính mờ neon ở Aesthetic Flexer, giấy kraft ở Memory Collectors…), nhưng vị trí và hành vi không đổi.

## 2. Vỏ chung: Soft Neo-Brutalism

| Token | Light | Dark |
|---|---|---|
| bg | `#FFF8EE` | `#121212` |
| surface | `#FFFFFF` | `#1C1B19` |
| ink / border | `#1A1A1A` | `#F5F0E6` |
| inkMuted | `#5A544C` | `#B8B0A4` |
| primary | `#FF8A3D` (chữ trên nền này là `#1A1A1A`) | `#FF8A3D` (chữ trên nền này là `#1A1A1A`, ~8:1; không dùng `#F5F0E6` vì chỉ ~2:1) |
| shadow | `4px 4px 0 #1A1A1A` | `4px 4px 0 #000`, viền `#F5F0E6` |

- Pastel nhấn, mỗi persona sở hữu một màu ở vỏ chung (dùng cho badge, thẻ hành trình trên Hub):
  Quiet Transformer = mint `#7EE8A2` · Accountability Squad = yellow `#FFD84D` · Memory Collectors = peach `#FFB347` · Couple Rituals = coral `#FF7E7E` · Aesthetic Flexer = lilac `#CF9FFF` · Minimalist Habit = sky `#7EC8E3`.
- Bo góc: chip 12 · card 16 · sheet 24 · nút capsule. Khi nhấn, bóng thu về 0 và phần tử dịch 4px về phía bóng ("bấm lún", 110ms, không thu nhỏ). Chủ dự án chốt 2026-11-12; `CLAUDE.md` §2 đã cập nhật.
- **Font:** tiêu đề Space Grotesk Bold, chữ thường và có dấu chấm cuối ("hành trình.", "tạo hành trình."). Nội dung dùng **Be Vietnam Pro** (đã có trong repo). Lưu ý: không dùng Outfit vì Outfit không có bộ dấu tiếng Việt. Trước khi chốt cần kiểm tra Space Grotesk ở dấu chồng (ệ, ữ, ấ). Nếu lỗi thì thay bằng Bricolage Grotesque (đã có trong repo).
- **Icon:** chỉ dùng bộ icon sticker của Ourney (`design/ourney-v2-app/src/app/icons.tsx`, thay Phosphor từ bản Make 39–40), luôn có màu. Không dùng emoji hay ký tự làm icon.
- **Minh họa:** sticker vẽ tay, nét dày, tông ấm, dùng cho ảnh bìa, màn trống và onboarding.

## 3. Journey DNA: cá nhân hoá từ nội dung

Khi tạo, mỗi hành trình sinh ra một bộ DNA. Bộ này được lưu lại và dùng ở **mọi** màn của hành trình đó:

| Thành phần | Nguồn | Ví dụ (Đà Lạt 5 ngày, 5 bạn) |
|---|---|---|
| **Skin** | loại hành trình (+ nhóm 2 người → Couple) | Memory Collectors |
| **Biến thể màu** | mỗi skin có 3 biến thể; tự chọn theo từ khoá/điểm đến, người dùng đổi được | "Sương thông" (olive + terracotta) |
| **Ảnh bìa sticker** | điểm đến, chủ đề, emoji | quả thông, sương, đồi |
| **Motif** | skin + biến thể | băng keo giấy, chỉ khâu terracotta |
| **Tên mốc** | loại + thời lượng | Ngày 3 "Giữa chuyến" · Ngày 5 "Hết cuộn" (chuyến 5 ngày); Ngày 7 "Tuần đầu trên đường" (chuyến dài hơn) |
| **Câu hỏi caption** | loại + ngày | "Hôm nay cả bọn lạc ở đâu?" |
| **Kiểu camera** | skin | máy film dùng một lần, `CUỘN PHIM 24/36` |
| **Vé khởi hành** | skin | vé xe khách Sài Gòn → Đà Lạt |
| **Thiệp tổng kết** | skin | contact sheet 35mm |

**Vé khởi hành theo từng skin:**
Quiet Transformer = thẻ hồ sơ riêng tư có icon `lock` · Accountability Squad = thẻ nhiệm vụ (quest card) có cúp · Memory Collectors = vé xe/vé máy bay · Couple Rituals = vé đôi xé đôi được · Aesthetic Flexer = số đeo áo (race bib) · Minimalist Habit = thẻ chỉ mục (index card) tối giản.

> **Ghi chú cho dev (ngoài contract hiện tại):** cần thêm `journey.dna` (jsonb: `variant`, `cover`, `milestoneNames`, `prompts`) và một số trường theo loại: `destination`, `startWeight`/`targetWeight` (riêng tư), `sport`, `dailyMinutes`, `partnerNames`. Thay đổi này phải đi qua PR contract riêng (SRS §5).

## 4. Sáu skin hành trình (bên trong hành trình)

Màu lấy theo docs/06 (đã đạt AA). Thêm 3 biến thể màu và phần "xương brutal" giữ lại.

| Skin | Chất liệu | Font tiêu đề | Xương brutal giữ lại | 3 biến thể |
|---|---|---|---|---|
| 1 Quiet Transformer | lâm sàng, êm, hairline, nhiều khoảng trắng | serif nhẹ (Fraunces/Newsreader) | dock + nút chính viền 1.5px, bóng 2px (ngoại lệ có chủ ý so với viền 2px chung) | Emerald · Sage · Mist |
| 2 Accountability Squad | sổ học kem, polaroid, nét mực | Space Grotesk | viền 2px + lip 3px ở mọi card | Flame Gold · Violet · Chalk Green |
| 3 Memory Collectors | giấy, băng keo, chỉ khâu, film | serif cổ điển (Fraunces) + mono stamp | nút "dán" bóng cứng | Sương thông · Biển muối · Phố đêm |
| 4 Couple Rituals | hồng phấn, bo 24px, khung đôi | serif mềm | card đôi viền 2px | Rose · Berry · Peach |
| 5 Aesthetic Flexer | tối, kính mờ, viền phát sáng, số liệu to | condensed bold (Barlow Condensed) | bóng cứng màu neon `4px 4px 0 #3DE88C` | Neon Lime · Electric Coral · Ice |
| 6 Minimalist Habit | Braun, lưới 1px, không trang trí | Space Grotesk mảnh | dock, nút chính và chip viền 2px + bóng cứng 3px 3px 0; card và nội dung giữ lưới 1px, không bóng | Braun Orange · Charcoal · Sky |

Cả 6 skin đều phải có light/dark. Màn camera luôn ở nền tối.

## 5. Danh sách màn hình V2 (tất cả, không dùng lại giao diện cũ)

### A. Vỏ chung
1. Splash (logo, 3 chữ chạy: "chụp một tấm.", "giữ một chuỗi.", "đi cùng nhau.")
2. Onboarding quiz 3 câu: *"Bạn đang muốn kiên trì điều gì?"*, *"Đi một mình hay có hội?"*, *"Bạn hay quên vào lúc nào?"*. Kết quả gợi ý mẫu hành trình đầu tiên.
3. Đăng nhập email → OTP 6 số (giọng văn bình tĩnh, rõ ràng) → username + avatar
4. Màn xin quyền đúng ngữ cảnh: camera (lần chụp đầu), thông báo (sau check-in đầu tiên). Mỗi màn có lý do cảm xúc và nút "để sau vậy."
5. **Hub "hành trình."**:
   - Hero "Hôm nay" là việc quan trọng nhất kế tiếp, ví dụ "Còn 3 tiếng để giữ chuỗi 12 của *IELTS 7.5*" (kèm icon `flame`, không dùng emoji).
   - Mỗi hành trình là một thẻ mang DNA riêng (ảnh bìa sticker, màu biến thể, ngày N/M, streak, mặt hội).
   - Thẻ "+ hành trình mới".
   - Có trạng thái trống, skeleton, lỗi, và offline. Danh sách cuộn được, không giới hạn số hành trình (vòng chọn trên camera tối đa 5 đĩa, xem `camera-journey-picker.md`); dữ liệu mẫu có đủ 6 hành trình, mỗi skin một hành trình.
6. Journey switcher (nhấn giữ nút chụp)
7. Hội: "Hôm nay" của mọi nhóm, nhập mã 8 ký tự, lời mời đang chờ
8. Hồ sơ: thống kê, huy hiệu đều đặn (không xếp hạng theo kết quả), kho hành trình đã xong
9. Cài đặt: nhắc nhở theo từng hành trình, giao diện sáng/tối, quyền riêng tư, danh sách đã chặn, xoá tài khoản (vùng nguy hiểm)
10. Sheet báo cáo/chặn, toast, màn lỗi mất mạng ("đang lưu trên máy, sẽ tự gửi")

### B. Luồng tạo hành trình (5 bước, màn hình đổi skin ngay khi chọn)
1. **Chọn loại:** 6 thẻ lớn vuốt ngang (swipe deck). Contract chỉ có 5 template; thẻ Couple là nhánh xem trước của `custom` cho nhóm 2 người (`personaSkinForTemplate`, J2 trong `docs/TASKS.md`), không phải loại hành trình riêng. Mỗi thẻ là bản xem trước sống của skin, chạm vào là nền và dock đổi theo. Có thêm "Tự đặt".
2. **Câu hỏi riêng của loại** (2–3 câu, mỗi câu một màn, thẻ đáp án to):
   - *Giảm cân:* mục tiêu (giảm / giữ / thay đổi vóc dáng), cân hiện tại (tuỳ chọn, ghi rõ "chỉ mình bạn thấy"), có chụp ảnh ngày 1 làm khung căn dáng không.
   - *Học tiếng Anh:* mục tiêu (IELTS band / giao tiếp / đọc sách), số phút mỗi ngày (15/30/45/60), tên chiếc cúp ở đích.
   - *Tập luyện:* môn (chạy / gym / pilates / yoga / khác), chỉ số (km / phút / buổi), kiểu HUD yêu thích.
   - *Chuyến đi:* điểm đến (gợi ý ảnh bìa ngay), ngày đi và ngày về (ngày về tuỳ chọn: có "chưa hẹn ngày về", khi đó bước đặt nhịp không đếm ngày về đích), cuộn phim 24 hay 36 tấm.
   - *Cặp đôi:* nghi thức chung (nấu ăn / tiết kiệm / yêu xa / tự đặt), tên hai người, mỗi người chụp nửa nào.
   - *Tự đặt:* tên thói quen + 1 câu "vì sao". Không hỏi thêm.
3. **Đi cùng ai:** một mình / rủ hội (tối đa 10) / chỉ hai đứa. Chọn "chỉ hai đứa" sẽ đổi sang skin Couple.
4. **Đặt nhịp:** thời lượng (chip gợi ý + "không hẹn ngày về" với Chuyến đi/Tự đặt), giờ nhắc, ai được xem.
5. **Đúc DNA, ra vé khởi hành:**
   - Màn "đang đúc…" có animation dập dấu.
   - Hiện tấm vé khởi hành.
   - Cho đổi biến thể màu và ảnh bìa (3 lựa chọn).
   - Nút "Khởi hành" chuyển thẳng sang camera để chụp tấm Ngày 1.
   - Nếu là nhóm thì hiện sheet mời: mã 8 ký tự, link. QR để sau MVP (SRS hoãn), không nằm trong luồng bắt buộc.

### C. Bên trong mỗi hành trình (×6 skin)
1. **Trang chủ hành trình:** timeline đặc trưng của skin, header DNA, streak, N/M, % hoàn thành, mốc kế tiếp có tên riêng
2. **Camera HUD** riêng của skin + chip hành trình
3. **Sau khi chụp:** caption theo câu hỏi DNA, nhập chỉ số kiểu riêng của skin (thanh trượt kg / vòng phút / bàn phím km). Nút Đăng, tổng ≤ 3 chạm.
4. **Ăn mừng check-in:** con dấu riêng của skin và streak +1. Ở mốc 7/30/về đích thì có confetti riêng của skin.
5. **Xem một ngày** (day viewer): ảnh, caption, chỉ số, reaction bằng icon Ourney `react-fire`, `react-flex`, `react-clap`, `react-heart`, `react-laugh` (không dùng emoji)
6. **Hội hôm nay** (nếu là nhóm): kiểu riêng của skin (polaroid wall, bàn đôi, contact sheet…). Ai chưa check-in có nút nhắc.
7. **Thiệp chia sẻ** story 9:16 và feed 4:5. Giảm cân mặc định ẩn kg và làm mờ ảnh.
8. **Cập nhật hành trình:** sửa tên, bìa, biến thể, giờ nhắc, thành viên, mã mời (đổi mã), kết thúc hành trình
9. **Về đích / kết thúc:** màn "Wrapped" dạng story nhiều trang theo skin, rồi tới thiệp tổng kết
10. **Trạng thái:** ngày lỡ (ô trống theo kiểu skin, ví dụ khung polaroid trống nét đứt), hành trình đã kết thúc (chỉ đọc), offline

## 6. Giọng văn
Thân thiện, Gen Z, ngắn, không cợt nhả. Giọng văn đổi theo skin:
- Quiet Transformer: dịu, riêng tư ("Chỉ mình bạn thấy.")
- Squad: hô hào ("4/5 đứa đã điểm danh, còn Minh!")
- Memory: hoài niệm ("Thêm một khung hình cho cuộn phim.")
- Couple: ngọt ("Nửa kia đang chờ nửa của bạn.")
- Flexer: ngắn, số liệu ("Ngày 21. 5.42 km. Xong.")
- Minimalist: gần như không chữ ("Ngày 24.")

Nội dung hệ thống (OTP, xoá tài khoản, báo cáo) luôn rõ ràng và bình tĩnh.

## 7. Accessibility (bắt buộc)
- Chữ đạt contrast ≥ 4.5:1. Trên pastel thì dùng chữ ink.
- Vùng chạm ≥ 48dp (≥ 44pt trên iOS), theo `CLAUDE.md` §2.
- Trạng thái luôn có nhãn hoặc hình dạng, không chỉ dựa vào màu.
- Dynamic Type 1.35x không vỡ layout.
- Reduce Motion thay animation dập dấu/confetti bằng fade.
- Dòng tiếng Việt có dấu dùng line-height 1.3–1.45.
