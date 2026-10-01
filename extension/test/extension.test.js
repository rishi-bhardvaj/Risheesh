import test from 'node:test';
import assert from 'node:assert';

// Simulated pure modules test
function detectPageType(urlStr) {
  const url = new URL(urlStr);
  const host = url.hostname.toLowerCase();
  const path = url.pathname.toLowerCase();

  if (host.includes('linkedin.com')) {
    if (path.includes('/jobs/view') || url.searchParams.has('currentJobId')) {
      return { platform: 'linkedin', pageType: 'JOB_DETAILS' };
    }
    if (path.includes('/jobs/search')) {
      return { platform: 'linkedin', pageType: 'SEARCH_RESULTS' };
    }
    return { platform: 'linkedin', pageType: 'OTHER' };
  }

  if (host.includes('greenhouse.io')) {
    return { platform: 'ats', pageType: 'JOB_DETAILS' };
  }

  return { platform: 'web', pageType: 'OTHER' };
}

class PolicyGate {
  static isAutoRefreshPermitted(platform) {
    if (platform === 'linkedin' || platform === 'naukri') return false;
    if (platform === 'ats') return true;
    return false;
  }
}

test('detectPageType classifies LinkedIn job details and search pages', () => {
  const view1 = detectPageType('https://www.linkedin.com/jobs/view/123456');
  assert.strictEqual(view1.platform, 'linkedin');
  assert.strictEqual(view1.pageType, 'JOB_DETAILS');

  const view2 = detectPageType('https://www.linkedin.com/jobs/collections/?currentJobId=987654');
  assert.strictEqual(view2.platform, 'linkedin');
  assert.strictEqual(view2.pageType, 'JOB_DETAILS');

  const search = detectPageType('https://www.linkedin.com/jobs/search/?keywords=flutter');
  assert.strictEqual(search.platform, 'linkedin');
  assert.strictEqual(search.pageType, 'SEARCH_RESULTS');
});

test('PolicyGate strictly prohibits auto-refresh on LinkedIn and Naukri', () => {
  assert.strictEqual(PolicyGate.isAutoRefreshPermitted('linkedin'), false);
  assert.strictEqual(PolicyGate.isAutoRefreshPermitted('naukri'), false);
  assert.strictEqual(PolicyGate.isAutoRefreshPermitted('ats'), true);
});
