import type { Coach, Invite, Player, Team, TeamPlayer } from '@prisma/client';
import type {
  CreatePlayerProfileInput,
  TeamCategory,
  UpdatePlayerProfileInput,
} from '@fittrack/shared';
import { prisma } from '../lib/prisma.js';
import { AppError } from '../lib/errors.js';
import {
  requireClubAdmin,
  requireClubMember,
  requireTeamAccess,
} from '../lib/auth-context.js';
import { generateInviteCode } from '../lib/invite-code.js';

export interface CreateTeamInput {
  name: string;
  category: TeamCategory;
  season: string;
}

export interface UpdateTeamInput {
  name?: string;
  category?: TeamCategory;
  season?: string;
  active?: boolean;
}

export interface CreatePlayerResult {
  player: Player;
  teamPlayer: TeamPlayer;
  invite: Invite;
}

const INVITE_DEFAULT_EXPIRES_DAYS = 14;
const INVITE_MAX_RETRIES = 5;

export const teamService = {
  async listMyTeams(coach: Coach, includeInactive = false): Promise<Team[]> {
    if (!coach.clubId) return [];
    const baseWhere = includeInactive ? {} : { active: true };
    if (coach.isClubAdmin) {
      return prisma.team.findMany({
        where: { clubId: coach.clubId, ...baseWhere },
        orderBy: [{ active: 'desc' }, { season: 'desc' }, { name: 'asc' }],
      });
    }
    return prisma.team.findMany({
      where: {
        clubId: coach.clubId,
        coaches: { some: { coachId: coach.userId } },
        ...baseWhere,
      },
      orderBy: [{ active: 'desc' }, { season: 'desc' }, { name: 'asc' }],
    });
  },

  async createTeam(coach: Coach, input: CreateTeamInput): Promise<Team> {
    if (!coach.clubId) {
      throw AppError.conflict('Önce bir kulüp oluşturmalısınız');
    }
    requireClubAdmin(coach, coach.clubId);
    return prisma.$transaction(async (tx) => {
      const team = await tx.team.create({ data: { ...input, clubId: coach.clubId! } });
      // Kuran admin baş antrenör olarak otomatik atanır.
      await tx.coachTeam.create({
        data: { coachId: coach.userId, teamId: team.id, role: 'head_coach' },
      });
      return team;
    });
  },

  async getTeam(coach: Coach, teamId: string): Promise<Team> {
    await requireTeamAccess(coach, teamId);
    const team = await prisma.team.findUnique({ where: { id: teamId } });
    if (!team) throw AppError.notFound('Takım bulunamadı');
    return team;
  },

  async updateTeam(coach: Coach, teamId: string, input: UpdateTeamInput): Promise<Team> {
    const team = await requireTeamAccess(coach, teamId);
    requireClubAdmin(coach, team.clubId);
    return prisma.team.update({ where: { id: teamId }, data: input });
  },

  async deleteTeam(coach: Coach, teamId: string): Promise<void> {
    const team = await requireTeamAccess(coach, teamId);
    requireClubAdmin(coach, team.clubId);
    await prisma.team.delete({ where: { id: teamId } });
  },

  async listRoster(
    coach: Coach,
    teamId: string,
  ): Promise<Array<TeamPlayer & { player: Player }>> {
    await requireTeamAccess(coach, teamId);
    return prisma.teamPlayer.findMany({
      where: { teamId, leftAt: null },
      include: { player: true },
      orderBy: [{ player: { fullName: 'asc' } }],
    });
  },

  async createPlayerProfile(
    coach: Coach,
    input: CreatePlayerProfileInput,
  ): Promise<CreatePlayerResult> {
    const team = await requireTeamAccess(coach, input.teamId);
    requireClubMember(coach, team.clubId);

    return prisma.$transaction(async (tx) => {
      const player = await tx.player.create({
        data: {
          clubId: team.clubId,
          createdById: coach.userId,
          fullName: input.fullName,
          birthDate: input.birthDate,
          position: input.position,
          detailedPosition: input.detailedPosition ?? null,
          secondaryPosition: input.secondaryPosition ?? null,
          preferredFoot: input.preferredFoot,
          heightCm: input.heightCm,
          weightKg: input.weightKg,
          jerseyNumber: input.jerseyNumber ?? null,
          employmentStatus: input.employmentStatus,
          notes: input.notes ?? null,
        },
      });

      const teamPlayer = await tx.teamPlayer.create({
        data: { teamId: team.id, playerId: player.id },
      });

      const invite = await createInviteWithRetry(tx, {
        invitedById: coach.userId,
        clubId: team.clubId,
        teamId: team.id,
        playerId: player.id,
        email: input.email ?? null,
        expiresInDays: INVITE_DEFAULT_EXPIRES_DAYS,
      });

      return { player, teamPlayer, invite };
    });
  },

  async assignExistingPlayer(
    coach: Coach,
    teamId: string,
    playerId: string,
  ): Promise<TeamPlayer> {
    const team = await requireTeamAccess(coach, teamId);
    const player = await prisma.player.findUnique({ where: { id: playerId } });
    if (!player) throw AppError.notFound('Oyuncu bulunamadı');
    if (player.clubId !== team.clubId) {
      throw AppError.forbidden('Oyuncu bu kulübe ait değil');
    }
    return prisma.teamPlayer.upsert({
      where: { teamId_playerId: { teamId, playerId } },
      create: { teamId, playerId },
      update: { leftAt: null },
    });
  },

  async removeFromRoster(coach: Coach, teamId: string, playerId: string): Promise<void> {
    await requireTeamAccess(coach, teamId);
    const membership = await prisma.teamPlayer.findUnique({
      where: { teamId_playerId: { teamId, playerId } },
    });
    if (!membership) throw AppError.notFound('Oyuncu bu takımda değil');
    await prisma.teamPlayer.update({
      where: { teamId_playerId: { teamId, playerId } },
      data: { leftAt: new Date() },
    });
  },

  async updatePlayer(
    coach: Coach,
    playerId: string,
    input: UpdatePlayerProfileInput,
  ): Promise<Player> {
    const player = await prisma.player.findUnique({ where: { id: playerId } });
    if (!player) throw AppError.notFound('Oyuncu bulunamadı');
    requireClubMember(coach, player.clubId);
    return prisma.player.update({
      where: { id: playerId },
      data: {
        birthDate: input.birthDate,
        position: input.position,
        detailedPosition: input.detailedPosition ?? undefined,
        secondaryPosition: input.secondaryPosition ?? undefined,
        preferredFoot: input.preferredFoot,
        heightCm: input.heightCm,
        weightKg: input.weightKg,
        jerseyNumber: input.jerseyNumber ?? undefined,
        employmentStatus: input.employmentStatus,
        notes: input.notes ?? undefined,
      },
    });
  },
};

interface InviteCreateData {
  invitedById: string;
  clubId: string;
  teamId: string | null;
  playerId: string | null;
  email: string | null;
  expiresInDays: number;
}

// Code unique constraint çakışırsa birkaç kez yeniden dene.
async function createInviteWithRetry(
  tx: Pick<typeof prisma, 'invite'>,
  data: InviteCreateData,
): Promise<Invite> {
  const expiresAt = new Date();
  expiresAt.setDate(expiresAt.getDate() + data.expiresInDays);
  for (let attempt = 0; attempt < INVITE_MAX_RETRIES; attempt += 1) {
    try {
      return await tx.invite.create({
        data: {
          code: generateInviteCode(8),
          invitedById: data.invitedById,
          clubId: data.clubId,
          teamId: data.teamId,
          playerId: data.playerId,
          email: data.email,
          expiresAt,
        },
      });
    } catch (err) {
      const e = err as { code?: string };
      if (e?.code === 'P2002' && attempt < INVITE_MAX_RETRIES - 1) continue;
      throw err;
    }
  }
  throw AppError.internal('Davet kodu üretilemedi (çakışma)');
}
