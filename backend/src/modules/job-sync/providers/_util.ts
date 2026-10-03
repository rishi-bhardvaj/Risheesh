import { ProviderHttpError, sleepMs } from '../http';
import type { ProviderContext, ProviderFetchResult, RawJob } from '../types';

export const isObj = (v: unknown): v is Record<string, unknown> => typeof v === 'object' && v !== null && !Array.isArray(v);
export const str = (v: unknown): string => (typeof v === 'string' ? v.trim() : typeof v === 'number' ? String(v) : '');

export const prettifyToken = (t: string): string =>
  t.split(/[-_]/).filter(Boolean).map((w) => w[0].toUpperCase() + w.slice(1)).join(' ');

export const looksRemote = (s: string): boolean => /remote|anywhere|worldwide/i.test(s);

export function formatSalary(min: unknown, max: unknown, currency = 'USD', interval?: string): string | null {
  const lo = typeof min === 'number' && min > 0 ? min : null;
  const hi = typeof max === 'number' && max > 0 ? max : null;
  if (lo === null && hi === null) return null;
  const sym: Record<string, string> = { USD: '$', EUR: '€', GBP: '£', INR: '₹' };
  const prefix = sym[currency.toUpperCase()] ?? `${currency} `;
  const fmt = (n: number) => (n >= 1000 ? `${prefix}${Math.round(n / 1000)}k` : `${prefix}${Math.round(n)}`);
  const range = lo !== null && hi !== null && lo !== hi ? `${fmt(lo)} - ${fmt(hi)}` : fmt((lo ?? hi) as number);
  return interval === 'per-hour-wage' || interval === 'hourly' ? `${range} /hr` : range;
}

export interface BoardSpec {
  board: string;
  url: string;
  parse: (board: string, json: unknown) => RawJob[];
}

/**
 * Fetches many independent boards of one ATS. A failing board is recorded and skipped; the
 * provider only throws when every board failed (so the sync can mark it FAILED).
 */
export async function fetchBoards(ctx: ProviderContext, specs: BoardSpec[]): Promise<ProviderFetchResult> {
  const jobs: RawJob[] = [];
  const errors: string[] = [];
  let failed = 0;

  for (let i = 0; i < specs.length; i++) {
    if (ctx.signal?.aborted) {
      failed += specs.length - i;
      errors.push('aborted before all boards were fetched');
      break;
    }
    const spec = specs[i];
    try {
      const json = await ctx.http.getJson(spec.url, { signal: ctx.signal });
      const parsed = spec.parse(spec.board, json);
      const keep = ctx.prefilter ? parsed.filter((j) => ctx.prefilter!(j.title, j.location ?? null)) : parsed;
      jobs.push(...keep.slice(0, ctx.config.maxJobsPerBoard));
    } catch (err) {
      failed++;
      errors.push(`${spec.board}: ${err instanceof Error ? err.message : 'unknown error'}`);
    }
    if (i < specs.length - 1 && ctx.config.http.boardDelayMs > 0) await sleepMs(ctx.config.http.boardDelayMs);
  }

  if (specs.length > 0 && failed === specs.length) {
    throw new ProviderHttpError(`All ${specs.length} boards failed: ${errors.slice(0, 3).join('; ')}`, null, false);
  }
  return { jobs, boardsAttempted: specs.length, boardsFailed: failed, errors };
}
