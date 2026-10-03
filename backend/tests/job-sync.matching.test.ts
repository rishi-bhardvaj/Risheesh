import { JobMatchingService, parseExperience } from '../src/modules/job-sync/job-matching.service';
import { loadJobSyncConfig } from '../src/modules/job-sync/job-sync.config';
import { normalizeJob } from '../src/modules/job-sync/job-normalization.service';
import type { RawJob } from '../src/modules/job-sync/types';

const matcher = new JobMatchingService(loadJobSyncConfig({} as NodeJS.ProcessEnv));

function evalJob(over: Partial<RawJob>) {
  const n = normalizeJob({ source: 'T', externalId: 'x', url: 'https://x.com/j', title: 'Backend Engineer', company: 'Acme', location: 'Bengaluru, India', description: '', ...over });
  if (!n.ok) throw new Error(n.reason);
  return matcher.evaluate(n.job);
}

describe('experience parsing', () => {
  it.each([
    ['5+ years of experience in Java', 5],
    ['3-5 years of experience', 3],
    ['at least 4 years of backend experience', 4],
    ['Experience: 2 years', 2],
    ['Freshers welcome', 0],
  ])('%s -> min %i', (text, min) => expect(parseExperience(text).min).toBe(min));
  it('returns null when nothing is stated and ignores noise', () => {
    expect(parseExperience('We have been around for 12 years.').min).toBeNull();
    expect(parseExperience('').min).toBeNull();
  });
});

describe('matching', () => {
  it('highly relevant job: accepted with high score, skills and reason', () => {
    const r = evalJob({ title: 'Backend Engineer - Java', description: 'Java, Spring Boot, Spring Security, PostgreSQL, Docker, REST APIs, JWT. 0-2 years experience.' });
    expect(r.accepted).toBe(true);
    expect(r.score).toBeGreaterThanOrEqual(85);
    expect(r.matchedSkills).toEqual(expect.arrayContaining(['Java', 'Spring Boot', 'PostgreSQL']));
    expect(r.reason).toMatch(/Role: .*Skills: .*Location: Bengaluru/);
    expect(r.experienceRequirement).toBe('0-2 years');
  });

  it('partially relevant job: accepted with a lower score', () => {
    const strong = evalJob({ description: 'Java Spring Boot PostgreSQL Docker REST' });
    const partial = evalJob({ title: 'Frontend Engineer', description: 'React and CSS', location: 'Remote - Worldwide' });
    expect(partial.accepted).toBe(true);
    expect(partial.score).toBeLessThan(strong.score);
  });

  it('JavaScript is not mistaken for Java', () => {
    const r = evalJob({ title: 'Software Engineer', description: 'We use JavaScript heavily.' });
    expect(r.matchedSkills).toContain('JavaScript');
    expect(r.matchedSkills).not.toContain('Java');
  });

  it.each([
    ['Senior Software Engineer', 'seniority'],
    ['Staff Backend Engineer', 'seniority'],
    ['Principal Engineer', 'seniority'],
    ['Engineering Manager', 'seniority'],
    ['Software Engineer III', 'seniority'],
    ['Software Engineering Intern', 'internship'],
    ['Sales Manager', 'seniority'],
    ['Account Executive', 'unrelated_role'],
    ['Recruiter', 'unrelated_role'],
    ['Marketing Specialist', 'unrelated_role'],
    ['Data Scientist', 'unrelated_role'],
    ['iOS Engineer', 'unrelated_role'],
    ['Product Designer', 'unrelated_role'],
  ])('rejects "%s" (%s)', (title, rejection) => {
    const r = evalJob({ title, description: 'Java Spring Boot' });
    expect(r.accepted).toBe(false);
    expect(r.rejection).toBe(rejection);
  });

  it('rejects a generic engineering title that is not a target role', () => {
    const r = evalJob({ title: 'Hardware Test Specialist', description: 'Java' });
    expect(r.accepted).toBe(false);
  });

  it('rejects roles demanding more experience than configured, accepts within range', () => {
    expect(evalJob({ description: '5+ years of experience required' })).toMatchObject({ accepted: false, rejection: 'experience' });
    expect(evalJob({ description: '3-5 years of experience' })).toMatchObject({ accepted: false, rejection: 'experience' });
    expect(evalJob({ description: '1-2 years of experience with Java' }).accepted).toBe(true);
  });

  it('location: India/remote-anywhere ok; region-locked remote and foreign on-site rejected', () => {
    expect(evalJob({ location: 'Pune, India' }).accepted).toBe(true);
    expect(evalJob({ location: 'Remote - Anywhere in the World' }).accepted).toBe(true);
    expect(evalJob({ location: 'Remote - USA Only' })).toMatchObject({ accepted: false, rejection: 'location' });
    expect(evalJob({ location: 'Remote U.S.' })).toMatchObject({ accepted: false, rejection: 'location' });
    expect(evalJob({ location: 'Remote (Canada)' })).toMatchObject({ accepted: false, rejection: 'location' });
    expect(evalJob({ location: 'San Francisco, CA' })).toMatchObject({ accepted: false, rejection: 'location' });
    expect(evalJob({ location: 'London, UK', isRemote: true })).toMatchObject({ accepted: false, rejection: 'location' });
  });

  it('rejects postings older than the configured age', () => {
    const r = evalJob({ postedAt: new Date(Date.now() - 800 * 86_400_000) });
    expect(r).toMatchObject({ accepted: false, rejection: 'too_old' });
  });

  it('thresholds and internships are configurable, not hardcoded', () => {
    const lenient = new JobMatchingService(loadJobSyncConfig({ JOB_SYNC_ALLOW_INTERNSHIPS: 'true', JOB_SYNC_MAX_YEARS: '5' } as unknown as NodeJS.ProcessEnv));
    const n = normalizeJob({ source: 'T', externalId: '1', url: 'https://x.com/1', title: 'Backend Engineer Intern', company: 'A', location: 'Pune', description: '4 years of experience' });
    if (!n.ok) throw new Error('bad');
    expect(lenient.evaluate(n.job).accepted).toBe(true);
    expect(matcher.evaluate(n.job).accepted).toBe(false);
  });

  it('prefilter drops obviously irrelevant titles before per-board caps', () => {
    expect(matcher.titlePrefilter('Backend Engineer', null)).toBe(true);
    expect(matcher.titlePrefilter('Senior Backend Engineer', null)).toBe(false);
    expect(matcher.titlePrefilter('Sales Development Representative', null)).toBe(false);
  });
});
