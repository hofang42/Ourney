# Tổng hợp lỗi, đợt quét 2026-11-18

File này gom kết quả của 9 worker Antigravity chạy `gemini-4-carbon-high` ngày 2026-11-18. Tám worker làm trên repo `Ourney` @ `2af3610`, worker thứ 9 làm web "Học tập" (mục 5.2). Báo cáo gốc nằm ngoài repo, ở `D:\agent-tasks\reports\`. Lỗi do owner thử trên máy thật vẫn ghi ở `docs/bugs.md`.

## 1. Tổng quan

| Worker | Việc | Kết quả | Trạng thái |
| --- | --- | --- | --- |
| `bug-scan` | Quét lỗi data layer, sync, server | 16 lỗi, Claude chấm lại 3 cao, 7 vừa, 6 thấp | Xong. 9 lỗi server giao `fix-be` |
| `bug-scan-b` | Quét lỗi camera, check-in, tạo/sửa hành trình, nhắc giờ | 15 lỗi, Claude chấm lại 1 cao, 8 vừa, 6 thấp | Xong, chưa sửa |
| `bug-scan-c` | Quét lỗi hồ sơ, cài đặt, đăng nhập, chia sẻ, an toàn | 15 lỗi và 1 lỗi ngoài phạm vi, Claude chấm lại 5 cao, 11 vừa | Xong, chưa sửa |
| `fix-be` | Sửa 8 lỗi server của `bug-scan` | 8/8 đã sửa, thêm 23 test pgTAP | Nằm ở branch `fix/backend-bugscan` của bản clone `Ourney-be`, chưa commit, chưa chạy CI |
| `fix-be2` | Sửa thêm 3 lỗi server (C1 đến C3 ở mục 1.2) | Mới sửa C1, chưa có test | Bị dừng giữa chừng khi Herdr restart |
| `ux-audit` | Rà UX và UI `apps/mobile` | 0 P0, 8 P1, 11 P2, 4 P3 (U1 đến U23) | Xong, chưa sửa |
| `stale-audit` | Rà tài liệu, asset, code, cấu hình lỗi thời | 34 mục (S1 đến S34) | Xong, chưa dọn |
| `impl-fr` | Làm màn "Đề xuất tính năng" | Review `review-fr`: ĐẠT | Branch `feat/feature-request` (`Ourney-fr`), còn 1 việc trước khi mở PR (mục 1.3) |
| `hoc-tap-uiux-2` | Rà UI web "Học tập" (project khác, không thuộc Ourney) | 13 mục: 6 cao, 5 vừa, 2 thấp | Báo cáo dừng ở danh sách vấn đề: 11 chờ sửa, 2 không sửa. Xem mục 5 |

### 1.0. Đã sửa gì, còn lại gì

Chưa có bản sửa nào lên `main`. Mọi phần "đã sửa" dưới đây đang nằm trong working tree của bản clone riêng, chưa commit và chưa chạy CI.

**Đã sửa (server, branch `fix/backend-bugscan` ở `Ourney-be`, migration `0016`, 23 test pgTAP mới):**

| Mã | Đã sửa |
| --- | --- |
| A-B3 | `shared_with_me` không lộ `shared_by` khi chủ nhóm chưa đồng ý, `send_friend_request` xét consent |
| A-B4 | Xóa tài khoản xóa cả ảnh chat ở bucket `messages` và dữ liệu ở `join_attempts`, `rate_events`, `journey_views` |
| A-B6 | Server ép `max_members = 2` cho hành trình cặp đôi. Phần app vẫn còn (B-B10) |
| A-B7 | Lời mời của thành viên đã rời hoặc bị đuổi hết hiệu lực |
| A-B8 | Không lộ `metric_name`, `metric_unit` khi bật `hide_metric` |
| A-B9 | `share_consents` lọc người đã chặn |
| A-B10 | Phần server: `consent_json` không trả `null` cho `requested_by` sau khi xóa tài khoản. Phần app vẫn còn |
| A-B15 | `group_today` không ẩn ảnh hợp lệ trước đó khi ảnh mới nhất bị báo cáo |
| A-B16 | `join_by_code` đóng lời mời đang chờ |
| C1 | `shared_with_me` ẩn ảnh bìa khi tác giả bật `blur_media` (của `fix-be2`, chưa có test) |

**Đã làm xong nhưng chưa merge:** tính năng "Đề xuất tính năng" (`impl-fr`, review ĐẠT), branch `feat/feature-request` ở `Ourney-fr`.

**Còn lại, chưa ai sửa:**

| Nhóm | Số mục | Mã |
| --- | --- | --- |
| Server | 2 | C2, C3 (mục 1.2) |
| App, đợt A | 7 | A-B1, A-B2, A-B5, A-B11, A-B12, A-B13, A-B14, cộng phần app của A-B10 |
| App, đợt B | 15 | B-B1 đến B-B15 |
| App, đợt C | 16 | C-B1 đến C-B15, cộng lỗi nhập hành trình (mục 1.1) |
| App, lỗi lẻ | 8 | mục 1.4 |
| UX và UI | 23 | U1 đến U23 |
| Dọn dẹp | 34 | S1 đến S34 |

### 1.1. Việc nên làm trước

1. **C-ngoài phạm vi, nhập và kể lại hành trình hỏng hoàn toàn (cao).** `create_imported_journey` tạo hành trình với `status = 'ended'` (`0006_social.sql:1503`), trigger server có ngoại lệ cho hành trình nhập (`0006:450-472`), nhưng `DataCheckInRepository.submit` (`check_in_repository.dart:59`) chặn mọi hành trình không `active`, nên `import_flow_screen.dart:211` luôn nhận lỗi `ended`.
2. **C-B1, C-B2, C-B4 (cao).** Hai công tắc riêng tư trong Cài đặt không có tác dụng, thẻ chia sẻ dùng cả ảnh đã ẩn, đổi tài khoản trên cùng máy làm quiz của người trước ghi đè người sau.
3. **A-B3 (cao).** Lộ danh tính chủ nhóm chưa đồng ý chia sẻ. Đã sửa ở `fix-be`, cần merge.
4. **B-B2 (cao).** Mọi người dùng mới: bảng xin quyền thông báo tự đóng sau 1,8 giây và không bao giờ hiện lại.
5. **C-B5 (cao, cần thử trên máy).** Người dùng mới có thể không được đưa qua `/profile/setup`.

### 1.2. Lỗi server còn dở (`fix-be2`)

Ba lỗi này do `bug-scan-c` và `fix-be` phát hiện thêm, giao `fix-be2` sửa trong cùng migration `0016_bugscan_backend_fixes.sql`:

| Mã | Lỗi | Trạng thái |
| --- | --- | --- |
| C1 | `public.shared_with_me` trả `cover_thumb_path` rõ dù tác giả ảnh bìa bật `blur_media` | Đã sửa trong `0016` (ẩn ảnh, trả thêm `cover_blurred`), chưa có test |
| C2 | `private.message_json` trả `reply_to_thumb_path` chỉ xét `deleted_at`, không xét quyền xem ảnh | Chưa sửa |
| C3 | `public.journey_pending_invitations` (`0010_invite_management.sql:68-79`) không lọc chặn hai chiều giữa người gọi và `inviter_id` | Chưa sửa |

### 1.3. Lưu ý từ `fix-be` và `impl-fr`

- **Sửa thẳng migration cũ.** `fix-be` sửa thẳng `0013_unlimited_journeys.sql` và `0014_multi_photo_per_day.sql` vì hai file này chưa deploy. Nếu môi trường nào đã chạy hai migration đó thì phần sửa sẽ không được áp dụng.
- **Thứ tự số migration.** Số `0015` thuộc branch "Đề xuất tính năng". `supabase db push` không có `--include-all` (`deploy-hosted.sh:213`) sẽ từ chối migration có số nhỏ hơn số lớn nhất đã chạy. Vì vậy phải deploy `0015` trước hoặc cùng đợt với `0016`, nếu không thì đổi số của branch kia thành `0017`.
- **Thứ tự deploy.** Chạy migration `0016` trước, deploy Edge Function `delete-account` sau, vì function mới gọi RPC `public.account_message_paths`.
- **Chưa kiểm chứng.** Máy làm việc không có `supabase`, `psql`, `deno`, nên `deno check`, `supabase start` và `supabase test db` phải để CI chạy.
- **Ca biên khi xóa tài khoản.** Ảnh chat của hành trình nhóm bị xóa theo chủ nhóm (`_journeys_dying_with`) nhưng không thuộc cuộc trò chuyện có chủ nhóm thì chưa nằm trong `account_message_paths`.
- **Câu hỏi cho owner.** `public.moderation_queue` giữ `actor_id`, `target_user_id` vĩnh viễn sau khi xóa tài khoản. Giữ như vậy hay ẩn danh hoặc xóa định kỳ các dòng đã xử lý, ví dụ sau 90 ngày?
- **`impl-fr` trước khi mở PR.** `supabase/tests/01_rls_enabled.test.sql:6-11` liệt kê cứng 20 bảng, thiếu `'feature_requests'`, nên CI sẽ fail.

### 1.4. Lỗi khác đã xác nhận, chưa có mã riêng

- `mapping.dart:305`: `checked_in = true` mà `checkin_id = null` thì app coi là chưa check-in, trái quy tắc L7. Phần server là A-B15.
- `group_repository.dart:284` không cập nhật `invite_code` local sau khi xóa thành viên.
- `safety_repository.dart:45` không gọi `social.changed()` sau khi chặn.
- `app.dart:58`: banner nhắc giờ bỏ rơi `journeyId`.
- `check_in_repository.dart:34-37` thiếu sắp xếp theo `capturedAt`.
- `journey_home_intro.dart:87` hiện tên tháng theo giờ máy.
- `notification_gateway.dart:218-221` bỏ qua ngôn ngữ chọn trong app.
- Đăng xuất và xóa tài khoản không hủy thông báo đã lên lịch, không reset `eulaAcceptedProvider` (gộp với C-B4).

### 1.5. Lỗi trùng giữa các đợt

- A-B1 (`group_repository.dart:190`, `getSingleOrNull`) được cả ba worker quét lỗi cùng thấy.
- A-B6, B-B10: `max_members = 10` cho hành trình cặp đôi. Phần server đã sửa ở `fix-be`, phần app thuộc B-B10.
- A-B14, B-B7: không có gì tự chuyển hành trình hết hạn sang `ended`. Nên sửa chung một lần.
- A-B11 trùng mục `_clipDna` ngoài phạm vi của `bug-scan-b`.
- B-B5, B-B6: phần còn dở của tính năng nhiều ảnh mỗi ngày theo `docs/design-v2/multi-photo-day.md`.
- C-B6 và U6: Đăng xuất ở Cài đặt không hỏi xác nhận.
- C-B1 và U11: công tắc làm mờ ảnh bị bỏ qua.
- Test tạm của ba đợt quét nằm ở `apps/mobile/test/zz_bugscan*/`, `apps/mobile/test/zz_uxscan/` và `packages/ourney_core/test/zz_bugscan/`. Các thư mục này chưa commit và không thuộc file này.


## 2. Lỗi chức năng (bug-scan, bug-scan-b, bug-scan-c)

Mỗi lỗi có mã dạng `A-B1`: chữ đầu là đợt quét, phần sau là mã trong báo cáo gốc. Cột "Mức (Claude)" là mức sau khi Claude đọc lại code và chạy lại test tạm, nên ưu tiên cột này hơn cột của worker.


### 2.1. Đợt A: `bug-scan` (data layer, repository, sync, `ourney_core`, server)

Worker tự chấm: 7 cao, 7 vừa, 2 thấp. 16 lỗi, đều có test tạm fail đúng như báo cáo.

| Mã | Lỗi | Vị trí chính | Mức (worker) | Mức (Claude) | Trạng thái |
| --- | --- | --- | --- | --- | --- |
| A-B1 | Crash `StateError` không được bắt trong `watchToday` khi chụp từ 2 ảnh/ngày trở lên lúc ảnh chưa upload xong | `apps/mobile/lib/data/repositories/group_repository.dart:190` | cao | vừa | open |
| A-B2 | `SharingRepository.unlike` luôn lỗi quyền `42501` trên Supabase và `like` không thể thích lại ảnh đã bỏ thích/bỏ lưu | `apps/mobile/lib/data/repositories/sharing_repository.dart:172-191` | cao | vừa | open |
| A-B3 | `shared_with_me()` làm lộ danh tính chủ nhóm chưa đồng ý chia sẻ trên link công khai và `send_friend_request` cho phép gửi kết bạn tới họ | `supabase/migrations/0006_social.sql:1173,1187` | cao | cao | đã sửa ở `fix/backend-bugscan` (Ourney-be), chưa merge |
| A-B4 | Xóa tài khoản bỏ sót toàn bộ ảnh chat trong Storage bucket `messages` và dữ liệu người dùng ở `join_attempts`, `rate_events`, `journey_views` | `supabase/functions/delete-account/index.ts:89-106` | cao | cao | đã sửa ở `fix/backend-bugscan` (Ourney-be), chưa merge |
| A-B5 | Race giữa `SyncEngine._pullOnce` và `signOut`/`deleteAccount` làm rò rỉ dữ liệu của User A sang User B và làm hỏng cursor đồng bộ của User B | `apps/mobile/lib/data/sync/sync_engine.dart:54-62,192-215` | cao | cao, hiếm | open |
| A-B6 | Hành trình cặp đôi (`couple`) bị tạo với `max_members = 10` thay vì `2` ở cả app lẫn RPC `create_journey` | `apps/mobile/lib/data/mapping.dart:125` | cao | vừa | server đã sửa (`fix-be`), app còn phải sửa |
| A-B7 | Lời mời `group_invitations` của thành viên đã bị đuổi khỏi nhóm vẫn còn hiệu lực và vượt qua việc xoay `invite_code` | `supabase/migrations/0008_group_invites.sql:270-299` | cao | vừa | đã sửa ở `fix/backend-bugscan` (Ourney-be), chưa merge |
| A-B8 | Link công khai (`public-journey`) và các RPC `journey_view`/`follow_frame` làm lộ `metric_name`, `metric_unit` dù chủ hành trình đã bật `hide_metric` | `supabase/functions/public-journey/index.ts:222-223` | vừa | thấp | đã sửa ở `fix/backend-bugscan` (Ourney-be), chưa merge |
| A-B9 | RPC `public.share_consents` bỏ qua kiểm tra chặn hai chiều (`blocked_between`), làm lộ hồ sơ của thành viên đã chặn nhau | `supabase/migrations/0006_social.sql:1530-1557` | vừa | thấp | đã sửa ở `fix/backend-bugscan` (Ourney-be), chưa merge |
| A-B10 | `consentFromJson` ném `FormatException` làm hỏng danh sách đồng ý chia sẻ của cả nhóm khi người yêu cầu chia sẻ xóa tài khoản | `apps/mobile/lib/data/social_mapping.dart:244` | vừa | vừa | server đã sửa (`fix-be`), app còn phải sửa |
| A-B11 | `sanitizeJourneyDna` cắt chuỗi theo UTF-16 code units làm vỡ đôi surrogate pair của emoji, khiến `update_journey` lỗi JSON trên Postgres | `packages/ourney_core/lib/src/models.dart:399-402` | vừa | thấp | open |
| A-B12 | `DataJourneyRepository.create` làm mất cục bộ `reminderTime`, `layout`, `cover`, `color`, `dna` khi `update_journey` thất bại ngay sau `create_journey` | `apps/mobile/lib/data/repositories/journey_repository.dart:103-109,141-157` | vừa | thấp | open |
| A-B13 | `resolveRedirect` đánh rơi universal link `https://ourney.tech/...` khi người dùng đi qua cổng onboarding, đăng nhập hoặc EULA | `apps/mobile/lib/app/redirect.dart:20-30,88-95,107-128` | vừa | vừa (chỉ phần Android) | open |
| A-B14 | `computeStreak` báo sai `atRisk = true` vào ngày ngay sau khi hành trình có thời hạn cố định đã hoàn thành và kết thúc | `packages/ourney_core/lib/src/streak.dart:76-82,98` | vừa | vừa | open |
| A-B15 | Khi thành viên đăng nhiều ảnh/ngày (`0014`) và chỉ ảnh mới nhất bị báo cáo, `group_today` hiển thị thành viên đó như chưa check-in hôm nay | `supabase/migrations/0014_multi_photo_per_day.sql:53-68` | thấp | thấp | đã sửa ở `fix/backend-bugscan` (Ourney-be), chưa merge |
| A-B16 | Lời mời `group_invitations` đang chờ không được đóng khi người được mời tự tham gia nhóm bằng mã mời (`join_by_code`) | `supabase/migrations/0013_unlimited_journeys.sql:170-180` | thấp | thấp | đã sửa ở `fix/backend-bugscan` (Ourney-be), chưa merge |


#### A-B1. Crash `StateError` không được bắt trong `watchToday` khi chụp từ 2 ảnh/ngày trở lên lúc ảnh chưa upload xong

- **Vị trí:** `apps/mobile/lib/data/repositories/group_repository.dart:190` (liên quan `apps/mobile/lib/data/repositories/group_repository.dart:105`, `apps/mobile/lib/data/repositories/group_repository.dart:159`, `supabase/migrations/0014_multi_photo_per_day.sql:15`)
- **Mức độ:** cao
- **Độ chắc:** chắc chắn
- **Tình huống gây lỗi:** Sau migration `0014_multi_photo_per_day` và Drift schema v6, người dùng trong hành trình nhóm chụp 2 ảnh trở lên trong cùng một ngày khi đang ngoại tuyến hoặc outbox chưa kịp upload xong, rồi mở tab Nhóm (`watchToday`). Luồng `load()` ném `Bad state: Too many elements` không được bắt (unhandled async error), làm vỡ stream danh sách thành viên hôm nay; ngoài ra nếu ảnh 1 đã lên server còn ảnh 2 mới chụp đang chờ ở máy, giao diện vẫn chỉ hiện ảnh 1 cũ.
- **Vì sao sai:** Migration `0014_multi_photo_per_day.sql:15` và bảng Drift `CheckIns` v6 đã bỏ ràng buộc duy nhất `(journey_id, user_id, local_date)`, nhưng `_localCheckIn` (`group_repository.dart:183-190`) vẫn truy vấn theo `(journeyId, userId, localDate)` rồi gọi `.getSingleOrNull()` không có `orderBy` hay `limit(1)`. Khi có >= 2 dòng cùng ngày, `.getSingleOrNull()` ném `StateError`, lọt qua khối `on OurneyException catch` ở `group_repository.dart:105`. Thêm vào đó, điều kiện `member.todayCheckIn == null` ở dòng `159` bỏ qua hoàn toàn bản ghi cục bộ mới hơn khi server đã có ảnh đầu tiên trong ngày.
- **Hướng sửa:** Trong `_localCheckIn`, sắp xếp `orderBy([(t) => OrderingTerm.desc(t.capturedAt), (t) => OrderingTerm.desc(t.id)])..limit(1)` trước `.getSingleOrNull()`, đồng thời ở `_fetchToday` so sánh `local.capturedAt` với `member.todayCheckIn?.capturedAt` để luôn lấy ảnh mới nhất trong ngày.
- **Test tạm:** `apps/mobile/test/zz_bugscan/data_app_bugs_test.dart` (test `B1`) — chạy fail với lỗi `Bad state: Too many elements` tại `DataGroupRepository.watchToday.load` (`group_repository.dart:103`).
- **Claude kiểm chứng:** `getSingleOrNull` ở `group_repository.dart:190` ném `StateError`, `_group` chỉ bắt `OurneyException`. App không văng: lỗi async không ai bắt, danh sách "hôm nay" ngừng cập nhật. Chỉ xảy ra khi online mà mình còn ≥2 ảnh hôm nay chưa lên server.

#### A-B2. `SharingRepository.unlike` luôn lỗi quyền `42501` trên Supabase và `like` không thể thích lại ảnh đã bỏ thích/bỏ lưu

- **Vị trí:** `apps/mobile/lib/data/repositories/sharing_repository.dart:172-191` (liên quan `supabase/migrations/0002_rls.sql:110,124`, `supabase/migrations/0006_social.sql:652-665,1519`)
- **Mức độ:** cao
- **Độ chắc:** chắc chắn
- **Tình huống gây lỗi:** (1) Người xem bấm bỏ tim (`unlike`) trên ảnh của hành trình được chia sẻ hoặc công khai: server trả lỗi `42501 permission denied for table reactions` (`OurneyErrorCode.forbidden`). (2) Người xem bỏ lưu hành trình (`unsave_journey`, đặt `reactions.deleted_at = now()`) hoặc thành viên từng bỏ cảm xúc rồi bấm thả tim lại (`like`) vào ảnh đó: lời gọi trả về thành công giả nhưng `deleted_at` vẫn khác `null`, tim không bao giờ được ghi nhận lại.
- **Vì sao sai:** `0002_rls.sql:110` thu hồi toàn bộ quyền trên `public.reactions` và dòng `124` chỉ cấp `select, insert, update` cho `authenticated` (không có quyền `DELETE` và cũng không có RLS policy `FOR DELETE` ở `0002` hay `0006_social.sql:652-665`); thế nhưng `DataSharingRepository.unlike` (`sharing_repository.dart:187-190`) lại gọi `social.remote.delete('reactions', ...)`. Ngược lại, `DataSharingRepository.like` (`sharing_repository.dart:172-180`) gọi `insert('reactions', ...)` và nuốt mã lỗi trùng khóa chính `23505` mà không cập nhật `deleted_at = null` cho dòng đã xóa mềm (khác với `SyncEngine.execute(OutboxKind.react)` ở `sync_engine.dart:88-102` dùng `upsert` kèm `'deleted_at': null` và `update({'deleted_at': ...})`).
- **Hướng sửa:** Trong `DataSharingRepository.like`, dùng `social.remote.upsert('reactions', {'checkin_id': checkInId, 'user_id': me, 'emoji': likeEmoji, 'deleted_at': null}, onConflict: 'checkin_id,user_id')`; trong `unlike`, dùng `social.remote.update('reactions', {'deleted_at': ...}, match: {'checkin_id': checkInId, 'user_id': me})`.
- **Test tạm:** `apps/mobile/test/zz_bugscan/data_app_bugs_test.dart` (test `B2a` và `B2b`) — chạy fail: `B2a` ném `OurneyException(forbidden: 42501: permission denied for table reactions)`, `B2b` giữ nguyên `deleted_at: '2026-10-15T10:00:00Z'`.
- **Claude kiểm chứng:** `0002_rls.sql:124` chỉ grant insert, update trên `reactions`; không migration nào grant delete. UI gọi `unlike` ở `shared_journey_screen.dart:131`.

#### A-B3. `shared_with_me()` làm lộ danh tính chủ nhóm chưa đồng ý chia sẻ trên link công khai và `send_friend_request` cho phép gửi kết bạn tới họ

- **Vị trí:** `supabase/migrations/0006_social.sql:1173,1187` và `supabase/migrations/0006_social.sql:803` (đối chiếu `0006_social.sql:1140-1152,1319`)
- **Mức độ:** cao
- **Độ chắc:** chắc chắn
- **Tình huống gây lỗi:** Một hành trình nhóm đã kết thúc bật link công khai (`public_token != null`, `allow_public_reactions = true`, `allow_viewer_requests = true`), trong đó thành viên M đồng ý chia sẻ (`consent = 'accepted'`) nhưng chủ nhóm O từ chối hoặc chưa đồng ý (theo quy tắc S29/S30 phải được ẩn danh hoàn toàn). Một người lạ đã đăng nhập mở link công khai, thả tim vào ảnh của M (trigger `reactions_saved_sync` lưu hành trình vào `saved_journeys`), rồi gọi `select * from public.shared_with_me()`: trường `owner` trả UUID rỗng nhưng trường `shared_by` ngay bên dưới lại trả đầy đủ `user_id`, `username`, `display_name`, `avatar_path` thật của O; tiếp đó người lạ gọi `public.send_friend_request(<user_id của O>, <journey_id>)` và tạo được lời mời kết bạn thẳng tới O.
- **Vì sao sai:** Trong CTE `items` của `public.shared_with_me` (`0006_social.sql:1173`), các dòng từ `saved_journeys` gán cứng cột `shared_by = j.owner_id`, rồi dòng `1187` gọi trực tiếp `'shared_by', private.person(i.shared_by)` trong hàm `SECURITY DEFINER` thay vì qua `private.owner_for_viewer(j.id)` như dòng `1186`. Đồng thời, `public.send_friend_request` (`0006_social.sql:798-805`) chỉ kiểm tra `j.public_token is null or not j.allow_viewer_requests or j.owner_id <> p_user`, thiếu hẳn điều kiện `(j.kind = 'solo' or private.consent_accepted(j.id, j.owner_id))` vốn có ở `can_add_owner` (`0006_social.sql:1318-1319`).
- **Hướng sửa:** Ở `shared_with_me` (`0006_social.sql:1173,1187`), đặt `shared_by` là `null` cho nhánh `saved_journeys` (hoặc dùng `case when i.saved then private.owner_for_viewer(j.id) else private.person(i.shared_by) end`). Ở `send_friend_request` (`0006_social.sql:803`), thêm kiểm tra `or (j.kind = 'group' and not private.consent_accepted(j.id, j.owner_id))` để raise `'forbidden'`.
- **Claude kiểm chứng:** `shared_with_me` nhánh saved đặt `shared_by = j.owner_id` (`0006:1173`) rồi `private.person` (`:1187`), trong khi `owner` dùng `owner_for_viewer`. `set_public_link` không ép chủ nhóm đồng ý. `send_friend_request` (`:803`) không xét consent.

#### A-B4. Xóa tài khoản bỏ sót toàn bộ ảnh chat trong Storage bucket `messages` và dữ liệu người dùng ở `join_attempts`, `rate_events`, `journey_views`

- **Vị trí:** `supabase/functions/delete-account/index.ts:89-106` và `supabase/migrations/0004_rpc.sql:572-610` (liên quan `supabase/migrations/0006_social.sql:118,139-165,170,679-708`, `0005_security_hardening.sql:475`)
- **Mức độ:** cao
- **Độ chắc:** chắc chắn
- **Tình huống gây lỗi:** Người dùng từng gửi hoặc nhận ảnh trong chat 1-1 (lưu ở bucket riêng tư `messages` theo đường dẫn `messages/{conversation_id}/{sender_id}/{message_id}.jpg`) thực hiện xóa tài khoản qua Edge Function `delete-account`. Tài khoản và các dòng `conversations`/`messages` bị xóa theo `ON DELETE CASCADE`, nhưng toàn bộ file JPEG trong `storage.objects` thuộc bucket `messages` vẫn nằm vĩnh viễn trên Storage (kể cả ảnh của người còn lại trong cuộc hội thoại đã bị cascade xóa mất dòng DB), cùng với các bản ghi chứa `user_id` của họ trong `private.join_attempts`, `private.rate_events`, và `public.journey_views`.
- **Vì sao sai:** `public.account_media_paths` (`0004_rpc.sql:578-587`) chỉ lọc `where o.bucket_id = 'media'`, và `delete-account/index.ts:99` chỉ gọi `admin.storage.from("media").remove(part)` trước khi gọi `admin.auth.admin.deleteUser(userId)` ở dòng `108`. Khi migration `0006_social.sql:679` bổ sung bucket `'messages'` và bảng `conversations` (`member_id`, `viewer_id` đều `references public.profiles(id) on delete cascade`), không có hàm liệt kê hay xóa file nào cho bucket `'messages'`. Ngoài ra, `private.join_attempts.user_id` (`0005:475`), `private.rate_events.user_id` (`0006:170`) và `public.journey_views.viewer_key` (`uid::text` từ `0006:1360,1388`) đều không có khóa ngoại `ON DELETE CASCADE` và không được xóa trong `public.purge_account_data` (`0004_rpc.sql:593-610`).
- **Hướng sửa:** Bổ sung RPC (hoặc mở rộng `account_media_paths` trả kèm `bucket_id`) liệt kê mọi object trong bucket `'messages'` có `(storage.foldername(name))[3] = p_user::text` hoặc `(storage.foldername(name))[2]` thuộc các `conversations` của `p_user` để `delete-account/index.ts` xóa khỏi `admin.storage.from("messages")` trước `deleteUser`; đồng thời xóa `join_attempts`, `rate_events`, `journey_views` của `p_user` trong `purge_account_data`.
- **Claude kiểm chứng:** `account_media_paths` chỉ lọc bucket `media` (`0004:580`), không được định nghĩa lại sau 0004. Bucket `messages` thêm ở `0006:679`, path `messages/{conv}/{sender}/{id}.jpg`.

#### A-B5. Race giữa `SyncEngine._pullOnce` và `signOut`/`deleteAccount` làm rò rỉ dữ liệu của User A sang User B và làm hỏng cursor đồng bộ của User B

- **Vị trí:** `apps/mobile/lib/data/sync/sync_engine.dart:54-62,192-215` (liên quan `apps/mobile/lib/data/repositories/auth_repository.dart:169-189`)
- **Mức độ:** cao
- **Độ chắc:** chắc chắn
- **Tình huống gây lỗi:** User A đang có một lượt `syncNow()` đang chạy nền (do mở app, khôi phục mạng hoặc resume) thì bấm Đăng xuất hoặc Xóa tài khoản. Phản hồi mạng của User A về trễ ngay sau khi `ctx.wipeLocal()` vừa xóa SQLite, sau đó User B đăng nhập trên cùng thiết bị: User B nhìn thấy dữ liệu hành trình/check-in của User A trong SQLite cục bộ, đồng thời các hành trình trên server của User B có `updated_at` cũ hơn cursor của User A bị bỏ qua không kéo về máy.
- **Vì sao sai:** `_pullOnce()` (`sync_engine.dart:193`) chỉ đọc `final me = remote.currentUserId` một lần ở đầu hàm rồi chạy tuần tự 9 lệnh `await _pullTable(...)` (`dòng 198-213`) mà không kiểm tra lại phiên đăng nhập; còn `signOut()` (`auth_repository.dart:170-171`) và `deleteAccount()` (`dòng 187-188`, thậm chí gọi `wipeLocal()` trước cả `remote.signOut()`) không hủy hay chờ `_pulling` kết thúc. Khi `db.wipe()` chạy giữa chừng `_pullOnce`, khóa `_owner` trong `sync_cursor` bị xóa về `null`, các lệnh `_pullTable` còn lại tiếp tục ghi dòng và `updated_at` cursor của User A vào DB. Tệ hơn, khi User B đăng nhập, `ensureOwner(userB)` (`sync_engine.dart:55-61`) chỉ gọi `db.wipe()` khi `if (owner != null)` — vì `owner` đang là `null`, `ensureOwner` bỏ qua bước xóa và nhận luôn dữ liệu lẫn cursor của User A thành của User B.
- **Hướng sửa:** Tăng biến đếm thế hệ phiên (`_epoch`) mỗi khi `wipeLocal()`/`signOut()` chạy (và đợi `_pulling` hoặc kiểm tra `remote.currentUserId == me && epoch == startEpoch` trước mọi bước ghi DB/cursor trong `_pullOnce`/`_pullTable`); trong `ensureOwner`, luôn xóa sạch bảng nếu `owner == null` mà DB đã có bất kỳ cursor hay bản ghi nào, và trong `deleteAccount` đổi thứ tự gọi `remote.signOut()` hoặc khóa sync trước `ctx.wipeLocal()`.
- **Test tạm:** `apps/mobile/test/zz_bugscan/data_app_bugs_test.dart` (test `B5`) — chạy fail: sau khi User A `signOut()` và User B đăng nhập + `syncNow()`, DB của User B chứa `['journey-of-user-a']` và mất hoàn toàn `'journey-of-user-b'`.
- **Claude kiểm chứng:** `_pullOnce` đọc `me` một lần, `signOut` không chờ `_pulling`; `ensureOwner` bỏ qua wipe khi `_owner == null` (`sync_engine.dart:57`). Cần sync đang chạy đúng lúc đăng xuất.

#### A-B6. Hành trình cặp đôi (`couple`) bị tạo với `max_members = 10` thay vì `2` ở cả app lẫn RPC `create_journey`

- **Vị trí:** `apps/mobile/lib/data/mapping.dart:125`, `apps/mobile/lib/data/repositories/journey_repository.dart:269`, `supabase/migrations/0013_unlimited_journeys.sql:85`
- **Mức độ:** cao
- **Độ chắc:** chắc chắn
- **Tình huống gây lỗi:** Người dùng tạo hành trình cặp đôi (`kind = group`, có `coupleSelfName` và `couplePartnerName`): hành trình được lưu với `max_members = 10`. Hệ quả là tối đa 10 người có mã mời 8 ký tự đều vào được hành trình riêng tư của 2 người (`join_by_code` cho vào tới 10 thành viên) và đọc toàn bộ ảnh/chú thích của cặp đôi, trong khi tường cặp đôi (`_CoupleWall` chỉ lấy `.take(2)`) ẩn mất các thành viên thứ 3..10 và màn `CheckinScreen` (`checkin_screen.dart:344` kiểm tra `journey.maxMembers == 2`) gắn nhãn quyền riêng tư sai thành nhóm thường thay vì cặp đôi.
- **Vì sao sai:** `createJourneyParams` (`mapping.dart:125`) và `_insertLocal` (`journey_repository.dart:269`) đều gán cứng `d.kind == JourneyKind.solo ? 1 : maxGroupMembers` (`10`) mà không xét `d.coupleSelfName != null`; phía server, `public.create_journey` trong `0013_unlimited_journeys.sql:85` cũng viết `case when p_kind = 'solo' then 1 else coalesce(p_max_members, 10) end` mà không ép `max_members = 2` khi `v_self is not null`.
- **Hướng sửa:** Ở cả `mapping.dart:125` và `journey_repository.dart:269`, đặt `maxMembers` là `1` cho `solo`, `2` khi `d.coupleSelfName != null`, ngược lại `maxGroupMembers` (`10`); ở `0013_unlimited_journeys.sql:85`, ép `when v_self is not null then 2` trong `create_journey`.
- **Test tạm:** `apps/mobile/test/zz_bugscan/data_app_bugs_test.dart` (test `B6`) — chạy fail: `Expected: <2>, Actual: <10>`.
- **Claude kiểm chứng:** `mapping.dart:125` luôn gửi `maxGroupMembers` (10) cho group, kể cả cặp đôi; `0013:85` nhận nguyên. `checkin_screen.dart:344` và `templates.dart:122` dựa vào `maxMembers == 2`. Người thứ 3 cần có mã mời.

#### A-B7. Lời mời `group_invitations` của thành viên đã bị đuổi khỏi nhóm vẫn còn hiệu lực và vượt qua việc xoay `invite_code`

- **Vị trí:** `supabase/migrations/0008_group_invites.sql:270-299` và `supabase/migrations/0005_security_hardening.sql:579-607`
- **Mức độ:** cao
- **Độ chắc:** chắc chắn
- **Tình huống gây lỗi:** Thành viên M dùng `invite_to_group` gửi lời mời trong app cho người ngoài X, sau đó chủ nhóm phát hiện và đuổi M bằng `remove_member(journey, M)` (hoặc chủ động gọi `rotate_invite(journey)` để vô hiệu hóa các lời mời cũ). Trong vòng 7 ngày kế tiếp, X bấm chấp nhận lời mời (`accept_group_invitation`): X vẫn vào thẳng được nhóm riêng tư dù người mời M đã bị đuổi và mã mời của nhóm đã bị đổi.
- **Vì sao sai:** `public.remove_member` (`0005_security_hardening.sql:603`) xoay `journeys.invite_code` để chặn mã cũ mà người bị đuổi từng biết, nhưng không hủy các dòng `status = 'pending'` trong `public.group_invitations` có `inviter_id = member`. Khi X gọi `public.accept_group_invitation` (`0008_group_invites.sql:285-292`, chạy quyền `SECURITY DEFINER`), hàm này tự đọc `j.invite_code` **mới nhất** từ bảng `journeys` để truyền vào `public.join_by_code(j.invite_code)` và chỉ kiểm tra chặn giữa `uid` với `i.inviter_id` (`dòng 289`), hoàn toàn không kiểm tra `private.is_active_member(i.journey_id, i.inviter_id)`.
- **Hướng sửa:** Trong `remove_member` (và `_leave_journey`), cập nhật `group_invitations set status = 'revoked', responded_at = now()` cho các lời mời `pending` của thành viên rời/bị xóa; đồng thời trong `accept_group_invitation` (`0008_group_invites.sql:289`) kiểm tra `if not private.is_active_member(i.journey_id, i.inviter_id) then raise exception 'not_found'; end if;`.
- **Claude kiểm chứng:** `accept_group_invitation` (`0008:270-299`) không xét inviter còn active; `remove_member` (`0005:579-607`) không thu hồi lời mời. Chủ nhóm vẫn thu hồi tay được (`0010:32`, `journey_pending_invitations`).

#### A-B8. Link công khai (`public-journey`) và các RPC `journey_view`/`follow_frame` làm lộ `metric_name`, `metric_unit` dù chủ hành trình đã bật `hide_metric`

- **Vị trí:** `supabase/functions/public-journey/index.ts:222-223`, `supabase/migrations/0006_social.sql:1309-1310`, `supabase/migrations/0006_social.sql:1421-1422`
- **Mức độ:** vừa
- **Độ chắc:** chắc chắn
- **Tình huống gây lỗi:** Chủ hành trình bật ẩn chỉ số (`memberships.hide_metric = true`, ví dụ chỉ số nhạy cảm `"Cân nặng"` / `"Số đo vòng eo"`, `"kg"` / `"cm"`) rồi tạo link công khai cho hành trình đã kết thúc hoặc hành trình import. Bất kỳ ai mở JSON của Edge Function `public-journey` (hoặc người xem đăng nhập gọi `public_journey_by_token`, `shared_journey`, `follow_frame`) đều thấy nguyên `metric_name` và `metric_unit` trong payload.
- **Vì sao sai:** Trong `public-journey/index.ts`, dòng `184` và `199-200` đã tính `ownerHides` và che `journey.metric_name`, `journey.metric_unit` thành `null` ở object `journey`, nhưng ngay bên dưới ở object `frame` (`dòng 213-225`), code lại gán thẳng `metric_name: journey.metric_name, metric_unit: journey.metric_unit` không qua `ownerHides` — trong khi `canFollow` luôn là `true` với 100% hành trình đủ điều kiện bật link công khai (`ended`, `archived` hoặc `imported`). Tương tự, `private.journey_view` (`0006_social.sql:1309-1310`) và `public.follow_frame` (`0006_social.sql:1421-1422`) trả trực tiếp `j.metric_name`, `j.metric_unit` mà không kiểm tra `memberships.hide_metric` của chủ hành trình.
- **Hướng sửa:** Ở `public-journey/index.ts:222-223`, đổi thành `metric_name: ownerHides ? null : journey.metric_name` và `metric_unit: ownerHides ? null : journey.metric_unit`; ở `private.journey_view` và `public.follow_frame` (`0006_social.sql`), ẩn hai trường này với người ngoài nhóm khi `exists (select 1 from public.memberships where journey_id = j.id and user_id = j.owner_id and hide_metric)`.
- **Test tạm:** Không chạy được Deno/pgTAP theo quy tắc môi trường; đường đi dữ liệu xác định trực tiếp tại `public-journey/index.ts:184-225` và `0006_social.sql:1309-1310,1421-1422`.
- **Claude kiểm chứng:** `public-journey/index.ts:222-223` lộ `metric_name`, `metric_unit` trong `frame`; `journey_view` (`0006:1309`) và `follow_frame` (`0006:1421`) cũng vậy. Không lộ giá trị chỉ số.

#### A-B9. RPC `public.share_consents` bỏ qua kiểm tra chặn hai chiều (`blocked_between`), làm lộ hồ sơ của thành viên đã chặn nhau

- **Vị trí:** `supabase/migrations/0006_social.sql:1530-1557`
- **Mức độ:** vừa
- **Độ chắc:** chắc chắn
- **Tình huống gây lỗi:** Trong cùng một hành trình nhóm, thành viên A chặn thành viên B (`block_user`). Dù RLS trên `profiles` (`0005_security_hardening.sql:452`) và RPC `group_today` (`0014_multi_photo_per_day.sql:71`) đã ẩn hoàn toàn hồ sơ hai chiều giữa A và B, khi B (hoặc A) gọi `public.share_consents(p_journey)` để xem trạng thái đồng ý chia sẻ nhóm, server vẫn trả về đầy đủ `user_id`, `username`, `display_name`, `avatar_path` mới nhất của người kia.
- **Vì sao sai:** `public.share_consents` (`0006_social.sql:1542-1557`) và `private.consent_json` (`dòng 1530-1540`) đều chạy với quyền `SECURITY DEFINER`, gọi thẳng `private.person(c.user_id)` và `private.person(c.requested_by)` bỏ qua RLS của `public.profiles`, nhưng câu `where` ở dòng `1554` không có điều kiện `and not private.blocked_between(public._uid(), c.user_id)`.
- **Hướng sửa:** Thêm `and not private.blocked_between(public._uid(), c.user_id)` vào `public.share_consents` (`0006_social.sql:1554`) và ẩn `requested_by` trong `private.consent_json` khi `private.blocked_between((select auth.uid()), c.requested_by)`.
- **Claude kiểm chứng:** `share_consents` (`0006:1542-1557`) và `consent_json` không lọc `blocked_between`; `private.person` không xét chặn.

#### A-B10. `consentFromJson` ném `FormatException` làm hỏng danh sách đồng ý chia sẻ của cả nhóm khi người yêu cầu chia sẻ xóa tài khoản

- **Vị trí:** `apps/mobile/lib/data/social_mapping.dart:244` (liên quan `supabase/migrations/0006_social.sql:104,1538`, `packages/ourney_core/lib/src/contracts/social.dart:192`)
- **Mức độ:** vừa
- **Độ chắc:** chắc chắn
- **Tình huống gây lỗi:** Chủ nhóm U1 bấm yêu cầu các thành viên đồng ý chia sẻ nhóm (`request_share_consents`), sau đó U1 xóa tài khoản (quyền chủ nhóm chuyển sang thành viên kế tiếp theo `purge_account_data`). Từ thời điểm đó, mọi thành viên còn lại mở màn chia sẻ nhóm (`watchForJourney`) hoặc hộp thư đồng ý chia sẻ (`watchMyPending`) đều nhận lỗi `OurneyException(unknown)` thay vì danh sách đồng ý.
- **Vì sao sai:** Bảng `public.journey_share_consents` khai báo `requested_by uuid references public.profiles (id) on delete set null` (`0006_social.sql:104`). Khi U1 xóa tài khoản, `requested_by` về `NULL`, `private.consent_json` (`0006_social.sql:1538`) gọi `private.person(null)` trả về JSON `'requested_by': null`. Ở phía app, `consentFromJson` (`social_mapping.dart:244`) gọi thẳng `personFromJson(r['requested_by'])` không chấp nhận `null`, khiến `_map(null)` (`dòng 13`) ném `FormatException: expected a JSON object`.
- **Hướng sửa:** Cho phép `ShareConsent.requestedBy` là `SocialPerson?` (hoặc fallback sang đối tượng ẩn danh khi `r['requested_by'] == null`) và dùng `_personOrNull(r['requested_by'])` trong `consentFromJson`.
- **Test tạm:** `apps/mobile/test/zz_bugscan/data_app_bugs_test.dart` (test `B10`) — chạy fail với `FormatException: expected a JSON object` tại `consentFromJson` (`social_mapping.dart:244`).
- **Claude kiểm chứng:** `private.person(null)` trả null, `consentFromJson` (`social_mapping.dart:244`) gọi `personFromJson(null)` và ném `FormatException`.

#### A-B11. `sanitizeJourneyDna` cắt chuỗi theo UTF-16 code units làm vỡ đôi surrogate pair của emoji, khiến `update_journey` lỗi JSON trên Postgres

- **Vị trí:** `packages/ourney_core/lib/src/models.dart:399-402` (đối chiếu `supabase/migrations/0012_journey_edit.sql:23`)
- **Mức độ:** vừa
- **Độ chắc:** chắc chắn
- **Tình huống gây lỗi:** Khi tạo hoặc sửa hành trình, người dùng nhập trường DNA văn bản (`trophy` tối đa 24 ký tự, `habit` 40, `place` 60, `reason` 80) có một emoji nằm đúng ở vị trí giới hạn (ví dụ `trophy` gồm 23 ký tự thường + `🏆`, tổng cộng đúng 24 ký tự hợp lệ theo `char_length` của Postgres). Hàm `sanitizeJourneyDna` cắt chuỗi thành ký tự lỗi `\uFFFD`/high surrogate lẻ `0xD83C` ở cuối, vừa làm hỏng chữ hiển thị vừa khiến Postgres `jsonb` từ chối RPC `update_journey` (`22P02 invalid input syntax for type json`).
- **Vì sao sai:** `_clipDna` (`models.dart:399-402`) kiểm tra `v.length > max ? v.substring(0, max) : v`. Trong Dart, `String.length` và `substring` đếm đơn vị UTF-16: một emoji ngoài BMP như `🏆` (`U+1F3C6`) chiếm 2 UTF-16 code units, nên chuỗi 24 code points có `v.length == 25 > 24`, và `v.substring(0, 24)` cắt đứt ngay giữa cặp surrogate, để lại nửa cao `0xD83C` không hợp lệ.
- **Hướng sửa:** Cắt theo Unicode scalar values (`Runes`): `final runes = v.runes; return max != null && runes.length > max ? String.fromCharCodes(runes.take(max)) : v;`.
- **Test tạm:** `packages/ourney_core/test/zz_bugscan/core_bugs_test.dart` (test `sanitizeJourneyDna keeps valid 24-rune emoji string without splitting UTF-16 surrogate pair`) — chạy fail vì chuỗi kết quả chứa lone UTF-16 surrogate.
- **Claude kiểm chứng:** `_clipDna` cắt theo UTF-16. Dart `jsonEncode` escape surrogate lẻ thành `\udXXX`, Postgres từ chối. Hiếm: emoji đúng ở ký tự giới hạn. Đi cùng B12 thì mất luôn layout, cover, color, giờ nhắc, DNA (outbox chết).

#### A-B12. `DataJourneyRepository.create` làm mất cục bộ `reminderTime`, `layout`, `cover`, `color`, `dna` khi `update_journey` thất bại ngay sau `create_journey`

- **Vị trí:** `apps/mobile/lib/data/repositories/journey_repository.dart:103-109,141-157`
- **Mức độ:** vừa
- **Độ chắc:** chắc chắn
- **Tình huống gây lỗi:** Người dùng tạo hành trình mới có chọn giờ nhắc (`reminderTime`), giao diện (`layout`), bìa (`cover`), màu (`color`) và câu trả lời `dna`. Lời gọi đầu tiên `create_journey` thành công, nhưng lời gọi nối tiếp `update_journey` gặp rớt mạng chập chờn: `create()` vẫn trả về `Journey` nhưng cả 5 trường trên trong SQLite cục bộ và đối tượng trả về đều là `null`, làm mất giao diện vừa chọn và bỏ qua việc đặt lịch thông báo nhắc giờ ngay sau khi tạo.
- **Vì sao sai:** `create_journey` trên server không nhận các cột của migration `0012`, nên `ctx.store.applyJourney(row)` ở dòng `103` ghi `null` cho cả 5 cột vào `_db.journeys`. Khi `_applyExtras` (`dòng 141-157`) bắt `on OurneyException`, nó chỉ đẩy `OutboxKind.updateJourney` vào hàng đợi outbox (không cập nhật `_db.journeys` cục bộ và cũng không kích hoạt `outbox.flush()`), rồi dòng `106-109` đọc lại dòng thiếu từ `_db.journeys` trả cho UI; ngoài ra `on OurneyException` còn nuốt luôn cả các lỗi không phải `offline` (như `invalid`).
- **Hướng sửa:** Trước hoặc trong khối `catch` của `_applyExtras`, ghi ngay các trường `extras` vào `_db.journeys` cục bộ (như `update()` đã làm ở dòng `193-204`), chỉ enqueue outbox khi lỗi là `offline` (các lỗi khác thì `rethrow`), và gọi `outbox.flush()` để lên lịch thử lại.
- **Test tạm:** `apps/mobile/test/zz_bugscan/data_app_bugs_test.dart` (test `B12`) — chạy fail: `Expected: '07:30', Actual: <null>`.
- **Claude kiểm chứng:** `_applyExtras` (`journey_repository.dart:141-157`) bắt mọi `OurneyException`, chỉ enqueue, không ghi local. Tự lành khi outbox đẩy lại nếu lỗi là offline.

#### A-B13. `resolveRedirect` đánh rơi universal link `https://ourney.tech/...` khi người dùng đi qua cổng onboarding, đăng nhập hoặc EULA

- **Vị trí:** `apps/mobile/lib/app/redirect.dart:20-30,88-95,107-128` (liên quan `apps/mobile/lib/app/app_routes.dart:50-53`, `apps/mobile/android/app/src/main/AndroidManifest.xml:32-33`)
- **Mức độ:** vừa
- **Độ chắc:** chắc chắn
- **Tình huống gây lỗi:** Người dùng chưa đăng nhập (hoặc mới cài app / chưa chấp nhận EULA) mở link kết bạn `https://ourney.tech/f/<token>` (được đặc tả tại `AppRoutes.friendInvite`, `app_routes.dart:50-51`). Sau khi hoàn tất đăng nhập/onboarding/EULA, router không mở `/f/<token>` mà đẩy người dùng về màn camera `/capture`, làm mất lời mời kết bạn. Ngoài ra trên Android, `AndroidManifest.xml:32-33` cũng chỉ khai báo `ourney://join` và `ourney://journey`, thiếu `ourney://friend` nên custom-scheme `ourney://friend/<token>` không mở được app trên Android.
- **Vì sao sai:** `normalizeDeepLink` (`redirect.dart:20-21`) trả `null` cho mọi URI không có scheme `ourney`. Khi `uri` là `https://ourney.tech/f/tok123`, `_withFrom` (`dòng 122`) và nhánh cổng EULA (`dòng 90`) lưu nguyên `uri.toString()` (`https://ourney.tech/f/tok123`) vào tham số `?from=`. Khi người dùng vượt qua cổng, `safeFrom` (`dòng 111-113`) từ chối mọi giá trị không bắt đầu bằng `'/'` hoặc có `hasScheme`/`hasAuthority`, trả về `null` và fallback về `AppRoutes.capture` (`dòng 101`).
- **Hướng sửa:** Chuẩn hóa các URI `https://ourney.tech/...` trong `normalizeDeepLink` về đường dẫn nội bộ `${uri.path}${uri.hasQuery ? '?${uri.query}' : ''}` (và chỉ ghi phần `path + query` vào `_withFrom`), đồng thời bổ sung `<data android:scheme="ourney" android:host="friend" />` vào `AndroidManifest.xml`.
- **Test tạm:** `apps/mobile/test/zz_bugscan/data_app_bugs_test.dart` (test `B13`) — chạy fail: `Expected: '/f/tok123456', Actual: '/capture'`.
- **Claude kiểm chứng:** Không có Android App Links hay iOS `applinks`, nên link https không bao giờ mở app: phần "rơi link https qua cổng" chỉ là lỗi tiềm ẩn. Phần thật: `AndroidManifest.xml:32-33` thiếu host `friend`, trong khi link chia sẻ là `https://ourney.tech/f/<token>` (`social_paths.dart:15`) và route ghi `ourney://friend/<token>`. iOS khai báo cả scheme `ourney` nên không bị.

#### A-B14. `computeStreak` báo sai `atRisk = true` vào ngày ngay sau khi hành trình có thời hạn cố định đã hoàn thành và kết thúc

- **Vị trí:** `packages/ourney_core/lib/src/streak.dart:76-82,98`
- **Mức độ:** vừa
- **Độ chắc:** chắc chắn
- **Tình huống gây lỗi:** Người dùng tạo hành trình 7 ngày (`start = 2026-11-01`, `durationDays = 7`) và check-in đủ cả 7 ngày (`01/11` đến `07/11`, đạt `completed = 7`, `progress = 1.0`). Sang ngày thứ 8 (`today = 2026-11-08`), khi cửa sổ hành trình đã đóng (nếu cố check-in sẽ bị chặn bởi lỗi `ended` ở cả client lẫn server), `computeStreak` vẫn trả về `atRisk = true`, khiến UI và bộ lập lịch cảnh báo nhận tín hiệu "chuỗi sắp mất hôm nay" dù người dùng không thể check-in thêm.
- **Vì sao sai:** Ở ngày `todayIdx == durationDays` (`7`), `lastIdx` là `durationDays - 1` (`6`). Vòng lặp tại `streak.dart:76-81` đặt `cursor = todayIdx - 1` (`6`), đếm ngược trong `windowed` được `current = 7`, trong khi `checkedInToday` là `false` (`all` không chứa ngày 8 ngoài cửa sổ). Dòng `98` tính `atRisk: !checkedInToday && current > 0` mà không kiểm tra xem hôm nay (`todayIdx <= lastIdx`) còn nằm trong cửa sổ cho phép check-in hay không.
- **Hướng sửa:** Đổi dòng `98` của `streak.dart` thành `atRisk: todayIdx <= lastIdx && !checkedInToday && current > 0`.
- **Test tạm:** `packages/ourney_core/test/zz_bugscan/core_bugs_test.dart` (test `computeStreak does not flag atRisk on the day after a fixed-duration journey window ended`) — chạy fail: `Expected: false, Actual: <true>`.
- **Claude kiểm chứng:** Không code app nào đọc `StreakSummary.atRisk`. Màn Hôm nay tự tính lại cùng công thức (`today_sheet.dart:47-50`), và hành trình không tự chuyển `ended` (chỉ `end_journey` thủ công, `0004:336`). Ngày 8 của hành trình 7 ngày vẫn hiện "Sắp mất chuỗi". Sửa cả `streak.dart:98` lẫn `today_sheet.dart` (hoặc lọc hành trình hết hạn).

#### A-B15. Khi thành viên đăng nhiều ảnh/ngày (`0014`) và chỉ ảnh mới nhất bị báo cáo, `group_today` hiển thị thành viên đó như chưa check-in hôm nay

- **Vị trí:** `supabase/migrations/0014_multi_photo_per_day.sql:53-68` và `apps/mobile/lib/data/mapping.dart:304-305`
- **Mức độ:** thấp
- **Độ chắc:** chắc chắn
- **Tình huống gây lỗi:** Thành viên M đăng 2 ảnh trong cùng ngày hôm nay; một thành viên khác báo cáo (`report_content`) chỉ tấm ảnh thứ 2 mới nhất còn tấm ảnh thứ 1 hoàn toàn hợp lệ. Trên màn nhóm của người báo cáo, M bị hiển thị như chưa check-in hôm nay (`todayCheckIn == null`, `checkedIn == false`) thay vì hiển thị tấm ảnh thứ 1.
- **Vì sao sai:** Trong `public.group_today` (`0014_multi_photo_per_day.sql:60-68`), subquery `c` lấy `order by c2.captured_at desc, c2.id desc limit 1` trước rồi mới kiểm tra `private.has_reported(c.id)` ở subquery `r` và xóa `checkin_id`, `thumb_path`, `captured_at` về `null`. Phía client, `memberTodayFromRemote` (`mapping.dart:305`) tính `final checkedIn = (r['checked_in'] as bool? ?? false) && checkInId != null;` nên biến thành `false` và tạo `MemberToday(todayCheckIn: null)`.
- **Hướng sửa:** Đưa điều kiện `and not private.has_reported(c2.id)` vào thẳng bên trong subquery `c` của `group_today` (`0014_multi_photo_per_day.sql:63-66`), đồng thời giữ một `exists(...)` riêng cho cột boolean `checked_in` nếu mọi ảnh trong ngày đều bị ẩn.
- **Claude kiểm chứng:** `group_today` (`0014:60-68`) chọn ảnh mới nhất rồi mới ẩn nếu bị báo cáo; client `mapping.dart:305` đổi thành chưa check-in. 0014 chưa deploy nên sửa thẳng.

#### A-B16. Lời mời `group_invitations` đang chờ không được đóng khi người được mời tự tham gia nhóm bằng mã mời (`join_by_code`)

- **Vị trí:** `supabase/migrations/0013_unlimited_journeys.sql:170-180`, `supabase/migrations/0008_group_invites.sql:234-260`, `supabase/migrations/0010_invite_management.sql:163`
- **Mức độ:** thấp
- **Độ chắc:** chắc chắn
- **Tình huống gây lỗi:** Thành viên nhóm gửi lời mời trong app (`invite_to_group`) cho bạn B, đồng thời gửi luôn mã/link mời nhóm qua tin nhắn ngoài. B vào nhóm bằng mã (`join_by_code`): dù B đã là thành viên đang hoạt động trong nhóm, lời mời trong `group_invitations` vẫn ở trạng thái `'pending'` suốt 7 ngày, làm `inbox_counts().group_invitations` đếm dư badge chưa đọc, `my_group_invitations()` vẫn hiện nút Chấp nhận/Từ chối và `journey_group_invitations()` của chủ nhóm vẫn báo B chưa phản hồi.
- **Vì sao sai:** `join_by_code` (`0013_unlimited_journeys.sql:170-180`) chỉ ghi bảng `memberships` mà không cập nhật các dòng `public.group_invitations` đang `'pending'` của `(j.id, uid)`, còn `inbox_counts`, `my_group_invitations` (`0008_group_invites.sql:234-260`) và `journey_group_invitations` (`0010_invite_management.sql:163`) cũng không lọc bỏ trường hợp `private.is_active_member(i.journey_id, i.invitee_id)`.
- **Hướng sửa:** Trong `join_by_code` (`0013_unlimited_journeys.sql:179`), thêm `update public.group_invitations set status = 'accepted', responded_at = now() where journey_id = j.id and invitee_id = uid and status = 'pending';`.
- **Claude kiểm chứng:** `join_by_code` (`0013:170-180`) không đóng lời mời `pending`. 0013 chưa deploy nên sửa thẳng.

### 2.2. Đợt B: `bug-scan-b` (camera, check-in, tạo và sửa hành trình, nhắc giờ)

Worker tự chấm: 4 cao, 10 vừa, 1 thấp. 15 lỗi, đều có test tạm fail đúng như báo cáo.

| Mã | Lỗi | Vị trí chính | Mức (worker) | Mức (Claude) | Trạng thái |
| --- | --- | --- | --- | --- | --- |
| B-B1 | Số cân vừa chọn trên thanh trượt Camera bị ghi đè bởi số cân của lần điểm danh trước khi sang màn đăng ảnh | `apps/mobile/lib/features/camera/capture_screen.dart:378` | cao | vừa | open |
| B-B2 | Hẹn giờ tự đóng 1.8s sau lần điểm danh đầu tiên tự tắt bảng xin quyền thông báo, khóa vĩnh viễn lời mời nhắc giờ và ném `StateError` trên `WidgetRef` đã huỷ | `apps/mobile/lib/features/checkin/checkin_screen.dart:217-228` | cao | cao | open |
| B-B3 | `DayTicker` tính khoảng chờ âm trong giờ lặp lại khi đổi giờ mùa đông (DST fall-back), gây vòng lặp `Timer` 0ms liên tục suốt 45 phút | `apps/mobile/lib/features/journeys/ui/day_ticker.dart:30-42` | cao | thấp | open |
| B-B4 | `CaptureScreen._start` gọi `ref.read` trong khối `finally` không kiểm tra `mounted`, ném `StateError` khi rời màn Camera lúc phần cứng đang khởi động | `apps/mobile/lib/features/camera/capture_screen.dart:225-231` | cao | thấp | open |
| B-B5 | Gộp cứng một bản ghi mỗi ngày trong `JourneyProgress` làm mất tổng km, số khoảnh khắc, điểm biểu đồ cân nặng và ảnh nửa kia khi chụp nhiều ảnh cùng ngày | `apps/mobile/lib/features/journeys/domain/journey_progress.dart:65-72` | vừa | vừa | open |
| B-B6 | `DayViewerScreen` chỉ hiển thị ảnh muộn nhất trong ngày, làm ẩn toàn bộ các ảnh và chú thích chụp sớm hơn cùng ngày | `apps/mobile/lib/features/journeys/ui/day_viewer_screen.dart:55-63` | vừa | vừa | open |
| B-B7 | Hành trình có thời hạn đã qua `endDate` vẫn hiện như đang hoạt động: Hub và Camera giục chụp hôm nay nhưng bấm Đăng luôn lỗi `ended`, còn thành viên nhóm không bao giờ xem được `Wrapped` | `apps/mobile/lib/features/journeys/ui/journeys_list_screen.dart:385-388` | vừa | vừa | open |
| B-B8 | Kết thúc hành trình từ màn Chỉnh sửa (`JourneyEditScreen`) quên gọi `reminderScheduler.reschedule()`, để thông báo nhắc giờ tiếp tục nổ sau khi hành trình đã kết thúc | `apps/mobile/lib/features/journeys/ui/edit/journey_edit_screen.dart:216-230` | vừa | thấp | open |
| B-B9 | Chọn giờ nhắc trong màn Chỉnh sửa hành trình không bật cờ `enabled` của `ReminderSetting` và không xin quyền thông báo, khiến lời nhắc không bao giờ chạy | `apps/mobile/lib/features/journeys/ui/edit/journey_edit_screen.dart:169-174` | vừa | vừa | open |
| B-B10 | Chọn chế độ Cặp đôi ở bước 3 luồng tạo hành trình hiển thị vé `couple` nhưng lúc lưu làm rơi `PersonaSkinId.coupleRituals`, không khóa khi `localOnly` và gắn sai nhãn `Squad` lúc đăng ảnh | `apps/mobile/lib/features/journeys/ui/create/create_flow_screen.dart:185, 320-341` | vừa | vừa | open |
| B-B11 | Chọn ngày chuyến đi (Travel DNA): bấm "Chưa định ngày về" vẫn giữ cứng 7 ngày, chuyến đi 2–6 ngày bị lờ đi giữ 7 ngày, và lệch -1 ngày khi qua mốc đổi giờ DST mùa xuân | `apps/mobile/lib/features/journeys/ui/create/create_flow_screen.dart:554-568` | vừa | vừa | open |
| B-B12 | Đổi màu vé ở bước Xem lại không lưu `color` vào `JourneyDraft`, và tắt công tắc "Ẩn số cân" ở bước DNA giảm cân vẫn bị ép ẩn số cân | `apps/mobile/lib/features/journeys/ui/create/create_flow_screen.dart:72, 77, 320-348` | vừa | vừa | open |
| B-B13 | Xoá trắng trường phần thưởng/cúp (`edit-trophy`) trong màn Chỉnh sửa hành trình không xoá được giá trị cũ trong `dna` | `apps/mobile/lib/features/journeys/ui/edit/journey_edit_screen.dart:145-160` | vừa | thấp | open |
| B-B14 | Đặt giờ nhắc hằng ngày lúc `21:00` khi đang có chuỗi (`streak >= 1`) lên lịch trùng 2 thông báo hệ thống nổ cùng lúc cho một hành trình | `apps/mobile/lib/features/reminders/domain/reminder_plan.dart:195-233` | vừa | thấp | open |
| B-B15 | `journeyHomeOfflineProvider` gọi `c.add(false)` sau khi `StreamController` đã đóng nếu provider huỷ trong lúc đang chờ `checkConnectivity()`, ném `StateError` không bắt được | `apps/mobile/lib/features/journeys/ui/home/journey_home_intro.dart:13-35` | thấp | vừa | open |


#### B-B1. Số cân vừa chọn trên thanh trượt Camera bị ghi đè bởi số cân của lần điểm danh trước khi sang màn đăng ảnh

- **Vị trí:** `apps/mobile/lib/features/camera/capture_screen.dart:378` (kèm `apps/mobile/lib/features/camera/capture_screen.dart:401`, `apps/mobile/lib/features/checkin/checkin_screen.dart:65-69`)
- **Mức độ:** cao
- **Độ chắc:** chắc chắn
- **Tình huống gây lỗi:** Ở hành trình giảm cân (`TemplateId.weightLoss`) đã có ít nhất một lần điểm danh kèm cân nặng (ví dụ Ngày 1 là `65.2 kg`), sang Ngày 2 người dùng kéo thanh trượt cân nặng ngay trên khung ngắm Camera sang mức mới (ví dụ `62.0 kg`) rồi bấm chụp (hoặc chọn ảnh từ thư viện) và bấm Đăng. Bản ghi điểm danh lưu lại `65.2 kg` của ngày cũ thay vì `62.0 kg` vừa chọn; ngoài ra nếu bấm Chụp lại (`Retake`) thì `pendingWeightProvider` cũng không được dọn.
- **Vì sao sai:** `CaptureSkinOverlay` trên `CaptureScreen` ghi số cân người dùng kéo vào `pendingWeightProvider(journey.id)` (`capture_screen.dart:758-760`), nhưng `_capture()` (`capture_screen.dart:378`) và `_pickFromLibrary()` (`capture_screen.dart:401`) lại truyền `initialMetricValue: _latestMetric(journey.id)` vào `CapturedPhoto`. Sang `CheckinScreen.initState` (`checkin_screen.dart:65-69`), `prefill = initialMetric ?? ref.read(pendingWeightProvider(photo.journeyId))` ưu tiên `initialMetric` khác `null`, làm mất hoàn toàn giá trị trong `pendingWeightProvider`.
- **Hướng sửa:** Trong `CheckinScreen.initState`, ưu tiên `ref.read(pendingWeightProvider(photo.journeyId)) ?? photo.initialMetricValue`, đồng thời xoá `pendingWeightProvider` khi huỷ/chụp lại để không rò sang lần sau.
- **Test tạm:** `apps/mobile/test/zz_bugscan_b/b02_camera_weight_slider_lost_test.dart` — chạy fail đúng lỗi (`Expected: '200'`, `Actual: '65.2'`).
- **Claude kiểm chứng:** `capture_screen.dart:378,401` luôn truyền `_latestMetric` (số của lần trước), `checkin_screen.dart:65-69` ưu tiên số đó hơn `pendingWeightProvider`. Số cũ hiện trong ô nhập ở màn đăng, người dùng sửa tay được trước khi đăng.

#### B-B2. Hẹn giờ tự đóng 1.8s sau lần điểm danh đầu tiên tự tắt bảng xin quyền thông báo, khóa vĩnh viễn lời mời nhắc giờ và ném `StateError` trên `WidgetRef` đã huỷ

- **Vị trí:** `apps/mobile/lib/features/checkin/checkin_screen.dart:217-228` (kèm `apps/mobile/lib/features/checkin/checkin_success.dart:54`, `apps/mobile/lib/features/reminders/data/reminder_permission.dart:43`)
- **Mức độ:** cao
- **Độ chắc:** chắc chắn
- **Tình huống gây lỗi:** Người dùng hoàn tất điểm danh đầu tiên (không phải mốc 7/14/30 ngày), màn `CheckinSuccessView` hiện lên cùng lúc bảng `showNotificationSheet` mời bật thông báo nhắc giữ chuỗi. (1) Nếu người dùng đọc quá `1.8s` chưa kịp bấm "Bật thông báo", bảng xin quyền tự biến mất, màn `CheckinScreen` bị kẹt lại không tự quay về Camera, và ứng dụng không bao giờ mời bật quyền lại nữa. (2) Nếu người dùng bấm "Bật thông báo" trước `1.8s` nhưng hộp thoại quyền của hệ điều hành trả lời sau mốc `1.8s`, ứng dụng ném `StateError` không bắt được và bỏ qua việc lên lịch thông báo (`reschedule`).
- **Vì sao sai:** `CheckinScreen._post` (`checkin_screen.dart:217-228`) vừa dựng `CheckinSuccessView` (khởi tạo `Timer(1800ms, widget.onDone)` tại `checkin_success.dart:54` gọi `context.pop()`) vừa chạy `unawaited(offerReminderPermission(...))`. `offerReminderPermission` (`reminder_permission_prompt.dart:49-56`) ghi ngay `ReminderPrefs.promptOffered = true` rồi mở modal bottom sheet trên cùng `Navigator`; ở giây `1.8`, `context.pop()` pop nhầm chính sheet này thay vì màn `/checkin`. Nếu sheet đã đóng để chờ `gateway.requestPermission()`, `context.pop()` ở giây `1.8` huỷ `CheckinScreen`, khiến `requestReminderPermission(ref)` (`reminder_permission.dart:43`) gọi `ref.invalidate` và `ref.read` trên `WidgetRef` đã unmount.
- **Hướng sửa:** `await offerReminderPermission(...)` trước khi bắt đầu đếm ngược tự đóng (hoặc tạm dừng `_autoClose` khi đang mở hộp thoại quyền), và trong `requestReminderPermission` truyền trực tiếp `NotificationGateway` + `ReminderScheduler` đã lấy trước `await` thay vì đọc lại từ `WidgetRef`.
- **Test tạm:** `apps/mobile/test/zz_bugscan_b/b01_checkin_permission_autoclose_test.dart` — cả 2 test đều fail đúng lỗi (sheet bị pop ở 1.8s; trả lời hộp thoại OS sau 1.8s ném `Bad state: Using "ref" when a widget is about to or has been unmounted is unsafe` tại `reminder_permission.dart:43` và `gateway.scheduled` rỗng).
- **Claude kiểm chứng:** Trùng mục "Ngoài phạm vi" số 1 và 6 của `bug-scan`. Mọi người dùng mới: lần check-in đầu, bảng xin quyền thông báo tự đóng sau 1,8 giây và không bao giờ hiện lại (`promptOffered = true`).

#### B-B3. `DayTicker` tính khoảng chờ âm trong giờ lặp lại khi đổi giờ mùa đông (DST fall-back), gây vòng lặp `Timer` 0ms liên tục suốt 45 phút

- **Vị trí:** `apps/mobile/lib/features/journeys/ui/day_ticker.dart:30-42`
- **Mức độ:** cao
- **Độ chắc:** chắc chắn
- **Tình huống gây lỗi:** Người dùng ở múi giờ có DST (ví dụ `America/New_York` ngày `2026-11-01` lúc `01:00–01:44:59 EST`, tức lần lặp thứ hai của khung 1 giờ sáng sau khi lùi đồng hồ) mở màn Hub (`JourneysListScreen`) hoặc Chi tiết hành trình (`JourneyDetailScreen`). Ngay lập tức giao diện bị treo/ngốn CPU liên tục cho tới `01:45 EST`.
- **Vì sao sai:** `_DayTickerState._schedule()` (`day_ticker.dart:31-38`) lấy `now = DateTime.now()` rồi dựng `DateTime(now.year, now.month, now.day, now.hour)` — hàm tạo `DateTime` địa phương của Dart phân giải giờ nhập nhằng về lần xuất hiện đầu tiên (`01:00 EDT = 05:00Z`), nên khi cộng `(now.minute ~/ 15 + 1) * 15` phút (`05:15Z..05:45Z`) thì `next` vẫn nhỏ hơn `now` (`06:00Z..06:44:59Z`). `next.difference(now)` ra số âm (ví dụ `-50 phút`), làm `Timer(negativeDuration, ...)` nổ ngay lập tức như `Duration.zero`, gọi `ref.invalidate(journeysNowProvider)` rồi đệ quy `_schedule()` vô tận; ngoài ra nơi này còn dùng `DateTime.now()` thay vì `journeysClockProvider`.
- **Hướng sửa:** Tính mốc 15 phút kế tiếp trên trục UTC (`final nowUtc = ref.read(journeysClockProvider).now().toUtc();` rồi làm tròn lên bội số 15 phút theo `millisecondsSinceEpoch`) để không bao giờ phụ thuộc giờ địa phương lặp lại khi đổi DST.
- **Test tạm:** `apps/mobile/test/zz_bugscan_b/b03_travel_dst_and_open_dates_test.dart` (chạy kèm `env TZ=America/New_York`) — fail đúng lỗi (`Expected: > 0:00:00`, `Actual: Duration:<-0:50:00.000000>`).
- **Claude kiểm chứng:** Chỉ xảy ra ở múi giờ có DST (Việt Nam không có), mỗi năm một lần lúc 1 giờ sáng, khi app đang mở.

#### B-B4. `CaptureScreen._start` gọi `ref.read` trong khối `finally` không kiểm tra `mounted`, ném `StateError` khi rời màn Camera lúc phần cứng đang khởi động

- **Vị trí:** `apps/mobile/lib/features/camera/capture_screen.dart:225-231`
- **Mức độ:** cao
- **Độ chắc:** chắc chắn
- **Tình huống gây lỗi:** Người dùng mở tab Camera (khi `permissionAsked` đã bật hoặc vừa bấm tiếp tục) rồi chuyển nhanh sang tab khác / đóng màn hình trong lúc `session.start()` đang chờ phần cứng camera hoặc hộp thoại quyền hệ điều hành. Khi `session.start()` hoàn tất hoặc ném lỗi sau đó, ứng dụng ném `StateError` không bắt được trên `WidgetRef` đã unmount; đồng thời nếu `_start` bị huỷ sớm (`gen != _generation`), cờ `CameraPrefs.permissionAsked` vẫn bị ghi thành `true`.
- **Vì sao sai:** Ở `capture_screen.dart:210` và `:220`, `_start()` đều có chốt `if (!mounted || gen != _generation) return;`, nhưng khối `finally` (`capture_screen.dart:225-231`) vẫn luôn chạy khi thoát khỏi `try/catch` và gọi thẳng `ref.read(sharedPreferencesProvider).setBool(CameraPrefs.permissionAsked, true)` mà không kiểm tra `mounted`.
- **Hướng sửa:** Chỉ ghi `permissionAsked = true` khi `mounted && gen == _generation` (hoặc lấy tham chiếu `SharedPreferencesWithCache` trước `await session.start` và chỉ ghi sau khi lời gọi phần cứng thực sự chạy xong).
- **Test tạm:** `apps/mobile/test/zz_bugscan_b/b04_capture_dispose_and_offline_stream_test.dart` — fail đúng lỗi (`Bad state: Using "ref" when a widget is about to or has been unmounted is unsafe` tại `capture_screen.dart:228:14`).
- **Claude kiểm chứng:** `finally` ở `capture_screen.dart:225-231` gọi `ref.read` sau khi unmount: lỗi async không ai bắt (bản release không văng), và cờ `permissionAsked` bị bật dù chưa hỏi xong.

#### B-B5. Gộp cứng một bản ghi mỗi ngày trong `JourneyProgress` làm mất tổng km, số khoảnh khắc, điểm biểu đồ cân nặng và ảnh nửa kia khi chụp nhiều ảnh cùng ngày

- **Vị trí:** `apps/mobile/lib/features/journeys/domain/journey_progress.dart:65-72` (kèm `apps/mobile/lib/features/journeys/domain/wrapped_story.dart:21-50`, `apps/mobile/lib/features/journeys/ui/journey_detail_screen.dart:400-402`, `apps/mobile/lib/features/journeys/ui/widgets/timeline_variants.dart:47-50, 744-746`)
- **Mức độ:** vừa
- **Độ chắc:** chắc chắn
- **Tình huống gây lỗi:** Sau migration `0014_multi_photo_per_day.sql`, người dùng tập thể thao buổi sáng đăng ảnh kèm `5.0 km`, buổi tối đăng thêm một ảnh giãn cơ không nhập `km` (hoặc buổi sáng nhập cân nặng `62.0 kg` / có ảnh ghép đôi, buổi tối chụp thêm ảnh không nhập số cân). Màn Chi tiết hành trình và `Wrapped` báo tổng quãng đường `0.0 km`, biểu đồ cân nặng mất điểm ngày hôm đó, cuộn phim Memory và `Wrapped` đếm thiếu số bức ảnh (`moments = 1` thay vì `2`).
- **Vì sao sai:** `JourneyProgress.compute` (`journey_progress.dart:65-72`) nén toàn bộ `checkIns` vào `Map<LocalDate, CheckIn> byDate` chỉ giữ bản ghi có `capturedAt` muộn nhất trong ngày và không giữ danh sách đầy đủ. `WrappedStats.from` (`wrapped_story.dart:22-50`), `_metricSeries` (`journey_detail_screen.dart:400-402`), `QuietTimeline` (`timeline_variants.dart:47-50`) và `CoupleTimeline` (`timeline_variants.dart:744-746`) đều chỉ đọc từ `checkInsByDate` / `TimelineDay.checkIn` duy nhất đó.
- **Hướng sửa:** Giữ thêm `allCheckIns` / `Map<LocalDate, List<CheckIn>> checkInsOnDate` (sắp theo `capturedAt`) trong `JourneyProgress`; tính `moments` bằng tổng số ảnh, cộng `km` trên mọi ảnh trong ngày, và lấy `metricValue` / `partnerPhotoPath` mới nhất khác `null` của ngày đó cho biểu đồ/diptych.
- **Test tạm:** `apps/mobile/test/zz_bugscan_b/b05_multi_photo_per_day_journeys_test.dart` — cả 2 test thống kê đều fail đúng lỗi (`moments`: `Expected: <2>, Actual: <1>`; `totalKm`: `Expected: <5.0>, Actual: <0.0>`).
- **Claude kiểm chứng:** Phần còn dở của tính năng nhiều ảnh mỗi ngày: `docs/design-v2/multi-photo-day.md` ghi rõ Wrapped đếm "N khoảnh khắc trong M ngày" và app Flutter chưa làm theo.

#### B-B6. `DayViewerScreen` chỉ hiển thị ảnh muộn nhất trong ngày, làm ẩn toàn bộ các ảnh và chú thích chụp sớm hơn cùng ngày

- **Vị trí:** `apps/mobile/lib/features/journeys/ui/day_viewer_screen.dart:55-63` (kèm `apps/mobile/lib/features/journeys/domain/journey_progress.dart:116-127`)
- **Mức độ:** vừa
- **Độ chắc:** chắc chắn
- **Tình huống gây lỗi:** Người dùng chụp 2–3 bức ảnh trong cùng một ngày (đã được cho phép từ `0014_multi_photo_per_day.sql`) rồi bấm vào ngày đó trên dòng thời gian để xem lại. Màn `DayViewerScreen` chỉ hiện duy nhất bức ảnh cuối cùng trong ngày; người dùng không có cách nào vuốt hay chọn xem các bức ảnh, chú thích và thông số đã đăng sớm hơn trong ngày đó.
- **Vì sao sai:** Trong `_DayViewerScreenState.build` (`day_viewer_screen.dart:55-63`), vòng lặp lọc `checkIns` theo `c.localDate == date` chỉ giữ lại một biến `CheckIn? checkIn` có `capturedAt` lớn nhất và dựng khung ảnh đơn thay vì `PageView`/danh sách theo tất cả bản ghi cùng `localDate`.
- **Hướng sửa:** Thu thập toàn bộ `List<CheckIn>` có `c.localDate == date` (sắp tăng/giảm theo `capturedAt`) và hiển thị bằng `PageView` kèm chỉ báo trang `1/N` trên `DayViewerScreen` (đồng thời truyền số lượng ảnh của ngày vào `TimelineDay` để hiện huy hiệu `+N`).
- **Test tạm:** `apps/mobile/test/zz_bugscan_b/b05_multi_photo_per_day_journeys_test.dart` — fail đúng lỗi (`Found 0 widgets with text "Morning coffee shot"`).
- **Claude kiểm chứng:** Cùng nhóm với B5: thiết kế yêu cầu màn ngày có dải ảnh vuốt cho mọi ảnh trong ngày. Hiện ảnh chụp sớm hơn bị ẩn hẳn.

#### B-B7. Hành trình có thời hạn đã qua `endDate` vẫn hiện như đang hoạt động: Hub và Camera giục chụp hôm nay nhưng bấm Đăng luôn lỗi `ended`, còn thành viên nhóm không bao giờ xem được `Wrapped`

- **Vị trí:** `apps/mobile/lib/features/journeys/ui/journeys_list_screen.dart:385-388` (kèm `apps/mobile/lib/features/journeys/ui/journey_actions.dart:33-36`, `apps/mobile/lib/features/journeys/ui/journey_detail_screen.dart:119, 299, 334`, `apps/mobile/lib/features/camera/camera_providers.dart:21`)
- **Mức độ:** vừa
- **Độ chắc:** chắc chắn
- **Tình huống gây lỗi:** Một hành trình có `durationDays = 7` (`startDate = 2026-10-01`, `endDate = 2026-10-07`) bước sang ngày `2026-10-16` mà chủ hành trình chưa bấm tay "Kết thúc hành trình". Màn Hub không bao giờ đạt trạng thái hoàn tất trong ngày (`allDone`), luôn treo thẻ `TodayCard` giục chụp cho hành trình đã hết hạn; khi người dùng bấm chụp và bấm Đăng thì luôn bị chặn bởi lỗi `OurneyErrorCode.ended`. Đồng thời nút xem `Wrapped` bị ẩn hoàn toàn — riêng thành viên nhóm (`role != owner`) không có quyền gọi `end_journey` nên bị kẹt vĩnh viễn không thể mở `Wrapped`.
- **Vì sao sai:** Không có cron hay logic tự chuyển `status` sang `ended` khi `today.isAfter(endDate)`, trong khi `DataCheckInRepository.submit` (`check_in_repository.dart:72-75`) và trigger DB từ chối mọi điểm danh sau `endDate`. Tuy vậy `JourneysListScreen` (`:385-388`), `activeJourneysProvider` của Camera (`camera_providers.dart:21`), `JourneyDetailScreen` (`:119, 299, 334`) và `JourneyPerms` (`journey_actions.dart:35`, `canWrap: !active`) chỉ kiểm tra `j.status == JourneyStatus.active` mà không xét `progress.today.isAfter(endDate)`.
- **Hướng sửa:** Bổ sung getter `bool isPastEndDate(LocalDate today)` trên `JourneyProgress` / `Journey`; coi hành trình đã qua `endDate` là không còn nhận ảnh hôm nay trên Hub/Camera/Detail, mở `canWrap = !active || pastEndDate`, và gợi ý chủ hành trình chốt kết thúc.
- **Test tạm:** `apps/mobile/test/zz_bugscan_b/b06_expired_journey_and_edit_bugs_test.dart` — fail đúng lỗi (`TodayCard` vẫn hiển thị trên Hub cho hành trình đã quá hạn 9 ngày).
- **Claude kiểm chứng:** Cùng gốc với B14 của `bug-scan`: không có gì tự chuyển hành trình hết hạn sang `ended` (chỉ `end_journey` thủ công). Gộp chung một lần sửa.

#### B-B8. Kết thúc hành trình từ màn Chỉnh sửa (`JourneyEditScreen`) quên gọi `reminderScheduler.reschedule()`, để thông báo nhắc giờ tiếp tục nổ sau khi hành trình đã kết thúc

- **Vị trí:** `apps/mobile/lib/features/journeys/ui/edit/journey_edit_screen.dart:216-230`
- **Mức độ:** vừa
- **Độ chắc:** chắc chắn
- **Tình huống gây lỗi:** Người dùng bật nhắc giờ hằng ngày cho hành trình rồi vào màn Chỉnh sửa hành trình (`JourneyEditScreen`), bấm "Kết thúc hành trình" (`edit-end` -> `edit-end-confirm`) và khoá máy/đóng app. Các thông báo nhắc giờ hằng ngày và cảnh báo giữ chuỗi 21:00 đã nạp sẵn cho 14 ngày tới trên hệ điều hành vẫn tiếp tục nổ cho hành trình đã kết thúc.
- **Vì sao sai:** Khác với `JourneyDetailScreen._run` (`journey_detail_screen.dart:499`) có gọi `unawaited(ref.read(reminderSchedulerProvider).reschedule())` sau khi kết thúc/lưu trữ/xoá, `_JourneyEditViewState._confirmEnd` (`journey_edit_screen.dart:224-226`) chỉ gọi `await ref.read(journeyRepositoryProvider).end(j.id)` rồi chuyển sang `Wrapped` mà không gọi `reschedule()`.
- **Hướng sửa:** Gọi `unawaited(ref.read(reminderSchedulerProvider).reschedule());` ngay sau `await ref.read(journeyRepositoryProvider).end(j.id);` trong `JourneyEditScreen._confirmEnd`.
- **Test tạm:** `apps/mobile/test/zz_bugscan_b/b06_expired_journey_and_edit_bugs_test.dart` — fail đúng lỗi (`gateway.scheduled` vẫn còn nguyên 8 thông báo `41000..41007` sau khi kết thúc hành trình).
- **Claude kiểm chứng:** `journey_edit_screen.dart:224` không gọi `reschedule()`. Lifecycle hook (`reminder_scheduler.dart:222`) xếp lại lịch khi app mở lại, nên thông báo thừa chỉ nổ tới lần mở app kế tiếp.

#### B-B9. Chọn giờ nhắc trong màn Chỉnh sửa hành trình không bật cờ `enabled` của `ReminderSetting` và không xin quyền thông báo, khiến lời nhắc không bao giờ chạy

- **Vị trí:** `apps/mobile/lib/features/journeys/ui/edit/journey_edit_screen.dart:169-174` (kèm `apps/mobile/lib/features/reminders/data/reminder_scheduler.dart:92`, `apps/mobile/lib/features/reminders/ui/reminders_screen.dart:208`)
- **Mức độ:** vừa
- **Độ chắc:** chắc chắn
- **Tình huống gây lỗi:** Người dùng tạo một hành trình (chưa vào màn `/reminders` bật công tắc tay), sau đó mở màn Chỉnh sửa hành trình, quay bánh xe chọn giờ nhắc (ví dụ `21:30` hoặc giữ `20:00`) rồi bấm Lưu. Dù `journeys.reminder_time` đã lưu `21:30`, ứng dụng không hỏi quyền thông báo và không lên lịch bất kỳ thông báo nhắc giờ nào (kể cả khi quyền hệ điều hành đã cấp sẵn).
- **Vì sao sai:** Trong `_JourneyEditViewState._save` (`journey_edit_screen.dart:169-174`), `current = reminders.of(j.id)` trả về `ReminderSetting.off` (`enabled: false, time: 20:00`). Khi lưu `current.copyWith(time: _time)`, trường `enabled` vẫn là `false` (và nếu chọn đúng `20:00` thì `current.time != _time` sai nên còn không lưu gì). Trong khi đó `ReminderScheduler` (`reminder_scheduler.dart:92`) chỉ đọc `settings[j.id]?.activeTime` (`enabled ? time : null`) và bỏ qua hoàn toàn `j.reminderTime`.
- **Hướng sửa:** Khi người dùng chủ động lưu giờ nhắc ở `JourneyEditScreen` (hoặc khi đồng bộ về hành trình có `j.reminderTime != null` mà chưa có cấu hình local), lưu `ReminderSetting(enabled: true, time: _time)`, gọi `offerReminderPermission` và `reschedule()`.
- **Test tạm:** `apps/mobile/test/zz_bugscan_b/b06_expired_journey_and_edit_bugs_test.dart` — fail đúng lỗi (`gateway.scheduled` rỗng `{}` sau khi chọn `21:30` và bấm Lưu dù `granted: true`).
- **Claude kiểm chứng:** `journey_edit_screen.dart:169-174` chỉ đổi `time`, giữ nguyên `enabled`. Luồng tạo (`create_flow_screen.dart:342-346`) thì có bật `enabled` và xin quyền.

#### B-B10. Chọn chế độ Cặp đôi ở bước 3 luồng tạo hành trình hiển thị vé `couple` nhưng lúc lưu làm rơi `PersonaSkinId.coupleRituals`, không khóa khi `localOnly` và gắn sai nhãn `Squad` lúc đăng ảnh

- **Vị trí:** `apps/mobile/lib/features/journeys/ui/create/create_flow_screen.dart:185, 320-341` (kèm `apps/mobile/lib/features/journeys/ui/create/steps/who_step.dart:64`, `apps/mobile/lib/features/checkin/checkin_screen.dart:344`)
- **Mức độ:** vừa
- **Độ chắc:** chắc chắn
- **Tình huống gây lỗi:** (1) Người dùng chọn mẫu bất kỳ (ví dụ Thói quen tối giản / Chạy bộ, hoặc chọn Cặp đôi ở bước 1 nhưng đổi sang emoji khác `💞`/`❤️` ở bước 2), đến bước 3 chọn "Cặp đôi" (`journey-kind-couple`), nhập tên hai người và thấy vé xem trước ở bước 5 mang giao diện Cặp đôi (`ticket-couple`); nhưng ngay khi tạo xong, hành trình lại biến thành giao diện đơn/nhóm thường thay vì `coupleRituals`. (2) Ở chế độ không máy chủ (`localOnly`), thẻ Nhóm bị khóa nhưng thẻ Cặp đôi vẫn cho chọn rồi mới báo lỗi lúc bấm Tạo ở bước cuối. (3) Khi đăng ảnh điểm danh cho hành trình Cặp đôi, thẻ quyền riêng tư hiện `"Squad"` thay vì `"Couple"`.
- **Vì sao sai:** `_skinId` trong `CreateFlowScreen` (`create_flow_screen.dart:185`) ép sang `'couple'` khi `_who == CreateWho.couple`, nhưng `_submit()` (`create_flow_screen.dart:320-341`) không truyền `layout: PersonaSkinId.coupleRituals` vào `JourneyDraft`, còn DB tạo nhóm luôn gán `maxMembers = 10` nên `personaSkinOf` (`templates.dart:119-123`) chỉ nhận diện couple qua emoji `💞`/`❤️` hoặc `maxMembers == 2`. Ngoài ra `who_step.dart:64` thiếu `localOnly ? null :`, và `checkin_screen.dart:344` kiểm tra `journey.maxMembers == 2` thay vì `personaSkinOf(journey) == PersonaSkinId.coupleRituals || journey.coupleSelfName != null`.
- **Hướng sửa:** Truyền `layout: (_option?.isCouple ?? false) || _who == CreateWho.couple ? PersonaSkinId.coupleRituals : null` vào `JourneyDraft`, vô hiệu hóa `journey-kind-couple` khi `localOnly`, và nhận diện hành trình cặp đôi ở `checkin_screen.dart:344` qua `journey.coupleSelfName != null || personaSkinOf(journey) == PersonaSkinId.coupleRituals`.
- **Test tạm:** `apps/mobile/test/zz_bugscan_b/b07_reminders_duplicate_and_create_bugs_test.dart` — fail đúng lỗi (`Expected: PersonaSkinId.coupleRituals`, `Actual: PersonaSkinId.minimalistHabit`).
- **Claude kiểm chứng:** `create_flow_screen.dart:320-341` không truyền `layout`. Phần `max_members` do `fix-be` sửa ở server; `personaSkinForTemplate` chỉ nhận cặp đôi theo `maxMembers == 2` với template `custom`, nên vẫn phải sửa phía app.

#### B-B11. Chọn ngày chuyến đi (Travel DNA): bấm "Chưa định ngày về" vẫn giữ cứng 7 ngày, chuyến đi 2–6 ngày bị lờ đi giữ 7 ngày, và lệch -1 ngày khi qua mốc đổi giờ DST mùa xuân

- **Vị trí:** `apps/mobile/lib/features/journeys/ui/create/create_flow_screen.dart:554-568` (kèm `apps/mobile/lib/features/journeys/ui/create/steps/dna_step.dart:89`)
- **Mức độ:** vừa
- **Độ chắc:** chắc chắn
- **Tình huống gây lỗi:** Khi tạo hành trình Du lịch (`TemplateId.travel`): (1) Chọn ngày đi rồi bấm `"Chưa định ngày về"` (`dna-dates-open`), màn hình báo không giới hạn ngày về nhưng hành trình tạo ra vẫn bị khóa cứng `durationDays = 7`. (2) Chọn chuyến đi ngắn 3 ngày (ví dụ mùng 10 đến 12), tóm tắt hiện 10–12 nhưng hành trình tạo ra vẫn là `7` ngày. (3) Ở múi giờ có DST (ví dụ `America/New_York`), chọn chuyến 14 ngày từ `2027-03-14` đến `2027-03-27` thì hành trình bị rút xuống `13` ngày (hoặc chọn đúng 7 ngày qua mốc DST thì bị tính thành `6` ngày rồi rơi về `7` cũ).
- **Vì sao sai:** Trong `_applyDates(DnaDates d)` (`create_flow_screen.dart:554-568`), khi `d.end == null` hàm `return` sớm ở dòng `560` mà không gán `f.durationDays = null` (mặc định của `TemplateId.travel` là `7`). Khi `d.end != null`, phép trừ `DateUtils.dateOnly(end).difference(DateUtils.dateOnly(d.start)).inDays + 1` tính theo `DateTime` địa phương nên ngày đổi giờ mùa xuân dài 23 tiếng làm `inDays` bị làm tròn thiếu 1 ngày; kế tiếp `if (validateDurationDays(n) == null)` (`durationMin == 7`) âm thầm bỏ qua mọi khoảng `< 7` ngày; ngoài ra `dna_step.dart:89` truyền `DateTime.now()` thay vì ngày theo `journeysClockProvider` / múi giờ thiết bị.
- **Hướng sửa:** Khi `d.end == null`, đặt `_update((f) { f.openEnded = true; f.durationDays = null; })`; tính số ngày bằng `DateTime.utc(end.year, end.month, end.day).difference(DateTime.utc(d.start.year, d.start.month, d.start.day)).inDays + 1` và cho phép thời lượng chuyến đi từ `1` ngày (hoặc khóa chọn ngày kết thúc dưới `durationMin` trên lịch để UI và dữ liệu khớp nhau).
- **Test tạm:** `apps/mobile/test/zz_bugscan_b/b03_travel_dst_and_open_dates_test.dart` (chạy kèm `env TZ=America/New_York`) — cả 2 test tạo chuyến đi đều fail đúng lỗi (`dna-dates-open`: `Expected: null, Actual: <7>`; DST 14 ngày: `Expected: <14>, Actual: <13>`).
- **Claude kiểm chứng:** `_applyDates` (`create_flow_screen.dart:554-568`): `end == null` thì return mà không xóa `durationDays`; chuyến dưới mức tối thiểu bị bỏ qua im lặng; lệch DST chỉ ở múi giờ có DST.

#### B-B12. Đổi màu vé ở bước Xem lại không lưu `color` vào `JourneyDraft`, và tắt công tắc "Ẩn số cân" ở bước DNA giảm cân vẫn bị ép ẩn số cân

- **Vị trí:** `apps/mobile/lib/features/journeys/ui/create/create_flow_screen.dart:72, 77, 320-348` (kèm `apps/mobile/lib/features/journeys/ui/create_journey_screen.dart:78, 149-154`, `apps/mobile/lib/features/journeys/ui/create/steps/dna_step.dart:59-64`)
- **Mức độ:** vừa
- **Độ chắc:** chắc chắn
- **Tình huống gây lỗi:** (1) Ở bước 5 tạo hành trình (`CreateFlowScreen` hoặc `CreateJourneyScreen`), người dùng bấm `"Đổi màu"` để chọn biến thể màu vé `1` hoặc `2` rồi bấm Tạo; khi mở hành trình vừa tạo, màu quay ngược về biến thể `0`. (2) Khi tạo hành trình Giảm cân, ở trang DNA chọn cân nặng người dùng chủ động gạt tắt công tắc `"Ẩn số cân mặc định"` (`dna-hide-weight` = `false`) rồi hoàn tất tạo hành trình; hành trình tạo ra vẫn bật `hideMetricDefault: true` và `hideMetric: true`.
- **Vì sao sai:** `_variant` (`create_flow_screen.dart:72`, `create_journey_screen.dart:78`) chỉ đổi giao diện xem trước trong `UiSkinScope` nhưng `_submit()` (`create_flow_screen.dart:320-341`, `create_journey_screen.dart:149-154`) không truyền `color: _variant` vào `JourneyDraft`. Tương tự, biến `_hideWeight` (`create_flow_screen.dart:77`) không bao giờ đồng bộ sang `_form.hideMetric` (vốn khởi tạo `true` từ mẫu `weightLoss`), nên `form.toDraft` và `repo.updateMyMembership(..., hideMetric: true)` (`create_flow_screen.dart:344-348`) ghi đè ngược ý người dùng.
- **Hướng sửa:** Truyền `color: _variant` vào `JourneyDraft` ở cả hai màn tạo hành trình, và khi `onHideWeightChanged(v)` chạy ở `CreateFlowScreen` thì gọi `_update((f) => f.hideMetric = v)`.
- **Test tạm:** `apps/mobile/test/zz_bugscan_b/b07_reminders_duplicate_and_create_bugs_test.dart` — fail đúng lỗi (`Expected: <1>`, `Actual: <null>` trên `draft.color`).
- **Claude kiểm chứng:** `JourneyDraft` ở `create_flow_screen.dart:321-340` không có `color`. Phần công tắc ẩn số cân chưa có test riêng: khá chắc.

#### B-B13. Xoá trắng trường phần thưởng/cúp (`edit-trophy`) trong màn Chỉnh sửa hành trình không xoá được giá trị cũ trong `dna`

- **Vị trí:** `apps/mobile/lib/features/journeys/ui/edit/journey_edit_screen.dart:145-160`
- **Mức độ:** vừa
- **Độ chắc:** chắc chắn
- **Tình huống gây lỗi:** Chủ hành trình nhóm Học tiếng Anh (`PersonaSkinId.accountabilitySquad`) đã đặt mục tiêu cúp (ví dụ `"IELTS 7.0"`), sau đó vào màn Chỉnh sửa hành trình xoá trắng ô `edit-trophy` và bấm Lưu (nút Lưu sáng lên bình thường). Sau khi lưu, hành trình vẫn giữ nguyên cúp `"IELTS 7.0"` cũ.
- **Vì sao sai:** `_changed` (`journey_edit_screen.dart:128`) nhận biết `_trophy.text.trim() != _initialTrophy`, nhưng trong `_save()` (`journey_edit_screen.dart:145-159`) code chép `final dna = <String, Object?>{...?j.dna};` rồi chỉ ghi `if (_trophy.text.trim().isNotEmpty) dna['trophy'] = ...` mà không `dna.remove('trophy')` khi chuỗi rỗng (và khi `sanitizeJourneyDna(dna)` trả về `null` cũng chưa thêm `'dna'` vào `JourneyUpdate.clear`).
- **Hướng sửa:** Khi `_trophy.text.trim().isEmpty` thì gọi `dna.remove('trophy')`, và nếu `j.dna != null && sanitizedDna == null` thì truyền `clear: {'dna'}` vào `JourneyUpdate`.
- **Test tạm:** `apps/mobile/test/zz_bugscan_b/b06_expired_journey_and_edit_bugs_test.dart` — fail đúng lỗi (`Expected: null`, `Actual: 'IELTS 7.0'`).
- **Claude kiểm chứng:** `journey_edit_screen.dart:146` chỉ ghi `trophy` khi khác rỗng, không xóa.

#### B-B14. Đặt giờ nhắc hằng ngày lúc `21:00` khi đang có chuỗi (`streak >= 1`) lên lịch trùng 2 thông báo hệ thống nổ cùng lúc cho một hành trình

- **Vị trí:** `apps/mobile/lib/features/reminders/domain/reminder_plan.dart:195-233` (kèm `apps/mobile/lib/features/reminders/data/reminder_scheduler.dart:144-160`)
- **Mức độ:** vừa
- **Độ chắc:** chắc chắn
- **Tình huống gây lỗi:** Người dùng đang có chuỗi điểm danh (`streak >= 1`, công tắc cảnh báo giữ chuỗi bật mặc định) và đặt giờ nhắc hằng ngày của hành trình vào đúng `21:00`. Đến `21:00` tối hôm đó (nếu chưa chụp), điện thoại rung và bắn cùng lúc 2 thông báo của cùng một hành trình ở đúng một thời điểm `21:00`.
- **Vì sao sai:** Trong `planReminders` (`reminder_plan.dart:195-233`), vòng lặp vừa thêm `PlannedNotification(kind: PlannedKind.reminder)` tại `setting.activeTime` (`21:00`), vừa thêm `PlannedNotification(kind: PlannedKind.streakAlert)` tại `_streakAlertTime` (`21:00`) cho cùng `(journey.id, day)` mà không khử trùng theo `(journeyId, fireAt)`. `ReminderScheduler._apply` (`reminder_scheduler.dart:148-158`) gán hai ID liên tiếp (`41000`, `41001`) nên OS nổ cả hai cùng lúc.
- **Hướng sửa:** Trong `planReminders`, nếu ngày đó đã có `streakAlert` trùng đúng `fireAt` với `reminder` của cùng `journey.id` thì bỏ bớt bản ghi `reminder` (giữ `streakAlert` vì mang thông điệp chuỗi cụ thể hơn).
- **Test tạm:** `apps/mobile/test/zz_bugscan_b/b07_reminders_duplicate_and_create_bugs_test.dart` — fail đúng lỗi (`Expected: <1>`, `Actual: <2>` thông báo cùng `payload == 'j1'` tại `2026-10-16 14:00:00Z`).
- **Claude kiểm chứng:** `reminder_plan.dart:194-233`: chỉ trùng khi giờ nhắc đúng bằng `21:00`.

#### B-B15. `journeyHomeOfflineProvider` gọi `c.add(false)` sau khi `StreamController` đã đóng nếu provider huỷ trong lúc đang chờ `checkConnectivity()`, ném `StateError` không bắt được

- **Vị trí:** `apps/mobile/lib/features/journeys/ui/home/journey_home_intro.dart:13-35`
- **Mức độ:** thấp
- **Độ chắc:** chắc chắn
- **Tình huống gây lỗi:** Người dùng mở màn Chi tiết hành trình (`JourneyDetailScreen`) rồi lập tức bấm Quay lại trước khi lời gọi kênh nền tảng `Connectivity().checkConnectivity()` kịp trả về. Ứng dụng ném `StateError: Bad state: Cannot add event after closing` không bắt được trong zone bất đồng bộ.
- **Vì sao sai:** `journeyHomeOfflineProvider` là `StreamProvider.autoDispose` đăng ký `ref.onDispose(c.close)` (`journey_home_intro.dart:34`). Khi provider bị huỷ lúc `await conn.checkConnectivity()` đang bay, `c.close()` đóng controller; ngay khi `checkConnectivity()` trả về (hoặc ném lỗi), `c.add(...)` ở dòng `18` ném `StateError`, rơi vào `catch` `on Object` ở dòng `28` rồi gọi tiếp `c.add(false)` trên chính `c` đã đóng.
- **Hướng sửa:** Kiểm tra `if (c.isClosed) return;` ngay sau `await conn.checkConnectivity()`, trong callback `onConnectivityChanged`, và trước `c.add(false)` trong khối `catch`.
- **Test tạm:** `apps/mobile/test/zz_bugscan_b/b04_capture_dispose_and_offline_stream_test.dart` — fail đúng lỗi (`Actual: StateError:<Bad state: Cannot add event after closing>`).

### 2.3. Đợt C: `bug-scan-c` (hồ sơ, cài đặt, đăng nhập, chia sẻ, an toàn)

Worker tự chấm: 7 cao, 8 vừa, 0 thấp. 15 lỗi, đều có test tạm fail đúng như báo cáo.

| Mã | Lỗi | Vị trí chính | Mức (worker) | Mức (Claude) | Trạng thái |
| --- | --- | --- | --- | --- | --- |
| C-B1 | Hai công tắc quyền riêng tư toàn cục "Ẩn số kg khi chia sẻ" và "Làm mờ ảnh khi chia sẻ" trong Cài đặt không có tác dụng khi chia sẻ | `apps/mobile/lib/features/profile/settings_screen.dart:87` | cao | cao | open |
| C-B2 | `ShareCardScreen` vẫn chọn và xuất ra ngoài các ảnh check-in đã đánh dấu "Ẩn khỏi mọi bản chia sẻ" (`hidden_in_share`) | `apps/mobile/lib/features/share_card/ui/share_card_screen.dart:117` | cao | cao | open |
| C-B3 | Chặn người dùng không lọc ngay ở `ChatScreen`, `InboxScreen`, `FriendsScreen`, `SharedWithMeList` và `SquadPendingInvites` | `apps/mobile/lib/features/social/ui/chat_screen.dart:212` | cao | vừa | open |
| C-B4 | Đăng xuất để sót dữ liệu tài khoản cũ trong `SharedPreferences`/provider, làm ghi đè quiz trên server của tài khoản kế tiếp và bỏ qua màn EULA | `apps/mobile/lib/features/onboarding/onboarding_providers.dart:45` | cao | cao | open |
| C-B5 | `AuthScreen._finishSignIn` gọi `ref.read` sau `await` khi `AuthScreen` đã bị router unmount, gây lỗi `StateError` và bỏ qua `/profile/setup` | `apps/mobile/lib/features/auth/auth_screen.dart:256` | cao | cao, cần thử trên máy | open |
| C-B6 | Bấm "Đăng xuất" ở `SettingsScreen` xóa ngay dữ liệu cục bộ và ảnh chưa tải lên mà không hỏi xác nhận hay bắt lỗi | `apps/mobile/lib/features/profile/settings_screen.dart:60` | cao | vừa | open |
| C-B7 | `PublicLinkSection` bỏ qua cảnh báo nhạy cảm cho hành trình giảm cân và kiểm tra ngược điều kiện trạng thái hành trình (quy tắc S9/S10) | `apps/mobile/lib/features/share_card/ui/public_link_section.dart:130` | cao | vừa | open |
| C-B8 | Tường nhóm `_MemoryWall` và `_CoupleWall` bỏ sót menu thành viên, khiến chủ nhóm không thể xóa thành viên và thành viên không thể báo cáo/chặn | `apps/mobile/lib/features/groups/ui/group_wall_skins.dart:352` | vừa | vừa | open |
| C-B9 | `GroupTodayView.build` ưu tiên `serverToday` thiếu dữ liệu hơn `localToday`, làm mất chú thích, thông số chạy bộ và ảnh thứ 2 chụp cùng ngày | `apps/mobile/lib/features/groups/domain/group_today.dart:98` | vừa | vừa | open |
| C-B10 | Báo cáo ảnh hôm nay trên tường nhóm `memory`, `couple`, `flexer`, `minimal` khiến ảnh của ngày cũ bị hiển thị nhầm thành check-in hôm nay | `apps/mobile/lib/features/groups/ui/group_wall_skins.dart:15` | vừa | vừa | open |
| C-B11 | `ImportFlowScreen` bỏ qua giao diện `_skin`, bỏ qua công tắc "Chụp tiếp" (`_continues`) và gán sai loại hành trình `'couple'` | `apps/mobile/lib/features/import/ui/import_flow_screen.dart:190` | vừa | vừa | open |
| C-B12 | `noonInZone` tạo thời điểm tương lai khi nhập ảnh hôm nay buổi sáng và `ImportFlowScreen` / `RetellScreen` rơi về múi giờ `'UTC'` | `apps/mobile/lib/features/sharing/data/sharing_providers.dart:139` | vừa | vừa | open |
| C-B13 | Tab Nhóm hiển thị các nhóm đã kết thúc trong mục "HÔM NAY" và mời bấm "Check-in ngay" | `apps/mobile/lib/features/groups/ui/squad_tab_sections.dart:489` | vừa | vừa | open |
| C-B14 | Thành viên thường trong nhóm thấy nút Lưu câu chuyện và nút "Dừng chia sẻ" hoạt động sai phân quyền ở `StoryEditorScreen` & `ShareJourneyPanel` | `apps/mobile/lib/features/sharing/ui/story_editor_screen.dart:164` | vừa | vừa | open |
| C-B15 | Bấm "Trả lời" trên một ảnh cụ thể ở `SharedJourneyScreen` đánh rơi `checkInId` khi sang `ChatScreen` | `apps/mobile/lib/features/sharing/ui/shared_journey_screen.dart:166` | vừa | vừa | open |


#### C-B1. Hai công tắc quyền riêng tư toàn cục "Ẩn số kg khi chia sẻ" và "Làm mờ ảnh khi chia sẻ" trong Cài đặt không có tác dụng khi chia sẻ

- **Vị trí:** `apps/mobile/lib/features/profile/settings_screen.dart:87` (liên quan: `apps/mobile/lib/features/profile/settings_providers.dart:46`, `apps/mobile/lib/features/share_card/ui/share_card_screen.dart:124`)
- **Mức độ:** cao
- **Độ chắc:** chắc chắn
- **Tình huống gây lỗi:** Người dùng vào `/profile/settings`, bật cả hai công tắc `"Ẩn số kg khi chia sẻ"` (`settings-hide-kg`) và `"Làm mờ ảnh khi chia sẻ"` (`settings-blur-photos`), sau đó mở màn xuất thẻ `/journeys/:id/share` của một hành trình có số đo và ảnh. Ảnh trên thẻ vẫn hiển thị rõ nét (`share-card-photo-blurred` không được bọc, công tắc làm mờ vẫn tắt) và con số đo vẫn in công khai trên thẻ xuất ra ngoài.
- **Vì sao sai:** `SettingsScreen` (`settings_screen.dart:87-102`) chỉ lưu `privacy.hideWeightOnShare` và `privacy.blurPhotosOnShare` vào `SharedPreferences` qua `hideWeightOnShareProvider` / `blurPhotosOnShareProvider` (`settings_providers.dart:46-51`). Toàn bộ codebase không có bất kỳ nơi nào đọc hai provider này: `ShareCardScreen.build` (`share_card_screen.dart:124-139`) chỉ tính `ShareCardContent.from(journey: journey, membership: membership, ...)` rồi lấy `blur = _blurOverride ?? content.blurPhoto`, đồng thời việc bật công tắc ở Cài đặt cũng không cập nhật `memberships.hide_metric` / `blur_media` cho chia sẻ nhóm/bạn bè.
- **Hướng sửa:** Cho `ShareCardScreen` (và luồng tạo/cập nhật `membership`) đọc `hideWeightOnShareProvider` và `blurPhotosOnShareProvider` làm giá trị mặc định kết hợp với `membership.hideMetric` / `membership.blurMedia`, hoặc đồng bộ hai công tắc này xuống `journeyRepository.updateMyMembership`.
- **Test tạm:** `apps/mobile/test/zz_bugscan_c/share_privacy_bugs_test.dart` — chạy fail (`0 +0 -4`, test B1 fail ở dòng 39 vì không tìm thấy `share-card-photo-blurred`).
- **Claude kiểm chứng:** Hai công tắc riêng tư toàn cục trong Cài đặt không được nơi nào đọc (`hideWeightOnShareProvider`, `blurPhotosOnShareProvider` chỉ có ở `settings_*`).

#### C-B2. `ShareCardScreen` vẫn chọn và xuất ra ngoài các ảnh check-in đã đánh dấu "Ẩn khỏi mọi bản chia sẻ" (`hidden_in_share`)

- **Vị trí:** `apps/mobile/lib/features/share_card/ui/share_card_screen.dart:117` (liên quan: dòng `132`, `162`)
- **Mức độ:** cao
- **Độ chắc:** chắc chắn
- **Tình huống gây lỗi:** Người dùng vào màn Chỉnh câu chuyện (`/sharing/:id/story`) và đánh dấu ẩn bức ảnh mới nhất `c-2026-10-15` khỏi mọi bản chia sẻ (`hiddenCheckInIds` chứa `'c-2026-10-15'`). Khi mở `/journeys/:id/share` để xuất ảnh Story/Feed, `ShareCardScreen` vẫn tự động lấy chính ảnh `c-2026-10-15` làm ảnh chính trên thẻ và đưa nó vào lưới ảnh ghép `gallery` (4–36 ảnh của skin `squad`, `memory`, `couple`).
- **Vì sao sai:** `ShareCardScreen.build` (`share_card_screen.dart:117, 132, 162-164`) lấy toàn bộ check-in từ `shareCheckInsProvider(id)` (đọc bảng local `check_ins`, vốn không lọc `hidden_in_share`) rồi truyền thẳng vào `photoCandidates(checkIns)` và `gallery`, mà không watch `shareStateProvider(id)` để loại bỏ các ID thuộc `hiddenCheckInIds` như `StoryEditorScreen` (`story_editor_screen.dart:187-190`).
- **Hướng sửa:** Khi có backend, watch `shareStateProvider(id)` trong `ShareCardScreen` (hoặc đồng bộ cờ `hidden_in_share` về bảng `check_ins` cục bộ) và loại các check-in nằm trong `hiddenCheckInIds` trước khi truyền vào `ShareCardContent.from` và `photoCandidates`.
- **Test tạm:** `apps/mobile/test/zz_bugscan_c/share_privacy_bugs_test.dart` — chạy fail (`0 +0 -4`, test B2 fail ở dòng 118 vì `share-card-photo` vẫn render `c-2026-10-15.jpg`).
- **Claude kiểm chứng:** Thẻ chia sẻ dùng cả ảnh người dùng đã ẩn khỏi mọi bản chia sẻ.

#### C-B3. Chặn người dùng không lọc ngay ở `ChatScreen`, `InboxScreen`, `FriendsScreen`, `SharedWithMeList` và `SquadPendingInvites`

- **Vị trí:** `apps/mobile/lib/features/social/ui/chat_screen.dart:212` (liên quan: `apps/mobile/lib/features/social/ui/inbox_screen.dart:189`, `apps/mobile/lib/features/social/ui/friends_screen.dart:58`, `apps/mobile/lib/features/sharing/ui/shared_with_me_list.dart:41`, `apps/mobile/lib/features/groups/ui/squad_tab_sections.dart:640`)
- **Mức độ:** cao
- **Độ chắc:** chắc chắn
- **Tình huống gây lỗi:** Người dùng chặn tài khoản `nam` (từ trong `ChatScreen`, `InboxScreen`, hoặc màn khác khiến `blockedUserIdsProvider` cập nhật ngay). Sau khi chặn xong: trên `ChatScreen` toàn bộ tin nhắn/ảnh của `nam` vẫn hiển thị và ô nhập tin nhắn vẫn cho phép gửi tiếp; trên `InboxScreen`, `FriendsScreen`, `SharedWithMeList` và mục lời mời nhóm ở `GroupsListScreen`, lời mời kết bạn (kèm nút `Chấp nhận` bấm được), hội thoại, hành trình được chia sẻ và lời mời vào nhóm từ `nam` vẫn hiển thị nguyên vẹn.
- **Vì sao sai:** Khác với `GroupTodayScreen` có lọc theo `groupBlockedIdsProvider`, các màn `ChatScreen` (`chat_screen.dart:212-254, 300-307`), `InboxScreen` (`inbox_screen.dart:189-207, 567-570`), `FriendsScreen` (`friends_screen.dart:58-63, 329-332`), `SharedWithMeList` (`shared_with_me_list.dart:41-64`) và `SquadPendingInvites` (`squad_tab_sections.dart:639-641`) đều không watch `blockedUserIdsProvider` để ẩn nội dung và khóa tương tác với người bị chặn ở phía client.
- **Hướng sửa:** Watch `blockedUserIdsProvider` tại các màn/provider trên để ẩn ngay tin nhắn, bạn bè, lời mời kết bạn, lời mời nhóm và hành trình chia sẻ từ `blockedIds`, đồng thời đóng hoặc chuyển `ChatScreen` sang trạng thái đã chặn không thể gửi tin.
- **Test tạm:** `apps/mobile/test/zz_bugscan_c/block_leak_bugs_test.dart` — chạy fail (`0 +0 -2`, cả hai test ở `ChatScreen` dòng 45 và `InboxScreen` dòng 81 đều còn nguyên dữ liệu của `nam` sau khi gọi `safety.block('nam')`).
- **Claude kiểm chứng:** Chặn người dùng chưa ẩn ngay nội dung ở client (chat, hộp thư, bạn bè, được chia sẻ, lời mời nhóm). Server vẫn lọc theo RLS khi tải lại.

#### C-B4. Đăng xuất để sót dữ liệu tài khoản cũ trong `SharedPreferences`/provider, làm ghi đè quiz trên server của tài khoản kế tiếp và bỏ qua màn EULA

- **Vị trí:** `apps/mobile/lib/features/onboarding/onboarding_providers.dart:45` (liên quan: `apps/mobile/lib/features/profile/profile_screen.dart:377`, `apps/mobile/lib/features/safety/data/safety_providers.dart:33`, `apps/mobile/lib/features/profile/widgets/delete_account_dialog.dart:160`)
- **Mức độ:** cao
- **Độ chắc:** chắc chắn
- **Tình huống gây lỗi:** Tài khoản A làm quiz onboarding (ví dụ mục tiêu `weightLoss`), đồng ý EULA, chặn người dùng và đặt lịch nhắc hành trình riêng tư trên máy, sau đó đăng xuất. Khi tài khoản B (vốn đã có quiz `english` trên server) đăng nhập trên cùng thiết bị: (1) `profiles.onboarding_quiz` trên server của B bị ghi đè thành `weightLoss` của A; (2) B vào thẳng app mà không phải đồng ý EULA; (3) tên người bị A chặn (`safety.blockedNames`), ID ảnh bị ẩn (`safety.hiddenCheckInIds`, kể cả khi xóa tài khoản ở `delete_account_dialog.dart:160-163` cũng quên xóa) và thông báo nhắc nhở cục bộ mang tên hành trình của A vẫn còn trên thiết bị.
- **Vì sao sai:** Đăng xuất (`profile_screen.dart:377`, `settings_screen.dart:60`) chỉ gọi `authRepository.signOut()` mà không gọi `onboardingQuizProvider.notifier.clear()`, không reset `eulaAcceptedProvider` / `blockedNamesProvider` / `hiddenCheckInIdsProvider` (các khóa `SharedPreferences` dùng chung toàn thiết bị, không gắn `userId`), và không gọi `reminderSchedulerProvider.reschedule()`. Khi B đăng nhập, `AuthScreen._finishSignIn` (`auth_screen.dart:256`) gọi `syncToServer()` (`onboarding_providers.dart:41-60`), thấy `local != null && !local.isEmpty` (dữ liệu của A) nên gọi thẳng `repo.saveQuiz(local)` ghi đè lên hồ sơ server của B.
- **Hướng sửa:** Khi đăng xuất và xóa tài khoản, dọn sạch `onboardingQuizProvider`, `eulaAcceptedProvider`, `blockedNamesProvider`, `hiddenCheckInIdsProvider` và gọi `reminderSchedulerProvider.reschedule()` (hoặc tách khóa `SharedPreferences` theo `userId`, và ưu tiên `remote` khi tài khoản đã có quiz trên server).
- **Test tạm:** `apps/mobile/test/zz_bugscan_c/account_lifecycle_bugs_test.dart` — chạy fail (`0 +0 -3`, test B4 fail ở dòng 100 vì `serverQuiz` của User B bị ghi đè thành quiz của User A).
- **Claude kiểm chứng:** `onboarding_providers.dart:41-49`: "local answers win" nên quiz của A ghi đè quiz server của B. Không reset EULA, tên đã chặn, ảnh đã ẩn; không xếp lại lịch nhắc. Trùng mục "Ngoài phạm vi" số 2 của `bug-scan`.

#### C-B5. `AuthScreen._finishSignIn` gọi `ref.read` sau `await` khi `AuthScreen` đã bị router unmount, gây lỗi `StateError` và bỏ qua `/profile/setup`

- **Vị trí:** `apps/mobile/lib/features/auth/auth_screen.dart:256` (gọi từ dòng `154`, `163`, `237`)
- **Mức độ:** cao
- **Độ chắc:** chắc chắn
- **Tình huống gây lỗi:** Người dùng mới (chưa có `profile` trên server) đăng nhập bằng mã OTP hoặc mật khẩu. Khi `verifyOtp` / `signInWithPassword` phát `userId` rồi chờ đồng bộ đầu phiên (`_postSignIn`), `routerProvider` nhận sự kiện đổi `authStatusProvider` và lập tức redirect khỏi `/auth` sang `/capture` (hoặc `/safety/eula/accept`), làm `AuthScreen` bị unmount. Khi lệnh `await` hoàn tất, `_finishSignIn` chạy tới dòng 256 và ném `StateError: Using "ref" when a widget is about to or has been unmounted is unsafe` (không được bắt ở `_verify` dòng 237), làm hủy luôn bước kiểm tra `_needsProfileSetup` ở dòng 257–264 nên người dùng mới không được chuyển tới `/profile/setup`.
- **Vì sao sai:** Dù `auth_screen.dart:204-205` đã ghi chú rõ router sẽ thay route ngay khi phát `userId` và đã chụp sẵn `auth`, `router`, `profiles` trước `await`, hàm `_finishSignIn` ở dòng 256 vẫn gọi trực tiếp `ref.read(onboardingQuizProvider.notifier)` trên `ConsumerState` đã bị dispose mà không kiểm tra `mounted` hay chụp notifier trước `await`.
- **Hướng sửa:** Chụp `final quiz = ref.read(onboardingQuizProvider.notifier);` trước lệnh `await` xác thực (cùng chỗ với `router` và `profiles`) rồi truyền vào `_finishSignIn` thay vì đọc `ref` sau `await`.
- **Test tạm:** `apps/mobile/test/zz_bugscan_c/account_lifecycle_bugs_test.dart` — chạy fail (`0 +0 -3`, test B5 ném `StateError` tại `auth_screen.dart:256:19` và ở lại `/capture` thay vì `/profile/setup`).
- **Claude kiểm chứng:** `auth_screen.dart:256` đọc `ref` sau `await`. Repository không chờ sync (`auth_repository.dart:100-104`), nên việc màn bị unmount trước dòng 256 phụ thuộc thời điểm router redirect. Nếu đúng thì người dùng mới không qua `/profile/setup` (chỉ có chỗ này mở màn đó tự động).

#### C-B6. Bấm "Đăng xuất" ở `SettingsScreen` xóa ngay dữ liệu cục bộ và ảnh chưa tải lên mà không hỏi xác nhận hay bắt lỗi

- **Vị trí:** `apps/mobile/lib/features/profile/settings_screen.dart:60`
- **Mức độ:** cao
- **Độ chắc:** chắc chắn
- **Tình huống gây lỗi:** Người dùng có ảnh check-in vừa chụp khi mất mạng chưa kịp tải lên server, vào `/profile/settings` và chạm nhầm vào hàng `"Đăng xuất"` (`settings-signout`). App lập tức gọi `authRepository.signOut()` (`ctx.wipeLocal()`), xóa vĩnh viễn toàn bộ SQLite, hàng đợi outbox và ảnh cục bộ mà không hiện hộp thoại cảnh báo mất dữ liệu như ở `ProfileScreen`; nếu `signOut()` ném lỗi thì phát sinh unhandled async exception.
- **Vì sao sai:** `ProfileScreen._confirmSignOut` (`profile_screen.dart:337-380`) có mở hộp thoại xác nhận cảnh báo mất check-in chưa gửi và bọc `try / catch`, nhưng `SettingsScreen` (`settings_screen.dart:54-61`) gọi thẳng `onPressed: () => unawaited(ref.read(authRepositoryProvider).signOut())`.
- **Hướng sửa:** Dùng chung hàm hộp thoại xác nhận đăng xuất (kèm cảnh báo mất dữ liệu chưa đồng bộ, dọn state cục bộ và `try / catch` hiển thị thông báo lỗi) cho cả `ProfileScreen` và `SettingsScreen`.
- **Test tạm:** `apps/mobile/test/zz_bugscan_c/account_lifecycle_bugs_test.dart` — chạy fail (`0 +0 -3`, test B6 fail ở dòng 183 vì `signOut` bị gọi ngay khi vừa chạm `settings-signout`).
- **Claude kiểm chứng:** Đăng xuất ở Cài đặt không hỏi xác nhận, mất check-in chưa gửi nếu bấm nhầm.

#### C-B7. `PublicLinkSection` bỏ qua cảnh báo nhạy cảm cho hành trình giảm cân và kiểm tra ngược điều kiện trạng thái hành trình (quy tắc S9/S10)

- **Vị trí:** `apps/mobile/lib/features/share_card/ui/public_link_section.dart:130` & `apps/mobile/lib/features/share_card/domain/share_card_content.dart:214`
- **Mức độ:** cao
- **Độ chắc:** chắc chắn
- **Tình huống gây lỗi:** (1) Trên hành trình giảm cân (`TemplateId.weightLoss`) đã kết thúc, bấm `"Tạo & sao chép liên kết"` (`share-card-link-create`) ở `/journeys/:id/share` sẽ bật ngay link công khai trên server và chép vào clipboard mà không hiện cảnh báo hành trình nhạy cảm (`showSensitiveLinkWarning`). (2) Trên hành trình cá nhân đang `active`, mục tạo link vẫn hiện ra nhưng bấm vào luôn bị server từ chối với lỗi `invalid`; ngược lại khi hành trình ở trạng thái `archived` (kể cả đang bật link công khai muốn thu hồi), mục link bị ẩn hoàn toàn.
- **Vì sao sai:** `PublicLinkSection._create` (`public_link_section.dart:130-151`) gọi thẳng `setPublicLink(id, enabled: true)` mà thiếu bước kiểm tra `isSensitiveTemplate(widget.journey.templateId)` như `ShareJourneyPanel._setLink` (`share_journey_sheet.dart:159-161`). Đồng thời `canHavePublicLink` (`share_card_content.dart:214`) viết `if (journey.status == JourneyStatus.archived) return false;` — ngược với quy tắc S9 trong RPC `set_public_link` (`0006_social.sql:1115`) và `_LinkBlock` (`share_journey_sheet.dart:786: journey.status != JourneyStatus.active`).
- **Hướng sửa:** Sửa điều kiện ở `canHavePublicLink` thành `journey.status != JourneyStatus.active || journey.origin == JourneyOrigin.imported`, và thêm hộp thoại xác nhận `showSensitiveLinkWarning` trong `PublicLinkSection._create` khi `isSensitiveTemplate(widget.journey.templateId)`.
- **Test tạm:** `apps/mobile/test/zz_bugscan_c/share_privacy_bugs_test.dart` — chạy fail (`0 +0 -4`, hai test B7 fail ở dòng 133 và dòng 186).
- **Claude kiểm chứng:** Thiếu cảnh báo nhạy cảm ở `PublicLinkSection`, điều kiện `canHavePublicLink` ngược với quy tắc S9.

#### C-B8. Tường nhóm `_MemoryWall` và `_CoupleWall` bỏ sót menu thành viên, khiến chủ nhóm không thể xóa thành viên và thành viên không thể báo cáo/chặn

- **Vị trí:** `apps/mobile/lib/features/groups/ui/group_wall_skins.dart:352` (liên quan: dòng `467`, đối chiếu `apps/mobile/lib/features/groups/ui/group_today_screen.dart:839`)
- **Mức độ:** vừa
- **Độ chắc:** chắc chắn
- **Tình huống gây lỗi:** Chủ nhóm tạo nhóm mẫu Du lịch (`TemplateId.travel` -> skin `memory`) hoặc Cặp đôi (`couple`), hoặc chuyển giao diện nhóm sang `memory` / `couple`. Trên màn Nhóm hôm nay (`/groups/:id`), thẻ của các thành viên không có nút menu `⋯` (`group-member-menu-<userId>`), khiến chủ nhóm hoàn toàn không thể xóa thành viên khỏi nhóm (vì toàn app chỉ có duy nhất `group_today_screen.dart:839` gọi `removeMember`) và các thành viên cũng không thể báo cáo/chặn từ tường nhóm.
- **Vì sao sai:** `GroupTodayScreen` đã truyền `memberMenu` vào `buildSkinnedGroupWall` (`group_today_screen.dart:516`), nhưng trong `group_wall_skins.dart`, chỉ `_QuietWall` (`334`), `_RunnerWall` (`646`) và `_MinimalWall` (`723`) gắn `memberMenu`; hai lớp `_MemoryWall` (`352-464`) và `_CoupleWall` (`467-573`) không nhận và không hiển thị `memberMenu`.
- **Hướng sửa:** Truyền `memberMenu` xuống `_MemoryWall` (`_FilmFrame`) và `_CoupleWall` (ô nửa khung của đối phương) tương tự `_QuietWall` / `_RunnerWall`.
- **Test tạm:** `apps/mobile/test/zz_bugscan_c/groups_bugs_test.dart` — chạy fail (`0 +0 -4`, test B8 fail ở dòng 36 vì không tìm thấy `group-member-menu-u2`).

#### C-B9. `GroupTodayView.build` ưu tiên `serverToday` thiếu dữ liệu hơn `localToday`, làm mất chú thích, thông số chạy bộ và ảnh thứ 2 chụp cùng ngày

- **Vị trí:** `apps/mobile/lib/features/groups/domain/group_today.dart:98`
- **Mức độ:** vừa
- **Độ chắc:** chắc chắn
- **Tình huống gây lỗi:** Thành viên nhóm check-in hôm nay có ghi chú thích (`caption`) hoặc thông số chạy bộ (`km`, `pace` trên nhóm Workout 30), hoặc đã đồng bộ ảnh thứ nhất rồi chụp thêm ảnh thứ hai trong ngày khi đang offline. Trên `GroupTodayScreen`, chú thích ở tường `squad` và số `km`/`pace` ở tường `flexer` bị mất trắng, đồng thời ảnh hiển thị vẫn là ảnh thứ nhất cũ từ `serverToday` thay vì ảnh mới nhất trong ngày.
- **Vì sao sai:** RPC `group_today` chỉ trả bản rút gọn nên `memberTodayFromRemote` (`mapping.dart:306-318`) tạo `serverToday` với `caption: null` và `extras: const {}`, còn `localToday` (từ bảng `check_ins` qua `groupCheckInsProvider`) có đủ `caption`, `extras` và ảnh mới nhất theo `capturedAt`. Tuy nhiên `group_today.dart:98-102` viết `(serverToday != null && !hidden ? serverToday : null) ?? localToday`, khiến `localToday` luôn bị bỏ qua mỗi khi `serverToday != null`.
- **Hướng sửa:** Ưu tiên bản ghi mới hơn theo `capturedAt` giữa `localToday` và `serverToday`; khi cùng `id`, ưu tiên `localToday` để giữ đầy đủ `caption`, `extras` và đường dẫn ảnh cục bộ.
- **Test tạm:** `apps/mobile/test/zz_bugscan_c/groups_bugs_test.dart` — chạy fail (`0 +0 -4`, test B9 fail ở dòng 89 vì trả về `'c-first'` thay vì `'c-second'`).

#### C-B10. Báo cáo ảnh hôm nay trên tường nhóm `memory`, `couple`, `flexer`, `minimal` khiến ảnh của ngày cũ bị hiển thị nhầm thành check-in hôm nay

- **Vị trí:** `apps/mobile/lib/features/groups/ui/group_wall_skins.dart:15` (liên quan: dòng `397`, `421`, `539`, `568`, `631`, `712`, `720`)
- **Mức độ:** vừa
- **Độ chắc:** chắc chắn
- **Tình huống gây lỗi:** Thành viên `u2` có ảnh hôm qua và ảnh hôm nay. Người dùng báo cáo ảnh hôm nay của `u2` (`hiddenCheckInIds` chứa ID ảnh hôm nay). Trên tường nhóm `memory`, `couple` và `flexer` (cùng giờ hiển thị ở `minimal`), ô của `u2` lấy ảnh hôm qua ra hiển thị sáng rõ như ảnh hôm nay, đóng dấu giờ chụp của hôm qua thành giờ check-in hôm nay và gắn thanh thả cảm xúc (`ReactionBar`) trực tiếp vào ảnh hôm qua.
- **Vì sao sai:** Khi ảnh hôm nay bị ẩn bởi `hiddenCheckInIds`, `GroupTodayView.build` (`group_today.dart:97-123`) giữ `checkedInToday: true` nhưng fallback `photo` về `latestOwn` (ảnh ngày cũ) với `photoIsToday: false`. Thế nhưng `_todayTime` (`group_wall_skins.dart:15`), `_FilmFrame` (`397, 421`), `_CoupleWall` (`539, 568`), `_RunnerWall` (`631`) và `_MinimalWall` (`720`) đều kiểm tra `e.checkedInToday` thay vì `e.photoIsToday`.
- **Hướng sửa:** Đổi các kiểm tra hiển thị ảnh/giờ/thanh cảm xúc của ngày hôm nay trong `group_wall_skins.dart` từ `e.checkedInToday` sang `e.photoIsToday` (giống `_SquadWall` ở `group_today_screen.dart:690`).
- **Test tạm:** `apps/mobile/test/zz_bugscan_c/groups_bugs_test.dart` — chạy fail (`0 +0 -4`, test B10 fail ở dòng 141 vì `groups-reactions-c-u2-yesterday` được gắn cho ảnh hôm qua).

#### C-B11. `ImportFlowScreen` bỏ qua giao diện `_skin`, bỏ qua công tắc "Chụp tiếp" (`_continues`) và gán sai loại hành trình `'couple'`

- **Vị trí:** `apps/mobile/lib/features/import/ui/import_flow_screen.dart:190` (liên quan: dòng `67`, `71`, `425`, `675`)
- **Mức độ:** vừa
- **Độ chắc:** chắc chắn
- **Tình huống gây lỗi:** Trong luồng Nhập hành trình (`/import`), người dùng chọn loại `"Cặp đôi"`, chọn giao diện `"Tối giản"` ở Bước 1, bật công tắc `"Chụp tiếp"` (`import-continue`) ở Bước 3 rồi bấm Lưu. Hành trình sau khi lưu không giữ giao diện đã chọn (`layout == null`), hiển thị biểu tượng `✨` của hành trình tùy chỉnh thường thay vì `💞` (nên mất luôn skin cặp đôi), và luôn ở trạng thái `ended` không thể chụp tiếp.
- **Vì sao sai:** `_ImportFlowScreenState` lưu `_skin` (dòng 67, chọn ở dòng 433) và `_continues` (dòng 71, bật ở dòng 681), nhưng `_save()` (`import_flow_screen.dart:175-248`) không hề đọc `_skin` hay `_continues`; đồng thời ở dòng 190–202, nhánh mặc định `_ => (TemplateId.custom, '✨')` gộp luôn `_type == 'couple'` vào `✨` (trong khi `personaSkinForTemplate` nhận diện cặp đôi dựa trên `emoji == '💞'` hoặc `maxMembers == 2`).
- **Hướng sửa:** Ánh xạ `'couple' => (TemplateId.custom, '💞')`, lưu `layout` tương ứng với `_skin` cho hành trình vừa tạo, và khi `_continues == true` thì tạo/mở hành trình ở trạng thái `active` thay vì khóa ở `ended`.
- **Test tạm:** `apps/mobile/test/zz_bugscan_c/import_sharing_bugs_test.dart` — chạy fail (`0 +0 -6`, test B11 fail ở dòng 113 vì `layout` không bao giờ được lưu).

#### C-B12. `noonInZone` tạo thời điểm tương lai khi nhập ảnh hôm nay buổi sáng và `ImportFlowScreen` / `RetellScreen` rơi về múi giờ `'UTC'`

- **Vị trí:** `apps/mobile/lib/features/sharing/data/sharing_providers.dart:139` (liên quan: `apps/mobile/lib/features/import/ui/import_flow_screen.dart:86, 184, 214`, `apps/mobile/lib/features/sharing/ui/retell_screen.dart:115, 148`)
- **Mức độ:** vừa
- **Độ chắc:** chắc chắn
- **Tình huống gây lỗi:** Lúc 08:30 sáng giờ địa phương, người dùng vào `/import` hoặc `/retell` và chọn ảnh chụp sáng hôm nay (cả hai màn đều cho phép chọn tới `today`). Vì `noonInZone(today, tz)` gán cứng `capturedAt = 12:00 trưa`, thời điểm này lớn hơn `now + 10 phút` nên bị cả `DataCheckInRepository.submit` lẫn trigger SQL `check_ins_before_write` từ chối với lỗi `invalid_captured_at`. Nghiêm trọng hơn, cả hai màn đọc `ref.read(deviceTimezoneProvider).value ?? 'UTC'` mà không watch `FutureProvider` này, nên lần mở đầu tiên luôn gán múi giờ hành trình thành `'UTC'` (12:00 UTC = 19:00 giờ Việt Nam).
- **Vì sao sai:** `noonInZone` (`sharing_providers.dart:139-142`) không kẹp `capturedAt <= now` khi `date == today`; `ImportFlowScreen._today()` (`import_flow_screen.dart:86-89`) còn lấy `now.year/month/day` trực tiếp từ `Clock` UTC; và cả `ImportFlowScreen._save` (`184`) lẫn `RetellScreen._save` (`115`) đều đọc `.value` đồng bộ của `deviceTimezoneProvider` chưa khởi tạo thay vì `await ref.read(deviceTimezoneProvider.future)`.
- **Hướng sửa:** Dùng `await ref.read(deviceTimezoneProvider.future)` (có fallback `'UTC'` khi lỗi) để lấy đúng múi giờ thiết bị, tính `_today()` theo múi giờ đó, và kẹp giá trị trả về của `noonInZone` không vượt quá `clock.now()`.
- **Test tạm:** `apps/mobile/test/zz_bugscan_c/import_sharing_bugs_test.dart` — chạy fail (`0 +0 -6`, hai test B12 fail ở dòng 136 và dòng 207 với `Actual: 'UTC'`).

#### C-B13. Tab Nhóm hiển thị các nhóm đã kết thúc trong mục "HÔM NAY" và mời bấm "Check-in ngay"

- **Vị trí:** `apps/mobile/lib/features/groups/ui/squad_tab_sections.dart:489` (liên quan: dòng `205`, và `apps/mobile/lib/features/groups/data/groups_providers.dart:18`)
- **Mức độ:** vừa
- **Độ chắc:** chắc chắn
- **Tình huống gây lỗi:** Khi một nhóm đã kết thúc (`JourneyStatus.ended`, chưa lưu trữ), mở tab Nhóm (`/groups`) vẫn thấy nhóm đó nằm dưới tiêu đề `"HÔM NAY"` với trạng thái `"Chưa ghi hôm nay"`. Chạm vào avatar của chính mình trên thẻ nhóm sẽ mở sheet thành viên có nút chính `"Check-in ngay"` (`squad-member-checkin`), dẫn người dùng sang camera của hành trình đã kết thúc không thể chụp.
- **Vì sao sai:** `groupJourneysProvider` (`groups_providers.dart:17-28`) lọc từ `journeyRepository.watchActive()` — stream trả tất cả hành trình chưa `archived` (bao gồm cả `ended`) — nhưng `SquadTodayCard` (`squad_tab_sections.dart:205`) và `_MemberSheet` (`squad_tab_sections.dart:489: final canCheckIn = entry.isMe && !entry.checkedInToday;`) không kiểm tra `journey.status == JourneyStatus.active`.
- **Hướng sửa:** Kiểm tra `journey.status == JourneyStatus.active` trước khi bật `canCheckIn` trong `_MemberSheet` và hiển thị nhãn đã kết thúc (hoặc tách mục nhóm đã kết thúc) trên `GroupsListScreen`.
- **Test tạm:** `apps/mobile/test/zz_bugscan_c/groups_bugs_test.dart` — chạy fail (`0 +0 -4`, test B13 fail ở dòng 175 vì nút `squad-member-checkin` vẫn hiển thị cho nhóm `ended`).

#### C-B14. Thành viên thường trong nhóm thấy nút Lưu câu chuyện và nút "Dừng chia sẻ" hoạt động sai phân quyền ở `StoryEditorScreen` & `ShareJourneyPanel`

- **Vị trí:** `apps/mobile/lib/features/sharing/ui/story_editor_screen.dart:164` (liên quan: dòng `71`, `96`, và `apps/mobile/lib/features/sharing/ui/share_journey_sheet.dart:353`)
- **Mức độ:** vừa
- **Độ chắc:** chắc chắn
- **Tình huống gây lỗi:** (1) Thành viên không phải chủ nhóm mở `/sharing/:id/story` (để ẩn ảnh của mình) vẫn sửa được tiêu đề/mở đầu/bài học/ảnh bìa và bấm nút `Lưu` (`story-save`), nhưng RPC `update_journey_story` từ chối với `forbidden` và UI báo nhầm `"Chỉ chia sẻ được với bạn bè"`. (2) Chủ hành trình chọn một ảnh làm ảnh bìa rồi bấm ẩn chính ảnh đó trên `StoryEditorScreen` thì `_coverId` vẫn giữ ảnh đã ẩn. (3) Khi nhóm có `linkOn == true` và `viewers.isEmpty`, thành viên thường vẫn thấy nút `"Dừng chia sẻ"` (`share-stop`); bấm xác nhận chỉ gọi `unshare(id, all: false)` nên không có gì thay đổi.
- **Vì sao sai:** `StoryEditorScreen` (`story_editor_screen.dart:164-169, 217-248`) bật `canSave: true` và cho sửa các trường câu chuyện mà không kiểm tra `currentUserId == journey.ownerId`; `_toggleHidden` (`96-109`) không xóa `_coverId` khi `hide && _coverId == checkIn.id`; và `ShareJourneyPanel` (`share_journey_sheet.dart:353-360`) hiển thị `share-stop` khi `state.viewers.isNotEmpty || state.linkOn` ngay cả khi `!owner && state.viewers.isEmpty`.
- **Hướng sửa:** Trên `StoryEditorScreen`, chỉ cho chủ hành trình sửa câu chuyện và bấm `Lưu` (thành viên thường chỉ bật/tắt ẩn ảnh của mình), xóa `_coverId` khi ảnh bìa bị ẩn; trên `ShareJourneyPanel`, chỉ hiện `share-stop` khi `state.viewers.isNotEmpty || (owner && state.linkOn)`.
- **Test tạm:** `apps/mobile/test/zz_bugscan_c/import_sharing_bugs_test.dart` — chạy fail (`0 +0 -6`, hai test B14 fail ở dòng 245 và dòng 288).

#### C-B15. Bấm "Trả lời" trên một ảnh cụ thể ở `SharedJourneyScreen` đánh rơi `checkInId` khi sang `ChatScreen`

- **Vị trí:** `apps/mobile/lib/features/sharing/ui/shared_journey_screen.dart:166` & `apps/mobile/lib/features/social/ui/chat_screen.dart:69` (liên quan: dòng `92`)
- **Mức độ:** vừa
- **Độ chắc:** chắc chắn
- **Tình huống gây lỗi:** Người xem mở hành trình được chia sẻ (`/shared/:id`), bấm nút `"Trả lời"` (`shared-reply-p1`) dưới bức ảnh `p1`, rồi gõ tin nhắn hoặc gửi ảnh trong màn `ChatScreen` vừa mở ra. Tin nhắn gửi đi có `replyToCheckInId == null`, mất hoàn toàn ảnh thu nhỏ ngữ cảnh (`message-reply-context`) cho biết đang trả lời bức ảnh nào.
- **Vì sao sai:** `SharedJourneyScreen._reply` (`shared_journey_screen.dart:166-169`) truyền `checkInId: p.checkInId` vào `openForReply` (RPC `open_conversation` chỉ tạo/tìm hội thoại theo `journey_id`, không lưu `p_checkin`), rồi `context.push(SharingPaths.chat(id))` mà không đính kèm `p.checkInId`; phía `ChatScreen` (`chat_screen.dart:69, 92`) cũng gọi `sendText` / `sendPhoto` mà không truyền tham số `replyToCheckInId`.
- **Hướng sửa:** Truyền `checkInId` qua query parameter của `/chat/:conversationId?replyTo=<checkInId>` vào `ChatScreen`, gắn nó vào tin nhắn đầu tiên gửi đi (`sendText` / `sendPhoto(replyToCheckInId: ...)`) rồi xóa trạng thái đang trả lời.
- **Test tạm:** `apps/mobile/test/zz_bugscan_c/import_sharing_bugs_test.dart` — chạy fail (`0 +0 -6`, test B15 fail ở dòng 327 vì `replyToCheckInId` bằng `null` thay vì `'p1'`).

## 3. Lỗi UX và UI (`ux-audit`)

Worker chấm: 0 P0, 8 P1, 11 P2, 4 P3. Quét `apps/mobile` @ `2af3610` theo skill `impeccable`, render golden 147 ảnh. Tất cả còn open.

| Mã | Vấn đề | Mức |
| --- | --- | --- |
| U1 | Thanh hành động cố định dưới đáy của `UiScaffold` mất vùng đệm an toàn (`SafeArea`), làm nút chính đè vào Home Indicator / thanh cử chỉ | `P1` · **Độ chắc:** **chắc chắn** |
| U2 | HUD camera của giao diện Giảm cân (`Quiet Transformer`) chồng đè thanh trượt cân nặng lên cụm nút `Bóng ngày 1` và `Kho riêng tư` trên màn tiếng Việt 360dp | `P1` · **Độ chắc:** **chắc chắn** |
| U3 | `UiPressable` không gộp ngữ nghĩa con khi thiếu `semanticLabel`, biến toàn bộ thẻ chọn Onboarding Quiz, danh sách Bạn bè, Hộp thư Hoạt động và thẻ QR thành nút rỗng với VoiceOver / TalkBack | `P1` · **Độ chắc:** **chắc chắn** |
| U4 | Màn tổng kết `JourneyWrappedScreen` làm kẹt người dùng trình đọc màn hình ở trang đầu và vứt bỏ toàn bộ tùy chỉnh khi bấm `Chia sẻ` hoặc `Lưu ảnh` | `P1` · **Độ chắc:** **chắc chắn** |
| U5 | Nhiều điều khiển tương tác chính nhỏ hơn chuẩn chạm tối thiểu 44pt (iOS) và 48dp (Android): `UiSegmented` (40dp), ô lịch Tối giản (43.1dp), ô nhập Check-in (47dp) và Chat (45dp) | `P1` · **Độ chắc:** **chắc chắn** |
| U6 | Hàng `Đăng xuất` trong Cài đặt thoát tài khoản ngay sau 1 chạm mà không hỏi xác nhận hay xử lý lỗi, trái ngược với cảnh báo mất ảnh chưa đồng bộ ở Hồ sơ | `P1` · **Độ chắc:** **chắc chắn** |
| U7 | Màn Camera bị từ chối quyền vĩnh viễn trên Android không hiện nút `Mở Cài đặt`, để lại nút `Thử lại` không thể xin lại quyền | `P1` · **Độ chắc:** **chắc chắn** |
| U8 | Thẻ `Tiếp tục tạo hành trình` trên Hub báo đang giữ Bước X/5 nhưng khi mở lại xóa sạch dữ liệu và quay về Bước 1/5 | `P1` · **Độ chắc:** **chắc chắn** |
| U9 | Tab gốc `Hồ sơ` trên thanh Dock hiển thị nút Quay lại (`←`) ở góc trái trên, bấm vào bị nhảy sang màn Camera | `P2` · **Độ chắc:** **chắc chắn** |
| U10 | Màn `GroupTodayScreen` của giao diện Nhóm (`Squad`) vẽ lặp hai thanh tiến độ màu cam và hai dòng điểm danh `3/4` sát nhau | `P2` · **Độ chắc:** **chắc chắn** |
| U11 | Công tắc `Làm mờ ảnh` trên màn Tạo thiệp cho phép gạt tắt ở giao diện Giảm cân nhưng bị bỏ qua, và bảng chọn màu avatar ở Thiết lập hồ sơ không lưu kết quả | `P2` · **Độ chắc:** **chắc chắn** |
| U12 | Thao tác `Lưu trữ` hành trình thực thi tức thì không hỏi xác nhận, không có thông báo phản hồi và không có lối khôi phục trong ứng dụng | `P2` · **Độ chắc:** **chắc chắn** |
| U13 | Hai liên kết `Điều khoản sử dụng` và `Chính sách quyền riêng tư` ở màn Đăng nhập đều dẫn về `SafetyHub` và bị rớt dòng rời rạc | `P2` · **Độ chắc:** **chắc chắn** |
| U14 | Tương phản chữ thấp và chỉ dùng màu viền để báo trạng thái đang chọn ở bộ chọn Icon ứng dụng, `UiAvatar`, thẻ riêng tư Check-in và chỉ số `Insights` | `P2` · **Độ chắc:** **chắc chắn** |
| U15 | Ở cỡ chữ `2.0x`, nút nổi `Check-in` ngắt gãy giữa từ (`Chec / k-in`), chữ cái tràn khỏi vòng tròn `UiAvatar`, và thẻ chuỗi ngày trên Hub bị cắt mất ý chính | `P2` · **Độ chắc:** **chắc chắn** |
| U16 | Màn `BlockedUsersScreen` hiển thị mọi tài khoản bị chặn giống hệt nhau là `"Người dùng"` khi mở trên máy mới hoặc mất bộ nhớ đệm cục bộ | `P2` · **Độ chắc:** **chắc chắn** |
| U17 | Viên nang chọn tab trên `UiDock` bo tròn kiểu bầu dục hẹp (`63×56dp`), làm chữ `"Hành trình"` và `"Hoạt động"` đâm xuyên qua viền đen trên màn 360dp | `P2` · **Độ chắc:** **chắc chắn** |
| U18 | Màn Hồ sơ và Cài đặt hiển thị thông tin Ngôn ngữ mâu thuẫn nhau và lặp lại các hàng chức năng tài khoản | `P2` · **Độ chắc:** **chắc chắn** |
| U19 | Biểu mẫu ở `JourneyEditScreen`, `StoryEditorScreen` và `RetellScreen` thiếu phản hồi trạng thái hợp lệ và không cảnh báo mất nội dung chưa lưu khi bấm Quay lại | `P2` · **Độ chắc:** **chắc chắn** |
| U20 | Rò rỉ tên giao diện tiếng Anh nội bộ (`Memory Collectors`, `Memory`, `Minimalist`, `QUIET TRANSFOR...`) ngay trên màn hình tiếng Việt | `P3` · **Độ chắc:** **chắc chắn** |
| U21 | Tiêu đề mục và nhãn ô nhập bị lặp nguyên văn hai dòng liên tiếp trên màn Thêm bạn, Sửa hành trình, Kể lại và Check-in | `P3` · **Độ chắc:** **chắc chắn** |
| U22 | Cụm nút `Chọn tất cả / Bỏ chọn` bị xếp chồng dọc lệch lạc và phơi nguyên URL Edge Function dài 3 dòng trên màn `ShareJourneyScreen` | `P3` · **Độ chắc:** **chắc chắn** |
| U23 | Quy tắc viết hoa tiêu đề mục không đồng nhất trên màn `SettingsScreen` và dư nút mở Hồ sơ ở góc phải trên của `GroupsListScreen` | `P3` · **Độ chắc:** **chắc chắn** |

#### U1. Thanh hành động cố định dưới đáy của `UiScaffold` mất vùng đệm an toàn (`SafeArea`), làm nút chính đè vào Home Indicator / thanh cử chỉ

- **Mức độ:** `P1` · **Độ chắc:** **chắc chắn**
- **Màn hình & vị trí:** Khung trang dùng chung và các màn Tạo hành trình, Chấp nhận điều khoản (EULA), Báo cáo, Liên hệ, Xem trước bố cục — `apps/mobile/lib/ui/components/layout.dart:49-52`, `apps/mobile/lib/ui/components/layout.dart:68-79`, `apps/mobile/lib/features/journeys/ui/create/create_flow_screen.dart:387`, `apps/mobile/lib/features/journeys/ui/create/create_flow_screen.dart:403`, `apps/mobile/lib/features/safety/ui/safety_common.dart:70-80`, `apps/mobile/lib/features/journeys/ui/edit/journey_edit_screen.dart:781-799`
- **Ảnh hưởng & Persona:** **Riley** và **Jordan** bấm nút tiếp tục ở cuối màn hình rất dễ kích hoạt nhầm cử chỉ vuốt về màn hình chính của iOS/Android, hoặc thấy thanh gạch ngang hệ thống cắt ngang chữ trên nút.
- **Bằng chứng:** Ảnh `apps/mobile/test/zz_uxscan/out/create_step5_ticket_en_393_light.png`, `apps/mobile/test/zz_uxscan/out/safety_eula_gate_en_393_light.png`, `apps/mobile/test/zz_uxscan/out/safety_report_en_393_light.png` và `apps/mobile/test/zz_uxscan/out/create_step1_vi_360_scale2.png` cho thấy nút `Continue`, `Agree and continue`, `Cancel` và `Chọn kiểu này` nằm sát đáy màn hình (`16–20dp`), đè trọn vào vùng Home Indicator `34dp` của màn `393×852`. Trong `layout.dart:49`, biểu thức `final useSafeBottom = safeBottom ?? (!scroll && bottom == null);` trả về `false` mỗi khi truyền `bottom:`, khiến cả `SafeArea` lẫn `bottomInset` đều bằng `0`.
- **Hướng sửa:** Trong `UiScaffold` (`apps/mobile/lib/ui/components/layout.dart:78`), bọc slot `bottom` bằng `SafeArea(top: false, child: bottom!)` (và bỏ phần cộng thủ công `MediaQuery.paddingOf(context).bottom` ở các màn đã tự chắp vá để không bị nhân đôi khoảng đệm).

#### U2. HUD camera của giao diện Giảm cân (`Quiet Transformer`) chồng đè thanh trượt cân nặng lên cụm nút `Bóng ngày 1` và `Kho riêng tư` trên màn tiếng Việt 360dp

- **Mức độ:** `P1` · **Độ chắc:** **chắc chắn**
- **Màn hình & vị trí:** Màn Camera `/capture` — `apps/mobile/lib/features/camera/capture_overlays.dart:131-172`
- **Ảnh hưởng & Persona:** **Riley** kéo thanh cân nặng bị bấm nhầm sang bật/tắt bóng ngày 1; **Sam** ở cỡ chữ `2.0x` không đọc được cả số cân lẫn nhãn nút vì hai lớp chữ trắng–đen đè kín lên nhau.
- **Bằng chứng:** Ảnh `apps/mobile/test/zz_uxscan/out/camera_ready_vi_360_light.png` (cỡ chữ chuẩn `1.0x`) và `apps/mobile/test/zz_uxscan/out/camera_ready_vi_360_scale2.png` (`2.0x`). Trên màn hình rộng `360dp` (khung ngắm rộng `288dp` sau lề), hai chip tiếng Việt `"👁 Bóng ngày 1 · Bật"` và `"🔒 Kho riêng tư"` tự xuống thành 2 dòng trong `Wrap` (cao ~`100dp`, vươn từ `bottom: 44` lên `bottom: 144`), đâm thẳng vào khối `Slider` cân nặng và dòng `"Lần cân gần nhất 62.6 kg"` đang neo cứng ở `Positioned(bottom: 92)`.
- **Hướng sửa:** Gộp hai khối `Positioned(bottom: 44)` và `Positioned(bottom: 92)` trong `_quiet()` (`capture_overlays.dart:131-172`) thành một `Positioned(left: UiSpace.lg, right: UiSpace.lg, bottom: 44)` duy nhất chứa `Column(mainAxisSize: MainAxisSize.min)` với `SizedBox(height: UiSpace.sm)` ngăn cách.

#### U3. `UiPressable` không gộp ngữ nghĩa con khi thiếu `semanticLabel`, biến toàn bộ thẻ chọn Onboarding Quiz, danh sách Bạn bè, Hộp thư Hoạt động và thẻ QR thành nút rỗng với VoiceOver / TalkBack

- **Mức độ:** `P1` · **Độ chắc:** **chắc chắn**
- **Màn hình & vị trí:** Khung bấm chung và các màn Onboarding Quiz, Hoạt động (`/inbox`), Bạn bè (`/friends`), Thêm bạn (`/friends/add`) — `apps/mobile/lib/ui/components/pressable.dart:106-113`, `apps/mobile/lib/ui/components/flow_kit.dart:419-425`, `apps/mobile/lib/features/onboarding/onboarding_quiz.dart:480-512`, `apps/mobile/lib/features/onboarding/onboarding_quiz.dart:539-572`, `apps/mobile/lib/features/social/ui/inbox_screen.dart:369-383`, `apps/mobile/lib/features/social/ui/friends_screen.dart:154-166`, `apps/mobile/lib/features/social/ui/add_friends_screen.dart:94-99`
- **Ảnh hưởng & Persona:** **Alex** (người dùng khiếm thị bật VoiceOver/TalkBack) mở ứng dụng lần đầu chỉ nghe thấy 6 lần `"Chưa chọn, Nút"` hoàn toàn không có nội dung câu trả lời, và không biết mình đang chạm vào cuộc trò chuyện hay người bạn nào trong danh bạ.
- **Bằng chứng:** Matcher `labeledTapTargetGuideline` báo `FAIL: expected tappable node to have semantic label, but none was found` trên cả 4 cấu hình của `onboarding_quiz_*` (`SemanticsNode#7, #9, #11, #13, #15, #17` — cả 6 thẻ chọn mục tiêu đầu tiên của app), `inbox_data_*` (`SemanticsNode#37, #44, #46`), `friends_data_*` (`SemanticsNode#33, #35`) và `add_friends_*` (`SemanticsNode#31`, nơi `_QrBlock` còn bọc thêm một lớp `Semantics(button: true)` lồng ngoài `_Block`).
- **Hướng sửa:** Bọc nhánh `Semantics` của `UiPressable` (`apps/mobile/lib/ui/components/pressable.dart:106`) trong `MergeSemantics` khi `widget.semanticLabel == null && !widget.excludeChildSemantics`, đồng thời xóa `Semantics(button: true)` dư thừa ở `_QrBlock` (`add_friends_screen.dart:250`).

#### U4. Màn tổng kết `JourneyWrappedScreen` làm kẹt người dùng trình đọc màn hình ở trang đầu và vứt bỏ toàn bộ tùy chỉnh khi bấm `Chia sẻ` hoặc `Lưu ảnh`

- **Mức độ:** `P1` · **Độ chắc:** **chắc chắn**
- **Màn hình & vị trí:** Tổng kết hành trình `/journeys/:id/wrapped` — `apps/mobile/lib/features/journeys/ui/wrapped/journey_wrapped_screen.dart:103-124`, `apps/mobile/lib/features/journeys/ui/wrapped/journey_wrapped_screen.dart:240-247`, `apps/mobile/lib/features/journeys/ui/wrapped/journey_wrapped_screen.dart:448-499`
- **Ảnh hưởng & Persona:** **Alex** không thể xem hết câu chuyện tổng kết; **Casey** và **Jordan** bật ẩn cân nặng/làm mờ ảnh rồi bấm `Lưu ảnh` nhưng bị chuyển sang màn khác với cấu hình mất sạch.
- **Bằng chứng:** Matcher `labeledTapTargetGuideline` FAIL trên cả 4 cấu hình `journey_wrapped_story_*` (`SemanticsNode#31 ... actions: [scrollLeft, scrollRight, tap]: expected tappable node to have semantic label`); ảnh `apps/mobile/test/zz_uxscan/out/journey_wrapped_story_vi_360_light.png` và `apps/mobile/test/zz_uxscan/out/journey_wrapped_summary_vi_360_light.png`. Ở dòng `242`, `_Story` quyết định tiến/lùi bằng `d.localPosition.dx > c.maxWidth / 2`; khi VoiceOver/TalkBack kích hoạt chạm đúp vào đúng tâm widget (`dx == c.maxWidth / 2`), biểu thức trả về `false` nên luôn **lùi trang**, còn thanh `_Segments` (dòng `120`) chỉ có `pages.length` đoạn nên không thể nhảy tới trang `_Summary`. Khi sang được `_Summary`, cả 3 nút `Chia sẻ lên Story`, `Chia sẻ` và `Lưu ảnh` (dòng `455, 480, 493`) chỉ gọi `context.push(AppRoutes.share(journey.id))`: mọi công tắc `9:16`/`4:5`, `Ẩn số kg`, `Làm mờ ảnh`, `Ẩn chữ ourney` vừa chỉnh đều bị hủy và nút `Lưu ảnh` không hề lưu ảnh. Ngoài ra, thanh tiêu đề vẽ đồng thời nút `←` và nút `✕` nhưng cả hai đều đóng thoát màn hình.
- **Hướng sửa:** Thêm `Semantics` có `onScrollLeft`/`onScrollRight`/nút điều hướng rõ ràng cho `_Story`, đổi nút `←` của `UiBackHeader` thành lùi 1 trang khi `_page > 0`, và truyền các tham số định dạng/riêng tư sang `ShareCardScreen` (hoặc gọi thẳng `shareCardExporterProvider` cho nút `Lưu ảnh`).

#### U5. Nhiều điều khiển tương tác chính nhỏ hơn chuẩn chạm tối thiểu 44pt (iOS) và 48dp (Android): `UiSegmented` (40dp), ô lịch Tối giản (43.1dp), ô nhập Check-in (47dp) và Chat (45dp)

- **Mức độ:** `P1` · **Độ chắc:** **chắc chắn**
- **Màn hình & vị trí:** Thanh chuyển đoạn dùng chung, Chi tiết hành trình Tối giản, Check-in, Chat, Tạo thiệp — `apps/mobile/lib/ui/components/segmented.dart:94`, `apps/mobile/lib/ui/components/segmented.dart:104-106`, `apps/mobile/lib/features/journeys/ui/widgets/timeline_variants.dart:971`, `apps/mobile/lib/features/journeys/ui/widgets/timeline_variants.dart:1046-1050`, `apps/mobile/lib/features/checkin/checkin_screen.dart:451-478`, `apps/mobile/lib/features/social/ui/chat_screen.dart:377-412`, `apps/mobile/lib/features/share_card/ui/share_card_screen.dart:199-245`
- **Ảnh hưởng & Persona:** **Riley** (bấm ngón cái một tay trên điện thoại 360dp) và **Alex** dễ bấm trượt hoặc chạm nhầm sang ngày kế bên trên lưới lịch 7 cột.
- **Bằng chứng:** Kết quả matcher trên hàng loạt cấu hình:
- **Hướng sửa:** Tăng chiều cao khung `UiSegmented` lên `56dp` (hoặc giữ vẻ ngoài `40dp` nhưng bỏ `padding` khỏi vùng nhận chạm để `UiPressable` đạt `minSize: Size(UiSize.tap, UiSize.tap)` `48dp`); giảm lề ngang lưới `MinimalTimeline` trên màn `< 380dp` / bỏ `minSize: 0`; dùng `UiTextArea` / `UiIconButton` chuẩn `UiSize.tap` (`48dp`) cho Check-in, Chat và ShareCard.

#### U6. Hàng `Đăng xuất` trong Cài đặt thoát tài khoản ngay sau 1 chạm mà không hỏi xác nhận hay xử lý lỗi, trái ngược với cảnh báo mất ảnh chưa đồng bộ ở Hồ sơ

- **Mức độ:** `P1` · **Độ chắc:** **chắc chắn**
- **Màn hình & vị trí:** Cài đặt `/profile/settings` — `apps/mobile/lib/features/profile/settings_screen.dart:54-61` (đối chiếu `apps/mobile/lib/features/profile/profile_screen.dart:335-380`)
- **Ảnh hưởng & Persona:** **Casey** và **Riley** chạm nhầm hàng có dấu `>` khi đang ngoại tuyến có thể bị đăng xuất đột ngột và mất vĩnh viễn ảnh vừa chụp chưa kịp đồng bộ.
- **Bằng chứng:** Ảnh `apps/mobile/test/zz_uxscan/out/settings_vi_360_light.png` cho thấy hàng `"Đăng xuất"` nằm ngay dưới `"Sửa hồ sơ"` với màu chữ thường và có mũi tên điều hướng `>` ở cuối hàng giống hệt một mục mở trang con. Trong `settings_screen.dart:59`, `onPressed: () => unawaited(ref.read(authRepositoryProvider).signOut())` đăng xuất tức thì không qua `showUiConfirmSheet` (trong khi `ProfileScreen` cảnh báo rõ qua `profile_signOutMessage` rằng đăng xuất sẽ xóa ảnh và check-in chưa đồng bộ trên máy) và không có `try/catch` báo lỗi khi mất mạng.
- **Hướng sửa:** Dùng lại hàm xác nhận `showUiConfirmSheet` có cảnh báo `profile_signOutMessage` giống `ProfileScreen`, bọc `signOut()` trong `try/catch` hiển thị `showUiToast`, và đặt `showChevron: false` trên `UiRow` `"Đăng xuất"`.

#### U7. Màn Camera bị từ chối quyền vĩnh viễn trên Android không hiện nút `Mở Cài đặt`, để lại nút `Thử lại` không thể xin lại quyền

- **Mức độ:** `P1` · **Độ chắc:** **chắc chắn**
- **Màn hình & vị trí:** Camera `/capture` — `apps/mobile/lib/features/camera/capture_services.dart:49-66`, `apps/mobile/lib/features/camera/widgets/camera_panels.dart:133-150`
- **Ảnh hưởng & Persona:** **Jordan** trên máy Android bị rơi vào ngõ cụt ngay màn hình khởi động của ứng dụng: bấm `Thử lại` liên tục nhưng màn hình không phản hồi gì thêm.
- **Bằng chứng:** Trong `capture_services.dart:52`, `UrlLauncherSettingsOpener.supported` kiểm tra cứng `defaultTargetPlatform == TargetPlatform.iOS` và chỉ mở `app-settings:` cho iOS. Trên Android, `settingsSupported` luôn bằng `false`, nên khi gặp `CameraFailure.permissionDeniedPermanently`, `CameraFailurePanel` (dòng `146-148`) ẩn nút `Mở Cài đặt` và hiển thị nút phụ `Thử lại`; nhưng khi người dùng Android đã chọn *"Don't ask again"*, gọi lại `session.start()` sẽ lập tức trả về lỗi cũ mà không bật hộp thoại hệ thống.
- **Hướng sửa:** Bổ sung mở trang App Details Settings của Android qua platform channel sẵn có (tương tự luồng mở cài đặt thông báo ở `reminders`) để `settingsSupported` hoạt động trên cả iOS lẫn Android, và ẩn nút `Thử lại` khi trạng thái là `permissionDeniedPermanently`.

#### U8. Thẻ `Tiếp tục tạo hành trình` trên Hub báo đang giữ Bước X/5 nhưng khi mở lại xóa sạch dữ liệu và quay về Bước 1/5

- **Mức độ:** `P1` · **Độ chắc:** **chắc chắn**
- **Màn hình & vị trí:** Luồng tạo hành trình `/journeys/new` & Danh sách hành trình `/journeys` — `apps/mobile/lib/features/journeys/ui/create/create_flow_screen.dart:439-447`, `apps/mobile/lib/features/journeys/data/create_progress.dart:5-37`, `apps/mobile/lib/features/journeys/ui/journeys_list_screen.dart:209-243`
- **Ảnh hưởng & Persona:** **Jordan** cảm thấy bị đánh lừa khi ứng dụng chủ động hứa hẹn lưu tiến độ bước 4/5 nhưng thực tế làm mất toàn bộ công sức nhập liệu.
- **Bằng chứng:** Ảnh `apps/mobile/test/zz_uxscan/out/hub_data_vi_360_light.png` hiển thị nổi bật thẻ `"Tiếp tục tạo hành trình · bước 4/5"`. Tuy nhiên `onClose` ở `create_flow_screen.dart:441-446` đóng màn ngay không hỏi xác nhận và chỉ lưu một số nguyên `_step + 1` vào `CreateProgressPrefs`; `CreateFlowScreen` không hề đọc lại `createProgressProvider` hay bản nháp biểu mẫu, nên bấm vào thẻ trên Hub luôn mở lại Bước 1/5 với mọi câu trả lời DNA/tên hành trình bị mất trắng, đồng thời nếu bấm `←` thoát từ Bước 1 thì thẻ `"bước 4/5"` vẫn kẹt mãi trên Hub.
- **Hướng sửa:** Lưu kèm bản nháp JSON (`option`, `step`, `dna`, `title`, `who`, `duration`) trong `CreateProgressPrefs` để khôi phục đúng bước, hoặc nếu chưa lưu nháp thì hiện `showUiConfirmSheet` cảnh báo hủy khi bấm `✕` và bỏ thẻ giả lập tiếp tục trên Hub.

#### U9. Tab gốc `Hồ sơ` trên thanh Dock hiển thị nút Quay lại (`←`) ở góc trái trên, bấm vào bị nhảy sang màn Camera

- **Mức độ:** `P2` · **Độ chắc:** **chắc chắn**
- **Màn hình & vị trí:** Hồ sơ `/profile` — `apps/mobile/lib/features/profile/profile_screen.dart:33-39`, `apps/mobile/lib/features/profile/profile_screen.dart:53-57`
- **Ảnh hưởng & Persona:** **Jordan** và **Alex** bị rối mô hình phân cấp điều hướng vì một tab cấp cao nhất trên thanh điều hướng đáy lại mang hình thái của trang con đẩy chồng.
- **Bằng chứng:** Ảnh `apps/mobile/test/zz_uxscan/out/profile_signed_in_vi_360_light.png` cho thấy tab thứ 5 (`Hồ sơ`) trên `AppDock` đang được chọn sáng, nhưng đầu trang vẫn dựng `UiBackHeader` có nút tròn `←`. Khi vào từ thanh Dock (`context.canPop() == false`), hàm `_back` chạy `context.go(AppRoutes.capture)` đẩy người dùng sang tab Camera.
- **Hướng sửa:** Chỉ hiện nút `←` khi `context.canPop()` là `true` (giống cách `InboxScreen` đang xử lý tại `apps/mobile/lib/features/social/ui/inbox_screen.dart:107`), còn khi đứng ở nhánh gốc của Dock thì dùng `UiTopBar` tiêu đề `"hồ sơ."`.

#### U10. Màn `GroupTodayScreen` của giao diện Nhóm (`Squad`) vẽ lặp hai thanh tiến độ màu cam và hai dòng điểm danh `3/4` sát nhau

- **Mức độ:** `P2` · **Độ chắc:** **chắc chắn**
- **Màn hình & vị trí:** Hôm nay của nhóm `/groups/:journeyId` — `apps/mobile/lib/features/groups/ui/group_today_screen.dart:277-329`, `apps/mobile/lib/features/groups/ui/group_wall_skins.dart:69-102`
- **Ảnh hưởng & Persona:** **Jordan** nhìn thấy hai thanh tiến độ giống hệt nhau xếp chồng gây cảm giác lỗi giao diện; **Alex** phải nghe trình đọc màn hình đọc lặp thông tin điểm danh 4 lần liên tiếp.
- **Bằng chứng:** Ảnh `apps/mobile/test/zz_uxscan/out/group_today_squad_vi_360_light.png`, `apps/mobile/test/zz_uxscan/out/group_today_squad_vi_360_dark.png` và `apps/mobile/test/zz_uxscan/out/group_today_squad_vi_360_scale2.png`: `_SquadWall` gọi `_SharedStreak(view: view)` (vẽ `3/4` + thanh `UiProgressBar` + `"Hôm nay 3/4 người đã check-in"`), rồi ngay cách `12dp` bên dưới lại vẽ tiếp một `UiProgressBar` giống hệt + `"3/4 ĐÃ ĐIỂM DANH"`, đồng thời bọc `Semantics(label: label)` bên ngoài `UiProgressBar` vốn đã có `semanticLabel: label`.
- **Hướng sửa:** Gộp dòng `"Cập nhật lúc ..."` vào dưới `_SharedStreak` và xóa khối `UiProgressBar` + `Text(label)` trùng lặp tại `group_wall_skins.dart:74-97`.

#### U11. Công tắc `Làm mờ ảnh` trên màn Tạo thiệp cho phép gạt tắt ở giao diện Giảm cân nhưng bị bỏ qua, và bảng chọn màu avatar ở Thiết lập hồ sơ không lưu kết quả

- **Mức độ:** `P2` · **Độ chắc:** **chắc chắn**
- **Màn hình & vị trí:** Tạo thiệp `/share/:journeyId` (`apps/mobile/lib/features/share_card/ui/share_card_screen.dart:315`, `apps/mobile/lib/features/share_card/ui/share_card_screen.dart:398-407`) & Thiết lập hồ sơ `/profile/setup` (`apps/mobile/lib/features/profile/profile_setup_screen.dart:159-191`, `apps/mobile/lib/features/profile/profile_setup_screen.dart:249-271`)
- **Ảnh hưởng & Persona:** **Casey** và **Jordan** mất niềm tin khi giao diện phản hồi trạng thái bật/tắt hoặc dấu kiểm đã chọn nhưng kết quả cuối cùng không khớp.
- **Bằng chứng:** Trong `share_card_screen.dart:315`, `ShareCard` nhận `blur: quiet ? true : blur`, nhưng dòng `398` vẫn hiển thị công tắc tương tác `UiSwitchRow(key: ValueKey('share-card-blur'))` ngay cả khi `quiet == true`; người dùng gạt tắt thấy công tắc đổi trạng thái nhưng ảnh trên thiệp vẫn bị làm mờ. Tương tự, trên `apps/mobile/test/zz_uxscan/out/profile_setup_vi_360_light.png`, `ProfileAvatarSwatches` cho chọn 6 màu (`_color`) nhưng `_save()` hoàn toàn không lưu `_color`, còn hình mặt cười phía trên nhận thao tác chọn ảnh thật nhưng không có huy hiệu máy ảnh gợi ý như `UiAvatarPicker` (ngoài ra tiêu đề dòng `237` ghi sai tên font `'Space Grotesk'` có dấu cách thay vì `'SpaceGrotesk'`).
- **Hướng sửa:** Ở `ShareCardScreen`, ẩn hoặc khóa `UiSwitchRow` (`onChanged: null`) kèm giải thích khi `quiet == true` (hoặc tôn trọng `_blurOverride` khi người dùng chủ động tắt); ở `ProfileSetupScreen`, gắn huy hiệu máy ảnh của `UiAvatarPicker`, sửa `UiFonts.heading` (`'SpaceGrotesk'`) và lưu mã màu avatar hoặc bỏ dãy swatch chưa hỗ trợ lưu.

#### U12. Thao tác `Lưu trữ` hành trình thực thi tức thì không hỏi xác nhận, không có thông báo phản hồi và không có lối khôi phục trong ứng dụng

- **Mức độ:** `P2` · **Độ chắc:** **chắc chắn**
- **Màn hình & vị trí:** Chi tiết hành trình `/journeys/:id` & Kệ lưu trữ — `apps/mobile/lib/features/journeys/ui/journey_detail_screen.dart:503-507`, `apps/mobile/lib/features/journeys/ui/journey_actions.dart:32-41`
- **Ảnh hưởng & Persona:** **Casey** lỡ chạm vào `Lưu trữ` trong menu `...` bị chuyển màn đột ngột và không có cách đưa hành trình trở lại trạng thái cũ.
- **Bằng chứng:** Trong `_run()` (`journey_detail_screen.dart:490-521`), cả `Kết thúc` (`end`) và `Xóa` (`delete`) đều mở `confirmJourneyAction`, riêng `Lưu trữ` (`archive`, dòng `503-507`) gọi thẳng `repo.archive(journey.id)` rồi nhảy về `/journeys` mà không có hộp thoại xác nhận, không hiện `showUiToast` / hoàn tác, và `JourneyPermissions` không cung cấp thao tác bỏ lưu trữ (Unarchive) ở bất kỳ màn nào.
- **Hướng sửa:** Bọc `_Action.archive` bằng `confirmJourneyAction` (dùng `showUiConfirmSheet`) và hiển thị `showUiToast` xác nhận sau khi chuyển về Hub.

#### U13. Hai liên kết `Điều khoản sử dụng` và `Chính sách quyền riêng tư` ở màn Đăng nhập đều dẫn về `SafetyHub` và bị rớt dòng rời rạc

- **Mức độ:** `P2` · **Độ chắc:** **chắc chắn**
- **Màn hình & vị trí:** Đăng nhập `/auth` — `apps/mobile/lib/features/auth/auth_screen.dart:422-428`, `apps/mobile/lib/features/auth/auth_screen.dart:786-801`
- **Ảnh hưởng & Persona:** **Casey** muốn đọc ngay Chính sách quyền riêng tư trước khi đăng nhập phải bấm thêm bước trung gian, đồng thời câu đồng ý pháp lý hiển thị đứt đoạn khó đọc.
- **Bằng chứng:** Ảnh `apps/mobile/test/zz_uxscan/out/auth_email_vi_360_light.png` cho thấy câu chân trang bị tách thành 4 khối rời rạc (`"Tiếp tục nghĩa là bạn đồng ý"` / `"Điều khoản sử dụng"` căn giữa / `"và"` sát lề trái / `"Chính sách quyền riêng tư."` căn giữa) vì `UiTextAction` chiếm 100% chiều ngang của `Wrap`. Trong code dòng `791` và `798`, cả hai nút đều gọi `context.push(AppRoutes.safety)` thay vì `SafetyPaths.eula` và `SafetyPaths.privacy`.
- **Hướng sửa:** Trỏ `auth-terms` tới `SafetyPaths.eula` và `auth-privacy` tới `SafetyPaths.privacy`; sửa `UiTextAction` (`apps/mobile/lib/ui/components/buttons.dart:249`) co theo nội dung (`widthFactor: 1`) để câu liên kết nằm gọn trong `Wrap`.

#### U14. Tương phản chữ thấp và chỉ dùng màu viền để báo trạng thái đang chọn ở bộ chọn Icon ứng dụng, `UiAvatar`, thẻ riêng tư Check-in và chỉ số `Insights`

- **Mức độ:** `P2` · **Độ chắc:** **chắc chắn**
- **Màn hình & vị trí:** Cài đặt, Avatar dùng chung, Check-in, Thông tin chi tiết — `apps/mobile/lib/features/profile/settings_screen.dart:296-384`, `apps/mobile/lib/ui/components/avatar.dart:9-15`, `apps/mobile/lib/ui/components/avatar.dart:72-81`, `apps/mobile/lib/features/checkin/checkin_screen.dart:430`, `apps/mobile/lib/features/sharing/ui/insights_screen.dart:125`
- **Ảnh hưởng & Persona:** **Sam** (thị lực kém / mù màu đỏ–lục hoặc nhìn dưới nắng gắt) khó nhận ra icon nào đang chọn, khó đọc chữ cái đại diện và nhãn quyền riêng tư.
- **Bằng chứng:** - Ảnh `apps/mobile/test/zz_uxscan/out/settings_vi_360_light.png` & `apps/mobile/test/zz_uxscan/out/settings_en_393_light.png`: Ô icon `"Mặc định"` vẽ chữ `'O'` xanh ngọc `#10B981` trên nền đỏ san hô `#FF4D6D` (tương phản ~`1.35:1`, gây lóa mạnh với người mù màu đỏ–lục), ô `"Nhóm"` vẽ `#FF9F1C` trên `#FFF0C7` (~`1.82:1`), và trạng thái đang chọn chỉ khác ở màu/độ dày viền (`ui.focus` `3dp` so với `ui.outline` `1.5dp`) mà không có huy hiệu dấu kiểm (hơn nữa chọn xong icon màn hình chính vẫn chưa đổi thật, chỉ báo nhỏ ở chú thích `3.20:1` bên dưới).
- **Hướng sửa:** Thêm huy hiệu dấu kiểm góc phải trên (như `ui-choice-check` của `UiChoiceCard`) cho ô Icon đang chọn, dùng màu mực tối `UiFlowColors.onPastel` (`#1A1A1A`) cho các nền sáng trong `uiAvatarColors` / Icon tiles, và nâng độ đậm của `UiPrivacyTag` / `ui.success` trên nền sáng để đạt `>= 4.5:1`.

#### U15. Ở cỡ chữ `2.0x`, nút nổi `Check-in` ngắt gãy giữa từ (`Chec / k-in`), chữ cái tràn khỏi vòng tròn `UiAvatar`, và thẻ chuỗi ngày trên Hub bị cắt mất ý chính

- **Mức độ:** `P2` · **Độ chắc:** **chắc chắn**
- **Màn hình & vị trí:** Chi tiết hành trình, Avatar dùng chung, Danh sách hành trình, Tham gia nhóm — `apps/mobile/lib/features/journeys/ui/journey_detail_screen.dart:334-383`, `apps/mobile/lib/ui/components/avatar.dart:58-81`, `apps/mobile/lib/features/journeys/ui/journeys_list_screen.dart`, `apps/mobile/lib/features/journeys/ui/create/steps/type_step.dart`
- **Ảnh hưởng & Persona:** **Sam** (bật cỡ chữ lớn 200% trên điện thoại 360dp) đọc thấy chữ gãy vụn và mất thông tin quan trọng về số hành trình còn chờ chụp trong ngày.
- **Bằng chứng:** - Ảnh `apps/mobile/test/zz_uxscan/out/detail_quiet_vi_360_scale2.png`: Khi hiện chip `"NGÀY 13 · NGHỈ"` chiếm `45%` chiều ngang, nút `UiButton` bên phải chỉ còn `~93dp` cho văn bản ở `2.0x` nên chữ `"Check-in"` bị bẻ gãy thành 2 dòng `"Chec"` / `"k-in"` và đè lên tiêu đề hành trình; ở `apps/mobile/test/zz_uxscan/out/detail_minimal_vi_360_light.png`, lớp nút nổi + Dock cũng che khuất hàng huy hiệu cột mốc ở cuối trang khi chưa cuộn hết cỡ.
- **Hướng sửa:** Bọc `Text(initial)` của `UiAvatar` trong `FittedBox(fit: BoxFit.scaleDown)` (có padding `4dp`); trên `JourneyDetailScreen`, chuyển `Row` chứa `MissedDayOverlay` và `checkInButton` sang `Wrap` hoặc xếp dọc khi `MediaQuery.textScalerOf(context).scale(1) > 1.3`, đồng thời cộng thêm chiều cao nút nổi vào `bottomInset` của `ListView`.

#### U16. Màn `BlockedUsersScreen` hiển thị mọi tài khoản bị chặn giống hệt nhau là `"Người dùng"` khi mở trên máy mới hoặc mất bộ nhớ đệm cục bộ

- **Mức độ:** `P2` · **Độ chắc:** **chắc chắn**
- **Màn hình & vị trí:** Người đã chặn `/safety/blocked` — `apps/mobile/lib/features/safety/ui/blocked_users_screen.dart:70-83`, `apps/mobile/lib/features/safety/data/safety_providers.dart:26-29`
- **Ảnh hưởng & Persona:** **Casey** đăng nhập trên điện thoại mới hoặc sau khi cài lại app muốn gỡ chặn cho một người bạn sẽ không thể biết dòng `"Người dùng"` nào là bạn mình và dòng nào là kẻ quấy rối.
- **Bằng chứng:** Ảnh `apps/mobile/test/zz_uxscan/out/safety_blocked_vi_360_light.png` cho thấy hai người bị chặn khác nhau (`u-spam-1`, `u-spam-2`) hiển thị thành hai dòng giống hệt 100%: avatar hồng chữ `N` + tiêu đề `"Người dùng"` + nút `"Bỏ chặn"`. Nguyên nhân là `SafetyRepository.watchBlockedIds()` chỉ trả ID, còn tên hiển thị chỉ lưu tạm trong `SharedPreferences` cục bộ (`safety.blockedNames`) của thiết bị thực hiện thao tác chặn.
- **Hướng sửa:** Khi `names[id]` là `null`, hiển thị thêm định danh rút gọn ở `subtitle` của `UiRow` (hoặc truy vấn `PersonSummary` từ bảng hồ sơ cho danh sách ID bị chặn) và truyền `colorIndex: UiAvatar.indexFor(id)` vào `UiAvatar` để mỗi tài khoản có màu phân biệt ổn định.

#### U17. Viên nang chọn tab trên `UiDock` bo tròn kiểu bầu dục hẹp (`63×56dp`), làm chữ `"Hành trình"` và `"Hoạt động"` đâm xuyên qua viền đen trên màn 360dp

- **Mức độ:** `P2` · **Độ chắc:** **chắc chắn**
- **Màn hình & vị trí:** Thanh điều hướng nổi `AppDock` toàn ứng dụng — `apps/mobile/lib/ui/components/dock.dart:20-21`, `apps/mobile/lib/ui/components/dock.dart:178-197`, `apps/mobile/lib/ui/components/dock_tab.dart:30-36`
- **Ảnh hưởng & Persona:** **Riley** và **Sam** thấy nhãn tab chính bị viền cắt ngang ở mọi màn hình chuẩn `360dp`, và nhãn tab phụ mờ đi khi cuộn qua ảnh tối.
- **Bằng chứng:** Ảnh `apps/mobile/test/zz_uxscan/out/hub_data_vi_360_light.png`, `apps/mobile/test/zz_uxscan/out/hub_empty_vi_360_light.png`, `apps/mobile/test/zz_uxscan/out/detail_quiet_vi_360_light.png` và `apps/mobile/test/zz_uxscan/out/inbox_data_vi_360_light.png`: Trên màn `360dp`, mỗi ô tab rộng `~63dp`, viên nang chọn cao `56dp` dùng `BorderRadius.circular(UiRadius.capsule)` (`999`) biến thành hình gần tròn (`bán kính 28dp`), khiến dòng chữ `"Hành trình"` và `"Hoạt động"` ở đáy ô cắt ngang qua đường viền đen `1.5–2dp` ở cả hai mép trái–phải. Ngoài ra, matcher `textContrastGuideline` ghi nhận nhãn tab không chọn (`10.5sp`, `alpha: 0.72`) tụt xuống `1.98:1` (`hub_data_vi_360_light`) và `2.56–2.61:1` (`inbox_data_vi_360_light`, `detail_couple_vi_360_light`) khi thẻ có màu đậm nằm ngay dưới lớp kính mờ `tintAlpha = 0.62`.
- **Hướng sửa:** Đổi `borderRadius` của `dockSelectionDecoration` (`dock_tab.dart:33`) sang bo đồng tâm `BorderRadius.circular(22)` khớp với vỏ `UiDock` (`radius 32` trừ lề trong `10dp`) để đáy viên nang đủ bề ngang phẳng chứa chữ tiếng Việt, đồng thời nâng `tintAlpha` của dock lên `>= 0.82` (hoặc đặt nhãn tab phụ ở `ui.ink.withValues(alpha: 0.85)`).

#### U18. Màn Hồ sơ và Cài đặt hiển thị thông tin Ngôn ngữ mâu thuẫn nhau và lặp lại các hàng chức năng tài khoản

- **Mức độ:** `P2` · **Độ chắc:** **chắc chắn**
- **Màn hình & vị trí:** Hồ sơ `/profile` & Cài đặt `/profile/settings` — `apps/mobile/lib/features/profile/profile_screen.dart:293-330`, `apps/mobile/lib/features/profile/settings_screen.dart:48-84`, `apps/mobile/lib/features/profile/settings_screen.dart:228-270`
- **Ảnh hưởng & Persona:** **Jordan** cuộn trang Hồ sơ đọc thấy dòng khẳng định ngôn ngữ đi theo máy nên tưởng ứng dụng không hỗ trợ đổi ngôn ngữ thủ công, dù bộ chuyển nằm cách đó 1 chạm trong `Cài đặt`.
- **Bằng chứng:** Trong `profile_screen.dart:305-311`, phần cài đặt ngay dưới Hồ sơ vẽ một `UiRow` chết (không có `onPressed`) ghi `"Ngôn ngữ · Theo ngôn ngữ của máy. Mặc định là tiếng Việt."`, kể cả khi người dùng đã chọn ghi đè tiếng Anh/tiếng Việt qua `localeOverrideProvider` ở `SettingsScreen`. Đồng thời cả hai màn cùng liệt kê trùng `Sửa hồ sơ`, `Nhắc nhở` và `Đăng xuất`.
- **Hướng sửa:** Xóa hàng tĩnh `"Ngôn ngữ"` (cùng các hàng bị trùng) khỏi cuối `ProfileScreen`, hoặc biến hàng `"Ngôn ngữ"` trên `ProfileScreen` thành hàng hiển thị đúng ngôn ngữ hiện hành và bấm vào mở thẳng `SettingsScreen`.

#### U19. Biểu mẫu ở `JourneyEditScreen`, `StoryEditorScreen` và `RetellScreen` thiếu phản hồi trạng thái hợp lệ và không cảnh báo mất nội dung chưa lưu khi bấm Quay lại

- **Mức độ:** `P2` · **Độ chắc:** **chắc chắn**
- **Màn hình & vị trí:** Sửa hành trình `/journeys/:id/edit`, Sửa câu chuyện `/sharing/:id/story`, Kể lại hành trình `/retell` — `apps/mobile/lib/features/journeys/ui/edit/journey_edit_screen.dart:116-125`, `apps/mobile/lib/features/journeys/ui/edit/journey_edit_screen.dart:238`, `apps/mobile/lib/features/sharing/ui/story_editor_screen.dart:58-64`, `apps/mobile/lib/features/sharing/ui/retell_screen.dart:99-115`, `apps/mobile/lib/features/sharing/ui/retell_screen.dart:244-248`
- **Ảnh hưởng & Persona:** **Jordan** không rõ vì sao nút `Lưu` bị khóa, hoặc lỡ tay vuốt lùi làm mất đoạn giới thiệu/bài học 300 ký tự vừa viết trên `StoryEditorScreen`.
- **Bằng chứng:** Ảnh `apps/mobile/test/zz_uxscan/out/retell_vi_360_light.png` cho thấy nút chính `"Lưu lên kệ"` sáng cam hoàn toàn dù tên trống và chưa chọn tấm ảnh nào (chỉ báo lỗi sau khi bấm). Ngược lại, ở `JourneyEditScreen`, khi xóa trắng tên hành trình hoặc tên cặp đôi thì nút `"Lưu"` bị vô hiệu hóa âm thầm mà `UiTextField` không hiển thị thông báo `error:`. Ở cả `JourneyEditScreen` và `StoryEditorScreen`, gõ sửa nội dung dài rồi bấm `←` hoặc vuốt cạnh màn hình sẽ thoát ngay lập tức mà không có `PopScope` + `showUiConfirmSheet` giữ lại thay đổi.
- **Hướng sửa:** Truyền thông báo lỗi trực tiếp vào tham số `error:` của `UiTextField` trên `JourneyEditScreen`, bọc `JourneyEditScreen` và `StoryEditorScreen` trong `PopScope` hỏi xác nhận khi dữ liệu đã thay đổi (`_dirty`), và đồng bộ điều kiện bật nút của `RetellScreen` (đồng thời cân nhắc hợp nhất `/retell` với `/import` để tránh hai luồng nhập ảnh cũ khác nhau).

#### U20. Rò rỉ tên giao diện tiếng Anh nội bộ (`Memory Collectors`, `Memory`, `Minimalist`, `QUIET TRANSFOR...`) ngay trên màn hình tiếng Việt

- **Mức độ:** `P3` · **Độ chắc:** **chắc chắn**
- **Màn hình & vị trí:** Làm hành trình mẫu `/follow/:id`, Nhập hành trình cũ `/import`, Thẻ hành trình trên Hub `/journeys` — `apps/mobile/lib/features/sharing/ui/follow_journey_screen.dart:156-160`, `apps/mobile/lib/features/import/ui/import_flow_screen.dart:508-545`, `apps/mobile/lib/ui/components/journey_widgets.dart`
- **Ảnh hưởng & Persona:** **Jordan** (người dùng tiếng Việt phổ thông) gặp tên kỹ thuật của hệ thống thiết kế mà không hiểu ý nghĩa.
- **Bằng chứng:** Ảnh `apps/mobile/test/zz_uxscan/out/follow_journey_vi_360_light.png` hiện tiêu đề `"MEMORY COLLECTORS"` và `"Bắt đầu hành trình Memory Collectors của riêng bạn"`; ảnh `apps/mobile/test/zz_uxscan/out/import_setup_vi_360_light.png` hiện tên hai thẻ giao diện là `"Memory"` và `"Minimalist"` (trong khi `journey_edit_vi_360_light.png` đã Việt hóa là `"Lặng"`, `"Ký ức"`, `"Tối giản"`); ảnh `apps/mobile/test/zz_uxscan/out/hub_data_vi_360_light.png` hiện `"QUIET TRANSFOR..."` ở góc phải trên của thẻ hành trình.
- **Hướng sửa:** Dùng tên giao diện đã bản địa hóa theo `Localizations.localeOf(context)` (như bộ nhãn tiếng Việt đang dùng ở `JourneyEditScreen`) thay cho chuỗi hằng tiếng Anh `style.name`.

#### U21. Tiêu đề mục và nhãn ô nhập bị lặp nguyên văn hai dòng liên tiếp trên màn Thêm bạn, Sửa hành trình, Kể lại và Check-in

- **Mức độ:** `P3` · **Độ chắc:** **chắc chắn**
- **Màn hình & vị trí:** Thêm bạn `/friends/add`, Sửa hành trình `/journeys/:id/edit`, Kể lại `/retell`, Check-in `/checkin` — `apps/mobile/lib/features/social/ui/add_friends_screen.dart:380-405`, `apps/mobile/lib/features/journeys/ui/edit/journey_edit_screen.dart:288-300`, `apps/mobile/lib/features/sharing/ui/retell_screen.dart:325-345`, `apps/mobile/lib/features/checkin/checkin_screen.dart:436`, `apps/mobile/lib/features/checkin/checkin_screen.dart:462`, `apps/mobile/lib/features/checkin/post_extras.dart:200`
- **Ảnh hưởng & Persona:** **Riley** và **Jordan** thấy giao diện dư chữ lặp và phải cuộn thêm mới thấy các chip chọn tâm trạng ở màn Check-in.
- **Bằng chứng:** Ảnh `apps/mobile/test/zz_uxscan/out/add_friends_vi_360_light.png` vẽ hai dòng đậm `"Tìm bằng tên người dùng"` chồng sát nhau; ảnh `apps/mobile/test/zz_uxscan/out/journey_edit_vi_360_light.png` vẽ hai dòng `"Tên"` chồng nhau; ảnh `apps/mobile/test/zz_uxscan/out/retell_vi_360_light.png` vẽ chữ `"Chọn ảnh"` đối diện nút `"Chọn ảnh"`; ảnh `apps/mobile/test/zz_uxscan/out/checkin_compose_vi_360_light.png` có 2 nút `"Đăng"` (trên đầu và dưới đáy) và lặp 2 câu `"Hôm nay bạn cảm thấy thế nào?"` (một làm gợi ý chú thích, một làm tiêu đề hàng chip tâm trạng bị che khuất ngay dưới mép cuộn `800dp`).
- **Hướng sửa:** Bỏ tiêu đề mục ngoài khi `UiTextField` bên trong đã có cùng `label:`; ở `CheckinScreen`, bỏ nút chữ `"Đăng"` trùng trên đầu trang và rút gọn chiều cao tối đa của `_PhotoPreview` trên màn `<= 800dp` để lộ hàng chip `PostExtrasSection` trên cùng một tầm mắt.

#### U22. Cụm nút `Chọn tất cả / Bỏ chọn` bị xếp chồng dọc lệch lạc và phơi nguyên URL Edge Function dài 3 dòng trên màn `ShareJourneyScreen`

- **Mức độ:** `P3` · **Độ chắc:** **chắc chắn**
- **Màn hình & vị trí:** Chia sẻ hành trình `/sharing/:journeyId` — `apps/mobile/lib/features/sharing/ui/share_journey_sheet.dart:610-632`, `apps/mobile/lib/features/sharing/ui/share_journey_sheet.dart:815-823`
- **Ảnh hưởng & Persona:** **Jordan** và **Casey** thấy bố cục bị lệch và e ngại đường dẫn kỹ thuật dài ngoằng thay vì tên miền rút gọn thân thiện.
- **Bằng chứng:** Ảnh `apps/mobile/test/zz_uxscan/out/share_journey_vi_360_light.png` cho thấy hai `UiTextAction` `"Chọn tất cả"` và `"Bỏ chọn"` mỗi nút giãn hết chiều ngang cột phải nên xếp chồng dọc cao `~96dp` cạnh tiêu đề `"Bạn bè"`; bên dưới mục `"Bật liên kết"`, `subtitle` in thẳng đường dẫn máy chủ `https://.../functions/v1/public-journey?token=tok000...` tràn thành 3 dòng thô.
- **Hướng sửa:** Sửa `UiTextAction` (`buttons.dart:249`) dùng `IntrinsicWidth` / `Align(widthFactor: 1)` để hai nút nằm gọn trên 1 hàng ngang, và rút gọn `subtitle` của liên kết công khai bằng `maxLines: 1, overflow: TextOverflow.ellipsis` (hoặc hiển thị dạng `ourney.tech/p/...`).

#### U23. Quy tắc viết hoa tiêu đề mục không đồng nhất trên màn `SettingsScreen` và dư nút mở Hồ sơ ở góc phải trên của `GroupsListScreen`

- **Mức độ:** `P3` · **Độ chắc:** **chắc chắn**
- **Màn hình & vị trí:** Cài đặt `/profile/settings` (`apps/mobile/lib/features/profile/settings_screen.dart:48`, `66`, `73`, `80`, `82`, `84`) & Danh sách nhóm `/groups` (`apps/mobile/lib/features/groups/ui/groups_list_screen.dart:57`)
- **Ảnh hưởng & Persona:** **Jordan** cảm nhận sự thiếu đồng nhất nhỏ về nhịp điệu chữ và điểm vào Hồ sơ giữa các tab chính.
- **Bằng chứng:** Ảnh `apps/mobile/test/zz_uxscan/out/settings_vi_360_light.png` và `apps/mobile/test/zz_uxscan/out/settings_en_393_light.png` trộn lẫn tiêu đề viết thường kiểu V2 (`tài khoản`, `nhắc nhở`, `giao diện`, `riêng tư` / `account`, `reminders`, `appearance`, `privacy`) với tiêu đề viết hoa đầu câu (`Ngôn ngữ`, `Icon ứng dụng` / `Language`, `App icon`). Trên `apps/mobile/test/zz_uxscan/out/groups_data_vi_360_light.png`, thanh đầu trang `Nhóm` vẫn giữ `ProfileEntryButton` từ bản 3-tab cũ dù `AppDock` V2 bên dưới đã có sẵn tab `Hồ sơ`.
- **Hướng sửa:** Đồng bộ kiểu chữ thường cho tất cả `_SectionTitle` trong `SettingsScreen` và gỡ `ProfileEntryButton()` khỏi `GroupsListScreen` để thống nhất với `JourneysListScreen` và `InboxScreen`.

## 4. Tài liệu, asset, code và cấu hình lỗi thời (`stale-audit`)

Worker đếm: Tài liệu 13, Asset 5, Code 12, Cấu hình 4. Đây là việc dọn dẹp, không phải lỗi chạy. Danh sách 172 key l10n không dùng nằm ở mục S28.

| Mã | Mục | Đường dẫn | Độ chắc | Rủi ro khi xử lý |
| --- | --- | --- | --- | --- |
| S1 | Luật và skill UI cũ đang bật tự động trong `.agent/` | `.agent/rules/adaptive-persona-ui.md` | **chắc chắn** | **an toàn** |
| S2 | `CLAUDE.md` ở gốc repo còn giữ thông tin trước khi hoàn tất Design V2 | `CLAUDE.md` | **chắc chắn** | **an toàn** |
| S3 | Các skill trong `.claude/skills/` trỏ tới file đã xóa và bảng việc `docs/TASKS.md` cũ | `.claude/skills/design-ref/SKILL.md` | **chắc chắn** | **an toàn** |
| S4 | Bảng phân việc cũ `docs/TASKS.md` và bộ câu hỏi khách hàng `docs/client-questions.md` | `docs/TASKS.md` | **chắc chắn** | **an toàn** |
| S5 | Chuỗi tài liệu phân tích, kế hoạch và review giai đoạn đầu (`docs/01` đến `06`, `07-review`, `08-review`) | `docs/01-analysis.md` | **chắc chắn** | **an toàn** |
| S6 | Đặc tả `docs/07-SDS-ui-design.md` và đề xuất `docs/09-journey-sharing.md` đã bị code V2/migrations vượt qua | `docs/07-SDS-ui-design.md` | **chắc chắn** | **cần xác nhận** |
| S7 | `docs/SRS.md` chưa cập nhật theo các đợt mở rộng tính năng và đổi tên V2 | `docs/SRS.md` | **chắc chắn** | **an toàn** |
| S8 | `docs/contracts/schema.md` bỏ sót toàn bộ thay đổi database từ migration `0007` đến `0012` | `docs/contracts/schema.md` | **chắc chắn** | **an toàn** |
| S9 | Nhật ký lỗi và đối chiếu nhánh tạm `docs/bugs.md` và `docs/figma-parity.md` đã hoàn thành trên `main` | `docs/bugs.md` | **chắc chắn** | **an toàn** |
| S10 | Cụm tài liệu `docs/design-v2/` còn quy định tên `"Hội"`, đường dẫn máy cá nhân và trạng thái chưa code | `docs/design-v2/README.md` | **chắc chắn** | **cần xác nhận** |
| S11 | Năm file `README.md` mô tả cấu trúc thư mục, route và các file persona đã bị xóa | `README.md` | **chắc chắn** | **an toàn** |
| S12 | Runbook Supabase và tài liệu Android lệch số lượng migration, thứ tự deploy và cấu hình ký release | `docs/runbooks/hosted-supabase.md` | **chắc chắn** | **an toàn** |
| S13 | Hai bản ghi kiến trúc `ADR 0002` và `ADR 0003` không còn phản ánh quyết định đang chạy | `docs/adr/0002-support-email-and-legal-text.md` | **chắc chắn** | **an toàn** |
| S14 | Thư mục `apps/mobile/assets/logo_options/` chứa 26 phương án logo thử nghiệm không được chọn | `apps/mobile/assets/logo_options/` | **chắc chắn** | **an toàn** |
| S15 | Icon launcher Android/iOS và ảnh splash native vẫn là hình mặc định của template Flutter | `apps/mobile/android/app/src/main/res/mipmap-{mdpi,hdpi,xhdpi,xxhdpi,xxxhdpi}/ic_launcher.png` | **chắc chắn** | **rủi ro** |
| S16 | Bản sao `apps/mobile/assets/design_personas/` (3,69 MB) trùng hệt `docs/assets/design_personas/` và không được app đọc | `apps/mobile/assets/design_personas/persona_{1..6}_*.jpg` | **chắc chắn** | **cần xác nhận** |
| S17 | Mã nguồn prototype cũ `design/figma-v1/` đã bị thay bằng `design/ourney-v2-app/` | `design/figma-v1/App.tsx` | **chắc chắn** | **an toàn** |
| S18 | File `design/ourney-v2-app/public/favicon.svg` dư thừa từ khung xuất Figma Make | `design/ourney-v2-app/public/favicon.svg` | **chắc chắn** | **an toàn** |
| S19 | Sáu thư mục con `apps/mobile/lib/personas/<persona>/l10n/` (30 file) không còn màn hình nào sử dụng | `apps/mobile/lib/personas/{accountability_squad,aesthetic_flexer,couple_rituals,memory_collectors,minimalist_habit,quiet_transformer}/l10n/` | **chắc chắn** | **an toàn** |
| S20 | Widget lịch chuỗi V1 `journey_chain.dart` không còn được import ở bất kỳ đâu | `apps/mobile/lib/features/journeys/ui/journey_chain.dart` | **chắc chắn** | **an toàn** |
| S21 | Ba thành phần giao diện (`today_sheet.dart`, `inbox_button.dart`, `ui/components/reaction_bar.dart`) chỉ còn được test gọi | `apps/mobile/lib/features/journeys/ui/today_sheet.dart` | **chắc chắn** | **cần xác nhận** |
| S22 | Các helper bố cục, màu sắc và kiểu chữ thế hệ đầu trong `lib/shared/` và `lib/app/theme/` không còn được `lib/` dùng | `apps/mobile/lib/shared/layout.dart` | **chắc chắn** | **an toàn** |
| S23 | Màn tạo nhanh V1 `CreateJourneyScreen` (738 dòng) còn nằm cạnh luồng V2 `CreateFlowScreen` | `apps/mobile/lib/features/journeys/ui/create_journey_screen.dart` | **khá chắc** | **rủi ro** |
| S24 | Màn hình V1 `RetellScreen` (`/retell`) trùng chức năng với màn hình V2 `ImportFlowScreen` (`/import`) | `apps/mobile/lib/features/sharing/ui/retell_screen.dart` | **khá chắc** | **cần xác nhận** |
| S25 | Đường dẫn shader `LiquidGlassWidgets` bị tắt (`liquid = false`) nhưng vẫn khởi tạo mỗi khi mở app | `apps/mobile/lib/main.dart` | **khá chắc** | **cần xác nhận** |
| S26 | Mười bảy tham số `IconData?` đánh dấu `@Deprecated` còn giữ trong `lib/ui/components/` | `apps/mobile/lib/ui/components/bars.dart` | **chắc chắn** | **an toàn** |
| S27 | Trường `designAssetPath` và hàm `designAssetForPersona` trong `packages/ourney_core` không còn nơi gọi | `packages/ourney_core/lib/src/templates.dart` | **chắc chắn** | **an toàn** |
| S28 | 172 key l10n không được gọi ở đâu và 9 key chỉ được test gọi trên 20 bộ file `.arb` | `.arb` | **chắc chắn** | **an toàn** |
| S29 | Chú thích cũ và các ca test chỉ giữ cho code không còn dùng trong `apps/mobile/test/` | `apps/mobile/test/shared/ourney_dock_test.dart` | **chắc chắn** | **an toàn** |
| S30 | Script và workflow triển khai Supabase còn giữ giá trị mặc định domain GitHub Pages cũ | `scripts/supabase/deploy-hosted.sh` | **chắc chắn** | **cần xác nhận** |
| S31 | Năm runtime dependencies trong `apps/mobile/pubspec.yaml` không được bất kỳ file nào import | `apps/mobile/pubspec.yaml` | **chắc chắn** | **an toàn** |
| S32 | Bốn `dev_dependencies` trong `apps/mobile/pubspec.yaml` không dùng hoặc chưa cấu hình | `apps/mobile/pubspec.yaml` | **chắc chắn** | **an toàn** |
| S33 | Workflow giữ chỗ `main-guard.yml`, bước `l10n.yaml` không bao giờ chạy và cấu hình ký Android debug trong release | `.github/workflows/main-guard.yml` | **chắc chắn** | **cần xác nhận** |
| S34 | Cấu hình `cubic.yaml` chứa pattern không tồn tại và `ourney_core/pubspec.yaml` lệch ràng buộc SDK | `cubic.yaml` | **chắc chắn** | **an toàn** |

#### S1. Luật và skill UI cũ đang bật tự động trong `.agent/`

- **Đường dẫn:** `.agent/rules/adaptive-persona-ui.md` (dòng 1–164, frontmatter `trigger: always_on`), `.agent/skills/ourney-adaptive-persona-ui/SKILL.md` (dòng 1–48).
- **Cái gì đã lỗi thời:** Cả hai tài liệu bắt buộc mọi agent dùng kiến trúc đã bị xóa bỏ hoàn toàn: `OurneyPersonaTheme.of(context)` (`persona_theme.dart`), dock 3 tab cao 68pt (`Journeys · Snap · Squad`), cho phép dùng `Icons`/`CupertinoIcons` và emoji làm huy hiệu, nút `OurneyPrimaryButton` co tỷ lệ `0.96`, `TemplateId.couple`, `JourneysScreen`, và `CreateJourneyScreen` (`selectTemplate`). Do đặt `trigger: always_on`, luật này đang trực tiếp mâu thuẫn với Design V2 trong code hiện tại.
- **Bằng chứng:** - `git grep -n OurneyPersonaTheme` và `git grep -n OurneyPrimaryButton` không còn bất kỳ kết quả nào trong `apps/mobile/lib/`.
- **Đề xuất xử lý:** **Sửa** lại toàn bộ theo quy ước V2 hiện hành (token `context.ui` / `UiSkinScope`, dock 5 tab tên tiếng Việt `"Nhóm"`, cấm default icon/emoji, luồng `CreateFlowScreen`), hoặc xóa hai file này và gom một nguồn duy nhất về `CLAUDE.md`.
- **Rủi ro khi xử lý:** **an toàn**
- **Độ chắc:** **chắc chắn**

#### S2. `CLAUDE.md` ở gốc repo còn giữ thông tin trước khi hoàn tất Design V2

- **Đường dẫn:** `CLAUDE.md` (dòng 9, 12, 21, 26, 52, 60–62).
- **Cái gì đã lỗi thời:** Dòng 12 ghi bộ icon Ourney chưa được port sang Flutter; dòng 9 gọi `lib/ui/` là V1.0 UI kit từ `design/figma-v1/`; dòng 21 và 26 còn nhắc `pTheme.primaryAccent`, `pTheme.cardRadius`, `pTheme.bottomLipHeight`; dòng 52 ghi `TemplateId` của `coupleRituals` là `couple`; dòng 60–62 nhắc tên màn hình cũ `JourneysScreen` và `CreateJourneyScreen` đọc ảnh từ `assets/design_personas/`.
- **Bằng chứng:** - Bộ 56 icon đã port xong tại `apps/mobile/lib/ui/components/ourney_icons.dart` (commit `28f9e57`, `767d7f6`).
- **Đề xuất xử lý:** **Sửa** dòng 9, 12 (trỏ sang `ourney_icons.dart` và `design/ourney-v2-app/`), thay `pTheme.*` ở dòng 21, 26 bằng `context.ui` / `UiSkin`, sửa cột `TemplateId` của `coupleRituals` ở dòng 52 thành `custom (couple)`, cập nhật dòng 60–62 sang `JourneysListScreen` và `CreateFlowScreen`, đồng thời ghi rõ thuật ngữ tiếng Việt `"Nhóm"` (commit `2af3610`).
- **Rủi ro khi xử lý:** **an toàn**
- **Độ chắc:** **chắc chắn**

#### S3. Các skill trong `.claude/skills/` trỏ tới file đã xóa và bảng việc `docs/TASKS.md` cũ

- **Đường dẫn:** `.claude/skills/design-ref/SKILL.md` (dòng 3, 11, 13, 26, 32–48), `.claude/skills/README.md` (dòng 3, 9, 43), `.claude/skills/{recall,pr-check,wrap-up,lesson}/SKILL.md` và `scripts/context.sh`.
- **Cái gì đã lỗi thời:** `design-ref/SKILL.md` trỏ tới `apps/mobile/lib/app/theme/persona_theme.dart` (đã xóa ở `02ec160`), `OurneyPersonaTheme.of(context)`, `.agent/rules/adaptive-persona-ui.md` và dock 3 tab; `README.md` cùng các skill nhắc thư mục `.claude/rules/` (không tồn tại) và gói `mocktail` (không dùng); các script `context.sh` vẫn dò mã việc `F1/Q1/Z1` trong `docs/TASKS.md` từ đợt tháng 10/2026.
- **Bằng chứng:** - `ls .claude` chỉ có `hooks/`, `settings.json`, `skills/` (không có `.claude/rules/`).
- **Đề xuất xử lý:** **Sửa** `design-ref/SKILL.md` để trỏ sang `apps/mobile/lib/ui/skins.dart`, `design/ourney-v2-app/` và `docs/assets/design_personas/`; bỏ tham chiếu `.claude/rules/` và `docs/TASKS.md` khỏi `README.md` cùng các `context.sh`.
- **Rủi ro khi xử lý:** **an toàn**
- **Độ chắc:** **chắc chắn**

#### S4. Bảng phân việc cũ `docs/TASKS.md` và bộ câu hỏi khách hàng `docs/client-questions.md`

- **Đường dẫn:** `docs/TASKS.md` (dòng 1–167), `docs/client-questions.md` (dòng 1–541).
- **Cái gì đã lỗi thời:** `docs/TASKS.md` chia việc xây `lib/personas/<persona>/{timeline,camera_hud,share_card}.dart`, `OurneyPersonaTheme`, `PersonaPill`, dock 3 tab và chứa link gãy tới `features/journeys/ui/timeline_grid.dart` (dòng 103) — toàn bộ kiến trúc này đã bị thay thế ở `02ec160` và các PR V2. `docs/client-questions.md` liệt kê 101 câu hỏi phỏng vấn khách hàng chưa điền câu trả lời từ ngày 22/10/2026, trong khi quyết định sản phẩm đã chốt xong trong SRS và V2.
- **Bằng chứng:** - `git ls-files apps/mobile/lib/personas` xác nhận không còn file `timeline.dart`, `camera_hud.dart`, `share_card.dart` nào; `features/journeys/ui/timeline_grid.dart` không tồn tại.
- **Đề xuất xử lý:** **Chuyển vào archive** (`docs/archive/TASKS-persona-v1.md` và `docs/archive/client-questions-2026-10.md`).
- **Rủi ro khi xử lý:** **an toàn**
- **Độ chắc:** **chắc chắn**

#### S5. Chuỗi tài liệu phân tích, kế hoạch và review giai đoạn đầu (`docs/01` đến `06`, `07-review`, `08-review`)

- **Đường dẫn:** `docs/01-analysis.md` (dòng 1–260), `docs/02-requirements-v2.md` (dòng 1–285), `docs/03-design-system.md` (dòng 1–278), `docs/04-implementation-plan-v1.md` (dòng 37, 57, 105, 154, 160), `docs/05-platform-plan-ios-android.md` (dòng 19, 58–59, 95–130), `docs/06-adaptive-persona-ui-system.md` (dòng 1–215), `docs/07-product-ux-and-persona-architecture-review.md` (dòng 16–40), `docs/08-SDS-review.md` (dòng 1–675).
- **Cái gì đã lỗi thời:** `01`–`03` mô tả bản SwiftUI + xtool + GRDB, domain cũ `journey.tech`, tối đa 3 hành trình, 1 ảnh/ngày và dock 3 mục; `04`–`05` là kế hoạch Wave A–D với checklist `[ ]` chưa đánh dấu và trỏ tới các đường dẫn không tồn tại (`docs/SPEC.md`, `docs/TRACE.md`, `docs/spikes/`, `builder.json`, `web/`, `scripts/android/`); `06` và `07-product-ux...` dựa trên `OurneyPersonaThemeExtension` cùng hàng loạt link gãy tới file đã xóa (`ourney_dock.dart`, `persona_switchers.dart`, `persona_placeholder.dart`, `persona_registry.dart`, `template_icons.dart`, `quiet_transformer/timeline.dart`); `08-SDS-review.md` là biên bản góp ý bản nháp SDS v0.2.
- **Bằng chứng:** - Đối chiếu `git ls-files`: tất cả các file được link ở `04` dòng 105/154, `05` dòng 19, và `07-product-ux...` dòng 16–40 đều không tồn tại trong repo.
- **Đề xuất xử lý:** **Chuyển vào archive** (`docs/archive/`) cả 8 tài liệu lịch sử này để tránh mâu thuẫn với code V2 và không còn link gãy trong `docs/`.
- **Rủi ro khi xử lý:** **an toàn**
- **Độ chắc:** **chắc chắn**

#### S6. Đặc tả `docs/07-SDS-ui-design.md` và đề xuất `docs/09-journey-sharing.md` đã bị code V2/migrations vượt qua

- **Đường dẫn:** `docs/07-SDS-ui-design.md` (dòng 14, 70, 280, 366, 636–945), `docs/09-journey-sharing.md` (dòng 3, 133).
- **Cái gì đã lỗi thời:** `07-SDS-ui-design.md` đặc tả 10 phong cách (thêm Glow Ritual, Little Milestones, Paw Growth, Blueprint Makeover), màn hỏi ngày sinh SCR-03, dock 3 mục CMP-01 và tiếng Anh làm ngôn ngữ gốc — trái ngược với sản phẩm hiện tại (6 phong cách, không thu ngày sinh, dock 5 tab, tiếng Việt gốc). `09-journey-sharing.md` vẫn ghi ở dòng 3 và 133 là `"Đề xuất — chờ thiết kế và PR contract dữ liệu"`, `"Chưa có trong supabase/migrations"`, dù tính năng đã lên code và database.
- **Bằng chứng:** - `supabase/migrations/0006_social.sql` và `docs/contracts/sharing.md` đã hiện thực hóa đầy đủ schema chia sẻ hành trình, bạn bè, chat 1-1 và `SharedJourneyScreen`.
- **Đề xuất xử lý:** **Chuyển vào archive** cả hai file (vì phần thiết kế giao diện nay theo `docs/design-v2/` + `design/ourney-v2-app/`, còn hợp đồng chia sẻ đã chuẩn hóa tại `docs/contracts/sharing.md`), hoặc giữ `07-SDS` kèm cảnh báo rõ ở đầu file về các mục đã bị V2 thay thế.
- **Rủi ro khi xử lý:** **cần xác nhận**
- **Độ chắc:** **chắc chắn**

#### S7. `docs/SRS.md` chưa cập nhật theo các đợt mở rộng tính năng và đổi tên V2

- **Đường dẫn:** `docs/SRS.md` (dòng 3, 68, 72, 89, 131, 201, 204, 241, 256).
- **Cái gì đã lỗi thời:** Dòng 3 và 256 vẫn đặt mục tiêu `v0.1.0` (trong khi `pubspec.yaml` đã lên `1.0.0+1`); dòng 68 trỏ `docs/TRACE.md` không tồn tại; dòng 72 (FR-A1) chỉ ghi đăng nhập email OTP (thiếu SĐT OTP và email/mật khẩu); dòng 89 (FR-B8) còn gọi `"Hội"`; dòng 131 (FR-E1) ghi `"Share card 1 theme"`; dòng 201 liệt kê `confetti` (không dùng); dòng 204 trỏ `03-design-system.md`; dòng 241 ghi `"merge vào main → workflow ios"` (thực tế `ios.yml` chỉ chạy theo tag `v*` hoặc chạy tay).
- **Bằng chứng:** - Đăng nhập SĐT + mật khẩu đã thêm ở `apps/mobile/lib/features/auth/auth_screen.dart` (`2937d31`); 6 mẫu thiệp theo skin đã có ở `apps/mobile/lib/features/share_card/ui/share_skin_chrome.dart` (`830c249`); tên `"Nhóm"` cập nhật ở `2af3610`; `.github/workflows/ios.yml:3-6` chỉ lắng nghe `push.tags: ['v*']` và `workflow_dispatch`.
- **Đề xuất xử lý:** **Sửa** các dòng nêu trên trong `docs/SRS.md` để khớp với phiên bản `1.0.0`, bộ phương thức đăng nhập mới, 6 skin share card, tên `"Nhóm"`, xóa tham chiếu `docs/TRACE.md` và cập nhật đúng điều kiện chạy `ios.yml`.
- **Rủi ro khi xử lý:** **an toàn**
- **Độ chắc:** **chắc chắn**

#### S8. `docs/contracts/schema.md` bỏ sót toàn bộ thay đổi database từ migration `0007` đến `0012`

- **Đường dẫn:** `docs/contracts/schema.md` (dòng 1–5, 59–135, 244).
- **Cái gì đã lỗi thời:** Tài liệu dừng ở `v1.3` (`0001..0006`) cộng một ghi chú vá cho `0013`/`0014`, nên dòng 97–99 vẫn khẳng định sai rằng `"invites — not a table ... No invite rows, no expiry"`, dòng 244 ghi cột `skin` chỉ là `"Pending change (prototype only)"`, và thiếu hàng loạt bảng/cột/RPC đang chạy thật trên Supabase.
- **Bằng chứng:** - Đối chiếu `supabase/migrations/0007_v2_parity.sql` đến `0012_journey_edit_and_wrapped.sql` (các commit `2937d31`, `ab9e974`, `1747226`): đã thêm bảng `group_invites` và các RPC mời nhóm (`0008`, `0010`), `profiles.onboarding_quiz` + `profile_stats()` (`0009`), `journeys.{couple_self_name,couple_partner_name,layout,cover,color,reminder_time,dna}` + `update_journey` (`0007`, `0012`), `memberships.{hide_extras,pinned}` (`0011`), `check_ins.{extras,partner_photo_path}` (`0007`, `0011`).
- **Đề xuất xử lý:** **Sửa** nâng `docs/contracts/schema.md` lên khớp đủ 14 migration (`0001`–`0014`), bổ sung bảng `group_invites`, các cột mới trên `profiles`/`journeys`/`memberships`/`check_ins` và danh mục RPC mới.
- **Rủi ro khi xử lý:** **an toàn**
- **Độ chắc:** **chắc chắn**

#### S9. Nhật ký lỗi và đối chiếu nhánh tạm `docs/bugs.md` và `docs/figma-parity.md` đã hoàn thành trên `main`

- **Đường dẫn:** `docs/bugs.md` (dòng 4–5, 11–24), `docs/figma-parity.md` (dòng 1–169).
- **Cái gì đã lỗi thời:** `docs/bugs.md` vẫn ghi cả 12 bug ở trạng thái `fixed (local)` trên nhánh `fix/device-bugs-2026-11-15, not merged`; `docs/figma-parity.md` đánh giá nhánh `ui/v2-13-flow-screens` và liệt kê `MISSING` / `V1-STALE` / `IN PROGRESS` cho Settings, Edit Journey, Wrapped, Import, Missed-day/Reminder overlays, 6 skin share cards, DNA questions và Squad wall — tất cả đều đã được code và gộp vào `main`.
- **Bằng chứng:** - `git log --oneline -n 15`: các commit `830c249`, `85806ed`, `1747226` (#54), `01893ec` (#55), `0e67119` (#56) và `2af3610` (#57) đã đưa toàn bộ các hạng mục trên vào `main`.
- **Đề xuất xử lý:** **Chuyển vào archive** (`docs/archive/`) cả hai báo cáo theo dõi ngắn hạn này, hoặc cập nhật trạng thái thành `merged` trong `bugs.md` nếu muốn giữ sổ theo dõi lỗi.
- **Rủi ro khi xử lý:** **an toàn**
- **Độ chắc:** **chắc chắn**

#### S10. Cụm tài liệu `docs/design-v2/` còn quy định tên `"Hội"`, đường dẫn máy cá nhân và trạng thái chưa code

- **Đường dẫn:** `docs/design-v2/README.md` (dòng 3, 13, 23, 27, 31, 72, 102), `docs/design-v2/orchestration/brief.md` (dòng 9, 50), `docs/design-v2/orchestration/f-rules.md` (dòng 18), `docs/design-v2/figma-make-prompts.md` (dòng 51–165), `docs/design-v2/HANDOFF.md` (dòng 1–95), `docs/design-v2/bugs.md` (dòng 1–90), `docs/design-v2/feedback-2026-11-11.md`, `docs/design-v2/compare-v1-v2.md`, `docs/design-v2/improvement-plan.md`.
- **Cái gì đã lỗi thời:** `README.md` và `brief.md` vẫn bắt buộc gọi tính năng nhóm là `"Hội"` (đã đổi sang `"Nhóm"` ở `2af3610`), ghi `"chưa vẽ trên Figma"`, `"Server và app Flutter hiện vẫn chặn 3"` (đã bỏ ở `0013`) và `journey.dna` chưa có trong contract (`0012` đã thêm); `f-rules.md:18` chứa đường dẫn cứng máy cá nhân `D:\DuAnMa\JourneyShared\docs\design-v2\figma-make-prompts.md`; `figma-make-prompts.md` Prompt 0–2 đầu file còn mô tả dock 3 mục và Phosphor icons trước khi bị các prompt cuối file ghi đè; `HANDOFF.md` và `bugs.md` là nhật ký chạy Figma Make.
- **Bằng chứng:** - Commit `2af3610` (`fix(groups): ... vi name Nhóm (#57)`), `01893ec` (migration `0013_unlimited_active_journeys.sql`), `1747226` (migration `0012_journey_edit_and_wrapped.sql`).
- **Đề xuất xử lý:** **Sửa** `docs/design-v2/README.md`, `orchestration/brief.md` (đổi `"Hội"` → `"Nhóm"`, cập nhật trạng thái không giới hạn hành trình và cột `dna`), sửa đường dẫn tương đối ở `orchestration/f-rules.md:18`; đồng thời chuyển các nhật ký quá trình (`HANDOFF.md`, `bugs.md`, `feedback-2026-11-11.md`) vào `docs/archive/`.
- **Rủi ro khi xử lý:** **cần xác nhận**
- **Độ chắc:** **chắc chắn**

#### S11. Năm file `README.md` mô tả cấu trúc thư mục, route và các file persona đã bị xóa

- **Đường dẫn:** `README.md` (dòng 30, 84, 104–116, 180–181, 235), `apps/mobile/README.md` (dòng 20–22), `apps/mobile/lib/features/README.md` (dòng 20–41, 149–203), `apps/mobile/lib/features/journeys/README.md` (dòng 10, 54), `apps/mobile/lib/ui/README.md` (dòng 1, 68, 75, 85).
- **Cái gì đã lỗi thời:** - `README.md` gốc ghi dự án đang ở `v0.1.0` chuẩn bị làm `docs/TASKS.md`, sơ đồ Auth chỉ có email OTP, cây thư mục thiếu `lib/ui/` và `design/`, bảng CI ghi sai rằng `android.yml`/`ios.yml` chạy mỗi khi đẩy lên `main`, và thiếu ADR 0003.
- **Bằng chứng:** - Đối chiếu `apps/mobile/lib/app/router.dart`, `apps/mobile/lib/features/` (13 thư mục feature), `.github/workflows/{android,ios}.yml` và `git ls-files`.
- **Đề xuất xử lý:** **Sửa** đồng bộ cả 5 file `README.md`: cập nhật cây thư mục đủ 13 feature + `lib/ui/`, viết lại mục Personas trong `features/README.md` theo `UiSkinScope` + `persona_contract.dart`, xóa tên các file đã bỏ (`onboarding_art.dart`, `PlaceholderScreen`, `persona_registry.dart`...), và sửa bảng trigger CI ở `README.md` gốc.
- **Rủi ro khi xử lý:** **an toàn**
- **Độ chắc:** **chắc chắn**

#### S12. Runbook Supabase và tài liệu Android lệch số lượng migration, thứ tự deploy và cấu hình ký release

- **Đường dẫn:** `docs/runbooks/hosted-supabase.md` (dòng 68, 83–84, 89, 96), `docs/platform/android.md` (dòng 37, 65, 68, 88).
- **Cái gì đã lỗi thời:** `hosted-supabase.md` ghi chỉ có 5 migration `0001`–`0005` (hiện có 14 file `0001`–`0014`), mô tả bước cập nhật Auth config chạy trước SMTP (đã đảo ngược ở `6d9d427`), và để URL mẫu `https://hofang42.github.io/Ourney/`; `docs/platform/android.md` ghi workflow `android.yml` là `"planned / Pending CI"`, chỉ nêu 2 host deep link `join`/`journey`, và viết rằng `build.gradle.kts` đọc `android/key.properties` (thực tế chưa có).
- **Bằng chứng:** - `ls supabase/migrations` có 14 file từ `0001_init.sql` tới `0014_fix_update_journey_couple_check.sql`; commit `6d9d427` đổi SMTP chạy trước Auth config; `.github/workflows/android.yml` đã tồn tại nhưng `apps/mobile/android/app/build.gradle.kts:38` vẫn gán `signingConfig = signingConfigs.getByName("debug")`.
- **Đề xuất xử lý:** **Sửa** `hosted-supabase.md` thành `0001`–`0014`, đảo đúng thứ tự SMTP → Auth config, đổi URL mẫu sang `https://ourney.tech`; sửa `docs/platform/android.md` cập nhật trạng thái `android.yml`, deep link và phản ánh đúng trạng thái ký release.
- **Rủi ro khi xử lý:** **an toàn**
- **Độ chắc:** **chắc chắn**

#### S13. Hai bản ghi kiến trúc `ADR 0002` và `ADR 0003` không còn phản ánh quyết định đang chạy

- **Đường dẫn:** `docs/adr/0002-support-email-and-legal-text.md` (dòng 3, 18–21, 31–44), `docs/adr/0003-liquid-glass-dock.md` (dòng 3, 10–19).
- **Cái gì đã lỗi thời:** `ADR 0002` vẫn để `Status: Proposed`, dẫn tới mã việc H4/H5 trong `docs/TASKS.md` và mô tả mục `privacy1` chưa bao gồm SĐT, bạn bè, tin nhắn 1-1 hay chia sẻ hành trình. `ADR 0003` ghi `Status: Accepted` với quyết định bọc dock trong `GlassContainer(useOwnLayer)` mặc định, nhưng sau bug #11 code đã tắt hẳn đường dẫn shader này (`liquid = false`).
- **Bằng chứng:** - `apps/mobile/lib/ui/components/dock.dart:81,90-95` đặt `this.liquid = false` với chú thích rõ lý do bỏ shader để giữ viền 2dp + bóng cứng bằng `BackdropFilter`.
- **Đề xuất xử lý:** **Sửa** trạng thái `ADR 0002` (chốt trạng thái + ghi chú cần rà lại `safety_privacy1Body` cho tính năng xã hội/SĐT) và cập nhật `ADR 0003` thành `Superseded` (hoặc bổ sung mục hậu kiểm bug #11 giải thích vì sao mặc định là `liquid: false`).
- **Rủi ro khi xử lý:** **an toàn**
- **Độ chắc:** **chắc chắn**

#### S14. Thư mục `apps/mobile/assets/logo_options/` chứa 26 phương án logo thử nghiệm không được chọn

- **Đường dẫn:** `apps/mobile/assets/logo_options/` (27 file: `README.md`, `ourney_ai_logo_01.jpg` .. `ourney_ai_logo_20.jpg`, `ourney_logo_option_1.jpg` .. `3.jpg`, `ourney_logo_bright_1.jpg` .. `3.jpg`).
- **Cái gì đã lỗi thời:** Toàn bộ 26 ảnh JPG (tạo bằng AI theo phong cách squircle 3D, dải màu cầu vồng, ống kính màn trập, chữ O phát sáng) là các phương án nháp trước khi chốt nhận diện V2 và không phương án nào được chọn đưa vào sản phẩm.
- **Bằng chứng:** - Đã mở xem trực tiếp các ảnh mẫu trong `logo_options/` và so với code thương hiệu hiện tại: splash và header dùng wordmark cắt dán chữ thường `"ourney"` vẽ bằng code (`UiRansomWordmark` tại `lib/ui/components/flow_kit.dart:198` và `UiWordmark` tại `lib/ui/components/brand.dart:10`), còn mục chọn icon trong Cài đặt (`settings-app-icons` tại `lib/features/profile/settings_screen.dart:272-391`) vẽ chữ `'O'` trên 7 ô màu bằng widget.
- **Đề xuất xử lý:** **Xóa** toàn bộ thư mục `apps/mobile/assets/logo_options/` (hoặc chuyển sang kho lưu trữ thiết kế bên ngoài repo code).
- **Rủi ro khi xử lý:** **an toàn**
- **Độ chắc:** **chắc chắn**

#### S15. Icon launcher Android/iOS và ảnh splash native vẫn là hình mặc định của template Flutter

- **Đường dẫn:** `apps/mobile/android/app/src/main/res/mipmap-{mdpi,hdpi,xhdpi,xxhdpi,xxxhdpi}/ic_launcher.png` (5 file), `apps/mobile/ios/Runner/Assets.xcassets/AppIcon.appiconset/*.png` (15 file), `apps/mobile/ios/Runner/Assets.xcassets/LaunchImage.imageset/LaunchImage*.png` (3 file), `apps/mobile/android/app/src/main/res/drawable{,-v21}/launch_background.xml`, `apps/mobile/ios/Runner/Base.lproj/LaunchScreen.storyboard`.
- **Cái gì đã lỗi thời:** Qua mở xem trực tiếp file PNG, cả icon Android (`ic_launcher.png`) lẫn iOS (`Icon-App-1024x1024@1x.png`) vẫn là logo chữ F màu xanh mặc định của `flutter create`, và `LaunchImage@3x.png` là ảnh 1×1 pixel trong suốt giữ chỗ từ lúc khởi tạo dự án.
- **Bằng chứng:** - Đã đọc trực tiếp file ảnh `mipmap-xxxhdpi/ic_launcher.png`, `Icon-App-1024x1024@1x.png`, `LaunchImage@3x.png`.
- **Đề xuất xử lý:** **Sửa** (thay thế bằng bộ icon chữ `"o"` / splash màu giấy kem `#F5F0E6` và tối `#121216` đã chốt của Ourney V2, có thể cấu hình qua `flutter_launcher_icons` và `flutter_native_splash`). **Lưu ý: tuyệt đối không xóa trống các file này** vì hệ thống build Android/Xcode đang tham chiếu trực tiếp.
- **Rủi ro khi xử lý:** **rủi ro**
- **Độ chắc:** **chắc chắn**

#### S16. Bản sao `apps/mobile/assets/design_personas/` (3,69 MB) trùng hệt `docs/assets/design_personas/` và không được app đọc

- **Đường dẫn:** `apps/mobile/assets/design_personas/persona_{1..6}_*.jpg` (6 file, tổng 3.686.490 byte) và dòng khai báo `apps/mobile/pubspec.yaml:97`.
- **Cái gì đã lỗi thời:** Cả 6 bức ảnh tham khảo thiết kế được nhân đôi hoàn toàn giữa `apps/mobile/assets/design_personas/` và `docs/assets/design_personas/`. Trong khi bản ở `docs/assets/` đang được tài liệu hiển thị, bản trong `apps/mobile/assets/` được đóng gói vào APK/IPA nhưng không có bất kỳ đoạn code nào trong ứng dụng tải lên màn hình.
- **Bằng chứng:** - `git ls-files -s apps/mobile/assets/design_personas docs/assets/design_personas` cho kết quả 6 cặp file có mã băm SHA-1 git blob trùng khít 100% (`fd42d170...`, `61173e9e...`, `1731176c...`, `706cc984...`, `daa56803...`, `f6ed1ee4...`); `wc -c` = `3,686,490` byte.
- **Đề xuất xử lý:** **Xóa** thư mục `apps/mobile/assets/design_personas/` và bỏ mục `assets:` tại `apps/mobile/pubspec.yaml:96-97` để giảm ~3,7 MB dung lượng app (giữ nguyên `docs/assets/design_personas/`); đồng thời cập nhật `crop.py:18` trỏ sang `docs/assets/design_personas/` và xóa trường `designAssetPath` ở mục S27.
- **Rủi ro khi xử lý:** **cần xác nhận**
- **Độ chắc:** **chắc chắn**

#### S17. Mã nguồn prototype cũ `design/figma-v1/` đã bị thay bằng `design/ourney-v2-app/`

- **Đường dẫn:** `design/figma-v1/App.tsx`, `design/figma-v1/Sharing.tsx`, `design/figma-v1/index.css`.
- **Cái gì đã lỗi thời:** Đây là bản mẫu React/CSS của Design V1 (dock 3 mục, icon cũ, bố cục cũ) đã bị loại bỏ sau khi dự án chuyển sang `design/ourney-v2-app/` (`docs/design-v2/README.md:4` ghi rõ: *"Bản V1 bị chê, không dùng lại"*).
- **Bằng chứng:** - `git ls-files design` cho thấy prototype hiện hành nằm trọn ở `design/ourney-v2-app/`; không có script build hay test nào chạy `design/figma-v1/`.
- **Đề xuất xử lý:** **Xóa** thư mục `design/figma-v1/` (hoặc chuyển vào `docs/archive/figma-v1/` nếu muốn lưu đối chiếu lịch sử).
- **Rủi ro khi xử lý:** **an toàn**
- **Độ chắc:** **chắc chắn**

#### S18. File `design/ourney-v2-app/public/favicon.svg` dư thừa từ khung xuất Figma Make

- **Đường dẫn:** `design/ourney-v2-app/public/favicon.svg`.
- **Cái gì đã lỗi thời:** Ảnh SVG hình học mặc định sinh ra tự động khi xuất project Vite từ Figma Make, không mang nhận diện Ourney và cũng không được `index.html` hay tài liệu nào gọi tới.
- **Bằng chứng:** - Đã đọc `design/ourney-v2-app/public/favicon.svg` và `design/ourney-v2-app/index.html` (không có thẻ `<link rel="icon">`); `git grep -n favicon` không có kết quả nào trỏ tới file này.
- **Đề xuất xử lý:** **Xóa** `design/ourney-v2-app/public/favicon.svg`.
- **Rủi ro khi xử lý:** **an toàn**
- **Độ chắc:** **chắc chắn**

#### S19. Sáu thư mục con `apps/mobile/lib/personas/<persona>/l10n/` (30 file) không còn màn hình nào sử dụng

- **Đường dẫn:** `apps/mobile/lib/personas/{accountability_squad,aesthetic_flexer,couple_rituals,memory_collectors,minimalist_habit,quiet_transformer}/l10n/` (12 file `.arb` + 18 file `.dart` sinh tự động), cùng đăng ký tại `apps/mobile/lib/app/localization.dart` (dòng 17–22, 49–54) và `apps/mobile/tool/gen_l10n.dart`.
- **Cái gì đã lỗi thời:** Khi xóa các widget persona riêng lẻ ở commit `02ec160`, 6 thư mục con chỉ còn giữ lại phần `l10n/` rỗng vai trò; toàn bộ câu chữ theo từng skin hiện đã chuyển về `journeys_*.arb`, `camera_*.arb`, `checkin_*.arb`, `groups_*.arb` và `share_card_*.arb`. *(Lưu ý: 2 file nằm trực tiếp ở `lib/personas/persona_contract.dart` và `lib/personas/active_journey_sync.dart` vẫn đang được dùng thật, không xóa).*
- **Bằng chứng:** - `git grep -n personas/ apps/mobile` và tìm tên 6 lớp (`QuietTransformerL10n`, `AccountabilitySquadL10n`, `MemoryCollectorsL10n`, `CoupleRitualsL10n`, `AestheticFlexerL10n`, `MinimalistHabitL10n`) xác nhận chỉ xuất hiện trong `lib/app/localization.dart` và `test/app/l10n_test.dart`, 0 lần xuất hiện trong `lib/features/` hay `lib/ui/`.
- **Đề xuất xử lý:** **Xóa** cả 6 thư mục con `apps/mobile/lib/personas/<persona>/`, gỡ 6 delegate khỏi `lib/app/localization.dart`, gỡ quét `lib/personas` trong `tool/gen_l10n.dart` và cập nhật `test/app/l10n_test.dart`.
- **Rủi ro khi xử lý:** **an toàn**
- **Độ chắc:** **chắc chắn**

#### S20. Widget lịch chuỗi V1 `journey_chain.dart` không còn được import ở bất kỳ đâu

- **Đường dẫn:** `apps/mobile/lib/features/journeys/ui/journey_chain.dart` (292 dòng).
- **Cái gì đã lỗi thời:** Lớp `JourneyChain` (lưới lịch 7 cột `.chain-grid` của bản V1.0) đã bị thay thế hoàn toàn bởi `widgets/journey_timeline.dart` và 6 biến thể timeline trong `widgets/timeline_variants.dart`, không còn file nào trong `lib/` lẫn `test/` gọi tới.
- **Bằng chứng:** - `git grep -n journey_chain` chỉ ra tài liệu cũ; `git grep -n JourneyChain` chỉ khớp đúng định nghĩa lớp ở `journey_chain.dart:17-18` (0 import toàn repo).
- **Đề xuất xử lý:** **Xóa** `apps/mobile/lib/features/journeys/ui/journey_chain.dart`.
- **Rủi ro khi xử lý:** **an toàn**
- **Độ chắc:** **chắc chắn**

#### S21. Ba thành phần giao diện (`today_sheet.dart`, `inbox_button.dart`, `ui/components/reaction_bar.dart`) chỉ còn được test gọi

- **Đường dẫn:** `apps/mobile/lib/features/journeys/ui/today_sheet.dart` (246 dòng, kèm `UiProgressRing` ở `lib/ui/components/feedback.dart:221-300`), `apps/mobile/lib/features/social/ui/inbox_button.dart` (59 dòng, re-export tại `lib/features/social/social.dart:6`), `apps/mobile/lib/ui/components/reaction_bar.dart` (150 dòng, export tại `lib/ui/ui.dart:28`).
- **Cái gì đã lỗi thời:** - `showTodaySheet` / `TodaySheetContent` là bottom sheet V1 trên màn Hub cũ (kéo theo `UiProgressRing` chỉ được gọi tại `today_sheet.dart:108`), nay Hub V2 không còn mở sheet này.
- **Bằng chứng:** - `git grep -n showTodaySheet` → chỉ có `today_sheet.dart:18`, `ui/README.md:75`, và `test/features/journeys/journey_hub_ui_test.dart:44,65`.
- **Đề xuất xử lý:** **Xóa** `today_sheet.dart`, `UiProgressRing`, `inbox_button.dart` (kèm dòng export ở `social.dart:6` và các test tương ứng); với `ui/components/reaction_bar.dart` thì xác nhận xem muốn nối vào `features/groups/ui/reaction_bar.dart` hay xóa hẳn khỏi `lib/ui/`.
- **Rủi ro khi xử lý:** **cần xác nhận**
- **Độ chắc:** **chắc chắn**

#### S22. Các helper bố cục, màu sắc và kiểu chữ thế hệ đầu trong `lib/shared/` và `lib/app/theme/` không còn được `lib/` dùng

- **Đường dẫn:** `apps/mobile/lib/shared/layout.dart` (133 dòng), `apps/mobile/lib/shared/color_utils.dart` (28 dòng), `apps/mobile/lib/app/theme/app_theme.dart` (dòng 8–60), `apps/mobile/lib/app/theme/tokens.dart` (dòng 5–12, 16–26).
- **Cái gì đã lỗi thời:** `OurneyLayout` và `OurneyResponsiveBody` (`lib/shared/layout.dart`) đã bị thay bởi `UiSpace` và `UiScaffold` của `lib/ui/`; `readableOn` và `shiftLightness` (`color_utils.dart`), `displayStyle`/`headingStyle`/`eyebrowStyle`/`bigNumberStyle` (`app_theme.dart`) cùng `OurneyCurves` và 7 hằng số trong `OurneyDurations` (`app/theme/tokens.dart`) không còn được bất kỳ file nào gọi; riêng `contrastRatio` và `buildAppTheme` chỉ còn được gọi trong `test/`.
- **Bằng chứng:** - `git grep -n OurneyLayout` / `OurneyResponsiveBody` → chỉ khớp `lib/shared/layout.dart` và `test/shared/layout_test.dart`.
- **Đề xuất xử lý:** **Xóa** `apps/mobile/lib/shared/layout.dart` (và `test/shared/layout_test.dart`), xóa các hàm/hằng chết trong `app_theme.dart` và `app/theme/tokens.dart` (chỉ giữ `OurneyTextScaleClamp` và 2 hằng `OurneyDurations.reducedFade`, `personaTheme`), đồng thời chuyển `contrastRatio` sang helper của `test/app/theme_contrast_test.dart` rồi xóa `lib/shared/color_utils.dart`.
- **Rủi ro khi xử lý:** **an toàn**
- **Độ chắc:** **chắc chắn**

#### S23. Màn tạo nhanh V1 `CreateJourneyScreen` (738 dòng) còn nằm cạnh luồng V2 `CreateFlowScreen`

- **Đường dẫn:** `apps/mobile/lib/features/journeys/ui/create_journey_screen.dart` (738 dòng), `apps/mobile/lib/features/journeys/ui/template_picker_screen.dart` (16 dòng), `apps/mobile/lib/features/journeys/journeys_paths.dart` (dòng 10–15: `newFromTemplate`, `newCoupleRitual`), `apps/mobile/lib/features/journeys/routes.dart` (dòng 35–53).
- **Cái gì đã lỗi thời:** Luồng tạo hành trình chính ở `/journeys/new` nay đã chuyển sang luồng 5 bước V2 `CreateFlowScreen` (`create/create_flow_screen.dart`), khiến `TemplatePickerScreen` chỉ còn là lớp vỏ 1 dòng bọc `CreateFlowScreen`, và hằng `JourneysPaths.newCoupleRitual` không còn ai gọi. Tuy nhiên `CreateJourneyScreen` **chưa thể xóa thẳng ngay lập tức** vì route `/journeys/new/:template` vẫn đang được màn "Làm theo hành trình" (`follow_journey_screen.dart:24`) gọi khi người dùng bấm "Đổi vài thứ".
- **Bằng chứng:** - `git grep -n newCoupleRitual` → chỉ xuất hiện duy nhất tại nơi khai báo `journeys_paths.dart:15` (0 caller).
- **Đề xuất xử lý:** **Gộp** về một luồng duy nhất: cho `CreateFlowScreen` nhận `JourneyFrame` từ `follow_journey_screen.dart`, trỏ route `/journeys/new` trực tiếp vào `CreateFlowScreen` (bỏ lớp bọc `TemplatePickerScreen`), sau đó xóa `create_journey_screen.dart`, `newCoupleRitual`, `newFromTemplate`, route `:template` và `create_journey_test.dart`.
- **Rủi ro khi xử lý:** **rủi ro**
- **Độ chắc:** **khá chắc**

#### S24. Màn hình V1 `RetellScreen` (`/retell`) trùng chức năng với màn hình V2 `ImportFlowScreen` (`/import`)

- **Đường dẫn:** `apps/mobile/lib/features/sharing/ui/retell_screen.dart` (510 dòng), `apps/mobile/lib/features/sharing/routes.dart` (dòng 52), `apps/mobile/lib/app/app_routes.dart` (dòng 59).
- **Cái gì đã lỗi thời:** Cả `RetellScreen` (`/retell`, giao diện 1 trang kiểu V1) và `ImportFlowScreen` (`/import`, giao diện 3 bước Setup → Library → Review của Figma V2) đều thực hiện cùng một nghiệp vụ tạo hành trình quá khứ từ ảnh cũ thông qua `sharingRepositoryProvider.createImported`. Hiện tại bước 1 tạo mới mở `/import`, nhưng menu trên Hub và nút trên Kệ lưu trữ vẫn mở `/retell` cũ.
- **Bằng chứng:** - `git grep -n importJourney` → `type_step.dart:84` điều hướng tới `AppRoutes.importJourney` (`/import`).
- **Đề xuất xử lý:** **Gộp** hai màn hình: đổi 2 điểm gọi ở `journeys_list_screen.dart:439` và `shelf_view.dart:77` sang `AppRoutes.importJourney` (kiểm tra trước xem có cần đem ô nhập metric tùy chọn của `RetellScreen` sang `ImportFlowScreen` hay không), tách `retellPhotoPickerProvider` về `import` rồi xóa `retell_screen.dart` và route `/retell`.
- **Rủi ro khi xử lý:** **cần xác nhận**
- **Độ chắc:** **khá chắc**

#### S25. Đường dẫn shader `LiquidGlassWidgets` bị tắt (`liquid = false`) nhưng vẫn khởi tạo mỗi khi mở app

- **Đường dẫn:** `apps/mobile/lib/main.dart` (dòng 5, 18), `apps/mobile/lib/ui/components/dock.dart` (dòng 7, 81, 85–95, 201–202, 283–289, 327–365), `apps/mobile/pubspec.yaml` (dòng 71).
- **Cái gì đã lỗi thời:** Sau khi test thiết bị phát hiện bug #11 (shader làm mất viền 2dp và bóng cứng của V2), `UiDock` đã đổi mặc định `this.liquid = false` để dùng `UiGlass` (`BackdropFilter`), và không có chỗ nào trong toàn bộ repo truyền `liquid: true`. Tuy nhiên `main.dart:18` vẫn gọi `LiquidGlassWidgets.initialize()` làm ấm shader vô ích ngay lúc khởi động.
- **Bằng chứng:** - `git grep -n liquid:` không có bất kỳ caller nào trong `apps/mobile/`; `git grep -n GlassContainer` chỉ khớp nhánh `useLiquid` ở `dock.dart:284`.
- **Đề xuất xử lý:** Nếu chốt hẳn kính mờ `BackdropFilter` theo V2, **xóa** nhánh `useLiquid` trong `dock.dart`, xóa `LiquidGlassWidgets.initialize` trong `main.dart` và gỡ luôn dependency `liquid_glass_widgets` khỏi `pubspec.yaml`.
- **Rủi ro khi xử lý:** **cần xác nhận**
- **Độ chắc:** **khá chắc**

#### S26. Mười bảy tham số `IconData?` đánh dấu `@Deprecated` còn giữ trong `lib/ui/components/`

- **Đường dẫn:** `apps/mobile/lib/ui/components/bars.dart` (dòng 15), `buttons.dart` (dòng 26, 39, 52, 172), `camera_chrome.dart` (dòng 16, 17, 147), `chips.dart` (dòng 15, 84), `dock.dart` (dòng 36), `feedback.dart` (dòng 14), `person_widgets.dart` (dòng 143, 172), `sheets.dart` (dòng 168, 248), `surfaces.dart` (dòng 382).
- **Cái gì đã lỗi thời:** Các tham số `icon` / `leading` / `trailing` kiểu `IconData?` được giữ tạm trong quá trình di cư sang bộ icon tự vẽ `OurneyIcon` (`glyph:`). Nay 100% màn hình trong `lib/` đã chuyển xong sang `glyph:`, không còn một chỗ nào trong app truyền `IconData`.
- **Bằng chứng:** - `git grep -n Deprecated` liệt kê đúng 17 vị trí trên; `git grep -n IconData apps/mobile/lib` xác nhận ngoài 9 file định nghĩa này không còn file nào trong `lib/` dùng `IconData`.
- **Đề xuất xử lý:** **Xóa** cả 17 tham số/trường `@Deprecated` khỏi 9 file component và đổi các lời gọi trong `test/ui/` + `test/app/accessibility_test.dart` sang `glyph:`.
- **Rủi ro khi xử lý:** **an toàn**
- **Độ chắc:** **chắc chắn**

#### S27. Trường `designAssetPath` và hàm `designAssetForPersona` trong `packages/ourney_core` không còn nơi gọi

- **Đường dẫn:** `packages/ourney_core/lib/src/templates.dart` (dòng 19, 36, 48, 60, 72, 84, 96–105), `packages/ourney_core/test/templates_test.dart`.
- **Cái gì đã lỗi thời:** Thuộc tính `JourneyTemplate.designAssetPath` và hàm `designAssetForPersona` trả về đường dẫn `'assets/design_personas/persona_...jpg'` phục vụ bản preview cũ, hiện không có bất kỳ file nào trong `apps/mobile/` đọc tới.
- **Bằng chứng:** - `git grep -n designAsset` chỉ khớp `packages/ourney_core/lib/src/templates.dart`, `packages/ourney_core/test/templates_test.dart` và tài liệu cũ (0 kết quả trong `apps/mobile/lib/` và `apps/mobile/test/`).
- **Đề xuất xử lý:** **Xóa** `designAssetPath` và `designAssetForPersona` trong `templates.dart` cùng test tương ứng trong `templates_test.dart` (thực hiện đồng thời với mục S16).
- **Rủi ro khi xử lý:** **an toàn**
- **Độ chắc:** **chắc chắn**

#### S28. 172 key l10n không được gọi ở đâu và 9 key chỉ được test gọi trên 20 bộ file `.arb`

- **Đường dẫn:** 16 cặp file `.arb` có key thừa dưới `apps/mobile/lib/l10n/`, `apps/mobile/lib/features/{auth,camera,checkin,groups,journeys,profile,share_card,sharing,social}/l10n/` và `apps/mobile/lib/personas/*/l10n/`. Danh sách đầy đủ từng key xem tại [stale-l10n-keys.md](file:///D:/agent-tasks/reports/stale-l10n-keys.md).
- **Cái gì đã lỗi thời:** Trên tổng số 1.674 key của 20 cặp file `.arb`, có **172 key hoàn toàn không có code hay test nào gọi** (gồm 84 key thuộc 6 bộ persona ở mục S19 và 88 key mồ côi trong các bộ `journeys` [38], `groups` [12], `share_card` [8], `social` [6], `checkin` [5], `profile` [5], `app` [4], `auth` [4], `sharing` [4], `camera` [2]), cùng **9 key chỉ còn xuất hiện trong test** (`camera_title`, `checkin_title`, `onboarding_title` và 6 key của persona). *(Ghi chú kiểm chứng: 27 tên liệt kê ở mục "Chỉ có ở vi" cuối file `stale-l10n-keys.md` như `active`, `caption`, `code`... thực chất là tên biến bên trong khối metadata `@key.placeholders` của file `*_vi.arb`, không phải key dịch bị lệch — `test/app/l10n_test.dart:83` đã đảm bảo tập key dịch gốc giữa `vi` và `en` khớp nhau 100%).*
- **Bằng chứng:** - Đã chạy `git grep -n` kiểm chứng mẫu trực tiếp trên repo cho các key đại diện: `groups_createGroup`, `journeys_personaPreviewLabel`, `share_card_sizeStory`, `quiet_transformer_vaultPill`, `auth_codeInvalidFormat`, `social_inboxEmpty`, `common_ok`, `empty_default_title`, `streak_atRisk` — tất cả chỉ xuất hiện trong `.arb` và `l10n/generated/`, 0 lần xuất hiện trong code Dart viết tay.
- **Đề xuất xử lý:** **Xóa** 172 key không dùng (cùng các key persona trong nhóm chỉ test dùng) khỏi cả hai bản `*_vi.arb` và `*_en.arb` theo danh sách tại `reports/stale-l10n-keys.md`, sau đó chạy `dart run tool/gen_l10n.dart` để sinh lại `l10n/generated/`.
- **Rủi ro khi xử lý:** **an toàn**
- **Độ chắc:** **chắc chắn**

#### S29. Chú thích cũ và các ca test chỉ giữ cho code không còn dùng trong `apps/mobile/test/`

- **Đường dẫn:** `apps/mobile/test/shared/ourney_dock_test.dart` (dòng 13–14), `apps/mobile/test/shared/layout_test.dart` (toàn bộ), `apps/mobile/test/app/l10n_test.dart` (dòng 18–23, 62–75, 131–139), `apps/mobile/test/features/journeys/journey_hub_ui_test.dart` (dòng 40–75), `apps/mobile/test/features/social/inbox_test.dart` (dòng 349–388).
- **Cái gì đã lỗi thời:** `ourney_dock_test.dart:13-14` vẫn mang doc comment `"The shared 3-tab dock (App.tsx Dock)"` dù các bài test bên dưới đã kiểm dock 5 tab; còn `layout_test.dart` cùng các nhóm test ở 3 file kia chỉ đang kiểm thử các lớp/delegate không còn màn hình nào dùng trong `lib/` (mục S19, S21, S22). *(Đã quét `skip` trên toàn bộ `test/` — không có test nào bị bỏ quên với `skip: true`).*
- **Bằng chứng:** - Đọc trực tiếp `ourney_dock_test.dart` và `l10n_test.dart`; `git grep -n skip apps/mobile/test packages/ourney_core/test supabase/tests` xác nhận 0 test bị `skip`.
- **Đề xuất xử lý:** **Sửa** doc comment ở `ourney_dock_test.dart:13-14` thành dock 5 tab; xóa `test/shared/layout_test.dart` và các ca test của persona l10n / `showTodaySheet` / `InboxButton` khi dọn các mục S19, S21, S22.
- **Rủi ro khi xử lý:** **an toàn**
- **Độ chắc:** **chắc chắn**

#### S30. Script và workflow triển khai Supabase còn giữ giá trị mặc định domain GitHub Pages cũ

- **Đường dẫn:** `scripts/supabase/deploy-hosted.sh` (dòng 7, 79), `.github/workflows/deploy-supabase.yml` (dòng 48).
- **Cái gì đã lỗi thời:** Cả script lẫn GitHub Actions workflow vẫn đặt URL dự phòng mặc định cho `AUTH_SITE_URL` là `https://hofang42.github.io/Ourney/` thay vì domain chính thức `https://ourney.tech` (đã chuyển ở `d54af01`); ngoài ra dòng 7 của `deploy-hosted.sh` còn ghi comment thứ tự bước 3–4 ngược với code thật bên dưới sau bản vá `6d9d427`.
- **Bằng chứng:** - Đọc trực tiếp `scripts/supabase/deploy-hosted.sh:7,79` và `.github/workflows/deploy-supabase.yml:48`; đối chiếu commit `d54af01` (`chore: move public domain to ourney.tech`) và `6d9d427` (`fix(deploy): apply custom SMTP before the email templates`).
- **Đề xuất xử lý:** **Sửa** giá trị mặc định `AUTH_SITE_URL` ở cả hai file thành `https://ourney.tech` (sau khi xác nhận biến môi trường trên GitHub) và sửa lại dòng comment thứ tự ở đầu `deploy-hosted.sh`.
- **Rủi ro khi xử lý:** **cần xác nhận**
- **Độ chắc:** **chắc chắn**

#### S31. Năm runtime dependencies trong `apps/mobile/pubspec.yaml` không được bất kỳ file nào import

- **Đường dẫn:** `apps/mobile/pubspec.yaml` (dòng 42 `background_downloader`, dòng 64 `confetti`, dòng 67 `collection`, dòng 69 `package_info_plus`, dòng 70 `cupertino_icons`).
- **Cái gì đã lỗi thời:** Năm gói này được khai báo sẵn từ giai đoạn dựng khung ban đầu (`plan 04 §1`), nhưng quá trình phát triển thực tế đã đi hướng khác: đồng bộ ảnh dùng trực tiếp Supabase Storage + Drift outbox, pháo giấy mốc 7/30 ngày tự vẽ bằng widget trong `checkin_success.dart`, và icon mặc định bị cấm bởi `CLAUDE.md`. Việc giữ `background_downloader`, `package_info_plus` và `cupertino_icons` làm kéo thêm native plugin Android/iOS cùng font `CupertinoIcons.ttf` không cần thiết vào bản cài.
- **Bằng chứng:** - Chạy `git grep -n` cho từng gói (`background_downloader`, `confetti`, `collection`, `package_info_plus`, `cupertino_icons`) trên toàn bộ `apps/mobile/lib` và `apps/mobile/test`: cả 5 gói đều có **0 lệnh `import`**.
- **Đề xuất xử lý:** **Xóa** cả 5 dòng dependency này khỏi `apps/mobile/pubspec.yaml` và chạy lại `flutter pub get` để làm sạch `pubspec.lock` cùng plugin registrant trên Android/iOS.
- **Rủi ro khi xử lý:** **an toàn**
- **Độ chắc:** **chắc chắn**

#### S32. Bốn `dev_dependencies` trong `apps/mobile/pubspec.yaml` không dùng hoặc chưa cấu hình

- **Đường dẫn:** `apps/mobile/pubspec.yaml` (dòng 76–77 `integration_test`, dòng 84 `mocktail`, dòng 86 `flutter_launcher_icons`, dòng 87 `flutter_native_splash`).
- **Cái gì đã lỗi thời:** Repo không có thư mục `apps/mobile/integration_test/` và không có bất kỳ test nào import `integration_test` hay `mocktail` (toàn bộ test đều dùng fake viết tay `*_fakes.dart`); hai công cụ `flutter_launcher_icons` và `flutter_native_splash` được thêm vào nhưng chưa từng có khối cấu hình hay được chạy lần nào.
- **Bằng chứng:** - `git grep -n integration_test`, `git grep -n mocktail`, `git grep -n flutter_launcher_icons`, `git grep -n flutter_native_splash` đều xác nhận 0 lần import và 0 khối cấu hình trong `apps/mobile/`.
- **Đề xuất xử lý:** **Xóa** `integration_test` và `mocktail` khỏi `dev_dependencies`; với `flutter_launcher_icons` và `flutter_native_splash`, hoặc bổ sung cấu hình để sinh bộ icon/splash thật cho mục S15, hoặc xóa nếu tạo asset bằng công cụ ngoài.
- **Rủi ro khi xử lý:** **an toàn**
- **Độ chắc:** **chắc chắn**

#### S33. Workflow giữ chỗ `main-guard.yml`, bước `l10n.yaml` không bao giờ chạy và cấu hình ký Android debug trong release

- **Đường dẫn:** `.github/workflows/main-guard.yml` (dòng 1–23), `.github/workflows/android.yml` (dòng 38, 41–54), `.github/workflows/ios.yml` (dòng 41), `apps/mobile/android/app/build.gradle.kts` (dòng 35–39).
- **Cái gì đã lỗi thời:** - `main-guard.yml` là workflow giữ chỗ từ mô hình nhánh `develop` cũ (bên trong chỉ `echo "Branch flow: ..."` để giữ đèn xanh nếu ruleset cũ bật lại).
- **Bằng chứng:** - Đọc trực tiếp `main-guard.yml`, `android.yml`, `ios.yml`, `apps/mobile/pubspec.yaml:91-93` và `apps/mobile/android/app/build.gradle.kts:34-40`; `git grep -n TODO` khớp đúng dòng 36 của `build.gradle.kts`.
- **Đề xuất xử lý:** **Sửa** `build.gradle.kts` để đọc `key.properties` khi có mặt (fallback về `debug` khi chạy máy local), đổi bước `l10n.yaml` trong `android.yml`/`ios.yml` thành `dart run tool/gen_l10n.dart` (hoặc bỏ hẳn vì `ci.yml` đã kiểm), và xóa `main-guard.yml` sau khi kiểm tra Branch Ruleset trên GitHub không còn yêu cầu check `source-branch`.
- **Rủi ro khi xử lý:** **cần xác nhận**
- **Độ chắc:** **chắc chắn**

#### S34. Cấu hình `cubic.yaml` chứa pattern không tồn tại và `ourney_core/pubspec.yaml` lệch ràng buộc SDK

- **Đường dẫn:** `cubic.yaml` (dòng 17, 21–22, 33), `packages/ourney_core/pubspec.yaml` (dòng 3, 7).
- **Cái gì đã lỗi thời:** `cubic.yaml` khai báo bỏ qua `**/*.freezed.dart` và `apps/mobile/dist/` (repo không dùng `freezed` và không có thư mục `dist/`, trong khi lại thiếu pattern bỏ qua `apps/mobile/lib/**/l10n/generated/**`), đồng thời nạp `CLAUDE.md` đang chứa thông tin cũ (mục S2). Bên cạnh đó, `packages/ourney_core/pubspec.yaml` giữ nguyên `sdk: ^3.5.0` và `version: 0.1.0` từ ngày dựng khung, lệch với `sdk: ^3.13.5` và `version: 1.0.0+1` của `apps/mobile/pubspec.yaml`.
- **Bằng chứng:** - `git ls-files` xác nhận 0 file `*.freezed.dart` và không có `apps/mobile/dist/`.
- **Đề xuất xử lý:** **Sửa** danh sách `ignore` trong `cubic.yaml` (bỏ `**/*.freezed.dart` và `apps/mobile/dist/`, thêm `apps/mobile/lib/**/l10n/generated/**`) và nâng `sdk` trong `packages/ourney_core/pubspec.yaml` đồng bộ với workspace.
- **Rủi ro khi xử lý:** **an toàn**
- **Độ chắc:** **chắc chắn**

## 5. Worker ngoài repo Ourney

### 5.1. `impl-fr`: màn "Đề xuất tính năng"

Worker làm ở bản clone `Ourney-fr`, branch `feat/feature-request`. Review `review-fr` (`claude-opus-4-6-thinking`) kết luận ĐẠT, không có lỗi logic hay bảo mật.

| Mục | Nội dung |
| --- | --- |
| 1 | Migration `supabase/migrations/0015_feature_requests.sql`, tạo bảng `public.feature_requests` |
| 2 | Test pgTAP `supabase/tests/15_feature_requests.test.sql` |
| 3 | Cập nhật `docs/contracts/schema.md` |
| 4 | Data layer phía app |
| 5 | Màn hình và lối vào |
| 6 | Chữ trên giao diện `profile_vi.arb`, `profile_en.arb` |
| 7 | Bổ sung Chính sách quyền riêng tư `safety_vi.arb`, `safety_en.arb` |
| 8 | Test Flutter |

Còn một việc trước khi mở PR: thêm `'feature_requests'` vào `tables_are` ở `supabase/tests/01_rls_enabled.test.sql:6-11`, nếu không thì CI fail. Xem thêm lưu ý thứ tự số `0015` và `0016` ở mục 1.3.

### 5.2. `hoc-tap-uiux-2`: web "Học tập" (CKA, DOP-C02, SOA-C03)

Đây là project khác, làm trên bản sao `D:\hoc-tap-staging`. Báo cáo chỉ có phần danh sách vấn đề, chưa có phần kết quả sửa và dòng `DONE`, nên coi như chưa sửa mục nào.

| # | Mức | Vấn đề | Trạng thái |
| --- | --- | --- | --- |
| 1 | Cao | Chữ tiếng Việt còn dịch sát tiếng Anh, tên gọi không thống nhất, còn sót tên thương hiệu bên thứ ba trên DOP/SOA | Chờ sửa |
| 2 | Cao | Thanh dính che đầu câu hỏi trên màn 390px, mất focus khi đánh dấu câu, thiếu bảng phím tắt `?` ở màn làm bài | Chờ sửa |
| 3 | Cao | Màn 2560px: Lịch lab DOP bị nén 6 cột, CKA và DOP kéo giãn dư khoảng trống | Chờ sửa |
| 4 | Cao | Hộp Trợ giúp, màn báo lỗi, hộp xóa tiến độ còn hướng dẫn cũ, còn vòng xoay tải vô tận | Chờ sửa |
| 5 | Cao | Màn 390px lệch hộp Tài khoản CKA, mất lối đổi ngày thi SOA-C03, thiếu nút lùi bài, bảng phím tắt tràn ngang | Chờ sửa |
| 6 | Cao | Cụm chuyển khóa ở DOP/SOA thiếu mục `CKA`, vài chi tiết chung chưa đồng bộ | Chờ sửa |
| 7 | Vừa | Lịch lab DOP mất khoảng 266 ms lần mở đầu vì parse HTML bằng `<template>` và chạy regex 13.888 lượt | Chờ sửa |
| 8 | Vừa | Màu chữ phụ, viền điều khiển chưa đạt WCAG 2.2 AA, vài vùng bấm nhỏ hơn 24px hoặc 40px | Chờ sửa |
| 9 | Vừa | Trạng thái lỗi và trống khi server tắt ở Tìm kiếm, Thông báo, Ghi chú, Hỏi đáp CKA chưa rõ cách khôi phục | Chờ sửa |
| 10 | Vừa | Phím tắt, điều hướng bàn phím trong menu và dải tab phụ, nhãn đọc màn hình còn thiếu | Chờ sửa |
| 11 | Thấp | Bài đọc CKA thiếu định dạng bảng, giãn dòng khít, gợi ý lab cuối Tuần 5 trỏ sang tuần rỗng | Chờ sửa |
| 12 | Vừa | Nút "Luyện lại câu sai và bỏ trống" ở trang Kết quả DOP giữ nguyên `src` của bộ đề gốc | Không sửa, chờ owner chốt hướng sản phẩm |
| 13 | Thấp | Nút "Trợ lý AI" và `.ai-fab` trên trang chủ CKA chỉ là hình mô phỏng | Không sửa, giữ giao diện hiện tại |
