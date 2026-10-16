# Ourney — Chia việc v0.1.0 (4 người, không block nhau)

> 2026-10-16 · Trạng thái xuất phát: code v1 đủ các yêu cầu P1 trong [SRS.md](SRS.md), CI xanh, đã có `.ipa` chưa ký + `.apk`. Còn thiếu: kiểm chứng trên máy thật, server hosted, trang web, quy trình release.
> Quy trình mỗi việc: branch `feat/<id>-<slug>` → PR (theo template) → reviewer cặp → squash merge vào `main`.

## 1. Nguyên tắc để không ai block ai

| # | Nguy cơ block | Cách gỡ |
|---|---|---|
| 1 | Chờ Supabase hosted (H1) | Mọi người dev/test bằng **Supabase local**: `supabase start` (Docker) dùng chung migration trong repo. Test trên điện thoại thật: trỏ `SUPABASE_URL` vào IP LAN của máy chạy Docker (`env.json`, đã gitignore). Hosted chỉ dùng cho dogfood |
| 2 | Chờ quyết định của owner | Dùng **quyết định mặc định** ở mục 4 ngay từ hôm nay, đổi sau nếu cần |
| 3 | PR chờ review | **Cặp review cố định**, review trong **24h**; quá 24h thì bất kỳ thành viên nào khác được duyệt thay |
| 4 | Bug đẩy qua lại | **Ai tìm ra thì người đó sửa** nếu nằm trong vùng của mình. Ngoài vùng → issue có label `area:*` cho chủ vùng |
| 5 | Release chờ tất cả | Release theo **ngày cố định**. Chỉ bug Blocker/Critical chặn release, việc chưa xong chuyển sang v0.1.1 |
| 6 | Hai người sửa cùng file | Mỗi người sở hữu một **vùng thư mục** (mục 2, khớp với `.github/CODEOWNERS`). Phải sửa ngoài vùng → PR nhỏ, chủ vùng review trong 24h; conflict thì người merge sau rebase |

## 2. Vùng sở hữu & cặp review

| Người | Vùng sở hữu | Reviewer |
|---|---|---|
| @hofang42 | `.github/`, `docs/` (trừ TRACE/spikes), `supabase/config.toml`, release | @nguyenductien-qnm |
| @thydynh03 | `docs/TRACE.md`, `docs/spikes/`, `apps/mobile/lib/features/{camera,checkin,share_card,onboarding,profile,auth}`, `apps/mobile/lib/app`, `apps/mobile/lib/shared` | @lken1514 |
| @lken1514 | `apps/mobile/lib/data/`, `apps/mobile/lib/features/reminders/`, `apps/mobile/android/`, `apps/mobile/ios/` | @thydynh03 |
| @nguyenductien-qnm | `web/`, `supabase/` (migrations, functions, tests), `packages/ourney_core/`, `docs/contracts/`, `apps/mobile/lib/features/{groups,journeys,safety}` | @hofang42 |

## 3. Việc của từng người (cả 4 luồng chạy song song từ ngày 1)

### @hofang42 — owner, server hosted, release
| ID | Việc | Xong khi | Phụ thuộc |
|---|---|---|---|
| H1 | Tạo Supabase hosted, `supabase db push` (0001–0005), deploy `delete-account` + `public-journey`, đặt secret `SUPABASE_URL` / `SUPABASE_ANON_KEY` trên repo | Build IPA/APK mới vào được tab Nhóm. Hướng dẫn: [runbooks/hosted-supabase.md](runbooks/hosted-supabase.md) | Không |
| H2 | SMTP riêng (Resend/SES) cho email OTP (spike S8) | 10/10 mail tới Gmail < 30s, không vào spam. Hướng dẫn + bảng nghiệm thu: [runbooks/hosted-supabase.md](runbooks/hosted-supabase.md) §3, §6 | H1 (cùng người) |
| H3 | Ruleset/branch protection, CODEOWNERS, PR template (**đã làm trong PR này**), mời thành viên đúng quyền | `main` chỉ nhận PR qua CI xanh + review. Mời thành viên: `scripts/github/invite-members.sh` (mặc định dry-run, cần `--apply`) | Không |
| H4 | Duyệt văn bản EULA/privacy (`lib/features/safety/l10n/`), email hỗ trợ thật thay `support@ourney.app` | Văn bản đã duyệt, ghi ADR ([adr/0002](adr/0002-support-email-and-legal-text.md), đang Proposed) | Không (đã có mặc định) |
| H5 | Release `v0.1.0` theo ngày cố định: tag → workflow tự gắn IPA + APK vào Release, release notes, hướng dẫn tự ký | Có GitHub Release. Checklist: [runbooks/release.md](runbooks/release.md) | Chỉ chờ bug Blocker/Critical |

### @thydynh03 — QA iPhone, UI, truy vết yêu cầu
| ID | Việc | Xong khi | Phụ thuộc |
|---|---|---|---|
| T1 | Ký IPA bằng Apple ID free, chạy luồng solo (local-only, không cần server) trên iPhone (spike S1) | onboarding → tạo journey → check-in → timeline → share chạy được | Không |
| T2 | Đo camera cold/warm start trên iPhone (S3) | Có số đo vs mục tiêu < 2s / < 1s trong `docs/spikes/` | Không |
| T3 | Share card trên máy thật (S6): dấu tiếng Việt, emoji, share IG/Zalo/Messenger, file < 1MB | Ảnh chụp minh hoạ trong `docs/spikes/` | Không |
| T4 | Accessibility (VoiceOver, chữ cỡ lớn, Reduce Motion) + rà chuỗi vi/en; tự sửa bug UI trong vùng | Không còn lỗi Blocker | Không |
| T5 | `docs/TRACE.md`: mỗi FR/NFR → file test tự động hoặc bước test tay | Mọi dòng P1 trong SRS có test | Không |
| T6 | *(tuần 2, sau H1 — bổ sung, không chặn ai)* chạy luồng nhóm trên server hosted | Biên bản test | H1 |

### @lken1514 — Android, chạy nền, thông báo, native
| ID | Việc | Xong khi | Phụ thuộc |
|---|---|---|---|
| L1 | Cài APK, chạy luồng chính trên Android tầm trung, đo camera start | Luồng chính chạy được | Không |
| L2 | Spike S4: upload nền bằng `background_downloader` trong `lib/data/sync/` (test với Supabase local) | Ảnh lên server sau khi kill app / có mạng lại | Không |
| L3 | Test thông báo nhắc cả 2 nền tảng: đúng giờ, 21:00 "streak sắp mất", ≤ 64 thông báo chờ | Biên bản test | Không |
| L4 | Android 12+ `dataExtractionRules` + loại DB/media khỏi iCloud backup trên iOS (native nhỏ) | Dữ liệu không bị backup/chuyển máy | Không |
| L5 | Test offline: tắt mạng → check-in → bật mạng → đồng bộ (Supabase local) | Không mất check-in | Không |
| L6 | *(tuần 2, sau H1 — bổ sung)* lặp lại L5 trên server hosted | Biên bản test | H1 |

### @nguyenductien-qnm — web, backend, vận hành
| ID | Việc | Xong khi | Phụ thuộc |
|---|---|---|---|
| N1 | Trang `web/` (GitHub Pages): landing link mời (mở `ourney://join/<code>`, fallback nhập mã) + trang xem journey solo gọi `public-journey` (JSON; thử bằng `supabase functions serve` local) | Mở link trên trình duyệt điện thoại xem được | Không |
| N2 | Nút "Copy public link" trong app trỏ sang trang ở N1 thay vì endpoint JSON | Người nhận link xem được journey | N1 (cùng người). Sửa trong `share_card` → nhờ @thydynh03 review |
| N3 | RPC xem trước nhóm theo mã mời (tên, số thành viên) + pgTAP; màn join hiện tên nhóm | Màn join hiện tên nhóm | Không. Sửa `lib/data/repositories/group_repository.dart` → nhờ @lken1514 review |
| N4 | `docs/runbook.md`: `pg_dump` theo lịch, quay về migration trước, xoay khoá | Có runbook | Không |
| N5 | Observability: bảng log/crash trên Supabase + truy vấn retention D1/D7/D14, số check-in/ngày | Xem được số liệu khi dogfood | Không (mặc định: log Supabase) |

## 4. Quyết định mặc định (owner có thể đổi sau)
- Email hỗ trợ: email của @hofang42 cho tới khi có domain.
- Log/metric: ghi vào bảng Supabase, **chưa dùng Sentry**.
- Thành viên bị owner xoá khỏi nhóm: **không** quay lại được bằng mã mời (đúng code hiện tại).
- EULA/privacy: dùng bản nháp hiện có, duyệt trước H5.
- Thiết bị: giả định @thydynh03 có iPhone, @lken1514 có Android. Nếu khác thì **đổi vai T ↔ L** (L4 phần iOS cần iPhone để kiểm tra).

## 5. Lịch
| Tuần | Việc |
|---|---|
| 1–2 | Toàn bộ H1–H4, T1–T5, L1–L5, N1–N5 song song |
| 2 (sau H1) | T6, L6 trên server hosted (bổ sung) |
| 3 | Bug bash chung → H5 release `v0.1.0` → dogfood 14 ngày (mục tiêu SRS §8: D14 ≥ 40%) |

## 6. Quy tắc repo (ruleset trên GitHub)
- `main`: cấm push thẳng, cấm force-push, cấm xoá; bắt buộc PR + 1 approval (approval cũ bị huỷ khi có commit mới), resolve hết comment, CI xanh (`ourney_core`, `supabase`, `apps/mobile`); chỉ squash merge hoặc merge commit. Admin (@hofang42) được bypass khi khẩn cấp.
- `release/**`: cấm force-push, cấm xoá.
- Tag `v*`: chỉ admin tạo/sửa/xoá (tag kích hoạt release IPA/APK).
- Branch tính năng (`feat/*`, `fix/*`, `chore/*`) **không** khoá force-push để còn rebase lên `main`.
