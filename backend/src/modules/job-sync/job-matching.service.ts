import type { CandidateProfile, JobSyncConfig } from './job-sync.config';
import type { MatchResult, NormalizedJob } from './types';

interface ExperienceReq {
  min: number | null;
  max: number | null;
  text: string | null;
}

const rx = (src: string): RegExp => new RegExp(src, 'i');

/**
 * Pulls the stated years-of-experience requirement out of free text.
 * Takes the strictest lower bound found next to the word "experience".
 */
export function parseExperience(text: string): ExperienceReq {
  let body = text.slice(0, 8000);
  let min: number | null = null;
  let max: number | null = null;
  let label: string | null = null;

  const consider = (lo: number, hi: number | null, snippet: string) => {
    if (lo > 40 || (hi !== null && hi > 50)) return; // "since 1998"-style noise
    if (min === null || lo > min) {
      min = lo;
      max = hi;
      label = snippet;
    }
  };

  // Ranges first ("3-5 years"); mask them so the upper bound is not re-read as a lower bound.
  const range = /(\d{1,2})\s*(?:-|–|—|to)\s*(\d{1,2})\s*\+?\s*(?:years?|yrs?)\b/gi;
  for (const m of body.matchAll(range)) {
    const end = m.index! + m[0].length;
    const tail = body.slice(end, end + 60);
    const head = body.slice(Math.max(0, m.index! - 40), m.index!);
    if (/experience/i.test(tail) || /experience/i.test(head)) {
      consider(Number(m[1]), Number(m[2]), `${m[1]}-${m[2]} years`);
    }
  }
  body = body.replace(range, (m) => ' '.repeat(m.length));

  const single = /(\d{1,2})\s*(\+|plus)?\s*(?:years?|yrs?)\b(?:'?s)?\s+(?:of\s+)?(?:[\w-]+[\s,/]+){0,4}?experience/gi;
  for (const m of body.matchAll(single)) consider(Number(m[1]), null, `${m[1]}${m[2] ? '+' : ''} years`);

  const reverse = /experience[^.\n]{0,40}?(?:of\s+)?(?:at least\s+)?(\d{1,2})\s*(\+|plus)?\s*(?:years?|yrs?)\b/gi;
  for (const m of body.matchAll(reverse)) consider(Number(m[1]), null, `${m[1]}${m[2] ? '+' : ''} years`);

  if (min === null && /\b(freshers?|entry[\s-]level|new grad(uate)?s?|recent graduates?)\b/i.test(body)) {
    return { min: 0, max: 1, text: '0-1 years (entry level)' };
  }
  return { min, max, text: label };
}

function anyMatch(patterns: string[], text: string): boolean {
  return patterns.some((p) => rx(p).test(text));
}

export class JobMatchingService {
  private readonly p: CandidateProfile;
  private readonly roleRx: Array<{ label: string; score: number; res: RegExp[] }>;
  private readonly skillRx: Array<{ name: string; tier: 'primary' | 'secondary'; re: RegExp }>;

  constructor(private readonly cfg: Pick<JobSyncConfig, 'profile' | 'minMatchScore' | 'maxPostedAgeDays'>) {
    this.p = cfg.profile;
    this.roleRx = this.p.roles.map((r) => ({ label: r.label, score: r.score, res: r.patterns.map(rx) }));
    this.skillRx = this.p.skills.map((s) => ({ name: s.name, tier: s.tier, re: rx(s.pattern) }));
  }

  /**
   * Cheap title-only gate used by providers before per-board caps: skips postings that could
   * never be accepted (seniority, unrelated professions, interns, non-target roles).
   */
  titlePrefilter = (title: string, _location: string | null): boolean => {
    if (!this.p.allowInternships && /\bintern(ship)?s?\b/i.test(title)) return false;
    if (anyMatch(this.p.rejectTitlePatterns, title) || anyMatch(this.p.nonTechTitlePatterns, title)) return false;
    return this.roleRx.some((r) => r.res.some((re) => re.test(title)));
  };

  evaluate(job: NormalizedJob, now: Date = new Date()): MatchResult {
    const reject = (rejection: string, reason: string, extra: Partial<MatchResult> = {}): MatchResult => ({
      accepted: false,
      score: 0,
      reason,
      rejection,
      matchedSkills: [],
      experienceRequirement: null,
      ...extra,
    });

    const title = job.title;
    const body = `${job.description ?? ''}`;
    const haystack = `${title}\n${job.skills.join(' ')}\n${body}`;

    // ---- Hard filters -------------------------------------------------------------------
    if (!this.p.allowInternships && (/\bintern(ship)?s?\b/i.test(title) || /intern/i.test(job.employmentType ?? ''))) {
      return reject('internship', 'Internship role');
    }
    if (anyMatch(this.p.rejectTitlePatterns, title)) return reject('seniority', 'Senior/leadership title');
    if (anyMatch(this.p.nonTechTitlePatterns, title)) return reject('unrelated_role', 'Unrelated profession or stack');

    if (job.postedAt) {
      const ageDays = (now.getTime() - job.postedAt.getTime()) / 86_400_000;
      if (ageDays > this.cfg.maxPostedAgeDays) return reject('too_old', `Posted ${Math.round(ageDays)} days ago`);
    }

    const exp = parseExperience(body);
    if (exp.min !== null && exp.min > this.p.maxYearsExperience) {
      return reject('experience', `Requires ${exp.text ?? `${exp.min}+ years`}`, { experienceRequirement: exp.text });
    }

    // ---- Role ---------------------------------------------------------------------------
    let roleScore = 0;
    let roleLabel = '';
    for (const r of this.roleRx) {
      if (r.score > roleScore && r.res.some((re) => re.test(title))) {
        roleScore = r.score;
        roleLabel = r.label;
      }
    }
    if (roleScore === 0) return reject('role_mismatch', 'Title does not match target roles', { experienceRequirement: exp.text });

    // ---- Location -----------------------------------------------------------------------
    const loc = this.scoreLocation(job);
    if (loc.score === 0) return reject('location', loc.note, { experienceRequirement: exp.text });

    // ---- Skills -------------------------------------------------------------------------
    const matched: string[] = [];
    let weight = 0;
    for (const s of this.skillRx) {
      if (s.re.test(haystack)) {
        matched.push(s.name);
        weight += s.tier === 'primary' ? 1 : 0.5;
      }
    }
    const skillScore = Math.round(Math.min(1, weight / 5) * 100);

    // ---- Experience ---------------------------------------------------------------------
    let expScore = 70; // unstated is neutral
    if (exp.min !== null) expScore = exp.min <= 1 ? 100 : 85;
    else if (/\b(junior|associate|graduate|entry[\s-]level|sde[\s-]?(i|1)|engineer[\s-]?(i|1))\b/i.test(title)) expScore = 95;

    const score = Math.round(0.4 * roleScore + 0.3 * skillScore + 0.15 * expScore + 0.15 * loc.score);
    const reasonParts = [
      `Role: ${roleLabel}`,
      matched.length ? `Skills: ${matched.slice(0, 8).join(', ')}` : 'Skills: none matched',
      `Experience: ${exp.text ?? 'not stated'}`,
      `Location: ${loc.note}`,
    ];

    if (score < this.cfg.minMatchScore) {
      return reject('low_score', `Score ${score} below threshold ${this.cfg.minMatchScore}`, {
        score,
        matchedSkills: matched,
        experienceRequirement: exp.text,
      });
    }

    return {
      accepted: true,
      score,
      reason: reasonParts.join(' · '),
      matchedSkills: matched,
      experienceRequirement: exp.text,
    };
  }

  private scoreLocation(job: NormalizedJob): { score: number; note: string } {
    const L = this.p.locations;
    const location = job.location ?? '';
    const text = location.toLowerCase();
    // A bare remote flag next to a named city (e.g. "San Francisco") does not mean open to India.
    const isRemote = /\bremote\b|work from home|\bwfh\b/i.test(text);

    if (!text) return L.allowUnknown ? { score: 40, note: 'not stated' } : { score: 0, note: 'location not stated' };
    if (L.preferred.some((p) => text.includes(p))) return { score: 100, note: location };

    const excluded = anyMatch(L.excludedRegionPatterns, location);
    const anywhere = L.anywherePatterns.some((p) => text.includes(p));

    if (isRemote && L.allowRemote) {
      if (anywhere) return { score: 85, note: `${location} (remote, open region)` };
      if (excluded) return { score: 0, note: `Remote restricted to ${location}` };
      return { score: 75, note: `${location} (remote)` };
    }
    if (anywhere) return { score: 70, note: location };
    return { score: 0, note: `On-site outside target region (${location})` };
  }
}
