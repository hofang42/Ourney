# ADR 0002: Email hỗ trợ cấu hình được và văn bản EULA / privacy

- Status: **Proposed** (chờ @hofang42 duyệt; chưa có phê duyệt pháp lý nào)
- Owner: @hofang42
- Related: `docs/TASKS.md` H4 và §4, `apps/mobile/lib/features/safety/README.md`, FR-F3 (`docs/SRS.md`)

## Bối cảnh

Apple Guideline 1.2 yêu cầu có điều khoản chặn nội dung phản cảm và kênh liên hệ hoạt động. Màn Liên hệ hiện hiển thị địa chỉ cứng `support@ourney.app` (placeholder của C3, chưa chắc tồn tại). Văn bản EULA/privacy là **bản nháp** do dev viết, chưa ai duyệt. TASKS §4 đặt mặc định: email hỗ trợ là email của @hofang42 cho tới khi có domain; EULA/privacy dùng bản nháp, duyệt trước H5.

## Thay đổi kỹ thuật đã làm (không cần duyệt để merge)

- Địa chỉ lấy từ `--dart-define=SUPPORT_EMAIL=...` qua `AppConfig.supportEmail` (cùng cách với `SUPABASE_URL`). Không đặt hoặc đặt rỗng thì dùng `support@ourney.app`. Một nơi duy nhất: `supportEmailProvider` (`lib/features/safety/data/safety_providers.dart`), màn Liên hệ (hiển thị, mailto, sao chép) đều đọc từ đó.
- `ios.yml` / `android.yml` ghi `SUPPORT_EMAIL` vào file dart-define khi repo secret `SUPPORT_EMAIL` có giá trị; không có thì không thêm khoá.
- Test: `test/app/providers_test.dart` (fallback, trim/blank, provider), `test/features/safety/safety_pages_test.dart` (màn Liên hệ dùng giá trị cấu hình).

## Văn bản hiện tại (`l10n/safety_{vi,en}.arb`, cập nhật `kLegalLastUpdated` = 2026-10-16)

**Điều khoản sử dụng (`safety_eula1..6`)**

| Khoá | Nội dung tóm tắt |
|---|---|
| `eula1` | Tạo tài khoản/dùng app là đồng ý; không đồng ý thì đừng dùng |
| `eula2` | Không dung thứ nội dung phản cảm và người dùng lạm dụng: khoả thân/tình dục, quấy rối/bắt nạt/đe doạ, thù ghét, bạo lực, cổ vũ tự hại, spam/lừa đảo, vi phạm pháp luật hoặc quyền người khác |
| `eula3` | Ảnh, chú thích, số liệu vẫn thuộc người dùng; cho phép Ourney lưu và hiển thị cho người họ chọn (thành viên nhóm, người có link công khai); người dùng chịu trách nhiệm nội dung |
| `eula4` | Báo cáo check-in/người dùng, chặn bất kỳ ai; **cam kết xem xét báo cáo trong 24 giờ**, gỡ nội dung vi phạm và xoá tài khoản người đăng |
| `eula5` | Có thể khoá/xoá tài khoản vi phạm không cần báo trước; người dùng tự xoá tài khoản trong Hồ sơ |
| `eula6` | Cung cấp "như hiện có", không thay thế tư vấn y tế/dinh dưỡng/tập luyện; thay đổi điều khoản sẽ thông báo trong app |

**Chính sách quyền riêng tư (`safety_privacy1..6`)**

| Khoá | Nội dung tóm tắt |
|---|---|
| `privacy1` | Lưu: email (đăng nhập), tên hiển thị/username/avatar, journey, check-in (ảnh, chú thích, số liệu như cân nặng, thời điểm chụp), reaction, báo cáo và danh sách chặn |
| `privacy2` | Journey riêng tư chỉ mình thấy; nhóm chỉ thành viên thấy; link công khai chỉ hiện phần người dùng bật, có thể ẩn số liệu / làm mờ ảnh; chế độ trên máy không rời điện thoại |
| `privacy3` | Không bán dữ liệu, không quảng cáo, không dùng ảnh cho mục đích khác |
| `privacy4` | Nhắc check-in là thông báo cục bộ |
| `privacy5` | Hồ sơ > Xoá tài khoản xoá vĩnh viễn tài khoản, check-in, ảnh trên server; chủ nhóm thì quyền chuyển cho người vào sớm nhất |
| `privacy6` | Câu hỏi về quyền riêng tư: xem trang Liên hệ |

Các chuỗi giao diện khác: `safety_eulaAccept{Title,Intro,Checkbox,Button}` (màn đồng ý), `safety_contact*` (màn Liên hệ).

## Câu hỏi mở cho owner

1. Email hỗ trợ thật là gì (email cá nhân của @hofang42 theo mặc định §4, hay alias trên domain riêng)? Hộp thư này có được theo dõi hằng ngày không? Cam kết "xem xét trong 24 giờ" (`eula4`) chỉ giữ được khi có người đọc thư và dùng được báo cáo trong app.
2. Có chấp nhận hiển thị email cá nhân công khai trong app và App Store không? Nếu không, cần domain + alias trước H5.
3. Pháp nhân / người vận hành là ai? Văn bản hiện không nêu tên đơn vị, luật áp dụng hay nơi giải quyết tranh chấp.
4. Có thu thập thêm dữ liệu ngoài danh sách `privacy1` không (log lỗi, retention theo N5, địa chỉ IP do Supabase, dữ liệu qua nhà cung cấp mail Resend)? Nếu có phải bổ sung, và nêu nhà cung cấp xử lý (Supabase, Resend).
5. Thời gian lưu giữ dữ liệu và xử lý báo cáo/nội dung đã gỡ: có cần nêu cụ thể không?
6. Có đối tượng dưới 13/16 tuổi không? Cần quy định độ tuổi tối thiểu (Apple age rating, GDPR/COPPA-like).
7. Cần bản dịch tiếng Anh nào là bản chính (hiện `vi` là mặc định)? Khi hai bản lệch nhau thì bản nào ưu tiên?
8. Có cần người có chuyên môn pháp lý rà soát trước khi lên cửa hàng ứng dụng, hay chỉ dùng cho dogfood sideload (H5 v0.1.0 là IPA/APK tự ký, không qua App Store)?

## Quy trình quyết định

1. @hofang42 trả lời các câu hỏi trên (comment trong PR của ADR này hoặc sửa trực tiếp).
2. Nếu cần đổi chữ: sửa `safety_vi.arb` và `safety_en.arb` (cùng khoá), chạy `dart run tool/gen_l10n.dart` trong `apps/mobile`, commit file sinh ra, **bump `kLegalLastUpdated`**. PR này thuộc vùng @nguyenductien-qnm (`features/safety`), @hofang42 là reviewer.
3. Đặt secret `SUPPORT_EMAIL` (repo secret) cho email thật rồi build lại IPA/APK (xem `docs/runbooks/hosted-supabase.md` §2).
4. Khi đã chốt: đổi **Status** thành `Accepted (ngày, người duyệt)` và ghi lại quyết định, kèm phạm vi duyệt (chỉ dogfood hay cả cửa hàng ứng dụng). Việc duyệt phải do chính owner (hoặc luật sư) xác nhận; tài liệu này không thay thế phê duyệt đó.
5. Hạn chót: trước H5 (`v0.1.0`). Nếu chưa kịp, release dùng bản nháp hiện tại và email mặc định theo TASKS §4, ghi rõ trong release notes.

## Hệ quả

- Đổi email hỗ trợ không cần sửa code, chỉ đặt secret và build lại.
- Bản nháp pháp lý vẫn có thể bị thay đổi sau; mỗi lần thay đổi phải bump `kLegalLastUpdated`. Hiện app chưa bắt người dùng đồng ý lại khi điều khoản đổi (cờ `safety.eulaAccepted` chỉ là true/false), cần cân nhắc nếu thay đổi lớn.
