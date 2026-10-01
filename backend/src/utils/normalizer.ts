export function normalizeUrl(url?: string | null): string | null {
  if (!url) return null;
  const trimmed = url.trim();
  if (!trimmed) return null;
  try {
    const parsed = new URL(trimmed);
    // remove tracking query parameters
    const searchParams = new URLSearchParams(parsed.search);
    for (const key of Array.from(searchParams.keys())) {
      if (
        key.startsWith('utm_') ||
        key === 'ref' ||
        key === 'source' ||
        key === 'campaign' ||
        key === 'fbclid' ||
        key === 'gclid'
      ) {
        searchParams.delete(key);
      }
    }
    parsed.search = searchParams.toString();
    parsed.hash = '';
    let result = parsed.toString();
    if (result.endsWith('/')) {
      result = result.slice(0, -1);
    }
    return result;
  } catch {
    // If not a standard URL, clean whitespace
    return trimmed.replace(/\/+$/, '');
  }
}

export function normalizeText(text?: string | null): string {
  if (!text) return '';
  return text
    .toLowerCase()
    .replace(/[^\w\s]/g, ' ')
    .replace(/\s+/g, ' ')
    .trim();
}
