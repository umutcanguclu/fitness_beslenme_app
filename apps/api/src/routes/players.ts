import type { FastifyPluginAsync } from 'fastify';
import { z } from 'zod';
import {
  AvailabilityStatusSchema,
  InjurySeveritySchema,
  InjuryTypeSchema,
  UpdatePlayerProfileInputSchema,
} from '@fittrack/shared';
import { authorizePlayerAccess } from '../lib/auth-context.js';
import { AppError } from '../lib/errors.js';
import { playerService } from '../services/player.service.js';

const PlayerIdParamsSchema = z.object({ playerId: z.string().uuid() });
const InjuryParamsSchema = z.object({
  playerId: z.string().uuid(),
  injuryId: z.string().uuid(),
});

const SetAvailabilityBodySchema = z.object({
  date: z.coerce.date(),
  status: AvailabilityStatusSchema,
  note: z.string().max(500).nullable().optional(),
});

const ListAvailabilityQuerySchema = z.object({
  from: z.coerce.date().optional(),
  to: z.coerce.date().optional(),
});

const CreateInjuryBodySchema = z.object({
  type: InjuryTypeSchema,
  severity: InjurySeveritySchema,
  bodyPart: z.string().min(1).max(80),
  startedAt: z.coerce.date(),
  expectedReturn: z.coerce.date().nullable().optional(),
  description: z.string().max(2000).nullable().optional(),
});

const ListInjuriesQuerySchema = z.object({
  includeResolved: z.coerce.boolean().default(false),
});

const ResolveInjuryBodySchema = z.object({
  resolvedAt: z.coerce.date().optional(),
});

export const playerRoutes: FastifyPluginAsync = async (app) => {
  app.get('/players/:playerId', { preHandler: app.requireAuth }, async (request) => {
    const { playerId } = PlayerIdParamsSchema.parse(request.params);
    await authorizePlayerAccess(request.authUser, playerId);
    return playerService.getPlayer(playerId);
  });

  // Profil yalnızca koç tarafından düzenlenir.
  app.patch('/players/:playerId', { preHandler: app.requireAuth }, async (request) => {
    const { playerId } = PlayerIdParamsSchema.parse(request.params);
    const auth = await authorizePlayerAccess(request.authUser, playerId);
    if (auth.actor !== 'coach') throw AppError.forbidden('Profil düzenleme yetkisi koça aittir');
    const input = UpdatePlayerProfileInputSchema.parse(request.body);
    return playerService.updateProfile(playerId, input);
  });

  // Availability: hem oyuncu kendisi hem koç günlük durum girer.
  app.post('/players/:playerId/availability', { preHandler: app.requireAuth }, async (request, reply) => {
    const { playerId } = PlayerIdParamsSchema.parse(request.params);
    await authorizePlayerAccess(request.authUser, playerId);
    const input = SetAvailabilityBodySchema.parse(request.body);
    const result = await playerService.setAvailability(playerId, input);
    return reply.code(201).send(result);
  });

  app.get('/players/:playerId/availability', { preHandler: app.requireAuth }, async (request) => {
    const { playerId } = PlayerIdParamsSchema.parse(request.params);
    await authorizePlayerAccess(request.authUser, playerId);
    const range = ListAvailabilityQuerySchema.parse(request.query);
    return playerService.listAvailability(playerId, range);
  });

  // Injury: yalnızca koç bildirir / kapatır.
  app.post('/players/:playerId/injuries', { preHandler: app.requireAuth }, async (request, reply) => {
    const { playerId } = PlayerIdParamsSchema.parse(request.params);
    const auth = await authorizePlayerAccess(request.authUser, playerId);
    if (auth.actor !== 'coach') throw AppError.forbidden('Sakatlık kaydı koç tarafından girilir');
    const input = CreateInjuryBodySchema.parse(request.body);
    const result = await playerService.createInjury(playerId, input);
    return reply.code(201).send(result);
  });

  app.get('/players/:playerId/injuries', { preHandler: app.requireAuth }, async (request) => {
    const { playerId } = PlayerIdParamsSchema.parse(request.params);
    await authorizePlayerAccess(request.authUser, playerId);
    const { includeResolved } = ListInjuriesQuerySchema.parse(request.query);
    return playerService.listInjuries(playerId, includeResolved);
  });

  app.patch('/players/:playerId/injuries/:injuryId', { preHandler: app.requireAuth }, async (request) => {
    const { playerId, injuryId } = InjuryParamsSchema.parse(request.params);
    const auth = await authorizePlayerAccess(request.authUser, playerId);
    if (auth.actor !== 'coach') throw AppError.forbidden('Sakatlık kapatma koç yetkisi gerektirir');
    const { resolvedAt } = ResolveInjuryBodySchema.parse(request.body ?? {});
    return playerService.resolveInjury(playerId, injuryId, resolvedAt);
  });
};
