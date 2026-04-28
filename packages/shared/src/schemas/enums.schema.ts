import { z } from 'zod';

// Tüm enum değerleri Prisma şemasıyla 1-1 senkron tutulmalı.

export const TeamCategorySchema = z.enum([
  'u13',
  'u14',
  'u15',
  'u16',
  'u17',
  'u18',
  'u19',
  'u21',
  'senior',
  'amateur',
  'veteran',
]);
export type TeamCategory = z.infer<typeof TeamCategorySchema>;

export const PositionGroupSchema = z.enum(['goalkeeper', 'defender', 'midfielder', 'forward']);
export type PositionGroup = z.infer<typeof PositionGroupSchema>;

export const DetailedPositionSchema = z.enum([
  'GK',
  'CB',
  'LB',
  'RB',
  'LWB',
  'RWB',
  'CDM',
  'CM',
  'CAM',
  'LM',
  'RM',
  'LW',
  'RW',
  'ST',
  'CF',
  'SS',
]);
export type DetailedPosition = z.infer<typeof DetailedPositionSchema>;

export const FootSchema = z.enum(['left', 'right', 'both']);
export type Foot = z.infer<typeof FootSchema>;

export const EmploymentStatusSchema = z.enum([
  'full_time_pro',
  'semi_pro',
  'amateur',
  'student',
  'working',
]);
export type EmploymentStatus = z.infer<typeof EmploymentStatusSchema>;

export const LicenseLevelSchema = z.enum([
  'none',
  'tff_grassroots',
  'tff_d',
  'tff_c',
  'tff_b',
  'tff_a',
  'uefa_c',
  'uefa_b',
  'uefa_a',
  'uefa_pro',
]);
export type LicenseLevel = z.infer<typeof LicenseLevelSchema>;

export const AvailabilityStatusSchema = z.enum([
  'ready',
  'doubtful',
  'limited',
  'injured',
  'ill',
  'suspended',
  'away',
]);
export type AvailabilityStatus = z.infer<typeof AvailabilityStatusSchema>;

export const InjurySeveritySchema = z.enum(['minor', 'moderate', 'major', 'severe']);
export type InjurySeverity = z.infer<typeof InjurySeveritySchema>;

export const InjuryTypeSchema = z.enum([
  'muscle',
  'ligament',
  'joint',
  'bone',
  'tendon',
  'concussion',
  'other',
]);
export type InjuryType = z.infer<typeof InjuryTypeSchema>;

export const TrainingCategorySchema = z.enum([
  'endurance',
  'sprint_agility',
  'strength',
  'plyometric',
  'technical',
  'tactical',
  'goalkeeper_specific',
  'recovery',
  'warmup',
  'cooldown',
  'small_sided_game',
  'set_piece',
]);
export type TrainingCategory = z.infer<typeof TrainingCategorySchema>;

export const ExerciseLocationSchema = z.enum([
  'field',
  'indoor_pitch',
  'gym',
  'bodyweight_anywhere',
  'pool',
  'home',
]);
export type ExerciseLocation = z.infer<typeof ExerciseLocationSchema>;

export const MicrocycleTypeSchema = z.enum([
  'match_week',
  'preseason',
  'recovery_week',
  'off_season',
]);
export type MicrocycleType = z.infer<typeof MicrocycleTypeSchema>;

export const SessionTypeSchema = z.enum([
  'team',
  'individual',
  'position_group',
  'recovery',
]);
export type SessionType = z.infer<typeof SessionTypeSchema>;

export const FacilityTypeSchema = z.enum([
  'natural_grass',
  'artificial_turf',
  'indoor_pitch',
  'gym',
  'weight_room',
  'sprint_track',
  'pool',
  'recovery_room',
]);
export type FacilityType = z.infer<typeof FacilityTypeSchema>;

export const EquipmentItemSchema = z.enum([
  'barbell',
  'dumbbell',
  'kettlebell',
  'bench',
  'squat_rack',
  'pull_up_bar',
  'resistance_band',
  'medicine_ball',
  'trx',
  'swiss_ball',
  'bosu',
  'weighted_vest',
  'speed_parachute',
  'cones',
  'agility_ladder',
  'hurdles',
  'plyo_box',
  'goal',
  'rebounder',
  'mannequin',
  'rowing_machine',
  'treadmill',
  'stationary_bike',
]);
export type EquipmentItem = z.infer<typeof EquipmentItemSchema>;

export const AttendanceStatusSchema = z.enum(['present', 'absent', 'late', 'excused']);
export type AttendanceStatus = z.infer<typeof AttendanceStatusSchema>;

export const PerformanceTestTypeSchema = z.enum([
  'sprint_10m',
  'sprint_20m',
  'sprint_30m',
  'agility_505',
  'agility_t_test',
  'yo_yo_ir1',
  'yo_yo_ir2',
  'beep_test',
  'cooper_test',
  'vertical_jump',
  'broad_jump',
  'bench_press_1rm',
  'squat_1rm',
  'pull_ups_max',
  'push_ups_max',
  'flexibility_sit_reach',
  'body_fat_percent',
]);
export type PerformanceTestType = z.infer<typeof PerformanceTestTypeSchema>;
