# Ourney — Chia việc v0.1.0 (4 người, không block nhau)

> 2026-10-16 · Trạng thái xuất phát: code v1 đủ các yêu cầu P1 trong [SRS.md](SRS.md), CI xanh, đã có `.ipa` chưa ký + `.apk`. Còn thiếu: kiểm chứng trên máy thật, server hosted, trang web, quy trình release.
> Quy trình mỗi việc: branch `feat/<id>-<slug>` → PR (theo template) → reviewer cặp → squash merge vào `main`.
> Giai đoạn 2 — Persona UI, mỗi người trọn persona: [§7](#7-giai-đoạn-2--persona-ui-mỗi-người-trọn-persona).

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
- `main`: cấm push thẳng, cấm force-push, cấm xoá; bắt buộc PR (không cần approval: ai có quyền ghi đều merge được), resolve hết comment, CI xanh (`ourney_core`, `supabase`, `apps/mobile`); chỉ squash merge hoặc merge commit. Admin (@hofang42) được bypass khi khẩn cấp.
- `release/**`: cấm force-push, cấm xoá.
- Tag `v*`: chỉ admin tạo/sửa/xoá (tag kích hoạt release IPA/APK).
- Branch tính năng (`feat/*`, `fix/*`, `chore/*`) **không** khoá force-push để còn rebase lên `main`.

## 7. Giai đoạn 2 — Persona UI: mỗi người trọn persona

> Mục tiêu: làm đủ 6 persona skin theo [06-adaptive-persona-ui-system.md](06-adaptive-persona-ui-system.md) và `CLAUDE.md` §4, ra trong bản release kế tiếp sau `v0.1.0`. Mỗi người bắt đầu phần của mình khi xong việc tuần 1–2 ở §3. Phân công là **quyết định mặc định**, owner đổi được.
>
> **Chia theo persona, không chia theo màn.** Ai nhận persona nào thì làm trọn 3 màn của persona đó: timeline, camera HUD, share card (persona 2 là Squad wall). Riêng phần nền dùng chung (theme, dock 3 tab, khung persona, Hub, tạo journey) do một người giữ (F).
>
> **UI nằm trong asset.** Mỗi màn có bảng thiết kế trong `apps/mobile/assets/design_personas/`. Cột "Bảng thiết kế" ghi `P2 · trái` = persona 2, điện thoại bên trái. Đọc bằng skill **`/design-ref <persona> <màn>`**: skill cắt đúng màn, phóng to, chỉ ra token cần dùng và các lỗi của ảnh mockup không được chép.

### 7.1 Phân công và thư mục

| Người | Phụ trách | Thư mục sở hữu | Reviewer |
|---|---|---|---|
| @thydynh03 | **F** — Nền tảng: theme, dock 3 tab, khung persona, widget dùng chung, Hub, tạo journey | `apps/mobile/lib/app/`, `apps/mobile/lib/shared/`, `apps/mobile/lib/personas/persona_contract.dart` | @lken1514 |
| @hofang42 | **Q** — Persona 1 Quiet Transformer · **R** — Persona 5 Aesthetic Flexer (cùng kiểu đường cong + trục dọc) | `lib/personas/{quiet_transformer,aesthetic_flexer}/` | @nguyenductien-qnm |
| @nguyenductien-qnm | **S** — Persona 2 Accountability Squad · **M** — Persona 3 Memory Collectors (cùng kiểu đường đi + Polaroid) | `lib/personas/{accountability_squad,memory_collectors}/` | @hofang42 |
| @lken1514 | **D** — Persona 4 Couple Rituals (kèm dữ liệu nhóm theo ngày trong `lib/data/`) · **Z** — Persona 6 Minimalist Habit | `lib/personas/{couple_rituals,minimalist_habit}/`, `lib/data/` | @thydynh03 |

Mỗi persona một thư mục, một người. F dựng khung ở F1, các thư mục còn lại chỉ người được giao sửa:

```
apps/mobile/lib/personas/
├── persona_contract.dart     # F: dữ liệu đầu vào cho timeline, camera HUD, share/squad
├── quiet_transformer/        # @hofang42
│   ├── timeline.dart         #   connectedWeightCurve
│   ├── camera_hud.dart       #   ghostAlignVault
│   ├── share_card.dart       #   sideBySideArchive
│   └── l10n/                 #   ARB vi/en riêng của persona
├── accountability_squad/     # @nguyenductien-qnm
├── memory_collectors/        # @nguyenductien-qnm
├── couple_rituals/           # @lken1514
├── aesthetic_flexer/         # @hofang42
└── minimalist_habit/         # @lken1514
apps/mobile/test/personas/<persona>/   # test của từng persona
```

Các thư mục `lib/features/*` vẫn theo §2. Bộ chuyển variant trong `journeys`, `camera`, `share_card`, `groups` do F gắn một lần ở F3, chủ feature theo §2 review. Sau đó persona owner không cần sửa file của feature.

### 7.2 Để không ai chờ ai

- **Hợp đồng theme đã có sẵn** trong `apps/mobile/lib/app/theme/`: `OurneyPersonaTheme`, 3 enum `TimelineLayoutVariant` / `CameraHudVariant` / `ShareCardVariant`, và `buildAppTheme(brightness, skin)`.
- **F1 là PR đầu tiên** (≤ 2 ngày): khung `lib/personas/`, `persona_contract.dart`, l10n và helper test. Trong lúc chờ, mỗi người đọc bảng bằng `/design-ref`, viết painter (`CustomPainter`) và widget test với dữ liệu giả ngay trong thư mục persona của mình.
- **Painter dùng chung trong cùng một người:** Q1 viết painter đường cong để R1 dùng lại; S1 viết painter đường đi để M1 dùng lại. Hai cặp này cùng một người làm nên không phải chờ ai.
- **Widget chưa có trong `lib/shared/`** thì làm tạm trong thư mục persona. F5 gom lại sau, không chặn ai.
- **Dữ liệu:** chỉ hiển thị field đã có (`Journey.metricName/metricUnit`, `CheckIn.metricValue`, streak, ngày thứ N, thành viên nhóm hôm nay). Bảng thiết kế có số liệu mà model chưa có (nhiệt độ, địa điểm, pace) thì bỏ khỏi UI và ghi "thiếu dữ liệu" trong PR, không bịa. Dữ liệu nhóm theo ngày do @lken1514 làm ở D1 (vùng `lib/data/` của mình).
- **Điều kiện xong chung cho mọi task UI**, ngoài cột "Xong khi": light và dark; rộng 320/390/430dp và chữ ×1.35 không tràn; chuỗi vi/en nằm trong ARB của persona; Reduce Motion; vùng chạm ≥ 48dp; `flutter analyze` và `dart analyze` sạch; có widget test; PR kèm ảnh chụp light và dark (`CLAUDE.md` §1–3).

### 7.3 Việc của từng người

#### @thydynh03 — F: nền tảng dùng chung
| ID | Việc | Bảng thiết kế | Xong khi | Phụ thuộc |
|---|---|---|---|---|
| F1 | Khung persona: `lib/personas/` với 6 thư mục chứa widget stub (timeline, camera HUD, share). `persona_contract.dart` định nghĩa dữ liệu đầu vào cho từng màn (journey, check-in theo ngày, streak, thành viên, cờ ẩn metric). Mở rộng `tool/gen_l10n.dart`, delegate và `l10n_test` cho `lib/personas/*/l10n/`. Helper test `pumpPersona(widget, skin:, brightness:, width:, textScale:)`. Thêm mục persona vào `lib/features/README.md` | — | Mỗi persona owner build, sinh l10n và chạy test được trong thư mục của mình | Không |
| F2 | `activeJourneyIdProvider` và `activePersonaSkinProvider` trong `lib/app/providers.dart` (lưu ở `camera.lastJourneyId`, skin tính bằng `personaSkinForTemplate`). `MaterialApp.router` dùng `buildAppTheme(b, skin)` với `themeAnimationDuration` 320ms, `Curves.easeOutCubic` | — ([06](06-adaptive-persona-ui-system.md) §1) | Đổi journey thì màu chuyển mượt, không reload route. Có test provider | Không |
| F3 | Gắn 4 bộ chuyển `AnimatedSwitcher` 260ms gọi widget persona: `journey_detail_screen` (timeline), `capture_screen` (HUD), `share_card_screen` (share), `group_today_screen` (squad wall). Đổi journey **không** khởi động lại `CameraController` | — ([06](06-adaptive-persona-ui-system.md) §1 Q1) | Đổi journey thì 3 màn đổi theo skin; test camera không start lại | F1, F2 |
| F4 | Dock 3 tab theo `CLAUDE.md` §2: Journeys (icon bản đồ) · nút chụp ở giữa (hero 76pt ở màn camera, pill 56×40 màu `primaryAccent` ở màn khác) · Squad (icon nhóm). Chỉ dùng icon vector | Dock dưới của cả 6 bảng | Dock giống nhau trên mọi màn chính và đổi màu theo skin | F2 |
| F5 | Widget dùng chung đọc `OurneyPersonaTheme`: `OurneyPrimaryButton` (cao 52/44dp, nhấn thu 0.96 trong 110ms, có gờ dưới khi `bottomLipHeight > 0`), pill ghost, `PersonaPill` (pill đầu màn), `PolaroidFrame` (nghiêng, băng dính), ô chờ nét đứt | P1 · giữa; P2 · trái, phải; P3 · trái | Widget test 6 skin × 2 theme. Persona owner thay bản tạm | F1 |
| F6 | Helper responsive theo `CLAUDE.md` §3 (lề 16/20/24dp theo độ rộng, card tối đa 480dp). Mở rộng `theme_contrast_test` cho 6 skin × 2 theme, chỉnh token nếu chưa đạt AA | — | Test xanh, mọi cặp chữ/nền đạt AA | Không |
| F7 | Hub Journeys trên nền Editorial Base (`editorialNeutralBase`). Mỗi `JourneyCard` có badge màu persona và emoji. Chạm card thì đặt journey đó làm active. Sửa trong `features/journeys`, nhờ @nguyenductien-qnm review | — ([06](06-adaptive-persona-ui-system.md) §1 Q2) | Hub đúng ở light/dark với 0, 1 và 3 journey | F2 |
| F8 | Tạo journey có live preview: 6 thẻ archetype (5 template, cộng Couple = `custom` 2 người hoặc 💞 theo `personaSkinForTemplate`). Chạm thẻ thì màn đổi màu ngay và hiện ảnh preview `designAssetPath`. Sửa trong `features/journeys`, nhờ @nguyenductien-qnm review | Cả 6 bảng (ảnh preview) | Chọn thẻ thì màu đổi trong 320ms; journey tạo ra đúng template | F2 |

#### @hofang42 — Q: Persona 1 Quiet Transformer (giảm cân)
| ID | Việc | Bảng thiết kế | Xong khi | Phụ thuộc |
|---|---|---|---|---|
| Q1 | Timeline `connectedWeightCurve`: đường cong cân nặng từ `metricValue` nối vào trục dọc ảnh mốc (ngày 1, 7, 14, hôm nay). Ẩn số khi journey ẩn metric (FR-B7). Viết painter đường cong để R1 dùng lại | P1 · giữa | Đúng khi chưa có, có 1 và có nhiều điểm metric | Không |
| Q2 | Camera `ghostAlignVault`: ảnh ngày 1 mờ 30% (bật/tắt được) để căn dáng, pill `Private Vault · Day N` có icon khoá vector, thanh trượt cân nặng ghi vào `metricValue` | P1 · trái | Check-in vẫn ≤ 3 chạm (FR-C4); ảnh ghost không rời khỏi máy | Không |
| Q3 | Share `sideBySideArchive`: ảnh ngày 1 cạnh ảnh hôm nay, công tắc "Ẩn số cân". Đi qua exporter hiện có (1080×1920, 1080×1350) | P1 · phải | Mặc định ẩn số kg và làm mờ ảnh khi share (FR-B7), người dùng tự tắt được | Không |

#### @hofang42 — R: Persona 5 Aesthetic Flexer (30 ngày tập luyện)
| ID | Việc | Bảng thiết kế | Xong khi | Phụ thuộc |
|---|---|---|---|---|
| R1 | Timeline `athleticTelemetry`: sparkline neon và trục dọc ảnh mốc, dùng lại painter của Q1. `workout30` không có metric mặc định thì không vẽ km, chỉ vẽ trục ngày | P5 · trái | Đúng cả khi journey có và không có metric | Q1 |
| R2 | Camera `stravaStickerStudio`: sau khi chụp, chọn một trong 3 kiểu overlay (Bold HUD, Minimal Stamp, Film Strip) với ngày N, streak, metric nếu có | P5 · giữa | Đổi kiểu bằng pill; overlay không in vào ảnh gốc | Không |
| R3 | Share `transparentStorySticker`: thẻ story 9:16 có dải heatmap các ngày hoạt động. Nút share dùng share sheet hệ thống (deep link Instagram Stories là FR-E4, P2) | P5 · phải | Heatmap đúng ngày có/không check-in, không chỉ phân biệt bằng màu | Không |

#### @nguyenductien-qnm — S: Persona 2 Accountability Squad (học tiếng Anh)
| ID | Việc | Bảng thiết kế | Xong khi | Phụ thuộc |
|---|---|---|---|---|
| S1 | Timeline `steppingStoneQuest`: đường chữ S dẫn tới cúp ngày cuối, Polaroid nghiêng ở các mốc. Viết painter đường đi để M1 dùng lại | P2 · trái | Cuộn mượt với 30+ ngày; mốc 7/14/hôm nay hiện đúng | Không |
| S2 | Camera `studyTimerSnap`: pill `số phút học · 🔥 streak` (phút lấy từ metric "Thời gian học") và pill giờ chụp | P2 · giữa | Hiện đúng số phút và streak; journey không có metric thì ẩn phần phút | Không |
| S3 | Squad `squadPolaroidWall` (hiện ở màn Squad hôm nay và làm share card của persona 2): thanh `x/y đã check-in hôm nay`, lưới Polaroid 2 cột co giãn theo độ rộng, reaction dùng `reaction_bar`, ô nét đứt "đang chờ" cho người chưa chụp. **Không có nút Nudge ở v1** (FR-G3 là P2) | P2 · phải | Nhóm 1–10 người hiện đúng; local-only hiện `NeedsServerView` | Không (F3 để hiện trong app) |

#### @nguyenductien-qnm — M: Persona 3 Memory Collectors (chuyến đi)
| ID | Việc | Bảng thiết kế | Xong khi | Phụ thuộc |
|---|---|---|---|---|
| M1 | Timeline `scrapbookThread`: đường chỉ khâu màu đất nung nối các Polaroid dán băng dính, dùng lại painter của S1 | P3 · trái | Cuộn mượt với 30+ ngày | S1 |
| M2 | Camera `disposableFilmStamp`: pill `FILM ROLL n/N` (n = số check-in, N = số ngày), dấu ngày màu hổ phách kiểu máy film | P3 · giữa | Dấu ngày chỉ là lớp overlay, không in vào ảnh (giữ pipeline nén FR-C5). Không hiện nhiệt độ, địa điểm (thiếu dữ liệu) | Không |
| M3 | Share `filmContactSheet`: dải film 35mm nền tối, tối đa 20 khung, có số khung | P3 · phải | Journey nhóm chỉ share ảnh, không bao giờ có link công khai (FR-E3) | Không |

#### @lken1514 — D: Persona 4 Couple Rituals (cặp đôi)
| ID | Việc | Bảng thiết kế | Xong khi | Phụ thuộc |
|---|---|---|---|---|
| D1 | Dữ liệu trong `lib/data/`: check-in của nhóm theo từng ngày và ảnh hôm nay của thành viên khác, có provider và test (dùng cho D2, D3; S3 dùng được nếu cần) | — | Test với nhóm 2 người và nhóm 10 người; local-only trả về rỗng | Không |
| D2 | Timeline `duoSplitTimeline`: mỗi ngày một cặp ảnh của 2 thành viên, nút tim/lửa ở giữa, thiếu ảnh một bên thì hiện ô chờ. Dùng tên hiển thị, không ghi "His/Her" | P4 · trái | Journey nhóm 2 người hiện đủ cặp theo ngày | D1 |
| D3 | Camera `halfFrameDuo`: nửa trái là ảnh hôm nay của người kia, nửa phải là viewfinder. Người kia chưa chụp thì nửa trái là ô chờ | P4 · giữa | Thấy ảnh của bạn; ảnh của mình vẫn lưu đủ khung | D1 |
| D4 | Share `coupleMosaicPoster`: lưới ảnh của 2 người, `N ngày · M khoảnh khắc` | P4 · phải | Không bao giờ có link công khai (FR-E3) | Không |

#### @lken1514 — Z: Persona 6 Minimalist Habit (tự đặt)
| ID | Việc | Bảng thiết kế | Xong khi | Phụ thuộc |
|---|---|---|---|---|
| Z1 | Timeline `chainCalendarGrid`: lưới 7 cột, ô ảnh vuông nối bằng đường cam liên tục, ngày lỡ hoặc chưa tới là ô nét đứt (FR-B4). Dựa trên `features/journeys/ui/timeline_grid.dart` hiện có, không sửa file đó | P6 · giữa | Lưới đúng ngày theo `local_date` | Không |
| Z2 | Camera `zeroText3Sec`: một pill, nút chụp màu cam, đăng không cần caption | P6 · trái | Đăng bằng 1 chạm, caption vẫn sửa được sau | Không |
| Z3 | Share `zenSummaryCard`: `x/N ngày`, % đều đặn, một ảnh vuông. Đi qua exporter hiện có | P6 · phải | Xuất đúng 2 cỡ, file < 1MB, dấu tiếng Việt đúng | Không |

### 7.4 Lịch theo từng người
| Người | Tuần 1 | Tuần 2 | Tuần 3 |
|---|---|---|---|
| @thydynh03 | F1, F2 | F3, F4, F5 | F6, F7, F8 |
| @hofang42 | Q1, Q2 | Q3, R1 | R2, R3 |
| @nguyenductien-qnm | S1, S2 | S3, M1 | M2, M3 |
| @lken1514 | D1, Z1 | D2, Z2 | D3, D4, Z3 |

Tuần 4, cả nhóm: ghép, đổi journey trên iPhone và Android thật, bug bash 6 skin × 2 theme, rồi release theo quy trình H5.
