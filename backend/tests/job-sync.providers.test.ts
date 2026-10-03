import { HttpClient, ProviderHttpError } from '../src/modules/job-sync/http';
import { loadJobSyncConfig } from '../src/modules/job-sync/job-sync.config';
import { parseAshby } from '../src/modules/job-sync/providers/ashby.provider';
import { greenhouseProvider, parseGreenhouse } from '../src/modules/job-sync/providers/greenhouse.provider';
import { parseLever } from '../src/modules/job-sync/providers/lever.provider';
import { ALLOWED_HOSTS } from '../src/modules/job-sync/providers';
import { parseRemoteOk } from '../src/modules/job-sync/providers/remoteok.provider';
import { parseWwrRss } from '../src/modules/job-sync/providers/weworkremotely.provider';

const cfg = loadJobSyncConfig({} as NodeJS.ProcessEnv);
const json = (body: unknown, status = 200, headers: Record<string, string> = {}) =>
  new Response(JSON.stringify(body), { status, headers: { 'content-type': 'application/json', ...headers } });

function client(responses: Array<Response | Error>, overrides: Partial<typeof cfg.http> = {}) {
  const calls: string[] = [];
  const sleeps: number[] = [];
  let i = 0;
  const fetchImpl = (async (url: URL) => {
    calls.push(String(url));
    const r = responses[Math.min(i++, responses.length - 1)];
    if (r instanceof Error) throw r;
    return r.clone();
  }) as unknown as typeof fetch;
  const http = new HttpClient({ ...cfg.http, ...overrides }, ALLOWED_HOSTS, {
    fetchImpl,
    sleep: async (ms) => void sleeps.push(ms),
    random: () => 0,
  });
  return { http, calls, sleeps };
}

const timeoutError = () => Object.assign(new Error('timed out'), { name: 'TimeoutError' });

describe('provider parsers', () => {
  it('Greenhouse: valid response', () => {
    const jobs = parseGreenhouse('stripe', {
      jobs: [
        { id: 1, title: 'Backend Engineer', absolute_url: 'https://boards.greenhouse.io/stripe/jobs/1', location: { name: 'Bengaluru' }, content: '&lt;p&gt;Java&lt;/p&gt;', first_published: '2026-09-01T00:00:00Z', departments: [{ name: 'Engineering' }] },
        { id: 2, title: '', absolute_url: 'https://x.test/2' }, // dropped: no title
        'garbage',
      ],
    });
    expect(jobs).toHaveLength(1);
    expect(jobs[0]).toMatchObject({ source: 'Greenhouse', externalId: 'stripe:1', company: 'Stripe', location: 'Bengaluru', skills: ['Engineering'] });
  });

  it('Greenhouse: malformed and empty responses', () => {
    expect(() => parseGreenhouse('x', 'nope')).toThrow(/Unexpected/);
    expect(() => parseGreenhouse('x', { jobs: 'nope' })).toThrow(/Unexpected/);
    expect(parseGreenhouse('x', { jobs: [] })).toEqual([]);
  });

  it('Lever: valid, "not found" object, empty', () => {
    const jobs = parseLever('palantir', [
      { id: 'a1', text: 'Software Engineer', hostedUrl: 'https://jobs.lever.co/palantir/a1', categories: { location: 'Remote', commitment: 'Full-time', team: 'Eng' }, descriptionPlain: 'Python', createdAt: 1_760_000_000_000, workplaceType: 'remote' },
    ]);
    expect(jobs[0]).toMatchObject({ source: 'Lever', externalId: 'palantir:a1', isRemote: true, employmentType: 'Full-time' });
    expect(() => parseLever('nope', { ok: false, error: 'Document not found' })).toThrow('Document not found');
    expect(parseLever('x', [])).toEqual([]);
  });

  it('Ashby: skips unlisted postings', () => {
    const jobs = parseAshby('ramp', {
      jobs: [
        { id: '1', title: 'Software Engineer', jobUrl: 'https://jobs.ashbyhq.com/ramp/1', location: 'Remote', isRemote: true, employmentType: 'FullTime', isListed: true },
        { id: '2', title: 'Hidden', jobUrl: 'https://jobs.ashbyhq.com/ramp/2', isListed: false },
      ],
    });
    expect(jobs).toHaveLength(1);
    expect(jobs[0].employmentType).toBe('Full-time');
    expect(() => parseAshby('x', null)).toThrow(/Unexpected/);
  });

  it('RemoteOK: skips legal notice, rejects non-array', () => {
    const jobs = parseRemoteOk([{ legal: 'tos' }, { id: 5, position: 'Backend Engineer', company: 'Acme', url: 'https://remoteok.com/remote-jobs/5', tags: ['java'], date: '2026-09-20T00:00:00Z' }]);
    expect(jobs).toHaveLength(1);
    expect(jobs[0]).toMatchObject({ source: 'RemoteOK', externalId: '5', skills: ['java'] });
    expect(() => parseRemoteOk({ error: 1 })).toThrow(/Unexpected/);
    expect(parseRemoteOk([])).toEqual([]);
  });

  it('WeWorkRemotely: parses CDATA items, region and company prefix; rejects non-RSS', () => {
    const xml = `<rss><channel><item><title><![CDATA[Acme: Backend Developer]]></title><link>https://weworkremotely.com/jobs/1</link><guid>g1</guid><region>Anywhere in the World</region><pubDate>Mon, 01 Sep 2026 10:00:00 +0000</pubDate><description><![CDATA[<p>Java</p>]]></description></item></channel></rss>`;
    const jobs = parseWwrRss(xml);
    expect(jobs).toHaveLength(1);
    expect(jobs[0]).toMatchObject({ company: 'Acme', title: 'Backend Developer', location: 'Remote - Anywhere in the World', externalId: 'g1' });
    expect(() => parseWwrRss('<html>blocked</html>')).toThrow(/not RSS/);
    expect(parseWwrRss('<rss><channel></channel></rss>')).toEqual([]);
  });
});

describe('HttpClient: retries, timeouts, safety', () => {
  it('returns parsed JSON on success', async () => {
    const { http, calls } = client([json({ ok: true })]);
    await expect(http.getJson('https://api.lever.co/v0/postings/x')).resolves.toEqual({ ok: true });
    expect(calls).toHaveLength(1);
  });

  it('retries 500 then succeeds, with exponential backoff', async () => {
    const { http, calls, sleeps } = client([json({}, 500), json({}, 503), json({ ok: 1 })]);
    await expect(http.getJson('https://api.lever.co/v0/postings/x')).resolves.toEqual({ ok: 1 });
    expect(calls).toHaveLength(3);
    expect(sleeps).toEqual([500, 1000]);
  });

  it('retries 429 and honours Retry-After up to the cap', async () => {
    const { http, sleeps } = client([json({}, 429, { 'retry-after': '3' }), json({ ok: 1 })], { retryMaxMs: 2000 });
    await http.getJson('https://api.lever.co/v0/postings/x');
    expect(sleeps).toEqual([2000]); // capped, never an unbounded wait
  });

  it('gives up after maxRetries on persistent 500', async () => {
    const { http, calls } = client([json({}, 500)], { maxRetries: 2 });
    await expect(http.getJson('https://api.lever.co/v0/postings/x')).rejects.toMatchObject({ status: 500, retryable: true });
    expect(calls).toHaveLength(3);
  });

  it('retries timeouts and network errors', async () => {
    const { http, calls } = client([timeoutError(), new TypeError('fetch failed'), json({ ok: 1 })]);
    await expect(http.getJson('https://api.lever.co/v0/postings/x')).resolves.toEqual({ ok: 1 });
    expect(calls).toHaveLength(3);
  });

  it.each([400, 401, 403, 404])('does not retry HTTP %i', async (status) => {
    const { http, calls } = client([json({}, status)]);
    await expect(http.getJson('https://api.lever.co/v0/postings/x')).rejects.toMatchObject({ status, retryable: false });
    expect(calls).toHaveLength(1);
  });

  it('does not retry malformed JSON', async () => {
    const { http, calls } = client([new Response('<html>', { status: 200 })]);
    await expect(http.getJson('https://api.lever.co/v0/postings/x')).rejects.toThrow(/Malformed JSON/);
    expect(calls).toHaveLength(1);
  });

  it('SSRF: blocks non-allowlisted hosts, http, credentials and redirects off-list', async () => {
    const { http, calls } = client([json({})]);
    await expect(http.getJson('https://evil.example.com/x')).rejects.toThrow(/Blocked host/);
    await expect(http.getJson('http://api.lever.co/x')).rejects.toThrow(/non-https/);
    await expect(http.getJson('https://user:pw@api.lever.co/x')).rejects.toThrow(/credentials/);
    await expect(http.getJson('https://169.254.169.254/latest/meta-data')).rejects.toThrow(/Blocked host/);
    expect(calls).toHaveLength(0);

    const redirect = client([new Response(null, { status: 302, headers: { location: 'https://evil.example.com/steal' } })]);
    await expect(redirect.http.getJson('https://api.lever.co/x')).rejects.toThrow(/Blocked host/);
  });

  it('enforces the response size limit', async () => {
    const { http } = client([new Response('x'.repeat(5000), { status: 200 })], { maxResponseBytes: 1024 });
    await expect(http.getText('https://api.lever.co/x')).rejects.toBeInstanceOf(ProviderHttpError);
  });

  it('error messages never include query strings or headers', async () => {
    const { http } = client([json({}, 401)]);
    const err = await http
      .getJson('https://api.lever.co/x?token=SECRETVALUE', { headers: { Authorization: 'Bearer SECRETVALUE' } })
      .then(() => new Error('unexpected success'), (e: Error) => e);
    expect(String(err.message)).not.toContain('SECRETVALUE');
  });
});

describe('Provider-level behaviour', () => {
  it('Greenhouse: a failing board is isolated, others still return jobs', async () => {
    const good = { jobs: [{ id: 1, title: 'Backend Engineer', absolute_url: 'https://boards.greenhouse.io/b/jobs/1', location: { name: 'Bengaluru' } }] };
    const responses: Array<Response | Error> = [json({}, 404), json(good)];
    const { http } = client(responses);
    const c = { ...cfg, greenhouseBoards: ['bad', 'good'], http: { ...cfg.http, boardDelayMs: 0 } };
    const res = await greenhouseProvider.fetchJobs({ http, config: c });
    expect(res.jobs).toHaveLength(1);
    expect(res.boardsFailed).toBe(1);
    expect(res.errors[0]).toMatch(/^bad:/);
  });

  it('Greenhouse: throws when every board fails (timeouts)', async () => {
    const { http } = client([timeoutError()], { maxRetries: 0 });
    const c = { ...cfg, greenhouseBoards: ['a', 'b'], http: { ...cfg.http, boardDelayMs: 0, maxRetries: 0 } };
    await expect(greenhouseProvider.fetchJobs({ http, config: c })).rejects.toThrow(/All 2 boards failed/);
  });

  it('config rejects unsafe board tokens (path injection)', () => {
    const c = loadJobSyncConfig({ JOB_SYNC_GREENHOUSE_BOARDS: 'good,../../etc/passwd,evil.com/x,ok_1' } as unknown as NodeJS.ProcessEnv);
    expect(c.greenhouseBoards).toEqual(['good', 'ok_1']);
  });
});
