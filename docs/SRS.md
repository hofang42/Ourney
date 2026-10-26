# Ourney — Software Requirements Specification (SRS) & Project Context

> Phiên bản 1.0 · 2026-10-16 · Chủ dự án: @hofang42 · Contributors: @thydynh03, @lken1514
> **Đọc file này trước tiên.** Đây là bản tóm tắt duy nhất bạn cần để hiểu Ourney là gì, vì sao làm, làm tới đâu và làm theo luật nào. Tài liệu chi tiết được liên kết ở từng mục.

---

## 1. Giới thiệu

### 1.1 Ý tưởng trong một câu
**Ourney = "Locket cho mục tiêu".** Bạn tạo một *hành trình* (giảm cân, học tiếng Anh, tập luyện, du lịch, hoặc tự đặt), mỗi ngày chụp **một ảnh check-in** để chứng minh mình vẫn đang đi tiếp, đi một mình hoặc **cùng bạn bè trong một nhóm**. Đến các mốc (7 ngày, 30 ngày, về đích) thì khoe bằng **share card** đẹp như Strava.

### 1.2 Vì sao làm
- App chuyên từng ngách (Strava, Duolingo, MyFitnessPal, Polarsteps) rất mạnh trong ngách của nó, nhưng **không có app nào gom "mọi loại hành trình + bằng chứng hằng ngày + nhóm bạn thân"**.
- Locket/BeReal đã chứng minh **chụp ảnh nhanh trong vòng bạn thân** tạo thói quen mạnh. Ourney gắn cơ chế đó vào **mục tiêu có thời hạn**, nên có lý do để quay lại mỗi ngày (streak, nhóm đang chờ mình).
- Tăng trưởng không dựa vào feed công khai mà dựa vào **mời bạn vào nhóm**, **share card ra Instagram/Zalo/Facebook**, và **link hành trình đã xong có nút "Làm theo"** (FR-H).
- Hành trình đã trải qua (đi xong trong app, hoặc đi từ trước khi có app) có **"đời sau"**: viết lời kể, chia sẻ cho bạn bè, nhận phản hồi, cho người khác làm theo, và biết câu chuyện công khai đã đến với bao nhiêu người (lượt xem, lượt thích, lượt làm theo) ([09-journey-sharing.md](09-journey-sharing.md)).

### 1.3 Phạm vi v1 (MVP)
App **iOS (ưu tiên) + Android**, một codebase Flutter, backend Supabase. **v1 chỉ có ảnh** (chưa có clip), chưa có push, widget, universal link vì chưa có tài khoản Apple Developer trả phí. Chi tiết ở §4 và §7.

### 1.4 Thuật ngữ
| Thuật ngữ | Nghĩa |
|---|---|
| **Journey** (hành trình) | Một mục tiêu có ngày bắt đầu, thời lượng (hoặc mở), loại `solo` hoặc `group` |
| **Template** | Mẫu soạn sẵn tạo ra journey (metric, thời lượng, mặc định riêng tư). Journey **copy** template, không tham chiếu |
| **Check-in** | Một ảnh (+ caption, metric tuỳ chọn) cho một journey trong một **ngày địa phương**. Mỗi người tối đa 1 check-in/ngày/journey, chụp lại thì thay thế |
| **local_date** | Ngày theo múi giờ của journey (không phải múi giờ của điện thoại) |
| **Streak** | Số ngày liên tiếp có check-in. Vẫn giữ nếu hôm nay chưa check-in nhưng hôm qua có |
| **Member** | Thành viên journey nhóm, vai trò `owner` hoặc `member` |
| **Share card** | Ảnh 1080×1920 / 1080×1350 render trên máy để chia sẻ ra ngoài |
| **Local-only mode** | App chạy không cần server (khi chưa cấu hình Supabase): solo journey dùng được, nhóm thì không |
| **Friend** (bạn bè) | Quan hệ **hai chiều**, phải được chấp nhận. Không có follow một chiều |
| **Journey share** | Quyền xem một journey của chủ cấp cho từng người bạn; thu hồi được từng người |
| **Retold journey** (kể lại) | Journey tạo từ ảnh cũ trong máy, nhãn `Imported` / `Kể lại`, không tính streak |
| **Follow-along** (làm theo) | Tạo journey mới từ **khung lộ trình** của journey đã xong (template, thời lượng, nhịp, chỉ số). Không sao chép ảnh/số liệu |
| **Inbox** (hộp thư) | Nơi gộp câu trả lời ảnh, lời mời xem journey, lời mời kết bạn; mở thành chat 1-1 |

## 2. Mô tả tổng quan

### 2.1 Người dùng
| Persona | Nhu cầu |
|---|---|
| **Linh, 22, giảm cân** | Muốn có động lực mỗi ngày, cần riêng tư cho ảnh cơ thể và số kg |
| **Nam, 25, học tiếng Anh** | Học cùng 3 người bạn, muốn thấy ai đã học hôm nay |
| **Nhóm 5 bạn đi Đà Lạt** | Mỗi ngày một ảnh, cuối chuyến có recap để đăng |

### 2.2 Vòng lặp sản phẩm
1. **Thói quen**: mở app vào thẳng camera → check-in trong ≤ 3 chạm → streak +1 → nhắc nhở hôm sau.
2. **Nhóm**: thấy bạn đã check-in → tự thấy phải check-in.
3. **Lan truyền**: mốc 7/30/về đích → share card → bạn bè hỏi → link/mã mời → tham gia nhóm.

### 2.3 Ràng buộc
| Ràng buộc | Hệ quả |
|---|---|
| Team **không có Mac** | iOS chỉ build trên **GitHub Actions macOS runner** (miễn phí vì repo public). Không ai mở Xcode. Native iOS chỉ sửa file text (`Info.plist`, `project.pbxproj`) |
| **Không có tài khoản Apple trả phí** ở v1 | `.ipa` **chưa ký** → mỗi người tự ký bằng Apple ID free (Sideloadly/zsign), hết hạn sau 7 ngày. Không push, không widget, không universal link |
| **Repo public** | Không bao giờ commit secret. Anon key của Supabase là public theo thiết kế, nên **RLS là lớp bảo vệ duy nhất** |
| Người dùng Việt Nam | Mặc định tiếng Việt, có tiếng Anh. Font hỗ trợ dấu (Be Vietnam Pro) |

### 2.4 Giả định
- Người dùng có iPhone iOS 15+ hoặc Android 8+ (chốt cụ thể trong ADR của platform).
- Nhóm nhỏ (≤ 10 người), quen biết nhau ngoài đời.

## 3. Yêu cầu chức năng (v1)

Mã yêu cầu giữ ổn định để truy vết trong `docs/TRACE.md`, issue và test. **P1** = bắt buộc ở v1, **P2** = nên có.

### FR-A — Tài khoản & hồ sơ
| ID | Yêu cầu | Ưu tiên |
|---|---|---|
| FR-A1 | Đăng nhập bằng email OTP (mã 6 số) | P1 |
| FR-A2 | Hồ sơ: username (`[a-z0-9_.]{3,20}`, duy nhất), tên hiển thị, avatar | P1 |
| FR-A3 | Onboarding ≤ 3 màn. Xin quyền camera/thông báo **đúng ngữ cảnh** (lúc cần, không xin ngay khi mở app) | P1 |
| FR-A4 | Xoá tài khoản ngay trong app → xoá dữ liệu + toàn bộ ảnh trên server | P1 |
| FR-A5 | Local-only mode khi chưa cấu hình server | P1 |

### FR-B — Journey
| ID | Yêu cầu | Ưu tiên |
|---|---|---|
| FR-B1 | Tạo journey từ 4 template (Giảm cân, Học tiếng Anh, 30 ngày tập luyện, Chuyến đi) hoặc Custom | P1 |
| FR-B2 | Chọn solo/nhóm, thời lượng, metric tuỳ chọn, emoji, tiêu đề | P1 |
| FR-B3 | Tối đa **3 journey đang chạy** mỗi người (server chặn, client báo trước) | P1 |
| FR-B4 | Timeline dạng **lưới lịch**: mỗi ô là ảnh của ngày, ngày lỡ hiện ô trống nét đứt | P1 |
| FR-B5 | Hiện streak hiện tại, streak dài nhất, % hoàn thành, ngày thứ N/M | P1 |
| FR-B6 | Kết thúc / lưu trữ journey. Journey đã kết thúc thì chỉ đọc | P1 |
| FR-B7 | Giảm cân: **mặc định ẩn số kg và làm mờ ảnh khi share ra ngoài** | P1 |

### FR-C — Check-in (camera-first)
| ID | Yêu cầu | Ưu tiên |
|---|---|---|
| FR-C1 | App mở vào **màn camera**, có chip chọn journey (nhớ journey vừa dùng) | P1 |
| FR-C2 | Chụp, đổi camera trước/sau, flash | P1 |
| FR-C3 | Chọn ảnh từ thư viện được, nhưng gắn nhãn **"từ thư viện"** | P1 |
| FR-C4 | Sau khi chụp: caption ≤ 140 ký tự, giá trị metric (nếu có) → **Đăng**. Tổng ≤ 3 chạm | P1 |
| FR-C5 | Nén trên máy: ảnh 1080px JPEG q70 + thumbnail | P1 |
| FR-C6 | **Offline-first**: lưu và hiện ngay trên máy, upload qua hàng đợi, tự thử lại | P1 |
| FR-C7 | 1 check-in/ngày/journey/người. Chụp lại thì thay thế | P1 |
| FR-C8 | Animation "đóng dấu" + haptic + streak +1. Confetti ở mốc 7/30/về đích | P1 |
| FR-C9 | Khi đã ở ≥ 2 journey: đăng 1 ảnh cho nhiều journey | P2 (v0.2) |

### FR-D — Nhóm
| ID | Yêu cầu | Ưu tiên |
|---|---|---|
| FR-D1 | Mời bằng mã 8 ký tự / link `ourney://join/<code>`. Có ô nhập mã thủ công | P1 |
| FR-D2 | Tối đa **10 thành viên**. Vai trò owner/member | P1 |
| FR-D3 | Màn **"Hôm nay"**: ai đã/chưa check-in, ảnh mới nhất của từng người, streak từng người | P1 |
| FR-D4 | Reaction emoji (🔥 💪 👏 ❤️ 😂) trên check-in. **Không có comment công khai ở v1** (trả lời riêng bằng ảnh trên journey được chia sẻ: FR-H6) | P1 |
| FR-D5 | **Không xếp hạng theo kết quả** (kg…), chỉ hiện mức độ đều đặn | P1 |
| FR-D6 | Owner: đổi mã mời, xoá thành viên, kết thúc journey | P1 |
| FR-D7 | Vòng đời: xem bảng §3.1 | P1 |

#### 3.1 Vòng đời journey nhóm
| Tình huống | Quy tắc |
|---|---|
| Tham gia muộn | Tiến độ cá nhân tính từ ngày tham gia. Xem được lịch sử nhóm |
| Rời nhóm | Check-in của người đó bị ẩn. Tham gia lại thì hiện lại |
| Owner rời / xoá tài khoản | Chuyển owner cho người tham gia sớm nhất. Không còn ai thì journey bị lưu trữ |
| Xoá journey | Chỉ được xoá khi nhóm còn mỗi owner. Còn người khác thì chỉ "kết thúc" được |
| Lộ mã mời | Owner đổi mã, mã cũ hết hiệu lực |
| Block | Không join được nhóm có người đã block mình. Đã cùng nhóm thì ẩn nội dung của nhau |

### FR-E — Chia sẻ
| ID | Yêu cầu | Ưu tiên |
|---|---|---|
| FR-E1 | Share card 1 theme, 2 cỡ (story 1080×1920 có vùng an toàn cho IG; feed 1080×1350): số lớn + ảnh + logo | P1 |
| FR-E2 | Chia sẻ qua share sheet hệ thống. Tự gợi ý ở các mốc | P1 |
| FR-E3 | Link xem read-only cho **journey solo đã kết thúc** (hoặc journey kể lại đã lên kệ) có visibility `link` (token thu hồi được). Journey đang chạy chỉ chia sẻ cho bạn bè (FR-H3). **Journey nhóm/cặp đôi** có link công khai khi đã kết thúc, do owner bật, chỉ gồm ảnh của thành viên đã đồng ý (FR-H14) | P1 |
| FR-E4 | Instagram Stories deep link, recap collage | P2 |

### FR-F — An toàn & tuân thủ
| ID | Yêu cầu | Ưu tiên |
|---|---|---|
| FR-F1 | Report check-in/người dùng/**tin nhắn** (lý do: spam, khoả thân, quấy rối, tự hại, an toàn trẻ em, khác) → `moderation_queue` | P1 |
| FR-F2 | Block / unblock. Nội dung đã report bị ẩn ngay với người report. Block = hủy kết bạn + mất quyền xem journey đã chia sẻ cho nhau + ẩn cuộc trò chuyện | P1 |
| FR-F3 | EULA (không dung thứ nội dung xấu), privacy policy, trang liên hệ | P1 |

### FR-G — Nhắc nhở
| ID | Yêu cầu | Ưu tiên |
|---|---|---|
| FR-G1 | Thông báo local theo giờ user chọn cho từng journey. Lên lịch cuốn chiếu 14 ngày, tổng ≤ 64 thông báo chờ (giới hạn của iOS) | P1 |
| FR-G2 | 21:00 cảnh báo "streak sắp mất" nếu hôm nay chưa check-in | P1 |
| FR-G3 | Nudge bạn bè, push thật (gồm push lời mời kết bạn, journey được chia sẻ, tin nhắn) | P2 (cần tài khoản Apple) |

### FR-H — Bạn bè & chia sẻ hành trình đã trải qua
Quyết định S1–S40, luồng và đề xuất dữ liệu: [09-journey-sharing.md](09-journey-sharing.md). Màn hình: [07-SDS-ui-design.md](07-SDS-ui-design.md) §5.9. v1 áp cho journey **solo** (gồm journey kể lại), **nhóm và cặp đôi** (FR-H14–H16).

| ID | Yêu cầu | Ưu tiên |
|---|---|---|
| FR-H1 | Bạn bè **hai chiều**: gửi lời mời qua link/QR hoặc đúng @username, bên kia chấp nhận. Không đồng bộ danh bạ, không gợi ý. Số bạn chỉ chủ tài khoản thấy | P1 |
| FR-H2 | **Kể lại** journey cũ từ ảnh trong máy, nhãn `Imported` hiện cả với người xem, không tính/không hiện streak. Lối vào ở màn journey đầu tiên, Hub `+`, đầu Kệ | P1 |
| FR-H3 | Chia sẻ journey cho bạn bè: tick sẵn tất cả, bỏ tick được; **mẫu nhạy cảm không tick sẵn ai**. Journey đang chạy chia sẻ được, người xem thấy ảnh mới | P1 |
| FR-H4 | Trước khi chia sẻ: ẩn kỳ/ảnh, ẩn số liệu, viết lời kể (tiêu đề, giới thiệu, điều rút ra, ảnh bìa) | P1 |
| FR-H5 | Người được chia sẻ thấy journey trong segment `Shared with me` của Hub (nhóm `From friends`; journey công khai đã thích nằm ở nhóm `Saved`, FR-H12). **Không có feed** | P1 |
| FR-H6 | Người xem là bạn bè: reaction + **trả lời bằng ảnh** trên từng ảnh. Journey **solo**: câu trả lời chỉ chủ thấy. Journey **nhóm/cặp đôi**: câu trả lời đi tới thành viên đã chia sẻ hoặc tác giả ảnh theo FR-H16, chỉ người nhận thấy. Không chia sẻ lại được. Trả lời bằng clip ≤ 5s đi cùng đợt có clip (v0.2, §7) | P1 |
| FR-H7 | **Hộp thư** (icon trên header Hub): trả lời, reaction, lời mời xem journey, lời mời kết bạn, yêu cầu đồng ý chia sẻ của nhóm. Từ một câu trả lời mở **chat 1-1** (chữ ≤ 500, ảnh; clip ≤ 5s từ v0.2 cùng với clip ở §7), có `Seen`, chặn, báo cáo — chat chữ + ảnh **làm đủ ở v1**. v1 chưa có push: số chưa đọc cập nhật khi mở app. Không giới hạn số bạn; tin nhắn được giữ — xóa cuộc trò chuyện hay `Delete for me` chỉ áp cho **phía người xóa**, bên kia giữ nguyên lịch sử | P1 |
| FR-H8 | **Làm theo**: từ journey đã xong (trong app hoặc link công khai) tạo journey mới với cùng template, thời lượng, nhịp, tên chỉ số, ghi "Based on {name}'s journey" (bỏ được). Không sao chép ảnh, caption, số liệu, thành viên. Nguồn là nhóm/cặp đôi → tạo journey cùng kiểu, người làm theo là owner rồi mời người của mình. Trang link có nút cài app rồi mở sẵn lộ trình | P1 |
| FR-H9 | Thu hồi: dừng chia sẻ cho tất cả, gỡ từng người, `Reset link`. Hủy kết bạn = mất quyền xem; journey làm theo của người khác vẫn giữ | P1 |
| FR-H10 | Journey có link công khai có **thống kê chỉ chủ thấy** (ngoại lệ: journey **nhóm/cặp đôi** thì **mọi thành viên** xem được số liệu tổng của Insights, nhưng tên người thích một ảnh chỉ tác giả ảnh đó thấy, FR-H15; người ngoài vẫn không bao giờ thấy): lượt xem (số người, mỗi người tính một lần trong toàn kỳ, chỉ là số, không bao giờ lộ ai đã xem; biểu đồ theo ngày tính riêng từng ngày), lượt thích (kèm tên người thích, tách bạn bè/người lạ), lượt làm theo. Xem theo từng journey (Insights) và tổng trong Hồ sơ (gồm journey solo của mình và journey nhóm/cặp đôi mình là thành viên) | P1 |
| FR-H11 | Công tắc `Show counts` theo journey (mặc định tắt): người xem thấy lượt thích + lượt làm theo. Lượt xem không bao giờ công khai | P1 |
| FR-H12 | Người lạ **có tài khoản** mở link trong app: thích (nếu `Let anyone react`), làm theo, gửi lời mời kết bạn (nếu `Allow friend requests from viewers`). Không trả lời ảnh, không chat. Thích → journey được lưu vào `Saved`. Web chưa đăng nhập không thích được | P1 |
| FR-H13 | Lời mời kết bạn từ người lạ vào mục riêng, không tính chưa đọc, tối đa 20 lời mời / người gửi / ngày. `Let anyone react` mặc định bật với mẫu thường. Mẫu nhạy cảm: 3 công tắc công khai mặc định tắt + cảnh báo; em bé: người lạ không bao giờ thích/mời kết bạn | P1 |
| FR-H14 | Journey **nhóm/cặp đôi** chia sẻ được ra ngoài: thành viên nào cũng đề nghị được, mỗi thành viên còn lại nhận yêu cầu đồng ý. Chia sẻ có hiệu lực ngay; **ảnh của người chưa đồng ý/từ chối không bao giờ hiện với người ngoài nhóm**; đồng ý sau thì hiện | P1 |
| FR-H15 | Thành viên rút ảnh của mình khỏi chia sẻ bất cứ lúc nào; rời nhóm thì ảnh ẩn; thành viên mới nhận yêu cầu đồng ý. Mỗi thành viên chia sẻ cho bạn bè của mình; link công khai, `Show counts`, công tắc công khai và lời kể do owner quản lý; mọi thành viên xem số liệu tổng của Insights, **tên người thích chỉ tác giả ảnh thấy** (thành viên khác chỉ thấy số) | P1 |
| FR-H16 | Trả lời bằng ảnh trên journey nhóm gửi tới thành viên đã chia sẻ cho người xem (hoặc tác giả ảnh nếu là bạn của người xem). Người xem chỉ thấy tên thành viên đã đồng ý; không thấy thống kê chuỗi từng người | P1 |

## 4. Yêu cầu phi chức năng

| ID | Hạng mục | Yêu cầu |
|---|---|---|
| NFR-1 | Hiệu năng | Mở app → camera sẵn sàng < 1s (warm), < 2s (cold). Đăng check-in < 5s trên máy |
| NFR-2 | Offline | Mọi thao tác solo chạy được khi mất mạng, tự đồng bộ lại |
| NFR-3 | Bảo mật | RLS bật trên **mọi** bảng. Bucket private + signed URL TTL 1h. Không lộ URL ảnh public. Không có secret trong repo |
| NFR-4 | Riêng tư | Ảnh cơ thể/số kg mặc định riêng tư. Xoá tài khoản thì xoá thật |
| NFR-5 | Accessibility | Dynamic Type/Text scale lớn không vỡ layout, Reduce Motion, VoiceOver/TalkBack cho nút chụp, contrast AA, trạng thái không chỉ dựa vào màu |
| NFR-6 | i18n | vi (mặc định), en |
| NFR-7 | Chi phí | 1k DAU nằm trong Supabase Pro ($25/tháng). Ảnh ~250KB, thumbnail riêng, cache theo path |
| NFR-8 | Chất lượng | `flutter analyze` sạch. Logic domain/SQL có test. CI xanh mới được merge |

## 5. Kiến trúc & công nghệ

```
Flutter app (iOS + Android)
 ├─ lib/features/*     UI theo tính năng (Riverpod + go_router)
 ├─ lib/data/*         drift (SQLite) + hàng đợi upload + sync ←→ supabase_flutter
 └─ packages/ourney_core   Dart thuần: model, streak, local_date, validation, templates (test trên Linux)
                 │
Supabase: Auth (email OTP) · Postgres + RLS + RPC · Storage (bucket media private) · Edge Functions
GitHub Actions: ci (analyze/test) · ios (.ipa chưa ký trên macOS runner) · android (.apk)
```

| Lớp | Công nghệ |
|---|---|
| App | Flutter 3.47.7 / Dart 3.13, Riverpod, go_router, drift, camera, image_picker, flutter_image_compress, share_plus, flutter_local_notifications, confetti |
| Backend | Supabase (Postgres, RLS, RPC SECURITY DEFINER, Storage, Edge Functions Deno), pgTAP |
| Build | GitHub Actions (macOS cho iOS, Ubuntu cho Android/test). MobAI ios-builder là tuỳ chọn cho dev loop trên iPhone |
| Thiết kế | Design system v0 ([03-design-system.md](03-design-system.md)): coral `#FF4D6D` + violet `#7C5CFF`, Be Vietnam Pro + Bricolage Grotesque, nút chunky, motion có spring |

**Hợp đồng dữ liệu** (bắt buộc đọc trước khi code data/backend): [contracts/schema.md](contracts/schema.md), [contracts/streak_vectors.json](contracts/streak_vectors.json), `packages/ourney_core/lib/src/models.dart`, `.../contracts/repositories.dart`. Chỉ đổi qua PR riêng cho contract.

## 6. Cách làm việc (dành cho contributor)

### 6.1 Cấu trúc repo & quyền sở hữu
| Thư mục | Nội dung | Ghi chú |
|---|---|---|
| `apps/mobile/lib/app`, `shared`, `l10n`, `pubspec.yaml` | Shell, theme, router, widget dùng chung | Thêm dependency qua PR riêng |
| `apps/mobile/lib/features/<x>` | Mỗi tính năng một thư mục, tự export `routes.dart` | Không sửa feature của người khác trong cùng PR |
| `apps/mobile/lib/data` | drift, repository, sync | Implement interface trong `ourney_core` |
| `apps/mobile/ios`, `android` | Cấu hình native | Chỉ sửa file text. iOS build trên CI |
| `packages/ourney_core` | Logic thuần | TDD, chạy `dart test` |
| `supabase/` | Migrations, RLS, RPC, Functions, pgTAP | Migration đánh số tăng dần `NNNN_name.sql` |
| `docs/` | Spec, plan, ADR, contract | |

### 6.2 Quy trình
1. Lấy issue (có acceptance criteria + mã FR). Tạo branch `feat/<slug>` / `fix/<slug>`.
2. Code + test. Chạy `flutter analyze && flutter test` (app) / `dart test` (core) / `supabase test db` (backend).
3. Mở PR theo template: làm gì, vì sao, bằng chứng test, **video/ảnh trên iPhone** (bắt buộc với UI), trên Android (hoặc ghi "android-verify pending").
4. Review: agent `code-reviewer` → (nếu đụng `supabase/` hoặc auth) `security-auditor` → 1 người duyệt → squash merge.
5. Commit theo Conventional Commits. Rebase lên `main` trước khi merge.

### 6.3 Chạy dự án
```bash
# Core (Linux/WSL)
cd packages/ourney_core && dart pub get && dart test
```
```bash
# App (Android emulator/thiết bị). Bỏ --dart-define thì chạy local-only mode
cd apps/mobile && flutter pub get && flutter run --dart-define-from-file=env.json
```
```bash
# Backend local (Docker trong WSL)
supabase start && supabase test db
```
**iOS**: merge vào `main` → workflow `ios` → tải artifact `Ourney-unsigned-ipa` → tự ký theo [platform/ios.md](platform/ios.md).

### 6.4 Luật bất di bất dịch
- ❌ Không commit secret (service_role, SMTP key, keystore, Apple ID). Dùng GitHub Secrets / `env.json` (đã gitignore).
- ❌ Không tạo bảng mới mà không có RLS và pgTAP test.
- ❌ Không xếp hạng người dùng theo kết quả cơ thể.
- ❌ Không bịa API: thư viện/API mới phải có link docs trong PR.
- ✅ iOS là ưu tiên: bug chỉ có trên iOS **chặn** release, bug chỉ có trên Android thì không.

## 7. Ngoài phạm vi v1 → lộ trình
| v0.2 (khi có tài khoản Apple $99) | v0.3+ |
|---|---|
| Clip ≤ 5s, widget màn hình chính (ảnh mới nhất của nhóm), push + nudge (gồm push tin nhắn, lời mời kết bạn), universal/App Links, Sign in with Apple, đăng 1 ảnh cho nhiều journey, comment, streak freeze | Discover / feed công khai (vẫn **không** làm ở v1, kể cả khi đã có bạn bè), thử thách tuần, leaderboard opt-in, Year-in-review, HealthKit, bản đồ chuyến đi, gói trả phí |

## 8. Tiêu chí thành công v1
- Beta `v0.1.0`: `.ipa` chưa ký + `.apk` trên GitHub Release.
- Dogfood 14 ngày với một nhóm có sẵn 10–15 người: **D14 retention ≥ 40%**, ≥ 70% ngày có check-in ở những người còn hoạt động.
- 0 bug Blocker/Critical. Security review không còn mục High.

## 9. Tài liệu liên quan
| File | Nội dung |
|---|---|
| [01-analysis.md](01-analysis.md) | Phân tích thị trường, khả thi (phần kỹ thuật Swift đã cũ) |
| [02-requirements-v2.md](02-requirements-v2.md) | Requirement chi tiết + phản biện (§9–10 là scope đã chốt) |
| [03-design-system.md](03-design-system.md) | Màu, font, motion, share card |
| [04-implementation-plan-v1.md](04-implementation-plan-v1.md) | Plan triển khai đa agent, các giai đoạn, wave |
| [05-platform-plan-ios-android.md](05-platform-plan-ios-android.md) | Checklist iOS/Android, ưu tiên iOS |
| [07-SDS-ui-design.md](07-SDS-ui-design.md) | Đặc tả giao diện: màn hình, luồng, trạng thái |
| [09-journey-sharing.md](09-journey-sharing.md) | Bạn bè, chia sẻ hành trình đã trải qua, hộp thư, làm theo (FR-H) + đề xuất dữ liệu |
| [contracts/](contracts/) | Hợp đồng dữ liệu |
