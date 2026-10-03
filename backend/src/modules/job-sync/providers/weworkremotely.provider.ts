import { ProviderHttpError } from '../http';
import { decodeEntities } from '../job-normalization.service';
import type { JobProvider, ProviderContext, RawJob } from '../types';

const FEED = 'https://weworkremotely.com/categories/remote-programming-jobs.rss';

export const weWorkRemotelyProvider: JobProvider = {
  id: 'weworkremotely',
  source: 'WeWorkRemotely',
  async fetchJobs(ctx: ProviderContext) {
    const xml = await ctx.http.getText(FEED, {
      signal: ctx.signal,
      headers: { Accept: 'application/rss+xml, application/xml;q=0.9, */*;q=0.5' },
    });
    const jobs = parseWwrRss(xml);
    const keep = ctx.prefilter ? jobs.filter((j) => ctx.prefilter!(j.title, j.location ?? null)) : jobs;
    return { jobs: keep.slice(0, ctx.config.maxJobsPerBoard), boardsAttempted: 1, boardsFailed: 0, errors: [] };
  },
};

function tag(block: string, name: string): string {
  const m = new RegExp(`<${name}(?:\\s[^>]*)?>([\\s\\S]*?)</${name}>`, 'i').exec(block);
  if (!m) return '';
  const cdata = /^\s*<!\[CDATA\[([\s\S]*?)\]\]>\s*$/.exec(m[1]);
  return (cdata ? cdata[1] : decodeEntities(m[1])).trim();
}

export function parseWwrRss(xml: string): RawJob[] {
  if (!/<rss[\s>]|<feed[\s>]/i.test(xml)) {
    throw new ProviderHttpError('Unexpected WeWorkRemotely feed (not RSS)', null, false);
  }
  const out: RawJob[] = [];
  for (const m of xml.matchAll(/<item>([\s\S]*?)<\/item>/gi)) {
    const block = m[1];
    const rawTitle = tag(block, 'title');
    const link = tag(block, 'link') || tag(block, 'guid');
    if (!rawTitle || !link) continue;
    let company = 'WeWorkRemotely';
    let title = rawTitle;
    const idx = rawTitle.indexOf(':');
    if (idx > 0) {
      company = rawTitle.slice(0, idx).trim();
      title = rawTitle.slice(idx + 1).trim();
    }
    const region = tag(block, 'region');
    out.push({
      source: 'WeWorkRemotely',
      externalId: tag(block, 'guid') || link,
      url: link,
      title,
      company,
      // <region> carries restrictions such as "USA Only" / "Anywhere in the World"; matching relies on it.
      location: region ? `Remote - ${region}` : 'Remote',
      description: tag(block, 'description') || null,
      postedAt: tag(block, 'pubDate') || null,
      employmentType: tag(block, 'type') || null,
      isRemote: true,
    });
  }
  return out;
}
