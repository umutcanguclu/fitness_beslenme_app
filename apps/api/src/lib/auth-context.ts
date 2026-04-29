import type { Coach, Player, User } from '@prisma/client';
import { prisma } from './prisma.js';
import { AppError } from './errors.js';
import type { AccessTokenPayload } from './tokens.js';

export interface CoachContext {
  user: User;
  coach: Coach;
}

export interface PlayerContext {
  user: User;
  player: Player;
}

export async function requireCoach(authUser: AccessTokenPayload | undefined): Promise<CoachContext> {
  if (!authUser) throw AppError.unauthorized();
  const user = await prisma.user.findUnique({
    where: { id: authUser.sub },
    include: { coach: true },
  });
  if (!user || user.role !== 'coach' || !user.coach) {
    throw AppError.forbidden('Bu işlem antrenör hesabı gerektirir');
  }
  return { user, coach: user.coach };
}

export async function requirePlayer(authUser: AccessTokenPayload | undefined): Promise<PlayerContext> {
  if (!authUser) throw AppError.unauthorized();
  const user = await prisma.user.findUnique({
    where: { id: authUser.sub },
    include: { playerProfile: true },
  });
  if (!user || user.role !== 'player' || !user.playerProfile) {
    throw AppError.forbidden('Bu işlem oyuncu hesabı gerektirir');
  }
  return { user, player: user.playerProfile };
}

export function requireClubMember(coach: Coach, clubId: string): void {
  if (coach.clubId !== clubId) {
    throw AppError.forbidden('Bu kulübe erişim yetkiniz yok');
  }
}

export function requireClubAdmin(coach: Coach, clubId: string): void {
  requireClubMember(coach, clubId);
  if (!coach.isClubAdmin) {
    throw AppError.forbidden('Bu işlem kulüp yöneticisi yetkisi gerektirir');
  }
}

// Player'a erişim: oyuncunun kendisi VEYA aynı kulüpte bir antrenör.
// Hangi role olduğunu döner ki endpoint write işlemlerini ona göre kısıtlasın.
export async function authorizePlayerAccess(
  authUser: AccessTokenPayload | undefined,
  playerId: string,
): Promise<{
  player: { id: string; userId: string | null; clubId: string };
  actor: 'self' | 'coach';
  coach?: Coach;
}> {
  if (!authUser) throw AppError.unauthorized();
  const player = await prisma.player.findUnique({
    where: { id: playerId },
    select: { id: true, userId: true, clubId: true },
  });
  if (!player) throw AppError.notFound('Oyuncu bulunamadı');
  const user = await prisma.user.findUnique({
    where: { id: authUser.sub },
    include: { coach: true, playerProfile: { select: { id: true } } },
  });
  if (!user) throw AppError.unauthorized();
  if (user.role === 'player' && user.playerProfile?.id === playerId) {
    return { player, actor: 'self' };
  }
  if (user.role === 'coach' && user.coach && user.coach.clubId === player.clubId) {
    return { player, actor: 'coach', coach: user.coach };
  }
  throw AppError.forbidden('Bu oyuncuya erişim yetkiniz yok');
}

// Coach takıma yalnızca kulüp admin'iyse veya CoachTeam pivotunda atanmışsa erişebilir.
// Takımı döner; hata fırlatır eğer yetki yoksa.
export async function requireTeamAccess(
  coach: Coach,
  teamId: string,
): Promise<{ id: string; clubId: string }> {
  const team = await prisma.team.findUnique({
    where: { id: teamId },
    select: { id: true, clubId: true },
  });
  if (!team) throw AppError.notFound('Takım bulunamadı');
  requireClubMember(coach, team.clubId);
  if (coach.isClubAdmin) return team;
  const membership = await prisma.coachTeam.findUnique({
    where: { coachId_teamId: { coachId: coach.userId, teamId } },
  });
  if (!membership) throw AppError.forbidden('Bu takıma erişim yetkiniz yok');
  return team;
}
