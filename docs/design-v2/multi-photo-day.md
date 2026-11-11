# Nhiều ảnh trong một ngày (chủ dự án chốt 2026-11-11)

Trả lời câu 10 trong `docs/client-questions.md`: chọn **nhiều ảnh mỗi ngày** (giống Locket), không còn "chụp ảnh khác là thay ảnh cũ".

## Quy tắc

- Mỗi lần chụp và đăng là **thêm** một ảnh vào ngày hôm nay của hành trình đó; không thay ảnh cũ. Không giới hạn số ảnh trong prototype (app thật cân nhắc giới hạn lưu trữ sau).
- **Ảnh đại diện của ngày** = ảnh đầu tiên; người dùng đổi được ("Đặt làm ảnh đại diện" trong màn ngày). Ảnh đại diện dùng cho timeline, lưới lịch, khung căn dáng (Quiet), thiệp chia sẻ mặc định, Wrapped.
- **Streak và ngày**: chỉ ảnh đầu tiên trong ngày làm tăng ngày/streak; ảnh thứ 2 trở đi không cộng thêm, không ăn mừng lại.
- **Hiển thị trên timeline/lưới**: ảnh đại diện + lớp ảnh chồng phía sau + nhãn số "+3" (nhãn + hình, không chỉ màu). Không đổi bố cục của 6 giao diện.
- **Màn xem một ngày** (`/j/:id/day/:n`): ảnh đại diện lớn, dải ảnh vuốt ngang (hoặc lưới) cho mọi ảnh trong ngày, mỗi ảnh có giờ chụp, caption, reaction riêng; xoá từng ảnh; đổi ảnh đại diện.
- **Camera**: sau khi đăng, nút chụp vẫn sẵn sàng; HUD có "Hôm nay: 3 ảnh"; ảnh vừa đăng hiện ở góc như Locket.
- **Nhóm / cặp đôi**: "Hôm nay" của Hội hiện mọi ảnh của từng người (theo thứ tự thời gian); điểm danh vẫn tính theo người (đã có ảnh hay chưa), không theo số ảnh. Couple: mỗi người có thể có nhiều nửa; "cặp hôm nay" ghép ảnh đại diện của hai người.
- **Memory (cuộn phim)**: mỗi ảnh là một khung trong cuộn ("CUỘN PHIM 14/24"); hết cuộn thì báo nhẹ, vẫn cho chụp và mở cuộn mới.
- **Riêng tư Quiet**: mọi ảnh trong ngày đều riêng tư; chia sẻ chỉ dùng ảnh đại diện, vẫn làm mờ và ẩn kg.
- **Nhập ảnh cũ**: nhiều ảnh cùng ngày chụp không còn đẩy vào "ảnh thêm" riêng mà thành ảnh của ngày đó như ảnh chụp thật (vẫn mang nhãn "từ thư viện", không tính streak).
- **Thiệp chia sẻ / Wrapped**: thiệp ngày có tuỳ chọn "1 ảnh" hoặc "ghép 2–4 ảnh trong ngày"; Wrapped đếm "N khoảnh khắc trong M ngày".

## Ảnh hưởng tài liệu khác

- `docs/client-questions.md` câu 10: đã có câu trả lời.
- Dữ liệu: check-in theo ngày phải chứa danh sách ảnh (`photos[]`, `coverPhotoId`) thay vì một ảnh; cần đưa vào PR contract dữ liệu (HANDOFF dòng "Đổi contract dữ liệu cho Journey DNA").
