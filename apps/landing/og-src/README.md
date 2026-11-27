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
| `og-default.{png,jpg}` | `1200×630` | `https://ourney.tech/` (default VI) | `Góp tấm hình, giữ nhịp mình.` |
| `og-default-en.{png,jpg}` | `1200×630` | `https://ourney.tech/?lang=en` (EN) | `One photo at a time, at your own pace.` |
| `og-invite.{png,jpg}` | `1200×630` | `https://ourney.tech/f/<token>` (Friend invites) | `Mời bạn kết bạn, cùng góp ảnh mỗi ngày.` |
| `og-join.{png,jpg}` | `1200×630` | `https://ourney.tech/j/<code>` (Squad 8-char code invites) | `Một mình dễ quên, có hội nhắc nhau thì nhớ.` |
| `og-journey.{png,jpg}` | `1200×630` | `https://ourney.tech/p/<token>` (Public shared journeys) | `Góp tấm hình, giữ nhịp mình.` |
| `og-default-square.{png,jpg}` | `1200×1200` | Compact 1:1 chat templates (WhatsApp / Zalo square fallback) | `Góp tấm hình, giữ nhịp mình.` |
