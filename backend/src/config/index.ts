import dotenv from 'dotenv';
import path from 'path';

dotenv.config({ path: path.resolve(__dirname, '../../.env') });

export const config = {
  port: parseInt(process.env.PORT || '8080', 10),
  nodeEnv: process.env.NODE_ENV || 'development',
  databaseUrl: process.env.DATABASE_URL || 'postgresql://postgres:postgres@localhost:5432/career_os',
  importApiKey: process.env.IMPORT_API_KEY || 'default_import_key',
  jwtSecret: process.env.JWT_SECRET || 'default_jwt_secret',
  // Protects /api/v1/internal/*. No default on purpose: when unset the endpoints are disabled (503).
  jobSyncSecret: process.env.JOB_SYNC_SECRET || '',
  // Protects /api/v1/assistant/*. Dedicated read-only key for ChatGPT routines / personal assistant.
  assistantApiKey: process.env.ASSISTANT_API_KEY || '',
  corsOrigins: process.env.CORS_ORIGINS || '*',
  logLevel: process.env.LOG_LEVEL || 'info',
};
