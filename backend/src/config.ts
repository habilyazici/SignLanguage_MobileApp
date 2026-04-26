import 'dotenv/config';

function required(key: string): string {
  const val = process.env[key];
  if (!val) throw new Error(`Missing env var: ${key}`);
  return val;
}

export const config = {
  port: parseInt(process.env['PORT'] ?? '3000', 10),
  jwtSecret: required('JWT_SECRET'),
  baseUrl: process.env['BASE_URL'] ?? 'http://localhost:3000',
  databaseUrl: required('DATABASE_URL'),
  smtpUser: process.env['SMTP_USER'] ?? '',
  smtpPass: process.env['SMTP_PASS'] ?? '',
} as const;
