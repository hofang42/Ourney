# Kiểm tra Q cho Prompt 4 → 10 (Figma Make version 20 → 22, 2026-11-11)

Cách kiểm: mở thẳng preview `*.makeproxy-c.figma.site` để đọc DOM trong `.phone-frame`, chạy script đo trên 14 route vỏ chung và 6 skin × 8 route (`''`, `/camera`, `/post`, `/squad`, `/share`, `/day/3`, `/edit`, `/wrapped`) ở cả Sáng và Tối, rồi bấm thử luồng bằng click DOM. Q-ref so ảnh chụp với `apps/mobile/assets/design_personas/`. Mẫu báo cáo theo `orchestration/q-rules.md`.

Lưu ý khi đọc số đo tương phản: trình duyệt trả một số màu dạng `color(srgb 0–1)`; script đọc nhầm thành thang 0–255 nên báo nhầm ở Hub, /squad, /create/4, /settings/delete/1, /j/quiet/share. Đo lại thủ công các chỗ đó đều đạt.

| Tiêu chí | Kết quả | Ghi chú |
| --- | --- | --- |
| Q-a11y: chữ ≥ 12px | ĐẠT | Không còn chữ < 12px ở cả hai chế độ |
| Q-a11y: vùng chạm ≥ 44pt | ĐẠT | Đã sửa: công tắc /j/quiet/share (v18), nút /create/4 ở Tối (v21) |
| Q-a11y: tương phản | ĐẠT | Đã sửa: nút nguy hiểm ở Tối (v18), chip Squad ở Tối (v18), nhãn camera Squad/Memory/Minimalist (v19), dock Flexer ở Sáng (v21) |
| Q-a11y: bàn phím | ĐẠT | Đã sửa (v22): thẻ nhóm ở /squad là nút có aria-label, focus được, Enter mở |
| Q-vi: tiếng Việt, không lẫn tiếng Anh | ĐẠT | Chỉ còn "Email", "Ourney", "kg", "km"; dấu phẩy thập phân (v21) |
| Q-mode: Sáng / Tối | ĐẠT | Mọi route ở cả hai chế độ đều đã đo |
| Q-skin: 6 skin khác thế giới | ĐẠT | Bố cục, chất liệu và font khác nhau ở trang chủ, camera, thiệp |
| Q-ref: bảng persona | ĐẠT | Đã sửa (v19): ảnh tường polaroid Squad, ảnh dòng thời gian Quiet, HUD camera Flexer, khung ngắm Minimalist; (v20) bỏ chip số trùng ở camera Flexer |
| Q-rules: không xếp hạng, không link công khai nhóm, Nhắc chỉ là toast | ĐẠT | Hội hôm nay chỉ có ai đã/chưa và giờ; vào nhóm có dòng "không có link công khai" |

Bấm thử trên version 21–22 (đều ĐẠT):
- Hội: "Tham gia" tắt khi trống; "Nhắc Minh" → "Đã nhắc Minh" và tắt; bấm thẻ nhóm → /j/ielts/squad; có lời mời đang chờ.
- Vào nhóm: AAAAAAAA, EXPIRED1, FULL0010, NOJOIN01 đều có thẻ lỗi riêng, đổi mã thì màn đổi theo; K7Q2M9XA hiện vé xem trước, "Tham gia" mở hành trình.
- Prompt 8: reaction +1 (2 → 3); "Lưu" tắt khi chưa sửa; chủ nhóm "Kết thúc hành trình" → chỉ đọc → Wrapped; thành viên không có nút kết thúc.
- Prompt 10: Ngày 1, Lỗi (có "Đang xem bản đã lưu"), Bị xoá khỏi nhóm; thành viên có "Rời nhóm", không có "Đổi mã"; ba trang điều khoản, chính sách, liên hệ.
- Nút chụp: chạm nhanh mở camera; giữ 600ms mở vòng xoay (bằng pointer event giả lập).

CHƯA KIỂM ĐƯỢC: nhấn giữ trên máy thật và Dynamic Type 1.35x, vì server điều khiển thiết bị (mobai) không kết nối được.
