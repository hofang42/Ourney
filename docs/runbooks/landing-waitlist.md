# Runbook: danh sách chờ beta của landing page (waitlist)

> Code: migration [`0022_landing_waitlist.sql`](../../supabase/migrations/0022_landing_waitlist.sql), Edge Function [`waitlist-signup`](../../supabase/functions/waitlist-signup/index.ts), form ở [`apps/landing/main.js`](../../apps/landing/main.js) (mục `#beta`). Script cài đặt: [`scripts/supabase/setup-waitlist.ps1`](../../scripts/supabase/setup-waitlist.ps1).

## Luồng hoạt động
1. Người dùng nhập email ở vé beta, chọn iOS/Android, bấm **nhận lời mời**.
2. `main.js` gửi `POST` tới địa chỉ trong `<meta name="ourney-waitlist-endpoint">` của `index.html`.
3. Function `waitlist-signup` kiểm tra Origin (CORS), honeypot, định dạng email, giới hạn 5 lần/giờ cho mỗi IP (chỉ lưu sha256 của IP), rồi gọi RPC `public.waitlist_signup` để ghi vào `private.waitlist`.
4. **Chỉ email mới** nhận mail cảm ơn (gửi qua Resend, tiếng Việt hoặc tiếng Anh theo ngôn ngữ đang xem trên trang). Email đã có trong danh sách vẫn nhận phản hồi 200 nhưng không được gửi lại mail, nên form không bị lợi dụng để spam ai đó.
5. Kết quả gửi mail được ghi vào `confirmation_sent_at` (thành công) hoặc `confirmation_error` (thất bại).

## Xem danh sách
- **Dashboard**: Supabase → project → **Table Editor** → chọn schema **`private`** ở ô schema → bảng **`waitlist`**. Có lọc, sắp xếp và **Export → CSV**.
- **SQL Editor**:
  ```sql
  select email, lang, platforms, created_at, confirmation_sent_at, confirmation_error
    from private.waitlist
   order by created_at desc;
  ```
- Muốn được báo mỗi khi có người đăng ký: đặt secret `WAITLIST_NOTIFY_TO` (xem bên dưới).

Bảng nằm ở schema `private`, bật RLS, không có policy và không cấp quyền cho `anon` hay `authenticated`: app và trình duyệt đều không đọc được, chỉ service role (Function, Dashboard) đọc được.

## Secret của Function
Đặt bằng `supabase secrets set ... --project-ref <ref>` hoặc ở Dashboard → **Edge Functions → Secrets**.

| Secret | Bắt buộc | Ý nghĩa |
|---|---|---|
| `RESEND_API_KEY` | có (để gửi mail) | API key của Resend. Có thể dùng chung key đang làm `SMTP_PASS`. Thiếu key thì email vẫn được lưu, chỉ không gửi mail (`confirmation_error = mail_not_configured`). |
| `WAITLIST_FROM` | có (để gửi mail) | Người gửi, domain phải được verify trên Resend, ví dụ `Ourney <hello@ourney.tech>`. |
| `WAITLIST_REPLY_TO` | không | Địa chỉ nhận khi người dùng bấm Reply. |
| `WAITLIST_NOTIFY_TO` | không | Mail của bạn (có thể nhiều, cách nhau dấu phẩy): nhận một thư ngắn cho mỗi lượt đăng ký mới. |
| `WAITLIST_ALLOWED_ORIGINS` | không | Danh sách Origin được phép, cách nhau dấu phẩy. Mặc định `https://ourney.tech,https://www.ourney.tech`. Thêm domain preview của Cloudflare Pages (`https://<hash>.ourney-landing.pages.dev`) nếu cần thử ở đó. |

> Gói miễn phí của Resend giới hạn khoảng 100 mail/ngày, 3.000 mail/tháng. Mail báo cho `WAITLIST_NOTIFY_TO` cũng tính vào hạn mức này.

## Cài đặt lần đầu
1. **Resend**: verify domain `ourney.tech` (SPF/DKIM) nếu chưa làm cho SMTP, rồi lấy API key.
2. **Endpoint**: trong `apps/landing/index.html`, thay `PROJECT_REF` trong thẻ `ourney-waitlist-endpoint` bằng project ref thật (`https://<ref>.supabase.co/functions/v1/waitlist-signup`). Khi còn `PROJECT_REF`, form chỉ báo "Chưa gửi được".
3. **Database và Function**: merge PR vào `main` rồi chạy workflow **Deploy Supabase (hosted)** (`dry_run` = false). Workflow sẽ áp migration 0022 và deploy `waitlist-signup` với `--no-verify-jwt`. Cách làm tay: chạy `scripts/supabase/setup-waitlist.ps1`.
4. **Secret**: đặt các secret ở bảng trên.
5. **Landing (Cloudflare Pages — `ourney-landing`)**:
   - Tạo project Cloudflare Pages tên **`ourney-landing`** kết nối với repo `Ourney` ([Build configuration](https://developers.cloudflare.com/pages/configuration/build-configuration/)):
     - **Root directory:** `apps/landing`
     - **Build command:** `sh scripts/build-pages.sh`
     - **Build output directory:** `dist`
     - **Build watch paths:** chỉ bao gồm `apps/landing/**` (tương tự `apps/admin/**` cho project `ourney-admin`) để các commit ở phần khác của monorepo không kích hoạt build thừa.
     - **Environment variables:** không cần biến môi trường build-time (endpoint Supabase và anon/publishable key đã nằm trong thẻ `<meta>` của HTML; **tuyệt đối không** thêm `SUPABASE_SERVICE_ROLE_KEY`).
     - **Custom domain & Analytics:** gắn domain chính `ourney.tech` (redirect `www.ourney.tech` → `ourney.tech` trên Cloudflare Dashboard). **Không** bật tính năng tự động chèn Web Analytics của Pages vì mã beacon đã có sẵn trong HTML.
   - Khi build, `scripts/build-pages.sh` đóng gói trang tĩnh cùng [`apps/landing/_headers`](../../apps/landing/_headers) và [`apps/landing/_redirects`](../../apps/landing/_redirects) vào `dist/` (CSP đã cho phép `connect-src 'self' https://*.supabase.co https://cloudflareinsights.com`).
   - **Lưu ý về Vercel legacy:** `apps/landing/vercel.json` và `.vercelignore` là cấu hình cũ (legacy), chỉ giữ lại tạm thời để rollback cho tới khi hoàn tất chuyển DNS sang Cloudflare Pages rồi sẽ được xoá ở task dọn dẹp tiếp theo.
6. **Thử**:
   ```bash
   curl -i -X POST "https://<ref>.supabase.co/functions/v1/waitlist-signup" \
     -H "Origin: https://ourney.tech" -H "Content-Type: application/json" \
     -d '{"email":"ban@example.com","lang":"vi","platforms":["ios","android"],"source":"curl"}'
   ```
   Kết quả mong đợi: `200 {"ok":true}`, có mail cảm ơn, và có một dòng mới trong `private.waitlist`.

## Xử lý sự cố
- **Form báo "Chưa gửi được"**: endpoint còn `PROJECT_REF`, Function chưa deploy, hoặc Origin không có trong `WAITLIST_ALLOWED_ORIGINS` (lỗi 403). Xem *Edge Functions → waitlist-signup → Logs*.
- **Có dòng trong bảng nhưng không có mail**: đọc cột `confirmation_error` (`mail_not_configured`, `resend_403` khi domain chưa verify, `resend_429` khi hết hạn mức).
- **Gửi lại mail cho các dòng lỗi**: hiện làm tay (gửi qua Resend dashboard) hoặc xoá dòng đó để người dùng đăng ký lại.
- **Xoá một email theo yêu cầu**: `delete from private.waitlist where email = 'x@y.z';`
