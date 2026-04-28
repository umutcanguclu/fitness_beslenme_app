/**
 * Curated, anatomy-aware subset of the free-exercise-db catalog.
 *
 * The program generator pulls exclusively from this table so it can reason
 * about movement patterns (squat, hinge, horizontal push) instead of the
 * coarser muscle-group tags in the source dataset. Every entry is hand
 * classified: pattern, primary mover, tier (where it belongs in a session),
 * difficulty, and the equipment categories it fits under.
 *
 * If an id here doesn't exist in the source JSON at runtime we silently
 * drop it; the dataset can be regenerated without breaking the algorithm.
 */
import type { Equipment } from '@fittrack/shared';

export type MovementPattern =
  | 'push_horizontal' // bench, push-up, machine chest press
  | 'push_vertical' // OHP, shoulder press, handstand push-up
  | 'pull_vertical' // pull-up, lat pulldown
  | 'pull_horizontal' // rows
  | 'squat' // knee-dominant bilateral
  | 'hinge' // hip-dominant bilateral (RDL, hip thrust)
  | 'lunge' // unilateral leg (split squats, lunges, step-ups)
  | 'isolation_chest'
  | 'isolation_delt_side'
  | 'isolation_delt_rear'
  | 'isolation_delt_front'
  | 'isolation_bicep'
  | 'isolation_tricep'
  | 'isolation_quad'
  | 'isolation_hamstring'
  | 'isolation_glute'
  | 'isolation_calf'
  | 'isolation_forearm'
  | 'core_brace'
  | 'core_flexion'
  | 'core_rotation';

export type PrimaryMuscle =
  | 'chest'
  | 'back_lats'
  | 'back_upper'
  | 'delts_front'
  | 'delts_side'
  | 'delts_rear'
  | 'biceps'
  | 'triceps'
  | 'forearms'
  | 'quads'
  | 'hamstrings'
  | 'glutes'
  | 'calves'
  | 'core';

export type Tier = 'primary' | 'secondary' | 'isolation';

export type ExerciseLevel = 'beginner' | 'intermediate' | 'expert';

export interface CuratedExercise {
  id: string;
  pattern: MovementPattern;
  primary: PrimaryMuscle;
  secondary?: PrimaryMuscle[];
  tier: Tier;
  level: ExerciseLevel;
  /** Equipment families this entry fits under. */
  equipment: Equipment[];
}

/* -------------------------------------------------------------------------- */
/* Chest — horizontal push                                                    */
/* -------------------------------------------------------------------------- */
const CHEST: CuratedExercise[] = [
  // Primary compounds
  { id: 'fed-Barbell_Bench_Press_-_Medium_Grip', pattern: 'push_horizontal', primary: 'chest', secondary: ['triceps', 'delts_front'], tier: 'primary', level: 'intermediate', equipment: ['barbell'] },
  { id: 'fed-Dumbbell_Bench_Press', pattern: 'push_horizontal', primary: 'chest', secondary: ['triceps', 'delts_front'], tier: 'primary', level: 'beginner', equipment: ['dumbbell'] },
  { id: 'fed-Barbell_Incline_Bench_Press_-_Medium_Grip', pattern: 'push_horizontal', primary: 'chest', secondary: ['delts_front', 'triceps'], tier: 'primary', level: 'intermediate', equipment: ['barbell'] },
  { id: 'fed-Incline_Dumbbell_Press', pattern: 'push_horizontal', primary: 'chest', secondary: ['delts_front', 'triceps'], tier: 'primary', level: 'beginner', equipment: ['dumbbell'] },
  { id: 'fed-Decline_Barbell_Bench_Press', pattern: 'push_horizontal', primary: 'chest', secondary: ['triceps'], tier: 'primary', level: 'intermediate', equipment: ['barbell'] },
  // Secondary compounds
  { id: 'fed-Parallel_Bar_Dip', pattern: 'push_horizontal', primary: 'chest', secondary: ['triceps', 'delts_front'], tier: 'secondary', level: 'intermediate', equipment: ['bodyweight'] },
  { id: 'fed-Pushups', pattern: 'push_horizontal', primary: 'chest', secondary: ['triceps', 'core'], tier: 'secondary', level: 'beginner', equipment: ['bodyweight'] },
  { id: 'fed-Push-Up_Wide', pattern: 'push_horizontal', primary: 'chest', secondary: ['triceps'], tier: 'secondary', level: 'beginner', equipment: ['bodyweight'] },
  { id: 'fed-Incline_Push-Up', pattern: 'push_horizontal', primary: 'chest', secondary: ['triceps'], tier: 'secondary', level: 'beginner', equipment: ['bodyweight'] },
  { id: 'fed-Decline_Push-Up', pattern: 'push_horizontal', primary: 'chest', secondary: ['triceps', 'delts_front'], tier: 'secondary', level: 'beginner', equipment: ['bodyweight'] },
  { id: 'fed-Cable_Chest_Press', pattern: 'push_horizontal', primary: 'chest', secondary: ['triceps'], tier: 'secondary', level: 'beginner', equipment: ['cable'] },
  { id: 'fed-Leverage_Chest_Press', pattern: 'push_horizontal', primary: 'chest', secondary: ['triceps'], tier: 'secondary', level: 'beginner', equipment: ['machine'] },
  { id: 'fed-Leverage_Incline_Chest_Press', pattern: 'push_horizontal', primary: 'chest', secondary: ['delts_front'], tier: 'secondary', level: 'beginner', equipment: ['machine'] },
  { id: 'fed-Smith_Machine_Incline_Bench_Press', pattern: 'push_horizontal', primary: 'chest', secondary: ['delts_front'], tier: 'secondary', level: 'beginner', equipment: ['machine'] },
  // Isolation
  { id: 'fed-Dumbbell_Flyes', pattern: 'isolation_chest', primary: 'chest', tier: 'isolation', level: 'beginner', equipment: ['dumbbell'] },
  { id: 'fed-Incline_Dumbbell_Flyes', pattern: 'isolation_chest', primary: 'chest', tier: 'isolation', level: 'beginner', equipment: ['dumbbell'] },
  { id: 'fed-Cable_Crossover', pattern: 'isolation_chest', primary: 'chest', tier: 'isolation', level: 'beginner', equipment: ['cable'] },
  { id: 'fed-Low_Cable_Crossover', pattern: 'isolation_chest', primary: 'chest', tier: 'isolation', level: 'beginner', equipment: ['cable'] },
  { id: 'fed-Decline_Dumbbell_Flyes', pattern: 'isolation_chest', primary: 'chest', tier: 'isolation', level: 'beginner', equipment: ['dumbbell'] },
];

/* -------------------------------------------------------------------------- */
/* Shoulders — vertical push + isolations                                     */
/* -------------------------------------------------------------------------- */
const SHOULDERS: CuratedExercise[] = [
  // Primary vertical push
  { id: 'fed-Standing_Military_Press', pattern: 'push_vertical', primary: 'delts_front', secondary: ['triceps', 'core'], tier: 'primary', level: 'intermediate', equipment: ['barbell'] },
  { id: 'fed-Seated_Barbell_Military_Press', pattern: 'push_vertical', primary: 'delts_front', secondary: ['triceps'], tier: 'primary', level: 'intermediate', equipment: ['barbell'] },
  { id: 'fed-Seated_Dumbbell_Press', pattern: 'push_vertical', primary: 'delts_front', secondary: ['triceps'], tier: 'primary', level: 'beginner', equipment: ['dumbbell'] },
  { id: 'fed-Dumbbell_Shoulder_Press', pattern: 'push_vertical', primary: 'delts_front', secondary: ['triceps'], tier: 'primary', level: 'intermediate', equipment: ['dumbbell'] },
  { id: 'fed-Standing_Dumbbell_Press', pattern: 'push_vertical', primary: 'delts_front', secondary: ['triceps', 'core'], tier: 'primary', level: 'beginner', equipment: ['dumbbell'] },
  { id: 'fed-Arnold_Dumbbell_Press', pattern: 'push_vertical', primary: 'delts_front', secondary: ['delts_side', 'triceps'], tier: 'secondary', level: 'intermediate', equipment: ['dumbbell'] },
  // Side delt isolation
  { id: 'fed-Side_Lateral_Raise', pattern: 'isolation_delt_side', primary: 'delts_side', tier: 'isolation', level: 'beginner', equipment: ['dumbbell'] },
  { id: 'fed-Seated_Side_Lateral_Raise', pattern: 'isolation_delt_side', primary: 'delts_side', tier: 'isolation', level: 'beginner', equipment: ['dumbbell'] },
  { id: 'fed-Cable_Seated_Lateral_Raise', pattern: 'isolation_delt_side', primary: 'delts_side', tier: 'isolation', level: 'beginner', equipment: ['cable'] },
  { id: 'fed-Lateral_Raise_-_With_Bands', pattern: 'isolation_delt_side', primary: 'delts_side', tier: 'isolation', level: 'beginner', equipment: ['resistance_band'] },
  // Rear delt isolation
  { id: 'fed-Reverse_Flyes', pattern: 'isolation_delt_rear', primary: 'delts_rear', tier: 'isolation', level: 'beginner', equipment: ['dumbbell'] },
  { id: 'fed-Face_Pull', pattern: 'isolation_delt_rear', primary: 'delts_rear', secondary: ['back_upper'], tier: 'isolation', level: 'beginner', equipment: ['cable'] },
  { id: 'fed-Cable_Rear_Delt_Fly', pattern: 'isolation_delt_rear', primary: 'delts_rear', tier: 'isolation', level: 'beginner', equipment: ['cable'] },
  { id: 'fed-Bent_Over_Dumbbell_Rear_Delt_Raise_With_Head_On_Bench', pattern: 'isolation_delt_rear', primary: 'delts_rear', tier: 'isolation', level: 'beginner', equipment: ['dumbbell'] },
  // Front delt isolation
  { id: 'fed-Front_Dumbbell_Raise', pattern: 'isolation_delt_front', primary: 'delts_front', tier: 'isolation', level: 'beginner', equipment: ['dumbbell'] },
  { id: 'fed-Front_Plate_Raise', pattern: 'isolation_delt_front', primary: 'delts_front', tier: 'isolation', level: 'beginner', equipment: ['other'] },
];

/* -------------------------------------------------------------------------- */
/* Back — vertical + horizontal pull                                          */
/* -------------------------------------------------------------------------- */
const BACK: CuratedExercise[] = [
  // Vertical pull
  { id: 'fed-Pullups', pattern: 'pull_vertical', primary: 'back_lats', secondary: ['biceps'], tier: 'primary', level: 'intermediate', equipment: ['bodyweight'] },
  { id: 'fed-Chin-Up', pattern: 'pull_vertical', primary: 'back_lats', secondary: ['biceps'], tier: 'primary', level: 'intermediate', equipment: ['bodyweight'] },
  { id: 'fed-Band_Assisted_Pull-Up', pattern: 'pull_vertical', primary: 'back_lats', secondary: ['biceps'], tier: 'primary', level: 'beginner', equipment: ['resistance_band', 'bodyweight'] },
  { id: 'fed-Wide-Grip_Lat_Pulldown', pattern: 'pull_vertical', primary: 'back_lats', secondary: ['biceps'], tier: 'primary', level: 'beginner', equipment: ['cable'] },
  { id: 'fed-Close-Grip_Front_Lat_Pulldown', pattern: 'pull_vertical', primary: 'back_lats', secondary: ['biceps'], tier: 'primary', level: 'beginner', equipment: ['cable'] },
  { id: 'fed-Full_Range-Of-Motion_Lat_Pulldown', pattern: 'pull_vertical', primary: 'back_lats', secondary: ['biceps'], tier: 'primary', level: 'intermediate', equipment: ['cable'] },
  // Horizontal pull
  { id: 'fed-Bent_Over_Barbell_Row', pattern: 'pull_horizontal', primary: 'back_upper', secondary: ['biceps', 'back_lats'], tier: 'primary', level: 'intermediate', equipment: ['barbell'] },
  { id: 'fed-Bent_Over_Two-Dumbbell_Row', pattern: 'pull_horizontal', primary: 'back_upper', secondary: ['biceps'], tier: 'primary', level: 'beginner', equipment: ['dumbbell'] },
  { id: 'fed-One-Arm_Dumbbell_Row', pattern: 'pull_horizontal', primary: 'back_upper', secondary: ['biceps'], tier: 'primary', level: 'beginner', equipment: ['dumbbell'] },
  { id: 'fed-Seated_Cable_Rows', pattern: 'pull_horizontal', primary: 'back_upper', secondary: ['biceps'], tier: 'primary', level: 'beginner', equipment: ['cable'] },
  { id: 'fed-Lying_T-Bar_Row', pattern: 'pull_horizontal', primary: 'back_upper', secondary: ['biceps'], tier: 'secondary', level: 'intermediate', equipment: ['machine'] },
  { id: 'fed-Reverse_Grip_Bent-Over_Rows', pattern: 'pull_horizontal', primary: 'back_upper', secondary: ['biceps'], tier: 'secondary', level: 'intermediate', equipment: ['barbell'] },
  { id: 'fed-Inverted_Row', pattern: 'pull_horizontal', primary: 'back_upper', secondary: ['biceps'], tier: 'secondary', level: 'beginner', equipment: ['bodyweight'] },
];

/* -------------------------------------------------------------------------- */
/* Biceps                                                                     */
/* -------------------------------------------------------------------------- */
const BICEPS: CuratedExercise[] = [
  { id: 'fed-Barbell_Curl', pattern: 'isolation_bicep', primary: 'biceps', tier: 'isolation', level: 'beginner', equipment: ['barbell'] },
  { id: 'fed-Dumbbell_Bicep_Curl', pattern: 'isolation_bicep', primary: 'biceps', tier: 'isolation', level: 'beginner', equipment: ['dumbbell'] },
  { id: 'fed-Alternate_Hammer_Curl', pattern: 'isolation_bicep', primary: 'biceps', secondary: ['forearms'], tier: 'isolation', level: 'beginner', equipment: ['dumbbell'] },
  { id: 'fed-Cross_Body_Hammer_Curl', pattern: 'isolation_bicep', primary: 'biceps', secondary: ['forearms'], tier: 'isolation', level: 'beginner', equipment: ['dumbbell'] },
  { id: 'fed-Preacher_Curl', pattern: 'isolation_bicep', primary: 'biceps', tier: 'isolation', level: 'beginner', equipment: ['barbell'] },
  { id: 'fed-Cable_Preacher_Curl', pattern: 'isolation_bicep', primary: 'biceps', tier: 'isolation', level: 'beginner', equipment: ['cable'] },
  { id: 'fed-Machine_Preacher_Curls', pattern: 'isolation_bicep', primary: 'biceps', tier: 'isolation', level: 'beginner', equipment: ['machine'] },
  { id: 'fed-Incline_Dumbbell_Curl', pattern: 'isolation_bicep', primary: 'biceps', tier: 'isolation', level: 'intermediate', equipment: ['dumbbell'] },
  { id: 'fed-Concentration_Curls', pattern: 'isolation_bicep', primary: 'biceps', tier: 'isolation', level: 'beginner', equipment: ['dumbbell'] },
  { id: 'fed-Standing_Biceps_Cable_Curl', pattern: 'isolation_bicep', primary: 'biceps', tier: 'isolation', level: 'beginner', equipment: ['cable'] },
  { id: 'fed-Cable_Hammer_Curls_-_Rope_Attachment', pattern: 'isolation_bicep', primary: 'biceps', tier: 'isolation', level: 'beginner', equipment: ['cable'] },
  { id: 'fed-High_Cable_Curls', pattern: 'isolation_bicep', primary: 'biceps', tier: 'isolation', level: 'beginner', equipment: ['cable'] },
];

/* -------------------------------------------------------------------------- */
/* Triceps                                                                    */
/* -------------------------------------------------------------------------- */
const TRICEPS: CuratedExercise[] = [
  { id: 'fed-Triceps_Pushdown', pattern: 'isolation_tricep', primary: 'triceps', tier: 'isolation', level: 'beginner', equipment: ['cable'] },
  { id: 'fed-Triceps_Pushdown_-_Rope_Attachment', pattern: 'isolation_tricep', primary: 'triceps', tier: 'isolation', level: 'beginner', equipment: ['cable'] },
  { id: 'fed-Triceps_Pushdown_-_V-Bar_Attachment', pattern: 'isolation_tricep', primary: 'triceps', tier: 'isolation', level: 'beginner', equipment: ['cable'] },
  { id: 'fed-Close-Grip_Barbell_Bench_Press', pattern: 'push_horizontal', primary: 'triceps', secondary: ['chest'], tier: 'secondary', level: 'beginner', equipment: ['barbell'] },
  { id: 'fed-Lying_Triceps_Press', pattern: 'isolation_tricep', primary: 'triceps', tier: 'isolation', level: 'intermediate', equipment: ['barbell'] },
  { id: 'fed-Dumbbell_One-Arm_Triceps_Extension', pattern: 'isolation_tricep', primary: 'triceps', tier: 'isolation', level: 'beginner', equipment: ['dumbbell'] },
  { id: 'fed-Seated_Bent-Over_Two-Arm_Dumbbell_Triceps_Extension', pattern: 'isolation_tricep', primary: 'triceps', tier: 'isolation', level: 'beginner', equipment: ['dumbbell'] },
  { id: 'fed-Standing_Overhead_Barbell_Triceps_Extension', pattern: 'isolation_tricep', primary: 'triceps', tier: 'isolation', level: 'beginner', equipment: ['barbell'] },
  { id: 'fed-Cable_Rope_Overhead_Triceps_Extension', pattern: 'isolation_tricep', primary: 'triceps', tier: 'isolation', level: 'beginner', equipment: ['cable'] },
  { id: 'fed-Bench_Dips', pattern: 'isolation_tricep', primary: 'triceps', tier: 'isolation', level: 'beginner', equipment: ['bodyweight'] },
  { id: 'fed-Body_Tricep_Press', pattern: 'isolation_tricep', primary: 'triceps', tier: 'isolation', level: 'beginner', equipment: ['bodyweight'] },
];

/* -------------------------------------------------------------------------- */
/* Quads — squat pattern                                                      */
/* -------------------------------------------------------------------------- */
const QUADS: CuratedExercise[] = [
  { id: 'fed-Barbell_Squat', pattern: 'squat', primary: 'quads', secondary: ['glutes', 'hamstrings'], tier: 'primary', level: 'intermediate', equipment: ['barbell'] },
  { id: 'fed-Front_Barbell_Squat', pattern: 'squat', primary: 'quads', secondary: ['glutes'], tier: 'primary', level: 'expert', equipment: ['barbell'] },
  { id: 'fed-Dumbbell_Squat', pattern: 'squat', primary: 'quads', secondary: ['glutes'], tier: 'primary', level: 'beginner', equipment: ['dumbbell'] },
  { id: 'fed-Goblet_Squat', pattern: 'squat', primary: 'quads', secondary: ['glutes', 'core'], tier: 'primary', level: 'beginner', equipment: ['dumbbell', 'kettlebell'] },
  { id: 'fed-Bodyweight_Squat', pattern: 'squat', primary: 'quads', secondary: ['glutes'], tier: 'secondary', level: 'beginner', equipment: ['bodyweight'] },
  { id: 'fed-Leg_Press', pattern: 'squat', primary: 'quads', secondary: ['glutes'], tier: 'primary', level: 'beginner', equipment: ['machine'] },
  { id: 'fed-Narrow_Stance_Leg_Press', pattern: 'squat', primary: 'quads', secondary: ['glutes'], tier: 'secondary', level: 'intermediate', equipment: ['machine'] },
  { id: 'fed-Smith_Machine_Squat', pattern: 'squat', primary: 'quads', secondary: ['glutes'], tier: 'secondary', level: 'beginner', equipment: ['machine'] },
  // Lunges (lunge pattern - unilateral)
  { id: 'fed-Dumbbell_Lunges', pattern: 'lunge', primary: 'quads', secondary: ['glutes', 'hamstrings'], tier: 'secondary', level: 'beginner', equipment: ['dumbbell'] },
  { id: 'fed-Bodyweight_Walking_Lunge', pattern: 'lunge', primary: 'quads', secondary: ['glutes'], tier: 'secondary', level: 'beginner', equipment: ['bodyweight'] },
  { id: 'fed-Barbell_Walking_Lunge', pattern: 'lunge', primary: 'quads', secondary: ['glutes'], tier: 'secondary', level: 'beginner', equipment: ['barbell'] },
  { id: 'fed-Barbell_Lunge', pattern: 'lunge', primary: 'quads', secondary: ['glutes'], tier: 'secondary', level: 'intermediate', equipment: ['barbell'] },
  { id: 'fed-Dumbbell_Step_Ups', pattern: 'lunge', primary: 'quads', secondary: ['glutes'], tier: 'secondary', level: 'intermediate', equipment: ['dumbbell'] },
  { id: 'fed-Dumbbell_Rear_Lunge', pattern: 'lunge', primary: 'quads', secondary: ['glutes'], tier: 'secondary', level: 'intermediate', equipment: ['dumbbell'] },
  // Quad isolation
  { id: 'fed-Leg_Extensions', pattern: 'isolation_quad', primary: 'quads', tier: 'isolation', level: 'beginner', equipment: ['machine'] },
  { id: 'fed-Single-Leg_Leg_Extension', pattern: 'isolation_quad', primary: 'quads', tier: 'isolation', level: 'beginner', equipment: ['machine'] },
];

/* -------------------------------------------------------------------------- */
/* Hamstrings + Glutes — hinge pattern                                        */
/* -------------------------------------------------------------------------- */
const HINGE: CuratedExercise[] = [
  { id: 'fed-Romanian_Deadlift', pattern: 'hinge', primary: 'hamstrings', secondary: ['glutes', 'back_upper'], tier: 'primary', level: 'intermediate', equipment: ['barbell'] },
  { id: 'fed-Romanian_Deadlift_from_Deficit', pattern: 'hinge', primary: 'hamstrings', secondary: ['glutes'], tier: 'primary', level: 'intermediate', equipment: ['barbell'] },
  { id: 'fed-Barbell_Hip_Thrust', pattern: 'hinge', primary: 'glutes', secondary: ['hamstrings'], tier: 'primary', level: 'intermediate', equipment: ['barbell'] },
  { id: 'fed-Barbell_Glute_Bridge', pattern: 'hinge', primary: 'glutes', secondary: ['hamstrings'], tier: 'primary', level: 'intermediate', equipment: ['barbell'] },
  { id: 'fed-Butt_Lift_Bridge', pattern: 'hinge', primary: 'glutes', secondary: ['hamstrings'], tier: 'secondary', level: 'beginner', equipment: ['bodyweight'] },
  { id: 'fed-Single_Leg_Glute_Bridge', pattern: 'hinge', primary: 'glutes', secondary: ['hamstrings'], tier: 'secondary', level: 'beginner', equipment: ['bodyweight'] },
  // Hamstring isolation
  { id: 'fed-Lying_Leg_Curls', pattern: 'isolation_hamstring', primary: 'hamstrings', tier: 'isolation', level: 'beginner', equipment: ['machine'] },
  { id: 'fed-Seated_Leg_Curl', pattern: 'isolation_hamstring', primary: 'hamstrings', tier: 'isolation', level: 'beginner', equipment: ['machine'] },
  { id: 'fed-Standing_Leg_Curl', pattern: 'isolation_hamstring', primary: 'hamstrings', tier: 'isolation', level: 'beginner', equipment: ['machine'] },
  { id: 'fed-Ball_Leg_Curl', pattern: 'isolation_hamstring', primary: 'hamstrings', tier: 'isolation', level: 'beginner', equipment: ['other'] },
  // Glute isolation
  { id: 'fed-Glute_Kickback', pattern: 'isolation_glute', primary: 'glutes', tier: 'isolation', level: 'beginner', equipment: ['bodyweight'] },
  { id: 'fed-One-Legged_Cable_Kickback', pattern: 'isolation_glute', primary: 'glutes', tier: 'isolation', level: 'intermediate', equipment: ['cable'] },
];

/* -------------------------------------------------------------------------- */
/* Calves                                                                     */
/* -------------------------------------------------------------------------- */
const CALVES: CuratedExercise[] = [
  { id: 'fed-Calf_Press', pattern: 'isolation_calf', primary: 'calves', tier: 'isolation', level: 'beginner', equipment: ['machine'] },
  { id: 'fed-Calf_Press_On_The_Leg_Press_Machine', pattern: 'isolation_calf', primary: 'calves', tier: 'isolation', level: 'beginner', equipment: ['machine'] },
  { id: 'fed-Standing_Barbell_Calf_Raise', pattern: 'isolation_calf', primary: 'calves', tier: 'isolation', level: 'beginner', equipment: ['barbell'] },
  { id: 'fed-Barbell_Seated_Calf_Raise', pattern: 'isolation_calf', primary: 'calves', tier: 'isolation', level: 'beginner', equipment: ['barbell'] },
  { id: 'fed-Calf_Raise_On_A_Dumbbell', pattern: 'isolation_calf', primary: 'calves', tier: 'isolation', level: 'intermediate', equipment: ['dumbbell'] },
  { id: 'fed-Dumbbell_Seated_One-Leg_Calf_Raise', pattern: 'isolation_calf', primary: 'calves', tier: 'isolation', level: 'beginner', equipment: ['dumbbell'] },
  { id: 'fed-Calf_Raises_-_With_Bands', pattern: 'isolation_calf', primary: 'calves', tier: 'isolation', level: 'beginner', equipment: ['resistance_band'] },
];

/* -------------------------------------------------------------------------- */
/* Core                                                                       */
/* -------------------------------------------------------------------------- */
const CORE: CuratedExercise[] = [
  { id: 'fed-Plank', pattern: 'core_brace', primary: 'core', tier: 'isolation', level: 'beginner', equipment: ['bodyweight'] },
  { id: 'fed-Dead_Bug', pattern: 'core_brace', primary: 'core', tier: 'isolation', level: 'beginner', equipment: ['bodyweight'] },
  { id: 'fed-Pallof_Press', pattern: 'core_brace', primary: 'core', tier: 'isolation', level: 'beginner', equipment: ['cable'] },
  { id: 'fed-Cable_Crunch', pattern: 'core_flexion', primary: 'core', tier: 'isolation', level: 'beginner', equipment: ['cable'] },
  { id: 'fed-Crunches', pattern: 'core_flexion', primary: 'core', tier: 'isolation', level: 'beginner', equipment: ['bodyweight'] },
  { id: 'fed-Crunch_-_Hands_Overhead', pattern: 'core_flexion', primary: 'core', tier: 'isolation', level: 'beginner', equipment: ['bodyweight'] },
  { id: 'fed-Cross-Body_Crunch', pattern: 'core_flexion', primary: 'core', tier: 'isolation', level: 'beginner', equipment: ['bodyweight'] },
  { id: 'fed-Hanging_Leg_Raise', pattern: 'core_flexion', primary: 'core', tier: 'isolation', level: 'expert', equipment: ['bodyweight'] },
  { id: 'fed-Reverse_Crunch', pattern: 'core_flexion', primary: 'core', tier: 'isolation', level: 'beginner', equipment: ['bodyweight'] },
  { id: 'fed-Russian_Twist', pattern: 'core_rotation', primary: 'core', tier: 'isolation', level: 'intermediate', equipment: ['bodyweight'] },
  { id: 'fed-Cable_Russian_Twists', pattern: 'core_rotation', primary: 'core', tier: 'isolation', level: 'beginner', equipment: ['cable'] },
  { id: 'fed-Pallof_Press_With_Rotation', pattern: 'core_rotation', primary: 'core', tier: 'isolation', level: 'beginner', equipment: ['cable'] },
];

/* -------------------------------------------------------------------------- */
/* Forearms                                                                   */
/* -------------------------------------------------------------------------- */
const FOREARMS: CuratedExercise[] = [
  { id: 'fed-Palms-Up_Barbell_Wrist_Curl_Over_A_Bench', pattern: 'isolation_forearm', primary: 'forearms', tier: 'isolation', level: 'beginner', equipment: ['barbell'] },
  { id: 'fed-Palms-Up_Dumbbell_Wrist_Curl_Over_A_Bench', pattern: 'isolation_forearm', primary: 'forearms', tier: 'isolation', level: 'beginner', equipment: ['dumbbell'] },
  { id: 'fed-Reverse_Barbell_Curl', pattern: 'isolation_forearm', primary: 'forearms', tier: 'isolation', level: 'beginner', equipment: ['barbell'] },
];

export const CURATED_EXERCISES: readonly CuratedExercise[] = [
  ...CHEST,
  ...SHOULDERS,
  ...BACK,
  ...BICEPS,
  ...TRICEPS,
  ...QUADS,
  ...HINGE,
  ...CALVES,
  ...CORE,
  ...FOREARMS,
];

export const CURATED_BY_ID: ReadonlyMap<string, CuratedExercise> = new Map(
  CURATED_EXERCISES.map((e) => [e.id, e]),
);
