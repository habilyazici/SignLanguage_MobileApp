import nodemailer from 'nodemailer';
import { config } from '../config';

const transporter = nodemailer.createTransport({
  service: 'gmail',
  auth: {
    user: config.smtpUser,
    pass: config.smtpPass,
  },
});

export async function sendPasswordResetEmail(to: string, code: string): Promise<void> {
  await transporter.sendMail({
    from: `"Hear Me Out" <${config.smtpUser}>`,
    to,
    subject: 'Şifre Sıfırlama Kodu — Hear Me Out',
    html: `
      <div style="font-family:sans-serif;max-width:480px;margin:auto;padding:32px">
        <h2 style="color:#0046AF">Şifre Sıfırlama</h2>
        <p>Aşağıdaki kodu uygulamaya girin. Kod <strong>15 dakika</strong> geçerlidir.</p>
        <div style="
          font-size:36px;font-weight:bold;letter-spacing:10px;
          text-align:center;padding:24px;margin:24px 0;
          background:#F0F5FF;border-radius:12px;color:#0046AF
        ">${code}</div>
        <p style="color:#888;font-size:13px">
          Bu isteği siz yapmadıysanız bu e-postayı yok sayabilirsiniz.
        </p>
      </div>
    `,
  });
}
