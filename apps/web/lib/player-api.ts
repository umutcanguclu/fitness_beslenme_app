import { api } from './api';
import type { SessionLog } from './coach-api';

export interface MePlayerResponse {
  playerId: string | null;
  player: {
    id: string;
    clubId: string;
    fullName: string;
    position: string;
    jerseyNumber: number | null;
  } | null;
}

export interface SessionLogInput {
  rpe?: number | null;
  fatigue?: number | null;
  mood?: number | null;
  sleepHours?: number | null;
  notes?: string | null;
}

export const playerApi = {
  getMe: () => api<MePlayerResponse>('/auth/me/player'),
  logSession: (sessionId: string, body: SessionLogInput) =>
    api<SessionLog>(`/sessions/${sessionId}/log`, { method: 'POST', body }),
};
