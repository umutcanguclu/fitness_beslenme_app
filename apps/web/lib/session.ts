'use client';

import { useEffect, useState } from 'react';
import { api, tokens } from './api';

export interface SessionUser {
  id: string;
  email: string;
  fullName: string;
  role: 'coach' | 'player';
  locale: 'tr' | 'en';
}

export interface AuthResponse {
  user: SessionUser;
  tokens: { accessToken: string; refreshToken: string };
}

export async function login(email: string, password: string): Promise<SessionUser> {
  const res = await api<AuthResponse>('/auth/login', {
    method: 'POST',
    body: { email, password },
    skipAuth: true,
  });
  tokens.set(res.tokens.accessToken, res.tokens.refreshToken);
  return res.user;
}

export async function loginWithCode(code: string): Promise<SessionUser> {
  const res = await api<AuthResponse>('/auth/login/code', {
    method: 'POST',
    body: { code: code.toUpperCase().trim() },
    skipAuth: true,
  });
  tokens.set(res.tokens.accessToken, res.tokens.refreshToken);
  return res.user;
}

export async function registerCoach(input: {
  email: string;
  password: string;
  fullName: string;
  clubName?: string;
}): Promise<SessionUser> {
  const res = await api<AuthResponse>('/auth/register/coach', {
    method: 'POST',
    body: input,
    skipAuth: true,
  });
  tokens.set(res.tokens.accessToken, res.tokens.refreshToken);
  return res.user;
}

export async function registerPlayer(input: {
  email: string;
  password: string;
  fullName: string;
  inviteCode: string;
}): Promise<SessionUser> {
  const res = await api<AuthResponse>('/auth/register/player', {
    method: 'POST',
    body: input,
    skipAuth: true,
  });
  tokens.set(res.tokens.accessToken, res.tokens.refreshToken);
  return res.user;
}

export async function logout(): Promise<void> {
  const refresh = tokens.refresh;
  if (refresh) {
    try {
      await api('/auth/logout', { method: 'POST', body: { refreshToken: refresh }, skipAuth: true });
    } catch { /* yine de localden temizle */ }
  }
  tokens.clear();
}

export async function fetchMe(): Promise<SessionUser | null> {
  if (!tokens.access) return null;
  try {
    return await api<SessionUser>('/auth/me');
  } catch {
    return null;
  }
}

// React hook: oturum durumu yükler.
export function useSession() {
  const [user, setUser] = useState<SessionUser | null>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    let cancelled = false;
    void fetchMe().then((u) => {
      if (!cancelled) {
        setUser(u);
        setLoading(false);
      }
    });
    return () => {
      cancelled = true;
    };
  }, []);

  return { user, loading };
}
