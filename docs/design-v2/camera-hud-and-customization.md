# Camera: tên hành trình bị cắt + tuỳ biến nền, avatar, sticker

Ngày 2026-11-12. Make đang hết credit nên **chưa gửi**; prompt ở mục 4 dùng khi có credit. Code tham chiếu: Make bản 42 (`design/ourney-v2-app`, commit `a099558`).

## 1. Lỗi: tên hành trình trên camera bị cắt "...", quá nhiều chữ

### Tái hiện và nguyên nhân
- `routes.tsx` (~dòng 8411–8483), mỗi đĩa `.journey-disc` rộng ~64–70px nhưng chứa tới 4 lớp chữ: "Ngày 21" (`.journey-disc-day`), tên hành trình (`<small>`, `text-overflow: ellipsis`), "Đã ghim" (`.journey-disc-pin`) hoặc "2/4 đã điểm danh" (`.journey-disc-status`). Trên đầu còn chip HUD "Hôm nay · 3 ảnh".
- Tên dài ("Ảnh gia đình mỗi ngày", "15 phút tiếng Nhật", "30 ngày nấu cho nhau") luôn bị cắt; 5 đĩa × 3–4 dòng = ~18 mẩu chữ cùng lúc trên nền camera tối, rối mắt.

### Tham khảo
- Chọn chế độ trong camera iOS, carousel lens của Snapchat, khay story Instagram: mục trong dải chỉ là **hình** (hoặc một chữ ngắn), **tên đầy đủ chỉ hiện một lần** cho mục đang chọn/đang ở giữa. Đây là cách giảm số chữ cùng lúc mà vẫn rõ đang chọn gì (Hick's Law: ít lựa chọn và ít thông tin cạnh tranh thì quyết định nhanh hơn — [Laws of UX](https://lawsofux.com/hicks-law/index.md)).
- NN/g: icon nên có nhãn, nhưng nhãn có thể đặt ở một chỗ cố định thay vì lặp ở mọi icon ([NN/g](https://www.nngroup.com/articles/icon-usability/)).

### Thiết kế lại
1. **Đĩa chỉ còn hình**: avatar hành trình (mặc định `TypeBadge`, sau này là avatar tự đặt — mục 2) cỡ 48px, không chữ bên dưới.
   - Trạng thái bằng hình nhỏ ở góc đĩa (không chữ): chấm ghim (icon `map-pin` 14px) góc trên trái; tick "đã chụp hôm nay" góc dưới phải; vòng cung tiến độ quanh đĩa cho nhóm (3/5 thành viên).
   - Đĩa đang chọn to hơn (56px) + viền bế sticker.
2. **Một dòng tiêu đề duy nhất** phía trên dải đĩa, cho đĩa đang chọn (hoặc đang chạm giữ):
   - Dòng 1: tên đầy đủ, tối đa 2 dòng, **không cắt "..."** (font 16px đậm; tên dài hơn 2 dòng thì giảm xuống 14px).
   - Dòng 2 (nhỏ, 13px): "Ngày 21/30 · chưa chụp hôm nay" hoặc "Ngày 21/30 · 3/5 đã điểm danh" hoặc "Đã ghim".
   - Đổi đĩa → tiêu đề cross-fade 120ms.
3. **Đĩa "Tất cả"**: icon lưới + số "12" trong đĩa, không chữ dưới; tiêu đề khi chạm: "Tất cả hành trình".
4. **Chip trên đầu camera** chỉ còn tên hành trình đang chọn (1 dòng, co chữ tới 13px trước khi cắt; nếu vẫn dài thì cuộn chậm kiểu marquee 1 lần rồi dừng). "Hôm nay · 3 ảnh" chuyển xuống thành số nhỏ trên thumbnail ảnh gần nhất ở góc dưới trái.
5. **Trợ năng**: mỗi đĩa có `aria-label` đầy đủ "Ảnh gia đình mỗi ngày, ngày 14 trên 30, 2 trên 4 đã điểm danh, đã ghim"; chữ 135% vẫn chỉ có tiêu đề 2 dòng.
6. **Kiểm tra**: reviewer "Kiểm tra camera" đếm số phần tử chữ hiển thị trên camera (mục tiêu ≤ 4: chip tên, tiêu đề 2 dòng, số ảnh), và báo mọi chữ có `text-overflow: ellipsis` đang bị cắt.

## 2. Tính năng mới: tuỳ biến hành trình (nền, avatar, tem/huy chương)

### Phạm vi
- **Avatar hành trình**: ảnh tròn đại diện hành trình (dùng ở đĩa camera, thẻ Hub, đầu trang hành trình, Hội). Nguồn: chọn từ ảnh đã chụp trong hành trình, tải ảnh lên, hoặc chọn sticker trong bộ của app. Mặc định là `TypeBadge`.
- **Nền hành trình**: ảnh hoặc hoạ tiết nền cho trang hành trình và thẻ Hub. Nguồn: bộ hoạ tiết theo giao diện (giấy kraft, lưới, neon…), ảnh trong hành trình, hoặc tải lên. Có lớp phủ tự động để chữ luôn đạt tương phản 4.5:1.
- **Tem / huy chương dán góc**: người dùng tải ảnh lên làm sticker (tự tách nền nếu máy hỗ trợ, có viền bế trắng như logo), hoặc chọn từ bộ có sẵn; dán ở 4 góc thẻ hành trình, ảnh ngày, thiệp chia sẻ. Tối đa 4 sticker mỗi chỗ; kéo để xoay ±15°, co giãn 0.6–1.4×.
- Huy chương mốc (7/30/về đích) tự mở khoá và dán được như sticker.

### Mở khoá (để làm tính năng trả phí hoặc phần thưởng sau này)
| Mục | Miễn phí | Mở khoá |
|---|---|---|
| Avatar | Chọn TypeBadge hoặc ảnh trong hành trình | Tải ảnh ngoài lên: đạt chuỗi 7 ngày (đề xuất) hoặc gói trả phí |
| Nền | Hoạ tiết mặc định của giao diện | Bộ hoạ tiết thêm, ảnh trong hành trình, tải lên: theo mốc hoặc gói trả phí |
| Sticker | Huy chương mốc đã đạt | Tải sticker riêng, bộ sticker theo mùa: gói trả phí hoặc sự kiện |

Chưa chốt mô hình kiếm tiền (câu 12 trong `docs/client-questions.md` vẫn mở), nên prototype dùng cờ `unlocks` và ghi "Mở khoá khi đạt chuỗi 7 ngày" thay vì giá.

### Ràng buộc
- **Riêng tư**: hành trình Giảm cân không cho dùng ảnh cơ thể làm avatar/nền khi chia sẻ ra ngoài; thiệp chia sẻ dùng lại quy tắc làm mờ.
- **Nhóm**: chỉ chủ nhóm đổi avatar/nền của hành trình nhóm; sticker cá nhân chỉ hiện trên ảnh của chính người đó.
- **An toàn**: ảnh tải lên đi qua kiểm duyệt như ảnh check-in (báo cáo, ẩn khi bị báo cáo); giới hạn 2MB, PNG/JPEG/WebP, tối đa 20 sticker tải lên mỗi tài khoản.
- **Không dùng emoji** làm sticker hệ thống (CLAUDE.md mục 1.3); sticker tải lên là nội dung người dùng.
- Dark mode: lớp phủ nền tự đổi để giữ tương phản.

## 3. Ảnh hưởng tài liệu
- SRS: thêm FR-B (tuỳ biến avatar/nền/sticker, mở khoá) — nhánh `docs/journey-customization`.
- SDS: thêm mục tuỳ biến và sửa SCR-10 (camera) theo mục 1.
- Contract dữ liệu (đề xuất, chưa migrate): `journeys.avatar_path`, `journeys.background_kind` (`preset|photo|upload`) + `background_ref`; bảng `journey_stickers(id, journey_id, owner_id, target (card|day|share), corner, rotation, scale, asset_path, created_at)`; bảng `user_unlocks(user_id, key, unlocked_at, source)`.

## 4. Prompt gửi Make (khi có credit)

```
FIX + NEW. 1) Camera journey names are cut with "..." and the wheel shows too much text: each disc (~64-70px) stacks "Ngày 21", the name (ellipsis), "Đã ghim" or "2/4 đã điểm danh", plus the top chip "Hôm nay · 3 ảnh". Redesign (routes.tsx journey-disc-strip + app.css):
- Discs are image-only: journey avatar (default TypeBadge) 48px, selected 56px with die-cut sticker border. No text under discs. Status as small shapes on the disc: pin icon top-left if pinned, check bottom-right if shot today, progress arc around the disc for group attendance.
- One title block above the strip for the selected/pressed disc: full name, max 2 lines, never ellipsis (16px bold, 14px if longer than 2 lines), second line 13px "Ngày 21/30 · chưa chụp hôm nay" / "· 3/5 đã điểm danh" / "Đã ghim". Cross-fade 120ms when the disc changes.
- "Tất cả" disc: grid icon + count inside the disc; title "Tất cả hành trình".
- Top camera chip shows only the selected journey name (1 line, shrink to 13px; if still too long, marquee once then stop). Move "Hôm nay · N ảnh" to a small count on the latest-photo thumbnail bottom-left.
- Every disc keeps a full aria-label (name, day, attendance, pinned). At 135% type only the title grows.
- Reviewer "Kiểm tra camera": count visible text nodes on the camera (target ≤ 4) and list any truncated text.

2) NEW journey customization (unlockable). In /j/:id/edit add section "Tuỳ biến":
- Avatar: choose TypeBadge (default), a photo from this journey, upload (simulated picker), or an app sticker. Used in camera discs, Hub card, journey header, Squad.
- Background: preset patterns per skin, a journey photo, or upload; auto overlay keeps text contrast ≥ 4.5:1 in light/dark.
- Stickers: user-uploaded sticker (simulated, white die-cut border like the logo) or earned milestone medals; place on the 4 corners of the journey card, day photo, share card; max 4 per surface; drag to rotate ±15° and scale 0.6–1.4.
- Locks: upload avatar/background/sticker show a lock with "Mở khoá khi đạt chuỗi 7 ngày" (store.unlocks flags; reviewer toggle "Mở khoá tất cả"). Milestone medals are free once earned.
- Rules: group journeys only the owner changes avatar/background, personal stickers show only on the user's own photos; Quiet (weight loss) never uses body photos for avatar/background on shared outputs; uploaded items can be reported like check-ins.
- No emoji; use OIcon. Light/dark, 135% type. Run tsc and build.
```
