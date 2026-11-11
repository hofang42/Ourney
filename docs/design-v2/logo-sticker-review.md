# Đánh giá hướng logo "Sticker chữ" (Hướng C, vòng 3)

Ngày 2026-11-11. Nguồn: bảng logo chủ dự án gửi, một lượt nghiên cứu web (5 lượt tìm, chủ yếu blog agency/nhà cung cấp; mức tin cậy ghi từng mục).

## Tóm tắt hướng

Chữ "ourney", mỗi chữ là một miếng sticker bế viền trắng, nghiêng nhẹ, mỗi chữ một font và màu của một kiểu hành trình (o Fraunces xanh lá · u Bricolage cam · r Space Mono đỏ trên giấy kraft · n Baloo 2 xanh chấm bi · e Barlow Condensed hồng/đen · y Fraunces Italic tím). Phần cố định: viền bế, độ nghiêng, thứ tự chữ. Phần thay đổi: "da" từng chữ theo mùa hoặc hành trình. Icon app là chữ "o" đổi da theo hành trình; cỡ nhỏ chỉ còn "o". Bản một màu vẫn giữ viền bế.

## Điểm phù hợp

| Dùng cho | Điểm | Lý do |
|---|---|---|
| Logo và icon app | **6/10** | Khác biệt, hợp văn hoá dán sticker của Gen Z Việt (khớp nghiên cứu trước: sticker, scrapbook, hoài cổ), viền bế là điểm neo thống nhất. Yếu: 6 font ở cỡ nhỏ khó đọc và thiếu nhất quán; chữ "o" đứng một mình dễ lẫn với icon tròn khác; icon đổi da theo hành trình làm loãng khả năng nhận ra; icon sặc sỡ lệch với hành trình giảm cân cần kín đáo |
| Phong cách sản phẩm chia sẻ (thiệp, Wrapped) | **8/10** | Sticker sinh ra để dán lên ảnh: "DAY 21", sticker địa điểm/thời tiết, wordmark sticker đều tự nhiên trong kiểu collage và không tranh chỗ với ảnh của người dùng. Khớp hướng "cá tính ở đầu ra" trong `improvement-plan.md` |

## Bằng chứng chính

- Kiểu chữ cắt dán, trộn font được nêu là xu hướng 2025 cho thương hiệu thân mật, gây chú ý; khuyên ghép với một font sans sạch để đọc được (Vistaprint, tin cậy trung bình): https://www.vistaprint.com/hub/logo-design-trends-2025
- Có phản ứng ngược với logo tối giản, nhưng khả năng đọc vẫn quan trọng hơn; Gen Z cũng thích sự rõ ràng, chân thật (Creative Bloq, tin cậy trung bình): https://www.creativebloq.com/design/logos-icons/could-unreadable-typography-the-latest-trend-in-logo-design
- Icon thay thế có từ iOS 10.3; Apple HIG khuyến khích cân nhắc; từ iOS 18 mỗi icon thay thế cần bản tối và bản tint; icon thay thế cũng qua App Review (tin cậy cao): https://developer.apple.com/design/human-interface-guidelines/app-icons
- Người dùng đón nhận icon thay thế tốt nhưng ít app làm vì tốn công (MacStories, tin cậy trung bình): https://club.macstories.net/posts/ios-apps-with-alternate-icons-vol-2
- Google Fonts (OFL/Apache) dùng thương mại và dùng trong logo được; giới hạn OFL: không bán file font riêng, bản sửa mang Reserved Font Name phải đổi tên (tin cậy cao): https://developers.google.com/fonts/faq
- Watermark trên nội dung chia sẻ giúp lan truyền (Musical.ly, Kapwing) nhưng là ví dụ, không có số đo; một số nền tảng hạ hiển thị nội dung có watermark app khác: https://www.kapwing.com/blog/viral-how-we-used-watermarks-to-grow-a-startup/
- Chưa có dữ liệu riêng về cách thị trường Việt Nam đón nhận kiểu chữ cắt dán.

## Đề xuất

1. **Khoá hệ thống**: cố định thứ tự chữ, viền bế, khoảng nghiêng (ví dụ −8° đến +8°), bảng 6 màu. Chọn một bộ da làm logo chính thức; chỉ chiến dịch/mùa mới đổi da.
2. **Icon chính cố định**, icon theo hành trình là lựa chọn bật thêm trong Cài đặt (icon thay thế). Làm bản sáng/tối/tint cho iOS 18+. Test chữ "o" ở 29, 40, 60px và 16px (favicon). Cân nhắc vẽ riêng chữ "o" (không dùng nguyên glyph Fraunces) để dễ đăng ký nhãn hiệu.
3. **Giảm font**: logo giữ 6 chữ nhưng nên rút còn 3 họ font (ví dụ Fraunces, Bricolage, Space Mono) để đọc rõ và nhất quán; chữ trong app vẫn là Be Vietnam Pro.
4. **Thiệp chia sẻ**: wordmark sticker nhỏ (15–20% bề ngang thiệp) ở góc dưới; có nút "ẩn chữ ourney" và bản một màu; hành trình giảm cân mặc định ẩn. Thêm link mời / mã QR nhỏ để biết lượt cài đến từ thiệp.
5. **Trước khi chốt**: đọc OFL.txt của từng họ font, kiểm tra bộ tiếng Việt trên fonts.google.com (Fraunces, Bricolage Grotesque, Barlow Condensed chưa xác nhận được từ nguồn), chuyển logo sang outline, lưu file license.

## Áp vào Ourney V2

- Icon hệ thống trong app vẫn là icon vector (CLAUDE.md mục 1.3: không dùng emoji hay chữ làm icon điều hướng). "Icon design" theo hướng sticker: nét 2px mực, góc bo, khi được chọn có viền bế trắng như logo; không dùng font chữ làm icon.
- Splash, Hub và thiệp chia sẻ dùng wordmark sticker; thiệp theo 6 giao diện giữ chất riêng, wordmark chỉ là sticker nhỏ.
