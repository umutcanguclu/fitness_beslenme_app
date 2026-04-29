import type { Club, Coach, Equipment, Facility } from '@prisma/client';
import type {
  ClubCreateInput,
  EquipmentItem,
  FacilityType,
} from '@fittrack/shared';
import { prisma } from '../lib/prisma.js';
import { AppError } from '../lib/errors.js';
import { requireClubAdmin, requireClubMember } from '../lib/auth-context.js';

export interface UpdateClubInput {
  name?: string;
  city?: string | null;
  league?: string | null;
  foundedYear?: number | null;
  logoUrl?: string | null;
}

export interface AddFacilityInput {
  type: FacilityType;
  name: string;
  notes?: string | null;
}

export interface UpsertEquipmentInput {
  item: EquipmentItem;
  quantity: number;
  notes?: string | null;
}

export const clubService = {
  async createClubForCoach(coach: Coach, input: ClubCreateInput): Promise<Club> {
    if (coach.clubId) {
      throw AppError.conflict('Zaten bir kulübe bağlısınız');
    }
    return prisma.$transaction(async (tx) => {
      const club = await tx.club.create({ data: input });
      await tx.coach.update({
        where: { userId: coach.userId },
        data: { clubId: club.id, isClubAdmin: true },
      });
      return club;
    });
  },

  async getMyClub(coach: Coach): Promise<Club | null> {
    if (!coach.clubId) return null;
    return prisma.club.findUnique({ where: { id: coach.clubId } });
  },

  async updateClub(coach: Coach, clubId: string, input: UpdateClubInput): Promise<Club> {
    requireClubAdmin(coach, clubId);
    return prisma.club.update({ where: { id: clubId }, data: input });
  },

  async listFacilities(coach: Coach, clubId: string): Promise<Facility[]> {
    requireClubMember(coach, clubId);
    return prisma.facility.findMany({ where: { clubId }, orderBy: { type: 'asc' } });
  },

  async addFacility(coach: Coach, clubId: string, input: AddFacilityInput): Promise<Facility> {
    requireClubAdmin(coach, clubId);
    return prisma.facility.create({ data: { ...input, clubId } });
  },

  async removeFacility(coach: Coach, clubId: string, facilityId: string): Promise<void> {
    requireClubAdmin(coach, clubId);
    const facility = await prisma.facility.findUnique({ where: { id: facilityId } });
    if (!facility || facility.clubId !== clubId) throw AppError.notFound('Tesis bulunamadı');
    await prisma.facility.delete({ where: { id: facilityId } });
  },

  async listEquipment(coach: Coach, clubId: string): Promise<Equipment[]> {
    requireClubMember(coach, clubId);
    return prisma.equipment.findMany({ where: { clubId }, orderBy: { item: 'asc' } });
  },

  // Aynı item için unique constraint var; coach miktarı güncellemek isterse upsert mantıklı.
  async upsertEquipment(coach: Coach, clubId: string, input: UpsertEquipmentInput): Promise<Equipment> {
    requireClubAdmin(coach, clubId);
    return prisma.equipment.upsert({
      where: { clubId_item: { clubId, item: input.item } },
      create: { clubId, item: input.item, quantity: input.quantity, notes: input.notes ?? null },
      update: { quantity: input.quantity, notes: input.notes ?? null },
    });
  },

  async removeEquipment(coach: Coach, clubId: string, equipmentId: string): Promise<void> {
    requireClubAdmin(coach, clubId);
    const equipment = await prisma.equipment.findUnique({ where: { id: equipmentId } });
    if (!equipment || equipment.clubId !== clubId) throw AppError.notFound('Ekipman bulunamadı');
    await prisma.equipment.delete({ where: { id: equipmentId } });
  },
};
