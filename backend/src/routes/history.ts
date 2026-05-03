import { Router } from 'express';
import type { Request, Response } from 'express';
import { z } from 'zod';
import { prisma } from '../db';
import { requireAuth } from '../middleware/requireAuth';
import type { AuthRequest } from '../middleware/requireAuth';

export const historyRouter = Router();

historyRouter.use(requireAuth);

const VALID_TYPES = ['RECOGNITION', 'DICTIONARY', 'TRANSLATION'] as const;
type HistoryType = typeof VALID_TYPES[number];

const addSchema = z.object({
  text: z.string().min(1).max(500),
  type: z.enum(VALID_TYPES).default('RECOGNITION'),
});

// GET /api/history?offset=0&limit=50&type=RECOGNITION
historyRouter.get('/', async (req: AuthRequest, res: Response): Promise<void> => {
  const limit = Math.min(parseInt(String(req.query['limit'] ?? '50'), 10) || 50, 100);
  const offset = Math.max(parseInt(String(req.query['offset'] ?? '0'), 10) || 0, 0);
  const typeParam = req.query['type'] as string | undefined;
  const typeFilter = typeParam && (VALID_TYPES as readonly string[]).includes(typeParam)
    ? typeParam as HistoryType
    : undefined;

  try {
    const items = await prisma.history.findMany({
      where: { userId: req.userId!, ...(typeFilter ? { type: typeFilter } : {}) },
      orderBy: { createdAt: 'desc' },
      take: limit,
      skip: offset,
    });
    res.json(items);
  } catch (err) {
    console.error('[history]:', err);
    res.status(500).json({ error: 'Sunucu hatasi.' });
  }
});

// POST /api/history
historyRouter.post('/', async (req: AuthRequest, res: Response): Promise<void> => {
  const parsed = addSchema.safeParse(req.body);
  if (!parsed.success) { res.status(400).json({ error: 'Gecersiz veri.' }); return; }

  try {
    const item = await prisma.history.create({
      data: { userId: req.userId!, text: parsed.data.text, type: parsed.data.type },
    });
    res.status(201).json(item);
  } catch (err) {
    console.error('[history]:', err);
    res.status(500).json({ error: 'Sunucu hatasi.' });
  }
});

// DELETE /api/history (all)
historyRouter.delete('/', async (req: AuthRequest, res: Response): Promise<void> => {
  try {
    await prisma.history.deleteMany({ where: { userId: req.userId! } });
    res.status(204).end();
  } catch (err) {
    console.error('[history]:', err);
    res.status(500).json({ error: 'Sunucu hatasi.' });
  }
});

// DELETE /api/history/:id
historyRouter.delete('/:id', async (req: AuthRequest, res: Response): Promise<void> => {
  const id = String(req.params['id'] ?? '');

  try {
    const { count } = await prisma.history.deleteMany({
      where: { id, userId: req.userId! },
    });
    if (count === 0) {
      res.status(404).json({ error: 'Bulunamadi.' });
      return;
    }
    res.status(204).end();
  } catch (err) {
    console.error('[history]:', err);
    res.status(500).json({ error: 'Sunucu hatasi.' });
  }
});
