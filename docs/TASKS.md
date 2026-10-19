# Ourney — Phân công giao diện sáu phong cách (5 người)

> Cập nhật 19/10/2026. Mục tiêu của đợt này là làm đủ sáu phong cách giao diện theo [06-adaptive-persona-ui-system.md](06-adaptive-persona-ui-system.md) và mục 4 của `CLAUDE.md`. Phân công dưới đây là đề xuất mặc định, chủ dự án có thể đổi.
>
> **Chia theo phong cách, không chia theo màn hình.** Ai nhận phong cách nào thì làm trọn cả ba màn của phong cách đó: dòng thời gian, màn hình chụp và thiệp chia sẻ (riêng Accountability Squad là bức tường ảnh của nhóm). Phần nền dùng chung do một người giữ.
>
> **Giao diện nằm trong thư mục asset.** Mỗi màn có bản thiết kế trong `apps/mobile/assets/design_personas/`. Cột "Bản thiết kế" ghi `P2 · trái` nghĩa là phong cách 2, điện thoại bên trái. Đọc bằng skill **`/design-ref <phong cách> <màn>`**: skill cắt đúng màn, phóng to, chỉ ra token cần dùng và những lỗi của ảnh mockup không được chép theo.
>
> **Quy trình mỗi việc:** tạo nhánh `feat/<mã việc>-<tên ngắn>` (ví dụ `feat/Z1-chain-grid`), mở pull request theo mẫu, nhờ người review ghi ở mục 1, rồi gộp vào `main` khi CI đạt.

## 1. Phân công và thư mục

| Người | Phụ trách | Thư mục | Người review |
|---|---|---|---|
| @thydynh03 | **F** — Phần nền dùng chung: theme, thanh điều hướng 3 tab, khung phong cách, widget dùng chung | `apps/mobile/lib/app/`, `apps/mobile/lib/shared/`, `apps/mobile/lib/personas/persona_contract.dart`, `apps/mobile/tool/` | @lken1514 |
| @hofang42 | **Q** — Phong cách 1 Quiet Transformer · **R** — Phong cách 5 Aesthetic Flexer | `lib/personas/{quiet_transformer,aesthetic_flexer}/` | @nguyenductien-qnm |
| @nguyenductien-qnm | **S** — Phong cách 2 Accountability Squad · **M** — Phong cách 3 Memory Collectors | `lib/personas/{accountability_squad,memory_collectors}/` | @hofang42 |
| @lken1514 | **D** — Phong cách 4 Couple Rituals, kèm dữ liệu nhóm theo ngày | `lib/personas/couple_rituals/`, `lib/data/` | @zacknguyn |
| @zacknguyn | **Z** — Phong cách 6 Minimalist Habit · **J** — Trang hành trình và màn tạo hành trình | `lib/personas/minimalist_habit/`, `lib/features/journeys/` (Hub, tạo hành trình) | @thydynh03 |

Mỗi người review đúng một người khác, nên không ai bị dồn việc review. Thư mục không có trong bảng thì ai cũng sửa được trong pull request của việc mình, và @hofang42 xem lại theo CODEOWNERS.

Mỗi phong cách có một thư mục riêng và chỉ người được giao mới sửa thư mục đó. @thydynh03 dựng khung ở việc F1:

```
apps/mobile/lib/personas/
├── persona_contract.dart     # F: dữ liệu đầu vào cho dòng thời gian, màn hình chụp, thiệp chia sẻ
├── quiet_transformer/        # @hofang42
│   ├── timeline.dart         #   connectedWeightCurve
│   ├── camera_hud.dart       #   ghostAlignVault
│   ├── share_card.dart       #   sideBySideArchive
│   └── l10n/                 #   bản dịch vi/en riêng của phong cách
├── accountability_squad/     # @nguyenductien-qnm
├── memory_collectors/        # @nguyenductien-qnm
├── couple_rituals/           # @lken1514
├── aesthetic_flexer/         # @hofang42
└── minimalist_habit/         # @zacknguyn
apps/mobile/test/personas/<phong cách>/   # kiểm thử của từng phong cách
```

Bộ chuyển giao diện trong các tính năng `journeys`, `camera`, `share_card` và `groups` do @thydynh03 gắn một lần ở việc F3. Sau đó, người làm phong cách không phải sửa tệp nào của các tính năng ấy nữa.

## 2. Làm sao để không ai phải chờ ai

- **Hợp đồng theme đã có sẵn** trong `apps/mobile/lib/app/theme/`: `OurneyPersonaTheme`, ba enum `TimelineLayoutVariant`, `CameraHudVariant`, `ShareCardVariant`, và hàm `buildAppTheme(brightness, skin)`.
- **F1 là pull request đầu tiên**, cần xong trong hai ngày. Trong lúc chờ, mỗi người đọc bản thiết kế bằng `/design-ref`, vẽ bằng `CustomPainter` và viết widget test với dữ liệu giả ngay trong thư mục phong cách của mình.
- **Phần vẽ dùng chung nằm trong tay một người.** Q1 viết phần vẽ đường cong để R1 dùng lại, S1 viết phần vẽ con đường để M1 dùng lại. Hai cặp này đều do một người làm nên không phải chờ ai.
- **Widget chưa có trong `lib/shared/`** thì làm tạm trong thư mục phong cách. F5 gom lại sau, không chặn ai.
- **Dữ liệu:** chỉ hiển thị những gì đã có (`Journey.metricName`, `Journey.metricUnit`, `CheckIn.metricValue`, chuỗi ngày, ngày thứ N, thành viên nhóm hôm nay). Bản thiết kế có số liệu mà model chưa có, như nhiệt độ, địa điểm hay tốc độ chạy, thì bỏ khỏi giao diện và ghi "thiếu dữ liệu" trong pull request, không bịa. Dữ liệu nhóm theo ngày do @lken1514 làm ở việc D1.
- **Điều kiện xong chung cho mọi việc giao diện**, ngoài cột "Xong khi": có cả nền sáng và nền tối; rộng 320, 390 và 430dp, chữ phóng 1,35 lần vẫn không tràn; chuỗi vi/en nằm trong tệp bản dịch của phong cách; tôn trọng chế độ giảm chuyển động; vùng chạm từ 48dp; `flutter analyze` và `dart analyze` sạch; có widget test; pull request kèm ảnh chụp nền sáng và nền tối (mục 1 đến 3 của `CLAUDE.md`).

## 3. Việc của từng người

#### @thydynh03 — F: phần nền dùng chung
| ID | Việc | Bản thiết kế | Xong khi | Phụ thuộc |
|---|---|---|---|---|
| F1 | Khung phong cách: `lib/personas/` với 6 thư mục chứa widget tạm (dòng thời gian, màn hình chụp, thiệp chia sẻ). `persona_contract.dart` định nghĩa dữ liệu đầu vào cho từng màn (hành trình, check-in theo ngày, chuỗi ngày, thành viên, cờ ẩn chỉ số). Mở rộng `tool/gen_l10n.dart`, delegate và `l10n_test` cho `lib/personas/*/l10n/`. Helper test `pumpPersona(widget, skin:, brightness:, width:, textScale:)`. Thêm mục phong cách vào `lib/features/README.md` | — | Ai cũng build, sinh bản dịch và chạy test được trong thư mục của mình | Không |
| F2 | `activeJourneyIdProvider` và `activePersonaSkinProvider` trong `lib/app/providers.dart` (lưu ở `camera.lastJourneyId`, phong cách tính bằng `personaSkinForTemplate`). `MaterialApp.router` dùng `buildAppTheme(b, skin)` với `themeAnimationDuration` 320ms, `Curves.easeOutCubic` | — ([06](06-adaptive-persona-ui-system.md) §1) | Đổi hành trình thì màu chuyển mượt, không tải lại route. Có test provider | Không |
| F3 | Gắn 4 bộ chuyển `AnimatedSwitcher` 260ms gọi widget phong cách: `journey_detail_screen` (dòng thời gian), `capture_screen` (màn hình chụp), `share_card_screen` (thiệp chia sẻ), `group_today_screen` (bức tường ảnh nhóm). Đổi hành trình **không** khởi động lại `CameraController` | — ([06](06-adaptive-persona-ui-system.md) §1 Q1) | Đổi hành trình thì cả ba màn đổi theo; test chứng minh camera không khởi động lại | F1, F2 |
| F4 | Thanh điều hướng 3 tab theo mục 2 của `CLAUDE.md`: Journeys (biểu tượng bản đồ), nút chụp ở giữa (76pt ở màn hình chụp, viên thuốc 56×40 màu `primaryAccent` ở các màn khác), Squad (biểu tượng nhóm). Chỉ dùng biểu tượng vector | Thanh dưới của cả 6 bản | Thanh điều hướng giống nhau trên mọi màn chính và đổi màu theo phong cách | F2 |
| F5 | Widget dùng chung đọc `OurneyPersonaTheme`: `OurneyPrimaryButton` (cao 52 hoặc 44dp, nhấn thu còn 0,96 trong 110ms, có gờ dưới khi `bottomLipHeight > 0`), nút viên thuốc, `PersonaPill` (nhãn đầu màn), `PolaroidFrame` (nghiêng, có băng keo), ô chờ viền nét đứt | P1 · giữa; P2 · trái, phải; P3 · trái | Widget test đủ 6 phong cách × 2 nền. Người làm phong cách thay bản tạm | F1 |
| F6 | Helper co giãn theo mục 3 của `CLAUDE.md` (lề 16, 20 hoặc 24dp theo độ rộng, thẻ rộng tối đa 480dp). Mở rộng `theme_contrast_test` cho 6 phong cách × 2 nền, chỉnh token nếu độ tương phản chưa đạt AA | — | Test đạt, mọi cặp chữ và nền đạt AA | Không |

#### @hofang42 — Q: phong cách 1 Quiet Transformer (giảm cân)
| ID | Việc | Bản thiết kế | Xong khi | Phụ thuộc |
|---|---|---|---|---|
| Q1 | Dòng thời gian `connectedWeightCurve`: đường cong cân nặng lấy từ `metricValue`, nối vào trục dọc gồm ảnh các mốc (ngày 1, 7, 14 và hôm nay). Ẩn số khi hành trình ẩn chỉ số (FR-B7). Viết phần vẽ đường cong để R1 dùng lại | P1 · giữa | Đúng khi chưa có, có một và có nhiều điểm số liệu | Không |
| Q2 | Màn hình chụp `ghostAlignVault`: ảnh ngày đầu hiện mờ 30% (bật tắt được) để đứng đúng tư thế, nhãn `Private Vault · Day N` có biểu tượng khoá dạng vector, thanh trượt cân nặng ghi vào `metricValue` | P1 · trái | Check-in vẫn tối đa 3 chạm (FR-C4); ảnh mờ không rời khỏi máy | Không |
| Q3 | Thiệp chia sẻ `sideBySideArchive`: ảnh ngày đầu đặt cạnh ảnh hôm nay, công tắc "Ẩn số cân". Xuất qua bộ xuất ảnh hiện có (1080×1920 và 1080×1350) | P1 · phải | Mặc định ẩn số cân và làm mờ ảnh khi chia sẻ (FR-B7), người dùng tự tắt được | Không |

#### @hofang42 — R: phong cách 5 Aesthetic Flexer (30 ngày tập luyện)
| ID | Việc | Bản thiết kế | Xong khi | Phụ thuộc |
|---|---|---|---|---|
| R1 | Dòng thời gian `athleticTelemetry`: biểu đồ phát sáng và trục dọc gồm ảnh các mốc, dùng lại phần vẽ của Q1. Mẫu `workout30` không có chỉ số mặc định thì không vẽ quãng đường, chỉ vẽ trục ngày | P5 · trái | Đúng cả khi hành trình có và không có chỉ số | Q1 |
| R2 | Màn hình chụp `stravaStickerStudio`: sau khi chụp, chọn một trong ba kiểu lớp phủ (Bold HUD, Minimal Stamp, Film Strip) hiển thị ngày thứ N, chuỗi ngày và chỉ số nếu có | P5 · giữa | Đổi kiểu bằng nhãn bấm; lớp phủ không in vào ảnh gốc | Không |
| R3 | Thiệp chia sẻ `transparentStorySticker`: ảnh story dọc 9:16 kèm dải màu những ngày đã tập. Nút chia sẻ dùng bảng chia sẻ của hệ thống (đăng thẳng lên Instagram Stories là FR-E4, để sau) | P5 · phải | Dải màu đúng ngày có và không có check-in, không chỉ phân biệt bằng màu | Không |

#### @nguyenductien-qnm — S: phong cách 2 Accountability Squad (học tiếng Anh)
| ID | Việc | Bản thiết kế | Xong khi | Phụ thuộc |
|---|---|---|---|---|
| S1 | Dòng thời gian `steppingStoneQuest`: con đường chữ S dẫn tới chiếc cúp ngày cuối, ảnh Polaroid nghiêng ở các mốc. Viết phần vẽ con đường để M1 dùng lại | P2 · trái | Cuộn mượt với hơn 30 ngày; mốc 7, 14 và hôm nay hiện đúng | Không |
| S2 | Màn hình chụp `studyTimerSnap`: nhãn `số phút học · 🔥 chuỗi ngày` (số phút lấy từ chỉ số "Thời gian học") và nhãn giờ chụp | P2 · giữa | Hiện đúng số phút và chuỗi ngày; hành trình không có chỉ số thì ẩn phần số phút | Không |
| S3 | Bức tường ảnh `squadPolaroidWall`, hiện ở màn Squad hôm nay và dùng làm thiệp chia sẻ của phong cách 2: thanh `x/y đã check-in hôm nay`, lưới ảnh Polaroid 2 cột co giãn theo độ rộng, cảm xúc dùng `reaction_bar`, ô viền nét đứt "đang chờ" cho người chưa chụp. **Bản đầu chưa có nút Nudge** (FR-G3 để sau) | P2 · phải | Nhóm từ 1 đến 10 người hiện đúng; chế độ không máy chủ hiện `NeedsServerView` | Không (cần F3 để hiện trong ứng dụng) |

#### @nguyenductien-qnm — M: phong cách 3 Memory Collectors (du lịch)
| ID | Việc | Bản thiết kế | Xong khi | Phụ thuộc |
|---|---|---|---|---|
| M1 | Dòng thời gian `scrapbookThread`: đường chỉ khâu màu đất nung nối những ảnh Polaroid dán băng keo, dùng lại phần vẽ của S1 | P3 · trái | Cuộn mượt với hơn 30 ngày | S1 |
| M2 | Màn hình chụp `disposableFilmStamp`: nhãn `FILM ROLL n/N` (n là số lần check-in, N là số ngày), dấu ngày màu hổ phách kiểu máy ảnh film | P3 · giữa | Dấu ngày chỉ là lớp phủ, không in vào ảnh (giữ nguyên quy trình nén ảnh FR-C5). Không hiện nhiệt độ và địa điểm vì thiếu dữ liệu | Không |
| M3 | Thiệp chia sẻ `filmContactSheet`: dải phim 35mm nền tối, tối đa 20 khung, có số khung | P3 · phải | Hành trình nhóm chỉ chia sẻ bằng ảnh, không bao giờ có link công khai (FR-E3) | Không |

#### @lken1514 — D: phong cách 4 Couple Rituals (cặp đôi)
| ID | Việc | Bản thiết kế | Xong khi | Phụ thuộc |
|---|---|---|---|---|
| D1 | Dữ liệu trong `lib/data/`: check-in của nhóm theo từng ngày và ảnh hôm nay của các thành viên khác, có provider và test (dùng cho D2, D3; S3 dùng được nếu cần) | — | Test với nhóm 2 người và nhóm 10 người; chế độ không máy chủ trả về rỗng | Không |
| D2 | Dòng thời gian `duoSplitTimeline`: mỗi ngày một đôi ảnh của hai thành viên, biểu tượng tim hoặc lửa ở giữa, thiếu ảnh một bên thì hiện ô chờ. Dùng tên hiển thị, không ghi "His/Her" | P4 · trái | Hành trình nhóm 2 người hiện đủ từng đôi ảnh theo ngày | D1 |
| D3 | Màn hình chụp `halfFrameDuo`: nửa trái là ảnh hôm nay của người kia, nửa phải là khung ngắm. Người kia chưa chụp thì nửa trái là ô chờ | P4 · giữa | Thấy được ảnh của người kia; ảnh của mình vẫn lưu đủ khung | D1 |
| D4 | Thiệp chia sẻ `coupleMosaicPoster`: lưới ảnh của hai người kèm dòng `N ngày · M khoảnh khắc` | P4 · phải | Không bao giờ có link công khai (FR-E3) | Không |

#### @zacknguyn — Z: phong cách 6 Minimalist Habit (thói quen tự đặt)
| ID | Việc | Bản thiết kế | Xong khi | Phụ thuộc |
|---|---|---|---|---|
| Z1 | Dòng thời gian `chainCalendarGrid`: lưới 7 cột, ô ảnh vuông nối bằng một đường cam liền mạch, ngày lỡ hoặc chưa tới là ô viền nét đứt (FR-B4). Dựa trên `features/journeys/ui/timeline_grid.dart` hiện có, không sửa tệp đó | P6 · giữa | Lưới đúng ngày theo `local_date` | Không |
| Z2 | Màn hình chụp `zeroText3Sec`: một nhãn duy nhất, nút chụp màu cam, đăng mà không cần nhập chú thích | P6 · trái | Đăng bằng một chạm, chú thích vẫn sửa được sau | Không |
| Z3 | Thiệp chia sẻ `zenSummaryCard`: `x/N ngày`, phần trăm đều đặn và một ảnh vuông. Xuất qua bộ xuất ảnh hiện có | P6 · phải | Xuất đúng 2 cỡ, tệp dưới 1MB, dấu tiếng Việt hiển thị đúng | Không |

#### @zacknguyn — J: trang hành trình và màn tạo hành trình
| ID | Việc | Bản thiết kế | Xong khi | Phụ thuộc |
|---|---|---|---|---|
| J1 | Trang hành trình (Hub) trên nền trung tính (`editorialNeutralBase`). Mỗi `JourneyCard` có huy hiệu mang màu phong cách và emoji. Chạm thẻ thì đặt hành trình đó làm hành trình đang chọn | — ([06](06-adaptive-persona-ui-system.md) §1 Q2) | Hiển thị đúng ở nền sáng và nền tối, với 0, 1 và 3 hành trình | F2 |
| J2 | Màn tạo hành trình có xem trước trực tiếp: 6 thẻ phong cách (5 mẫu, cộng Couple là mẫu `custom` cho nhóm 2 người hoặc có emoji 💞, theo `personaSkinForTemplate`). Chạm thẻ nào thì màn đổi màu ngay và hiện ảnh xem trước `designAssetPath` của thẻ đó | Cả 6 bản (ảnh xem trước) | Chọn thẻ thì màu đổi trong 320ms; hành trình tạo ra đúng mẫu | F2 |

## 4. Lịch

| Người | Tuần 1 | Tuần 2 | Tuần 3 |
|---|---|---|---|
| @thydynh03 | F1, F2 | F3, F4 | F5, F6 |
| @hofang42 | Q1, Q2 | Q3, R1 | R2, R3 |
| @nguyenductien-qnm | S1, S2 | S3, M1 | M2, M3 |
| @lken1514 | D1 | D2, D3 | D4 |
| @zacknguyn | Z1, Z2 | Z3, J1 | J2 |

Sang tuần thứ 4, cả nhóm ghép các phần lại, thử đổi hành trình trên iPhone và Android thật, rồi cùng rà lỗi trên đủ 6 phong cách với cả hai nền trước khi phát hành.
