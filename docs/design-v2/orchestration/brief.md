# BRIEF CHUNG CHO MỌI SUBAGENT — thiết kế lại UI/UX Ourney V2

Repo: D:\DuAnMa\JourneyShared, nhánh design/v2-spec. KHÔNG được đổi hướng thiết kế ở mục C.
File đích Figma: https://www.figma.com/design/nyvBJzr7XYlg7ZzhsJGoZx/Ourney-V2
Bản V1 (ví dụ những gì KHÔNG nên làm): https://www.figma.com/make/z3B1WO8e7SUNG83jvaPotn/Ourney-V1.0

# QUYẾT ĐỊNH MỚI CỦA NGƯỜI DÙNG (ưu tiên hơn mục C khi khác nhau)
- Thẻ Minimalist dùng "24/30 NGÀY · 80% ĐỀU ĐẶN".
- Nhãn hiển thị trong UI của tab phải dock và khu vực nhóm là "Hội", không dùng chữ "Squad" trong UI ("Squad" chỉ còn là tên nội bộ, ví dụ tên skin Accountability Squad). "Squad hôm nay" hiển thị là "Hội hôm nay".
- Nút chụp skin Accountability Squad màu cam lửa #FF9F1C, chữ ink; tím chỉ dùng cho hành động nhóm.
- Chọn "chỉ hai đứa" ở bước 3 khi đang ở loại khác: đổi sang skin Couple, giữ câu trả lời và luật của loại cũ (ví dụ Giảm cân vẫn ẩn kg), hỏi thêm hai màn: tên hai người và ai chụp nửa nào.

- BỎ luật "tối đa 3 hành trình đang chạy": không giới hạn số hành trình. Không có trạng thái "đủ 3", luôn tạo thêm được. Hub và vòng xoay phải dùng tốt khi có nhiều hành trình (ví dụ 8). Thay thế dòng tương ứng ở mục B.
- Đối soát độ phủ chỉ dựa trên đặc tả V2 (docs/design-v2/README.md và brief này), bỏ qua SDS và V1.

# B. APP LÀ GÌ
Ourney = "Locket cho mục tiêu". App Flutter cho iOS + Android, người dùng Việt Nam, UI tiếng Việt.
- Người dùng tạo "hành trình": Giảm cân, Học tiếng Anh, 30 ngày tập luyện, Chuyến đi, Cặp đôi, Tự đặt.
- Mỗi ngày chụp 1 ảnh check-in (caption ≤140 ký tự, chỉ số tuỳ chọn), tối đa 3 chạm.
  Mở app là vào thẳng camera.
- Có streak, ngày N/M, % hoàn thành. Mốc 7 / 30 / về đích có confetti và thiệp chia sẻ (9:16 và 4:5).
- Nhóm tối đa 10 người, mời bằng mã 8 ký tự hoặc link. Màn "Hôm nay" cho thấy ai đã/chưa check-in.
  Có reaction 🔥 💪 👏 ❤️ 😂, không có comment.
- Luật cứng:
  - Không giới hạn số hành trình (chốt 2026-11-12, SRS FR-B3).
  - KHÔNG xếp hạng theo kết quả cơ thể.
  - Giảm cân: mặc định ẩn kg và làm mờ ảnh khi chia sẻ.
  - Hành trình nhóm không bao giờ có link công khai.
  - Chạy offline trước, đồng bộ sau.
  - Đăng nhập email OTP 6 số.
  - Xin quyền đúng ngữ cảnh.
  - Có report/block và xoá tài khoản.
- V1 hỏng ở chỗ: mọi hành trình dùng chung một form dài và một lưới lịch, skin chỉ đổi màu.
  V2 phải "cá nhân hoá, hành trình hoá": mỗi hành trình được "đúc" từ chính nội dung của nó
  và là một thế giới giao diện riêng. Làm lại TẤT CẢ màn hình, không dùng lại giao diện cũ.
  Không bắt buộc theo luật UI cũ trong CLAUDE.md. Ưu tiên hiện đại, bắt mắt nhất.

# C. HƯỚNG THIẾT KẾ ĐÃ CHỐT
1. VỎ CHUNG "Soft Neo-Brutalism" cho Hub / tạo hành trình / onboarding / hồ sơ / squad / cài đặt.
   - Light: bg #FFF8EE, surface #FFF, ink/viền #1A1A1A, chữ phụ #5A544C.
   - Dark: bg #121212, surface #1C1B19, viền #F5F0E6.
   - Primary cam #FF8A3D, chữ trên nền cam là ink.
   - Card viền 2px, bóng cứng 4px 4px 0 không blur, bo 16. Khi nhấn: bóng về 0, phần tử dịch 4px.
   - Pastel theo loại: mint #7EE8A2 Giảm cân · vàng #FFD84D Tiếng Anh · peach #FFB347 Chuyến đi ·
     coral #FF7E7E Cặp đôi · lilac #CF9FFF Tập luyện · sky #7EC8E3 Tự đặt.
   - Font: tiêu đề Space Grotesk Bold, chữ thường, có dấu chấm cuối ("hành trình.").
     Nội dung Be Vietnam Pro. KHÔNG dùng Outfit (thiếu dấu tiếng Việt). Line-height 1.3–1.45.
   - Icon Phosphor Bold/Duotone 24px, không dùng emoji làm icon điều hướng.
   - Minh họa sticker vẽ tay, nét dày, tông ấm. Ảnh dùng khung Polaroid xoay -3°..3°.
2. ĐIỀU HƯỚNG: floating dock capsule 5 tab (cập nhật 2026-11-11): Hành trình · Hội · Chụp · Hoạt động · Hồ sơ.
   - Giữa: nút Chụp 76pt trên camera (56×40 ở màn khác) màu của hành trình đang chọn,
     nhấn giữ để mở vòng chọn hành trình. UI ghi "Hội"; "Squad" chỉ là tên nội bộ.
   - Trong hành trình, dock đổi chất liệu theo skin nhưng vị trí và hành vi giữ nguyên.
3. JOURNEY DNA: lúc tạo, câu trả lời sinh ra skin, biến thể màu (3 lựa chọn mỗi skin),
   ảnh bìa sticker, motif, tên các mốc, câu hỏi caption, kiểu camera, VÉ KHỞI HÀNH và thiệp tổng kết.
   - Vé theo skin: thẻ hồ sơ riêng tư 🔒 · thẻ nhiệm vụ có cúp · vé xe/máy bay ·
     vé đôi xé đôi · số đeo áo (race bib) · thẻ chỉ mục tối giản.
4. LUỒNG TẠO 5 BƯỚC (màn hình đổi skin ngay khi chọn loại):
   (1) Vuốt chọn 6 thẻ, mỗi thẻ là bản xem trước sống của skin.
   (2) 2–3 câu hỏi riêng của loại, mỗi câu một màn, thẻ đáp án to:
       - Giảm cân: mục tiêu / cân hiện tại (riêng tư) / ảnh ngày 1 làm khung căn dáng.
       - Tiếng Anh: mục tiêu / số phút mỗi ngày / tên chiếc cúp.
       - Tập luyện: môn / đơn vị đo / kiểu HUD.
       - Chuyến đi: điểm đến (gợi ý ảnh bìa ngay) / ngày đi–về / cuộn phim 24 hay 36.
       - Cặp đôi: nghi thức chung / tên hai người / ai chụp nửa nào.
       - Tự đặt: chỉ một màn, tên thói quen + "vì sao".
   (3) Đi cùng ai: một mình / rủ hội / chỉ hai đứa (chọn hai đứa thì đổi sang skin Couple).
   (4) Đặt nhịp: thời lượng, giờ nhắc, ai được xem.
   (5) "Đúc" DNA, ra vé khởi hành (đổi được biến thể màu và ảnh bìa).
       Nút "Khởi hành" mở camera chụp Ngày 1. Hành trình nhóm thì hiện sheet mời
       (mã, link, QR).
5. SÁU SKIN BÊN TRONG HÀNH TRÌNH: bám sát 6 ảnh mẫu, giữ "xương" brutal ở dock, nút chính, chip.
   Mỗi skin có light + dark, camera luôn nền tối.
   - Quiet Transformer (Giảm cân): emerald #10B981, nút chụp coral #FF4D6D.
     Light #EFF3F0/#FFF/#0F172A, Dark #0B0F12/#151C21/#F1F5F9.
     Đường cân nặng + node ảnh, camera ghost-align, thiệp NGÀY 01 vs NGÀY 21 ẩn kg.
   - Accountability Squad (Tiếng Anh): vàng lửa #FF9F1C, tím #7556F8.
     Light #F7F1E5/#FFFDF9/#1E1B18, Dark #12131A/#1D1F2B/#F8FAFC. Viền 2px + lip 3px.
     Con đường chữ S tới cúp, HUD "📖 45 PHÚT · 🔥 21", tường polaroid "4/5 ĐÃ ĐIỂM DANH" + "Nhắc Minh 👋".
   - Memory Collectors (Chuyến đi): terracotta #CC4A2F, olive #4A6B53.
     Light #F4EFE6/#FFF/#231F1E, Dark #141312/#1F1D1B/#F5F2EB. Serif + chữ mono đóng dấu.
     Sổ dán polaroid băng keo, máy film "CUỘN PHIM 12/24", contact sheet 35mm.
   - Couple Rituals (Cặp đôi): rose #E15B72, berry #9D174D.
     Light #F9F0EE/#FFF/#261F22, Dark #171215/#241C21/#FCE7F3. Bo 24.
     Cặp ảnh mỗi ngày + tim, camera nửa khung, poster "18 NGÀY BÊN NHAU · 36 KHOẢNH KHẮC".
   - Aesthetic Flexer (Tập luyện): ưu tiên nền tối, coral #FF4D6D, neon lime #3DE88C.
     Light #F3F4F6/#FFF/#090A0F, Dark #090A0F/#14161F/#F8FAFC.
     Kính mờ, số condensed, sparkline neon, sticker HUD km/pace, story kèm dải 21 ngày.
   - Minimalist Habit (Tự đặt): cam Braun #EA580C, than #27272A.
     Light #F5F3EE/#FFF/#1C1C1E, Dark #0E0E10/#18181B/#F4F4F5. Lưới 1px, không trang trí.
     Lịch ảnh 7 cột nối bằng một đường cam, chụp 1 chạm không chữ, thẻ "24/30 NGÀY · 80% ĐỀU ĐẶN".
6. MỖI SKIN CẦN ĐỦ: trang chủ hành trình, camera HUD, màn sau khi chụp (nhập chỉ số kiểu riêng),
   ăn mừng check-in + mốc, xem một ngày, squad hôm nay, thiệp chia sẻ, cập nhật hành trình
   (sửa tên/bìa/biến thể/giờ nhắc/thành viên/đổi mã/kết thúc), về đích (Wrapped), ngày lỡ,
   chỉ đọc, offline.
7. GIỌNG VĂN: Gen Z, ngắn, không cợt nhả. Đổi theo skin:
   dịu và riêng tư / hô hào / hoài niệm / ngọt / số liệu cụt / gần như không chữ.
   Nội dung OTP, xoá tài khoản, báo cáo luôn rõ ràng và bình tĩnh.
8. ACCESSIBILITY: contrast ≥ 4.5:1, vùng chạm ≥ 44pt, trạng thái không chỉ dựa vào màu,
   Dynamic Type 1.35x, Reduce Motion.
