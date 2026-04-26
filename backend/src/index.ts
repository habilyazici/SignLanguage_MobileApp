import './config';
import express from 'express';
import type { Request, Response, NextFunction } from 'express';
import cors from 'cors';
import helmet from 'helmet';
import rateLimit from 'express-rate-limit';
import path from 'path';
import { config } from './config';
import { authRouter } from './routes/auth';
import { wordsRouter } from './routes/words';
import { historyRouter } from './routes/history';
import { bookmarksRouter } from './routes/bookmarks';

const app = express();

app.use(helmet({ crossOriginResourcePolicy: { policy: 'cross-origin' } }));
app.use(cors());
app.use(express.json());

// Genel limiter: 200 istek / 1 dakika / IP
const generalLimiter = rateLimit({
  windowMs: 60 * 1000,
  max: 200,
  standardHeaders: true,
  legacyHeaders: false,
  message: { error: 'Çok fazla istek gönderildi. Lütfen bekleyin.' },
});

// Auth limiter: 20 istek / 15 dakika / IP (brute-force koruması)
const authLimiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 20,
  standardHeaders: true,
  legacyHeaders: false,
  message: { error: 'Çok fazla giriş denemesi. 15 dakika bekleyin.' },
});

app.use('/api', generalLimiter);
app.use('/api/auth', authLimiter);

app.use('/videos', express.static(path.join(process.cwd(), 'public', 'videos')));

app.use('/api/auth', authRouter);
app.use('/api/words', wordsRouter);
app.use('/api/history', historyRouter);
app.use('/api/bookmarks', bookmarksRouter);

app.get('/health', (_req, res) => res.json({ ok: true }));

// 404 handler — bilinmeyen route'larda HTML yerine JSON döner
app.use((_req: Request, res: Response) => {
  res.status(404).json({ error: 'Kaynak bulunamadi.' });
});

// Global error handler
app.use((err: unknown, _req: Request, res: Response, _next: NextFunction) => {
  console.error(err);
  res.status(500).json({ error: 'Sunucu hatasi.' });
});

const server = app.listen(config.port, '0.0.0.0', () => {
  console.log(`Server: http://localhost:${config.port}`);
  console.log(`Base URL: ${config.baseUrl}`);
  console.log(`Tunnel:  ngrok http --domain=reaffirm-visor-gazing.ngrok-free.dev ${config.port}`);
});

server.on('error', (err) => {
  console.error('SERVER ERROR:', err);
});
