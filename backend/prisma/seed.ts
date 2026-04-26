import 'dotenv/config';
import fs from 'fs';
import path from 'path';
import { PrismaPg } from '@prisma/adapter-pg';
import { PrismaClient } from '../generated/prisma/client';

const adapter = new PrismaPg({ connectionString: process.env['DATABASE_URL']! });
const prisma = new PrismaClient({ adapter });

interface RawWord {
  id: number;
  word_id: string;
  word: string;
  letter: string;
  meaning_en: string;
  video_url: string;
  all_videos: string[];
  detail_url: string;
}

// "Ben" → "0001_Ben.mp4"
// "Sagir, Isitme Engelli" → "0011_Sagir__Isitme_Engelli.mp4"
function wordToFilename(wordId: string, word: string): string {
  const sanitized = word.replace(/[^\p{L}\p{N}]/gu, '_');
  return `${wordId}_${sanitized}.mp4`;
}

async function main(): Promise<void> {
  const jsonPath = path.join(__dirname, '..', 'public', 'tid_words.json');
  const videosDir = path.join(__dirname, '..', 'public', 'videos');

  console.log('JSON:', jsonPath);
  console.log('Videos:', videosDir);

  if (!fs.existsSync(jsonPath)) {
    throw new Error(`JSON bulunamadi: ${jsonPath}`);
  }

  const raw = JSON.parse(fs.readFileSync(jsonPath, 'utf-8')) as RawWord[];
  console.log(`${raw.length} kelime okundu.`);

  let localCount = 0;
  let cdnCount = 0;

  const data = raw.map(entry => {
    const filename = wordToFilename(entry.word_id, entry.word);
    const exists = fs.existsSync(path.join(videosDir, filename));
    if (exists) localCount++; else cdnCount++;

    return {
      wordId: entry.word_id,
      word: entry.word,
      letter: (entry.letter || entry.word[0] || 'A').toUpperCase(),
      meaningEn: entry.meaning_en || null,
      videoFilename: exists ? filename : null,
      cdnVideoUrl: entry.video_url,
      allVideos: entry.all_videos ?? [],
      detailUrl: entry.detail_url || null,
    };
  });

  console.log(`Lokal: ${localCount} | CDN fallback: ${cdnCount}`);
  console.log('Veritabanina yaziliyor...');

  let i = 0;
  for (const item of data) {
    await prisma.word.upsert({
      where: { wordId: item.wordId },
      update: item,
      create: item,
    });
    i++;
    if (i % 200 === 0) console.log(`  ${i}/${data.length}`);
  }

  console.log(`Tamamlandi: ${i} kelime.`);
}

main()
  .catch(e => { console.error(e); process.exit(1); })
  .finally(() => prisma.$disconnect());
