import type { FastifyPluginAsync } from 'fastify';
import { z } from 'zod';
import {
  AttendanceStatusSchema,
  MicrocycleTypeSchema,
} from '@fittrack/shared';
import { authorizePlayerAccess, requireCoach, requirePlayer } from '../lib/auth-context.js';
import { AppError } from '../lib/errors.js';
import { programService } from '../services/program.service.js';

const PlayerIdParamsSchema = z.object({ playerId: z.string().uuid() });
const SessionIdParamsSchema = z.object({ sessionId: z.string().uuid() });

const GenerateProgramBodySchema = z.object({
  weekStartDate: z.coerce.date(),
  microcycleType: MicrocycleTypeSchema.optional(),
});

const ListProgramsQuerySchema = z.object({
  weekStartDate: z.coerce.date().optional(),
  from: z.coerce.date().optional(),
  to: z.coerce.date().optional(),
});

const AttendanceBulkBodySchema = z.object({
  entries: z
    .array(
      z.object({
        playerId: z.string().uuid(),
        status: AttendanceStatusSchema,
        arrivedAt: z.coerce.date().nullable().optional(),
        note: z.string().max(500).nullable().optional(),
      }),
    )
    .min(1)
    .max(100),
});

const SessionLogBodySchema = z.object({
  rpe: z.number().int().min(1).max(10).nullable().optional(),
  fatigue: z.number().int().min(1).max(5).nullable().optional(),
  mood: z.number().int().min(1).max(5).nullable().optional(),
  sleepHours: z.number().min(0).max(24).nullable().optional(),
  notes: z.string().max(2000).nullable().optional(),
});

export const programRoutes: FastifyPluginAsync = async (app) => {
  // POST /players/:playerId/programs/generate — yalnızca koç tetikler.
  app.post(
    '/players/:playerId/programs/generate',
    { preHandler: app.requireAuth },
    async (request, reply) => {
      const { playerId } = PlayerIdParamsSchema.parse(request.params);
      const auth = await authorizePlayerAccess(request.authUser, playerId);
      if (auth.actor !== 'coach') {
        throw AppError.forbidden('Program üretimi koç yetkisi gerektirir');
      }
      const input = GenerateProgramBodySchema.parse(request.body);
      const result = await programService.generateForPlayer({
        playerId,
        weekStartDate: input.weekStartDate,
        microcycleType: input.microcycleType,
      });
      return reply.code(201).send(result);
    },
  );

  // GET /players/:playerId/programs — koç + oyuncu kendisi.
  app.get('/players/:playerId/programs', { preHandler: app.requireAuth }, async (request) => {
    const { playerId } = PlayerIdParamsSchema.parse(request.params);
    await authorizePlayerAccess(request.authUser, playerId);
    const range = ListProgramsQuerySchema.parse(request.query);
    return programService.listForPlayer(playerId, range);
  });

  // POST /sessions/:sessionId/attendance — bulk; koç tüm takım için tek seferde.
  app.post(
    '/sessions/:sessionId/attendance',
    { preHandler: app.requireAuth },
    async (request, reply) => {
      const { sessionId } = SessionIdParamsSchema.parse(request.params);
      const ctx = await requireCoach(request.authUser);
      const session = await programService.getProgramSessionWithProgram(sessionId);
      // Session bireysel bir programa aitse — programın oyuncusu koçun kulübünde mi?
      if (session.program.playerId) {
        const auth = await authorizePlayerAccess(request.authUser, session.program.playerId);
        if (auth.actor !== 'coach') throw AppError.forbidden();
      }
      // Koç token'a sahip olduğu sürece: ileride teamId-bazlı session geldiğinde de
      // burada team erişimi kontrol edilecek (#17 sonrası).
      void ctx;
      const input = AttendanceBulkBodySchema.parse(request.body);
      const result = await programService.setAttendanceBulk(sessionId, input);
      return reply.code(201).send(result);
    },
  );

  app.get('/sessions/:sessionId/attendance', { preHandler: app.requireAuth }, async (request) => {
    const { sessionId } = SessionIdParamsSchema.parse(request.params);
    const session = await programService.getProgramSessionWithProgram(sessionId);
    if (session.program.playerId) {
      await authorizePlayerAccess(request.authUser, session.program.playerId);
    } else {
      await requireCoach(request.authUser);
    }
    return programService.listAttendance(sessionId);
  });

  // POST /sessions/:sessionId/log — sadece oyuncu kendi RPE/fatigue'ünü girer.
  app.post('/sessions/:sessionId/log', { preHandler: app.requireAuth }, async (request, reply) => {
    const { sessionId } = SessionIdParamsSchema.parse(request.params);
    const ctx = await requirePlayer(request.authUser);
    const session = await programService.getProgramSessionWithProgram(sessionId);
    // Oyuncu yalnızca kendi programının seansına log girebilir.
    if (session.program.playerId !== ctx.player.id) {
      throw AppError.forbidden('Bu seans size ait değil');
    }
    const input = SessionLogBodySchema.parse(request.body);
    const result = await programService.upsertSessionLog(sessionId, ctx.player.id, input);
    return reply.code(201).send(result);
  });

  app.get('/sessions/:sessionId/logs', { preHandler: app.requireAuth }, async (request) => {
    const { sessionId } = SessionIdParamsSchema.parse(request.params);
    const session = await programService.getProgramSessionWithProgram(sessionId);
    if (session.program.playerId) {
      await authorizePlayerAccess(request.authUser, session.program.playerId);
    } else {
      await requireCoach(request.authUser);
    }
    return programService.listSessionLogs(sessionId);
  });
};
