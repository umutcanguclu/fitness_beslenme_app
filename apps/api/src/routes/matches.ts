import type { FastifyPluginAsync } from 'fastify';
import { z } from 'zod';
import { requireCoach } from '../lib/auth-context.js';
import { matchService } from '../services/match.service.js';

const TeamIdParamsSchema = z.object({ teamId: z.string().uuid() });
const MatchIdParamsSchema = z.object({ matchId: z.string().uuid() });

const CreateMatchBodySchema = z.object({
  opponent: z.string().min(1).max(120),
  date: z.coerce.date(),
  isHome: z.boolean(),
  competition: z.string().max(80).nullable().optional(),
  notes: z.string().max(2000).nullable().optional(),
});

const UpdateMatchBodySchema = z.object({
  opponent: z.string().min(1).max(120).optional(),
  date: z.coerce.date().optional(),
  isHome: z.boolean().optional(),
  competition: z.string().max(80).nullable().optional(),
  scoreUs: z.number().int().min(0).max(99).nullable().optional(),
  scoreThem: z.number().int().min(0).max(99).nullable().optional(),
  notes: z.string().max(2000).nullable().optional(),
});

export const matchRoutes: FastifyPluginAsync = async (app) => {
  app.post('/teams/:teamId/matches', { preHandler: app.requireAuth }, async (request, reply) => {
    const ctx = await requireCoach(request.authUser);
    const { teamId } = TeamIdParamsSchema.parse(request.params);
    const input = CreateMatchBodySchema.parse(request.body);
    const match = await matchService.create(ctx.coach, { teamId, ...input });
    return reply.code(201).send(match);
  });

  app.get('/teams/:teamId/matches', { preHandler: app.requireAuth }, async (request) => {
    const ctx = await requireCoach(request.authUser);
    const { teamId } = TeamIdParamsSchema.parse(request.params);
    return matchService.listForTeam(ctx.coach, teamId);
  });

  app.patch('/matches/:matchId', { preHandler: app.requireAuth }, async (request) => {
    const ctx = await requireCoach(request.authUser);
    const { matchId } = MatchIdParamsSchema.parse(request.params);
    const input = UpdateMatchBodySchema.parse(request.body);
    return matchService.update(ctx.coach, matchId, input);
  });

  app.delete('/matches/:matchId', { preHandler: app.requireAuth }, async (request, reply) => {
    const ctx = await requireCoach(request.authUser);
    const { matchId } = MatchIdParamsSchema.parse(request.params);
    await matchService.delete(ctx.coach, matchId);
    return reply.code(204).send();
  });
};
