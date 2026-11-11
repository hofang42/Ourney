# Chọn hành trình trên camera khi có nhiều hành trình

Ngày 2026-11-12. Vấn đề: vòng xoay vuốt ngang trên camera (V2) hiện mọi hành trình; 10–20 hành trình thì phải vuốt lâu, khó tìm, dễ chụp nhầm.

## Cơ sở

- Hick's Law: thời gian quyết định tăng theo số và độ phức tạp của lựa chọn ([Laws of UX](https://lawsofux.com/hicks-law/index.md)). Với danh sách dài, người dùng tìm nhanh hơn khi có ô tìm kiếm và thứ tự hợp lý thay vì một dải không sắp xếp ([IxDF](https://ixdf.org/literature/article/the-hick-hyman-law-an-argument-against-complexity-in-user-interface-design)).
- Locket: chụp xong gửi ngay cho một nhóm bạn cố định; có widget riêng cho một người ("Best Friend") để gửi thẳng cho người đó ([Bustle](https://www.bustle.com/life/locket-app-how-to-use-tiktok-photo-widget), [App Store](https://apps.apple.com/us/app/1600525061)). Tức là đích đến mặc định đã được chọn sẵn, không bắt chọn mỗi lần.
- SRS FR-C1: camera nhớ hành trình vừa dùng; FR-C9 (P2): đăng 1 ảnh cho nhiều hành trình.
- Chưa tìm được nghiên cứu so sánh trực tiếp "ghim" và "gần đây" cho camera; phần dưới là đề xuất thiết kế.

## Các phương án

| Phương án | Cách làm | Được | Mất |
|---|---|---|---|
| A. Ghim lên camera (ý của chủ dự án) | Chỉ hành trình được ghim mới hiện trên vòng xoay | Người dùng kiểm soát, vòng xoay ngắn | Phải tự ghim; hành trình mới tạo không ghim thì "biến mất" khỏi camera; người ít hành trình phải làm thêm một việc vô ích |
| B. Tự sắp xếp thông minh | Vòng xoay hiện tối đa 5, tự xếp: chưa chụp hôm nay → giờ nhắc gần nhất → vừa dùng | Không cần cài đặt | Thứ tự đổi liên tục, khó nhớ vị trí |
| C. Chụp trước, chọn sau | Chụp xong mới hỏi "cất vào hành trình nào", có gợi ý | Không bao giờ lỡ khoảnh khắc; hợp với đăng nhiều hành trình (FR-C9) | Thêm một bước sau khi chụp nếu gợi ý sai |
| D. Tìm kiếm | Sheet "Tất cả hành trình" có ô tìm | Tìm được dù có 50 hành trình | Chậm nếu là cách duy nhất |

## Đề xuất: kết hợp A + B + D, giữ C làm lối thoát

1. **Camera mặc định đã có đích**: chip hành trình trên cùng = hành trình vừa dùng (FR-C1). Phần lớn lần chụp không cần chọn.
2. **Vòng xoay tối đa 5 đĩa**, không bao giờ dài hơn:
   - Trước hết là hành trình **đã ghim lên camera** (tối đa 3), giữ thứ tự cố định để nhớ được vị trí.
   - Các chỗ còn lại tự điền bằng hành trình **chưa chụp hôm nay**, ưu tiên giờ nhắc gần nhất.
   - Đĩa cuối luôn là **"Tất cả (12)"** → mở sheet có ô tìm, nhóm theo: Đã ghim · Hôm nay chưa chụp · Đã chụp hôm nay · Đã kết thúc (ẩn mặc định).
3. **Ghim không bắt buộc**: người có ≤ 5 hành trình đang chạy không cần ghim, vòng xoay hiện đủ. Gợi ý ghim chỉ xuất hiện một lần khi có hành trình thứ 6 ("Ghim tối đa 3 hành trình hay chụp lên camera").
4. **Ghim ở đâu**: nhấn giữ một hành trình trong sheet "Tất cả" → "Ghim lên camera"; hoặc công tắc "Hiện trên camera" trong Cài đặt hành trình. Đĩa ghim có dấu ghim nhỏ (hình + nhãn, không chỉ màu).
5. **Sửa sau khi chụp (C)**: màn đăng có chip hành trình bấm đổi được, kèm "Đăng thêm vào…" để chọn nhiều hành trình (FR-C9, P2). Chụp nhầm không phải chụp lại.
6. **Nhóm**: hành trình nhóm còn bạn chờ mình ("3/5 đã điểm danh") được đẩy lên trước trong phần tự điền, vì có người đang chờ.

Số thao tác: chụp cho hành trình mặc định 1 chạm; đổi sang hành trình đã ghim 2 chạm (giữ nút chụp, chọn đĩa); hành trình khác 3–4 chạm (giữ, "Tất cả", tìm/chọn). Không bước nào cần vuốt dài.

## Việc tiếp theo

- Gửi Make thay vòng xoay hiện tại bằng thiết kế trên, thêm dữ liệu mẫu 12 hành trình để thử.
- Cập nhật SRS (FR-C1, thêm yêu cầu ghim lên camera) và SDS (SCR-10 camera) nếu chủ dự án duyệt.
