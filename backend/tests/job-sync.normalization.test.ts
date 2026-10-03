import {
  canonicalizeUrl,
  cleanText,
  contentHashFor,
  dedupeKeyFor,
  normalizeCompany,
  normalizeJob,
  normalizeLocation,
  normalizeTitle,
} from '../src/modules/job-sync/job-normalization.service';

describe('URL canonicalization', () => {
  it('strips tracking params, fragment, www, trailing slash; forces https', () => {
    expect(canonicalizeUrl('http://www.Example.com/jobs/1/?utm_source=x&utm_medium=y&ref=abc&gclid=1#apply')).toBe('https://example.com/jobs/1');
  });
  it('keeps job-identifying params and sorts them for stability', () => {
    expect(canonicalizeUrl('https://co.com/careers?gh_jid=42&b=2&a=1&gh_src=tw')).toBe('https://co.com/careers?a=1&b=2&gh_jid=42');
  });
  it('is idempotent', () => {
    const once = canonicalizeUrl('https://a.com/x/?utm_campaign=1&id=3')!;
    expect(canonicalizeUrl(once)).toBe(once);
  });
  it('rejects unsafe or invalid URLs', () => {
    for (const bad of ['javascript:alert(1)', 'ftp://x.com/a', 'not a url', '', null, undefined, 'https://user:pw@x.com/a']) {
      expect(canonicalizeUrl(bad as string)).toBeNull();
    }
  });
});

describe('text normalization', () => {
  it('title / company / location are trimmed, collapsed and clamped', () => {
    expect(normalizeTitle('  Backend \n  Engineer  ')).toBe('Backend Engineer');
    expect(normalizeTitle('x'.repeat(500))).toHaveLength(200);
    expect(normalizeCompany('  Acme   Corp ')).toBe('Acme Corp');
    expect(normalizeLocation(' Bangalore,  India ')).toBe('Bengaluru, India');
    expect(normalizeLocation('   ')).toBeNull();
  });

  it('cleanText produces inert plain text (no tags/scripts/entities)', () => {
    const out = cleanText('&lt;p&gt;Hello &amp;amp; <b>welcome</b></p><script>alert(1)</script><style>x{}</style><li>Java</li>', 1000)!;
    expect(out).not.toMatch(/<|script|alert/);
    expect(out).toContain('Hello');
    expect(out).toContain('- Java');
  });

  it('cleanText strips control characters and truncates', () => {
    expect(cleanText('a\u0000b\u0007c', 100)).toBe('a b c');
    const long = cleanText('word '.repeat(5000), 100)!;
    expect(long.length).toBeLessThanOrEqual(100);
    expect(cleanText('', 10)).toBeNull();
  });
});

describe('dedupe keys', () => {
  it('same company+title+location normalizes equal across formatting', () => {
    expect(dedupeKeyFor('Acme, Inc.', 'Backend  Engineer!', 'Bangalore')).toBe(dedupeKeyFor('ACME Inc', 'backend engineer', 'Bengaluru'));
  });
  it('different location is a different job', () => {
    expect(dedupeKeyFor('Acme', 'Backend Engineer', 'Pune')).not.toBe(dedupeKeyFor('Acme', 'Backend Engineer', 'Delhi'));
  });
  it('never keys on titles that normalize to nothing', () => {
    expect(dedupeKeyFor('Acme', '後端工程師', null)).toBeNull();
  });
  it('content hash is stable and sensitive to content', () => {
    const a = contentHashFor('Acme', 'Hello world');
    expect(contentHashFor('acme', 'hello   world!')).toBe(a);
    expect(contentHashFor('Acme', 'Different')).not.toBe(a);
    expect(contentHashFor('Other', 'Hello world')).not.toBe(a);
  });
});

describe('normalizeJob validation', () => {
  const base = { source: 'T', externalId: '1', url: 'https://x.com/1?utm_source=a', title: ' Backend Engineer ', company: ' Acme ', location: 'Bangalore' };
  it('normalizes a valid posting', () => {
    const r = normalizeJob({ ...base, postedAt: '2026-09-01T00:00:00Z', skills: ['Java', 'java ', ''] });
    expect(r.ok).toBe(true);
    if (r.ok) {
      expect(r.job).toMatchObject({ url: 'https://x.com/1', title: 'Backend Engineer', company: 'Acme', location: 'Bengaluru' });
      expect(r.job.postedAt).toBeInstanceOf(Date);
    }
  });
  it('rejects bad URL, missing title/company/id', () => {
    expect(normalizeJob({ ...base, url: 'javascript:1' })).toEqual({ ok: false, reason: 'invalid_url' });
    expect(normalizeJob({ ...base, title: '' })).toEqual({ ok: false, reason: 'invalid_fields' });
    expect(normalizeJob({ ...base, company: '  ' })).toEqual({ ok: false, reason: 'invalid_fields' });
    expect(normalizeJob({ ...base, externalId: '' })).toEqual({ ok: false, reason: 'invalid_fields' });
  });
  it('drops absurd or future dates instead of storing them', () => {
    const future = normalizeJob({ ...base, postedAt: new Date(Date.now() + 30 * 86_400_000) });
    const ancient = normalizeJob({ ...base, postedAt: '1970-01-02' });
    expect(future.ok && future.job.postedAt).toBeNull();
    expect(ancient.ok && ancient.job.postedAt).toBeNull();
  });
  it('treats provider fields as untrusted: HTML in title/description is neutralised', () => {
    const r = normalizeJob({ ...base, title: '<img src=x onerror=alert(1)>Engineer', description: '<script>steal()</script>Java dev' });
    expect(r.ok).toBe(true);
    if (r.ok) {
      expect(r.job.title).not.toMatch(/[<>]/);
      expect(r.job.description).toBe('Java dev');
    }
  });
});
