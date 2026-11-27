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
      title: 'ourney · Góp tấm hình, giữ nhịp mình · nhật ký ảnh mỗi ngày',
      meta_desc: 'Ourney là nhật ký ảnh mỗi ngày cho việc bạn muốn làm đều: học ngoại ngữ, chạy bộ, giảm cân, đi du lịch hay đọc sách, tự lưu riêng hoặc chụp cùng hội bạn.',
      og_title: 'ourney · Góp tấm hình, giữ nhịp mình',
      og_image: 'https://ourney.tech/assets/og/og-default.png',
      og_image_alt: 'Ourney: Góp tấm hình, giữ nhịp mình. Nhật ký ảnh mỗi ngày trên Android và iOS',
      og_url: 'https://ourney.tech/',
      og_locale: 'vi_VN',
      og_locale_alt: 'en_US',
      skip: 'Bỏ qua tới nội dung chính',
      nav_brand_aria: 'Ourney, về đầu trang',
      nav_main_aria: 'Điều hướng chính',
      nav_journeys: '6 giao diện',
      nav_how: 'cách dùng',
      nav_squad: 'nhóm',
      nav_privacy: 'riêng tư',
      nav_faq: 'hỏi đáp',
      nav_cta: 'Tải APK / Chờ iOS',
      nav_lang_aria: 'Chuyển ngôn ngữ sang tiếng Anh',
      nav_theme_aria: 'Đổi giao diện sáng hoặc tối',
      stamp_1: 'Góp tấm hình,',
      stamp_2: 'giữ nhịp mình,',
      stamp_3: 'đi cùng nhau.',
      hero_ticket_aria: 'Tải APK thử nghiệm cho Android hoặc đăng ký danh sách chờ iOS',
      ticket_kicker: 'BẢN THỬ NGHIỆM',
      ticket_title: 'Android APK · Chờ iOS',
      ticket_sub: 'Tải cho Android hoặc đăng ký chờ iOS',
      hero_phone_alt: 'Màn hình chính Ourney: mục IELTS 7.5 ngày 21/30, 21 ngày đã chụp và nút Chụp hôm nay',
      hcc_t0: 'IELTS 7.5 · Ngày 21/30',
      hcc_b0_pre: '20 ngày đã chụp',
      hcc_b0: '21 ngày đã chụp',
      hcc_t1: 'Chạy sáng · 5,4 km',
      hcc_b1: '20/30 buổi',
      hcc_t2: 'Đà Lạt 7\u00A0ngày · Khung 14/24',
      hcc_b2: 'cả nhóm đã chụp',
      hero_h1: 'Góp tấm hình, giữ nhịp mình',
      hero_lede: 'Nhật ký ảnh cho việc bạn muốn làm đều như học tiếng Anh, chạy bộ, giảm cân, một chuyến đi hay vài trang sách mỗi tối. Tự lưu cho riêng mình hoặc rủ hội bạn cùng chụp.',
      hero_cta_primary: 'Tải APK / Chờ iOS',
      hero_cta_secondary: 'xem 6 giao diện',
      hero_cta_android: 'Tải APK cho Android',
      hero_cta_ios: 'Đăng ký danh sách chờ iOS',
      hero_apk_note: 'Android đã có bản thử nghiệm để tải (APK). Nếu dùng iPhone, bạn có thể đăng ký danh sách chờ.',
      hero_apk_note_android: 'Android đã có bản thử nghiệm để tải trực tiếp (Ourney.apk).',
      hero_apk_note_ios: 'Nếu dùng iPhone, bạn có thể đăng ký danh sách chờ bản thử nghiệm iOS ở bên dưới.',
      hero_scroll_aria: 'Cuộn xuống xem 6 giao diện',
      dock_cta_aria: 'Tải APK cho Android hoặc đăng ký danh sách chờ iOS',
      dock_cta_text: 'Có APK Android · Chờ iOS',
      dock_cta_btn: 'Tải APK / Chờ iOS',
      j_eyebrow: 'mỗi mục tiêu một giao diện',
      j_h2: 'Đổi mục tiêu, đổi luôn cách bày biện',
      j_intro: 'Học tiếng Anh đi theo từng chặng tới chiếc cúp ngày 30, chạy bộ vẽ biểu đồ số km, còn chuyến đi nối thành cuộn phim dán băng keo. Chạm thử từng mẫu bên dưới để xem giao diện thật.',
      j_tablist_aria: 'Chọn mẫu giao diện',
      j_tab_0: 'IELTS 7.5',
      j_tab_1: 'Chạy sáng',
      j_tab_2: 'Đà Lạt 7\u00A0ngày',
      j_tab_3: '30\u00A0ngày cơ thể',
      j_tab_4: 'Chúng mình',
      j_tab_5: 'Đọc 10\u00A0trang',
      j_stub_lbl: 'Mẫu',
      cs_pill: 'CẶP ĐÔI · RIÊNG TƯ',
      cs_sub: 'Mỗi ngày hai tấm ảnh ghép cạnh nhau',
      cs_title: 'chúng mình',
      cs_stat: '18 NGÀY BÊN NHAU · 36 TẤM ẢNH',
      cs_stat_sub: 'Cả hai đã chụp đủ hôm nay',
      cs_d18: 'NGÀY 18 · HÔM NAY',
      cs_d17: 'NGÀY 17 · HÔM QUA',
      cs_nam: 'Nam · 07:30',
      cs_linh: 'Linh · 08:12',
      how_eyebrow: 'cách dùng',
      how_h2: 'Ba bước gọn trong vài chạm',
      how_s1_t: 'Chọn một mẫu, chụp tấm đầu tiên',
      how_s1_d: 'Chọn trong 6 mẫu sẵn có và đặt tên mục tiêu, thời gian cùng quyền riêng tư để ứng dụng xếp sẵn giao diện phù hợp.',
      how_s1_alt: 'Bước 1/5: Chọn mẫu giao diện, thẻ Giảm cân',
      how_s2_t: 'Bấm nút chụp ở giữa thanh dưới',
      how_s2_d: 'Nút chụp nằm ngay chính giữa thanh điều hướng. Nhấn giữ để đổi mục tiêu đang theo dõi, bấm chụp rồi bấm Đăng là xong.',
      how_s2_alt: 'Màn hình camera: Đọc 10 trang · Ngày 24 và nút chụp ở giữa thanh dưới',
      how_s3_t: 'Lưu lại xem dần, chia sẻ lúc nào tùy bạn',
      how_s3_d: 'Ảnh chụp mỗi ngày tự xếp vào dòng thời gian của mục tiêu đó. Khi muốn khoe với bạn bè, bạn có thể xuất thẻ ảnh 9:16 hoặc 4:5 kèm số liệu tự chọn.',
      how_s3_alt: 'Thẻ chia sẻ Story của mục Chạy sáng: 4,6 km, ngày 21',
      squad_eyebrow: 'đi cùng nhóm',
      squad_h2: 'Một mình dễ quên, có hội nhắc nhau thì nhớ',
      squad_desc: 'Mời tối đa 10 người bạn thân bằng mã 8 ký tự, không bảng xếp hạng, không đếm người theo dõi. Mở ứng dụng là thấy tường ảnh hôm nay ai đã check-in để thả cảm xúc cho nhau.',
      squad_chip_1: 'Tối đa 10 bạn · Mã mời 8 ký tự',
      squad_chip_2: 'Chạm thả cảm xúc trực tiếp bên cạnh',
      squad_wall_title: 'IELTS 7.5 · HỘI 4 NGƯỜI',
      squad_wall_prog: '3/4 đã chụp hôm nay',
      sq_c1_cap: '“45 phút Reading xong!”',
      sq_c2_cap: '“Ngày 21, xong gọn bài Reading”',
      sq_c3_cap: '“Thêm 30 từ mới vào sổ”',
      sq_c4_wait: 'chưa có ảnh hôm nay',
      finish_eyebrow: 'về đích',
      finish_h2: 'Khép lại một chặng, giữ lại poster tổng kết',
      finish_desc: 'Chuyến đi khép lại thành tấm poster cuộn phim 35mm, còn đợt tập chạy hay ôn thi ghép thành bộ thẻ tổng kết từng ngày bạn đã góp ảnh.',
      finish_tick_1: 'Khổ Story 9:16 và bài đăng 4:5 sắc nét',
      finish_tick_2: 'Hiện tổng số ngày đã chụp và cột mốc đạt được',
      finish_tick_3: 'Ẩn bất kỳ con số nhạy cảm nào trước khi xuất',
      finish_a_alt: 'Poster chuyến đi Đà Lạt 7 ngày với cuộn phim các ngày',
      finish_b_alt: 'Thẻ tổng kết chặng đường: 20 bức ảnh trong 20 ngày',
      priv_eyebrow: 'riêng tư & trên máy',
      priv_h2: 'Có những mục tiêu chỉ cần lưu cho riêng mình',
      priv_desc: 'Bạn chọn quyền xem riêng cho từng mục tiêu. Với mục theo dõi cân nặng, số kg luôn được che thành dấu chấm, nhấn giữ nút bên dưới để xem thử.',
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
      priv_local_chip: 'Lưu trước trên máy: chụp và lưu ảnh cá nhân ngay cả khi mất mạng, có mạng sẽ tự đồng bộ. Trang web này chỉ đếm lượt truy cập không dùng cookie qua Cloudflare.',
      priv_phone_alt: 'Màn hình 30 ngày cơ thể: biểu đồ cân nặng với con số được ẩn và nút Giữ để xem',
      faq_eyebrow: 'hỏi đáp',
      faq_h2: 'Một vài câu hỏi thường gặp',
      faq_q1: 'Không có mạng hay chưa muốn đăng ký thì dùng được không?',
      faq_a1: 'Khi mất mạng, bạn vẫn mở camera chụp và lưu ảnh check-in ngay trên điện thoại. Khi có mạng trở lại hoặc khi tham gia nhóm, ứng dụng sẽ tự đồng bộ dữ liệu của bạn.',
      faq_q2: 'Một nhóm tối đa bao nhiêu người? Vào muộn có thiệt không?',
      faq_a2: 'Mỗi nhóm tối đa 10 người, tham gia bằng mã mời 8 ký tự. Tiến độ của người vào sau được tính từ đúng ngày họ bắt đầu tham gia, và vẫn xem được toàn bộ ảnh nhóm đã chụp trước đó.',
      faq_q3: 'Ai có thể xem ảnh và chỉ số của tôi?',
      faq_a3: 'Mỗi mục tiêu có cài đặt riêng: Chỉ mình tôi, Ai có link, hoặc Thành viên nhóm. Ngay cả khi chia sẻ, bạn vẫn bật tắt được việc ẩn con số theo dõi và làm mờ ảnh xem trước. Trang web này chỉ thống kê lượt truy cập không dùng cookie qua Cloudflare.',
      faq_q4: 'Một ngày chụp nhiều tấm hoặc thêm lại ảnh chuyến đi cũ có được không?',
      faq_a4: 'Chụp nhiều tấm trong cùng một ngày sẽ được gom gọn vào ngày hôm đó. Bạn cũng có thể chọn ảnh từ chuyến đi đã qua theo ngày chụp trong máy để ứng dụng xếp lại thành dòng thời gian riêng.',
      faq_q5: 'Khi nào Ourney mở tải trên iOS và Android?',
      faq_a5: 'Android đã có bản thử nghiệm để tải (APK). Nếu dùng iPhone, bạn có thể đăng ký danh sách chờ.',
      beta_eyebrow: 'tải bản beta · android & ios',
      beta_eyebrow_android: 'tải bản beta · android',
      beta_eyebrow_ios: 'danh sách chờ beta · ios',
      beta_h2: 'Bắt đầu từ tấm ảnh đầu tiên hôm nay',
      beta_apk_kicker: 'Đã có bản cài đặt trực tiếp',
      beta_apk_btn: 'Tải APK cho Android (Ourney.apk)',
      beta_apk_note: 'Tải trực tiếp file Ourney.apk cho điện thoại Android và mở file vừa tải để cài đặt.',
      beta_ios_lead: 'Dùng iOS (iPhone) hoặc muốn nhận thông báo khi có bản cập nhật mới? Để lại email nhận thông tin beta:',
      beta_ios_lead_android: 'Muốn nhận thông báo khi có bản cập nhật Android mới hoặc khi lên Google Play? Để lại email nhận thông tin beta:',
      beta_ios_lead_ios: 'Để lại email để đăng ký danh sách chờ beta cho iOS (iPhone):',
      beta_plat_aria: 'Chọn nền tảng điện thoại',
      beta_email_label: 'Email',
      beta_placeholder: 'ban@email-cua-ban.vn',
      beta_submit: 'nhận thông tin beta',
      beta_stub_kicker: 'NGÀY 01',
      beta_stub_title: 'VÉ BETA',
      form_err: 'Email chưa đúng định dạng, bạn kiểm tra lại giúp nhé.',
      form_plat_err: 'Bạn chọn giúp ít nhất một nền tảng (iOS hoặc Android) nhé.',
      form_ok: 'Bạn đã vào danh sách nhận tin bản thử nghiệm.',
      form_ok_ios: 'Bạn đã vào danh sách chờ bản thử nghiệm iOS.',
      form_ok_android: 'Bạn đã vào danh sách nhận tin bản thử nghiệm Android.',
      form_ok_both: 'Bạn đã vào danh sách nhận tin bản thử nghiệm iOS và Android.',
      form_sending: 'Đang gửi…',
      form_fail: 'Chưa gửi được, bạn thử lại sau ít phút nhé.',
      form_rate: 'Bạn gửi hơi nhiều lần rồi, đợi một lúc rồi thử lại nhé.',
      beta_tiktok_follow: 'Theo dõi @ourney.official trên TikTok trong lúc chờ',
      footer_tagline: 'Góp tấm hình, giữ nhịp mình',
      footer_journeys: '6 giao diện',
      footer_privacy: 'riêng tư',
      footer_faq: 'hỏi đáp',
      footer_beta: 'Tải APK / Chờ iOS',
      nf_title: 'ourney · 404 · lạc đường một nhịp',
      nf_brand_aria: 'Ourney, về trang chủ',
      nf_eyebrow: '404 · không tìm thấy trang',
      nf_h1: 'lạc đường một nhịp',
      nf_lede: 'Trang bạn mở không tồn tại hoặc đã đổi địa chỉ. Quay về trang chủ Ourney nhé.',
      nf_cta: 'về trang chủ ourney'
    },
    en: {
      title: 'ourney · One photo at a time, at your own pace · daily photo diary',
      meta_desc: 'Ourney is a daily photo diary for what you want to keep up: language study, running, body goals, a trip, or daily reading, on your own or with close friends.',
      og_title: 'ourney · One photo at a time, at your own pace',
      og_image: 'https://ourney.tech/assets/og/og-default-en.png',
      og_image_alt: 'Ourney: One photo at a time, at your own pace. Daily photo diary on Android and iOS',
      og_url: 'https://ourney.tech/?lang=en',
      og_locale: 'en_US',
      og_locale_alt: 'vi_VN',
      skip: 'Skip to main content',
      nav_brand_aria: 'Ourney, back to top',
      nav_main_aria: 'Main navigation',
      nav_journeys: '6 layouts',
      nav_how: 'how it works',
      nav_squad: 'groups',
      nav_privacy: 'privacy',
      nav_faq: 'faq',
      nav_cta: 'Android APK / iOS waitlist',
      nav_lang_aria: 'Switch language to Vietnamese',
      nav_theme_aria: 'Toggle light or dark theme',
      stamp_1: 'One photo at a time,',
      stamp_2: 'at your own pace,',
      stamp_3: 'on your own or together.',
      hero_ticket_aria: 'Download Android beta APK or join the iOS waitlist',
      ticket_kicker: 'BETA ACCESS',
      ticket_title: 'Android APK · iOS Waitlist',
      ticket_sub: 'Download on Android or join iOS waitlist',
      hero_phone_alt: 'Ourney app Hub screen: IELTS 7.5 Day 21/30 card, 21 days logged, and Snap Today button',
      hcc_t0: 'IELTS 7.5 · Day 21/30',
      hcc_b0_pre: '20 days logged',
      hcc_b0: '21 days logged',
      hcc_t1: 'Morning Run · 5.4 km',
      hcc_b1: '20/30 sessions',
      hcc_t2: 'Da Lat 7\u00A0Days · Frame 14/24',
      hcc_b2: 'all 5 checked in',
      hero_h1: 'One photo at a time, at your own pace',
      hero_lede: 'A photo diary for what you want to keep up, from language study, running, and body goals to a trip or ten pages of reading. Keep it private or check in with close friends.',
      hero_cta_primary: 'Android APK / iOS waitlist',
      hero_cta_secondary: 'see 6 layouts',
      hero_cta_android: 'Download Android APK',
      hero_cta_ios: 'Join iOS beta waitlist',
      hero_apk_note: 'Android already has a beta APK to download. If you use an iPhone, you can join the iOS waitlist.',
      hero_apk_note_android: 'Android already has a direct beta APK download (Ourney.apk).',
      hero_apk_note_ios: 'If you use an iPhone, you can join the iOS beta waitlist below.',
      hero_scroll_aria: 'Scroll down to explore 6 layouts',
      dock_cta_aria: 'Download Android APK or join the iOS waitlist',
      dock_cta_text: 'Android APK · iOS waitlist',
      dock_cta_btn: 'Get APK / iOS',
      j_eyebrow: 'six templates, six distinct layouts',
      j_h2: 'Each goal gets a layout built for it',
      j_intro: 'Language study follows a stepping-stone path to a Day 30 trophy, running plots a kilometer sparkline, and a trip tapes daily photos along a 35mm film roll. Tap each template below to preview the real screen.',
      j_tablist_aria: 'Choose template layout',
      j_tab_0: 'IELTS 7.5',
      j_tab_1: 'Morning Run',
      j_tab_2: 'Da Lat 7\u00A0Days',
      j_tab_3: '30-Day Body',
      j_tab_4: 'Just Us Two',
      j_tab_5: 'Read 10\u00A0Pages',
      j_stub_lbl: 'Style',
      cs_pill: 'COUPLE · PRIVATE VAULT',
      cs_sub: 'Two photos paired side by side each day',
      cs_title: 'just us two',
      cs_stat: '18 DAYS TOGETHER · 36 PHOTOS',
      cs_stat_sub: 'Both partners checked in today',
      cs_d18: 'DAY 18 · TODAY',
      cs_d17: 'DAY 17 · YESTERDAY',
      cs_nam: 'Nam · 07:30',
      cs_linh: 'Linh · 08:12',
      how_eyebrow: 'how it works',
      how_h2: 'Three quick steps each time you check in',
      how_s1_t: 'Pick a template, snap your first photo',
      how_s1_d: 'Choose from 6 templates and set your goal name, timeframe, and privacy so Ourney sets up the right layout from Day 1.',
      how_s1_alt: 'Step 1 of 5: Choose template layout, Weight Loss card',
      how_s2_t: 'Tap the center shutter to snap',
      how_s2_d: 'The shutter sits right in the center of the bottom dock. Long-press to switch goals, take your photo, and tap Post.',
      how_s2_alt: 'Live camera screen: Read 10 Pages · Day 24 and center dock shutter',
      how_s3_t: 'Look back anytime, share only when you want',
      how_s3_d: 'Each check-in photo lands on your timeline automatically. Whenever you want to share, export a 9:16 Story or 4:5 card with only the stats you pick.',
      how_s3_alt: 'Story share card for Morning Run: 4.6 km, Day 21',
      squad_eyebrow: 'with close friends',
      squad_h2: 'Easy to forget alone, easier when friends check in together',
      squad_desc: 'Invite up to 10 close friends with an 8-character code, with no public follower counts or leaderboards. Open the app to see today’s Polaroid wall and drop sticker reactions on each other’s check-ins.',
      squad_chip_1: 'Up to 10 friends · 8-char invite code',
      squad_chip_2: 'Tap sticker reactions on the board',
      squad_wall_title: 'IELTS 7.5 · GROUP OF 4',
      squad_wall_prog: '3/4 snapped today',
      sq_c1_cap: '“45 min Reading done!”',
      sq_c2_cap: '“Day 21, finished the Reading set”',
      sq_c3_cap: '“Added 30 new vocab words”',
      sq_c4_wait: 'no photo yet today',
      finish_eyebrow: 'finish line',
      finish_h2: 'Wrap up a goal with a keepsake poster',
      finish_desc: 'A trip packs into a 35mm contact-sheet poster, while a study or running goal builds a multi-card recap of the days you checked in.',
      finish_tick_1: 'Crisp 9:16 Story and 4:5 Feed formats',
      finish_tick_2: 'Show total days logged and milestones reached',
      finish_tick_3: 'Hide any sensitive metric before exporting',
      finish_a_alt: 'Da Lat 7-day trip poster with 35mm film strip frames',
      finish_b_alt: 'Completed recap card: 20 photos across 20 days',
      priv_eyebrow: 'privacy & local-first',
      priv_h2: 'Some goals are meant for your eyes only',
      priv_desc: 'Set visibility separately for each goal. On body and weight logs, exact numbers stay masked behind dots until you press and hold below.',
      priv_vis_1: 'Only me',
      priv_vis_2: 'Anyone with link',
      priv_vis_3: 'Group members',
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
      priv_local_chip: 'Local-first storage: snap and save check-in photos on your phone even while offline, then sync when connected. This site only counts visits with cookieless Cloudflare analytics.',
      priv_phone_alt: '30-Day Body screen: weight trend curve with masked numbers and Hold to view button',
      faq_eyebrow: 'faq',
      faq_h2: 'Things you might ask',
      faq_q1: 'Can I use Ourney offline or without creating an account?',
      faq_a1: 'When you are offline, you can still open the camera, snap your check-in photo, and save it on your phone. Your photos sync automatically once you reconnect or join a group.',
      faq_q2: 'How big can a group be, and what if someone joins late?',
      faq_a2: 'Each group holds up to 10 people via an 8-character invite code. Late joiners track their days from the date they join while still seeing the group’s earlier photos.',
      faq_q3: 'Who can see my check-in photos and numbers?',
      faq_a3: 'Each goal has its own privacy setting: Only me, Anyone with link, or Group members. Even on shared goals, you can hide exact metrics and blur external link previews. This site only uses cookieless visit analytics by Cloudflare.',
      faq_q4: 'Can I snap multiple photos a day or import a past trip?',
      faq_a4: 'Multiple photos taken on the same day group cleanly into that day’s entry. You can also import photos from a past trip by capture date to build a dedicated trip timeline.',
      faq_q5: 'When will Ourney launch on iOS and Android?',
      faq_a5: 'Android already has a beta APK to download. If you use an iPhone, you can join the iOS waitlist.',
      beta_eyebrow: 'beta release · android & ios',
      beta_eyebrow_android: 'beta release · android',
      beta_eyebrow_ios: 'beta waitlist · ios',
      beta_h2: 'Start with your first photo today',
      beta_apk_kicker: 'Direct install available now',
      beta_apk_btn: 'Download Android APK (Ourney.apk)',
      beta_apk_note: 'Download Ourney.apk directly for Android phones and open the file to install.',
      beta_ios_lead: 'Using iOS (iPhone) or want notifications when a new update drops? Leave your email for beta updates:',
      beta_ios_lead_android: 'Want notifications when a new Android beta update or Google Play release drops? Leave your email for beta updates:',
      beta_ios_lead_ios: 'Leave your email to join the iOS beta waitlist:',
      beta_plat_aria: 'Select phone platform',
      beta_email_label: 'Email',
      beta_placeholder: 'you@example.com',
      beta_submit: 'get beta updates',
      beta_stub_kicker: 'DAY 01',
      beta_stub_title: 'BETA PASS',
      form_err: 'That email doesn’t look right, please check and try again.',
      form_plat_err: 'Please select at least one platform (iOS or Android).',
      form_ok: 'You’re on the beta list for iOS and Android!',
      form_ok_ios: 'You’re on the iOS beta waitlist!',
      form_ok_android: 'You’re on the Android beta list!',
      form_ok_both: 'You’re on the beta list for iOS and Android!',
      form_sending: 'Sending…',
      form_fail: 'Couldn’t send that. Please try again in a few minutes.',
      form_rate: 'Too many tries. Please wait a bit and try again.',
      beta_tiktok_follow: 'Follow @ourney.official on TikTok while you wait',
      footer_tagline: 'One photo at a time, at your own pace',
      footer_journeys: '6 layouts',
      footer_privacy: 'privacy',
      footer_faq: 'faq',
      footer_beta: 'Android APK / iOS waitlist',
      nf_title: 'ourney · 404 · off the trail for a beat',
      nf_brand_aria: 'Ourney, back to home',
      nf_eyebrow: '404 · page not found',
      nf_h1: 'off the trail for a beat',
      nf_lede: 'The page you opened doesn’t exist or has moved. Head back to the Ourney homepage.',
      nf_cta: 'back to ourney home'
    }
  };

  /* --- 2. 6-Persona Chameleon Data (Section 2) --- */
  const JOURNEYS = [
    {
      skin: 'squad', screen: 'j-ielts', no: '01',
      vi: {
        label: 'IELTS 7.5', kind: 'Học ngoại ngữ · Học cùng nhóm',
        title: 'Hôm nay học được bao lâu',
        desc: 'Con đường từng chặng dẫn tới chiếc cúp ngày 30 do bạn tự đặt tên. Mỗi buổi học đính thêm một tấm ảnh lên lộ trình.',
        chips: ['Con đường cúp', '45 phút/ngày', 'Nhóm 5 người'],
        alt: 'Màn hình IELTS 7.5 trong ứng dụng Ourney'
      },
      en: {
        label: 'IELTS 7.5', kind: 'Language study · Study with friends',
        title: 'How long you studied today',
        desc: 'A winding stepping-stone path leading to a Day 30 trophy you name yourself. Every study session pins a photo checkpoint along the trail.',
        chips: ['Trophy trail', '45 min/day', 'Group of 5'],
        alt: 'IELTS 7.5 screen in Ourney app'
      }
    },
    {
      skin: 'flexer', screen: 'j-run', no: '02',
      vi: {
        label: 'Chạy sáng', kind: 'Tập luyện · Theo dõi chỉ số',
        title: 'Mỗi buổi tập thêm một vạch',
        desc: 'Quãng đường từng buổi nối thành biểu đồ đầu trang, kèm tiến độ 20/30 buổi và thẻ Story 9:16 xuất ra bất cứ lúc nào.',
        chips: ['Biểu đồ km', 'Kính mờ neon', 'Story 9:16'],
        alt: 'Màn hình Chạy sáng trong ứng dụng Ourney'
      },
      en: {
        label: 'Morning Run', kind: 'Workout · Pace & distance',
        title: 'Every run adds to the chart',
        desc: 'Daily kilometers plot into a sparkline with 20/30 progress on top, ready to export as a 9:16 Story card.',
        chips: ['Pace sparkline', 'Neon glass', '9:16 Story'],
        alt: 'Morning Run screen in Ourney app'
      }
    },
    {
      skin: 'memory', screen: 'j-travel', no: '03',
      vi: {
        label: 'Đà Lạt 7\u00A0ngày', kind: 'Chuyến đi · Sổ ảnh cuộn phim',
        title: 'Hôm nay cả nhóm đi qua những đâu',
        desc: 'Cuộn phim 24 khung trên nền giấy ấm, ảnh mỗi ngày dán băng keo dọc sợi chỉ khâu và ghép thành poster 35mm khi kết thúc chuyến đi.',
        chips: ['Chỉ khâu & băng keo', 'Cuộn 24 tấm', 'Poster 35mm'],
        alt: 'Màn hình Đà Lạt 7 ngày trong ứng dụng Ourney'
      },
      en: {
        label: 'Da Lat 7\u00A0Days', kind: 'Trip · Film contact sheet',
        title: 'Where the trip took you today',
        desc: 'A 24-frame roll on warm paper where daily photos tape along a stitched thread and pack into a 35mm film poster at the end.',
        chips: ['Stitched scrapbook', '24-frame roll', '35mm poster'],
        alt: 'Da Lat 7 Days trip screen in Ourney app'
      }
    },
    {
      skin: 'quiet', screen: 'j-weight', no: '04',
      vi: {
        label: '30\u00A0ngày cơ thể', kind: 'Cơ thể & cân nặng · Riêng tư',
        title: 'Nhìn lại thay đổi từng chút một',
        desc: 'Mặc định chỉ mình bạn xem. Đường biểu đồ vẫn nối qua từng mốc ảnh, còn số cân được che bằng dấu chấm cho tới khi bạn nhấn giữ.',
        chips: ['Riêng tư mặc định', 'Khung căn dáng', 'Giữ để xem kg'],
        alt: 'Màn hình 30 ngày cơ thể trong ứng dụng Ourney'
      },
      en: {
        label: '30-Day Body', kind: 'Body & weight · Private by default',
        title: 'Track changes privately over time',
        desc: 'Private to you by default. The trend line connects milestone photos while exact weight numbers stay masked behind dots until you press and hold.',
        chips: ['Private vault', 'Day-1 ghost guide', 'Hold to view kg'],
        alt: '30-Day Body screen in Ourney app'
      }
    },
    {
      skin: 'couple', screen: 'j-couple', no: '05',
      vi: {
        label: 'Chúng mình', kind: 'Cặp đôi · Khung ảnh ghép đôi',
        title: 'Mỗi ngày hai tấm ảnh ghép cạnh nhau',
        desc: 'Mỗi ngày là một khung ảnh đôi đặt cạnh nhau. Ảnh của người chụp trước hiện ở góc màn hình camera để người kia chụp ghép nốt tấm còn lại.',
        chips: ['Khung ảnh đôi', 'Ảnh góc PiP', 'Chỉ hai người'],
        alt: 'Màn hình Chúng mình trong ứng dụng Ourney: 30 ngày nấu ăn cùng nhau, 18 ngày đã chụp và khung ảnh đôi của Nam và Linh'
      },
      en: {
        label: 'Just Us Two', kind: 'Couple · Paired daily photos',
        title: 'Two photos paired side by side each day',
        desc: 'Each day pairs both partners side by side: whoever snaps first appears as a corner picture-in-picture guide while the other completes the pair.',
        chips: ['Paired diptych', 'Partner PiP', '2-person vault'],
        alt: 'Just Us Two couple screen in Ourney app: 18 days logged and paired daily photos from Nam and Linh'
      }
    },
    {
      skin: 'minimal', screen: 'j-minimal', no: '06',
      vi: {
        label: 'Đọc 10\u00A0trang', kind: 'Thói quen tự chọn · Lưới lịch tối giản',
        title: 'Mỗi ngày thêm một ô ảnh trên lịch',
        desc: 'Lưới lịch 7 cột gọn gàng, không bắt gõ chữ. Chụp xong bấm Đăng là tấm ảnh hôm nay hiện ngay vào ô lịch của tháng.',
        chips: ['Lưới 7 cột', 'Không gõ chữ', 'Mốc 7 · 15 · 30'],
        alt: 'Màn hình Đọc 10 trang trong ứng dụng Ourney'
      },
      en: {
        label: 'Read 10\u00A0Pages', kind: 'Custom habit · Minimal calendar grid',
        title: 'One photo square on the calendar each day',
        desc: 'A clean 7-column monthly calendar grid with no text fields required. Snap and tap Post to place today’s photo square onto the calendar.',
        chips: ['7-col grid', 'Quick check-in', 'Day 7 · 15 · 30'],
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
  let streakTicked = isReducedMotion() || root.classList.contains('intro-seen');

  /* --- 2b. Detect Platform (Android / iOS / Desktop) & Sync Platform CTAs --- */
  const detectPlatform = () => {
    const ua = navigator.userAgent || '';
    const uaPlat = (navigator.userAgentData && typeof navigator.userAgentData.platform === 'string')
      ? navigator.userAgentData.platform
      : '';
    const touchPoints = Number(navigator.maxTouchPoints || 0);
    if (/^android$/i.test(uaPlat)) return 'android';
    if (/^(ios|ipad|ipados|iphone|ipod)$/i.test(uaPlat)) return 'ios';
    if (/iPhone|iPad|iPod|FBIOS/i.test(ua) || (/Macintosh/i.test(ua) && touchPoints > 1)) {
      return 'ios';
    }
    if (
      /Android/i.test(ua) ||
      (/X11;\s*Linux/i.test(ua) && touchPoints > 1 && matchMedia('(pointer: coarse)').matches)
    ) {
      return 'android';
    }
    return 'desktop';
  };
  const platform = detectPlatform();
  root.dataset.platform = platform;

  const heroAndroidDl = $('hero-android-dl');
  const heroIosBeta = $('hero-ios-beta');
  const heroApkNote = $('hero-apk-note') || document.querySelector('.hero-apk-note');
  const betaApkBox = $('beta-apk-box');
  const betaEyebrow = $('beta-eyebrow') || document.querySelector('[data-i18n="beta_eyebrow"]');
  const betaIosLead = $('beta-ios-lead') || document.querySelector('.beta-ios-lead');
  const betaStubCode = $('beta-stub-code') || document.querySelector('.cta-stub-code');

  const syncPlatformCtas = () => {
    const dict = COPY[curLang];
    if (platform === 'ios') {
      if (heroAndroidDl) heroAndroidDl.hidden = true;
      if (betaApkBox) betaApkBox.hidden = true;
      if (heroIosBeta) {
        heroIosBeta.hidden = false;
        heroIosBeta.classList.remove('btn-secondary');
        heroIosBeta.classList.add('btn-primary');
      }
      if (heroApkNote) {
        heroApkNote.dataset.i18n = 'hero_apk_note_ios';
        heroApkNote.textContent = dict.hero_apk_note_ios;
      }
      if (betaEyebrow) {
        betaEyebrow.dataset.i18n = 'beta_eyebrow_ios';
        betaEyebrow.textContent = dict.beta_eyebrow_ios;
      }
      if (betaIosLead) {
        betaIosLead.dataset.i18n = 'beta_ios_lead_ios';
        betaIosLead.textContent = dict.beta_ios_lead_ios;
      }
      if (betaStubCode) betaStubCode.textContent = 'IOS · BETA';
    } else if (platform === 'android') {
      if (heroAndroidDl) heroAndroidDl.hidden = false;
      if (betaApkBox) betaApkBox.hidden = false;
      if (heroIosBeta) heroIosBeta.hidden = true;
      if (heroApkNote) {
        heroApkNote.dataset.i18n = 'hero_apk_note_android';
        heroApkNote.textContent = dict.hero_apk_note_android;
      }
      if (betaEyebrow) {
        betaEyebrow.dataset.i18n = 'beta_eyebrow_android';
        betaEyebrow.textContent = dict.beta_eyebrow_android;
      }
      if (betaIosLead) {
        betaIosLead.dataset.i18n = 'beta_ios_lead_android';
        betaIosLead.textContent = dict.beta_ios_lead_android;
      }
      if (betaStubCode) betaStubCode.textContent = 'ANDROID · APK';
    } else {
      if (heroAndroidDl) heroAndroidDl.hidden = false;
      if (betaApkBox) betaApkBox.hidden = false;
      if (heroIosBeta) {
        heroIosBeta.hidden = false;
        heroIosBeta.classList.remove('btn-primary');
        heroIosBeta.classList.add('btn-secondary');
      }
      if (heroApkNote) {
        heroApkNote.dataset.i18n = 'hero_apk_note';
        heroApkNote.textContent = dict.hero_apk_note;
      }
      if (betaEyebrow) {
        betaEyebrow.dataset.i18n = 'beta_eyebrow';
        betaEyebrow.textContent = dict.beta_eyebrow;
      }
      if (betaIosLead) {
        betaIosLead.dataset.i18n = 'beta_ios_lead';
        betaIosLead.textContent = dict.beta_ios_lead;
      }
      if (betaStubCode) betaStubCode.textContent = 'IOS · ANDROID';
    }
  };
  syncPlatformCtas();

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
    if (jChips) jChips.innerHTML = copy.chips.map((c) => `<span class="j-chip">${c}</span>`).join('');
    if (jCouple) jCouple.setAttribute('aria-label', JOURNEYS[4][curLang].alt);

    const swapScreen = () => {
      if (!jPic || !jImg || !jSrcD || !phoneJ) return;
      if (item.screen) {
        if (jCouple) jCouple.hidden = true;
        jPic.hidden = false;
        jImg.src = `/assets/screens/${item.screen}.webp`;
        jSrcD.srcset = `/assets/screens/${item.screen}-dark.webp`;
        jImg.alt = copy.alt;
      } else if (jCouple) {
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
  const form = $('beta-form'), msg = $('form-msg'), email = $('email'), betaFollow = $('beta-follow');
  const platGroup = $('platform-group') || document.querySelector('.platform-group');
  const platPills = [...document.querySelectorAll('.plat-pill')];
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

  const getSelectedPlatforms = () =>
    platPills
      .filter((b) => b.getAttribute('aria-pressed') === 'true')
      .map((b) => b.getAttribute('data-plat'))
      .filter((p) => p === 'ios' || p === 'android');

  const setSelectedPlatforms = (targets) => {
    const set = new Set(targets);
    platPills.forEach((pill) => {
      const p = pill.getAttribute('data-plat');
      pill.setAttribute('aria-pressed', String(set.has(p)));
    });
    if (platGroup && set.size > 0) {
      platGroup.removeAttribute('aria-invalid');
    }
  };

  /* Initialize platform selection without preselecting a wrong OS:
     - Explicit ?plat=ios|android query param wins
     - iOS device preselects iOS
     - Android device preselects Android
     - Desktop preselects neither until the user chooses */
  (() => {
    let initialPlat = '';
    try {
      const qp = (new URLSearchParams(location.search).get('plat') || '').toLowerCase();
      if (qp === 'ios' || qp === 'android') initialPlat = qp;
    } catch (e) {}
    if (!initialPlat && (platform === 'ios' || platform === 'android')) {
      initialPlat = platform;
    }
    setSelectedPlatforms(initialPlat ? [initialPlat] : []);
  })();

  platPills.forEach((pill) => {
    pill.addEventListener('click', () => {
      const cur = pill.getAttribute('aria-pressed') === 'true';
      if (cur) {
        const activeCount = getSelectedPlatforms().length;
        if (activeCount <= 1) {
          if (platGroup) platGroup.setAttribute('aria-invalid', 'true');
          announce('form_plat_err');
          return;
        }
        pill.setAttribute('aria-pressed', 'false');
      } else {
        pill.setAttribute('aria-pressed', 'true');
        if (platGroup) platGroup.removeAttribute('aria-invalid');
        if (formMsgKey === 'form_plat_err') announce('');
      }
    });
  });

  document.querySelectorAll('[data-select-plat]').forEach((link) => {
    link.addEventListener('click', () => {
      const targetPlat = link.getAttribute('data-select-plat');
      if (targetPlat === 'ios' || targetPlat === 'android') {
        setSelectedPlatforms([targetPlat]);
        if (formMsgKey === 'form_plat_err') announce('');
      }
      setTimeout(() => {
        if (email) email.focus({ preventScroll: true });
      }, 320);
    });
  });

  const confirmKeyForPlatforms = (platforms) => {
    const hasIos = platforms.includes('ios');
    const hasAndroid = platforms.includes('android');
    if (hasIos && hasAndroid) return 'form_ok_both';
    if (hasIos) return 'form_ok_ios';
    if (hasAndroid) return 'form_ok_android';
    return 'form_ok';
  };

  if (form && email) {
    // Endpoint of the waitlist-signup Edge Function, set in <meta name="ourney-waitlist-endpoint">.
    const endpointMeta = document.querySelector('meta[name="ourney-waitlist-endpoint"]');
    const endpoint = endpointMeta ? endpointMeta.getAttribute('content') || '' : '';
    const submitBtn = form.querySelector('button[type="submit"]');
    const honeypot = form.querySelector('input[name="website"]');
    let sending = false;
    form.addEventListener('submit', async (e) => {
      e.preventDefault();
      if (sending) return;
      if (betaFollow) betaFollow.hidden = true;
      const platforms = getSelectedPlatforms();
      if (platforms.length === 0) {
        if (platGroup) platGroup.setAttribute('aria-invalid', 'true');
        announce('form_plat_err');
        if (platPills[0]) platPills[0].focus();
        return;
      }
      if (platGroup) platGroup.removeAttribute('aria-invalid');
      const ok = Boolean(email.value.trim()) && email.checkValidity();
      email.setAttribute('aria-invalid', ok ? 'false' : 'true');
      if (!ok) {
        announce('form_err');
        email.focus();
        return;
      }
      if (!/^https:\/\//.test(endpoint) || endpoint.includes('PROJECT_REF')) {
        announce('form_fail');
        return;
      }
      sending = true;
      if (submitBtn) submitBtn.disabled = true;
      form.setAttribute('aria-busy', 'true');
      announce('form_sending');
      let key = 'form_fail';
      try {
        const res = await fetch(endpoint, {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({
            email: email.value.trim(),
            lang: curLang,
            platforms,
            source: 'landing',
            website: honeypot ? honeypot.value : '',
          }),
        });
        if (res.ok && (await res.json())?.ok === true) key = confirmKeyForPlatforms(platforms);
        else if (res.status === 429) key = 'form_rate';
        else if (res.status === 400) key = 'form_err';
      } catch (_) {
        key = 'form_fail';
      }
      sending = false;
      if (submitBtn) submitBtn.disabled = false;
      form.removeAttribute('aria-busy');
      announce(key);
      if (key.startsWith('form_ok')) {
        form.reset();
        if (betaFollow) betaFollow.hidden = false;
      } else {
        if (betaFollow) betaFollow.hidden = true;
        if (key === 'form_err') {
          email.setAttribute('aria-invalid', 'true');
          email.focus();
        }
      }
    });
    // Only reveal the controls once the JSON submit handler is installed.
    form.hidden = false;
    if (platGroup) platGroup.hidden = false;
    const waitlistHelp = $('beta-waitlist-help');
    if (waitlistHelp) waitlistHelp.hidden = true;
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
    syncPlatformCtas();
    reactChips.forEach(syncReactChipAria);
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
