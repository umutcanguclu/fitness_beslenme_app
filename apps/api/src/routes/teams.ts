import type { FastifyPluginAsync } from 'fastify';
import { z } from 'zod';
import {
  CreatePlayerProfileInputSchema,
  TeamCategorySchema,
} from '@fittrack/shared';
import { requireCoach } from '../lib/auth-context.js';
import { teamService } from '../services/team.service.js';

const CreateTeamInputSchema = z.object({
  name: z.string().min(1).max(120),
  category: TeamCategorySchema,
  season: z.string().min(1).max(20),
});

const UpdateTeamInputSchema = CreateTeamInputSchema.partial().extend({
  active: z.boolean().optional(),
});

const TeamIdParamsSchema = z.object({ teamId: z.string().uuid() });
const TeamPlayerParamsSchema = z.object({
  teamId: z.string().uuid(),
  playerId: z.string().uuid(),
});

export const teamRoutes: FastifyPluginAsync = async (app) => {
  app.get('/teams', { preHandler: app.requireAuth }, async (request) => {
    const ctx = await requireCoach(request.authUser);
    const { includeInactive } = z
      .object({ includeInactive: z.coerce.boolean().default(false) })
      .parse(request.query);
    return teamService.listMyTeams(ctx.coach, includeInactive);
  });

  app.post('/teams', { preHandler: app.requireAuth }, async (request, reply) => {
    const ctx = await requireCoach(request.authUser);
    const input = CreateTeamInputSchema.parse(request.body);
    const team = await teamService.createTeam(ctx.coach, input);
    return reply.code(201).send(team);
  });

  app.get('/teams/:teamId', { preHandler: app.requireAuth }, async (request) => {
    const ctx = await requireCoach(request.authUser);
    const { teamId } = TeamIdParamsSchema.parse(request.params);
    return teamService.getTeam(ctx.coach, teamId);
  });

  app.patch('/teams/:teamId', { preHandler: app.requireAuth }, async (request) => {
    const ctx = await requireCoach(request.authUser);
    const { teamId } = TeamIdParamsSchema.parse(request.params);
    const input = UpdateTeamInputSchema.parse(request.body);
    return teamService.updateTeam(ctx.coach, teamId, input);
  });

  app.delete('/teams/:teamId', { preHandler: app.requireAuth }, async (request, reply) => {
    const ctx = await requireCoach(request.authUser);
    const { teamId } = TeamIdParamsSchema.parse(request.params);
    await teamService.deleteTeam(ctx.coach, teamId);
    return reply.code(204).send();
  });

  app.get('/teams/:teamId/players', { preHandler: app.requireAuth }, async (request) => {
    const ctx = await requireCoach(request.authUser);
    const { teamId } = TeamIdParamsSchema.parse(request.params);
    return teamService.listRoster(ctx.coach, teamId);
  });

  // Yeni player profili oluştur + invite üret. teamId path'ten gelir; body'deki teamId ile uyumlu olmalı.
  app.post('/teams/:teamId/players', { preHandler: app.requireAuth }, async (request, reply) => {
    const ctx = await requireCoach(request.authUser);
    const { teamId } = TeamIdParamsSchema.parse(request.params);
    const input = CreatePlayerProfileInputSchema.parse({ ...(request.body as object), teamId });
    const result = await teamService.createPlayerProfile(ctx.coach, input);
    return reply.code(201).send(result);
  });

  // Mevcut player'ı takıma ata (örn. U17 oyuncusunu A takımı kadrosuna almak).
  app.post('/teams/:teamId/players/:playerId', { preHandler: app.requireAuth }, async (request, reply) => {
    const ctx = await requireCoach(request.authUser);
    const { teamId, playerId } = TeamPlayerParamsSchema.parse(request.params);
    const tp = await teamService.assignExistingPlayer(ctx.coach, teamId, playerId);
    return reply.code(201).send(tp);
  });

  app.delete('/teams/:teamId/players/:playerId', { preHandler: app.requireAuth }, async (request, reply) => {
    const ctx = await requireCoach(request.authUser);
    const { teamId, playerId } = TeamPlayerParamsSchema.parse(request.params);
    await teamService.removeFromRoster(ctx.coach, teamId, playerId);
    return reply.code(204).send();
  });
};
