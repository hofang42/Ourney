(() => {
  const root = document.documentElement;
  root.classList.add('js', 'hero-settled');
  const $ = (id) => document.getElementById(id);
  const darkMql = matchMedia('(prefers-color-scheme: dark)');

  /* --- 1. Supabase Public Config (mirrors apps/landing/index.html & env.json) --- */
  const DEFAULT_SUPABASE_URL = 'https://dmgpwpaouiphhrtukcie.supabase.co';
  const DEFAULT_SUPABASE_ANON_KEY = 'sb_publishable_YP_EL-U5_VqOKJpMuXexmA_eCQpc5Kt';

  const getMetaContent = (name, fallback) => {
    const el = document.querySelector(`meta[name="${name}"]`);
    return (el && el.getAttribute('content')) || fallback;
  };

  /* --- 2. Bilingual Copy Dictionary (VI default + EN) --- */
  const COPY = {
    vi: {
      skip: 'Bỏ qua tới nội dung chính',
      nav_brand_aria: 'Ourney, về trang chủ',
      nav_lang_aria: 'Chuyển ngôn ngữ sang tiếng Anh',
      nav_theme_aria: 'Đổi giao diện sáng hoặc tối',
      open_in_app: 'Mở trong app',
      inapp_hint: 'Đang mở từ ứng dụng chat? Chạm “Mở trong app”, hoặc chọn Mở bằng trình duyệt (Safari / Chrome) ở góc màn hình nếu nút không phản hồi.',
      back_home: 'Về trang chủ Ourney',
      copy_code: 'Sao chép mã',
      copy_done: 'Đã sao chép mã',
      fallback_title: 'Chưa có ứng dụng Ourney trên máy?',
      fallback_title_p: 'Bắt đầu Ngày 1 của riêng bạn trên Ourney',
      fallback_android: 'Tải APK',
      fallback_ios: 'iOS · đăng ký danh sách chờ beta',
      fallback_note: 'Sau khi cài đặt ứng dụng, chạm lại vào liên kết này để mở thẳng lời mời.',
      fallback_note_desktop: 'Sau khi cài đặt ứng dụng trên điện thoại, quét mã QR bên cạnh hoặc mở lại liên kết này để vào thẳng lời mời.',
      fallback_note_ios: 'Bản iOS đang mở đăng ký danh sách chờ beta. Để lại email để nhận lời mời ngay khi Ourney ra mắt trên iPhone.',
      fallback_note_j: 'Sau khi cài ứng dụng, mở tab Nhóm → Nhập mã mời để tham gia cùng hội bạn.',
      fallback_note_p: 'Chụp một tấm mỗi ngày, giữ một chuỗi, đi một mình hoặc cùng hội bạn thân.',
      qr_aria: 'Mã QR của liên kết hiện tại để mở trên điện thoại',
      qr_heading: 'Mở trên điện thoại',
      qr_desc: 'Quét mã QR bằng camera điện thoại để mở trực tiếp trang này trên iOS hoặc Android.',
      footer_tagline: 'chụp một tấm. giữ một chuỗi. đi cùng nhau.',
      footer_home: 'trang chủ',
      footer_beta: 'nhận lời mời',

      /* Friend (/f/:token) */
      f_meta_title: 'ourney · lời mời kết bạn trên Ourney',
      f_meta_desc: 'Bạn được mời kết bạn trên Ourney — mở trong ứng dụng để kết nối, chia sẻ hành trình ảnh mỗi ngày và giữ chuỗi cùng nhau.',
      f_kicker: 'VÉ MỜI KẾT BẠN · OURNEY',
      f_loading: 'Đang tải lời mời kết bạn…',
      f_headline: 'Bạn được mời kết bạn trên Ourney',
      f_invited_suffix: ' mời bạn kết bạn trên Ourney',
      f_desc: 'Mở lời mời trong ứng dụng Ourney để kết bạn ngay, cùng chia sẻ hành trình ảnh mỗi ngày và giữ liền chuỗi ngày không bỏ cuộc.',
      f_expired_h1: 'Lời mời không còn hiệu lực',
      f_expired_desc: 'Có thể bạn ấy đã đổi sang liên kết mời mới. Hãy nhờ bạn ấy gửi lại liên kết mới cho bạn nhé.',
      f_invalid_h1: 'Liên kết lời mời không hợp lệ',
      f_invalid_desc: 'Đường dẫn kết bạn này bị thiếu mã hoặc không đúng định dạng. Nhờ bạn bè gửi lại liên kết mới hoặc mở trực tiếp trong ứng dụng Ourney.',

      /* Squad (/j/:code, /join/:code) */
      j_meta_title: 'ourney · lời mời vào squad trên Ourney',
      j_meta_desc: 'Bạn được mời vào squad trên Ourney — mở trong ứng dụng hoặc sao chép mã mời để tham gia tường Polaroid mỗi ngày cùng nhóm bạn.',
      j_kicker: 'VÉ MỜI SQUAD · TỐI ĐA 10 BẠN',
      j_kicker_fmt: (max) =>
        (typeof max === 'number' && max > 0 ? `VÉ MỜI SQUAD · TỐI ĐA ${max} BẠN` : 'VÉ MỜI SQUAD · TỐI ĐA 10 BẠN'),
      j_loading: 'Đang tải thông tin squad…',
      j_headline: 'Bạn được mời vào squad',
      j_headline_named_prefix: 'Vào squad ',
      j_headline_named_suffix: ' trên Ourney',
      j_members_fmt: (count, max) =>
        (typeof max === 'number' && max > 0 ? `${count}/${max} thành viên` : `${count} thành viên`),
      j_owner_fmt: (name) => `Squad của ${name}`,
      j_desc: 'Một mình dễ quên, có hội thì giữ được. Mở thẳng trong ứng dụng Ourney hoặc sao chép mã bên dưới để vào tường Polaroid của nhóm.',
      j_code_label: 'MÃ MỜI VÀO SQUAD',
      j_expired_h1: 'Mã mời không còn hiệu lực',
      j_expired_desc: 'Squad này có thể đã đổi mã mời mới hoặc đã kết thúc hành trình. Hãy nhờ thành viên trong nhóm gửi lại liên kết mời mới nhé.',
      j_full_h1: 'Squad này đã đủ thành viên',
      j_full_desc: 'Nhóm đã đạt số lượng thành viên tối đa. Bạn có thể tự mở một hành trình mới hoặc nhờ bạn bè tạo squad khác trên Ourney.',
      j_invalid_h1: 'Mã mời squad không hợp lệ',
      j_invalid_desc: 'Mã mời vào nhóm trong liên kết này bị thiếu hoặc không đúng định dạng. Hãy kiểm tra lại mã mời từ trưởng nhóm.',

      /* Public Journey (/p/:token) */
      p_meta_title: 'ourney · hành trình ảnh được chia sẻ trên Ourney',
      p_meta_desc: 'Xem trọn chuỗi ngày không bỏ cuộc trên Ourney — nhật ký ảnh mỗi ngày cho điều bạn muốn kiên trì.',
      p_kicker: 'HÀNH TRÌNH ĐƯỢC CHIA SẺ',
      p_kicker_group: 'HÀNH TRÌNH NHÓM ĐƯỢC CHIA SẺ',
      p_kicker_imported: 'HÀNH TRÌNH KỶ NIỆM',
      p_loading: 'Đang tải hành trình…',
      p_by_owner: (name) => `bởi ${name}`,
      p_by_anon: 'bởi Thành viên Ourney',
      p_streak: (n) => `Chuỗi ${n} ngày`,
      p_days_moments: (days, photos) => `${days} ngày · ${photos} ảnh`,
      p_moments_only: (photos) => `${photos} khoảnh khắc`,
      p_duration: (d) => `Mục tiêu ${d} ngày`,
      p_status_ended: 'ĐÃ VỀ ĐÍCH',
      p_status_live: 'ĐANG DIỄN RA',
      p_lessons_label: 'Bài học rút ra',
      p_grid_h: 'Nhật ký ảnh từng ngày',
      p_empty_photos: 'Hành trình này chưa có ảnh công khai nào.',
      p_day_n: (n) => `Ngày ${n}`,
      p_blurred_label: 'Ảnh được làm mờ theo cài đặt riêng tư',
      p_photo_alt: (title, dayLabel, dateStr, cap) => {
        const when = [dayLabel, dateStr ? (dayLabel ? `(${dateStr})` : dateStr) : ''].filter(Boolean).join(' ');
        return `${title}${when ? ' — ' + when : ''}${cap ? ': ' + cap : ''}`;
      },
      p_expired_h1: 'Liên kết không tồn tại hoặc đã thu hồi',
      p_expired_desc: 'Hành trình này đã chuyển về riêng tư, chủ nhân đã đặt lại liên kết chia sẻ, hoặc địa chỉ không đúng.',
      p_error_h1: 'Chưa tải được hành trình',
      p_error_desc: 'Kết nối tạm thời bị gián đoạn. Bạn thử tải lại hoặc mở trực tiếp trong ứng dụng Ourney.',
      p_retry: 'Thử lại'
    },
    en: {
      skip: 'Skip to main content',
      nav_brand_aria: 'Ourney, back to home',
      nav_lang_aria: 'Switch language to Vietnamese',
      nav_theme_aria: 'Toggle light or dark theme',
      open_in_app: 'Open in app',
      inapp_hint: 'Opening from a chat app? Tap “Open in app”, or choose Open in browser (Safari / Chrome) from the corner menu if nothing happens.',
      back_home: 'Back to Ourney home',
      copy_code: 'Copy code',
      copy_done: 'Code copied',
      fallback_title: 'Don’t have Ourney on your phone yet?',
      fallback_title_p: 'Start your own Day 1 on Ourney',
      fallback_android: 'Download APK',
      fallback_ios: 'iOS · join the beta waitlist',
      fallback_note: 'Once installed, tap this link again to open the invite in the app.',
      fallback_note_desktop: 'Once installed on your phone, scan the QR code or reopen this link to open the invite.',
      fallback_note_ios: 'Ourney for iOS is on the beta waitlist. Leave your email to get invited as soon as it launches on iPhone.',
      fallback_note_j: 'Once installed, open the Squad tab → Enter invite code to join your friends.',
      fallback_note_p: 'Snap one photo a day, keep one streak, go solo or with your closest friends.',
      qr_aria: 'QR code of the current URL to open on your phone',
      qr_heading: 'Open on your phone',
      qr_desc: 'Scan this QR code with your phone camera to open this link directly on iOS or Android.',
      footer_tagline: 'snap one photo. keep one streak. go together.',
      footer_home: 'home',
      footer_beta: 'get invite',

      /* Friend (/f/:token) */
      f_meta_title: 'ourney · friend invite on Ourney',
      f_meta_desc: 'You’re invited to be friends on Ourney — open in the app to connect, share daily photo journeys, and keep streaks together.',
      f_kicker: 'FRIEND INVITE PASS · OURNEY',
      f_loading: 'Loading friend invite…',
      f_headline: 'You’re invited to be friends on Ourney',
      f_invited_suffix: ' invited you to be friends on Ourney',
      f_desc: 'Open this invite in the Ourney app to connect right away, share daily photo journeys, and keep your streak alive together.',
      f_expired_h1: 'This invite link is no longer active',
      f_expired_desc: 'Your friend may have created a new invite link. Ask them to resend their latest link.',
      f_invalid_h1: 'Invalid friend invite link',
      f_invalid_desc: 'This friend invite link is missing a token or has an invalid format. Ask your friend for a fresh link or open Ourney directly.',

      /* Squad (/j/:code, /join/:code) */
      j_meta_title: 'ourney · squad invite on Ourney',
      j_meta_desc: 'You’re invited to join a squad on Ourney — open in the app or copy the invite code to join the daily Polaroid wall.',
      j_kicker: 'SQUAD INVITE · UP TO 10 FRIENDS',
      j_kicker_fmt: (max) =>
        (typeof max === 'number' && max > 0 ? `SQUAD INVITE · UP TO ${max} FRIENDS` : 'SQUAD INVITE · UP TO 10 FRIENDS'),
      j_loading: 'Loading squad invite…',
      j_headline: 'You’re invited to join a squad',
      j_headline_named_prefix: 'Join squad ',
      j_headline_named_suffix: ' on Ourney',
      j_members_fmt: (count, max) =>
        (typeof max === 'number' && max > 0 ? `${count}/${max} members` : `${count} members`),
      j_owner_fmt: (name) => `${name}'s squad`,
      j_desc: 'Solo fades fast, squads stick together. Open straight in the Ourney app or copy the code below to join your squad’s Polaroid wall.',
      j_code_label: 'SQUAD INVITE CODE',
      j_expired_h1: 'This squad invite code is no longer active',
      j_expired_desc: 'This squad may have rotated its invite code or completed its journey. Ask a squad member to send you the latest invite link.',
      j_full_h1: 'This squad is already full',
      j_full_desc: 'This squad has reached its maximum member limit. You can start your own journey or ask your friends to create another squad on Ourney.',
      j_invalid_h1: 'Invalid squad invite code',
      j_invalid_desc: 'The squad invite code in this link is missing or malformed. Please double-check the code with your squad owner.',

      /* Public Journey (/p/:token) */
      p_meta_title: 'ourney · shared photo journey on Ourney',
      p_meta_desc: 'See a full daily photo journey on Ourney — one photo a day to keep the streak alive.',
      p_kicker: 'SHARED PHOTO JOURNEY',
      p_kicker_group: 'SHARED SQUAD JOURNEY',
      p_kicker_imported: 'KEEPSAKE JOURNEY',
      p_loading: 'Loading journey…',
      p_by_owner: (name) => `by ${name}`,
      p_by_anon: 'by Ourney member',
      p_streak: (n) => `${n}-day streak`,
      p_days_moments: (days, photos) => `${days} days · ${photos} photos`,
      p_moments_only: (photos) => `${photos} moments`,
      p_duration: (d) => `${d}-day goal`,
      p_status_ended: 'COMPLETED',
      p_status_live: 'ACTIVE',
      p_lessons_label: 'Lessons learned',
      p_grid_h: 'Daily photo timeline',
      p_empty_photos: 'No public photos in this journey yet.',
      p_day_n: (n) => `Day ${n}`,
      p_blurred_label: 'Photo blurred by author’s privacy settings',
      p_photo_alt: (title, dayLabel, dateStr, cap) => {
        const when = [dayLabel, dateStr ? (dayLabel ? `(${dateStr})` : dateStr) : ''].filter(Boolean).join(' ');
        return `${title}${when ? ' — ' + when : ''}${cap ? ': ' + cap : ''}`;
      },
      p_expired_h1: 'Link expired, invalid, or revoked',
      p_expired_desc: 'This journey is now private, its owner rotated the share link, or the address is invalid.',
      p_error_h1: 'Couldn’t load this journey',
      p_error_desc: 'The connection was interrupted. Please try again or open the link directly in the Ourney app.',
      p_retry: 'Try again'
    }
  };

  /* --- 3. Theme Resolution & Toggle --- */
  const isDark = () => (root.dataset.theme ? root.dataset.theme === 'dark' : darkMql.matches);
  const syncThemeMeta = () => {
    const dark = isDark();
    const metaL = $('meta-theme-light');
    const metaD = $('meta-theme-dark');
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
  syncThemeMeta();

  const themeToggle = $('theme-toggle');
  if (themeToggle) {
    themeToggle.addEventListener('click', () => {
      const next = isDark() ? 'light' : 'dark';
      root.dataset.theme = next;
      try { localStorage.setItem('ourney-theme', next); } catch (e) {}
      syncThemeMeta();
    });
  }
  darkMql.addEventListener('change', syncThemeMeta);

  /* --- 4. Language Resolution --- */
  let curLang = 'vi';
  try {
    const q = new URLSearchParams(location.search).get('lang');
    const saved = localStorage.getItem('ourney-lang');
    if (q === 'en' || q === 'vi') curLang = q;
    else if (saved === 'en' || saved === 'vi') curLang = saved;
  } catch (e) {}

  /* --- 5. Detect Platform (Android / iOS / Desktop) & In-App WebView --- */
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
  const detectInAppBrowser = () => {
    const ua = navigator.userAgent || '';
    return /\b(FBAN|FBAV|FB_IAB|FBIOS|Instagram|Zalo|ZaloTheme|Line|MicroMessenger|BytedanceWebview|TikTok|Musical\.ly|Threads|Snapchat)\b/i.test(ua);
  };
  const platform = detectPlatform();
  const isInAppBrowser = detectInAppBrowser();
  root.dataset.platform = platform;
  if (isInAppBrowser) {
    root.dataset.inapp = '1';
  }

  /* --- 6. Parse & Validate Route Parameters (/f/:token, /j/:code, /join/:code, /p/:token) --- */
  const FRIEND_TOKEN_RE = /^[a-z0-9]{12}$/;
  const TOKEN_RE = /^[A-Za-z0-9_-]{1,64}$/;
  const SQUAD_CODE_RE = /^[A-Z0-9]{8}$/;

  function parseRoute() {
    const path = location.pathname || '/';
    const params = new URLSearchParams(location.search);
    const pageAttr = root.dataset.linkPage || '';

    let kind = pageAttr;
    let rawParam = '';

    const fMatch = path.match(/^\/f\/([^/?#]+)\/?$/i);
    const jMatch = path.match(/^\/(?:j|join)\/([^/?#]+)\/?$/i);
    const pMatch = path.match(/^\/p\/([^/?#]+)\/?$/i);

    if (fMatch) {
      kind = 'friend';
      try { rawParam = decodeURIComponent(fMatch[1]).trim(); } catch (e) { rawParam = ''; }
    } else if (jMatch) {
      kind = 'squad';
      try { rawParam = decodeURIComponent(jMatch[1]).trim(); } catch (e) { rawParam = ''; }
    } else if (pMatch) {
      kind = 'journey';
      try { rawParam = decodeURIComponent(pMatch[1]).trim(); } catch (e) { rawParam = ''; }
    } else {
      rawParam = (params.get('token') || params.get('code') || '').trim();
    }

    if (kind === 'friend') {
      const cleaned = rawParam.toLowerCase();
      const valid = FRIEND_TOKEN_RE.test(cleaned);
      return {
        kind: 'friend',
        valid,
        value: valid ? cleaned : '',
        deepLink: valid ? `ourney://friend/${encodeURIComponent(cleaned)}` : ''
      };
    }

    if (kind === 'squad') {
      const cleaned = rawParam.replace(/[\s\-_.]/g, '').toUpperCase();
      const valid = SQUAD_CODE_RE.test(cleaned);
      return {
        kind: 'squad',
        valid,
        value: valid ? cleaned : '',
        deepLink: valid ? `ourney://join/${encodeURIComponent(cleaned)}` : ''
      };
    }

    if (kind === 'journey') {
      const valid = TOKEN_RE.test(rawParam);
      return {
        kind: 'journey',
        valid,
        value: valid ? rawParam : '',
        deepLink: valid ? `ourney://p/${encodeURIComponent(rawParam)}` : ''
      };
    }

    return { kind: 'unknown', valid: false, value: '', deepLink: '' };
  }

  const route = parseRoute();
  if (route.deepLink) {
    root.dataset.deepLink = route.deepLink;
  }

  /* --- 7. Auto-Attempt to Open App on Mobile Once (Non-Breaking Pattern) --- */
  function attemptOpenAppOnce(deepLink) {
    if (!deepLink) return;
    /* Do not auto-navigate to ourney:// on desktop, inside in-app WebViews
       (Messenger, Zalo, Instagram, TikTok, Line, WeChat), or on iOS while
       Ourney is waitlist-only; users still have the explicit #open-app-btn. */
    if (platform === 'desktop' || platform === 'ios' || isInAppBrowser || navigator.webdriver) {
      return;
    }
    const params = new URLSearchParams(location.search);
    if (params.get('noapp') === '1') return;

    const sessionKey = `ourney-auto-open:${location.pathname}`;
    try {
      if (sessionStorage.getItem(sessionKey) === '1') return;
      sessionStorage.setItem(sessionKey, '1');
    } catch (e) {}

    root.dataset.autoOpenAttempted = '1';

    setTimeout(() => {
      if (document.hidden) return;
      try {
        location.assign(deepLink);
      } catch (e) {}
    }, 180);
  }

  /* --- 8. Local ISO/IEC 18004 QR Code Generator (Byte Mode, ECC Level L, Versions 1..10, Zero External Services) --- */
  const QR_V_TABLE = [
    null,
    { total: 26, data: 19, ec: 7, blocks: 1, align: [] },
    { total: 44, data: 34, ec: 10, blocks: 1, align: [6, 18] },
    { total: 70, data: 55, ec: 15, blocks: 1, align: [6, 22] },
    { total: 100, data: 80, ec: 20, blocks: 1, align: [6, 26] },
    { total: 134, data: 108, ec: 26, blocks: 1, align: [6, 30] },
    { total: 172, data: 136, ec: 18, blocks: 2, align: [6, 34] },
    { total: 196, data: 156, ec: 20, blocks: 2, align: [6, 22, 38] },
    { total: 242, data: 194, ec: 24, blocks: 2, align: [6, 24, 42] },
    { total: 292, data: 232, ec: 30, blocks: 2, align: [6, 26, 46] },
    { total: 346, data: 274, ec: 18, blocks: 4, align: [6, 28, 50] }
  ];

  const GF_EXP = new Uint8Array(512);
  const GF_LOG = new Uint8Array(256);
  (() => {
    let x = 1;
    for (let i = 0; i < 255; i++) {
      GF_EXP[i] = x;
      GF_LOG[x] = i;
      x <<= 1;
      if (x & 0x100) x ^= 0x11d;
    }
    for (let i = 255; i < 512; i++) GF_EXP[i] = GF_EXP[i - 255];
  })();

  function gfMul(a, b) {
    return (a === 0 || b === 0) ? 0 : GF_EXP[GF_LOG[a] + GF_LOG[b]];
  }

  function rsGeneratorPoly(degree) {
    let poly = new Uint8Array([1]);
    for (let i = 0; i < degree; i++) {
      const next = new Uint8Array(poly.length + 1);
      const root = GF_EXP[i];
      for (let j = 0; j < poly.length; j++) {
        next[j] ^= poly[j];
        next[j + 1] ^= gfMul(poly[j], root);
      }
      poly = next;
    }
    return poly;
  }

  function rsEncode(dataBytes, ecLen) {
    const gen = rsGeneratorPoly(ecLen);
    const rem = new Uint8Array(ecLen);
    for (let i = 0; i < dataBytes.length; i++) {
      const factor = dataBytes[i] ^ rem[0];
      for (let j = 0; j < ecLen - 1; j++) rem[j] = rem[j + 1];
      rem[ecLen - 1] = 0;
      if (factor !== 0) {
        for (let j = 0; j < ecLen; j++) {
          rem[j] ^= gfMul(gen[j + 1], factor);
        }
      }
    }
    return rem;
  }

  function buildQrMatrix(text) {
    const bytes = new TextEncoder().encode(text);
    let ver = 1;
    while (ver <= 10) {
      const lenBits = ver < 10 ? 8 : 16;
      const capBytes = Math.floor((QR_V_TABLE[ver].data * 8 - 4 - lenBits) / 8);
      if (bytes.length <= capBytes) break;
      ver++;
    }
    if (ver > 10) ver = 10;
    const spec = QR_V_TABLE[ver];
    const lenBits = ver < 10 ? 8 : 16;
    const maxInput = Math.floor((spec.data * 8 - 4 - lenBits) / 8);
    const payload = bytes.length > maxInput ? bytes.slice(0, maxInput) : bytes;

    /* Pack bit stream: mode 0100 (Byte), char count, payload bytes, terminator, pad bytes */
    const bits = [];
    const pushBits = (val, count) => {
      for (let i = count - 1; i >= 0; i--) bits.push((val >>> i) & 1);
    };
    pushBits(0b0100, 4);
    pushBits(payload.length, lenBits);
    for (let i = 0; i < payload.length; i++) pushBits(payload[i], 8);

    const maxDataBits = spec.data * 8;
    const term = Math.min(4, maxDataBits - bits.length);
    pushBits(0, term);
    while (bits.length % 8 !== 0) bits.push(0);

    const codewords = new Uint8Array(spec.data);
    for (let i = 0; i < bits.length / 8; i++) {
      let b = 0;
      for (let j = 0; j < 8; j++) b = (b << 1) | bits[i * 8 + j];
      codewords[i] = b;
    }
    const pads = [0xec, 0x11];
    for (let i = bits.length / 8, p = 0; i < spec.data; i++, p ^= 1) {
      codewords[i] = pads[p];
    }

    /* Split into blocks, compute Reed-Solomon EC, and interleave */
    const numBlocks = spec.blocks;
    const baseDataLen = Math.floor(spec.data / numBlocks);
    const extraBlocks = spec.data % numBlocks;
    const dataBlocks = [];
    const ecBlocks = [];
    let offset = 0;
    for (let b = 0; b < numBlocks; b++) {
      const dLen = baseDataLen + (b >= numBlocks - extraBlocks ? 1 : 0);
      const slice = codewords.slice(offset, offset + dLen);
      offset += dLen;
      dataBlocks.push(slice);
      ecBlocks.push(rsEncode(slice, spec.ec));
    }

    const finalBytes = [];
    const maxBlockLen = baseDataLen + (extraBlocks > 0 ? 1 : 0);
    for (let i = 0; i < maxBlockLen; i++) {
      for (let b = 0; b < numBlocks; b++) {
        if (i < dataBlocks[b].length) finalBytes.push(dataBlocks[b][i]);
      }
    }
    for (let i = 0; i < spec.ec; i++) {
      for (let b = 0; b < numBlocks; b++) {
        finalBytes.push(ecBlocks[b][i]);
      }
    }

    /* Initialize grid */
    const size = 17 + ver * 4;
    const grid = Array.from({ length: size }, () => new Uint8Array(size));
    const reserved = Array.from({ length: size }, () => new Uint8Array(size));

    const setMod = (r, c, dark, res = true) => {
      if (r < 0 || r >= size || c < 0 || c >= size) return;
      grid[r][c] = dark ? 1 : 0;
      if (res) reserved[r][c] = 1;
    };

    const placeFinder = (row, col) => {
      for (let dr = -1; dr <= 7; dr++) {
        for (let dc = -1; dc <= 7; dc++) {
          const r = row + dr;
          const c = col + dc;
          if (r < 0 || r >= size || c < 0 || c >= size) continue;
          const inOuter = dr >= 0 && dr <= 6 && dc >= 0 && dc <= 6;
          const onBorder = dr === 0 || dr === 6 || dc === 0 || dc === 6;
          const inCore = dr >= 2 && dr <= 4 && dc >= 2 && dc <= 4;
          setMod(r, c, inOuter && (onBorder || inCore), true);
        }
      }
    };

    placeFinder(0, 0);
    placeFinder(0, size - 7);
    placeFinder(size - 7, 0);

    /* Alignment patterns */
    const align = spec.align;
    for (let i = 0; i < align.length; i++) {
      for (let j = 0; j < align.length; j++) {
        if ((i === 0 && j === 0) || (i === 0 && j === align.length - 1) || (i === align.length - 1 && j === 0)) {
          continue;
        }
        const cr = align[i];
        const cc = align[j];
        for (let dr = -2; dr <= 2; dr++) {
          for (let dc = -2; dc <= 2; dc++) {
            const dark = Math.max(Math.abs(dr), Math.abs(dc)) !== 1;
            setMod(cr + dr, cc + dc, dark, true);
          }
        }
      }
    }

    /* Timing patterns */
    for (let i = 8; i < size - 8; i++) {
      if (!reserved[6][i]) setMod(6, i, i % 2 === 0, true);
      if (!reserved[i][6]) setMod(i, 6, i % 2 === 0, true);
    }

    /* Dark module & reserve format areas */
    setMod(4 * ver + 9, 8, true, true);
    for (let i = 0; i < 9; i++) {
      if (!reserved[8][i]) reserved[8][i] = 1;
      if (!reserved[i][8]) reserved[i][8] = 1;
    }
    for (let i = 0; i < 8; i++) {
      if (!reserved[8][size - 1 - i]) reserved[8][size - 1 - i] = 1;
      if (!reserved[size - 1 - i][8]) reserved[size - 1 - i][8] = 1;
    }

    /* Version info for ver >= 7 */
    if (ver >= 7) {
      let rem = ver;
      for (let i = 0; i < 12; i++) rem = (rem << 1) ^ ((rem >>> 11) * 0x1f25);
      const vBits = (ver << 12) | rem;
      for (let i = 0; i < 18; i++) {
        const bit = ((vBits >>> i) & 1) === 1;
        const a = size - 11 + (i % 3);
        const b = Math.floor(i / 3);
        setMod(b, a, bit, true);
        setMod(a, b, bit, true);
      }
    }

    /* Place data bits in upward/downward 2-column zig-zag */
    let bitIdx = 0;
    const totalBits = finalBytes.length * 8;
    let upward = true;
    for (let right = size - 1; right >= 1; right -= 2) {
      if (right === 6) right = 5;
      for (let vert = 0; vert < size; vert++) {
        const r = upward ? size - 1 - vert : vert;
        for (let j = 0; j < 2; j++) {
          const c = right - j;
          if (reserved[r][c]) continue;
          let dark = false;
          if (bitIdx < totalBits) {
            dark = ((finalBytes[bitIdx >>> 3] >>> (7 - (bitIdx & 7))) & 1) === 1;
            bitIdx++;
          }
          grid[r][c] = dark ? 1 : 0;
        }
      }
      upward = !upward;
    }

    /* Apply mask 0 ((r + c) % 2 === 0) and write BCH format info for ECC L (01), mask 000 */
    for (let r = 0; r < size; r++) {
      for (let c = 0; c < size; c++) {
        if (!reserved[r][c] && (r + c) % 2 === 0) {
          grid[r][c] ^= 1;
        }
      }
    }

    const formatData = (0b01 << 3) | 0; // ECC Level L (01) + Mask 0 (000)
    let fRem = formatData;
    for (let i = 0; i < 10; i++) fRem = (fRem << 1) ^ ((fRem >>> 9) * 0x537);
    const formatBits = ((formatData << 10) | fRem) ^ 0x5412;

    for (let i = 0; i <= 5; i++) setMod(8, i, ((formatBits >>> i) & 1) === 1, true);
    setMod(8, 7, ((formatBits >>> 6) & 1) === 1, true);
    setMod(8, 8, ((formatBits >>> 7) & 1) === 1, true);
    setMod(7, 8, ((formatBits >>> 8) & 1) === 1, true);
    for (let i = 9; i < 15; i++) setMod(14 - i, 8, ((formatBits >>> i) & 1) === 1, true);

    for (let i = 0; i < 8; i++) setMod(8, size - 1 - i, ((formatBits >>> i) & 1) === 1, true);
    for (let i = 8; i < 15; i++) setMod(size - 15 + i, 8, ((formatBits >>> i) & 1) === 1, true);

    return { size, grid };
  }

  function renderQrSvg(container, urlText) {
    if (!container || !urlText) return;
    try {
      const { size, grid } = buildQrMatrix(urlText);
      const quiet = 2;
      const total = size + quiet * 2;
      const ns = 'http://www.w3.org/2000/svg';
      const svg = document.createElementNS(ns, 'svg');
      svg.setAttribute('viewBox', `0 0 ${total} ${total}`);
      svg.setAttribute('width', '128');
      svg.setAttribute('height', '128');
      svg.setAttribute('aria-hidden', 'true');
      svg.setAttribute('shape-rendering', 'crispEdges');

      const bg = document.createElementNS(ns, 'rect');
      bg.setAttribute('width', String(total));
      bg.setAttribute('height', String(total));
      bg.setAttribute('fill', '#FFFFFF');
      svg.appendChild(bg);

      let d = '';
      for (let r = 0; r < size; r++) {
        for (let c = 0; c < size; c++) {
          if (grid[r][c]) {
            d += `M${c + quiet},${r + quiet}h1v1h-1z`;
          }
        }
      }
      const path = document.createElementNS(ns, 'path');
      path.setAttribute('d', d);
      path.setAttribute('fill', '#1A1A1A');
      svg.appendChild(path);

      container.replaceChildren(svg);
    } catch (e) {}
  }

  const qrBox = $('qr-box');
  if (qrBox && platform === 'desktop') {
    renderQrSvg(qrBox, location.href);
  }

  /* --- 9. Render Friend Page (/f/:token) --- */
  const CLIENT_RPC_TIMEOUT_MS = 4000;
  let friendPageState = 'loading'; // 'loading' | 'loaded' | 'fallback' | 'expired' | 'invalid'
  let loadedFriendData = null;
  let qrHighlightTimer = null;

  function firstGrapheme(raw) {
    const str = typeof raw === 'string' ? raw.trim() : '';
    if (!str) return '';
    if (typeof Intl !== 'undefined' && typeof Intl.Segmenter === 'function') {
      const seg = new Intl.Segmenter(undefined, { granularity: 'grapheme' });
      const first = seg.segment(str)[Symbol.iterator]().next();
      if (first && first.value && first.value.segment) {
        return first.value.segment.toUpperCase();
      }
    }
    const cp = Array.from(str)[0];
    return cp ? cp.toUpperCase() : '';
  }

  function syncFallbackCard(isDeadLink) {
    const qrPanel = $('qr-panel');
    const fbAndroid = $('fallback-android');
    const fbIos = $('fallback-ios');
    const fbNote = $('fallback-note') || document.querySelector('.link-fallback-note');
    const dict = COPY[curLang];

    if (qrPanel) {
      qrPanel.hidden = Boolean(isDeadLink || platform !== 'desktop');
    }
    if (fbAndroid) {
      fbAndroid.hidden = platform === 'ios';
    }
    if (fbIos) {
      fbIos.hidden = platform === 'android';
    }
    if (fbNote) {
      fbNote.hidden = Boolean(isDeadLink);
      if (route.kind === 'journey') {
        fbNote.dataset.i18n = 'fallback_note_p';
        fbNote.textContent = dict.fallback_note_p;
      } else if (platform === 'ios') {
        fbNote.dataset.i18n = 'fallback_note_ios';
        fbNote.textContent = dict.fallback_note_ios;
      } else if (route.kind === 'squad') {
        fbNote.dataset.i18n = 'fallback_note_j';
        fbNote.textContent = dict.fallback_note_j;
      } else if (platform === 'desktop') {
        fbNote.dataset.i18n = 'fallback_note_desktop';
        fbNote.textContent = dict.fallback_note_desktop;
      } else {
        fbNote.dataset.i18n = 'fallback_note';
        fbNote.textContent = dict.fallback_note;
      }
    }
  }

  function wireOpenAppButton(openBtn) {
    const inappHint = $('inapp-hint');
    if (inappHint) {
      inappHint.hidden = !isInAppBrowser;
    }
    if (!openBtn) return;
    if (route.deepLink) {
      openBtn.dataset.deepLink = route.deepLink;
    }
    if (platform === 'desktop') {
      openBtn.setAttribute('href', '#qr-panel');
    } else if (route.deepLink) {
      openBtn.setAttribute('href', route.deepLink);
    } else {
      openBtn.setAttribute('href', '#fallback-heading');
    }
    if (openBtn.dataset.wired === '1') return;
    openBtn.dataset.wired = '1';
    openBtn.addEventListener('click', (e) => {
      if (platform === 'desktop') {
        e.preventDefault();
        const qrPanel = $('qr-panel');
        const target = (qrPanel && !qrPanel.hidden)
          ? qrPanel
          : document.querySelector('.link-fallback-card');
        if (target && typeof target.scrollIntoView === 'function') {
          target.scrollIntoView({ behavior: 'smooth', block: 'center' });
        }
        if (qrPanel && !qrPanel.hidden) {
          qrPanel.classList.add('is-highlighted');
          clearTimeout(qrHighlightTimer);
          qrHighlightTimer = setTimeout(() => {
            qrPanel.classList.remove('is-highlighted');
          }, 1800);
        }
      }
    });
  }

  function readEmbeddedPreview(keyName, expectedValue) {
    const raw = root.getAttribute('data-invite-preview');
    if (!raw) return null;
    try {
      const parsed = JSON.parse(raw);
      if (!parsed || typeof parsed !== 'object') return null;
      if (parsed[keyName] !== expectedValue) return null;
      if (parsed.status === 'ok' && parsed.data && typeof parsed.data === 'object') {
        return { status: 'ok', data: parsed.data };
      }
      if (parsed.status === 'empty') {
        return { status: 'empty', data: null };
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  function getRpcEndpoint(rpcName) {
    const supabaseUrl = getMetaContent('ourney-supabase-url', DEFAULT_SUPABASE_URL).replace(/\/+$/, '');
    const anonKey = getMetaContent('ourney-supabase-anon-key', DEFAULT_SUPABASE_ANON_KEY);
    const isLocalhost = location.hostname === '127.0.0.1' || location.hostname === 'localhost';
    const hasCustomMetaUrl = Boolean(document.querySelector('meta[name="ourney-supabase-url"]'));
    const baseUrl = (isLocalhost && !hasCustomMetaUrl) ? location.origin : supabaseUrl;
    const headers = { 'Content-Type': 'application/json' };
    if (anonKey) {
      headers.apikey = anonKey;
      headers.Authorization = `Bearer ${anonKey}`;
    }
    return { url: `${baseUrl}/rest/v1/rpc/${rpcName}`, headers };
  }

  function renderFriendState() {
    const validCard = $('f-valid-card');
    const expiredCard = $('f-expired-card');
    const invalidCard = $('f-invalid-card');
    const loadingSkel = $('f-loading-skel');
    const loadingMsg = $('f-loading-msg');
    const inviterBox = $('f-inviter-box');
    const stickerCluster = $('f-sticker-cluster');
    const avatarInitialEl = $('f-avatar-initial');
    const handleEl = $('f-inviter-handle');
    const titleEl = $('f-title');
    const descEl = $('f-desc');
    const dict = COPY[curLang];

    if (friendPageState === 'invalid') {
      if (validCard) validCard.hidden = true;
      if (expiredCard) expiredCard.hidden = true;
      if (invalidCard) invalidCard.hidden = false;
      syncFallbackCard(true);
      document.title = dict.f_meta_title;
      return;
    }

    if (friendPageState === 'expired') {
      if (validCard) validCard.hidden = true;
      if (expiredCard) expiredCard.hidden = false;
      if (invalidCard) invalidCard.hidden = true;
      syncFallbackCard(true);
      document.title = dict.f_meta_title;
      return;
    }

    syncFallbackCard(false);
    if (validCard) {
      validCard.hidden = false;
      validCard.setAttribute('aria-busy', friendPageState === 'loading' ? 'true' : 'false');
    }
    if (expiredCard) expiredCard.hidden = true;
    if (invalidCard) invalidCard.hidden = true;

    if (friendPageState === 'loading') {
      if (loadingSkel) loadingSkel.hidden = false;
      if (loadingMsg) loadingMsg.hidden = false;
      if (inviterBox) inviterBox.hidden = true;
      if (stickerCluster) stickerCluster.hidden = true;
      if (titleEl) titleEl.hidden = true;
      if (descEl) descEl.hidden = true;
      document.title = dict.f_meta_title;
      return;
    }

    if (loadingSkel) loadingSkel.hidden = true;
    if (loadingMsg) loadingMsg.hidden = true;
    if (titleEl) titleEl.hidden = false;
    if (descEl) {
      descEl.hidden = false;
      descEl.textContent = dict.f_desc;
    }

    if (friendPageState === 'loaded' && loadedFriendData) {
      const displayName = typeof loadedFriendData.display_name === 'string'
        ? loadedFriendData.display_name.trim()
        : '';
      const handle = typeof loadedFriendData.handle === 'string'
        ? loadedFriendData.handle.trim().replace(/^@+/, '')
        : '';
      const rawInitial = typeof loadedFriendData.avatar_initial === 'string'
        ? loadedFriendData.avatar_initial.trim()
        : '';
      const initial = firstGrapheme(rawInitial || displayName || handle || 'O') || 'O';

      if (inviterBox) inviterBox.hidden = false;
      if (stickerCluster) stickerCluster.hidden = true;
      if (avatarInitialEl) avatarInitialEl.textContent = initial;
      if (handleEl) {
        if (handle) {
          handleEl.hidden = false;
          handleEl.textContent = `@${handle}`;
        } else {
          handleEl.hidden = true;
          handleEl.textContent = '';
        }
      }

      if (titleEl && displayName) {
        const b = document.createElement('b');
        b.textContent = displayName;
        const suffix = document.createTextNode(dict.f_invited_suffix);
        titleEl.replaceChildren(b, suffix);
        document.title = `ourney · ${displayName}${dict.f_invited_suffix}`;
      } else if (titleEl) {
        const b = document.createElement('b');
        b.textContent = dict.f_headline;
        titleEl.replaceChildren(b);
        document.title = dict.f_meta_title;
      }
      return;
    }

    /* Fetch failure -> generic headline (current copy), still with Open-in-app */
    if (inviterBox) inviterBox.hidden = true;
    if (stickerCluster) stickerCluster.hidden = false;
    if (titleEl) {
      const b = document.createElement('b');
      b.textContent = dict.f_headline;
      titleEl.replaceChildren(b);
    }
    document.title = dict.f_meta_title;
  }

  async function fetchFriendPreview() {
    const embedded = readEmbeddedPreview('token', route.value);
    if (embedded) {
      if (embedded.status === 'ok' && embedded.data && typeof embedded.data.display_name === 'string' && embedded.data.display_name.trim()) {
        loadedFriendData = embedded.data;
        friendPageState = 'loaded';
      } else {
        loadedFriendData = null;
        friendPageState = 'expired';
      }
      renderFriendState();
      return;
    }

    friendPageState = 'loading';
    renderFriendState();

    const { url, headers } = getRpcEndpoint('preview_friend_invite');
    const controller = new AbortController();
    const timer = setTimeout(() => controller.abort(), CLIENT_RPC_TIMEOUT_MS);
    try {
      const res = await fetch(url, {
        method: 'POST',
        headers,
        body: JSON.stringify({ p_token: route.value }),
        signal: controller.signal
      });
      if (!res.ok) {
        friendPageState = 'fallback';
        renderFriendState();
        return;
      }
      const data = await res.json();
      if (!data || typeof data !== 'object' || typeof data.display_name !== 'string' || !data.display_name.trim()) {
        friendPageState = 'expired';
        loadedFriendData = null;
        renderFriendState();
        return;
      }
      loadedFriendData = data;
      friendPageState = 'loaded';
      renderFriendState();
    } catch (e) {
      friendPageState = 'fallback';
      renderFriendState();
    } finally {
      clearTimeout(timer);
    }
  }

  function initFriendPage() {
    const openBtn = $('open-app-btn');

    if (!route.valid) {
      friendPageState = 'invalid';
      renderFriendState();
      return;
    }

    wireOpenAppButton(openBtn);
    attemptOpenAppOnce(route.deepLink);
    fetchFriendPreview();
  }

  /* --- 10. Render Squad Page (/j/:code, /join/:code) --- */
  let codeCopied = false;
  let copyResetTimer = null;
  let squadPageState = 'idle'; // 'loading' | 'loaded' | 'fallback' | 'expired' | 'full' | 'invalid'
  let loadedSquadData = null;

  function isSquadFull(data) {
    if (!data || typeof data !== 'object') return false;
    const count = typeof data.member_count === 'number' && Number.isFinite(data.member_count)
      ? data.member_count
      : 0;
    const max = typeof data.max_members === 'number' && Number.isFinite(data.max_members)
      ? data.max_members
      : 0;
    return max > 0 && count >= max;
  }

  function renderSquadState() {
    const validCard = $('j-valid-card');
    const expiredCard = $('j-expired-card');
    const expiredTitleEl = $('j-expired-title');
    const expiredDescEl = $('j-expired-desc') || (expiredCard ? expiredCard.querySelector('.link-lede') : null);
    const invalidCard = $('j-invalid-card');
    const loadingSkel = $('j-loading-skel');
    const loadingMsg = $('j-loading-msg');
    const squadMeta = $('j-squad-meta');
    const squadNameEl = $('j-squad-name');
    const squadMembersEl = $('j-squad-members');
    const inviterPill = $('j-squad-inviter-pill');
    const inviterEl = $('j-squad-inviter');
    const titleEl = $('j-title');
    const kickerEl = document.querySelector('[data-i18n="j_kicker"]');
    const dict = COPY[curLang];

    if (squadPageState === 'invalid') {
      if (validCard) validCard.hidden = true;
      if (expiredCard) expiredCard.hidden = true;
      if (invalidCard) invalidCard.hidden = false;
      syncFallbackCard(true);
      document.title = dict.j_meta_title;
      return;
    }

    if (squadPageState === 'expired' || squadPageState === 'full') {
      if (validCard) validCard.hidden = true;
      if (expiredCard) expiredCard.hidden = false;
      if (invalidCard) invalidCard.hidden = true;
      const isFull = squadPageState === 'full';
      if (expiredTitleEl) {
        const b = document.createElement('b');
        b.dataset.i18n = isFull ? 'j_full_h1' : 'j_expired_h1';
        b.textContent = isFull ? dict.j_full_h1 : dict.j_expired_h1;
        expiredTitleEl.replaceChildren(b);
      }
      if (expiredDescEl) {
        expiredDescEl.dataset.i18n = isFull ? 'j_full_desc' : 'j_expired_desc';
        expiredDescEl.textContent = isFull ? dict.j_full_desc : dict.j_expired_desc;
      }
      syncFallbackCard(true);
      document.title = dict.j_meta_title;
      return;
    }

    syncFallbackCard(false);
    if (validCard) {
      validCard.hidden = false;
      validCard.setAttribute('aria-busy', squadPageState === 'loading' ? 'true' : 'false');
    }
    if (expiredCard) expiredCard.hidden = true;
    if (invalidCard) invalidCard.hidden = true;

    if (squadPageState === 'loading') {
      if (loadingSkel) loadingSkel.hidden = false;
      if (loadingMsg) loadingMsg.hidden = false;
      if (squadMeta) squadMeta.hidden = true;
      return;
    }

    if (loadingSkel) loadingSkel.hidden = true;
    if (loadingMsg) loadingMsg.hidden = true;

    if (squadPageState === 'loaded' && loadedSquadData) {
      const rawTitle = loadedSquadData.title || loadedSquadData.group_name || '';
      const title = typeof rawTitle === 'string' ? rawTitle.trim() : '';
      const memberCount = typeof loadedSquadData.member_count === 'number' && Number.isFinite(loadedSquadData.member_count)
        ? loadedSquadData.member_count
        : 0;
      const maxMembers = typeof loadedSquadData.max_members === 'number' && Number.isFinite(loadedSquadData.max_members)
        ? loadedSquadData.max_members
        : 10;
      const rawOwner = loadedSquadData.owner_display_name || '';
      const ownerName = typeof rawOwner === 'string' ? rawOwner.trim() : '';

      if (title) {
        if (kickerEl) kickerEl.textContent = dict.j_kicker_fmt(maxMembers);
        if (squadMeta) squadMeta.hidden = false;
        if (squadNameEl) squadNameEl.textContent = title;
        if (squadMembersEl) squadMembersEl.textContent = dict.j_members_fmt(memberCount, maxMembers);
        if (inviterPill && inviterEl) {
          if (ownerName) {
            inviterPill.hidden = false;
            inviterEl.textContent = dict.j_owner_fmt(ownerName);
          } else {
            inviterPill.hidden = true;
            inviterEl.textContent = '';
          }
        }
        if (titleEl) {
          const prefix = document.createTextNode(dict.j_headline_named_prefix);
          const b = document.createElement('b');
          b.textContent = title;
          const suffix = document.createTextNode(dict.j_headline_named_suffix);
          titleEl.replaceChildren(prefix, b, suffix);
        }
        document.title = `ourney · ${dict.j_headline_named_prefix}${title}${dict.j_headline_named_suffix}`;
        return;
      }
    }

    if (kickerEl) kickerEl.textContent = dict.j_kicker;
    if (squadMeta) squadMeta.hidden = true;
    if (titleEl) {
      const b = document.createElement('b');
      b.textContent = dict.j_headline;
      titleEl.replaceChildren(b);
    }
    document.title = dict.j_meta_title;
  }

  async function fetchSquadPreview() {
    const embedded = readEmbeddedPreview('code', route.value);
    if (embedded) {
      const embTitle = embedded.data && (embedded.data.title || embedded.data.group_name);
      if (embedded.status === 'ok' && typeof embTitle === 'string' && embTitle.trim()) {
        loadedSquadData = embedded.data;
        squadPageState = isSquadFull(embedded.data) ? 'full' : 'loaded';
      } else {
        loadedSquadData = null;
        squadPageState = 'expired';
      }
      renderSquadState();
      return;
    }

    squadPageState = 'loading';
    renderSquadState();

    const { url, headers } = getRpcEndpoint('preview_group_invite');
    const controller = new AbortController();
    const timer = setTimeout(() => controller.abort(), CLIENT_RPC_TIMEOUT_MS);
    try {
      const res = await fetch(url, {
        method: 'POST',
        headers,
        body: JSON.stringify({ p_code: route.value }),
        signal: controller.signal
      });
      if (!res.ok) {
        squadPageState = 'fallback';
        renderSquadState();
        return;
      }
      const data = await res.json();
      const title = data && typeof data === 'object' ? (data.title || data.group_name) : '';
      if (!data || typeof title !== 'string' || !title.trim()) {
        loadedSquadData = null;
        squadPageState = 'expired';
        renderSquadState();
        return;
      }
      loadedSquadData = data;
      squadPageState = isSquadFull(data) ? 'full' : 'loaded';
      renderSquadState();
    } catch (e) {
      squadPageState = 'fallback';
      renderSquadState();
    } finally {
      clearTimeout(timer);
    }
  }

  function initSquadPage() {
    const codeVal = $('squad-code-val');
    const codeSlots = $('squad-code-slots');
    const openBtn = $('open-app-btn');
    const copyBtn = $('copy-code-btn');
    const copyLabel = $('copy-code-label');
    const copyIconDefault = $('copy-icon-default');
    const copyIconDone = $('copy-icon-done');
    const copyLiveMsg = $('copy-live-msg');

    if (!route.valid) {
      squadPageState = 'invalid';
      renderSquadState();
      return;
    }
    if (codeVal) codeVal.textContent = route.value;
    wireOpenAppButton(openBtn);

    if (codeSlots) {
      const frag = document.createDocumentFragment();
      for (const ch of route.value) {
        const slot = document.createElement('span');
        slot.className = 'link-code-char';
        slot.textContent = ch;
        frag.appendChild(slot);
      }
      codeSlots.replaceChildren(frag);
    }

    if (copyBtn) {
      copyBtn.addEventListener('click', async () => {
        codeCopied = true;
        clearTimeout(copyResetTimer);
        const dict = COPY[curLang];
        if (copyLabel) copyLabel.textContent = dict.copy_done;
        if (copyIconDefault) copyIconDefault.setAttribute('hidden', '');
        if (copyIconDone) copyIconDone.removeAttribute('hidden');
        if (copyLiveMsg) copyLiveMsg.textContent = `${dict.copy_done}: ${route.value}`;

        copyResetTimer = setTimeout(() => {
          codeCopied = false;
          if (copyLabel) copyLabel.textContent = COPY[curLang].copy_code;
          if (copyIconDone) copyIconDone.setAttribute('hidden', '');
          if (copyIconDefault) copyIconDefault.removeAttribute('hidden');
        }, 2400);

        try {
          if (navigator.clipboard && navigator.clipboard.writeText) {
            await navigator.clipboard.writeText(route.value);
          } else {
            const ta = document.createElement('textarea');
            ta.value = route.value;
            ta.setAttribute('readonly', '');
            ta.style.position = 'fixed';
            ta.style.opacity = '0';
            document.body.appendChild(ta);
            ta.select();
            document.execCommand('copy');
            ta.remove();
          }
        } catch (e) {}
      });
    }

    attemptOpenAppOnce(route.deepLink);
    fetchSquadPreview();
  }

  /* --- 11. Render Public Journey Page (/p/:token) --- */
  const MAX_IMG_ERROR_RETRIES = 1;
  const MAX_AUTO_REFRESHES = 3;
  const ERROR_BATCH_DELAY_MS = 120;
  const VISIBILITY_DEBOUNCE_MS = 250;

  let loadedJourneyData = null;
  let journeyPageState = 'loading'; // 'loading' | 'loaded' | 'expired' | 'error'
  let journeyFetchedAt = 0;
  let journeyTtlMs = 600 * 1000;
  let journeyFetchBatch = 0;
  let journeyAutoRefreshCount = 0;
  let journeyRefreshFailCount = 0;
  let journeyLastRefreshAttemptAt = 0;
  let journeyRefreshPromise = null;
  let journeyTtlTimer = null;
  let journeyErrorBatchTimer = null;
  let journeyVisDebounceTimer = null;

  const TEMPLATE_ICONS = {
    english_daily: '#i-book',
    study: '#i-book',
    workout_30: '#i-workout',
    workout30: '#i-workout',
    travel: '#i-trip',
    weight_loss: '#i-scales',
    weightLoss: '#i-scales',
    couple: '#i-couple',
    custom: '#i-custom'
  };

  function isSafeMediaUrl(rawUrl) {
    if (typeof rawUrl !== 'string' || !rawUrl.trim()) return false;
    try {
      const u = new URL(rawUrl, location.origin);
      if (u.protocol === 'https:') return true;
      if (u.protocol === 'http:' && (u.hostname === '127.0.0.1' || u.hostname === 'localhost')) return true;
      return false;
    } catch (e) {
      return false;
    }
  }

  function computeDayNumber(startDateStr, localDateStr) {
    if (typeof startDateStr === 'string' && typeof localDateStr === 'string') {
      const s = Date.parse(`${startDateStr}T00:00:00Z`);
      const c = Date.parse(`${localDateStr}T00:00:00Z`);
      if (Number.isFinite(s) && Number.isFinite(c)) {
        const diff = Math.floor((c - s) / 86400000) + 1;
        if (diff >= 1 && diff <= 3660) return diff;
      }
    }
    return null;
  }

  function formatMetricNumber(val, unit) {
    if (typeof val !== 'number' || !Number.isFinite(val)) return '';
    const rounded = Number.isInteger(val) ? String(val) : val.toFixed(1);
    const localized = curLang === 'vi' ? rounded.replace('.', ',') : rounded;
    return unit ? `${localized} ${unit}` : localized;
  }

  function showJourneyState(stateName) {
    journeyPageState = stateName;
    const loadingCard = $('p-loading-card');
    const journeyCard = $('p-journey-card');
    const expiredCard = $('p-expired-card');
    const errorCard = $('p-error-card');

    if (loadingCard) {
      loadingCard.hidden = stateName !== 'loading';
      loadingCard.setAttribute('aria-busy', stateName === 'loading' ? 'true' : 'false');
    }
    if (journeyCard) journeyCard.hidden = stateName !== 'loaded';
    if (expiredCard) expiredCard.hidden = stateName !== 'expired';
    if (errorCard) errorCard.hidden = stateName !== 'error';
    syncFallbackCard(stateName === 'expired');
  }

  function getPublicJourneyRequest() {
    const supabaseUrl = getMetaContent('ourney-supabase-url', DEFAULT_SUPABASE_URL).replace(/\/+$/, '');
    const anonKey = getMetaContent('ourney-supabase-anon-key', DEFAULT_SUPABASE_ANON_KEY);
    const configuredEndpoint = getMetaContent(
      'ourney-public-journey-endpoint',
      `${supabaseUrl}/functions/v1/public-journey`
    );
    const isLocalhost = location.hostname === '127.0.0.1' || location.hostname === 'localhost';
    const endpoint = isLocalhost
      ? `${location.origin}/functions/v1/public-journey`
      : configuredEndpoint;
    const url = `${endpoint}?token=${encodeURIComponent(route.value)}`;
    const headers = (!isLocalhost && anonKey) ? { apikey: anonKey } : {};
    return { url, headers };
  }

  function getMinExpiryAgeMs() {
    return Math.min(30000, Math.max(500, Math.floor(journeyTtlMs * 0.5)));
  }

  function getRefreshCooldownMs() {
    const baseMs = Math.min(30000, Math.max(500, Math.floor(journeyTtlMs * 0.5)));
    return baseMs * Math.pow(2, Math.min(journeyRefreshFailCount, 4));
  }

  function hasUnloadedOrRetryableImages() {
    const gridEl = $('p-photo-grid');
    if (!gridEl) return false;
    const imgs = gridEl.querySelectorAll('img.link-polaroid-img');
    if (imgs.length === 0) return false;
    return Array.from(imgs).some((img) => {
      if (img.dataset.exhausted === '1') return false;
      const retries = Number(img.dataset.retryCount || '0');
      const isBroken = img.dataset.loadFailed === '1' || (img.complete && img.naturalWidth === 0);
      if (isBroken) return retries < MAX_IMG_ERROR_RETRIES;
      const isHealthyLoaded = img.complete && img.naturalWidth > 0;
      return !isHealthyLoaded;
    });
  }

  function scheduleProactiveUrlRefresh() {
    clearTimeout(journeyTtlTimer);
    if (!loadedJourneyData || !route.valid || journeyAutoRefreshCount >= MAX_AUTO_REFRESHES) return;
    const checkIns = Array.isArray(loadedJourneyData.check_ins) ? loadedJourneyData.check_ins : [];
    if (checkIns.length === 0 || !hasUnloadedOrRetryableImages()) return;
    const delayMs = Math.max(15000, Math.floor(journeyTtlMs * 0.85));
    journeyTtlTimer = setTimeout(() => {
      if (document.visibilityState === 'visible' && hasUnloadedOrRetryableImages()) {
        refreshPublicJourneyUrls();
      }
    }, delayMs);
  }

  function updateRenderedPhotoUrls(data) {
    const checkIns = data && Array.isArray(data.check_ins) ? data.check_ins : [];
    const gridEl = $('p-photo-grid');
    if (!gridEl || checkIns.length === 0) return;

    const urlByKey = new Map();
    checkIns.forEach((item, idx) => {
      if (!item || typeof item !== 'object') return;
      const rawUrl = item.photo_url || item.thumb_url || '';
      if (!isSafeMediaUrl(rawUrl)) return;
      const key = item.checkin_id ? String(item.checkin_id) : `idx:${idx}`;
      urlByKey.set(key, rawUrl);
      urlByKey.set(`idx:${idx}`, rawUrl);
    });

    gridEl.querySelectorAll('img.link-polaroid-img').forEach((img, idx) => {
      const key = img.dataset.checkinKey || `idx:${idx}`;
      const freshUrl = urlByKey.get(key) || urlByKey.get(`idx:${idx}`);
      /* Never overwrite src on already-decoded healthy images */
      const isHealthyLoaded = img.complete && img.naturalWidth > 0 && img.dataset.loadFailed !== '1';
      if (isHealthyLoaded) return;

      const isBroken = img.dataset.loadFailed === '1' || (img.complete && img.naturalWidth === 0);
      if (isBroken) {
        const retries = Number(img.dataset.retryCount || '0');
        if (retries >= MAX_IMG_ERROR_RETRIES || img.dataset.exhausted === '1' || !freshUrl) {
          img.dataset.retryCount = String(Math.max(retries, MAX_IMG_ERROR_RETRIES));
          img.dataset.exhausted = '1';
          return;
        }
        img.dataset.retryCount = String(retries + 1);
      }
      if (!freshUrl) return;

      img.dataset.loadFailed = '0';
      img.dataset.retriedBatch = String(journeyFetchBatch);
      img.src = freshUrl;
    });
  }

  async function refreshPublicJourneyUrls() {
    if (!route.valid || route.kind !== 'journey') return null;
    if (journeyRefreshPromise) return journeyRefreshPromise;
    if (journeyAutoRefreshCount >= MAX_AUTO_REFRESHES) return null;

    const now = Date.now();
    if (journeyLastRefreshAttemptAt > 0 && (now - journeyLastRefreshAttemptAt) < getRefreshCooldownMs()) {
      return null;
    }

    /* Stamp attempt & increment counter BEFORE fetch so 500/429/network errors back off cleanly */
    journeyLastRefreshAttemptAt = now;
    journeyAutoRefreshCount += 1;

    const { url, headers } = getPublicJourneyRequest();
    journeyRefreshPromise = (async () => {
      try {
        const res = await fetch(url, { method: 'GET', headers, cache: 'no-store' });
        if (!res.ok) {
          journeyRefreshFailCount += 1;
          return null;
        }
        const data = await res.json();
        if (!data || typeof data !== 'object' || !data.journey) {
          journeyRefreshFailCount += 1;
          return null;
        }
        journeyRefreshFailCount = 0;
        journeyFetchBatch += 1;
        journeyFetchedAt = Date.now();
        if (typeof data.signed_url_ttl_seconds === 'number' && data.signed_url_ttl_seconds > 0) {
          journeyTtlMs = data.signed_url_ttl_seconds * 1000;
        }
        loadedJourneyData = data;
        updateRenderedPhotoUrls(data);
        scheduleProactiveUrlRefresh();
        return data;
      } catch (_) {
        journeyRefreshFailCount += 1;
        return null;
      } finally {
        journeyRefreshPromise = null;
      }
    })();

    return journeyRefreshPromise;
  }

  function scheduleBatchedErrorRefresh() {
    if (journeyErrorBatchTimer || journeyRefreshPromise) return;
    if (journeyAutoRefreshCount >= MAX_AUTO_REFRESHES) return;
    const elapsedSinceLastRefresh = journeyLastRefreshAttemptAt > 0
      ? Date.now() - journeyLastRefreshAttemptAt
      : Infinity;
    const cooldownRemaining = journeyLastRefreshAttemptAt > 0
      ? Math.max(0, getRefreshCooldownMs() - elapsedSinceLastRefresh)
      : 0;
    const delayMs = Math.max(ERROR_BATCH_DELAY_MS, cooldownRemaining);
    journeyErrorBatchTimer = setTimeout(() => {
      journeyErrorBatchTimer = null;
      if (hasUnloadedOrRetryableImages()) {
        refreshPublicJourneyUrls();
      }
    }, delayMs);
  }

  function handleJourneyImageError(img) {
    if (!img) return;
    img.dataset.loadFailed = '1';
    const retries = Number(img.dataset.retryCount || '0');
    if (retries >= MAX_IMG_ERROR_RETRIES || img.dataset.exhausted === '1') {
      img.dataset.exhausted = '1';
      return;
    }
    scheduleBatchedErrorRefresh();
  }

  function renderPublicJourneyData(data) {
    if (!data || typeof data !== 'object' || !data.journey) {
      showJourneyState('expired');
      return;
    }

    const dict = COPY[curLang];
    const j = data.journey || {};
    const story = data.story || {};
    const streak = data.streak || null;
    const checkIns = Array.isArray(data.check_ins) ? data.check_ins : [];

    const title = (typeof story.title === 'string' && story.title.trim())
      ? story.title.trim()
      : (typeof j.title === 'string' && j.title.trim() ? j.title.trim() : 'Ourney');

    const ownerName = (typeof j.owner_display_name === 'string' && j.owner_display_name.trim())
      ? j.owner_display_name.trim()
      : '';

    const templateUse = $('p-template-use');
    if (templateUse) {
      const iconHref = TEMPLATE_ICONS[j.template_id] || '#i-camera';
      templateUse.setAttribute('href', iconHref);
    }

    const eyebrowEl = $('p-eyebrow');
    if (eyebrowEl) {
      if (data.origin === 'imported' || j.origin === 'imported') {
        eyebrowEl.textContent = dict.p_kicker_imported;
      } else if (j.kind === 'group') {
        eyebrowEl.textContent = dict.p_kicker_group;
      } else {
        eyebrowEl.textContent = dict.p_kicker;
      }
    }

    const statusTag = $('p-status-tag');
    if (statusTag) {
      const ended = j.status === 'ended' || j.status === 'archived';
      statusTag.textContent = ended ? dict.p_status_ended : dict.p_status_live;
    }

    const titleEl = $('p-title');
    if (titleEl) titleEl.textContent = title;
    document.title = `ourney · ${title}`;

    const ownerEl = $('p-owner');
    if (ownerEl) {
      ownerEl.hidden = false;
      ownerEl.textContent = ownerName ? dict.p_by_owner(ownerName) : dict.p_by_anon;
    }

    const introEl = $('p-intro');
    if (introEl) {
      const introTxt = typeof story.intro === 'string' ? story.intro.trim() : '';
      introEl.hidden = !introTxt;
      introEl.textContent = introTxt;
    }

    /* Streak & Day Count pills (never show "0 khoảnh khắc" / "0 moments") */
    const statsRow = $('p-stats-row');
    const streakPill = $('p-streak-pill');
    const streakText = $('p-streak-text');
    const streakVal = streak && typeof streak.current === 'number' && streak.current > 0
      ? streak.current
      : (streak && typeof streak.best === 'number' && streak.best > 0 ? streak.best : 0);

    if (streakPill && streakText) {
      if (streakVal > 0) {
        streakPill.hidden = false;
        streakText.textContent = dict.p_streak(streakVal);
      } else {
        streakPill.hidden = true;
      }
    }

    const uniqueDays = new Set(
      checkIns.map((c) => (c && typeof c.local_date === 'string' ? c.local_date : '')).filter(Boolean)
    ).size;
    const completedDays = (streak && typeof streak.completed === 'number' && streak.completed > 0)
      ? streak.completed
      : uniqueDays;

    const daysPill = $('p-days-pill');
    const daysText = $('p-days-text');
    if (daysPill && daysText) {
      if (checkIns.length > 0) {
        daysPill.hidden = false;
        daysText.textContent = completedDays > 0
          ? dict.p_days_moments(completedDays, checkIns.length)
          : dict.p_moments_only(checkIns.length);
      } else {
        daysPill.hidden = true;
        daysText.textContent = '';
      }
    }

    const durationPill = $('p-duration-pill');
    const durationText = $('p-duration-text');
    if (durationPill && durationText) {
      if (typeof j.duration_days === 'number' && j.duration_days > 0) {
        durationPill.hidden = false;
        durationText.textContent = dict.p_duration(j.duration_days);
      } else {
        durationPill.hidden = true;
      }
    }

    if (statsRow) {
      const anyStatVisible = [streakPill, daysPill, durationPill].some((el) => el && !el.hidden);
      statsRow.hidden = !anyStatVisible;
    }

    const openBtn = $('open-app-btn');
    wireOpenAppButton(openBtn);

    /* Story Lessons */
    const lessonsBox = $('p-lessons-box');
    const lessonsText = $('p-lessons-text');
    if (lessonsBox && lessonsText) {
      const lTxt = typeof story.lessons === 'string' ? story.lessons.trim() : '';
      lessonsBox.hidden = !lTxt;
      lessonsText.textContent = lTxt;
    }

    /* Photo Grid (lazy loaded, descriptive alt text, auto signed-URL refresh, zero private data) */
    const gridEl = $('p-photo-grid');
    const emptyEl = $('p-empty-photos');
    if (gridEl && emptyEl) {
      if (checkIns.length === 0) {
        gridEl.replaceChildren();
        gridEl.hidden = true;
        emptyEl.hidden = false;
      } else {
        gridEl.hidden = false;
        emptyEl.hidden = true;
        const frag = document.createDocumentFragment();
        const metricUnit = typeof j.metric_unit === 'string' ? j.metric_unit.trim() : '';

        checkIns.forEach((item, idx) => {
          if (!item || typeof item !== 'object') return;
          const card = document.createElement('article');
          card.className = 'link-polaroid';

          const dateStr = typeof item.local_date === 'string' ? item.local_date : '';
          const dayNum = computeDayNumber(j.start_date, dateStr);
          const dayLabel = dayNum !== null ? dict.p_day_n(dayNum) : '';
          const caption = typeof item.caption === 'string' ? item.caption.trim() : '';
          const rawUrl = item.photo_url || item.thumb_url || '';
          const isBlurred = Boolean(item.blurred || data.media_blurred || !isSafeMediaUrl(rawUrl));

          const frame = document.createElement('div');
          frame.className = isBlurred
            ? 'link-polaroid-frame is-blurred'
            : 'link-polaroid-frame';

          if (!isBlurred) {
            const img = document.createElement('img');
            img.className = 'link-polaroid-img';
            img.loading = 'lazy';
            img.decoding = 'async';
            img.width = 360;
            img.height = 450;
            img.dataset.checkinKey = item.checkin_id ? String(item.checkin_id) : `idx:${idx}`;
            img.dataset.retriedBatch = String(journeyFetchBatch);
            img.dataset.retryCount = '0';
            img.dataset.loadFailed = '0';
            img.src = rawUrl;
            img.alt = dict.p_photo_alt(title, dayLabel, dateStr, caption);
            img.addEventListener('error', () => {
              handleJourneyImageError(img);
            });
            frame.appendChild(img);
          } else {
            const blurBox = document.createElement('div');
            blurBox.className = 'link-polaroid-blur-placeholder';
            blurBox.setAttribute('role', 'img');
            blurBox.setAttribute('aria-label', dict.p_blurred_label);

            const ns = 'http://www.w3.org/2000/svg';
            const svg = document.createElementNS(ns, 'svg');
            svg.setAttribute('class', 'o-sticker');
            svg.setAttribute('width', '36');
            svg.setAttribute('height', '36');
            svg.setAttribute('aria-hidden', 'true');
            const use = document.createElementNS(ns, 'use');
            use.setAttribute('href', '#i-drop');
            svg.appendChild(use);

            const span = document.createElement('span');
            span.textContent = dict.p_blurred_label;

            blurBox.appendChild(svg);
            blurBox.appendChild(span);
            frame.appendChild(blurBox);
          }

          /* Day Badge inside frame (omitted if start_date/local_date is unparseable) */
          if (dayLabel) {
            const badge = document.createElement('span');
            badge.className = 'link-day-badge';
            badge.textContent = dayLabel;
            frame.appendChild(badge);
          }

          card.appendChild(frame);

          /* Meta row (date + optional public metric) */
          const metaRow = document.createElement('div');
          metaRow.className = 'link-polaroid-meta';

          const dateSpan = document.createElement('time');
          dateSpan.className = 'link-polaroid-date';
          if (dateStr) dateSpan.setAttribute('datetime', dateStr);
          dateSpan.textContent = dateStr || dayLabel;
          if (dateSpan.textContent) {
            metaRow.appendChild(dateSpan);
          }

          if (typeof item.metric_value === 'number' && Number.isFinite(item.metric_value)) {
            const metricPill = document.createElement('span');
            metricPill.className = 'link-polaroid-metric';
            metricPill.textContent = formatMetricNumber(item.metric_value, metricUnit);
            metaRow.appendChild(metricPill);
          }

          if (metaRow.childNodes.length > 0) {
            card.appendChild(metaRow);
          }

          if (caption) {
            const capEl = document.createElement('p');
            capEl.className = 'link-polaroid-cap';
            capEl.textContent = caption;
            card.appendChild(capEl);
          }

          frag.appendChild(card);
        });

        gridEl.replaceChildren(frag);
      }
    }

    showJourneyState('loaded');
  }

  async function fetchPublicJourney() {
    if (!route.valid) {
      showJourneyState('expired');
      return;
    }

    showJourneyState('loading');
    const { url, headers } = getPublicJourneyRequest();

    try {
      const res = await fetch(url, { method: 'GET', headers });
      if (res.status === 404 || res.status === 400 || res.status === 410) {
        showJourneyState('expired');
        return;
      }
      if (!res.ok) {
        showJourneyState('error');
        return;
      }
      const data = await res.json();
      clearTimeout(journeyErrorBatchTimer);
      clearTimeout(journeyVisDebounceTimer);
      journeyErrorBatchTimer = null;
      journeyVisDebounceTimer = null;
      journeyFetchBatch += 1;
      journeyFetchedAt = Date.now();
      journeyLastRefreshAttemptAt = 0;
      journeyAutoRefreshCount = 0;
      journeyRefreshFailCount = 0;
      if (data && typeof data.signed_url_ttl_seconds === 'number' && data.signed_url_ttl_seconds > 0) {
        journeyTtlMs = data.signed_url_ttl_seconds * 1000;
      }
      loadedJourneyData = data;
      renderPublicJourneyData(data);
      scheduleProactiveUrlRefresh();
    } catch (e) {
      showJourneyState('error');
    }
  }

  function checkJourneyImagesOnVisible() {
    if (document.visibilityState !== 'visible' || route.kind !== 'journey' || !loadedJourneyData) {
      return;
    }
    if (journeyAutoRefreshCount >= MAX_AUTO_REFRESHES) return;
    const now = Date.now();
    if (journeyLastRefreshAttemptAt > 0 && (now - journeyLastRefreshAttemptAt) < getRefreshCooldownMs()) {
      return;
    }
    const elapsed = now - journeyFetchedAt;

    const gridEl = $('p-photo-grid');
    const hasRetryableBrokenImg = Boolean(
      gridEl &&
      Array.from(gridEl.querySelectorAll('img.link-polaroid-img')).some((img) => {
        if (img.dataset.exhausted === '1') return false;
        const retries = Number(img.dataset.retryCount || '0');
        const isBroken = img.dataset.loadFailed === '1' || (img.complete && img.naturalWidth === 0);
        return isBroken && retries < MAX_IMG_ERROR_RETRIES;
      })
    );
    const nearExpiryWithPending = elapsed >= Math.floor(journeyTtlMs * 0.8) && hasUnloadedOrRetryableImages();
    if (hasRetryableBrokenImg || nearExpiryWithPending) {
      refreshPublicJourneyUrls();
    }
  }

  function scheduleJourneyVisibilityCheck() {
    clearTimeout(journeyVisDebounceTimer);
    journeyVisDebounceTimer = setTimeout(() => {
      journeyVisDebounceTimer = null;
      checkJourneyImagesOnVisible();
    }, VISIBILITY_DEBOUNCE_MS);
  }

  function initJourneyPage() {
    const retryBtn = $('p-retry-btn');
    if (retryBtn) {
      retryBtn.addEventListener('click', () => {
        fetchPublicJourney();
      });
    }
    document.addEventListener('visibilitychange', scheduleJourneyVisibilityCheck);
    window.addEventListener('focus', scheduleJourneyVisibilityCheck);
    if (route.valid) {
      attemptOpenAppOnce(route.deepLink);
    }
    fetchPublicJourney();
  }

  /* --- 12. Bilingual Switcher (VI / EN) --- */
  function applyLanguage(lang, persist) {
    curLang = lang === 'en' ? 'en' : 'vi';
    const dict = COPY[curLang];
    root.lang = curLang;
    root.dataset.lang = curLang;

    document.querySelectorAll('[data-i18n]').forEach((el) => {
      const k = el.dataset.i18n;
      if (typeof dict[k] === 'string') el.textContent = dict[k];
    });
    document.querySelectorAll('[data-i18n-aria]').forEach((el) => {
      const k = el.dataset.i18nAria;
      if (typeof dict[k] === 'string') el.setAttribute('aria-label', dict[k]);
    });

    const homeHref = curLang === 'en' ? '/?lang=en' : '/';
    document.querySelectorAll('[data-home-link]').forEach((el) => {
      el.setAttribute('href', homeHref);
    });
    document.querySelectorAll('[data-waitlist-link]').forEach((el) => {
      const forcedPlat = el.getAttribute('data-waitlist-plat') || (el.id === 'fallback-ios' ? 'ios' : '');
      const targetPlat = forcedPlat || (platform === 'ios' ? 'ios' : (platform === 'android' ? 'android' : ''));
      const waitlistQuery = [
        curLang === 'en' ? 'lang=en' : '',
        targetPlat ? `plat=${targetPlat}` : ''
      ].filter(Boolean).join('&');
      const waitlistHref = waitlistQuery ? `/?${waitlistQuery}#beta-waitlist-box` : '/#beta-waitlist-box';
      el.setAttribute('href', waitlistHref);
    });

    if (route.kind === 'friend') {
      renderFriendState();
    } else if (route.kind === 'squad') {
      renderSquadState();
      const copyLabel = $('copy-code-label');
      if (copyLabel) copyLabel.textContent = codeCopied ? dict.copy_done : dict.copy_code;
    } else if (route.kind === 'journey') {
      if (loadedJourneyData) {
        renderPublicJourneyData(loadedJourneyData);
      } else {
        document.title = dict.p_meta_title;
        syncFallbackCard(journeyPageState === 'expired');
      }
      const fbHeading = $('fallback-heading');
      if (fbHeading) fbHeading.textContent = dict.fallback_title_p;
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
  }

  const langToggle = $('lang-toggle');
  if (langToggle) {
    langToggle.addEventListener('click', () => {
      applyLanguage(curLang === 'vi' ? 'en' : 'vi', true);
    });
  }

  /* --- 13. Bootstrap Current Page --- */
  if (route.kind === 'friend') initFriendPage();
  else if (route.kind === 'squad') initSquadPage();
  else if (route.kind === 'journey') initJourneyPage();

  applyLanguage(curLang, false);
})();
