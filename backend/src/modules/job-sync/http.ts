import type { JobSyncConfig } from './job-sync.config';

export class ProviderHttpError extends Error {
  /** From a Retry-After header, in ms. */
  retryAfterMs?: number;

  constructor(
    message: string,
    public readonly status: number | null,
    public readonly retryable: boolean
  ) {
    super(message);
    this.name = 'ProviderHttpError';
  }
}

export interface HttpClientOptions {
  /** Injectable for tests. */
  fetchImpl?: typeof fetch;
  sleep?: (ms: number) => Promise<void>;
  random?: () => number;
}

export interface RequestOptions {
  headers?: Record<string, string>;
  signal?: AbortSignal;
  /** Overrides the default timeout for one request. */
  timeoutMs?: number;
}

const MAX_REDIRECTS = 3;
const RETRYABLE_STATUS = new Set([408, 425, 429, 500, 502, 503, 504]);

/**
 * Hardened fetch wrapper for untrusted provider endpoints:
 *  - https only, host must be in the allowlist (also re-checked on every redirect hop)
 *  - per-request timeout, never unbounded
 *  - bounded response size
 *  - retries only transient failures (timeout, network, 408/425/429/5xx) with capped exponential backoff + jitter
 *  - error messages never contain request headers or query strings
 */
export class HttpClient {
  private readonly fetchImpl: typeof fetch;
  private readonly sleep: (ms: number) => Promise<void>;
  private readonly random: () => number;

  constructor(
    private readonly cfg: JobSyncConfig['http'],
    private readonly allowedHosts: ReadonlySet<string>,
    opts: HttpClientOptions = {}
  ) {
    this.fetchImpl = opts.fetchImpl ?? fetch;
    this.sleep = opts.sleep ?? ((ms) => new Promise((r) => setTimeout(r, ms)));
    this.random = opts.random ?? Math.random;
  }

  async getJson<T = unknown>(url: string, opts: RequestOptions = {}): Promise<T> {
    const text = await this.getText(url, { ...opts, headers: { Accept: 'application/json', ...opts.headers } });
    try {
      return JSON.parse(text) as T;
    } catch {
      // Malformed body is a provider contract problem, not transient: do not retry.
      throw new ProviderHttpError(`Malformed JSON from ${this.safeLabel(url)}`, null, false);
    }
  }

  async getText(url: string, opts: RequestOptions = {}): Promise<string> {
    let attempt = 0;
    for (;;) {
      try {
        return await this.once(url, opts);
      } catch (err) {
        const retryable = err instanceof ProviderHttpError ? err.retryable : false;
        if (!retryable || attempt >= this.cfg.maxRetries || opts.signal?.aborted) throw err;
        await this.sleep(this.backoffMs(attempt, err));
        attempt++;
      }
    }
  }

  private backoffMs(attempt: number, err: unknown): number {
    const exp = Math.min(this.cfg.retryMaxMs, this.cfg.retryBaseMs * 2 ** attempt);
    const retryAfter = err instanceof ProviderHttpError ? err.retryAfterMs : undefined;
    const jitter = Math.floor(this.random() * Math.min(250, exp));
    return Math.min(this.cfg.retryMaxMs, Math.max(exp + jitter, retryAfter ?? 0));
  }

  private assertAllowed(rawUrl: string): URL {
    let u: URL;
    try {
      u = new URL(rawUrl);
    } catch {
      throw new ProviderHttpError('Invalid provider URL', null, false);
    }
    if (u.protocol !== 'https:') throw new ProviderHttpError(`Blocked non-https URL (${u.protocol})`, null, false);
    if (u.username || u.password) throw new ProviderHttpError('Blocked URL with credentials', null, false);
    if (!this.allowedHosts.has(u.hostname.toLowerCase())) throw new ProviderHttpError(`Blocked host ${u.hostname}`, null, false);
    return u;
  }

  private safeLabel(rawUrl: string): string {
    try {
      const u = new URL(rawUrl);
      return `${u.hostname}${u.pathname}`;
    } catch {
      return 'provider';
    }
  }

  private async once(startUrl: string, opts: RequestOptions): Promise<string> {
    let url = this.assertAllowed(startUrl);
    const label = this.safeLabel(startUrl);
    const timeout = AbortSignal.timeout(opts.timeoutMs ?? this.cfg.timeoutMs);
    const signal = opts.signal ? AbortSignal.any([opts.signal, timeout]) : timeout;

    for (let hop = 0; hop <= MAX_REDIRECTS; hop++) {
      let res: Response;
      try {
        res = await this.fetchImpl(url, {
          method: 'GET',
          redirect: 'manual',
          signal,
          headers: { 'User-Agent': this.cfg.userAgent, ...opts.headers },
        });
      } catch (err) {
        if (opts.signal?.aborted) throw new ProviderHttpError(`Aborted ${label}`, null, false);
        const name = (err as Error)?.name;
        if (name === 'TimeoutError' || name === 'AbortError') throw new ProviderHttpError(`Timeout fetching ${label}`, null, true);
        throw new ProviderHttpError(`Network error fetching ${label}`, null, true);
      }

      if (res.status >= 300 && res.status < 400 && res.headers.get('location')) {
        // Follow manually so every hop is re-validated against the allowlist.
        url = this.assertAllowed(new URL(res.headers.get('location') as string, url).toString());
        void res.body?.cancel().catch(() => undefined);
        continue;
      }

      if (!res.ok) {
        void res.body?.cancel().catch(() => undefined);
        const err = new ProviderHttpError(`HTTP ${res.status} from ${label}`, res.status, RETRYABLE_STATUS.has(res.status));
        const ra = Number.parseInt(res.headers.get('retry-after') ?? '', 10);
        if (Number.isFinite(ra) && ra >= 0) err.retryAfterMs = ra * 1000;
        throw err;
      }

      try {
        return await this.readCapped(res, label);
      } catch (err) {
        if (err instanceof ProviderHttpError) throw err;
        const name = (err as Error)?.name;
        if (name === 'TimeoutError' || name === 'AbortError') throw new ProviderHttpError(`Timeout reading ${label}`, null, true);
        throw new ProviderHttpError(`Network error reading ${label}`, null, true);
      }
    }
    throw new ProviderHttpError(`Too many redirects from ${label}`, null, false);
  }

  private async readCapped(res: Response, label: string): Promise<string> {
    const declared = Number.parseInt(res.headers.get('content-length') ?? '', 10);
    if (Number.isFinite(declared) && declared > this.cfg.maxResponseBytes) {
      void res.body?.cancel().catch(() => undefined);
      throw new ProviderHttpError(`Response from ${label} exceeds size limit`, null, false);
    }
    if (!res.body) return '';
    const reader = res.body.getReader();
    const chunks: Uint8Array[] = [];
    let total = 0;
    for (;;) {
      const { done, value } = await reader.read();
      if (done) break;
      total += value.byteLength;
      if (total > this.cfg.maxResponseBytes) {
        void reader.cancel().catch(() => undefined);
        throw new ProviderHttpError(`Response from ${label} exceeds size limit`, null, false);
      }
      chunks.push(value);
    }
    return Buffer.concat(chunks).toString('utf8');
  }
}

export const sleepMs = (ms: number): Promise<void> => new Promise((r) => setTimeout(r, ms));
