import { createHash } from 'crypto';
import { z } from 'zod';
import type { NormalizedJob, RawJob } from './types';

const NAMED_ENTITIES: Record<string, string> = {
  amp: '&', lt: '<', gt: '>', quot: '"', apos: "'", nbsp: ' ', ndash: '-', mdash: '-', hellip: '...',
  rsquo: "'", lsquo: "'", rdquo: '"', ldquo: '"', bull: '-', middot: '-', copy: '(c)', reg: '(r)', trade: '(tm)',
};

export function decodeEntities(input: string): string {
  return input.replace(/&(#x[0-9a-f]+|#\d+|[a-z]+);/gi, (m, e: string) => {
    if (e[0] === '#') {
      const code = e[1].toLowerCase() === 'x' ? Number.parseInt(e.slice(2), 16) : Number.parseInt(e.slice(1), 10);
      if (!Number.isFinite(code) || code <= 0 || code > 0x10ffff) return ' ';
      try {
        return String.fromCodePoint(code);
      } catch {
        return ' ';
      }
    }
    return NAMED_ENTITIES[e.toLowerCase()] ?? m;
  });
}

/**
 * Provider text is untrusted. Output is inert plain text: no tags, no scripts, no control
 * characters. Flutter renders it as text, never as HTML.
 */
export function cleanText(input: string | null | undefined, maxChars: number): string | null {
  if (!input) return null;
  let s = decodeEntities(String(input)); // Greenhouse ships entity-encoded HTML
  s = s
    .replace(/<(script|style|iframe|object|embed)\b[\s\S]*?<\/\1\s*>/gi, ' ')
    .replace(/<!--[\s\S]*?-->/g, ' ')
    .replace(/<\s*(br|\/p|\/div|\/li|\/h[1-6]|\/tr)\b[^>]*>/gi, '\n')
    .replace(/<\s*li\b[^>]*>/gi, '\n- ')
    .replace(/<[^>]*>/g, ' ');
  s = decodeEntities(s)
    // eslint-disable-next-line no-control-regex
    .replace(/[\u0000-\u0008\u000b\u000c\u000e-\u001f\u007f]/g, ' ')
    .replace(/[ \t ]+/g, ' ')
    .replace(/ ?\n ?/g, '\n')
    .replace(/\n{3,}/g, '\n\n')
    .trim();
  if (!s) return null;
  return s.length > maxChars ? `${s.slice(0, maxChars - 1).trimEnd()}…` : s;
}

const oneLine = (v: string | null | undefined, max: number): string => {
  const s = cleanText(v ?? '', max * 2)?.replace(/\s+/g, ' ').trim() ?? '';
  return s.length > max ? s.slice(0, max).trim() : s;
};

export function normalizeTitle(title: string | null | undefined): string {
  return oneLine(title, 200);
}

export function normalizeCompany(company: string | null | undefined): string {
  return oneLine(company, 150);
}

export function normalizeLocation(location: string | null | undefined): string | null {
  const s = oneLine(location, 200).replace(/\bbangalore\b/gi, 'Bengaluru');
  return s || null;
}

const TRACKING_PARAMS = new Set([
  'ref', 'source', 'src', 'campaign', 'fbclid', 'gclid', 'msclkid', 'mc_cid', 'mc_eid', 'trk', 'trkid',
  'gh_src', 'lever-source', 'lever-origin', 'utm', 'igshid', 'yclid', '_hsenc', '_hsmi',
]);

/**
 * Canonical form used for cross-source deduplication: lowercase host without www, no fragment,
 * no tracking params, sorted query, no trailing slash. Job-identifying params such as gh_jid are kept.
 */
export function canonicalizeUrl(raw: string | null | undefined): string | null {
  if (!raw) return null;
  let u: URL;
  try {
    u = new URL(raw.trim());
  } catch {
    return null;
  }
  if (u.protocol !== 'https:' && u.protocol !== 'http:') return null;
  if (u.username || u.password) return null;
  u.protocol = 'https:';
  u.hostname = u.hostname.toLowerCase().replace(/^www\./, '');
  u.hash = '';
  const kept: Array<[string, string]> = [];
  for (const [k, v] of u.searchParams) {
    const key = k.toLowerCase();
    if (key.startsWith('utm_') || TRACKING_PARAMS.has(key)) continue;
    kept.push([k, v]);
  }
  kept.sort(([a], [b]) => a.localeCompare(b));
  u.search = new URLSearchParams(kept).toString();
  let out = u.toString();
  if (out.endsWith('/')) out = out.slice(0, -1);
  return out.length <= 2048 ? out : null;
}

const alnum = (s: string): string => s.toLowerCase().replace(/[^a-z0-9]+/g, ' ').trim();

const COMPANY_SUFFIX = /\b(inc|llc|ltd|limited|pvt|private|corp|corporation|co|gmbh)\b/g;

/** Mirrors the SQL backfill in migration 005 (ASCII alnum only) so old and new rows agree. */
export function dedupeKeyFor(company: string, title: string, location: string | null): string | null {
  const c = alnum(company).replace(COMPANY_SUFFIX, ' ').replace(/\s+/g, ' ').trim();
  const t = alnum(title);
  if (!c || !t) return null; // e.g. non-Latin titles collapse to nothing: never key on them
  const l = alnum((location ?? '').replace(/\bbangalore\b/gi, 'bengaluru'));
  return `${c}|${t}|${l}`;
}

/**
 * Fingerprint of the posting body (company + description). Deliberately excludes title/location
 * so re-titled or relocated copies of the same posting still match; title/location changes are
 * detected separately when deciding whether a stored row needs updating.
 */
export function contentHashFor(company: string, description: string | null): string {
  const body = alnum(description ?? '').slice(0, 4000);
  return createHash('sha256').update(`${alnum(company)}\n${body}`).digest('hex');
}

const normalizedSchema = z.object({
  source: z.string().trim().min(1).max(50),
  externalId: z.string().trim().min(1).max(300),
  url: z.string().url().max(2048),
  title: z.string().min(2).max(200),
  company: z.string().min(1).max(150),
});

export type NormalizeResult = { ok: true; job: NormalizedJob } | { ok: false; reason: string };

function toDate(v: RawJob['postedAt']): Date | null {
  if (v === null || v === undefined || v === '') return null;
  const d = v instanceof Date ? v : new Date(typeof v === 'number' && v < 1e12 ? v * 1000 : v);
  const t = d.getTime();
  // Reject nonsense and future-dated values (clock skew tolerated up to 1 day).
  if (Number.isNaN(t) || t < Date.UTC(2000, 0, 1) || t > Date.now() + 86_400_000) return null;
  return d;
}

export function normalizeJob(raw: RawJob, maxDescriptionChars = 12000): NormalizeResult {
  const canonical = canonicalizeUrl(raw?.url);
  if (!canonical) return { ok: false, reason: 'invalid_url' };

  const title = normalizeTitle(raw.title);
  const company = normalizeCompany(raw.company);
  const checked = normalizedSchema.safeParse({
    source: raw.source,
    externalId: String(raw.externalId ?? '').slice(0, 300),
    url: canonical,
    title,
    company,
  });
  if (!checked.success) return { ok: false, reason: 'invalid_fields' };

  const location = normalizeLocation(raw.location);
  const description = cleanText(raw.description, maxDescriptionChars);
  const skills = Array.from(
    new Set((raw.skills ?? []).map((s) => oneLine(String(s), 60)).filter(Boolean))
  ).slice(0, 30);

  return {
    ok: true,
    job: {
      source: checked.data.source,
      externalId: checked.data.externalId,
      url: canonical,
      canonicalUrl: canonical,
      title,
      company,
      location,
      description,
      postedAt: toDate(raw.postedAt),
      salary: raw.salary ? oneLine(raw.salary, 100) || null : null,
      employmentType: raw.employmentType ? oneLine(raw.employmentType, 50) || null : null,
      skills,
      isRemote: raw.isRemote === true,
      dedupeKey: dedupeKeyFor(company, title, location),
      contentHash: contentHashFor(company, description),
      metadata: raw.metadata && typeof raw.metadata === 'object' ? raw.metadata : {},
    },
  };
}
