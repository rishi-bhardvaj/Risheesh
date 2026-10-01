export type PageType = 'SEARCH_RESULTS' | 'JOB_DETAILS' | 'PROFILE' | 'FEED' | 'OTHER';

export function detectPageType(urlStr: string): { platform: string; pageType: PageType } {
  try {
    const url = new URL(urlStr);
    const host = url.hostname.toLowerCase();
    const path = url.pathname.toLowerCase();

    // LinkedIn
    if (host.includes('linkedin.com')) {
      if (path.includes('/jobs/view') || url.searchParams.has('currentJobId')) {
        return { platform: 'linkedin', pageType: 'JOB_DETAILS' };
      }
      if (path.includes('/jobs/search') || path.includes('/jobs/collections')) {
        return { platform: 'linkedin', pageType: 'SEARCH_RESULTS' };
      }
      if (path.includes('/in/')) {
        return { platform: 'linkedin', pageType: 'PROFILE' };
      }
      if (path.includes('/feed')) {
        return { platform: 'linkedin', pageType: 'FEED' };
      }
      return { platform: 'linkedin', pageType: 'OTHER' };
    }

    // Naukri
    if (host.includes('naukri.com')) {
      if (path.includes('-jobs-') || path.includes('/job-listings-')) {
        return { platform: 'naukri', pageType: 'JOB_DETAILS' };
      }
      if (path.includes('/jobs-in-') || path.includes('/search')) {
        return { platform: 'naukri', pageType: 'SEARCH_RESULTS' };
      }
      return { platform: 'naukri', pageType: 'OTHER' };
    }

    // Greenhouse / Lever / Ashby
    if (host.includes('greenhouse.io') || host.includes('lever.co') || host.includes('ashbyhq.com')) {
      return { platform: 'ats', pageType: 'JOB_DETAILS' };
    }

    return { platform: 'web', pageType: 'OTHER' };
  } catch {
    return { platform: 'unknown', pageType: 'OTHER' };
  }
}
