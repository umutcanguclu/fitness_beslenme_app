import type { FastifyPluginAsync } from 'fastify';
import { z } from 'zod';
import {
  ClubCreateInputSchema,
  EquipmentItemSchema,
  FacilityTypeSchema,
} from '@fittrack/shared';
import { AppError } from '../lib/errors.js';
import { requireCoach } from '../lib/auth-context.js';
import { clubService } from '../services/club.service.js';

const UpdateClubInputSchema = ClubCreateInputSchema.partial();

const AddFacilityInputSchema = z.object({
  type: FacilityTypeSchema,
  name: z.string().min(1).max(80),
  notes: z.string().max(500).nullable().optional(),
});

const UpsertEquipmentInputSchema = z.object({
  item: EquipmentItemSchema,
  quantity: z.number().int().min(0).max(999),
  notes: z.string().max(200).nullable().optional(),
});

const ClubIdParamsSchema = z.object({ clubId: z.string().uuid() });
const FacilityParamsSchema = z.object({
  clubId: z.string().uuid(),
  facilityId: z.string().uuid(),
});
const EquipmentParamsSchema = z.object({
  clubId: z.string().uuid(),
  equipmentId: z.string().uuid(),
});

export const clubRoutes: FastifyPluginAsync = async (app) => {
  app.post('/clubs', { preHandler: app.requireAuth }, async (request, reply) => {
    const ctx = await requireCoach(request.authUser);
    const input = ClubCreateInputSchema.parse(request.body);
    const club = await clubService.createClubForCoach(ctx.coach, input);
    return reply.code(201).send(club);
  });

  // Kulübü yoksa 200 + null döner — UI "henüz kulüp yok → wizard göster"
  // akışını tek bir code path ile yönetebilsin diye.
  app.get('/clubs/me', { preHandler: app.requireAuth }, async (request) => {
    const ctx = await requireCoach(request.authUser);
    return clubService.getMyClub(ctx.coach);
  });

  app.patch('/clubs/:clubId', { preHandler: app.requireAuth }, async (request) => {
    const ctx = await requireCoach(request.authUser);
    const { clubId } = ClubIdParamsSchema.parse(request.params);
    const input = UpdateClubInputSchema.parse(request.body);
    return clubService.updateClub(ctx.coach, clubId, input);
  });

  app.get('/clubs/:clubId/facilities', { preHandler: app.requireAuth }, async (request) => {
    const ctx = await requireCoach(request.authUser);
    const { clubId } = ClubIdParamsSchema.parse(request.params);
    return clubService.listFacilities(ctx.coach, clubId);
  });

  app.post('/clubs/:clubId/facilities', { preHandler: app.requireAuth }, async (request, reply) => {
    const ctx = await requireCoach(request.authUser);
    const { clubId } = ClubIdParamsSchema.parse(request.params);
    const input = AddFacilityInputSchema.parse(request.body);
    const facility = await clubService.addFacility(ctx.coach, clubId, input);
    return reply.code(201).send(facility);
  });

  app.delete('/clubs/:clubId/facilities/:facilityId', { preHandler: app.requireAuth }, async (request, reply) => {
    const ctx = await requireCoach(request.authUser);
    const { clubId, facilityId } = FacilityParamsSchema.parse(request.params);
    await clubService.removeFacility(ctx.coach, clubId, facilityId);
    return reply.code(204).send();
  });

  app.get('/clubs/:clubId/equipment', { preHandler: app.requireAuth }, async (request) => {
    const ctx = await requireCoach(request.authUser);
    const { clubId } = ClubIdParamsSchema.parse(request.params);
    return clubService.listEquipment(ctx.coach, clubId);
  });

  app.post('/clubs/:clubId/equipment', { preHandler: app.requireAuth }, async (request, reply) => {
    const ctx = await requireCoach(request.authUser);
    const { clubId } = ClubIdParamsSchema.parse(request.params);
    const input = UpsertEquipmentInputSchema.parse(request.body);
    const equipment = await clubService.upsertEquipment(ctx.coach, clubId, input);
    return reply.code(201).send(equipment);
  });

  app.delete('/clubs/:clubId/equipment/:equipmentId', { preHandler: app.requireAuth }, async (request, reply) => {
    const ctx = await requireCoach(request.authUser);
    const { clubId, equipmentId } = EquipmentParamsSchema.parse(request.params);
    await clubService.removeEquipment(ctx.coach, clubId, equipmentId);
    return reply.code(204).send();
  });
};
