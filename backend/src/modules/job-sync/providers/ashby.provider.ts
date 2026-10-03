import type { JobProvider, ProviderContext, RawJob } from '../types';
import { fetchBoards, isObj, looksRemote, prettifyToken, str } from './_util';

/** Ashby Posting API: https://developers.ashbyhq.com/docs/public-job-posting-api */
export const ashbyProvider: JobProvider = {
  id: 'ashby',
  source: 'Ashby',
  fetchJobs(ctx: ProviderContext) {
    return fetchBoards(
      ctx,
      ctx.config.ashbyOrgs.map((board) => ({
        board,
        url: `https://api.ashbyhq.com/posting-api/job-board/${encodeURIComponent(board)}?includeCompensation=true`,
        parse: parseAshby,
      }))
    );
  },
};

const EMPLOYMENT: Record<string, string> = { FullTime: 'Full-time', PartTime: 'Part-time', Contract: 'Contract', Intern: 'Internship' };

export function parseAshby(board: string, json: unknown): RawJob[] {
  if (!isObj(json) || !Array.isArray(json.jobs)) throw new Error('Unexpected Ashby response shape');
  const out: RawJob[] = [];
  for (const item of json.jobs) {
    if (!isObj(item) || item.isListed === false) continue; // unlisted == not publicly open
    const loc = str(item.location);
    const title = str(item.title);
    const url = str(item.jobUrl) || str(item.applyUrl);
    const id = str(item.id);
    if (!title || !url || !id) continue;
    const comp = isObj(item.compensation) ? str(item.compensation.scrapeableCompensationSalarySummary) : '';
    out.push({
      source: 'Ashby',
      externalId: `${board}:${id}`,
      url,
      title,
      company: prettifyToken(board),
      location: loc || null,
      description: str(item.descriptionPlain) || str(item.descriptionHtml) || null,
      postedAt: str(item.publishedAt) || null,
      salary: comp || null,
      employmentType: EMPLOYMENT[str(item.employmentType)] ?? null,
      skills: [str(item.department), str(item.team)].filter(Boolean),
      isRemote: item.isRemote === true || looksRemote(loc),
      metadata: { organization: board },
    });
  }
  return out;
}
