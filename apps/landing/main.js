(() => {
  const root = document.documentElement;
  root.classList.add('js');
  const $ = (id) => document.getElementById(id);
  const reduceMotionMql = matchMedia('(prefers-reduced-motion: reduce)');
  const isReducedMotion = () => reduceMotionMql.matches;
  const darkMql = matchMedia('(prefers-color-scheme: dark)');

  /* --- 1. Bilingual Copy Dictionary (vi default + en) --- */
  const COPY = {
    vi: {
      title: 'ourney · chụp một tấm. giữ một chuỗi. — nhật ký ảnh mỗi ngày',
      meta_desc: 'Ourney là nhật ký ảnh mỗi ngày cho điều bạn muốn kiên trì: học ngoại ngữ, chạy bộ, giảm cân, chuyến đi hay thói quen nhỏ — đi một mình hoặc cùng nhóm bạn.',
      og_title: 'ourney · chụp một tấm. giữ một chuỗi. đi cùng nhau.',
      og_image: 'https://ourney.tech/assets/og/og-default.png',
      og_image_alt: 'Ourney — Nhật ký ảnh mỗi ngày: chụp một tấm, giữ một chuỗi, đi cùng nhau trên iOS và Android',
      og_url: 'https://ourney.tech/',
      og_locale: 'vi_VN',
      og_locale_alt: 'en_US',
      skip: 'Bỏ qua tới nội dung chính',
      nav_brand_aria: 'Ourney, về đầu trang',
      nav_main_aria: 'Điều hướng chính',
      nav_journeys: 'hành trình',
      nav_how: 'cách dùng',
      nav_squad: 'nhóm',
      nav_privacy: 'riêng tư',
      nav_faq: 'hỏi đáp',
      nav_cta: 'nhận lời mời',
      nav_lang_aria: 'Chuyển ngôn ngữ sang tiếng Anh',
      nav_theme_aria: 'Đổi giao diện sáng hoặc tối',
      stamp_1: 'chụp một tấm.',
      stamp_2: 'giữ một chuỗi.',
      stamp_3: 'đi cùng nhau.',
      hero_ticket_aria: 'Vé khởi hành Beta cho iOS và Android',
      ticket_kicker: 'VÉ KHỞI HÀNH · BETA',
      ticket_title: 'iOS & Android',
      ticket_sub: 'Bấm để giữ chỗ Ngày\u00A01',
      hero_phone_alt: 'Màn hành trình của app Ourney: thẻ chuỗi 21 ngày, hành trình IELTS 7.5 ngày 21/30 và nút Chụp hôm nay',
      hcc_t0: 'IELTS 7.5 · Ngày 21/30',
      hcc_b0_pre: 'chuỗi 20 ngày',
      hcc_b0: 'chuỗi 21 ngày',
      hcc_t1: 'Chạy sáng · 5,4 km',
      hcc_b1: '20/30 buổi',
      hcc_t2: 'Đà Lạt 7\u00A0ngày · Khung 14/24',
      hcc_b2: 'cả nhóm đã chụp',
      hero_h1: 'chụp một tấm. giữ một chuỗi.',
      hero_lede: 'Nhật ký ảnh mỗi ngày cho điều bạn muốn kiên trì — học tiếng Anh, chạy bộ, giảm cân, một chuyến đi hay thói quen nhỏ. Đi một mình hoặc rủ cả nhóm.',
      hero_cta_primary: 'nhận lời mời beta',
      hero_cta_secondary: 'xem 6 giao diện',
      hero_scroll_aria: 'Cuộn xuống xem 6 giao diện',
      dock_cta_aria: 'Nhận lời mời beta',
      dock_cta_text: 'Ngày 1 bắt đầu hôm nay.',
      dock_cta_btn: 'nhận lời mời',
      j_eyebrow: 'mỗi hành trình một thế giới',
      j_h2: 'bước vào là đổi hẳn chất liệu.',
      j_intro: 'Không nhốt mọi mục tiêu vào một lưới lịch giống hệt nhau. Học tiếng Anh là đường quest tới chiếc cúp, chạy bộ là biểu đồ km, chuyến đi là cuộn phim dán băng keo. Chạm thử từng kiểu bên dưới.',
      j_tablist_aria: 'Chọn giao diện hành trình',
      j_tab_0: 'IELTS 7.5',
      j_tab_1: 'Chạy sáng',
      j_tab_2: 'Đà Lạt 7\u00A0ngày',
      j_tab_3: '30\u00A0ngày cơ thể',
      j_tab_4: 'Tụi mình',
      j_tab_5: 'Đọc 10\u00A0trang',
      cs_pill: 'CẶP ĐÔI · RIÊNG TƯ',
      cs_sub: 'mỗi ngày hai nửa ghép lại.',
      cs_title: 'tụi mình.',
      cs_stat: '18 NGÀY BÊN NHAU · 36 KHOẢNH KHẮC',
      cs_stat_sub: 'Cả hai đã chụp đủ hôm nay',
      cs_d18: 'NGÀY 18 · HÔM NAY',
      cs_d17: 'NGÀY 17 · HÔM QUA',
      cs_nam: 'Nam · 07:30',
      cs_linh: 'Linh · 08:12',
      how_eyebrow: 'cách dùng',
      how_h2: 'ba bước, chưa tới mười giây.',
      how_s1_t: 'chọn kiểu, đúc vé khởi hành.',
      how_s1_d: 'Vuốt 6 mẫu hành trình, trả lời 2–3 câu ngắn để app tạo màu sắc, tên cột mốc và tấm vé khởi hành mang dấu ấn riêng của bạn.',
      how_s1_alt: 'Bước 1/5: Chọn kiểu hành trình, thẻ Giảm cân',
      how_s2_t: 'mở nút giữa, chụp một tấm.',
      how_s2_d: 'Nút chụp nằm ngay giữa thanh dưới. Nhấn giữ để xoay vòng chọn hành trình chưa chụp hôm nay, bấm chụp rồi bấm Đăng — xong trong 3 chạm.',
      how_s2_alt: 'Màn camera: Mỗi ngày một tấm ảnh, Đọc 10 trang ngày 24/30',
      how_s3_t: 'giữ liền chuỗi, khoe khi muốn.',
      how_s3_d: 'Mỗi ngày nối thêm một mắt xích vào hành trình. Bất cứ lúc nào, xuất ngay thẻ Story 9:16 hoặc 4:5 có sẵn số liệu của bạn.',
      how_s3_alt: 'Thẻ chia sẻ Story của hành trình Chạy sáng: 4,6 km, ngày 21',
      squad_eyebrow: 'đi cùng nhóm',
      squad_h2: 'một mình dễ quên. có hội thì giữ được.',
      squad_desc: 'Mời tối đa 10 người bạn thân bằng mã 8 ký tự — không bảng xếp hạng độc hại, không đếm người theo dõi. Mở app là thấy tường Polaroid hôm nay ai đã điểm danh, thả cảm xúc hoặc nhắc nhẹ đứa còn thiếu.',
      squad_chip_1: 'Tối đa 10 bạn · Mã mời 8 ký tự',
      squad_chip_2: 'Chạm thả cảm xúc trực tiếp bên cạnh',
      squad_wall_title: 'IELTS 7.5 · HỘI 4 NGƯỜI',
      squad_wall_prog: '3/4 đã chụp hôm nay',
      sq_c1_cap: '“45 phút Reading xong!”',
      sq_c2_cap: '“Ngày 21 không gãy chuỗi”',
      sq_c3_cap: '“Thêm 30 từ mới vào sổ”',
      sq_c4_time: 'còn 4 giờ',
      sq_c4_wait: 'chưa có ảnh hôm nay',
      sq_c4_nudged: 'đã nhận lời nhắc từ nhóm',
      sq_nudge_btn: 'Nhắc Minh',
      sq_nudge_done: 'Đã nhắc Minh giữ chuỗi!',
      finish_eyebrow: 'về đích',
      finish_h2: 'hết chặng đường, cầm về một kỷ vật.',
      finish_desc: 'Chuyến đi khép lại thành tấm poster cuộn phim 35mm. Ba mươi ngày chạy bộ mở ra câu chuyện tổng kết Wrapped nhìn lại trọn vẹn từng ngày bạn đã không bỏ cuộc.',
      finish_tick_1: 'Khổ Story 9:16 và bài đăng 4:5 sắc nét',
      finish_tick_2: 'Tự chọn in chuỗi liên tiếp hay tổng số ngày',
      finish_tick_3: 'Ẩn bất kỳ con số nhạy cảm nào trước khi xuất',
      finish_a_alt: 'Poster chuyến đi Đà Lạt 7 ngày với cuộn phim các ngày',
      finish_b_alt: 'Hành trình đã về đích: 20 khoảnh khắc trong 20 ngày',
      priv_eyebrow: 'riêng tư & trên máy',
      priv_h2: 'có những hành trình chỉ dành cho riêng bạn.',
      priv_desc: 'Bạn chọn quyền xem riêng cho từng hành trình. Với hành trình giảm cân, số kg luôn được che thành dấu chấm — nhấn giữ bên dưới để thử.',
      priv_vis_1: 'Chỉ mình tôi',
      priv_vis_2: 'Ai có link',
      priv_vis_3: 'Thành viên nhóm',
      priv_hold_label: 'Cân nặng hôm nay',
      priv_dec_sep: ',',
      priv_masked_sr: 'Đã ẩn số cân',
      priv_hold_revealed: '62,0 kg (-3,2 kg so với Ngày 1)',
      priv_hold_btn: 'Giữ để xem',
      priv_tg1_t: 'Ẩn con số với người khác',
      priv_tg1_d: 'Chỉ hiện ảnh check-in, giấu số kg hoặc số phút.',
      priv_tg2_t: 'Làm mờ ảnh khi chia sẻ link',
      priv_tg2_d: 'Ảnh xem trước bên ngoài được làm mờ tự động.',
      priv_preview_kicker: 'Xem trước thẻ chia sẻ ra ngoài',
      priv_preview_title: '30 ngày cơ thể · Ngày 21',
      priv_preview_hidden: 'Đã ẩn số kg',
      priv_preview_shown: '62,0 kg (-3,2 kg)',
      priv_local_chip: 'Chế độ chỉ trên máy: dùng trọn vẹn hành trình cá nhân khi mất mạng, không cần tạo tài khoản.',
      priv_phone_alt: 'Hành trình 30 ngày cơ thể: Nhìn lại từng chút một, biểu đồ cân nặng với con số bị ẩn, Giữ để xem',
      faq_eyebrow: 'hỏi đáp',
      faq_h2: 'vài câu chắc bạn sẽ hỏi.',
      faq_q1: 'Không có mạng hay chưa muốn đăng ký thì dùng được không?',
      faq_a1: 'Được ngay. Ourney có chế độ chỉ trên máy: ảnh và chuỗi nằm ngay trên điện thoại của bạn, hành trình một mình hoạt động đầy đủ. Bạn chỉ cần đăng nhập khi muốn đồng bộ đám mây hoặc đi cùng nhóm.',
      faq_q2: 'Một nhóm tối đa bao nhiêu người? Vào muộn có thiệt không?',
      faq_a2: 'Mỗi hành trình nhóm tối đa 10 người, tham gia bằng mã mời 8 ký tự. Tiến độ của người vào sau được tính công bằng từ ngày họ tham gia, đồng thời vẫn xem lại được toàn bộ kỷ niệm trước đó của nhóm.',
      faq_q3: 'Ai có thể xem ảnh và chỉ số của tôi?',
      faq_a3: 'Mỗi hành trình có cài đặt riêng: Chỉ mình tôi, Ai có link, hoặc Thành viên trong nhóm. Ngay cả khi chia sẻ, bạn vẫn bật tắt được việc ẩn con số theo dõi và làm mờ ảnh xem trước.',
      faq_q4: 'Một ngày chụp nhiều tấm hay nhập hành trình cũ có được không?',
      faq_a4: 'Chụp nhiều tấm trong ngày sẽ gom gọn vào ngày hôm đó (chuỗi vẫn tính 1 ngày). Bạn cũng có thể nhập ảnh từ chuyến đi đã qua theo ngày chụp — app sẽ xếp thành timeline kỷ niệm mà không làm sai lệch chuỗi ngày thực tế.',
      faq_q5: 'Khi nào Ourney mở tải trên iOS và Android?',
      faq_a5: 'Ourney được phát triển đồng thời bằng Flutter cho cả iOS và Android. Để lại email ở vé bên dưới để nhận lời mời thử nghiệm beta đợt đầu tiên cho iOS và Android.',
      beta_eyebrow: 'beta sắp mở cửa',
      beta_h2: 'ngày 1 của bạn bắt đầu từ hôm nay.',
      beta_plat_aria: 'Chọn nền tảng điện thoại',
      beta_email_label: 'Email',
      beta_placeholder: 'ban@email-cua-ban.vn',
      beta_submit: 'nhận lời mời',
      beta_stub_kicker: 'NGÀY 01',
      beta_stub_title: 'VÉ BETA',
      form_err: 'Email chưa đúng định dạng — bạn kiểm tra lại giúp nhé.',
      form_ok: 'Đã ghi nhận trên bản xem trước! Tụi mình sẽ mở cổng đăng ký beta chính thức cho iOS & Android thật sớm.',
      footer_tagline: 'chụp một tấm. giữ một chuỗi. đi cùng nhau.',
      footer_journeys: 'hành trình',
      footer_privacy: 'riêng tư',
      footer_faq: 'hỏi đáp',
      footer_beta: 'nhận lời mời',
      nf_title: 'ourney · 404 — lạc đường một nhịp.',
      nf_brand_aria: 'Ourney, về trang chủ',
      nf_eyebrow: '404 · không tìm thấy trang',
      nf_h1: 'lạc đường một nhịp.',
      nf_lede: 'Trang bạn mở không tồn tại hoặc đã đổi địa chỉ. Quay về trang chủ để tiếp tục hành trình Ngày\u00A01 cùng Ourney.',
      nf_cta: 'về trang chủ ourney'
    },
    en: {
      title: 'ourney · snap one photo. keep one streak. — photo journal',
      meta_desc: 'Ourney is a daily photo journal for what you want to stick with: language study, running, weight loss, a trip, or a small habit — solo or with a close squad.',
      og_title: 'ourney · snap one photo. keep one streak. go together.',
      og_image: 'https://ourney.tech/assets/og/og-default-en.png',
      og_image_alt: 'Ourney — Daily photo journal: snap one photo, keep one streak, go together on iOS and Android',
      og_url: 'https://ourney.tech/?lang=en',
      og_locale: 'en_US',
      og_locale_alt: 'vi_VN',
      skip: 'Skip to main content',
      nav_brand_aria: 'Ourney, back to top',
      nav_main_aria: 'Main navigation',
      nav_journeys: 'journeys',
      nav_how: 'how it works',
      nav_squad: 'squads',
      nav_privacy: 'privacy',
      nav_faq: 'faq',
      nav_cta: 'get invite',
      nav_lang_aria: 'Switch language to Vietnamese',
      nav_theme_aria: 'Toggle light or dark theme',
      stamp_1: 'snap one photo.',
      stamp_2: 'keep one streak.',
      stamp_3: 'go together.',
      hero_ticket_aria: 'Beta Departure Pass for iOS and Android',
      ticket_kicker: 'DEPARTURE PASS · BETA',
      ticket_title: 'iOS & Android',
      ticket_sub: 'Tap to claim your Day\u00A01',
      hero_phone_alt: 'Ourney app Hub screen: 21-day streak card, IELTS 7.5 Day 21/30 card, and Snap Today CTA',
      hcc_t0: 'IELTS 7.5 · Day 21/30',
      hcc_b0_pre: '20-day streak',
      hcc_b0: '21-day streak',
      hcc_t1: 'Morning Run · 5.4 km',
      hcc_b1: '20/30 sessions',
      hcc_t2: 'Da Lat 7\u00A0Days · Frame 14/24',
      hcc_b2: 'all 5 checked in',
      hero_h1: 'snap one photo. keep one streak.',
      hero_lede: 'A daily photo journal for what you want to stick with — studying, running, body goals, a trip, or a tiny habit. Go solo or bring your squad.',
      hero_cta_primary: 'get beta invite',
      hero_cta_secondary: 'see 6 skins',
      hero_scroll_aria: 'Scroll down to explore 6 skins',
      dock_cta_aria: 'Get beta invite',
      dock_cta_text: 'Day 1 starts today.',
      dock_cta_btn: 'get invite',
      j_eyebrow: 'every journey is its own world',
      j_h2: 'step inside and the whole material shifts.',
      j_intro: 'No single generic calendar grid for everything. Studying becomes a quest trail to a trophy, running becomes a pace sparkline, and a trip becomes a taped 35mm film roll. Tap each skin below.',
      j_tablist_aria: 'Choose journey skin',
      j_tab_0: 'IELTS 7.5',
      j_tab_1: 'Morning Run',
      j_tab_2: 'Da Lat 7\u00A0Days',
      j_tab_3: '30-Day Body',
      j_tab_4: 'Just Us Two',
      j_tab_5: 'Read 10\u00A0Pages',
      cs_pill: 'COUPLE · PRIVATE VAULT',
      cs_sub: 'two halves of the same day.',
      cs_title: 'just us two.',
      cs_stat: '18 DAYS TOGETHER · 36 MOMENTS',
      cs_stat_sub: 'Both partners checked in today',
      cs_d18: 'DAY 18 · TODAY',
      cs_d17: 'DAY 17 · YESTERDAY',
      cs_nam: 'Nam · 07:30',
      cs_linh: 'Linh · 08:12',
      how_eyebrow: 'how it works',
      how_h2: 'three steps, under ten seconds.',
      how_s1_t: 'pick a type, mint your pass.',
      how_s1_d: 'Swipe 6 journey templates and answer 2–3 quick prompts so Ourney tailors your palette, milestone names, and departure ticket.',
      how_s1_alt: 'Step 1 of 5: Choose journey type, Weight Loss card',
      how_s2_t: 'tap center shutter, snap once.',
      how_s2_d: 'The shutter lives right at the center of the dock. Long-press to spin the journey wheel, snap your moment, and tap Post — done in 3 taps.',
      how_s2_alt: 'Camera screen: One photo a day, Read 10 Pages Day 24/30',
      how_s3_t: 'keep the chain, share on your terms.',
      how_s3_d: 'Every photo links another day onto your timeline. Whenever you feel proud, export a 9:16 Story or 4:5 card with the stats you choose.',
      how_s3_alt: 'Story share card for Morning Run: 4.6 km, Day 21',
      squad_eyebrow: 'accountability squads',
      squad_h2: 'solo fades fast. squads stick together.',
      squad_desc: 'Invite up to 10 close friends with an 8-character code — no public follower counts, no toxic leaderboards. Open the app to see today’s Polaroid wall, drop sticker reactions, or nudge whoever hasn’t snapped yet.',
      squad_chip_1: 'Up to 10 friends · 8-char invite code',
      squad_chip_2: 'Tap sticker reactions on the board',
      squad_wall_title: 'IELTS 7.5 · SQUAD OF 4',
      squad_wall_prog: '3/4 snapped today',
      sq_c1_cap: '“45 min Reading done!”',
      sq_c2_cap: '“Day 21 streak intact”',
      sq_c3_cap: '“Added 30 new vocab words”',
      sq_c4_time: '4h left',
      sq_c4_wait: 'waiting for today’s snap',
      sq_c4_nudged: 'streak nudge received',
      sq_nudge_btn: 'Nudge Minh',
      sq_nudge_done: 'Streak nudge sent to Minh!',
      finish_eyebrow: 'finish line',
      finish_h2: 'finish a journey, keep a keepsake.',
      finish_desc: 'A trip wraps into a 35mm contact-sheet poster. Thirty days of running unlocks a multi-card Wrapped recap celebrating every day you showed up.',
      finish_tick_1: 'Crisp 9:16 Story and 4:5 Feed formats',
      finish_tick_2: 'Print your active streak or total days completed',
      finish_tick_3: 'Hide any sensitive metric before exporting',
      finish_a_alt: 'Da Lat 7-day trip poster with 35mm film strip frames',
      finish_b_alt: 'Completed journey Wrapped card: 20 moments in 20 days',
      priv_eyebrow: 'privacy & local-first',
      priv_h2: 'some journeys belong only to you.',
      priv_desc: 'Set visibility independently per journey. On body & weight journeys, exact numbers stay masked behind dots — press and hold below to try it.',
      priv_vis_1: 'Only me',
      priv_vis_2: 'Anyone with link',
      priv_vis_3: 'Squad members',
      priv_hold_label: 'Today’s weight',
      priv_dec_sep: '.',
      priv_masked_sr: 'Weight number masked',
      priv_hold_revealed: '62.0 kg (-3.2 kg since Day 1)',
      priv_hold_btn: 'Hold to reveal',
      priv_tg1_t: 'Hide metrics from others',
      priv_tg1_d: 'Friends see your photo, never your weight or minutes.',
      priv_tg2_t: 'Blur photo on external links',
      priv_tg2_d: 'Link preview thumbnails blur automatically.',
      priv_preview_kicker: 'External share card preview',
      priv_preview_title: '30-Day Body · Day 21',
      priv_preview_hidden: 'Weight hidden',
      priv_preview_shown: '62.0 kg (-3.2 kg)',
      priv_local_chip: 'On-device mode: run solo journeys 100% offline on your phone — no account required.',
      priv_phone_alt: '30-Day Body journey: weight trend curve with masked numbers and Hold to view button',
      faq_eyebrow: 'faq',
      faq_h2: 'a few things you might ask.',
      faq_q1: 'Can I use Ourney offline or without creating an account?',
      faq_a1: 'Yes. Ourney includes a full local-only mode: your photos and streaks live right on your phone, and solo journeys work offline. Sign in only when you want cloud backup or squad journeys.',
      faq_q2: 'How big can a squad be, and what if someone joins late?',
      faq_a2: 'Up to 10 people per squad journey via an 8-character invite code. Late joiners track consistency fairly from the day they join while still seeing the squad’s full timeline.',
      faq_q3: 'Who can see my check-in photos and numbers?',
      faq_a3: 'Each journey has its own privacy setting: Only me, Anyone with link, or Squad members. Even on shared journeys, you can hide exact metrics and blur external link previews.',
      faq_q4: 'Can I snap multiple photos a day or import a past trip?',
      faq_a4: 'Multiple photos on the same day group cleanly into that day while counting once toward your streak. You can also import past trip photos by capture date into a keepsake timeline without inflating live streaks.',
      faq_q5: 'When will Ourney launch on iOS and Android?',
      faq_a5: 'Ourney is built for both iOS and Android. Drop your email on the ticket below to get first-wave iOS and Android beta invites.',
      beta_eyebrow: 'beta opening soon',
      beta_h2: 'your day 1 starts today.',
      beta_plat_aria: 'Select phone platform',
      beta_email_label: 'Email',
      beta_placeholder: 'you@example.com',
      beta_submit: 'get beta invite',
      beta_stub_kicker: 'DAY 01',
      beta_stub_title: 'BETA PASS',
      form_err: 'That email doesn’t look right — please check and try again.',
      form_ok: 'Noted in preview mode! Official iOS & Android beta waitlist storage opens very soon.',
      footer_tagline: 'snap one photo. keep one streak. go together.',
      footer_journeys: 'journeys',
      footer_privacy: 'privacy',
      footer_faq: 'faq',
      footer_beta: 'get invite',
      nf_title: 'ourney · 404 — off the trail for a beat.',
      nf_brand_aria: 'Ourney, back to home',
      nf_eyebrow: '404 · page not found',
      nf_h1: 'off the trail for a beat.',
      nf_lede: 'The page you opened doesn’t exist or has moved. Head back home to continue your Day\u00A01 journey with Ourney.',
      nf_cta: 'back to ourney home'
    }
  };

  /* --- 2. 6-Persona Chameleon Data (Section 2) --- */
  const JOURNEYS = [
    {
      skin: 'squad', screen: 'j-ielts', no: '01',
      vi: {
        label: 'IELTS 7.5', kind: 'học tiếng Anh · Accountability Squad',
        title: 'hôm nay học bao lâu.',
        desc: 'Đường quest uốn lượn dẫn tới chiếc cúp ngày 30 do bạn tự đặt tên. Mỗi buổi học đính thêm một tấm ảnh lên đường đi.',
        chips: ['Con đường cúp', '45 phút/ngày', 'Nhóm 5 người'],
        alt: 'Trang hành trình IELTS 7.5 trong app Ourney'
      },
      en: {
        label: 'IELTS 7.5', kind: 'study · Accountability Squad',
        title: 'how long did you study today.',
        desc: 'A winding quest path leading to a Day 30 trophy you name yourself. Every study session pins a real photo checkpoint along the trail.',
        chips: ['Quest trail', '45 min/day', 'Squad of 5'],
        alt: 'IELTS 7.5 journey screen in Ourney app'
      }
    },
    {
      skin: 'flexer', screen: 'j-run', no: '02',
      vi: {
        label: 'Chạy sáng', kind: 'tập luyện · Aesthetic Flexer',
        title: 'mỗi buổi chạy một vạch.',
        desc: 'Quãng đường từng buổi nối thành biểu đồ sống động, tiến độ 20/30 hiện ngay đầu trang và sẵn sàng xuất thành thẻ Story trong suốt.',
        chips: ['Biểu đồ km', 'Kính mờ neon', 'Story 9:16'],
        alt: 'Trang hành trình Chạy sáng trong app Ourney'
      },
      en: {
        label: 'Morning Run', kind: 'workout · Aesthetic Flexer',
        title: 'every session leaves a mark.',
        desc: 'Daily kilometers plot into a crisp sparkline with 20/30 progress right on top — ready to export as a transparent 9:16 Story card.',
        chips: ['Pace sparkline', 'Neon glass', '9:16 Story'],
        alt: 'Morning Run journey screen in Ourney app'
      }
    },
    {
      skin: 'memory', screen: 'j-travel', no: '03',
      vi: {
        label: 'Đà Lạt 7\u00A0ngày', kind: 'chuyến đi · Memory Collectors',
        title: 'hôm nay cả bọn lạc ở đâu.',
        desc: 'Cuộn phim 24 khung trên nền giấy hạt ấm. Ảnh mỗi ngày dán băng keo dọc sợi chỉ khâu, hết chuyến tự đóng gói thành poster 35mm.',
        chips: ['Chỉ khâu & băng keo', 'Cuộn 24 tấm', 'Poster 35mm'],
        alt: 'Trang hành trình Đà Lạt 7 ngày trong app Ourney'
      },
      en: {
        label: 'Da Lat 7\u00A0Days', kind: 'trip · Memory Collectors',
        title: 'where did we get lost today.',
        desc: 'A 24-frame roll on warm grain paper. Daily Polaroids tape along a stitched thread and pack into a 35mm contact-sheet poster at the end.',
        chips: ['Stitched scrapbook', '24-frame roll', '35mm poster'],
        alt: 'Da Lat 7 Days trip screen in Ourney app'
      }
    },
    {
      skin: 'quiet', screen: 'j-weight', no: '04',
      vi: {
        label: '30\u00A0ngày cơ thể', kind: 'giảm cân · Quiet Transformer',
        title: 'nhìn lại từng chút một.',
        desc: 'Êm ái và riêng tư mặc định. Đường xu hướng vẫn nối đều qua từng mốc ngày, nhưng con số cân nặng luôn ẩn sau thao tác giữ ngón tay.',
        chips: ['Riêng tư mặc định', 'Khung căn dáng', 'Giữ để xem kg'],
        alt: 'Trang hành trình 30 ngày cơ thể trong app Ourney'
      },
      en: {
        label: '30-Day Body', kind: 'weight & body · Quiet Transformer',
        title: 'notice every quiet shift.',
        desc: 'Calm and private by default. Your trend curve connects milestone photos smoothly while exact numbers stay masked until you press and hold.',
        chips: ['Private vault', 'Day-1 ghost guide', 'Hold to view kg'],
        alt: '30-Day Body journey screen in Ourney app'
      }
    },
    {
      skin: 'couple', screen: null, no: '05',
      vi: {
        label: 'Tụi mình', kind: 'cặp đôi · Couple Rituals',
        title: 'mỗi ngày hai nửa ghép lại.',
        desc: 'Mỗi ngày là một khung ảnh đôi đặt cạnh nhau: người chụp trước nằm chờ ở góc ống kính để người kia chụp nốt nửa còn lại.',
        chips: ['Khung ảnh đôi', 'Ảnh góc PiP', 'Chỉ hai người'],
        alt: 'Trang hành trình Cặp đôi Tụi mình trong app Ourney: 18 ngày bên nhau, khung ảnh đôi của Nam và Linh'
      },
      en: {
        label: 'Just Us Two', kind: 'couple · Couple Rituals',
        title: 'two halves of the same day.',
        desc: 'Each day pairs both partners side by side: whoever snaps first appears as a corner picture-in-picture guide while the other completes the pair.',
        chips: ['Paired diptych', 'Partner PiP', '2-person vault'],
        alt: 'Just Us Two couple journey screen in Ourney app: 18 days together, paired daily photos from Nam and Linh'
      }
    },
    {
      skin: 'minimal', screen: 'j-minimal', no: '06',
      vi: {
        label: 'Đọc 10\u00A0trang', kind: 'tự đặt · Minimalist Habit',
        title: 'một ô mỗi ngày.',
        desc: 'Lưới lịch 7 cột tinh gọn, không chi tiết thừa: không ô nhập chữ rườm rà, một chạm chụp là nối liền sợi dây cam không đứt quãng.',
        chips: ['Lưới 7 cột', 'Chụp 3 giây', 'Mốc 7 · 15 · 30'],
        alt: 'Trang hành trình Đọc 10 trang trong app Ourney'
      },
      en: {
        label: 'Read 10\u00A0Pages', kind: 'custom habit · Minimalist Habit',
        title: 'one square a day.',
        desc: 'A clean, distraction-free 7-column calendar grid: zero text friction, one shutter tap links today’s square onto an unbroken orange chain.',
        chips: ['7-col chain', '3-sec check-in', 'Day 7 · 15 · 30'],
        alt: 'Read 10 Pages custom habit screen in Ourney app'
      }
    }
  ];

  const HERO_CYCLES = [
    { streak: '21', fire: '4', clap: '3' },
    { streak: '20', fire: '6', clap: '2' },
    { streak: '7',  fire: '5', clap: '4' }
  ];

  /* Resolve initial language strictly inside main.js so no-JS / failed-JS stays truthful to static VI HTML */
  let curLang = 'vi';
  try {
    const q = new URLSearchParams(location.search).get('lang');
    const saved = localStorage.getItem('ourney-lang');
    if (q === 'en' || q === 'vi') curLang = q;
    else if (saved === 'en' || saved === 'vi') curLang = saved;
  } catch (e) {}

  const is404 = Boolean(document.querySelector('.notfound-stage'));
  let curTab = 0;
  let curHeroCycle = 0;
  let minhNudged = false;
  let streakTicked = isReducedMotion() || root.classList.contains('intro-seen');

  /* --- 3. Theme Resolution & <picture> Source Media Sync --- */
  const isDark = () => root.dataset.theme ? root.dataset.theme === 'dark' : darkMql.matches;
  const syncThemePictures = () => {
    const dark = isDark();
    const mediaVal = root.dataset.theme ? (dark ? 'all' : 'not all') : '(prefers-color-scheme: dark)';
    document.querySelectorAll('source.src-dark').forEach((s) => { s.media = mediaVal; });
    const metaL = $('meta-theme-light'), metaD = $('meta-theme-dark');
    if (metaL && metaD) {
      if (root.dataset.theme) {
        const hex = dark ? '#1B1916' : '#FFF8EE';
        metaL.content = hex;
        metaD.content = hex;
      } else {
        metaL.content = '#FFF8EE';
        metaD.content = '#1B1916';
      }
    }
  };
  syncThemePictures();

  const themeToggle = $('theme-toggle');
  if (themeToggle) {
    themeToggle.addEventListener('click', () => {
      const next = isDark() ? 'light' : 'dark';
      root.dataset.theme = next;
      try { localStorage.setItem('ourney-theme', next); } catch (e) {}
      syncThemePictures();
    });
  }
  darkMql.addEventListener('change', syncThemePictures);

  /* --- 4. First-Load Intro Skip & Clean Settle Disarm --- */
  let streakTickTimer = null;
  const markIntroSeen = () => {
    try { sessionStorage.setItem('ourney-intro-seen', '1'); } catch (e) {}
  };
  const settleHero = () => {
    root.classList.add('hero-settled');
    markIntroSeen();
  };

  if (!is404 && !root.classList.contains('intro-seen') && !isReducedMotion()) {
    const skipEvents = ['wheel', 'touchmove', 'pointerdown', 'keydown'];
    const disarmSkip = () => {
      skipEvents.forEach((ev) => removeEventListener(ev, skipIntro));
    };
    function skipIntro() {
      disarmSkip();
      clearTimeout(streakTickTimer);
      root.classList.add('intro-skip', 'hero-settled');
      streakTicked = true;
      renderHeroCycle(curHeroCycle);
      markIntroSeen();
    }
    skipEvents.forEach((ev) => addEventListener(ev, skipIntro, { once: true, passive: true }));
    setTimeout(disarmSkip, 1100);
    setTimeout(settleHero, 2020);
  } else if (!is404) {
    setTimeout(settleHero, 420);
  }

  /* --- 5. Hero Live Check-In Card Streak Flip & 3.6s Cycle --- */
  const heroSec = $('hero');
  const checkinCard = $('hero-checkin-card');
  const hccPhoto = $('hcc-photo');
  const hccStreak = $('hcc-streak');
  const hccFlame = $('hcc-flame');
  const hccTitle = $('hcc-title');
  const hccBadge = $('hcc-badge');
  const hccFireCnt = $('hcc-fire-cnt');
  const hccClapCnt = $('hcc-clap-cnt');

  function renderHeroCycle(idx) {
    if (!hccPhoto || !hccTitle || !hccStreak || !hccBadge) return;
    const dict = COPY[curLang];
    const meta = HERO_CYCLES[idx] || HERO_CYCLES[0];
    const titleKey = `hcc_t${idx}`;
    const badgeKey = (idx === 0 && !streakTicked) ? 'hcc_b0_pre' : `hcc_b${idx}`;
    hccPhoto.dataset.cycle = String(idx);
    hccTitle.dataset.i18n = titleKey;
    hccTitle.textContent = dict[titleKey];
    hccStreak.textContent = (idx === 0 && !streakTicked) ? '20' : meta.streak;
    hccBadge.dataset.i18n = badgeKey;
    hccBadge.textContent = dict[badgeKey];
    if (hccFireCnt) hccFireCnt.textContent = meta.fire;
    if (hccClapCnt) hccClapCnt.textContent = meta.clap;
  }

  renderHeroCycle(0);

  let heroVisible = true;
  let heroHovered = false;
  if (heroSec) {
    heroSec.classList.add('in-view');
    const heroIO = new IntersectionObserver((entries) => {
      heroVisible = entries[0].isIntersecting;
      heroSec.classList.toggle('in-view', heroVisible);
    }, { threshold: 0.05 });
    heroIO.observe(heroSec);
  }
  if (checkinCard) {
    checkinCard.addEventListener('pointerenter', () => { heroHovered = true; });
    checkinCard.addEventListener('pointerleave', () => { heroHovered = false; });
  }
  if (hccFlame) {
    hccFlame.addEventListener('animationend', () => hccFlame.classList.remove('pop'));
  }

  if (!is404 && !isReducedMotion()) {
    if (!streakTicked) {
      streakTickTimer = setTimeout(() => {
        streakTicked = true;
        if (curHeroCycle === 0) renderHeroCycle(0);
        if (hccFlame && !isReducedMotion()) hccFlame.classList.add('pop');
      }, 1740);
    }
    setInterval(() => {
      if (isReducedMotion() || !heroVisible || heroHovered || document.hidden) return;
      curHeroCycle = (curHeroCycle + 1) % 3;
      renderHeroCycle(curHeroCycle);
    }, 3600);
  }

  /* --- 6. Sticky Nav, Hero Scroll Dispersion & Mobile Thumb-Zone CTA --- */
  const nav = document.querySelector('.nav');
  const scrollCue = $('hero-scroll-cue');
  const orbitItems = [...document.querySelectorAll('.hero-orbit-item')];
  const mobileDock = $('mobile-dock-cta');
  const heroCta = $('hero-cta');
  const betaSec = $('beta');
  let rafPending = false;

  const resetHeroTransforms = () => {
    orbitItems.forEach((el) => {
      el.style.transform = '';
      el.style.opacity = '';
    });
    if (checkinCard) checkinCard.style.transform = '';
  };

  const syncDock = () => {
    if (!mobileDock || !heroCta || !betaSec) return;
    if (innerWidth >= 768) {
      mobileDock.hidden = true;
      return;
    }
    const hRect = heroCta.getBoundingClientRect();
    const bRect = betaSec.getBoundingClientRect();
    mobileDock.hidden = !(hRect.bottom < 0 && bRect.top > innerHeight * 0.92);
  };

  const updateScroll = () => {
    rafPending = false;
    const y = scrollY;
    if (nav) nav.classList.toggle('scrolled', y > 12);
    if (scrollCue) scrollCue.classList.toggle('hide', y > 24);
    syncDock();

    if (isReducedMotion()) {
      resetHeroTransforms();
      return;
    }

    if (y <= innerHeight * 1.1) {
      if (y > 4 && !root.classList.contains('hero-settled')) {
        root.classList.add('hero-settled');
      }
      const p = Math.min(1, Math.max(0, y / (innerHeight * 0.85)));
      const csMap = [
        [-1, -0.85, '-9deg'],
        [1, -0.8, '8deg'],
        [-0.95, 0.75, '7deg'],
        [0.95, 0.8, '-7deg'],
        [-1.15, 0.1, '-5deg'],
        [1.15, 0.12, '6deg']
      ];
      orbitItems.forEach((el, idx) => {
        const [ux, uy, rot] = csMap[idx] || [0, 0, '0deg'];
        el.style.transform = p === 0
          ? ''
          : `translate3d(${(ux * p * 84).toFixed(1)}px, ${(uy * p * 60).toFixed(1)}px, 0) rotate(${rot})`;
        el.style.opacity = p === 0 ? '' : String(Math.max(0, 1 - p * 1.15).toFixed(2));
      });
      if (checkinCard && innerWidth >= 768) {
        checkinCard.style.transform = p === 0
          ? ''
          : `translate3d(${(p * 22).toFixed(1)}px, ${(p * -16).toFixed(1)}px, 0) rotate(4deg)`;
      } else if (checkinCard) {
        checkinCard.style.transform = '';
      }
    } else if (checkinCard && innerWidth < 768) {
      checkinCard.style.transform = '';
    }
  };

  const scheduleScrollUpdate = () => {
    if (!rafPending) {
      rafPending = true;
      requestAnimationFrame(updateScroll);
    }
  };

  addEventListener('scroll', scheduleScrollUpdate, { passive: true });
  addEventListener('resize', scheduleScrollUpdate, { passive: true });
  updateScroll();

  /* --- 7. Section 2: 6-Persona Chameleon Switcher --- */
  const jStage = $('journeys-stage');
  const jTabs = $('j-tabs');
  const jPanel = $('j-panel');
  const jKind = $('j-kind');
  const jTitle = $('j-title');
  const jDesc = $('j-desc');
  const jChips = $('j-chips');
  const jNo = $('j-no');
  const phoneJ = $('phone-j');
  const jPic = $('j-pic');
  const jImg = $('j-img');
  const jSrcD = $('j-src-d');
  const jCouple = $('j-couple-screen');
  let swapTimer = null;

  const applyJourneyTab = (idx, moveFocus, animate = true) => {
    if (!jStage || !jTabs || !jPanel) return;
    const prevTab = curTab;
    curTab = idx;
    const item = JOURNEYS[idx];
    const copy = item[curLang];
    const tabBtns = [...jTabs.querySelectorAll('.j-tab')];
    tabBtns.forEach((btn, k) => {
      const active = k === idx;
      btn.setAttribute('aria-selected', String(active));
      btn.tabIndex = active ? 0 : -1;
    });
    if (moveFocus && tabBtns[idx]) tabBtns[idx].focus();

    jStage.dataset.skin = item.skin;
    jPanel.setAttribute('aria-labelledby', `tab-${item.skin}`);
    if (jKind) jKind.textContent = copy.kind;
    if (jTitle) jTitle.textContent = copy.title;
    if (jDesc) jDesc.textContent = copy.desc;
    if (jNo) jNo.textContent = item.no;
    if (jChips) jChips.innerHTML = copy.chips.map((c) => `<span class="dna-chip">${c}</span>`).join('');
    if (jCouple) jCouple.setAttribute('aria-label', JOURNEYS[4][curLang].alt);

    const swapScreen = () => {
      if (!jPic || !jImg || !jSrcD || !jCouple || !phoneJ) return;
      if (item.screen) {
        jCouple.hidden = true;
        jPic.hidden = false;
        jImg.src = `/assets/screens/${item.screen}.webp`;
        jSrcD.srcset = `/assets/screens/${item.screen}-dark.webp`;
        jImg.alt = copy.alt;
      } else {
        jPic.hidden = true;
        jCouple.hidden = false;
      }
      phoneJ.classList.remove('swapping');
    };

    clearTimeout(swapTimer);
    if (!animate || isReducedMotion() || idx === prevTab || !phoneJ) {
      swapScreen();
    } else {
      phoneJ.classList.add('swapping');
      swapTimer = setTimeout(swapScreen, 130);
    }
  };

  if (jTabs) {
    jTabs.addEventListener('click', (e) => {
      const btn = e.target.closest('.j-tab');
      if (!btn) return;
      const idx = Number(btn.dataset.idx);
      if (!Number.isNaN(idx)) applyJourneyTab(idx, false, true);
    });

    jTabs.addEventListener('keydown', (e) => {
      const delta = { ArrowRight: 1, ArrowDown: 1, ArrowLeft: -1, ArrowUp: -1 }[e.key];
      if (delta) {
        e.preventDefault();
        applyJourneyTab((curTab + delta + JOURNEYS.length) % JOURNEYS.length, true, true);
      } else if (e.key === 'Home') {
        e.preventDefault();
        applyJourneyTab(0, true, true);
      } else if (e.key === 'End') {
        e.preventDefault();
        applyJourneyTab(JOURNEYS.length - 1, true, true);
      }
    });
  }

  /* Preload remaining journey screenshots only when #journeys approaches viewport */
  const journeysSec = $('journeys');
  if (journeysSec) {
    const jPreloadIO = new IntersectionObserver((entries) => {
      if (!entries[0].isIntersecting) return;
      jPreloadIO.disconnect();
      const suffix = isDark() ? '-dark' : '';
      JOURNEYS.forEach((j) => {
        if (j.screen && j.screen !== 'j-ielts') {
          const pre = new Image();
          pre.src = `/assets/screens/${j.screen}${suffix}.webp`;
        }
      });
    }, { rootMargin: '480px 0px' });
    jPreloadIO.observe(journeysSec);
  }

  /* --- 8. Section 3: 3-Step Daily Loop Scrollytelling --- */
  const steps = [...document.querySelectorAll('.step')];
  const howPhone = $('phone-how');
  const stepsFill = $('steps-fill');
  const setStep = (n) => {
    steps.forEach((s, i) => s.classList.toggle('active', i === n));
    if (howPhone) howPhone.dataset.screen = String(n);
    if (stepsFill) stepsFill.style.transform = `scaleY(${((n + 1) / 3).toFixed(2)})`;
  };
  if (steps.length) {
    const stepIO = new IntersectionObserver((entries) => {
      entries.forEach((en) => {
        if (en.isIntersecting) setStep(Number(en.target.dataset.step));
      });
    }, { rootMargin: '-42% 0px -42% 0px' });
    steps.forEach((s) => stepIO.observe(s));
  }

  /* --- 9. Section 4: Interactive Squad Polaroid Wall --- */
  const RX_LABELS = {
    vi: {
      fire: (who, n) => `Thả lửa cho ảnh của ${who} (${n})`,
      heart: (who, n) => `Thả tim cho ảnh của ${who} (${n})`,
      clap: (who, n) => `Vỗ tay cho ảnh của ${who} (${n})`,
      flex: (who, n) => `Thả cơ bắp cho ảnh của ${who} (${n})`
    },
    en: {
      fire: (who, n) => `Fire reaction for ${who}'s photo (${n})`,
      heart: (who, n) => `Heart reaction for ${who}'s photo (${n})`,
      clap: (who, n) => `Clap reaction for ${who}'s photo (${n})`,
      flex: (who, n) => `Muscle reaction for ${who}'s photo (${n})`
    }
  };

  const reactChips = [...document.querySelectorAll('.react-chip')];
  const syncReactChipAria = (chip) => {
    const kind = chip.dataset.rxKind || 'fire';
    const who = (curLang === 'en' && chip.dataset.rxWho === 'Hà') ? 'Ha' : (chip.dataset.rxWho || '');
    const count = chip.dataset.count || '1';
    const fmt = (RX_LABELS[curLang] && RX_LABELS[curLang][kind]) || RX_LABELS.vi.fire;
    chip.setAttribute('aria-label', fmt(who, count));
  };

  reactChips.forEach((chip) => {
    syncReactChipAria(chip);
    chip.addEventListener('click', () => {
      const pressed = chip.getAttribute('aria-pressed') === 'true';
      const nextPressed = !pressed;
      const base = Number(chip.dataset.count || '1');
      const numEl = chip.querySelector('.rc-num');
      chip.setAttribute('aria-pressed', String(nextPressed));
      if (numEl) {
        const nextVal = pressed ? base - 1 : base + 1;
        chip.dataset.count = String(nextVal);
        numEl.textContent = String(nextVal);
      }
      syncReactChipAria(chip);
      if (!isReducedMotion()) {
        chip.classList.remove('pop');
        void chip.offsetWidth;
        chip.classList.add('pop');
      }
    });
  });

  const nudgeBtn = $('nudge-btn');
  const nudgeSvg = $('nudge-svg');
  const nudgeCheck = $('nudge-check');
  const nudgeLabel = $('nudge-label');
  const minhCard = $('polaroid-minh');
  const minhStatus = $('minh-status');
  const squadMsg = $('squad-nudge-msg');
  const meter4 = $('squad-meter-4');

  if (nudgeBtn) {
    nudgeBtn.addEventListener('click', () => {
      minhNudged = true;
      const dict = COPY[curLang];
      nudgeBtn.classList.add('done');
      if (nudgeSvg) nudgeSvg.setAttribute('hidden', '');
      if (nudgeCheck) nudgeCheck.removeAttribute('hidden');
      if (nudgeLabel) {
        nudgeLabel.dataset.i18n = 'sq_nudge_done';
        nudgeLabel.textContent = dict.sq_nudge_done;
      }
      if (minhStatus) {
        minhStatus.dataset.i18n = 'sq_c4_nudged';
        minhStatus.textContent = dict.sq_c4_nudged;
      }
      if (squadMsg) squadMsg.textContent = dict.sq_nudge_done;
      if (meter4) meter4.classList.add('nudged');
      if (minhCard && !isReducedMotion()) {
        minhCard.classList.remove('wiggle');
        void minhCard.offsetWidth;
        minhCard.classList.add('wiggle');
      }
    });
  }

  /* --- 9b. Section 5: Finish Line Fan-Open Observer --- */
  const finishPhones = $('finish-phones');
  if (finishPhones) {
    if (isReducedMotion()) {
      finishPhones.classList.add('in');
    } else {
      const finIO = new IntersectionObserver((entries) => {
        if (entries[0].isIntersecting) {
          finishPhones.classList.add('in');
          finIO.disconnect();
        }
      }, { threshold: 0.2 });
      finIO.observe(finishPhones);
    }
  }

  reduceMotionMql.addEventListener('change', () => {
    if (isReducedMotion()) {
      clearTimeout(streakTickTimer);
      clearTimeout(swapTimer);
      streakTicked = true;
      settleHero();
      renderHeroCycle(curHeroCycle);
      resetHeroTransforms();
      if (hccFlame) hccFlame.classList.remove('pop');
      reactChips.forEach((c) => c.classList.remove('pop'));
      if (minhCard) minhCard.classList.remove('wiggle');
      if (phoneJ) phoneJ.classList.remove('swapping');
      if (finishPhones) finishPhones.classList.add('in');
    }
  });

  /* --- 10. Section 6: Hold-to-Reveal Metric & Live Share Preview Toggles --- */
  const holdBtn = $('hold-btn');
  const holdMasked = $('hold-masked');
  const holdRevealed = $('hold-revealed');
  let holdTimer = null;
  let suppressTimer = null;
  let suppressClick = false;
  let pointerDownAt = 0;

  const setHoldReveal = (show) => {
    if (!holdBtn || !holdMasked || !holdRevealed) return;
    holdBtn.setAttribute('aria-pressed', String(show));
    holdMasked.hidden = show;
    holdRevealed.hidden = !show;
  };

  if (holdBtn) {
    holdBtn.addEventListener('pointerdown', () => {
      clearTimeout(holdTimer);
      clearTimeout(suppressTimer);
      suppressClick = false;
      pointerDownAt = performance.now();
      setHoldReveal(true);
    });
    holdBtn.addEventListener('pointerup', () => {
      clearTimeout(holdTimer);
      clearTimeout(suppressTimer);
      const heldMs = pointerDownAt > 0 ? performance.now() - pointerDownAt : 0;
      pointerDownAt = 0;
      suppressClick = true;
      suppressTimer = setTimeout(() => { suppressClick = false; }, 120);
      if (heldMs >= 180) {
        setHoldReveal(false);
      } else {
        setHoldReveal(true);
        holdTimer = setTimeout(() => setHoldReveal(false), 2500);
      }
    });
    ['pointerleave', 'pointercancel'].forEach((ev) => {
      holdBtn.addEventListener(ev, () => {
        clearTimeout(holdTimer);
        clearTimeout(suppressTimer);
        pointerDownAt = 0;
        suppressClick = false;
        setHoldReveal(false);
      });
    });
    holdBtn.addEventListener('keydown', (e) => {
      if (e.key === ' ' || e.key === 'Enter') {
        e.preventDefault();
        if (e.repeat) return;
        clearTimeout(holdTimer);
        clearTimeout(suppressTimer);
        suppressClick = false;
        setHoldReveal(true);
      }
    });
    holdBtn.addEventListener('keyup', (e) => {
      if (e.key === ' ' || e.key === 'Enter') {
        e.preventDefault();
        clearTimeout(holdTimer);
        clearTimeout(suppressTimer);
        suppressClick = false;
        setHoldReveal(false);
      }
    });
    holdBtn.addEventListener('blur', () => {
      clearTimeout(holdTimer);
      clearTimeout(suppressTimer);
      pointerDownAt = 0;
      suppressClick = false;
      setHoldReveal(false);
    });
    /* Quick tap (<180ms) or virtual assistive-tech click reveals for 2.5s */
    holdBtn.addEventListener('click', () => {
      if (suppressClick) {
        clearTimeout(suppressTimer);
        suppressClick = false;
        return;
      }
      clearTimeout(holdTimer);
      setHoldReveal(true);
      holdTimer = setTimeout(() => setHoldReveal(false), 2500);
    });
  }

  const tgHideNum = $('tg-hide-num');
  const tgBlurImg = $('tg-blur-img');
  const sharePreview = $('share-preview');
  const spMetricPill = $('sp-metric-pill');

  const syncPrivacyPreview = () => {
    if (!sharePreview || !spMetricPill) return;
    const hideNum = tgHideNum ? tgHideNum.checked : true;
    const blurImg = tgBlurImg ? tgBlurImg.checked : false;
    const pillKey = hideNum ? 'priv_preview_hidden' : 'priv_preview_shown';
    sharePreview.dataset.hideNum = String(hideNum);
    sharePreview.dataset.blurImg = String(blurImg);
    spMetricPill.dataset.i18n = pillKey;
    spMetricPill.textContent = COPY[curLang][pillKey];
  };
  if (tgHideNum) tgHideNum.addEventListener('change', syncPrivacyPreview);
  if (tgBlurImg) tgBlurImg.addEventListener('change', syncPrivacyPreview);

  /* --- 11. Section 8: Platform Pills, Beta Form & Focus Not Obscured Guard --- */
  document.querySelectorAll('.plat-pill').forEach((pill) => {
    pill.addEventListener('click', () => {
      const cur = pill.getAttribute('aria-pressed') === 'true';
      pill.setAttribute('aria-pressed', String(!cur));
    });
  });

  const form = $('beta-form'), msg = $('form-msg'), email = $('email');
  let formMsgKey = '';
  let announceRaf = 0;
  const announce = (key) => {
    formMsgKey = key;
    if (!msg) return;
    cancelAnimationFrame(announceRaf);
    msg.textContent = '';
    announceRaf = requestAnimationFrame(() => {
      msg.textContent = (formMsgKey && COPY[curLang][formMsgKey]) || '';
    });
  };
  if (form && email) {
    form.addEventListener('submit', (e) => {
      e.preventDefault();
      const ok = Boolean(email.value.trim()) && email.checkValidity();
      email.setAttribute('aria-invalid', ok ? 'false' : 'true');
      if (!ok) {
        announce('form_err');
        email.focus();
        return;
      }
      announce('form_ok');
      form.reset();
    });
  }

  addEventListener('focusin', (e) => {
    const t = e.target;
    if (!t || !t.getBoundingClientRect || (nav && nav.contains(t)) || (mobileDock && mobileDock.contains(t))) return;
    const r = t.getBoundingClientRect();
    if (nav) {
      const nr = nav.getBoundingClientRect();
      if (r.top < nr.bottom + 8 && r.bottom > 0) {
        scrollBy({ top: r.top - nr.bottom - 12, behavior: 'instant' });
        return;
      }
    }
    if (mobileDock && !mobileDock.hidden && innerWidth < 768) {
      const dr = mobileDock.getBoundingClientRect();
      if (r.bottom > dr.top - 8 && r.top < innerHeight) {
        scrollBy({ top: r.bottom - dr.top + 16, behavior: 'instant' });
      }
    }
  });

  /* --- 12. Bilingual VI / EN Switcher --- */
  const applyLanguage = (lang, persist) => {
    curLang = lang === 'en' ? 'en' : 'vi';
    const dict = COPY[curLang];
    root.lang = curLang;
    root.dataset.lang = curLang;
    document.title = (is404 && dict.nf_title) ? dict.nf_title : dict.title;
    const metaDesc = document.querySelector('meta[name="description"]');
    if (metaDesc) metaDesc.content = (is404 && dict.nf_lede) ? dict.nf_lede : dict.meta_desc;
    if (!is404) {
      const setAttr = (id, attr, val) => { const el = $(id); if (el && val) el.setAttribute(attr, val); };
      setAttr('link-canonical', 'href', dict.og_url);
      setAttr('meta-og-url', 'content', dict.og_url);
      setAttr('meta-og-locale', 'content', dict.og_locale);
      setAttr('meta-og-locale-alt', 'content', dict.og_locale_alt);
      setAttr('meta-og-title', 'content', dict.og_title);
      setAttr('meta-og-desc', 'content', dict.meta_desc);
      setAttr('meta-og-image', 'content', dict.og_image);
      setAttr('meta-og-image-secure', 'content', dict.og_image);
      setAttr('meta-og-image-alt', 'content', dict.og_image_alt);
      setAttr('meta-tw-url', 'content', dict.og_url);
      setAttr('meta-tw-title', 'content', dict.og_title);
      setAttr('meta-tw-desc', 'content', dict.meta_desc);
      setAttr('meta-tw-image', 'content', dict.og_image);
      setAttr('meta-tw-image-alt', 'content', dict.og_image_alt);
    }

    document.querySelectorAll('[data-i18n]').forEach((el) => {
      const k = el.dataset.i18n;
      if (dict[k]) el.textContent = dict[k];
    });
    document.querySelectorAll('[data-i18n-placeholder]').forEach((el) => {
      const k = el.dataset.i18nPlaceholder;
      if (dict[k]) el.placeholder = dict[k];
    });
    document.querySelectorAll('[data-i18n-aria]').forEach((el) => {
      const k = el.dataset.i18nAria;
      if (dict[k]) el.setAttribute('aria-label', dict[k]);
    });
    document.querySelectorAll('[data-i18n-alt]').forEach((el) => {
      const k = el.dataset.i18nAlt;
      if (dict[k]) el.alt = dict[k];
    });
    document.querySelectorAll('[data-home-link]').forEach((el) => {
      el.setAttribute('href', curLang === 'en' ? '/?lang=en' : '/');
    });

    renderHeroCycle(curHeroCycle);
    applyJourneyTab(curTab, false, false);
    syncPrivacyPreview();
    reactChips.forEach(syncReactChipAria);
    if (minhNudged) {
      if (nudgeLabel) nudgeLabel.textContent = dict.sq_nudge_done;
      if (minhStatus) minhStatus.textContent = dict.sq_c4_nudged;
      if (squadMsg) squadMsg.textContent = dict.sq_nudge_done;
    }
    if (msg && formMsgKey && dict[formMsgKey]) {
      cancelAnimationFrame(announceRaf);
      msg.textContent = dict[formMsgKey];
    }

    if (persist) {
      try { localStorage.setItem('ourney-lang', curLang); } catch (e) {}
      try {
        const url = new URL(location.href);
        if (curLang === 'en') url.searchParams.set('lang', 'en');
        else url.searchParams.delete('lang');
        history.replaceState(null, '', url);
      } catch (e) {}
    }
  };

  const langToggle = $('lang-toggle');
  if (langToggle) {
    langToggle.addEventListener('click', () => {
      applyLanguage(curLang === 'vi' ? 'en' : 'vi', true);
    });
  }

  if (curLang === 'en') applyLanguage('en', false);
})();
