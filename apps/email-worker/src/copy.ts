// Auto-reply text, Vietnamese first. No response time is promised for general
// mail; the 24h figure is the content-report review the app already states
// (safety_contactIntro, safety_eula4Body).

const VI = `Chào bạn,

Cảm ơn bạn đã viết cho Ourney. Thư của bạn đã đến nơi, một người trong nhóm sẽ đọc và trả lời bạn.

Nếu app bị lỗi hoặc tài khoản có trục trặc, bạn trả lời thư này và gửi kèm:
- tên điện thoại (ví dụ iPhone 13, Galaxy A55)
- phiên bản app (trong Hồ sơ > Cài đặt, dòng Phiên bản)
- ảnh chụp màn hình chỗ bị lỗi, nhớ đừng để lộ mặt ai trong ảnh

Muốn báo cáo một bài đăng hay một người dùng thì bạn bấm Báo cáo ngay trong app cho nhanh. Báo cáo được xem trong vòng 24 giờ.

Ourney`;

const EN = `Hi,

Thanks for writing to Ourney. Your message got through, and someone on the team will read it and reply.

If the app is broken or something is wrong with your account, reply to this email with:
- your phone model (for example iPhone 13, Galaxy A55)
- the app version (Profile > Settings, the Version row)
- a screenshot of the problem, with no faces in it

To report a post or a user, tap Report in the app. That's the fastest way, and reports are reviewed within 24 hours.

Ourney`;

const FOOTER = 'Thư tự động / Automatic reply';

export const replyText = `${VI}\n\n---\n\n${EN}\n\n${FOOTER}\n`;

function escapeHtml(text: string): string {
  return text
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;');
}

function toHtml(block: string): string {
  return block
    .split('\n\n')
    .map((paragraph) => {
      const lines = paragraph.split('\n');
      const items = lines.filter((l) => l.startsWith('- '));
      if (items.length === 0) {
        return `<p>${lines.map(escapeHtml).join('<br>')}</p>`;
      }
      const intro = lines.filter((l) => !l.startsWith('- '));
      const list = items.map((l) => `<li>${escapeHtml(l.slice(2))}</li>`).join('');
      return `${intro.map((l) => `<p>${escapeHtml(l)}</p>`).join('')}<ul>${list}</ul>`;
    })
    .join('\n');
}

export const replyHtml = `<!doctype html>
<html><body style="font-family:-apple-system,Segoe UI,Roboto,Arial,sans-serif;font-size:15px;line-height:1.45;color:#1f1f1f">
<div lang="vi">${toHtml(VI)}</div>
<hr style="border:0;border-top:1px solid #ddd;margin:24px 0">
<div lang="en">${toHtml(EN)}</div>
<p style="color:#777;font-size:13px">${FOOTER}</p>
</body></html>
`;
