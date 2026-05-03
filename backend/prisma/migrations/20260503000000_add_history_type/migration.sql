-- CreateEnum
CREATE TYPE "HistoryType" AS ENUM ('RECOGNITION', 'DICTIONARY', 'TRANSLATION');

-- AlterTable
ALTER TABLE "History" ADD COLUMN "type" "HistoryType" NOT NULL DEFAULT 'RECOGNITION';

-- CreateIndex
CREATE INDEX "History_userId_type_idx" ON "History"("userId", "type");
