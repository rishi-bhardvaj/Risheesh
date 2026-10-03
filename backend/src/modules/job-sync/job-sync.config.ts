import fs from 'fs';
import path from 'path';

/**
 * All tunables for the hourly job sync live here (plus env vars and an optional JSON profile
 * file), so filtering rules are never scattered through the code.
 */
export interface SkillRule {
  name: string;
  /** Regex source, matched case-insensitively against title + tags + description. */
  pattern: string;
  tier: 'primary' | 'secondary';
}

export interface RoleRule {
  label: string;
  patterns: string[];
  /** 0-100 role fit when any pattern matches the title. */
  score: number;
}

export interface CandidateProfile {
  roles: RoleRule[];
  skills: SkillRule[];
  /** Highest minimum-years requirement still considered a fit. */
  maxYearsExperience: number;
  allowInternships: boolean;
  /** Title patterns that are rejected outright (seniority). */
  rejectTitlePatterns: string[];
  /** Title patterns for clearly unrelated professions / stacks. */
  nonTechTitlePatterns: string[];
  locations: {
    preferred: string[];
    /** A remote role is rejected if it names one of these regions without a preferred/anywhere term. */
    excludedRegionPatterns: string[];
    anywherePatterns: string[];
    allowRemote: boolean;
    allowUnknown: boolean;
  };
}

export interface JobSyncConfig {
  enabledProviders: string[];
  greenhouseBoards: string[];
  leverOrgs: string[];
  ashbyOrgs: string[];
  http: {
    timeoutMs: number;
    maxRetries: number;
    retryBaseMs: number;
    retryMaxMs: number;
    maxResponseBytes: number;
    /** Pause between consecutive board requests of one provider (politeness / rate limits). */
    boardDelayMs: number;
    userAgent: string;
  };
  providerTimeoutMs: number;
  maxJobsPerBoard: number;
  maxDescriptionChars: number;
  minMatchScore: number;
  maxPostedAgeDays: number;
  staleAfterHours: number;
  closeAfterDays: number;
  lockTtlSeconds: number;
  profile: CandidateProfile;
}

export const DEFAULT_PROFILE: CandidateProfile = {
  roles: [
    {
      label: 'Backend / Java / Spring',
      score: 100,
      patterns: [
        'back[\\s-]?end',
        '\\bjava\\b(?!\\s?script)',
        'spring\\s?boot',
        'node(\\.?js)?\\s+(developer|engineer)',
        'nest\\s?js',
        'api\\s+(developer|engineer)',
        'server[\\s-]?side',
      ],
    },
    {
      label: 'Software Engineer / Developer',
      score: 100,
      patterns: [
        'software\\s+(engineer|developer)',
        '\\bsde\\b',
        'software\\s+development\\s+engineer',
        'application\\s+(developer|engineer)',
        '^(associate|junior|graduate|entry[\\s-]level)?\\s*engineer\\b',
      ],
    },
    { label: 'Full Stack', score: 95, patterns: ['full[\\s-]?stack'] },
    {
      label: 'Platform / DevOps / SRE',
      score: 60,
      patterns: ['platform\\s+engineer', 'devops', 'site\\s+reliability', '\\bsre\\b', 'cloud\\s+engineer', 'infrastructure\\s+engineer'],
    },
    {
      label: 'Frontend / Web',
      score: 55,
      patterns: ['front[\\s-]?end', 'web\\s+developer', 'ui\\s+engineer', 'angular', 'react\\s+(developer|engineer)'],
    },
  ],
  skills: [
    { name: 'Java', pattern: '\\bjava\\b(?!\\s?script)', tier: 'primary' },
    { name: 'Spring Boot', pattern: 'spring[\\s-]?boot', tier: 'primary' },
    { name: 'Spring Security', pattern: 'spring[\\s-]?security', tier: 'primary' },
    { name: 'JavaScript', pattern: 'java[\\s-]?script|\\becmascript\\b', tier: 'primary' },
    { name: 'TypeScript', pattern: 'type[\\s-]?script', tier: 'primary' },
    { name: 'Node.js', pattern: '\\bnode(\\.?js)?\\b', tier: 'primary' },
    { name: 'NestJS', pattern: 'nest\\.?js', tier: 'primary' },
    { name: 'Python', pattern: '\\bpython\\b', tier: 'primary' },
    { name: 'SQL', pattern: '\\bsql\\b|\\bmysql\\b', tier: 'primary' },
    { name: 'PostgreSQL', pattern: 'postgres(ql)?', tier: 'primary' },
    { name: 'REST APIs', pattern: '\\brest(ful)?\\b|\\bapis?\\b', tier: 'primary' },
    { name: 'Oracle', pattern: '\\boracle\\b', tier: 'secondary' },
    { name: 'MongoDB', pattern: 'mongo\\s?db', tier: 'secondary' },
    { name: 'Angular', pattern: '\\bangular(js)?\\b', tier: 'secondary' },
    { name: 'React', pattern: '\\breact(\\.?js)?\\b', tier: 'secondary' },
    { name: 'JWT', pattern: '\\bjwt\\b|json web token', tier: 'secondary' },
    { name: 'OAuth2', pattern: 'oauth\\s?2?', tier: 'secondary' },
    { name: 'RBAC', pattern: '\\brbac\\b|role[\\s-]based access', tier: 'secondary' },
    { name: 'Docker', pattern: '\\bdocker\\b', tier: 'secondary' },
    { name: 'Kubernetes', pattern: '\\bkubernetes\\b|\\bk8s\\b', tier: 'secondary' },
    { name: 'Jenkins', pattern: '\\bjenkins\\b', tier: 'secondary' },
    { name: 'Git', pattern: '\\bgit(hub|lab)?\\b', tier: 'secondary' },
    { name: 'CI/CD', pattern: 'ci\\s?/\\s?cd|continuous (integration|delivery|deployment)', tier: 'secondary' },
  ],
  maxYearsExperience: 2,
  allowInternships: false,
  rejectTitlePatterns: [
    '\\b(senior|sr\\.?|staff|principal|lead|distinguished|fellow)\\b',
    '\\b(manager|director|head of|vp|vice president|chief|cto|architect)\\b',
    '\\b(iii|iv|v)\\s*$',
    '\\b(engineer|developer)\\s+(iii|iv|v)\\b',
  ],
  nonTechTitlePatterns: [
    '\\b(sales|marketing|recruit(er|ing)?|talent|hr|human resources|account (executive|manager)|customer (success|support)|finance|accountant|legal|counsel|content|copywriter|designer|support specialist|business development|payroll|compliance|paralegal)\\b',
    '\\b(data scientist|machine learning|ml|research scientist|security engineer|hardware|mechanical|electrical|embedded|firmware|ios|android|solutions? engineer|sales engineer|support engineer|qa|test engineer|sdet)\\b',
  ],
  locations: {
    preferred: [
      'india', 'bengaluru', 'bangalore', 'karnataka', 'hyderabad', 'pune', 'mumbai', 'delhi',
      'gurgaon', 'gurugram', 'noida', 'chennai', 'kolkata', 'ahmedabad',
    ],
    excludedRegionPatterns: [
      // Lookarounds instead of \b so dotted forms such as "U.S." and "U.K." are caught too.
      '(?<![a-z])(us|usa|u\\.s\\.a?\\.?|united states|canada|uk|u\\.k\\.?|united kingdom|england|europe|emea|eu|latam|latin america|americas|north america|south america|australia|new zealand|germany|france|spain|ireland|netherlands|poland|brazil|mexico|argentina|colombia|israel|japan|singapore|dubai|uae)(?![a-z])',
    ],
    anywherePatterns: ['anywhere', 'worldwide', 'world wide', 'global', 'apac', 'asia', 'any location'],
    allowRemote: true,
    allowUnknown: true,
  },
};

const listFromEnv = (v: string | undefined, fallback: string[]): string[] =>
  v === undefined ? fallback : v.split(',').map((s) => s.trim()).filter(Boolean);

const intFromEnv = (v: string | undefined, fallback: number, min = 0): number => {
  if (v === undefined || v.trim() === '') return fallback;
  const n = Number.parseInt(v, 10);
  return Number.isFinite(n) && n >= min ? n : fallback;
};

const boolFromEnv = (v: string | undefined, fallback: boolean): boolean =>
  v === undefined || v.trim() === '' ? fallback : ['1', 'true', 'yes'].includes(v.trim().toLowerCase());

/** Board tokens end up in provider URLs, so they are validated hard (SSRF / path injection). */
export const BOARD_TOKEN_RE = /^[a-z0-9][a-z0-9_-]{0,63}$/i;

export function loadJobSyncConfig(env: NodeJS.ProcessEnv = process.env): JobSyncConfig {
  let profile = DEFAULT_PROFILE;

  // Optional override: JSON file with a partial CandidateProfile (keep it out of Git if personal).
  const profilePath = env.JOB_SYNC_PROFILE_PATH;
  if (profilePath) {
    const override = JSON.parse(fs.readFileSync(path.resolve(profilePath), 'utf8')) as Partial<CandidateProfile>;
    profile = {
      ...DEFAULT_PROFILE,
      ...override,
      locations: { ...DEFAULT_PROFILE.locations, ...(override.locations ?? {}) },
    };
  }
  profile = {
    ...profile,
    maxYearsExperience: intFromEnv(env.JOB_SYNC_MAX_YEARS, profile.maxYearsExperience),
    allowInternships: boolFromEnv(env.JOB_SYNC_ALLOW_INTERNSHIPS, profile.allowInternships),
  };

  const tokens = (v: string | undefined, d: string[]) => listFromEnv(v, d).filter((t) => BOARD_TOKEN_RE.test(t));

  return {
    enabledProviders: listFromEnv(env.JOB_SYNC_PROVIDERS, ['greenhouse', 'lever', 'ashby', 'remoteok', 'weworkremotely']).map((s) =>
      s.toLowerCase()
    ),
    // Boards verified live by the Flutter provider (hashicorp/retool/etc. 404 as of Sep 2026).
    greenhouseBoards: tokens(env.JOB_SYNC_GREENHOUSE_BOARDS, [
      'airbnb', 'stripe', 'figma', 'cloudflare', 'databricks', 'gusto', 'discord', 'gitlab', 'coinbase', 'vercel', 'datadog', 'reddit',
    ]),
    leverOrgs: tokens(env.JOB_SYNC_LEVER_ORGS, ['palantir', 'spotify', 'shieldai']),
    ashbyOrgs: tokens(env.JOB_SYNC_ASHBY_ORGS, ['ramp', 'linear', 'supabase', 'notion', 'vanta']),
    http: {
      timeoutMs: intFromEnv(env.JOB_SYNC_TIMEOUT_MS, 15000, 1000),
      maxRetries: intFromEnv(env.JOB_SYNC_MAX_RETRIES, 3),
      retryBaseMs: intFromEnv(env.JOB_SYNC_RETRY_BASE_MS, 500, 1),
      retryMaxMs: intFromEnv(env.JOB_SYNC_RETRY_MAX_MS, 8000, 1),
      maxResponseBytes: intFromEnv(env.JOB_SYNC_MAX_RESPONSE_BYTES, 20 * 1024 * 1024, 1024),
      boardDelayMs: intFromEnv(env.JOB_SYNC_BOARD_DELAY_MS, 250),
      userAgent: 'CareerOS-JobSync/1.0 (personal job discovery)',
    },
    providerTimeoutMs: intFromEnv(env.JOB_SYNC_PROVIDER_TIMEOUT_MS, 120000, 1000),
    maxJobsPerBoard: intFromEnv(env.JOB_SYNC_MAX_JOBS_PER_BOARD, 400, 1),
    maxDescriptionChars: 12000,
    minMatchScore: intFromEnv(env.JOB_SYNC_MIN_MATCH_SCORE, 45),
    maxPostedAgeDays: intFromEnv(env.JOB_SYNC_MAX_POSTED_AGE_DAYS, 365, 1),
    staleAfterHours: intFromEnv(env.JOB_SYNC_STALE_AFTER_HOURS, 48, 1),
    closeAfterDays: intFromEnv(env.JOB_SYNC_CLOSE_AFTER_DAYS, 14, 1),
    lockTtlSeconds: intFromEnv(env.JOB_SYNC_LOCK_TTL_SECONDS, 900, 30),
    profile,
  };
}
