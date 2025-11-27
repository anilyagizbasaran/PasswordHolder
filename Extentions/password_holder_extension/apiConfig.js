const DEFAULT_API_BASE = 'http://localhost:3000/api';

export const USERS_BASE = `${DEFAULT_API_BASE}/users`;
export const HOLDERS_BASE = `${DEFAULT_API_BASE}/passwordholder`;

export function resolveApiBase() {
  return DEFAULT_API_BASE;
}

export function buildApiUrl(path = '', base = DEFAULT_API_BASE) {
  if (!path) {
    return base;
  }
  return `${base.replace(/\/$/, '')}/${path.replace(/^\//, '')}`;
}

