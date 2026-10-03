import { createHash, timingSafeEqual } from 'crypto';
import { NextFunction, Request, Response } from 'express';
import { config } from '../config';
import { AppError, UnauthorizedError } from '../utils/errors';

export const MIN_SECRET_LENGTH = 24;

const sha256 = (v: string): Buffer => createHash('sha256').update(v).digest();

// Tiny in-memory brute-force brake: 20 bad attempts / 15 min per client address.
const WINDOW_MS = 15 * 60 * 1000;
const MAX_FAILURES = 20;
const failures = new Map<string, { count: number; resetAt: number }>();

export function resetJobSyncAuthLimiter(): void {
  failures.clear();
}

function clientKey(req: Request): string {
  return req.ip || req.socket.remoteAddress || 'unknown';
}

function tooManyFailures(key: string): boolean {
  const entry = failures.get(key);
  if (!entry) return false;
  if (entry.resetAt < Date.now()) {
    failures.delete(key);
    return false;
  }
  return entry.count >= MAX_FAILURES;
}

function recordFailure(key: string): void {
  const now = Date.now();
  const entry = failures.get(key);
  if (!entry || entry.resetAt < now) failures.set(key, { count: 1, resetAt: now + WINDOW_MS });
  else entry.count++;
}

/**
 * Guards /api/v1/internal/*. Requires `Authorization: Bearer <JOB_SYNC_SECRET>`.
 * Fails closed: if the secret is unset or weak the endpoints are disabled, never open.
 * Error bodies never echo the header or the secret.
 */
export function requireJobSyncAuth(req: Request, _res: Response, next: NextFunction): void {
  const secret = config.jobSyncSecret;
  if (!secret || secret.length < MIN_SECRET_LENGTH) {
    throw new AppError(
      `Job sync is disabled: JOB_SYNC_SECRET must be set to at least ${MIN_SECRET_LENGTH} characters.`,
      503,
      'SYNC_NOT_CONFIGURED'
    );
  }

  const key = clientKey(req);
  if (tooManyFailures(key)) {
    throw new AppError('Too many failed authentication attempts. Try again later.', 429, 'RATE_LIMITED');
  }

  const header = req.headers.authorization;
  const match = typeof header === 'string' ? /^Bearer\s+(\S+)$/i.exec(header) : null;
  if (!match) {
    recordFailure(key);
    throw new UnauthorizedError('Missing or malformed Authorization header. Expected: Bearer <JOB_SYNC_SECRET>.');
  }

  // Compare fixed-length digests in constant time.
  if (!timingSafeEqual(sha256(match[1]), sha256(secret))) {
    recordFailure(key);
    throw new UnauthorizedError('Invalid credentials.');
  }
  next();
}
