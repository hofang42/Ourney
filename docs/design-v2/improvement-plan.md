# Plan cải thiện Ourney sau nghiên cứu V1 và V2

Ngày 2026-11-11. Dựa trên [compare-v1-v2.md](compare-v1-v2.md) và hai lượt nghiên cứu thêm (create flow, giữ chân người dùng, chia sẻ; khả năng tiếp cận, hệ thống skin, riêng tư). Phần lớn nguồn là bài tổng hợp và blog, chỉ đọc đoạn trích; mức tin cậy ghi ở từng mục. Chưa có số liệu của chính Ourney, nên mọi chỉ tiêu ở đây là tạm, chỉnh sau khi đo nhóm người dùng đầu.

## 0. Hướng đã chốt

Lai, nghiêng V2: **thao tác tối giản như V1, cá tính ở đầu ra như V2.** Xây tiếp trên V2 (Make bản 29), không làm lại từ đầu và **giữ đủ 6 giao diện**.

- Chụp và đăng: ≤ 3 chạm, giống nhau ở mọi hành trình.
- Một mô hình dữ liệu, một bộ component; skin chỉ đổi token, timeline, HUD camera, thiệp chia sẻ, Wrapped.
- Gu: dễ thương, hoài cổ, film; neo-brutalism làm mềm.

### Những gì V2 đã có và được giữ

| Phần đã có trên V2 | Giữ thế nào trong plan |
|---|---|
| 6 giao diện (Quiet, Squad, Memory, Couple, Flexer, Minimalist), mỗi cái có timeline, HUD camera, thiệp, màn ngày, Wrapped, 3 biến thể màu | Giữ cả 6. Nghiên cứu không bảo bỏ bớt; nó chỉ nhắc chi phí QA nhân lên, nên giải bằng token chung (GĐ4) chứ không cắt |
| Đổi giao diện trong hành trình, ẩn giao diện thiếu dữ liệu, bố cục lấy dữ liệu của chính hành trình (bản 29) | Giữ; đây là chỗ người dùng tự chọn mức "tối giản" (Minimalist) hay "biểu cảm" |
| Luồng tạo 5 bước + băng chuyền 6 thẻ + vé khởi hành; onboarding điền sẵn | Giữ băng chuyền và vé; gộp bước 2–4 bằng mặc định (GĐ2) |
| Khởi hành mở thẳng camera; nút chụp giữa dock, nhấn giữ mở vòng xoay đổi hành trình | Giữ nguyên, dùng làm mốc đo kích hoạt |
| Nhập hành trình đã qua (ảnh cũ không tính streak) | Giữ; thêm vào test GĐ1 như một lối vào thứ hai |
| Dock 5 nút, màn Hoạt động, Hội (điểm danh, nhắc nhẹ, reaction), kính mờ + tắt trong suốt, chữ 135% | Giữ; GĐ3 và GĐ5 chỉ chỉnh lời văn, tương phản, trạng thái |
| Riêng tư Quiet: ẩn kg, làm mờ ảnh khi chia sẻ | Giữ; GĐ6 bổ sung lưu trên máy và khoá |

## 1. Chỉ số đo (đặt trước khi sửa)

| Chỉ số | Định nghĩa | Mốc tham khảo ban đầu |
|---|---|---|
| Kích hoạt | % người tạo xong hành trình **và** chụp lần đầu trong 24 giờ | ≥ 50% trong phiên đầu (quy tắc kinh nghiệm, tin cậy thấp) |
| Thời gian tới lần chụp đầu | Mở app lần đầu → đăng ảnh đầu | < 90 giây |
| Giữ chân D1 / D7 / D30 | Có check-in vào ngày đó | Health & Fitness: D1 ~20–27%, D7 ~8–13%, D30 ~3–8% (Phiture, UXCam; các nguồn lệch nhau ~2 lần) |
| Tới chuỗi 7 ngày | % người đạt streak 7 | Duolingo coi 7 ngày là ngưỡng giữ chân (Lenny's Newsletter, tin cậy trung bình) |
| Tỉ lệ chia sẻ | Lượt chia sẻ thiệp / người dùng hoạt động / tuần | Đo nền rồi đặt chỉ tiêu |

Việc kỹ thuật: thêm sự kiện analytics cho các chỉ số trên (không gửi ảnh, không gửi kg).

## 2. Lộ trình

### Giai đoạn 1: Kiểm chứng trước khi làm tiếp (1 tuần, rẻ)

1. **Test 5 người dùng 18–30 tuổi** trên prototype Make V1 và V2 bản 29 (5 người tìm được khoảng 85% lỗi của một luồng; tin cậy trung bình). Ba nhiệm vụ: tạo hành trình và chụp lần đầu; xem lại sau "21 ngày" và chia sẻ; chọn bản muốn dùng hằng ngày và bản muốn khoe. Đo thời gian, số lần bấm, chỗ khựng.
2. **Khảo sát nhanh** (Google Form, ảnh 2 bản) cho 30–50 người: bản nào dùng hằng ngày, bản nào để khoe, giao diện nào muốn có.
3. Test đủ 6 giao diện, chia người test theo loại hành trình họ thật sự có (mỗi người 2 giao diện, mỗi giao diện ít nhất 2 người qua 2 vòng). Thử thêm: đổi giao diện trong hành trình, nhập ảnh cũ.
4. Ghi kết quả vào `docs/design-v2/`, xếp thứ tự đánh bóng 6 giao diện theo lỗi và mức thích.

Xong khi: có báo cáo test, danh sách lỗi theo mức độ cho từng giao diện, thứ tự đánh bóng.

### Giai đoạn 2: Rút gọn thao tác (ưu tiên cao, công vừa)

1. **Tạo hành trình ≤ 60 giây, dùng lại luồng V2**: giữ băng chuyền 6 thẻ (bước 1) và vé khởi hành (bước 5); bước 2 chỉ còn 1–2 câu quan trọng nhất của loại (ví dụ Chuyến đi: đi đâu; Tiếng Anh: tên cúp), bước 3–4 (đi cùng ai, thời lượng, giờ nhắc, ai xem) lấy mặc định từ onboarding và gộp thành một dòng "Sửa" trên vé. Câu còn lại chuyển vào `/j/:id/edit`. Nguồn tham khảo: 5–7 bước hoàn thành ~35–55%, 1–2 bước ~70–85% (Lazyweb, tin cậy thấp).
2. **Chụp lần đầu nằm trong luồng tạo**: "Khởi hành" mở thẳng camera (Make V2 đã làm), đo kích hoạt từ đây.
3. **Chụp và đăng giống nhau ở mọi skin**: caption và chỉ số tuỳ chọn, không bắt nhập.

Xong khi: test lại 5 người, tạo + chụp đầu < 90 giây, không ai khựng ở bước tạo.

### Giai đoạn 3: Chuỗi ngày không gây áp lực (ưu tiên cao, công vừa)

1. **Ngày ân hạn / đóng băng chuỗi**: lỡ 1 ngày không mất streak (nghiên cứu UCL của Lally: lỡ một ngày không ảnh hưởng đáng kể việc hình thành thói quen; chỉ đọc qua blog). Có nghiên cứu cho thấy đứt chuỗi làm người dùng bỏ (Journal of Consumer Research 2023), nên tránh để chuỗi đứt vì lý do nhỏ.
2. **Hai con số**: streak (có ân hạn) và "tổng số ngày đã chụp" không bao giờ về 0.
3. **Lời văn quay lại**: "Lỡ một hôm thôi. Mai về lại đường nào!" (đã có ở Squad), không dùng lời trách.
4. **Nhóm và cặp đôi**: hiện tiến độ chung ("3/5 đã học"), không có danh sách công khai ai lỡ; nhắc riêng bằng "Nhắc nhẹ 👋".

Xong khi: spec trong `docs/`, cập nhật Make, test 5 người không ai thấy bị trách.

### Giai đoạn 4: Hệ thống skin bền vững trong Flutter (ưu tiên cao, công vừa)

1. **Token ba lớp**: primitive → semantic → component; mỗi skin là một `ThemeExtension` (có `copyWith`, `lerp` để chuyển mượt 320ms như CLAUDE.md mục 5). Đối chiếu với `OurneyPersonaTheme` hiện có, không tạo hệ song song.
2. **Luật skin**: skin được đổi token, timeline, HUD, thiệp; không được đổi component, vị trí nút, số chạm. Học Duolingo: ít hình khối, ít màu, một ngôn ngữ hình dạng.
3. **Ra mắt đủ 6 giao diện** như V2 và như CLAUDE.md mục 4. Chuyển từng giao diện từ Make (`design/ourney-v2-app`) sang Flutter theo thứ tự đánh bóng của GĐ1; giao diện nào chưa đạt cổng chất lượng (GĐ5) thì ẩn khỏi băng chuyền tạm thời bằng cờ cấu hình, không xoá.
4. **Làm mềm vỏ**: bo tròn hơn, sticker, lớp grain nhẹ cho Memory; giữ viền 2px và bóng cứng nhưng giảm độ gắt.

Xong khi: `flutter analyze` sạch, đổi skin không reset camera, golden test cho 6 skin × sáng/tối.

### Giai đoạn 5: Khả năng tiếp cận (ưu tiên cao, công thấp)

1. **Cổng tương phản trong token**: chữ ≥ 4.5:1, viền và vòng focus ≥ 3:1 (WCAG 2.2 SC 1.4.11), kiểm trong CI. Viền pastel trên nền kem dễ trượt.
2. **Không chỉ dùng màu**: mọi trạng thái kèm icon, nhãn hoặc hình (đã làm ở ô ngày nhập/ngày chụp).
3. **Kính chỉ ở lớp điều hướng nổi**, có nền đặc khi `highContrast` bật; kiểm tra Reduce Transparency trên máy thật (Flutter chưa có cờ có tài liệu).
4. **Chữ 135%**: test sticker, bóng cứng, chip cao cố định.

Xong khi: báo cáo contrast của 6 skin × 2 chế độ đạt, ảnh chụp 135% không cắt chữ.

### Giai đoạn 6: Riêng tư cho hành trình giảm cân (ưu tiên cao, công vừa)

1. Mặc định "Chỉ mình tôi", lưu trên máy trước, khoá bằng sinh trắc học tuỳ chọn.
2. Thiệp chia sẻ ẩn kg và làm mờ ảnh mặc định; chỉ chia sẻ sau khi bấm rõ ràng.
3. Skin Quiet yên tĩnh: không sticker, không gợi ý chia sẻ.
4. Rà Nghị định 13/2023/NĐ-CP về dữ liệu cá nhân nhạy cảm (ảnh cơ thể, sức khoẻ) trước khi lưu lên máy chủ.

### Giai đoạn 7: Thiệp chia sẻ và Wrapped (ưu tiên vừa, công vừa)

1. Mỗi giao diện một thiệp 9:16 cho Story Instagram, TikTok, Zalo; người dùng là nhân vật chính, không phải logo.
2. Wrapped cuối hành trình: thử "fake door" trước (nút "Xem tổng kết" đếm lượt bấm), làm vài bản thủ công cho nhóm người dùng đầu.
3. Đo tỉ lệ chia sẻ; dùng widget kiểu Locket làm hướng sau nếu có số liệu.

## 3. Thứ tự đề xuất

| # | Việc | Tác động | Công |
|---|---|---|---|
| 1 | Test 5 người + khảo sát (GĐ1) | Cao | Thấp |
| 2 | Định nghĩa và gắn analytics (mục 1) | Cao | Thấp |
| 3 | Cổng tương phản + không chỉ dùng màu (GĐ5) | Cao | Thấp |
| 4 | Rút gọn tạo hành trình (GĐ2) | Cao | Vừa |
| 5 | Chuỗi có ân hạn + tổng ngày (GĐ3) | Cao | Vừa |
| 6 | Token ba lớp + chuyển 6 skin sang Flutter (GĐ4) | Cao | Cao |
| 7 | Riêng tư giảm cân (GĐ6) | Cao | Vừa |
| 8 | Thiệp 9:16 + fake door Wrapped (GĐ7) | Vừa | Vừa |

## 4. Rủi ro và chỗ còn thiếu

- Số liệu giữ chân lệch nhau ~2 lần giữa các nguồn; con số về streak freeze chủ yếu từ blog.
- Chưa có dữ liệu Việt Nam riêng cho app nhật ký/thói quen, chưa có A/B.
- Chưa tra nguồn gốc cho Notion, Spotify, Apple Journal về cách quản lý nhiều giao diện.
- Nếu test giai đoạn 1 cho thấy người dùng thích V1 rõ rệt: vẫn giữ 6 giao diện nhưng đặt Minimalist làm mặc định cho mọi loại, 5 giao diện còn lại là lựa chọn trong "Giao diện" của hành trình (tính năng đổi giao diện V2 đã có).

## Nguồn

- Giữ chân: https://phiture.com/mobilegrowthstack/managing-retention-rate-benchmarks-and-expectations/ , https://uxcam.com/blog/mobile-app-retention-benchmarks/
- Độ dài onboarding (tin cậy thấp): https://www.lazyweb.com/research/onboarding-flow-length-benchmark-steps
- Kích hoạt: https://revenuecat.com/blog/growth/activation-metrics
- Streak: https://www.lennysnewsletter.com/p/behind-the-product-duolingo-streaks , https://www.colorado.edu/business/node/17581
- Wrapped: https://adma.com.au/resources/personal-shareable-no-strings-attached-the-winning-formula-behind-spotify-wrapped
- Locket: https://techcrunch.com/2025/11/03/lockets-social-app-is-picking-up-steam-with-gen-alpha
- Số người test: https://blog.uxtweak.com/usability-studies-how-many-participants-are-enough/
- Liquid glass: https://infinum.com/blog/apples-ios-26-liquid-glass-sleek-shiny-and-questionably-accessible/
- WCAG 1.4.11: https://www.w3.org/WAI/WCAG22/Understanding/non-text-contrast.html
- Duolingo shape language: https://design.duolingo.com/illustration
- Ảnh cơ thể riêng tư: https://progress.helpscoutdocs.com/article/45-photos-data-private
