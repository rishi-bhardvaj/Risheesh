// Injected only on user action or allowlisted domains
export function extractJsonLd(): Record<string, unknown>[] {
  const scripts = document.querySelectorAll('script[type="application/ld+json"]');
  const results: Record<string, unknown>[] = [];

  scripts.forEach((s) => {
    try {
      const data = JSON.parse(s.textContent || '');
      if (Array.isArray(data)) {
        results.push(...data);
      } else if (data && typeof data === 'object') {
        results.push(data);
      }
    } catch {
      // Ignore malformed JSON-LD
    }
  });

  return results;
}
