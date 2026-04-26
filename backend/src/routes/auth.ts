import { Router } from 'express';
import type { Request, Response } from 'express';
import bcrypt from 'bcrypt';
import jwt from 'jsonwebtoken';
import { randomInt } from 'crypto';
import { z } from 'zod';
import { prisma } from '../db';
import { config } from '../config';
import { requireAuth } from '../middleware/requireAuth';
import type { AuthRequest } from '../middleware/requireAuth';
import { sendPasswordResetEmail } from '../services/email';

export const authRouter = Router();

const registerSchema = z.object({
  name: z.string().min(2),
  email: z.string().email(),
  password: z.string().min(6),
});

const loginSchema = z.object({
  email: z.string().email(),
  password: z.string().min(1),
});

function signToken(userId: string): string {
  return jwt.sign({ sub: userId }, config.jwtSecret, { expiresIn: '7d' });
}

authRouter.post('/register', async (req: Request, res: Response): Promise<void> => {
  const parsed = registerSchema.safeParse(req.body);
  if (!parsed.success) {
    res.status(400).json({ error: 'Gecersiz veri.', details: parsed.error.flatten() });
    return;
  }

  const { name, email, password } = parsed.data;

  try {
    const existing = await prisma.user.findUnique({ where: { email } });
    if (existing) {
      res.status(409).json({ error: 'Bu e-posta zaten kayitli.' });
      return;
    }

    const passwordHash = await bcrypt.hash(password, 10);
    const user = await prisma.user.create({ data: { name, email, passwordHash } });

    res.status(201).json({
      token: signToken(user.id),
      user: { id: user.id, name: user.name, email: user.email },
    });
  } catch (err) {
    res.status(500).json({ error: 'Sunucu hatasi.' });
  }
});

authRouter.post('/login', async (req: Request, res: Response): Promise<void> => {
  const parsed = loginSchema.safeParse(req.body);
  if (!parsed.success) {
    res.status(400).json({ error: 'Gecersiz veri.' });
    return;
  }

  const { email, password } = parsed.data;

  try {
    const user = await prisma.user.findUnique({ where: { email } });
    if (!user) {
      res.status(401).json({ error: 'E-posta veya sifre hatali.' });
      return;
    }

    const valid = await bcrypt.compare(password, user.passwordHash);
    if (!valid) {
      res.status(401).json({ error: 'E-posta veya sifre hatali.' });
      return;
    }

    res.json({
      token: signToken(user.id),
      user: { id: user.id, name: user.name, email: user.email },
    });
  } catch (err) {
    res.status(500).json({ error: 'Sunucu hatasi.' });
  }
});

const forgotPasswordSchema = z.object({ email: z.string().email() });

authRouter.post('/forgot-password', async (req: Request, res: Response): Promise<void> => {
  const parsed = forgotPasswordSchema.safeParse(req.body);
  if (!parsed.success) {
    res.status(400).json({ error: 'Gecersiz e-posta.' });
    return;
  }

  const { email } = parsed.data;

  // Güvenlik: kullanıcı varlığından bağımsız olarak her zaman başarılı döner.
  res.json({ message: 'Sıfırlama kodu gönderildi.' });

  // Yanıt gönderdikten sonra arka planda işle — yanıt gecikmesini önler.
  (async () => {
    try {
      const user = await prisma.user.findUnique({ where: { email } });
      if (!user) return;

      // Eski token'ları temizle
      await prisma.passwordResetToken.deleteMany({ where: { email } });

      const code = String(randomInt(100000, 1000000)).padStart(6, '0');
      const codeHash = await bcrypt.hash(code, 10);
      const expiresAt = new Date(Date.now() + 15 * 60 * 1000);

      await prisma.passwordResetToken.create({
        data: { email, codeHash, expiresAt },
      });

      await sendPasswordResetEmail(email, code);
    } catch (err) {
      console.error('Sifre sifirlama hatasi:', err);
    }
  })();
});

const resetPasswordSchema = z.object({
  email: z.string().email(),
  code: z.string().length(6),
  newPassword: z.string().min(6),
});

authRouter.post('/reset-password', async (req: Request, res: Response): Promise<void> => {
  const parsed = resetPasswordSchema.safeParse(req.body);
  if (!parsed.success) {
    res.status(400).json({ error: 'Gecersiz veri.' });
    return;
  }

  const { email, code, newPassword } = parsed.data;

  try {
    const token = await prisma.passwordResetToken.findFirst({
      where: { email, used: false, expiresAt: { gt: new Date() } },
      orderBy: { createdAt: 'desc' },
    });

    if (!token) {
      res.status(400).json({ error: 'Gecersiz veya suresi dolmus kod.' });
      return;
    }

    const valid = await bcrypt.compare(code, token.codeHash);
    if (!valid) {
      res.status(400).json({ error: 'Kod hatali.' });
      return;
    }

    const passwordHash = await bcrypt.hash(newPassword, 10);
    await prisma.$transaction([
      prisma.passwordResetToken.update({ where: { id: token.id }, data: { used: true } }),
      prisma.user.update({ where: { email }, data: { passwordHash } }),
    ]);

    res.json({ message: 'Sifre guncellendi.' });
  } catch (err) {
    res.status(500).json({ error: 'Sunucu hatasi.' });
  }
});

const updateProfileSchema = z.object({
  name: z.string().min(2).optional(),
  currentPassword: z.string().min(1).optional(),
  newPassword: z.string().min(6).optional(),
}).refine(
  data => !data.newPassword || !!data.currentPassword,
  { message: 'Yeni sifre icin mevcut sifre gerekli.' },
);

authRouter.put('/profile', requireAuth, async (req: AuthRequest, res: Response): Promise<void> => {
  const parsed = updateProfileSchema.safeParse(req.body);
  if (!parsed.success) {
    res.status(400).json({ error: 'Gecersiz veri.', details: parsed.error.flatten() });
    return;
  }

  const { name, currentPassword, newPassword } = parsed.data;
  if (!name && !newPassword) {
    res.status(400).json({ error: 'Guncelleme icin en az bir alan gerekli.' });
    return;
  }

  try {
    const user = await prisma.user.findUnique({ where: { id: req.userId! } });
    if (!user) { res.status(404).json({ error: 'Kullanici bulunamadi.' }); return; }

    if (newPassword) {
      const valid = await bcrypt.compare(currentPassword!, user.passwordHash);
      if (!valid) { res.status(400).json({ error: 'Mevcut sifre hatali.' }); return; }
    }

    const updated = await prisma.user.update({
      where: { id: req.userId! },
      data: {
        ...(name ? { name } : {}),
        ...(newPassword ? { passwordHash: await bcrypt.hash(newPassword, 10) } : {}),
      },
    });

    res.json({ id: updated.id, name: updated.name, email: updated.email });
  } catch (err) {
    res.status(500).json({ error: 'Sunucu hatasi.' });
  }
});

authRouter.delete('/profile', requireAuth, async (req: AuthRequest, res: Response): Promise<void> => {
  try {
    const user = await prisma.user.findUnique({ where: { id: req.userId! } });
    if (!user) { res.status(404).json({ error: 'Kullanici bulunamadi.' }); return; }

    // History ve Bookmark kayıtları cascade ile otomatik silinir (schema.prisma).
    await prisma.user.delete({ where: { id: req.userId! } });

    res.status(204).send();
  } catch (err) {
    res.status(500).json({ error: 'Sunucu hatasi.' });
  }
});
