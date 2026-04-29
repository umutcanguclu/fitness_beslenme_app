import type { Match } from '@prisma/client';
import type { Coach } from '@prisma/client';
import { prisma } from '../lib/prisma.js';
import { AppError } from '../lib/errors.js';
import { requireTeamAccess } from '../lib/auth-context.js';

export interface CreateMatchInput {
  teamId: string;
  opponent: string;
  date: Date;
  isHome: boolean;
  competition?: string | null;
  notes?: string | null;
}

export interface UpdateMatchInput {
  opponent?: string;
  date?: Date;
  isHome?: boolean;
  competition?: string | null;
  scoreUs?: number | null;
  scoreThem?: number | null;
  notes?: string | null;
}

export const matchService = {
  async create(coach: Coach, input: CreateMatchInput): Promise<Match> {
    await requireTeamAccess(coach, input.teamId);
    return prisma.match.create({
      data: {
        teamId: input.teamId,
        opponent: input.opponent,
        date: input.date,
        isHome: input.isHome,
        competition: input.competition ?? null,
        notes: input.notes ?? null,
      },
    });
  },

  async listForTeam(coach: Coach, teamId: string): Promise<Match[]> {
    await requireTeamAccess(coach, teamId);
    return prisma.match.findMany({ where: { teamId }, orderBy: { date: 'desc' } });
  },

  async update(coach: Coach, matchId: string, input: UpdateMatchInput): Promise<Match> {
    const match = await prisma.match.findUnique({ where: { id: matchId } });
    if (!match) throw AppError.notFound('Maç bulunamadı');
    await requireTeamAccess(coach, match.teamId);
    return prisma.match.update({
      where: { id: matchId },
      data: {
        opponent: input.opponent,
        date: input.date,
        isHome: input.isHome,
        competition: input.competition,
        scoreUs: input.scoreUs,
        scoreThem: input.scoreThem,
        notes: input.notes,
      },
    });
  },

  async delete(coach: Coach, matchId: string): Promise<void> {
    const match = await prisma.match.findUnique({ where: { id: matchId } });
    if (!match) throw AppError.notFound('Maç bulunamadı');
    await requireTeamAccess(coach, match.teamId);
    await prisma.match.delete({ where: { id: matchId } });
  },
};
