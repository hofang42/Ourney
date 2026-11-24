# Ourney Open Graph & Brand Icon Source (`apps/landing/og-src/`)

This folder contains the HTML/CSS brand templates and headless-Chrome renderer for Ourney's Open Graph (`1200×630` and `1200×1200`) link preview images and app icons (`apple-touch-icon.png`, `icon-192.png`, `icon-512.png`, `favicon.ico`).

It is excluded from Vercel static deployment via `apps/landing/.vercelignore`.

## Re-rendering Assets

```bash
node apps/landing/og-src/render.mjs
```

## Card Matrix (`apps/landing/assets/og/`)

| Card Name | Dimensions | Target Route / Context | Primary Copy |
| :--- | :---: | :--- | :--- |
| `og-default.{png,jpg}` | `1200×630` | `https://ourney.tech/` (default VI) | `chụp một tấm. giữ một chuỗi. đi cùng nhau.` |
| `og-default-en.{png,jpg}` | `1200×630` | `https://ourney.tech/?lang=en` (EN) | `snap one photo. keep one streak. go together.` |
| `og-invite.{png,jpg}` | `1200×630` | `https://ourney.tech/f/<token>` (Friend invites) | `bạn được mời cùng đi một hành trình.` |
| `og-join.{png,jpg}` | `1200×630` | `https://ourney.tech/j/<code>` (Squad 8-char code invites) | `một mình dễ quên. có hội thì giữ được.` |
| `og-journey.{png,jpg}` | `1200×630` | `https://ourney.tech/p/<token>` (Public shared journeys) | `xem trọn một chuỗi ngày không bỏ cuộc.` |
| `og-default-square.{png,jpg}` | `1200×1200` | Compact 1:1 chat templates (WhatsApp / Zalo square fallback) | `chụp một tấm. giữ một chuỗi. đi cùng nhau.` |
