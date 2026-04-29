'use client';

const API_BASE = process.env.NEXT_PUBLIC_API_URL ?? 'http://localhost:3000';
const ACCESS_KEY = 'fittrack.access';
const REFRESH_KEY = 'fittrack.refresh';

export interface ApiError {
  status: number;
  code: string;
  message: string;
  details?: unknown;
}

export const tokens = {
  get access(): string | null {
    if (typeof window === 'undefined') return null;
    return localStorage.getItem(ACCESS_KEY);
  },
  get refresh(): string | null {
    if (typeof window === 'undefined') return null;
    return localStorage.getItem(REFRESH_KEY);
  },
  set(access: string, refresh: string) {
    localStorage.setItem(ACCESS_KEY, access);
    localStorage.setItem(REFRESH_KEY, refresh);
  },
  clear() {
    localStorage.removeItem(ACCESS_KEY);
    localStorage.removeItem(REFRESH_KEY);
  },
};

let refreshInFlight: Promise<string | null> | null = null;

async function refreshAccessToken(): Promise<string | null> {
  if (refreshInFlight) return refreshInFlight;
  const refreshToken = tokens.refresh;
  if (!refreshToken) return null;
  refreshInFlight = (async () => {
    try {
      const res = await fetch(`${API_BASE}/auth/refresh`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ refreshToken }),
      });
      if (!res.ok) {
        tokens.clear();
        return null;
      }
      const data = (await res.json()) as { accessToken: string; refreshToken: string };
      tokens.set(data.accessToken, data.refreshToken);
      return data.accessToken;
    } catch {
      return null;
    } finally {
      refreshInFlight = null;
    }
  })();
  return refreshInFlight;
}

export interface ApiOptions extends Omit<RequestInit, 'body'> {
  body?: unknown;
  skipAuth?: boolean;
}

export async function api<T = unknown>(path: string, opts: ApiOptions = {}): Promise<T> {
  const send = async (token: string | null): Promise<Response> => {
    const headers = new Headers(opts.headers);
    if (opts.body !== undefined) headers.set('Content-Type', 'application/json');
    if (token && !opts.skipAuth) headers.set('Authorization', `Bearer ${token}`);
    return fetch(`${API_BASE}${path}`, {
      ...opts,
      headers,
      body: opts.body !== undefined ? JSON.stringify(opts.body) : undefined,
    });
  };

  let res = await send(tokens.access);
  if (res.status === 401 && !opts.skipAuth) {
    const fresh = await refreshAccessToken();
    if (fresh) {
      res = await send(fresh);
    }
  }

  if (!res.ok) {
    let payload: { error?: { code?: string; message?: string; details?: unknown } } = {};
    try { payload = await res.json(); } catch { /* ignore */ }
    const err: ApiError = {
      status: res.status,
      code: payload.error?.code ?? 'HTTP_ERROR',
      message: payload.error?.message ?? `HTTP ${res.status}`,
      details: payload.error?.details,
    };
    throw err;
  }

  if (res.status === 204) return undefined as T;
  return (await res.json()) as T;
}
