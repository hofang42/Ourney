# Ourney — Kế hoạch implement v1 (đa agent)

> 2026-10-16 · Đầu vào: [02-requirements-v2.md](02-requirements-v2.md) (mục 9–10 là scope đã chốt), [03-design-system.md](03-design-system.md).
> Ký hiệu: ✅ đã kiểm chứng · ⚠️ chưa kiểm chứng, phải verify ở spike · **TBD** = chủ dự án quyết.

---

## 0. Quyết định đã chốt (ghi đè các tài liệu trước)

| Hạng mục | Quyết định | Ảnh hưởng |
|---|---|---|
| Nền tảng | **iOS + Android** ngay ở v1 | |
| Stack | **Flutter** (1 codebase). Lý do: cần cả hai nền tảng, team biết cả Swift lẫn Flutter. Swift+Kotlin là 2 codebase. Skip/KMP vẫn cần Mac | Phần Swift/xtool/SwiftUI ở 01/02/03 **không còn hiệu lực**. Các phần sản phẩm, data model, RLS, vòng đời nhóm vẫn giữ |
| Build iOS | **MobAI ios-builder** v0.11.0 (MIT) ✅: chạy trên Windows, đẩy job build lên **GitHub Actions macOS runner** (miễn phí, không giới hạn với repo public ✅), mặc định ra **`.ipa` chưa ký** ✅. Xcode chạy trên cloud, không chạy trên máy | xtool không dùng cho v1 |
| Ký & cài iOS | Tự ký bằng Sideloadly/zsign hoặc MobAI re-sign bằng Apple ID free. **Không có tài khoản Apple trả phí** | Apple ID free: hết hạn 7 ngày, không push, không App Groups, không universal link ⚠️. Vì vậy v1 **không có** widget/push/universal link |
| Dev loop iOS | `builder dev flutter` hot reload trên iPhone thật qua MobAI **bản free** ⚠️ (chưa rõ giới hạn của bản free) | Phần lớn dev chạy trên Android emulator/thiết bị Android + `flutter test`. iPhone dùng để verify |
| Android | Build local (Windows/WSL), ra APK | |
| Media | **Chỉ ảnh** ở v1 (clip lên v0.2) | |
| Backend | Supabase: **local Docker (Supabase CLI trong WSL)** khi dev, project hosted khi dogfood (chủ dự án tạo, đưa URL + anon key) | |
| Repo | [github.com/hofang42/Ourney](https://github.com/hofang42/Ourney), public. `thydynh03`, `lken1514` đã được mời (quyền write, mức cao nhất cho repo cá nhân) | Muốn quyền admin thì phải chuyển repo sang Organization (**TBD**) |
| CI | GitHub Actions: analyze + test mỗi PR. Build `.ipa` chưa ký + `.apk` khi merge `main`/tag | |
| Bundle ID | `com.hofang42.ourney` (cả iOS lẫn Android). Đổi được rẻ **trước** lần publish store đầu tiên; sau publish thì không đổi được | Chốt lại trước khi nộp store (v1 chưa nộp) |
| Chia việc cho người | **TBD**: chủ dự án tự phân. Plan chia theo workstream, cột "Owner" để trống |

## 1. Techstack Flutter

| Lớp | Chọn | Ghi chú |
|---|---|---|
| Ngôn ngữ/SDK | Flutter stable mới nhất lúc spike, Dart 3 | Pin version trong `.fvmrc` / CI |
| State + DI | **Riverpod** (codegen) | Khớp khuyến nghị `ui-ux-pro-max` stack flutter |
| Routing + deep link | **go_router** + custom scheme `ourney://` | Universal/App Links để v0.2 |
| Local DB / offline | **drift** (SQLite) | Hàng đợi upload, cache |
| Backend SDK | **supabase_flutter** | Auth OTP, Postgres, Storage, Functions |
| Camera | `camera` plugin. Nếu spike không đạt mục tiêu cold start thì viết plugin native nhỏ (Swift/Kotlin) | Mục tiêu theo 02 §6: camera sẵn sàng < 1s (warm), cold start < 2s ⚠️ đo ở spike S3 |
| Nén ảnh | `flutter_image_compress` (1080px, q70) | |
| Upload nền | `background_downloader` (có hỗ trợ upload nền iOS/Android) ⚠️ verify ở spike | Thay cho URLSession tự viết |
| Thông báo local | `flutter_local_notifications` + `timezone` | Lên lịch cuốn chiếu 14 ngày |
| Share card | `RepaintBoundary` → PNG → `share_plus` | 1080×1920, 1080×1350 |
| Hiệu ứng | `confetti`, haptics bằng `HapticFeedback` | Tôn trọng `MediaQuery.disableAnimations` |
| Font | Be Vietnam Pro + Bricolage Grotesque, bundle trong `assets/fonts` (OFL) | |
| Lỗi/crash | Sentry Flutter (free tier) **TBD** | Hoặc chỉ log vào Supabase |
| Lint/format | `flutter_lints` + `dart format`, `custom_lint`/`riverpod_lint` | |
| Backend code | SQL migrations + pgTAP tests, Edge Functions (Deno/TS) | |
| Link xem công khai (journey solo) | Edge Function render HTML + OG tag (không cần Next.js ở v1) | |

### Cấu trúc repo (monorepo)

```
Ourney/
├── apps/mobile/                 # Flutter app (iOS + Android)
│   ├── lib/
│   │   ├── app/                 # bootstrap, router, theme (design tokens)
│   │   ├── features/            # auth, onboarding, camera, checkin, journeys,
│   │   │                        # groups, share_card, profile, safety, reminders
│   │   └── data/                # drift db, repositories, sync/upload queue
│   └── test/ integration_test/
├── packages/ourney_core/        # Dart thuần: model, streak, local_date, validation (test trên Linux)
├── supabase/                    # migrations/, functions/, tests/ (pgTAP), seed.sql
├── .github/workflows/           # ci.yml, build.yml
├── builder.json                 # cấu hình ios-builder
└── docs/                        # spec, ADR, plan
```

Ranh giới thư mục chính là **ranh giới sở hữu của từng agent** (mục 4). Hai agent không bao giờ ghi cùng một thư mục trong cùng một wave.

## 2. Đội agent & skill

Session chính đóng vai **Orchestrator**: giữ plan, cắt task, giao việc, merge. Mỗi workstream code chạy trong **session/worktree riêng** (`start_session`, `use_worktree: true`, branch riêng, PR riêng). **Không có agent nào làm tất cả.**

| Vai trò | Agent type | Skill nạp vào | Model | Phụ trách |
|---|---|---|---|---|
| Orchestrator | Session chính | `agent-skills:planning-and-task-breakdown`, `git-workflow-and-versioning` | opus | Plan, phân task, merge, giữ hợp đồng giữa các module |
| Product/Spec | Session chính + `general-purpose` | `agent-skills:spec` (spec-driven-development), `interview-me`, `idea-refine` | sonnet | SPEC.md, acceptance criteria, user stories |
| Researcher | `researcher` (qua `deep-dive`) | `source-driven-development` | sonnet | Verify thư viện/API trước khi dùng (chống hallucination) |
| Architect | `Plan` | `api-and-interface-design`, `documentation-and-adrs` | opus | Kiến trúc, contract Dart interface + SQL schema, ADR |
| UX/UI Designer | `general-purpose` | `ui-ux-pro-max` (stack `flutter`), `ui-ux-pro-max:design-system`, `ui-ux-pro-max:brand` | sonnet | Design tokens Flutter, wireframe các màn, share card template |
| Backend Engineer | `general-purpose` | `security-and-hardening`, `api-and-interface-design`, `test-driven-development` | sonnet | Migrations, RLS, RPC/trigger vòng đời, Storage policies, Edge Functions, pgTAP. Mọi migration đều qua Security Auditor |
| Security Auditor | `agent-skills:security-auditor` | `security-and-hardening` | opus | Review RLS/Storage/Edge Function, threat model, OWASP Mobile |
| Core/Domain Engineer | `general-purpose` | `test-driven-development`, `incremental-implementation` | sonnet | `packages/ourney_core`: streak, local_date, validation |
| Data/Sync Engineer | `general-purpose` | `test-driven-development`, `doubt-driven-development` | opus | drift, repository, upload queue, sync cursor |
| Mobile UI Engineer A | `general-purpose` | `frontend-ui-engineering`, `ui-ux-pro-max` | sonnet | Theme, onboarding, journeys, timeline |
| Mobile UI Engineer B | `general-purpose` | `frontend-ui-engineering`, `performance-optimization` | sonnet | Camera, check-in, share card |
| Social Engineer | `general-purpose` | `frontend-ui-engineering`, `security-and-hardening` | sonnet | Groups, invite, today view, reactions, safety (report/block) |
| DevOps/CI | `cloud-engineer` | `ci-cd-and-automation` | sonnet | GitHub Actions, ios-builder, script ký/cài, release artifacts |
| Test Engineer | `agent-skills:test-engineer` | `test-driven-development` (Flutter `integration_test`, widget test, pgTAP) | sonnet | Chiến lược test, widget/integration test, coverage |
| Code Reviewer | `agent-skills:code-reviewer` | `code-review-and-quality` | opus | Review mọi PR trước khi người review |
| Simplifier | `/simplify` skill | `code-simplification` | sonnet | Dọn code sau mỗi wave |
| Codebase search | `Explore` | — | haiku | Tra cứu nhanh, không ghi |
| Release Manager | `agent-skills:ship` (fan-out persona) | `shipping-and-launch` | opus | Go/no-go checklist cho beta |
| Observability | `general-purpose` | `observability-and-instrumentation` | sonnet | Logging, crash, metric retention D1/D7/D14 |

**Quy tắc chung cho mọi agent code:**
1. Chỉ ghi trong thư mục của mình (mục 4). Cần sửa contract dùng chung thì báo Orchestrator, không tự sửa.
2. Mọi API/thư viện phải có nguồn (pub.dev/docs). Không chắc thì hỏi lại, **không đoán**.
3. TDD với logic (`ourney_core`, data, SQL). UI có widget test cho trạng thái chính.
4. Mỗi task = 1 PR nhỏ: `flutter analyze` sạch, test xanh, `code-reviewer` agent duyệt, rồi **người** duyệt và merge.
5. Commit message theo Conventional Commits.

## 3. Các giai đoạn trong vòng đời phát triển

| # | Giai đoạn | Agent chính | Đầu ra | Gate (điều kiện qua) |
|---|---|---|---|---|
| P0 | **Thiết lập** | Orchestrator, DevOps | Repo, branch protection, CODEOWNERS, issue/PR template, labels, Supabase local chạy được, `builder` cài trên Windows. **Quản lý cấu hình/secret**: `.env.example` commit, `.env.local` gitignore, `--dart-define-from-file`, `service_role`/SMTP key/Android keystore chỉ nằm trong GitHub Secrets, bật secret scanning + push protection. **SMTP riêng** (Resend/SES) cho OTP | `supabase start` OK. `flutter doctor` OK (Android). Không có secret trong git |
| P1 | **Discovery & Spec** | Product/Spec, Researcher | `docs/SPEC.md`: user stories + acceptance criteria. **`docs/TRACE.md`**: ma trận mục 02 §10 → issue → test. ADR cắt clip khỏi v1 | 3 người duyệt spec. Mọi mục §10 đều có dòng trong TRACE |
| P2 | **Thiết kế** | Architect, UX/UI, Security | ADR-001…00n (stack, state, offline, RLS, build iOS), schema SQL + Dart interface (contract), wireframe 12 màn, design tokens, threat model | Contract freeze v1. Security auditor không còn High |
| P3 | **Spike kỹ thuật** | DevOps, Mobile UI B, Data/Sync | Kết quả 6 spike (mục 5) | Mọi spike ⚠️ có kết luận. Spike fail thì quay lại P2 |
| P4 | **Lập task** | Orchestrator (`agent-skills:plan`) | GitHub Issues theo wave, mỗi issue có acceptance criteria + owner (người) + agent | Không issue nào > 1 ngày công agent |
| P5 | **Build theo wave** | Các Engineer agent (song song) | Code + test theo mục 4 | Mỗi wave: CI xanh, review xong, demo được |
| P6 | **Test & QA** | Test Engineer, người (iPhone/Android thật) | Test plan, integration test, bug bash, **kiểm tra accessibility** (cỡ chữ lớn, giảm chuyển động, VoiceOver/TalkBack cho nút chụp), **i18n vi/en**, báo cáo | 0 bug Blocker/Critical. Luồng chính qua trên cả 2 nền tảng. TRACE.md mọi dòng có test pass |
| P7 | **Review bảo mật & tuân thủ** | Security Auditor, Code Reviewer | Báo cáo RLS/Storage, OWASP MASVS-lite, checklist Guideline 1.2/5.1.1 (để sẵn cho lần lên store sau) | Không còn High |
| P8 | **Phát hành beta** | Release Manager, DevOps | Tag `v0.1.0`, `.ipa` chưa ký + `.apk` trên GitHub Release, release notes, hướng dẫn tự ký, Supabase hosted, **privacy policy + EULA + trang liên hệ**, **runbook rollback + backup** (`pg_dump` theo lịch, cách quay về bản trước) | `agent-skills:ship` ra GO |
| P9 | **Vận hành & đo lường** | Observability | Dashboard D1/D7/D14 retention, số check-in/ngày, crash | Có số liệu 14 ngày dogfood |
| P10 | **Retro & lên kế hoạch v0.2** | Orchestrator, Product | Retro, backlog v0.2 (clip, push/widget khi có tài khoản Apple, universal link) | |

## 4. Wave build (P5): ai làm gì, song song thế nào

Mỗi ô = 1 session/worktree riêng. Cột "Ghi vào" là vùng sở hữu độc quyền trong wave đó.

### Wave A — Nền móng (song song 4 luồng)
| Luồng | Agent | Ghi vào | Việc | Phụ thuộc |
|---|---|---|---|---|
| A0 | Architect *(trước A1–A4)* | `docs/contracts/`, `packages/ourney_core/lib/contracts/` | `schema.md` (bảng/cột/enum dùng chung cho SQL ↔ drift), Dart interface + fake của repository, `streak_vectors.json` (golden test dùng chung cho Dart/pgTAP/Deno), quy ước route registry | P2 |
| A1 | Backend Engineer | `supabase/` | Schema (profiles, journeys, memberships, check_ins, reactions, reports, blocks, invites, moderation_queue), `is_member()`, hàm SQL `local_date(created_at, tz)` + streak phía server (**SQL là nguồn chuẩn ở server**, Dart là nguồn chuẩn ở client, cả hai chạy chung `streak_vectors.json`), RLS (CI kiểm tra **mọi bảng đều bật RLS**), Storage policy theo path, pgTAP. Migration do Orchestrator đánh số | A0 |
| A2 | Core Engineer | `packages/ourney_core/` | Model, `computeStreak(localDates)`, `localDate(createdAt, tz)`, validation + unit test | Contract P2 |
| A3 | Mobile UI A | `apps/mobile/lib/app/`, **`pubspec.yaml`**, `analysis_options.yaml`, `l10n/` | Skeleton app, **khai báo trước mọi dependency của v1**, theme tokens, router tổng hợp `routes.dart` của từng feature, font, component cơ bản, i18n vi/en (mỗi feature có file ARB riêng). Code sinh (`*.g.dart`) **được commit**, CI kiểm tra build_runner không còn diff | A0, design tokens |
| A4 | DevOps | `.github/`, `builder.json`, `scripts/` | CI analyze/test, build ipa/apk, script ký/cài | P3 spike CI |
| Review | Security Auditor → A1. Code Reviewer → tất cả | | | |

### Wave B — Tính năng (song song 5 luồng)
| Luồng | Agent | Ghi vào | Việc |
|---|---|---|---|
| B1 | Data/Sync | `apps/mobile/lib/data/` | drift schema, repository, upload queue (upsert theo `(journey,user,local_date)`, UUID từ client), sync cursor `updated_at`, cache ảnh theo storage path |
| B2 | Mobile UI A | `features/auth`, `onboarding`, `profile` | Email OTP, profile, xin quyền đúng ngữ cảnh, empty state, xoá tài khoản |
| B3 | Mobile UI B | `features/camera`, `checkin` | Camera-first, chụp, nén, caption/metric, animation đóng dấu (gọi repository B1 qua interface) |
| B4 | Mobile UI A *(sau B2)* | `features/journeys` | Tạo journey từ 4 template + custom, timeline lưới lịch, streak, tối đa 3 journey đang chạy |
| B5 | Backend Engineer *(chạy đầu Wave B)* | `supabase/functions/` | Edge Functions: `delete-account` (xoá cả media), `public-journey` (trả JSON + signed URL ngắn hạn, token thu hồi được; trang HTML theo kết quả S7), `rotate-invite` |

Phụ thuộc Wave B: B2 (xoá tài khoản) cần B5. B3 dùng interface + fake từ A0, không chờ B1. B4 chạy sau B2 trong cùng luồng UI A. Bổ sung vào B2: upload avatar. B3: nhãn "từ thư viện". B4: lưu trữ/kết thúc journey, giới hạn 3 journey đang chạy (server chặn ở C0).

### Wave C — Social, chia sẻ, an toàn (C0 trước, sau đó song song 3 luồng)
| Luồng | Agent | Ghi vào | Việc |
|---|---|---|---|
| C0 | Backend Engineer | `supabase/` (Wave C chỉ ghi `supabase/` qua C0) | RPC/trigger vòng đời nhóm (02 §9.1): chuyển owner, ẩn check-in khi rời nhóm, chỉ xoá khi còn mỗi owner, chặn join khi có block, giới hạn 10 thành viên + 3 journey đang chạy, `join_by_code`, RPC report/block → `moderation_queue`, pgTAP |
| C4 | DevOps | `web/` (GitHub Pages) | Trang landing cho link mời + link xem journey solo (gọi Function trả JSON), nút mở `ourney://`, fallback nhập mã |
| C1 | Social Engineer | `features/groups` | Mời bằng link/mã, nhập mã thủ công, tối đa 10 thành viên, màn hôm nay, reaction, các rule vòng đời (02 §9.1) |
| C2 | Mobile UI B | `features/share_card` | 1 theme, 2 cỡ, `share_plus`, link solo |
| C3 | Social Engineer *(sau C1)* hoặc UI A | `features/safety`, `reminders` | Report/block/EULA/trang liên hệ, nhắc nhở local cuốn chiếu 14 ngày + cảnh báo "streak sắp mất" lúc 21:00 |

### Wave D — Tích hợp & hoàn thiện (tuần tự)
Orchestrator ghép nhánh → Test Engineer viết `integration_test` luồng chính → `/simplify` → Observability gắn log/crash → sửa bug.

## 5. Spike P3 (mỗi spike = 1 session riêng, kết quả ghi vào `docs/spikes/`)

| # | Spike | Agent | Đạt khi |
|---|---|---|---|
| S1 | `builder ios build --unsigned` từ Windows → GitHub Actions → `.ipa` → ký Sideloadly/MobAI bằng Apple ID free → chạy trên iPhone | DevOps | App Hello chạy trên iPhone thật |
| S2 | MobAI free: `builder dev flutter` hot reload được không, giới hạn bản free | DevOps | Ghi rõ giới hạn. Không dùng được thì loop iOS = build CI |
| S3 | Camera cold start (`camera` plugin) trên iPhone + Android tầm trung | Mobile UI B | < 1.5s, nếu không thì quyết định viết plugin native |
| S4 | Upload nền `background_downloader` → Supabase Storage signed upload URL, kể cả khi app bị kill | Data/Sync | File lên được sau khi mở lại app / có mạng |
| S5 | RLS `is_member()` + Storage policy + pgTAP chạy trong CI | Backend | Test pass trên Supabase local |
| S6 | Font tiếng Việt (dấu chồng) ở weight 800, render share card 1080×1920 | UX/UI | Không bị cắt dấu, file < 1MB |
| S7 | Supabase Edge Function trả `text/html` trên domain `supabase.co` được không (⚠️ có thể bị ép thành `text/plain`) | Backend | Kết luận: HTML từ Function, hoặc trang tĩnh GitHub Pages + Function JSON |
| S8 | Email OTP qua SMTP riêng tới Gmail (người dùng VN), không vào spam | Backend | 10/10 mail tới trong < 30s |

## 6. Lịch (gợi ý, 3 người + agents)

| Tuần | Giai đoạn |
|---|---|
| 1 | P0 + P1 |
| 2 | P2 + P3 (spike song song) |
| 3 | P4 + Wave A |
| 4–5 | Wave B |
| 6 | Wave C |
| 7 | Wave D + P6 |
| 8 | P7 + P8 (beta v0.1.0) |
| 9–10 | P9 dogfood 14 ngày → P10 |

## 7. Quy trình mỗi PR

```
Issue (acceptance criteria) → session/worktree agent → TDD → flutter analyze + test
→ PR (template: what/why/test evidence/screenshot) → code-reviewer agent
→ (nếu đụng supabase/ hoặc auth) security-auditor agent → người owner review → squash merge
```
Branch: `feat/<wave>-<slug>`, `fix/…`, `chore/…`. `main` được bảo vệ: bắt buộc CI xanh + 1 review.

- **WIP limit**: mỗi người review tối đa 3 PR đang mở. Tối đa 4 agent code chạy song song.
- **Rebase lên `main`** trước khi merge. Conflict do agent của nhánh đó tự xử lý, Orchestrator chỉ phân xử khi đụng contract.
- **Migration** do Orchestrator cấp số thứ tự, tránh trùng timestamp.
- **PR bị từ chối**: comment lý do, quay lại cùng session agent đó (giữ context), không mở agent mới.
- **Contract thay đổi** (`docs/contracts/`): chỉ Architect sửa, qua PR riêng, các luồng đang chạy rebase lại.

## 8. Rủi ro của plan

| Rủi ro | Giảm thiểu |
|---|---|
| ios-builder mới v0.11, có thể có lỗi | S1 sớm. Dự phòng: workflow GitHub Actions tự viết `flutter build ios --release --no-codesign` + zip `Payload/` |
| MobAI free bị giới hạn | Dev chủ yếu trên Android. iPhone dùng để verify qua CI build |
| Apple ID free: hết hạn 7 ngày, giới hạn số app | Script ký lại hằng tuần. Dogfood iOS chỉ trong nhóm nhỏ |
| Agents song song đụng nhau | Ranh giới thư mục + contract freeze ở P2. Orchestrator merge theo thứ tự wave |
| Agent bịa API | Rule 2 + Researcher verify + code-reviewer kiểm tra import/package có thật |

## 9. Trạng thái kiểm chứng của các khẳng định về tool
- ✅ ios-builder v0.11.0, MIT, build trên GitHub Actions/Codemagic/Bitrise, mặc định unsigned, `--unsigned`, `builder dev flutter`, `builder.json`: đọc trực tiếp từ pkg.go.dev/github.com/MobAI-App/ios-builder.
- ✅ Runner GitHub-hosted chuẩn miễn phí, không giới hạn với repo public: docs.github.com (actions/reference/runners).
- ⚠️ MobAI bản free (giới hạn), re-sign bằng Apple ID free, `background_downloader` upload nền iOS, Edge Function trả HTML, cold start camera: chốt ở S1–S8.

## 10. Việc còn chờ chủ dự án (TBD)
1. Gán người cho từng workstream (cột Owner trong Issues).
2. Có chuyển repo sang Organization để có quyền admin cho 2 thành viên không?
3. Sentry hay chỉ log Supabase?
4. Tên miền cho link công khai (không chặn v1, có thể dùng URL của Supabase Functions).
