# Runbook: Supabase hosted + SMTP riêng (H1, H2)

> Chủ: @hofang42. Script: [`scripts/supabase/deploy-hosted.sh`](../../scripts/supabase/deploy-hosted.sh). Workflow: [`deploy-supabase.yml`](../../.github/workflows/deploy-supabase.yml).
> Chỉ cần cho dogfood nhóm. Dev/test hằng ngày vẫn dùng `supabase start` (local, mailpit), xem [TASKS.md](../TASKS.md) §1.

## 1. Tạo project (làm tay, một lần)

1. Vào <https://supabase.com/dashboard> → **New project**. Chọn region gần người dùng (vd. Southeast Asia - Singapore), đặt **Database password** mạnh và lưu vào password manager.
2. Ghi lại:
   - **Project ref**: chuỗi 20 ký tự trong URL dashboard / `https://<ref>.supabase.co`.
   - **Project URL** (`https://<ref>.supabase.co`) và **anon (publishable) key**: *Project Settings → API*. Anon key là public theo thiết kế (RLS bảo vệ dữ liệu), nhưng **không** bao giờ dùng `service_role` key trong app.
3. Tạo **Access token** cá nhân: <https://supabase.com/dashboard/account/tokens> → *Generate new token* (đặt tên `ourney-deploy`). Token chỉ hiện một lần.
4. *Authentication → Providers → Email*: bật Email OTP. (Số mail/giờ do H2 chỉnh, xem mục 3.)

## 2. Secret của GitHub

Dùng **Environment** thay vì repo secret cho phần deploy, để bắt buộc duyệt thủ công.

*Settings → Environments → New environment* tên **`production`**. **Bắt buộc** cấu hình bảo vệ **trước khi** thêm secret (không có thì bất kỳ ai có quyền ghi và chạy được workflow trên branch của mình đều đọc được secret):
- *Required reviewers* = **@hofang42** (bỏ chọn "Prevent self-review" chỉ khi @hofang42 là người duy nhất chạy deploy).
- *Deployment branches and tags* = **Selected branches** → chỉ `main`.

Workflow cũng tự từ chối chạy ngoài `main` (`if: github.ref == 'refs/heads/main'`). Thêm **Environment secrets**:

| Secret | Bắt buộc | Ý nghĩa |
|---|---|---|
| `SUPABASE_ACCESS_TOKEN` | có | Token ở bước 1.3 |
| `SUPABASE_PROJECT_REF` | có | Project ref |
| `SUPABASE_DB_PASSWORD` | có | Database password |
| `SMTP_HOST` | H2 | vd. `smtp.resend.com` |
| `SMTP_USER` | H2 | Resend: `resend` |
| `SMTP_PASS` | H2 | API key của Resend (quyền gửi mail) |
| `SMTP_SENDER_EMAIL` | H2 | vd. `no-reply@<domain-của-bạn>` (phải thuộc domain đã verify) |
| `SMTP_PORT` | không | mặc định `465` |
| `SMTP_SENDER_NAME` | không | mặc định `Ourney` |

Quy tắc SMTP: hoặc đặt đủ 4 biến `SMTP_HOST/USER/PASS/SENDER_EMAIL`, hoặc không đặt biến nào (script báo lỗi nếu chỉ đặt một phần). Không đặt thì deploy giữ nguyên cấu hình SMTP hiện có.

**Repo secret** (*Settings → Secrets and variables → Actions → Repository secrets*) cho app build (workflow `ios.yml`, `android.yml` đọc):

| Secret | Ý nghĩa |
|---|---|
| `SUPABASE_URL` | Project URL |
| `SUPABASE_ANON_KEY` | anon / publishable key |
| `SUPPORT_EMAIL` | *(tuỳ chọn)* email hỗ trợ, xem [ADR 0002](../adr/0002-support-email-and-legal-text.md) |

Không đặt hai secret `SUPABASE_*` thì app build ra ở chế độ **local-only** (không có tab Nhóm).

## 3. SMTP riêng với Resend (H2)

Mail mặc định của Supabase bị giới hạn rất thấp và hay vào spam, nên cần SMTP riêng.

1. Tạo tài khoản <https://resend.com>, *Domains → Add Domain* (nên dùng subdomain, vd. `mail.<domain>`).
2. Thêm các bản ghi DNS Resend đưa ra tại nhà cung cấp DNS:
   - **SPF**: bản ghi `TXT` (Resend tạo trên subdomain `send.<domain>`): `v=spf1 include:amazonses.com ~all`. Chỉ có **một** bản ghi SPF cho mỗi tên; nếu đã có thì gộp `include`.
   - **DKIM**: bản ghi `TXT` `resend._domainkey.<domain>` (giá trị dài do Resend cấp, copy nguyên văn).
   - **MX** cho `send.<domain>` như Resend hướng dẫn (để nhận bounce).
   - **DMARC**: `TXT` `_dmarc.<domain>` giá trị khởi đầu `v=DMARC1; p=none; rua=mailto:<email-của-bạn>`. Sau khi ổn (vài tuần) nâng dần `p=quarantine`.
3. Bấm *Verify* trên Resend, chờ trạng thái **Verified** (vài phút tới vài giờ).
4. *API Keys → Create API key* (quyền *Sending access*, giới hạn theo domain). Dùng làm `SMTP_PASS`. SMTP của Resend: host `smtp.resend.com`, cổng `465`, user `resend`.
5. Đặt các secret SMTP ở mục 2. Script sẽ gọi Management API `PATCH /v1/projects/<ref>/config/auth` với `smtp_host`, `smtp_port`, `smtp_user`, `smtp_pass`, `smtp_admin_email`, `smtp_sender_name` và `rate_limit_email_sent` (mặc định 30 mail/giờ). Mật khẩu không bao giờ được in ra log.

`supabase/config.toml` **không** bật SMTP: CI và `supabase start` vẫn dùng mailpit.

## 4. Chạy deploy

### 4.1 Dry run (an toàn, luôn làm trước)
GitHub → *Actions → Deploy Supabase (hosted) → Run workflow*, giữ `dry_run` = **true**, bấm chạy (duyệt environment nếu được hỏi). Job chỉ chạy `supabase link` và `supabase db push --dry-run`: log liệt kê migration `0001`–`0005` sẽ áp dụng. Không thay đổi gì trên project.

Hoặc chạy trên máy (cần Supabase CLI):

```bash
export SUPABASE_ACCESS_TOKEN=... SUPABASE_PROJECT_REF=... SUPABASE_DB_PASSWORD=...   # không commit
bash scripts/supabase/deploy-hosted.sh --dry-run
```

### 4.2 Deploy thật
Chạy lại workflow với `dry_run` = **false** (hoặc bỏ `--dry-run`). Script lần lượt:

1. `supabase link` rồi `supabase db push` (migration trong `supabase/migrations`).
2. Deploy function `delete-account` (giữ kiểm tra JWT: hàm tự xác thực người gọi và xoá chính người đó).
3. Deploy function `public-journey` với `--no-verify-jwt` (người xem link công khai không đăng nhập; truy cập được chặn bằng `public_token` có thể thu hồi).
4. Cập nhật cấu hình Auth (luôn chạy, xem mục 4.4): email OTP dạng mã 6 số + `site_url`.
5. Nếu có đủ `SMTP_*`: cập nhật SMTP cho Auth.

Chạy lại bao nhiêu lần cũng được (idempotent). Khi gặp lỗi, đọc thông điệp ở log, sửa rồi chạy lại.

### 4.3 Kiểm tra sau deploy
- Dashboard → *Database → Migrations*: thấy đủ 5 migration. *Edge Functions*: thấy 2 hàm. `curl "https://<ref>.supabase.co/functions/v1/public-journey?token=x"` trả `404 {"error":"not_found"}` (không phải 401).
- *Authentication → Emails → SMTP Settings*: đã bật custom SMTP, đúng sender.

### 4.4 Email đăng nhập là mã 6 số (OTP), không phải link
App đăng nhập bằng `signInWithOtp` + `verifyOTP` nên người dùng phải nhận **mã 6 số**. Template email mặc định của Supabase gửi magic link tạo từ Site URL mặc định `http://localhost:3000`, nên mỗi lần deploy thật script tự `PATCH /v1/projects/<ref>/config/auth` với:
- Template `supabase/templates/magic_link.html` và `confirmation.html` (song ngữ Việt/Anh, chỉ hiện `{{ .Token }}`, hiệu lực 60 phút, không có link) cùng tiêu đề lấy từ `supabase/config.toml`; `supabase start` local dùng đúng các template này.
- `mailer_otp_length` = 6, `mailer_otp_exp` = 3600, `mailer_autoconfirm` = true (khớp `enable_confirmations = false` ở local).
- `site_url` và `uri_allow_list` = `AUTH_SITE_URL` (mặc định `https://hofang42.github.io/Ourney/`). Muốn đổi, đặt *Environment variable* (không phải secret) `AUTH_SITE_URL` trong environment `production`; workflow đã truyền biến này cho script.

Áp dụng cho project đang chạy: chỉ cần **chạy lại workflow Deploy Supabase (hosted)** với `dry_run` = false; bước này không cần SMTP và chạy lại nhiều lần vẫn an toàn. Sau đó thử đăng nhập: email phải có mã 6 số, không có link tới localhost.

## 5. Đưa `SUPABASE_URL` / `SUPABASE_ANON_KEY` vào app

1. Đặt repo secret `SUPABASE_URL` và `SUPABASE_ANON_KEY` (mục 2).
2. Chạy lại workflow **iOS (unsigned IPA)** và **Android (APK)** (*Run workflow* trên `main`). Hai workflow ghi `dart-defines.json` từ secret và build với `--dart-define-from-file`.
3. Cài bản mới: vào được tab **Nhóm** là đạt tiêu chí H1.
4. Dev local muốn trỏ hosted: sao chép `apps/mobile/env.example.json` thành `env.json` (đã gitignore), điền hai giá trị, rồi `flutter run --dart-define-from-file=env.json`.

## 6. Nghiệm thu H2 (spike S8)

Mục tiêu: **10/10 mail OTP tới Gmail trong < 30 giây và không vào Spam**.

Quy trình:
1. Dùng một tài khoản Gmail thật, mở trong trình duyệt. Dùng app bản hosted, đăng nhập bằng email đó để gửi OTP.
2. Với mỗi lần: ghi giờ bấm *Gửi mã* (giây), giờ thấy mail trong Gmail (giây), thư mục (Hộp thư đến / Spam / Quảng cáo). Chờ ít nhất 1 phút giữa các lần nếu chạm giới hạn rate limit.
3. Mở một mail → *Show original* → kiểm tra `SPF: PASS`, `DKIM: PASS`, `DMARC: PASS`.
4. Điền bảng và gửi kết quả lên PR/issue.

| # | Giờ bấm gửi | Giờ mail tới | Độ trễ (s) | Thư mục | Ghi chú |
|---|---|---|---|---|---|
| 1 |  |  |  |  |  |
| 2 |  |  |  |  |  |
| 3 |  |  |  |  |  |
| 4 |  |  |  |  |  |
| 5 |  |  |  |  |  |
| 6 |  |  |  |  |  |
| 7 |  |  |  |  |  |
| 8 |  |  |  |  |  |
| 9 |  |  |  |  |  |
| 10 |  |  |  |  |  |

Đạt khi: 10/10 mail có độ trễ < 30 s, cả 10 nằm ở *Hộp thư đến*, và SPF/DKIM/DMARC đều PASS. Nếu rớt: kiểm tra DNS đã verify, dùng domain riêng thay vì domain chung, nâng DMARC dần, giảm nội dung mẫu mail có link rút gọn.

## 7. Xoay khoá
- Lộ `SUPABASE_ACCESS_TOKEN`: thu hồi ở trang token rồi tạo cái mới, cập nhật environment secret.
- Lộ Resend API key: xoá key trên Resend, tạo key mới, cập nhật `SMTP_PASS`, chạy lại deploy (không cần `dry_run`).
- Đổi database password: *Project Settings → Database*, cập nhật `SUPABASE_DB_PASSWORD`.
