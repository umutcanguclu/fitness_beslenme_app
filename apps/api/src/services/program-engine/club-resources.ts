import type { PrismaClient } from '@prisma/client';
import type { EquipmentItem, ExerciseLocation, FacilityType } from '@fittrack/shared';
import { prisma } from '../../lib/prisma.js';
import type { ClubResources } from './types.js';

// Tesis tipini engine'in egzersiz seçiminde kullandığı lokasyon kümesine çevirir.
const FACILITY_TO_LOCATIONS: Record<FacilityType, ExerciseLocation[]> = {
  natural_grass: ['field'],
  artificial_turf: ['field'],
  indoor_pitch: ['indoor_pitch'],
  gym: ['gym'],
  weight_room: ['gym'],
  sprint_track: ['field'],
  pool: ['pool'],
  recovery_room: ['home'], // recovery odası = ekipmansız hafif rutinler için uygun
};

export async function loadClubResources(
  clubId: string,
  db: PrismaClient = prisma,
): Promise<ClubResources> {
  const [equipmentRows, facilityRows] = await Promise.all([
    db.equipment.findMany({ where: { clubId } }),
    db.facility.findMany({ where: { clubId } }),
  ]);

  const equipment = new Set<EquipmentItem>(equipmentRows.map((e) => e.item));
  const facilities = new Set<FacilityType>(facilityRows.map((f) => f.type));

  // 'bodyweight_anywhere' ve 'home' her zaman uygundur (oyuncu evde de yapabilir).
  const availableLocations = new Set<ExerciseLocation>([
    'bodyweight_anywhere',
    'home',
  ]);
  for (const fac of facilities) {
    for (const loc of FACILITY_TO_LOCATIONS[fac]) {
      availableLocations.add(loc);
    }
  }

  return { clubId, equipment, facilities, availableLocations };
}
