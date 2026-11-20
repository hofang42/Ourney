(() => {
  const root = document.documentElement;
  const $ = (id) => document.getElementById(id);
  const reduce = matchMedia('(prefers-reduced-motion: reduce)').matches;
  const icon = (n) => `assets/brand/icon-${n}.png`;

  /* theme toggle: system default, remembered per viewer */
  const isDark = () => root.dataset.theme ? root.dataset.theme === 'dark' : matchMedia('(prefers-color-scheme: dark)').matches;
  $('theme-toggle').addEventListener('click', () => {
    const next = isDark() ? 'light' : 'dark';
    root.dataset.theme = next;
    try { localStorage.setItem('ourney-theme', next); } catch (e) {}
  });

  /* nav rule once scrolled */
  const nav = document.querySelector('.nav');
  const onScroll = () => nav.classList.toggle('scrolled', scrollY > 8);
  addEventListener('scroll', onScroll, { passive: true }); onScroll();

  /* ticker band: the app's splash taglines, separated by sticker icons */
  const words = [['chụp một tấm.', 'camera'], ['giữ một chuỗi.', 'flame'], ['đi cùng nhau.', 'squad'], ['nhìn lại từng chút một.', 'star']];
  const set = words.map(([w, i]) => `<span>${w}<img src="${icon(i)}" alt="" width="40" height="40"></span>`).join('');
  $('marquee-track').innerHTML = `<div style="display:flex">${set}${set}</div><div style="display:flex" aria-hidden="true">${set}${set}</div>`;
  const mq = $('marquee'), mqBtn = $('marquee-toggle');
  mqBtn.addEventListener('click', () => {
    const paused = mq.classList.toggle('paused');
    mqBtn.setAttribute('aria-pressed', paused);
    mqBtn.textContent = paused ? 'chạy tiếp' : 'tạm dừng';
  });

  /* journeys: real home screens of each skin (captured from the Flutter app) */
  const J = [
    { key: 'ielts', label: 'IELTS 7.5', icon: 'type-study', c: '#FFD84D', kind: 'học tiếng Anh · Accountability Squad',
      title: 'hôm nay học bao lâu.', desc: 'Một con đường quest dẫn tới chiếc cúp ngày 30 do bạn tự đặt tên. Mỗi buổi học là một ảnh trên đường đi.' },
    { key: 'run', label: 'Chạy sáng', icon: 'type-workout', c: '#CF9FFF', kind: 'tập luyện · Aesthetic Flexer',
      title: 'mỗi buổi chạy một vạch.', desc: 'Số km của từng buổi thành biểu đồ, tiến độ 20/30 hiện ngay đầu trang. Thẻ Story in sẵn quãng đường hôm nay.' },
    { key: 'travel', label: 'Đà Lạt 7 ngày', icon: 'type-trip', c: '#FFB347', kind: 'chuyến đi · Memory Collectors',
      title: 'hôm nay cả bọn lạc ở đâu.', desc: 'Một cuộn phim 24 khung. Ảnh mỗi ngày được dán băng keo dọc sợi chỉ, hết chuyến thì thành poster.' },
    { key: 'weight', label: '30 ngày cơ thể', icon: 'type-weight', c: '#7EE8A2', kind: 'giảm cân · Quiet Transformer',
      title: 'nhìn lại từng chút một.', desc: 'Riêng tư mặc định. Đường cân nặng đi xuống nhưng con số thì ẩn, giữ ngón tay lên mới thấy.' },
    { key: 'minimal', label: 'Đọc 10 trang', icon: 'type-custom', c: '#7EC8E3', kind: 'thói quen tự đặt · Minimalist Habit',
      title: 'một ô mỗi ngày.', desc: 'Lịch chuỗi theo tháng, không trang trí thừa. Các mốc ngày 7, 15 và 30 nhắc bạn đã đi được bao xa.' },
  ];
  const tabs = $('j-tabs');
  const section = document.querySelector('.journeys');
  tabs.innerHTML = J.map((j) => `<button class="j-tab" type="button" role="tab" id="tab-${j.key}" aria-controls="j-panel" aria-selected="false" tabindex="-1" style="--c:${j.c}"><img src="${icon(j.icon)}" alt="" width="32" height="32">${j.label}</button>`).join('');
  const img = $('j-img'), imgD = $('j-img-d');
  let cur = 0;
  const select = (i, focus) => {
    const j = J[i];
    [...tabs.children].forEach((b, k) => { b.setAttribute('aria-selected', k === i); b.tabIndex = k === i ? 0 : -1; });
    if (focus) tabs.children[i].focus();
    section.style.setProperty('--accent', j.c);
    img.src = `assets/screens/j-${j.key}.webp`;
    imgD.src = `assets/screens/j-${j.key}-dark.webp`;
    img.alt = `Trang hành trình ${j.label} trong app Ourney`;
    $('j-panel').setAttribute('aria-labelledby', `tab-${j.key}`);
    $('j-kind').textContent = j.kind;
    $('j-title').textContent = j.title;
    $('j-desc').textContent = j.desc;
  };
  tabs.addEventListener('click', (e) => { const b = e.target.closest('.j-tab'); if (b) { cur = [...tabs.children].indexOf(b); select(cur); } });
  tabs.addEventListener('keydown', (e) => {
    const k = { ArrowRight: 1, ArrowDown: 1, ArrowLeft: -1, ArrowUp: -1 }[e.key];
    if (k) { e.preventDefault(); cur = (cur + k + J.length) % J.length; select(cur, true); }
    if (e.key === 'Home') { e.preventDefault(); cur = 0; select(cur, true); }
    if (e.key === 'End') { e.preventDefault(); cur = J.length - 1; select(cur, true); }
  });
  select(cur);
  J.forEach((j) => { const p = new Image(); p.src = `assets/screens/j-${j.key}.webp`; });

  /* how: the step at the viewport centre drives the sticky phone (desktop);
     the swap images follow the theme */
  const steps = [...document.querySelectorAll('.step')];
  const howPhone = document.querySelector('.phone-how');
  const swaps = [...howPhone.querySelectorAll('.swap')];
  const base = ['create', 'capture', 'share-run'];
  const syncSwapTheme = () => swaps.forEach((s, i) => { s.src = `assets/screens/${base[i]}${isDark() ? '-dark' : ''}.webp`; });
  syncSwapTheme();
  $('theme-toggle').addEventListener('click', syncSwapTheme);
  matchMedia('(prefers-color-scheme: dark)').addEventListener('change', syncSwapTheme);
  const setStep = (n) => { steps.forEach((s, i) => s.classList.toggle('active', i === n)); howPhone.dataset.screen = n; };
  setStep(0);
  const stepIO = new IntersectionObserver((entries) => {
    entries.forEach((en) => { if (en.isIntersecting) setStep(+en.target.dataset.step); });
  }, { rootMargin: '-45% 0px -45% 0px' });
  steps.forEach((s) => stepIO.observe(s));

  /* number ticker (final value is already in the HTML) */
  const tick = (el) => {
    if (reduce) return;
    const to = +el.dataset.to, t0 = performance.now(), dur = 1300;
    const step = (t) => {
      const p = Math.min(1, (t - t0) / dur);
      el.textContent = Math.round(to * (1 - Math.pow(1 - p, 3)));
      if (p < 1) requestAnimationFrame(step);
    };
    requestAnimationFrame(step);
    setTimeout(() => { el.textContent = to; }, dur + 300);
  };

  /* reveal once, staggered per section */
  const io = new IntersectionObserver((entries) => {
    entries.forEach((en) => {
      if (!en.isIntersecting) return;
      en.target.classList.add('in');
      if (en.target.classList.contains('ticker')) tick(en.target);
      io.unobserve(en.target);
    });
  }, { threshold: 0.15, rootMargin: '0px 0px -40px 0px' });
  document.querySelectorAll('section').forEach((sec) => {
    sec.querySelectorAll('.reveal').forEach((el, i) => el.style.setProperty('--d', `${Math.min(i, 6) * 70}ms`));
  });
  document.querySelectorAll('.reveal, .ticker').forEach((el) => io.observe(el));

  /* beta form: preview only, nothing is stored or sent */
  const form = $('beta-form'), msg = $('form-msg'), email = $('email');
  const say = (text) => { msg.textContent = ''; requestAnimationFrame(() => { msg.textContent = text; }); };
  form.addEventListener('submit', (e) => {
    e.preventDefault();
    const ok = email.value.trim() && email.checkValidity();
    email.setAttribute('aria-invalid', ok ? 'false' : 'true');
    if (!ok) { say('Email chưa đúng định dạng, bạn xem lại giúp nhé.'); email.focus(); return; }
    say('Cảm ơn bạn! Đây là bản xem trước nên email chưa được lưu. Danh sách beta sẽ mở sớm.');
    form.reset();
  });
})();
