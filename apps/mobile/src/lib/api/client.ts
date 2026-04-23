import Constants from 'expo-constants';
import { secureStorage, StorageKey } from '../storage';

const DEFAULT_BASE_URL = 'http://localhost:3000';

function resolveBaseUrl(): string {
  const fromEnv = process.env.EXPO_PUBLIC_API_URL;
  if (fromEnv && fromEnv.length > 0) return fromEnv;
  const extra = (Constants.expoConfig?.extra ?? {}) as { apiUrl?: string };
  return extra.apiUrl ?? DEFAULT_BASE_URL;
}

export const API_BASE_URL = resolveBaseUrl();

export class ApiError extends Error {
  readonly status: number;
  readonly code: string;
  readonly details?: unknown;

  constructor(status: number, code: string, message: string, details?: unknown) {
    super(message);
    this.name = 'ApiError';
    this.status = status;
    this.code = code;
    this.details = details;
  }
}

type RequestOptions = RequestInit & { auth?: boolean };

export async function apiFetch<T>(path: string, options: RequestOptions = {}): Promise<T> {
  const { auth = true, headers, ...rest } = options;

  const finalHeaders = new Headers(headers);
  if (!finalHeaders.has('Content-Type') && rest.body) {
    finalHeaders.set('Content-Type', 'application/json');
  }
  if (auth) {
    const token = secureStorage.getString(StorageKey.AccessToken);
    if (token) finalHeaders.set('Authorization', `Bearer ${token}`);
  }

  const response = await fetch(`${API_BASE_URL}${path}`, {
    ...rest,
    headers: finalHeaders,
  });

  if (response.status === 204) {
    return undefined as T;
  }

  const text = await response.text();
  const data = text.length > 0 ? (JSON.parse(text) as unknown) : undefined;

  if (!response.ok) {
    const errBody = data as { error?: { code?: string; message?: string; details?: unknown } };
    throw new ApiError(
      response.status,
      errBody?.error?.code ?? 'UNKNOWN',
      errBody?.error?.message ?? response.statusText,
      errBody?.error?.details,
    );
  }

  return data as T;
}
