import { create } from 'zustand';
import type { User } from '@fittrack/shared';
import { secureStorage, StorageKey } from '../lib/storage';

interface AuthState {
  user: User | null;
  accessToken: string | null;
  refreshToken: string | null;
  isHydrated: boolean;
  hydrate: () => void;
  setSession: (params: { user: User; accessToken: string; refreshToken: string }) => void;
  clear: () => void;
}

export const useAuthStore = create<AuthState>((set) => ({
  user: null,
  accessToken: null,
  refreshToken: null,
  isHydrated: false,
  hydrate: () => {
    const accessToken = secureStorage.getString(StorageKey.AccessToken) ?? null;
    const refreshToken = secureStorage.getString(StorageKey.RefreshToken) ?? null;
    set({ accessToken, refreshToken, isHydrated: true });
  },
  setSession: ({ user, accessToken, refreshToken }) => {
    secureStorage.set(StorageKey.AccessToken, accessToken);
    secureStorage.set(StorageKey.RefreshToken, refreshToken);
    set({ user, accessToken, refreshToken });
  },
  clear: () => {
    secureStorage.delete(StorageKey.AccessToken);
    secureStorage.delete(StorageKey.RefreshToken);
    set({ user: null, accessToken: null, refreshToken: null });
  },
}));
