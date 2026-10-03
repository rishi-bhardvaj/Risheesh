import { config } from '../config';

const MASK = '[REDACTED]';

/** Secrets that must never reach logs, however a message was built. */
function secretValues(): string[] {
  return [config.jobSyncSecret, config.assistantApiKey, config.importApiKey, config.jwtSecret, process.env.DATABASE_URL]
    .filter((v): v is string => typeof v === 'string' && v.length >= 8);
}

function safeStringify(v: unknown): string {
  try {
    return JSON.stringify(v) ?? String(v);
  } catch {
    return String(v);
  }
}

export function redact(input: unknown): string {
  let text =
    typeof input === 'string' ? input : input instanceof Error ? `${input.name}: ${input.message}` : safeStringify(input);
  for (const secret of secretValues()) {
    text = text.split(secret).join(MASK);
  }
  return text
    .replace(/(bearer\s+)[A-Za-z0-9._~+/=-]{8,}/gi, `$1${MASK}`)
    .replace(/(postgres(?:ql)?:\/\/[^:\s/]+:)[^@\s]+@/gi, `$1${MASK}@`)
    .replace(/(authorization["']?\s*[:=]\s*["']?)[^\s"',]+/gi, `$1${MASK}`);
}

type Level = 'info' | 'warn' | 'error';

function write(level: Level, message: string, fields?: Record<string, unknown>): void {
  if (config.nodeEnv === 'test' && !process.env.LOG_IN_TESTS) return;
  const line = redact(fields ? `${message} ${safeStringify(fields)}` : message);
  (level === 'info' ? console.log : level === 'warn' ? console.warn : console.error)(`[job-sync] ${line}`);
}

export const logger = {
  info: (m: string, f?: Record<string, unknown>) => write('info', m, f),
  warn: (m: string, f?: Record<string, unknown>) => write('warn', m, f),
  error: (m: string, f?: Record<string, unknown>) => write('error', m, f),
};
