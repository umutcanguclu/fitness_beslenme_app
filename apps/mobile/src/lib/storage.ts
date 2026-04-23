import { MMKV } from 'react-native-mmkv';

export const storage = new MMKV({ id: 'fittrack.default' });

export const secureStorage = new MMKV({
  id: 'fittrack.secure',
  encryptionKey: 'fittrack-dev-key-replace-for-prod',
});

export const StorageKey = {
  AccessToken: 'auth.accessToken',
  RefreshToken: 'auth.refreshToken',
  UserLocale: 'settings.locale',
  UserTheme: 'settings.theme',
} as const;
