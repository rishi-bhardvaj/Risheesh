import type { JobProvider, ProviderContext, RawJob } from '../types';
import { fetchBoards, formatSalary, isObj, looksRemote, prettifyToken, str } from './_util';

/** Lever Postings API: https://github.com/lever/postings-api */
export const leverProvider: JobProvider = {
  id: 'lever',
  source: 'Lever',
  fetchJobs(ctx: ProviderContext) {
    return fetchBoards(
      ctx,
      ctx.config.leverOrgs.map((board) => ({
        board,
        // `limit` keeps very large boards (Palantir ~6 MB unpaged) inside the timeout.
        url: `https://api.lever.co/v0/postings/${encodeURIComponent(board)}?mode=json&limit=200`,
        parse: parseLever,
      }))
    );
  },
};

export function parseLever(board: string, json: unknown): RawJob[] {
  // Unknown orgs return {"ok": false, "error": "Document not found"}.
  if (!Array.isArray(json)) {
    throw new Error(isObj(json) ? str(json.error) || 'Unexpected Lever response' : 'Unexpected Lever response');
  }
  const out: RawJob[] = [];
  for (const item of json) {
    if (!isObj(item)) continue;
    const cat = isObj(item.categories) ? item.categories : {};
    const loc = str(cat.location);
    const title = str(item.text);
    const url = str(item.hostedUrl);
    const id = str(item.id);
    if (!title || !url || !id) continue;
    const sal = isObj(item.salaryRange) ? item.salaryRange : null;
    out.push({
      source: 'Lever',
      externalId: `${board}:${id}`,
      url,
      title,
      company: prettifyToken(board),
      location: loc || null,
      description: str(item.descriptionPlain) || str(item.description) || null,
      postedAt: typeof item.createdAt === 'number' ? item.createdAt : null,
      salary: sal ? formatSalary(sal.min, sal.max, str(sal.currency) || 'USD', str(sal.interval)) : null,
      employmentType: str(cat.commitment) || null,
      skills: [str(cat.team), str(cat.department)].filter(Boolean),
      isRemote: str(item.workplaceType) === 'remote' || looksRemote(loc),
      metadata: { organization: board },
    });
  }
  return out;
}
