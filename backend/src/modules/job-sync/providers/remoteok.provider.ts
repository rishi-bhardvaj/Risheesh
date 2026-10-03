import { ProviderHttpError } from '../http';
import type { JobProvider, ProviderContext, RawJob } from '../types';
import { formatSalary, isObj, str } from './_util';

/**
 * RemoteOK public API. Element 0 is a legal notice. Their terms require linking back to the
 * posting, which we do (url is the RemoteOK page).
 */
export const remoteOkProvider: JobProvider = {
  id: 'remoteok',
  source: 'RemoteOK',
  async fetchJobs(ctx: ProviderContext) {
    const json = await ctx.http.getJson('https://remoteok.com/api', { signal: ctx.signal });
    const jobs = parseRemoteOk(json);
    const keep = ctx.prefilter ? jobs.filter((j) => ctx.prefilter!(j.title, j.location ?? null)) : jobs;
    return { jobs: keep.slice(0, ctx.config.maxJobsPerBoard), boardsAttempted: 1, boardsFailed: 0, errors: [] };
  },
};

export function parseRemoteOk(json: unknown): RawJob[] {
  if (!Array.isArray(json)) throw new ProviderHttpError('Unexpected RemoteOK response shape', null, false);
  const out: RawJob[] = [];
  for (const item of json) {
    if (!isObj(item) || 'legal' in item) continue;
    const title = str(item.position);
    const company = str(item.company);
    const url = str(item.url);
    const id = str(item.id) || url;
    if (!title || !company || !url) continue;
    const tags = Array.isArray(item.tags) ? item.tags.map(str).filter(Boolean) : [];
    out.push({
      source: 'RemoteOK',
      externalId: id,
      url,
      title,
      company,
      location: str(item.location) || 'Remote',
      description: str(item.description) || null,
      postedAt: str(item.date) || null,
      salary: formatSalary(item.salary_min, item.salary_max),
      skills: tags,
      isRemote: true,
      metadata: { tags },
    });
  }
  return out;
}
