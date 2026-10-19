---
name: design-ref
description: Đọc bảng thiết kế UI của Ourney trong apps/mobile/assets/design_personas/ (6 persona × 3 màn timeline, camera HUD, share/squad) — cắt đúng màn cần làm, phóng to để xem chi tiết, rồi đối chiếu với token và spec (trỏ tới nguồn, không chép). Dùng trước khi code hoặc review một màn timeline, camera HUD, share card hay squad wall của persona; khi task trong docs/TASKS.md §3 (F, Q, R, S, M, D, Z, J) trỏ tới một bản thiết kế; hoặc khi user gõ /design-ref.
argument-hint: "[persona 1-6 | PersonaSkinId] [timeline | camera | share | all]"
allowed-tools:
  - Bash(python3 ${CLAUDE_SKILL_DIR}/scripts/crop.py *)
---

# Design ref — đọc bảng thiết kế persona (Ourney)

Yêu cầu: $ARGUMENTS (trống thì lấy persona và màn từ dòng task trong `docs/TASKS.md` §3, cột "Bản thiết kế"; vẫn không rõ thì hỏi user).

**Skill khác rule.** Skill này chỉ là quy trình đọc ảnh thiết kế. Rule UI nằm ở `CLAUDE.md` và `.agent/rules/adaptive-persona-ui.md`; rule thắng nếu ảnh hoặc skill mâu thuẫn với rule.

## Bản đồ bảng thiết kế

| # | `PersonaSkinId` | Template | File | Trái | Giữa | Phải |
|---|---|---|---|---|---|---|
| 1 | `quietTransformer` | `weightLoss` | `persona_1_quiet_transformer.jpg` | camera | timeline | share |
| 2 | `accountabilitySquad` | `englishDaily` | `persona_2_accountability_squad.jpg` | timeline | camera | squad (share) |
| 3 | `memoryCollectors` | `travel` | `persona_3_memory_collectors.jpg` | timeline | camera | share |
| 4 | `coupleRituals` | `custom` 2 người / 💞 | `persona_4_couple_rituals.jpg` | timeline | camera | share |
| 5 | `aestheticFlexer` | `workout30` | `persona_5_aesthetic_flexers.jpg` | timeline | camera | share |
| 6 | `minimalistHabit` | `custom` | `persona_6_minimalist_habit.jpg` | camera | timeline | share |

Mỗi bảng là ảnh 1376×768, ba điện thoại xếp ngang. Thứ tự trên khớp với `PERSONAS` trong `scripts/crop.py`. Tên variant của từng màn nằm ở `apps/mobile/lib/app/theme/persona_theme.dart` (`TimelineLayoutVariant`, `CameraHudVariant`, `ShareCardVariant`) và bảng §4 của `CLAUDE.md`.

## Quy trình

1. **Cắt màn cần làm:** `python3 ${CLAUDE_SKILL_DIR}/scripts/crop.py <persona> <màn> --out <thư mục>`. Có scratchpad thì `--out` vào scratchpad; không thì bỏ `--out` (ghi vào thư mục tạm). Script in đường dẫn PNG đã phóng 2×.
2. **Xem ảnh:** mở từng PNG bằng tool Read. Cần toàn cảnh 3 màn thì Read thẳng file `.jpg` trong `apps/mobile/assets/design_personas/`. Thiếu Pillow thì script in đường dẫn bảng gốc; không có `python3` thì lấy tên file ở bảng trên. Cả hai trường hợp đều đọc cả bảng.
3. **Đọc spec chữ của persona:** mục persona tương ứng trong `.agent/rules/adaptive-persona-ui.md` §5 (màn, chữ, palette) và `docs/06-adaptive-persona-ui-system.md` §2–3. Chỉ ghi số mục, không chép.
4. **Viết lại màn thành checklist** trước khi code, theo thứ tự trên xuống dưới:
   - Bố cục: từng khối, căn lề, tỉ lệ (ô vuông, 9:16, lưới mấy cột).
   - Thành phần: cái nào đã có trong `lib/shared/` hoặc `persona_theme.dart`, cái nào phải vẽ (`CustomPainter`).
   - Chữ: mọi chuỗi đi vào ARB vi/en của feature (`apps/mobile/lib/features/README.md` §2); tiếng Việt là mặc định.
   - Dữ liệu: field nào có sẵn (`Journey.metricName/metricUnit`, `CheckIn.metricValue`, streak, ngày thứ N, thành viên nhóm hôm nay). Ảnh có số liệu mà model không có (nhiệt độ, địa điểm, pace, phút đếm giờ) thì **bỏ hoặc ghi vào task là thiếu dữ liệu**, không bịa.
   - Tương tác: chạm, chuyển màn, animation (`OurneyMotion`, Reduce Motion), haptic.
5. **Màu và kích thước lấy từ code, không lấy từ ảnh:** dùng `OurneyPersonaTheme.of(context)` (`background`, `surface`, `ink`, `primaryAccent`, `border`, `cardRadius`, `bottomLipHeight`, …). Ảnh là JPEG do AI render nên màu lệch; không đo pixel để lấy mã màu.
6. **Phải làm cả light và dark** dù bảng chỉ vẽ một chế độ (bảng persona 5 vẽ dark, các bảng khác vẽ light). Camera và ảnh full-bleed luôn nền tối.
7. **Không chép lỗi của mockup.** Ảnh do AI tạo, có các lỗi đã biết:
   - Nhãn rác trên thanh dưới: `3-tab`, `3 tab`, nút giữa ghi `...` (persona 2, 3, 4, 6). Thanh dưới luôn là Journeys · nút chụp · Squad, icon vector (`CLAUDE.md` §2).
   - Thanh dưới lệch chuẩn ở màn share persona 5 (la bàn, dấu cộng, bánh răng): bỏ qua, dùng dock chuẩn.
   - Lịch persona 6 chỉ có 5 cột, thứ `FF`, số ngày lặp và sai thứ tự: spec là lưới **7 cột**, ngày tính đúng theo `local_date`.
   - Chữ sai hoặc méo: `Flim Strip` → `Film Strip` (persona 5), nhãn Polaroid `CAMPFIRE NIGHT` bị méo (persona 3), giờ status bar `9:16` (persona 5).
   - Dữ liệu mẫu (`LINH`, `NAM`, `MINH`, `HA`, `IELTS 7.5`, `DA LAT`, kg, km): chỉ là ví dụ, lấy từ dữ liệu thật.
   - Chữ "His/Her": không giả định giới tính, dùng tên hiển thị của 2 thành viên.
   - Nút `Nudge 👋` (persona 2) cần push (FR-G3, P2): v1 không có, xem task S3.
   - Nút `Share to Instagram Story` (persona 5) là FR-E4 (P2): v1 dùng share sheet hệ thống.
8. **Kiểm tra sau khi code:** chụp màn trên máy hoặc emulator (hoặc xuất PNG từ widget test) rồi Read cạnh ảnh đã cắt ở bước 1 để so bố cục. Kiểm thêm: light/dark, rộng 320/390/430dp, chữ ×1.35, không tràn chữ tiếng Việt (`CLAUDE.md` §1, §3).
9. **Trả lời ngắn:** đường dẫn ảnh đã cắt, checklist ở bước 4, những gì bỏ qua theo bước 7, và dữ liệu còn thiếu.
