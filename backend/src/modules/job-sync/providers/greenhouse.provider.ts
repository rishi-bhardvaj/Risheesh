import type { JobProvider, ProviderContext, RawJob } from '../types';
import { fetchBoards, isObj, looksRemote, prettifyToken, str } from './_util';

/** Greenhouse Job Board API: https://developers.greenhouse.io/job-board.html */
export const greenhouseProvider: JobProvider = {
  id: 'greenhouse',
  source: 'Greenhouse',
  fetchJobs(ctx: ProviderContext) {
    return fetchBoards(
      ctx,
      ctx.config.greenhouseBoards.map((board) => ({
        board,
        url: `https://boards-api.greenhouse.io/v1/boards/${encodeURIComponent(board)}/jobs?content=true`,
        parse: parseGreenhouse,
      }))
    );
  },
};

export function parseGreenhouse(board: string, json: unknown): RawJob[] {
  if (!isObj(json) || !Array.isArray(json.jobs)) throw new Error('Unexpected Greenhouse response shape');
  const out: RawJob[] = [];
  for (const item of json.jobs) {
    if (!isObj(item)) continue;
    const loc = isObj(item.location) ? str(item.location.name) : '';
    const departments = Array.isArray(item.departments)
      ? item.departments.filter(isObj).map((d) => str(d.name)).filter(Boolean)
      : [];
    const title = str(item.title);
    const url = str(item.absolute_url);
    const id = str(item.id);
    if (!title || !url || !id) continue;
    out.push({
      source: 'Greenhouse',
      externalId: `${board}:${id}`,
      url,
      title,
      company: str(item.company_name) || prettifyToken(board),
      location: loc || null,
      description: str(item.content) || null,
      postedAt: str(item.first_published) || str(item.updated_at) || null,
      skills: departments,
      isRemote: looksRemote(loc),
      metadata: { board },
    });
  }
  return out;
}
