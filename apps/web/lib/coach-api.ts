import { api } from './api';

export interface Club {
  id: string;
  name: string;
  city: string | null;
  league: string | null;
  foundedYear: number | null;
  logoUrl: string | null;
}

export interface Team {
  id: string;
  clubId: string;
  name: string;
  category: string;
  season: string;
  active: boolean;
}

export interface Player {
  id: string;
  userId: string | null;
  clubId: string;
  fullName: string;
  birthDate: string;
  position: 'goalkeeper' | 'defender' | 'midfielder' | 'forward';
  detailedPosition: string | null;
  preferredFoot: 'left' | 'right' | 'both';
  heightCm: number;
  weightKg: number;
  jerseyNumber: number | null;
  employmentStatus: string;
  notes: string | null;
}

export interface RosterEntry {
  teamId: string;
  playerId: string;
  isCaptain: boolean;
  player: Player;
}

export interface Invite {
  id: string;
  code: string;
  expiresAt: string;
}

export interface Facility {
  id: string;
  clubId: string;
  type: string;
  name: string;
  notes: string | null;
}

export interface Equipment {
  id: string;
  clubId: string;
  item: string;
  quantity: number;
  notes: string | null;
}

export interface ExerciseSummary {
  id: string;
  slug: string;
  nameTr: string;
  nameEn: string;
  category: string;
  description: string | null;
  requiredEquipment: string[];
  thumbnailUrl: string | null;
  imageUrls: string[];
}

export interface SessionExercise {
  id: string;
  exerciseId: string;
  order: number;
  sets: number | null;
  reps: number | null;
  durationSeconds: number | null;
  distanceMeters: number | null;
  restSeconds: number | null;
  intensity: number | null;
  exercise: ExerciseSummary;
}

export interface SessionLog {
  id: string;
  sessionId: string;
  playerId: string;
  rpe: number | null;
  fatigue: number | null;
  mood: number | null;
  sleepHours: number | null;
  notes: string | null;
  loggedAt: string;
}

export type AttendanceStatus = 'present' | 'absent' | 'late' | 'excused';

export interface TrainingAttendance {
  id: string;
  sessionId: string;
  playerId: string;
  status: AttendanceStatus;
  arrivedAt: string | null;
  note: string | null;
  createdAt: string;
}

export interface TrainingSession {
  id: string;
  date: string;
  type: 'individual' | 'team' | 'position_group' | 'recovery';
  category: string;
  durationMinutes: number;
  intensity: number;
  notes: string | null;
  exercises: SessionExercise[];
  logs: SessionLog[];
  attendance: TrainingAttendance[];
}

export interface ProgramWithSessions {
  id: string;
  playerId: string | null;
  weekStartDate: string;
  matchDayOfWeek: number | null;
  microcycleType: string;
  generatedBy: string;
  notes: string | null;
  sessions: TrainingSession[];
}

export const coachApi = {
  getMyClub: () => api<Club | null>('/clubs/me'),
  createClub: (body: { name: string; city?: string; league?: string }) =>
    api<Club>('/clubs', { method: 'POST', body }),
  updateClub: (clubId: string, body: Partial<Club>) =>
    api<Club>(`/clubs/${clubId}`, { method: 'PATCH', body }),

  listFacilities: (clubId: string) => api<Facility[]>(`/clubs/${clubId}/facilities`),
  addFacility: (clubId: string, body: { type: string; name: string; notes?: string | null }) =>
    api<Facility>(`/clubs/${clubId}/facilities`, { method: 'POST', body }),
  removeFacility: (clubId: string, facilityId: string) =>
    api<void>(`/clubs/${clubId}/facilities/${facilityId}`, { method: 'DELETE' }),

  listEquipment: (clubId: string) => api<Equipment[]>(`/clubs/${clubId}/equipment`),
  upsertEquipment: (
    clubId: string,
    body: { item: string; quantity: number; notes?: string | null },
  ) => api<Equipment>(`/clubs/${clubId}/equipment`, { method: 'POST', body }),
  removeEquipment: (clubId: string, equipmentId: string) =>
    api<void>(`/clubs/${clubId}/equipment/${equipmentId}`, { method: 'DELETE' }),

  listTeams: (includeInactive = false) =>
    api<Team[]>(`/teams${includeInactive ? '?includeInactive=true' : ''}`),
  createTeam: (body: { name: string; category: string; season: string }) =>
    api<Team>('/teams', { method: 'POST', body }),
  getTeam: (teamId: string) => api<Team>(`/teams/${teamId}`),
  updateTeam: (teamId: string, body: Partial<Team>) =>
    api<Team>(`/teams/${teamId}`, { method: 'PATCH', body }),
  deleteTeam: (teamId: string) => api<void>(`/teams/${teamId}`, { method: 'DELETE' }),
  listRoster: (teamId: string) => api<RosterEntry[]>(`/teams/${teamId}/players`),
  createPlayer: (
    teamId: string,
    body: {
      fullName: string;
      birthDate: string;
      position: string;
      detailedPosition?: string | null;
      preferredFoot: 'left' | 'right' | 'both';
      heightCm: number;
      weightKg: number;
      jerseyNumber?: number | null;
      employmentStatus: string;
      email?: string;
    },
  ) => api<{ player: Player; invite: Invite }>(`/teams/${teamId}/players`, { method: 'POST', body }),
  removeFromRoster: (teamId: string, playerId: string) =>
    api<void>(`/teams/${teamId}/players/${playerId}`, { method: 'DELETE' }),

  getPlayer: (playerId: string) => api<Player>(`/players/${playerId}`),
  updatePlayer: (playerId: string, body: Partial<Player>) =>
    api<Player>(`/players/${playerId}`, { method: 'PATCH', body }),

  listPrograms: (playerId: string, weekStartDate?: string) =>
    api<ProgramWithSessions[]>(
      `/players/${playerId}/programs${weekStartDate ? `?weekStartDate=${weekStartDate}` : ''}`,
    ),
  generateProgram: (
    playerId: string,
    body: { weekStartDate: string; microcycleType?: string },
  ) =>
    api<ProgramWithSessions>(`/players/${playerId}/programs/generate`, {
      method: 'POST',
      body,
    }),

  // Tek bir oyuncu için bulk-attendance endpoint'ini single-entry olarak kullanır.
  setAttendance: (
    sessionId: string,
    playerId: string,
    status: AttendanceStatus,
    note?: string | null,
  ) =>
    api<TrainingAttendance[]>(`/sessions/${sessionId}/attendance`, {
      method: 'POST',
      body: { entries: [{ playerId, status, note: note ?? null }] },
    }),
};
