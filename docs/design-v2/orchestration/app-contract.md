# HỢP ĐỒNG APP (yêu cầu trực tiếp của người dùng, ưu tiên cao nhất)

Người dùng: "thiết kế app, phải có màn hình và các tương tác giữa các màn hình, không phải một landing page".

Kết quả trên Figma Make phải là PROTOTYPE APP CHẠY ĐƯỢC:
1. Một khung điện thoại 390×844 ở giữa preview. Mỗi lần chỉ hiện MỘT màn, nội dung cuộn bên trong màn đó. Cấm trang cuộn dài, hero, các section giới thiệu, chữ marketing, hay trang trưng bày component/style guide.
2. Điểm vào là luồng app thật: lần đầu vào đăng nhập/onboarding; đã đăng nhập thì vào thẳng camera.
3. Router với route thật cho từng màn, có quay lại. Trạng thái chung trong một store dùng cho toàn app (hành trình đang chọn, skin, light/dark, check-in hôm nay, offline), giữ nguyên khi chuyển màn. Hành động làm thay đổi dữ liệu thấy được ở màn khác (ví dụ check-in xong thì streak và Hub đổi).
4. Mọi nút, thẻ, tab, chip đều bấm được và dẫn tới màn đúng hoặc đổi trạng thái. Không có nút chết, không có màn cụt, sheet nào cũng đóng được.
5. Tương tác và chuyển cảnh thật: push/slide giữa các màn, sheet kéo lên, dock hoạt động, nhấn giữ nút Chụp mở vòng xoay đổi hành trình, chụp → sau khi chụp → ăn mừng → trang chủ hành trình, đổi skin ngay khi chọn loại. Có nhánh Giảm chuyển động.
6. Design system chỉ là token và component trong code, không hiển thị thành màn trong app.
7. Bảng điều khiển để duyệt (light/dark, chọn skin, chọn trạng thái như offline/chỉ đọc/ngày lỡ, đi tới màn bất kỳ) đặt NGOÀI khung điện thoại, trông khác app, thu gọn được.
8. Mỗi prompt là bổ sung vào cùng một app: thêm route và nối vào các màn đã có. Không dựng lại, không tạo trang riêng.
