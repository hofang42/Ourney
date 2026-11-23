(() => {
  const root = document.documentElement;
  const $ = (id) => document.getElementById(id);
  const reduceMotion = matchMedia('(prefers-reduced-motion: reduce)').matches;
  const darkMql = matchMedia('(prefers-color-scheme: dark)');

  /* --- 1. Bilingual Copy Dictionary (vi default + en) --- */
  const COPY = {
    vi: {
      title: 'ourney · chụp một tấm. giữ một chuỗi.',
      meta_desc: 'Ourney là nhật ký ảnh mỗi ngày cho điều bạn muốn kiên trì: học ngoại ngữ, chạy bộ, giảm cân, chuyến đi hay thói quen nhỏ — đi một mình hoặc cùng nhóm bạn.',
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
      ticket_sub: 'Bấm để giữ chỗ Ngày 1',
      hero_phone_alt: 'Màn hành trình của app Ourney: thẻ chuỗi 21 ngày, hành trình IELTS 7.5 ngày 21/30 và nút Chụp hôm nay',
      hcc_t0: 'IELTS 7.5 · Ngày 21/30',
      hcc_b0: 'chuỗi 21 ngày',
      hcc_t1: 'Chạy sáng · 5,4 km',
      hcc_b1: '21/30 buổi',
      hcc_t2: 'Đà Lạt 7 ngày · Khung 14/24',
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
      j_tab_2: 'Đà Lạt 7 ngày',
      j_tab_3: '30 ngày cơ thể',
      j_tab_4: 'Tụi mình',
      j_tab_5: 'Đọc 10 trang',
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
      beta_placeholder: 'ban@email-cua-ban.vn…',
      beta_submit: 'nhận lời mời',
      form_err: 'Email chưa đúng định dạng — bạn kiểm tra lại giúp nhé.',
      form_ok: 'Đã ghi nhận trên bản xem trước! Tụi mình sẽ mở cổng đăng ký beta chính thức cho iOS & Android thật sớm.',
      footer_tagline: 'chụp một tấm. giữ một chuỗi. đi cùng nhau.',
      footer_journeys: 'hành trình',
      footer_privacy: 'riêng tư',
      footer_faq: 'hỏi đáp',
      footer_beta: 'nhận lời mời'
    },
    en: {
      title: 'ourney · snap one photo. keep one streak.',
      meta_desc: 'Ourney is a daily photo journal for what you want to stick with: language study, running, weight loss, a trip, or a small habit — solo or with a close squad.',
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
      ticket_sub: 'Tap to claim your Day 1',
      hero_phone_alt: 'Ourney app Hub screen: 21-day streak card, IELTS 7.5 Day 21/30 card, and Snap Today CTA',
      hcc_t0: 'IELTS 7.5 · Day 21/30',
      hcc_b0: '21-day streak',
      hcc_t1: 'Morning Run · 5.4 km',
      hcc_b1: '21/30 sessions',
      hcc_t2: 'Da Lat 7 Days · Frame 14/24',
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
      j_tab_2: 'Da Lat 7 Days',
      j_tab_3: '30-Day Body',
      j_tab_4: 'Just Us Two',
      j_tab_5: 'Read 10 Pages',
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
      beta_placeholder: 'you@example.com…',
      beta_submit: 'get beta invite',
      form_err: 'That email doesn’t look right — please check and try again.',
      form_ok: 'Noted in preview mode! Official iOS & Android beta waitlist storage opens very soon.',
      footer_tagline: 'snap one photo. keep one streak. go together.',
      footer_journeys: 'journeys',
      footer_privacy: 'privacy',
      footer_faq: 'faq',
      footer_beta: 'get invite'
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
        label: 'Đà Lạt 7 ngày', kind: 'chuyến đi · Memory Collectors',
        title: 'hôm nay cả bọn lạc ở đâu.',
        desc: 'Cuộn phim 24 khung trên nền giấy hạt ấm. Ảnh mỗi ngày dán băng keo dọc sợi chỉ khâu, hết chuyến tự đóng gói thành poster 35mm.',
        chips: ['Chỉ khâu & băng keo', 'Cuộn 24 tấm', 'Poster 35mm'],
        alt: 'Trang hành trình Đà Lạt 7 ngày trong app Ourney'
      },
      en: {
        label: 'Da Lat 7 Days', kind: 'trip · Memory Collectors',
        title: 'where did we get lost today.',
        desc: 'A 24-frame roll on warm grain paper. Daily Polaroids tape along a stitched thread and pack into a 35mm contact-sheet poster at the end.',
        chips: ['Stitched scrapbook', '24-frame roll', '35mm poster'],
        alt: 'Da Lat 7 Days trip screen in Ourney app'
      }
    },
    {
      skin: 'quiet', screen: 'j-weight', no: '04',
      vi: {
        label: '30 ngày cơ thể', kind: 'giảm cân · Quiet Transformer',
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
        alt: 'Trang hành trình Cặp đôi Tụi mình trong app Ourney'
      },
      en: {
        label: 'Just Us Two', kind: 'couple · Couple Rituals',
        title: 'two halves of the same day.',
        desc: 'Each day pairs both partners side by side: whoever snaps first appears as a corner picture-in-picture guide while the other completes the pair.',
        chips: ['Paired diptych', 'Partner PiP', '2-person vault'],
        alt: 'Just Us Two couple journey screen in Ourney app'
      }
    },
    {
      skin: 'minimal', screen: 'j-minimal', no: '06',
      vi: {
        label: 'Đọc 10 trang', kind: 'tự đặt · Minimalist Habit',
        title: 'một ô mỗi ngày.',
        desc: 'Lưới lịch 7 cột tinh gọn, không chi tiết thừa: không ô nhập chữ rườm rà, một chạm chụp là nối liền sợi dây cam không đứt quãng.',
        chips: ['Lưới 7 cột', 'Chụp 3 giây', 'Mốc 7 · 15 · 30'],
        alt: 'Trang hành trình Đọc 10 trang trong app Ourney'
      },
      en: {
        label: 'Read 10 Pages', kind: 'custom habit · Minimalist Habit',
        title: 'one square a day.',
        desc: 'A clean, distraction-free 7-column calendar grid: zero text friction, one shutter tap links today’s square onto an unbroken orange chain.',
        chips: ['7-col chain', '3-sec check-in', 'Day 7 · 15 · 30'],
        alt: 'Read 10 Pages custom habit screen in Ourney app'
      }
    }
  ];

  let curLang = root.dataset.lang === 'en' ? 'en' : 'vi';
  let curTab = 0;
  let curHeroCycle = 0;
  let minhNudged = false;

  /* --- 3. Theme Resolution & <picture> Source Media Sync --- */
  const isDark = () => root.dataset.theme ? root.dataset.theme === 'dark' : darkMql.matches;
  const syncThemePictures = () => {
    const dark = isDark();
    const mediaVal = root.dataset.theme ? (dark ? 'all' : 'not all') : '(prefers-color-scheme: dark)';
    document.querySelectorAll('source.src-dark').forEach((s) => { s.media = mediaVal; });
    const metaL = $('meta-theme-light'), metaD = $('meta-theme-dark');
    if (metaL && metaD && root.dataset.theme) {
      const hex = dark ? '#1B1916' : '#FFF8EE';
      metaL.content = hex;
      metaD.content = hex;
    }
  };
  syncThemePictures();

  $('theme-toggle').addEventListener('click', () => {
    const next = isDark() ? 'light' : 'dark';
    root.dataset.theme = next;
    try { localStorage.setItem('ourney-theme', next); } catch (e) {}
    syncThemePictures();
  });
  darkMql.addEventListener('change', syncThemePictures);
  new MutationObserver(syncThemePictures).observe(root, { attributes: true, attributeFilter: ['data-theme'] });

  /* --- 4. First-Load Intro Skip & Session Memory --- */
  const markIntroSeen = () => {
    try { sessionStorage.setItem('ourney-intro-seen', '1'); } catch (e) {}
  };
  if (!root.classList.contains('intro-seen') && !reduceMotion) {
    const skipIntro = () => {
      root.classList.add('intro-skip');
      markIntroSeen();
    };
    ['wheel', 'touchmove', 'pointerdown', 'keydown'].forEach((ev) => {
      addEventListener(ev, skipIntro, { once: true, passive: true });
    });
    setTimeout(markIntroSeen, 1400);
  } else {
    markIntroSeen();
  }

  /* --- 5. Hero Live Check-In Card Streak Flip & 3.6s Cycle --- */
  const hccPhoto = $('hcc-photo');
  const hccStreak = $('hcc-streak');
  const hccFlame = $('hcc-flame');
  const hccTitle = $('hcc-title');
  const hccBadge = $('hcc-badge');

  const renderHeroCycle = (idx) => {
    const dict = COPY[curLang];
    hccPhoto.dataset.cycle = String(idx);
    hccTitle.textContent = dict[`hcc_t${idx}`];
    hccBadge.textContent = dict[`hcc_b${idx}`];
  };

  if (!reduceMotion) {
    setTimeout(() => {
      hccStreak.textContent = '21';
      hccFlame.classList.add('pop');
    }, 1780);

    let heroVisible = true;
    const heroIO = new IntersectionObserver((entries) => {
      heroVisible = entries[0].isIntersecting;
    }, { threshold: 0.2 });
    heroIO.observe($('hero'));

    setInterval(() => {
      if (!heroVisible || document.hidden) return;
      curHeroCycle = (curHeroCycle + 1) % 3;
      renderHeroCycle(curHeroCycle);
    }, 3600);
  } else {
    hccStreak.textContent = '21';
  }

  /* --- 6. Sticky Nav & Hero Scroll Dispersion --- */
  const nav = document.querySelector('.nav');
  const scrollCue = $('hero-scroll-cue');
  const orbitItems = [...document.querySelectorAll('.hero-orbit-item')];
  const checkinCard = $('hero-checkin-card');
  let rafPending = false;

  const updateScroll = () => {
    rafPending = false;
    const y = scrollY;
    nav.classList.toggle('scrolled', y > 12);
    if (scrollCue) scrollCue.classList.toggle('hide', y > 24);

    if (!reduceMotion && y <= innerHeight * 1.1) {
      const p = Math.min(1, Math.max(0, y / (innerHeight * 0.85)));
      orbitItems.forEach((el) => {
        const ux = parseFloat(el.style.getPropertyValue('--ux') || '0');
        const uy = parseFloat(el.style.getPropertyValue('--uy') || '0');
        const rot = el.style.getPropertyValue('--rot') || '0deg';
        el.style.transform = `translate3d(${(ux * p * 84).toFixed(1)}px, ${(uy * p * 60).toFixed(1)}px, 0) rotate(${rot})`;
        el.style.opacity = String(Math.max(0, 1 - p * 1.15).toFixed(2));
      });
      if (checkinCard) {
        checkinCard.style.transform = `translate3d(${(p * 22).toFixed(1)}px, ${(p * -16).toFixed(1)}px, 0) rotate(4deg)`;
      }
    }
  };

  addEventListener('scroll', () => {
    if (!rafPending) {
      rafPending = true;
      requestAnimationFrame(updateScroll);
    }
  }, { passive: true });
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

  const applyJourneyTab = (idx, moveFocus) => {
    curTab = idx;
    const item = JOURNEYS[idx];
    const copy = item[curLang];
    const tabBtns = [...jTabs.querySelectorAll('.j-tab')];
    tabBtns.forEach((btn, k) => {
      const active = k === idx;
      btn.setAttribute('aria-selected', String(active));
      btn.tabIndex = active ? 0 : -1;
    });
    if (moveFocus) tabBtns[idx].focus();

    jStage.dataset.skin = item.skin;
    jPanel.setAttribute('aria-labelledby', `tab-${item.skin}`);
    jKind.textContent = copy.kind;
    jTitle.textContent = copy.title;
    jDesc.textContent = copy.desc;
    jNo.textContent = item.no;
    jChips.innerHTML = copy.chips.map((c) => `<span class="dna-chip">${c}</span>`).join('');

    const swapScreen = () => {
      if (item.screen) {
        jCouple.hidden = true;
        jPic.hidden = false;
        jImg.src = `assets/screens/${item.screen}.webp`;
        jSrcD.srcset = `assets/screens/${item.screen}-dark.webp`;
        jImg.alt = copy.alt;
      } else {
        jPic.hidden = true;
        jCouple.hidden = false;
      }
      phoneJ.classList.remove('swapping');
    };

    if (reduceMotion) {
      swapScreen();
    } else {
      phoneJ.classList.add('swapping');
      setTimeout(swapScreen, 130);
    }
  };

  jTabs.addEventListener('click', (e) => {
    const btn = e.target.closest('.j-tab');
    if (!btn) return;
    const idx = Number(btn.dataset.idx);
    if (!Number.isNaN(idx)) applyJourneyTab(idx, false);
  });

  jTabs.addEventListener('keydown', (e) => {
    const delta = { ArrowRight: 1, ArrowDown: 1, ArrowLeft: -1, ArrowUp: -1 }[e.key];
    if (delta) {
      e.preventDefault();
      applyJourneyTab((curTab + delta + JOURNEYS.length) % JOURNEYS.length, true);
    } else if (e.key === 'Home') {
      e.preventDefault();
      applyJourneyTab(0, true);
    } else if (e.key === 'End') {
      e.preventDefault();
      applyJourneyTab(JOURNEYS.length - 1, true);
    }
  });

  /* Defer preloading remaining journey screenshots until 1.5s after window load */
  addEventListener('load', () => {
    setTimeout(() => {
      const suffix = isDark() ? '-dark' : '';
      JOURNEYS.forEach((j) => {
        if (j.screen && j.screen !== 'j-ielts') {
          const pre = new Image();
          pre.src = `assets/screens/${j.screen}${suffix}.webp`;
        }
      });
    }, 1500);
  });

  /* --- 8. Section 3: 3-Step Daily Loop Scrollytelling --- */
  const steps = [...document.querySelectorAll('.step')];
  const howPhone = $('phone-how');
  const stepsFill = $('steps-fill');
  const setStep = (n) => {
    steps.forEach((s, i) => s.classList.toggle('active', i === n));
    if (howPhone) howPhone.dataset.screen = String(n);
    if (stepsFill) stepsFill.style.transform = `scaleY(${((n + 1) / 3).toFixed(2)})`;
  };
  const stepIO = new IntersectionObserver((entries) => {
    entries.forEach((en) => {
      if (en.isIntersecting) setStep(Number(en.target.dataset.step));
    });
  }, { rootMargin: '-42% 0px -42% 0px' });
  steps.forEach((s) => stepIO.observe(s));

  /* --- 9. Section 4: Interactive Squad Polaroid Wall --- */
  document.querySelectorAll('.react-chip').forEach((chip) => {
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
      chip.classList.remove('pop');
      void chip.offsetWidth;
      chip.classList.add('pop');
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
      nudgeSvg.setAttribute('hidden', '');
      nudgeCheck.hidden = false;
      nudgeLabel.textContent = dict.sq_nudge_done;
      minhStatus.textContent = dict.sq_c4_nudged;
      squadMsg.textContent = dict.sq_nudge_done;
      if (meter4) meter4.classList.add('nudged');
      minhCard.classList.remove('wiggle');
      void minhCard.offsetWidth;
      minhCard.classList.add('wiggle');
    });
  }

  /* --- 10. Section 6: Hold-to-Reveal Metric & Live Share Preview Toggles --- */
  const holdBtn = $('hold-btn');
  const holdMasked = $('hold-masked');
  const holdRevealed = $('hold-revealed');
  let holdTimer = null;

  const setHoldReveal = (show) => {
    if (!holdBtn || !holdMasked || !holdRevealed) return;
    holdBtn.setAttribute('aria-pressed', String(show));
    holdMasked.hidden = show;
    holdRevealed.hidden = !show;
  };

  if (holdBtn) {
    holdBtn.addEventListener('pointerdown', () => {
      clearTimeout(holdTimer);
      setHoldReveal(true);
    });
    ['pointerup', 'pointerleave', 'pointercancel'].forEach((ev) => {
      holdBtn.addEventListener(ev, () => setHoldReveal(false));
    });
    holdBtn.addEventListener('keydown', (e) => {
      if (e.key === ' ' || e.key === 'Enter') {
        e.preventDefault();
        setHoldReveal(true);
      }
    });
    holdBtn.addEventListener('keyup', (e) => {
      if (e.key === ' ' || e.key === 'Enter') setHoldReveal(false);
    });
    holdBtn.addEventListener('blur', () => setHoldReveal(false));
    /* Tap/click fallback reveals for 2.5s on touch/switch devices */
    holdBtn.addEventListener('click', () => {
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
    sharePreview.dataset.hideNum = String(hideNum);
    sharePreview.dataset.blurImg = String(blurImg);
    spMetricPill.textContent = hideNum ? COPY[curLang].priv_preview_hidden : COPY[curLang].priv_preview_shown;
  };
  if (tgHideNum) tgHideNum.addEventListener('change', syncPrivacyPreview);
  if (tgBlurImg) tgBlurImg.addEventListener('change', syncPrivacyPreview);

  /* --- 11. Section 8: Platform Pills, Beta Form & Mobile Sticky CTA --- */
  document.querySelectorAll('.plat-pill').forEach((pill) => {
    pill.addEventListener('click', () => {
      const cur = pill.getAttribute('aria-pressed') === 'true';
      pill.setAttribute('aria-pressed', String(!cur));
    });
  });

  const form = $('beta-form'), msg = $('form-msg'), email = $('email');
  const announce = (text) => {
    msg.textContent = '';
    requestAnimationFrame(() => { msg.textContent = text; });
  };
  form.addEventListener('submit', (e) => {
    e.preventDefault();
    const ok = Boolean(email.value.trim()) && email.checkValidity();
    email.setAttribute('aria-invalid', ok ? 'false' : 'true');
    if (!ok) {
      announce(COPY[curLang].form_err);
      email.focus();
      return;
    }
    announce(COPY[curLang].form_ok);
    form.reset();
  });

  /* Mobile Floating Thumb-Zone CTA visibility */
  const mobileDock = $('mobile-dock-cta');
  const heroCta = $('hero-cta');
  const betaSec = $('beta');
  if (mobileDock && heroCta && betaSec) {
    let heroCtaOut = false;
    let betaIn = false;
    const syncDock = () => { mobileDock.hidden = !(heroCtaOut && !betaIn); };
    const dockIO = new IntersectionObserver((entries) => {
      entries.forEach((en) => {
        if (en.target === heroCta) heroCtaOut = !en.isIntersecting && en.boundingClientRect.top < 0;
        if (en.target === betaSec) betaIn = en.isIntersecting;
      });
      syncDock();
    }, { threshold: 0.05 });
    dockIO.observe(heroCta);
    dockIO.observe(betaSec);
  }

  /* --- 12. Bilingual VI / EN Switcher --- */
  const applyLanguage = (lang, persist) => {
    curLang = lang === 'en' ? 'en' : 'vi';
    const dict = COPY[curLang];
    root.lang = curLang;
    root.dataset.lang = curLang;
    document.title = dict.title;
    const metaDesc = document.querySelector('meta[name="description"]');
    if (metaDesc) metaDesc.content = dict.meta_desc;

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

    renderHeroCycle(curHeroCycle);
    applyJourneyTab(curTab, false);
    syncPrivacyPreview();
    if (minhNudged && nudgeLabel && minhStatus) {
      nudgeLabel.textContent = dict.sq_nudge_done;
      minhStatus.textContent = dict.sq_c4_nudged;
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

  $('lang-toggle').addEventListener('click', () => {
    applyLanguage(curLang === 'vi' ? 'en' : 'vi', true);
  });

  if (curLang === 'en') applyLanguage('en', false);
})();
