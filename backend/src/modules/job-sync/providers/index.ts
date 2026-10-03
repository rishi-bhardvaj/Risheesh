import type { JobSyncConfig } from '../job-sync.config';
import type { JobProvider } from '../types';
import { ashbyProvider } from './ashby.provider';
import { greenhouseProvider } from './greenhouse.provider';
import { leverProvider } from './lever.provider';
import { remoteOkProvider } from './remoteok.provider';
import { weWorkRemotelyProvider } from './weworkremotely.provider';

export const ALL_PROVIDERS: JobProvider[] = [
  greenhouseProvider,
  leverProvider,
  ashbyProvider,
  remoteOkProvider,
  weWorkRemotelyProvider,
];

/** Fixed allowlist of hosts the sync may ever contact (SSRF guard). */
export const ALLOWED_HOSTS: ReadonlySet<string> = new Set([
  'boards-api.greenhouse.io',
  'api.lever.co',
  'api.ashbyhq.com',
  'remoteok.com',
  'weworkremotely.com',
  'www.weworkremotely.com',
]);

export function enabledProviders(cfg: JobSyncConfig): JobProvider[] {
  return ALL_PROVIDERS.filter((p) => cfg.enabledProviders.includes(p.id));
}
