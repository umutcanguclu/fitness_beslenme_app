/**
 * Prescriptive session templates. Each training day has an ordered list of
 * slots; each slot provides a *preferred* chain of exercise IDs in coach
 * priority order. The selector picks the first viable id (respects user
 * equipment + level + no-duplicates across the week).
 *
 * Design principles:
 *  - Day A vs Day B variants for repeated day types so push×2 doesn't feel
 *    identical. A-variants favor chest/quad, B-variants favor shoulders/
 *    posterior chain.
 *  - Compound → secondary compound → isolation ordering within a day.
 *  - Preferred lists degrade gracefully: if barbell bench isn't allowed,
 *    the fallback is DB bench; if DB isn't allowed, push-ups; etc.
 *  - Each slot also states a `fallbackPattern` so when every preferred id
 *    is exhausted (tiny equipment pool, reuse block) the algorithm can find
 *    *any* matching exercise via the curated table's pattern index.
 */
import type { MovementPattern, PrimaryMuscle, Tier } from './curated-exercises.js';

export interface SessionSlot {
  /** Ordered preferred exercise ids — first valid one wins. */
  preferred: string[];
  /** Last-resort pattern match if none of `preferred` is available. */
  fallbackPattern: MovementPattern;
  /** Anatomical role of this slot; used for weekly-volume accounting. */
  muscle: PrimaryMuscle;
  tier: Tier;
  /**
   * Skip the slot if the user didn't request work for this muscle group in
   * the wizard. Leaves empty slots for stripped-down programs (e.g. user
   * who only picked legs shouldn't see biceps isolation on an Upper day).
   */
  required?: boolean;
}

export interface SessionTemplate {
  key: string;
  name: string;
  slots: SessionSlot[];
}

/* -------------------------------------------------------------------------- */
/* PUSH (chest + shoulders + triceps)                                         */
/* -------------------------------------------------------------------------- */

/** Push A — chest anchor, shoulders/triceps accessory. */
const pushA: SessionTemplate = {
  key: 'push_a',
  name: 'İtiş A · Göğüs Ağırlıklı',
  slots: [
    {
      muscle: 'chest', tier: 'primary', fallbackPattern: 'push_horizontal',
      preferred: [
        'fed-Barbell_Bench_Press_-_Medium_Grip',
        'fed-Dumbbell_Bench_Press',
        'fed-Leverage_Chest_Press',
        'fed-Pushups',
      ],
      required: true,
    },
    {
      muscle: 'delts_front', tier: 'primary', fallbackPattern: 'push_vertical',
      preferred: [
        'fed-Seated_Dumbbell_Press',
        'fed-Dumbbell_Shoulder_Press',
        'fed-Standing_Dumbbell_Press',
        'fed-Standing_Military_Press',
      ],
    },
    {
      muscle: 'chest', tier: 'secondary', fallbackPattern: 'push_horizontal',
      preferred: [
        'fed-Incline_Dumbbell_Press',
        'fed-Barbell_Incline_Bench_Press_-_Medium_Grip',
        'fed-Leverage_Incline_Chest_Press',
        'fed-Parallel_Bar_Dip',
        'fed-Incline_Push-Up',
      ],
    },
    {
      muscle: 'chest', tier: 'isolation', fallbackPattern: 'isolation_chest',
      preferred: [
        'fed-Cable_Crossover',
        'fed-Dumbbell_Flyes',
        'fed-Low_Cable_Crossover',
      ],
    },
    {
      muscle: 'delts_side', tier: 'isolation', fallbackPattern: 'isolation_delt_side',
      preferred: [
        'fed-Side_Lateral_Raise',
        'fed-Seated_Side_Lateral_Raise',
        'fed-Cable_Seated_Lateral_Raise',
        'fed-Lateral_Raise_-_With_Bands',
      ],
    },
    {
      muscle: 'triceps', tier: 'isolation', fallbackPattern: 'isolation_tricep',
      preferred: [
        'fed-Triceps_Pushdown_-_Rope_Attachment',
        'fed-Triceps_Pushdown',
        'fed-Dumbbell_One-Arm_Triceps_Extension',
        'fed-Bench_Dips',
      ],
    },
    {
      muscle: 'triceps', tier: 'isolation', fallbackPattern: 'isolation_tricep',
      preferred: [
        'fed-Cable_Rope_Overhead_Triceps_Extension',
        'fed-Standing_Overhead_Barbell_Triceps_Extension',
        'fed-Lying_Triceps_Press',
        'fed-Body_Tricep_Press',
      ],
    },
  ],
};

/** Push B — shoulders anchor, incline chest, side delt volume. */
const pushB: SessionTemplate = {
  key: 'push_b',
  name: 'İtiş B · Omuz Ağırlıklı',
  slots: [
    {
      muscle: 'delts_front', tier: 'primary', fallbackPattern: 'push_vertical',
      preferred: [
        'fed-Standing_Military_Press',
        'fed-Seated_Barbell_Military_Press',
        'fed-Seated_Dumbbell_Press',
        'fed-Dumbbell_Shoulder_Press',
      ],
      required: true,
    },
    {
      muscle: 'chest', tier: 'primary', fallbackPattern: 'push_horizontal',
      preferred: [
        'fed-Barbell_Incline_Bench_Press_-_Medium_Grip',
        'fed-Incline_Dumbbell_Press',
        'fed-Leverage_Incline_Chest_Press',
        'fed-Pushups',
      ],
    },
    {
      muscle: 'delts_front', tier: 'secondary', fallbackPattern: 'push_vertical',
      preferred: [
        'fed-Arnold_Dumbbell_Press',
        'fed-Standing_Dumbbell_Press',
      ],
    },
    {
      muscle: 'delts_side', tier: 'isolation', fallbackPattern: 'isolation_delt_side',
      preferred: [
        'fed-Cable_Seated_Lateral_Raise',
        'fed-Side_Lateral_Raise',
        'fed-Seated_Side_Lateral_Raise',
        'fed-Lateral_Raise_-_With_Bands',
      ],
    },
    {
      muscle: 'delts_rear', tier: 'isolation', fallbackPattern: 'isolation_delt_rear',
      preferred: [
        'fed-Face_Pull',
        'fed-Reverse_Flyes',
        'fed-Cable_Rear_Delt_Fly',
      ],
    },
    {
      muscle: 'triceps', tier: 'secondary', fallbackPattern: 'push_horizontal',
      preferred: [
        'fed-Close-Grip_Barbell_Bench_Press',
        'fed-Lying_Triceps_Press',
        'fed-Bench_Dips',
      ],
    },
    {
      muscle: 'triceps', tier: 'isolation', fallbackPattern: 'isolation_tricep',
      preferred: [
        'fed-Triceps_Pushdown',
        'fed-Dumbbell_One-Arm_Triceps_Extension',
        'fed-Standing_Overhead_Barbell_Triceps_Extension',
      ],
    },
  ],
};

/* -------------------------------------------------------------------------- */
/* PULL (back + biceps + rear delt)                                           */
/* -------------------------------------------------------------------------- */

/** Pull A — back thickness (row-heavy) + biceps. */
const pullA: SessionTemplate = {
  key: 'pull_a',
  name: 'Çekiş A · Sırt Kalınlığı',
  slots: [
    {
      muscle: 'back_lats', tier: 'primary', fallbackPattern: 'pull_vertical',
      preferred: [
        'fed-Pullups',
        'fed-Wide-Grip_Lat_Pulldown',
        'fed-Band_Assisted_Pull-Up',
      ],
      required: true,
    },
    {
      muscle: 'back_upper', tier: 'primary', fallbackPattern: 'pull_horizontal',
      preferred: [
        'fed-Bent_Over_Barbell_Row',
        'fed-Bent_Over_Two-Dumbbell_Row',
        'fed-Lying_T-Bar_Row',
        'fed-Inverted_Row',
      ],
      required: true,
    },
    {
      muscle: 'back_upper', tier: 'secondary', fallbackPattern: 'pull_horizontal',
      preferred: [
        'fed-Seated_Cable_Rows',
        'fed-One-Arm_Dumbbell_Row',
      ],
    },
    {
      muscle: 'delts_rear', tier: 'isolation', fallbackPattern: 'isolation_delt_rear',
      preferred: [
        'fed-Face_Pull',
        'fed-Cable_Rear_Delt_Fly',
        'fed-Reverse_Flyes',
      ],
    },
    {
      muscle: 'biceps', tier: 'isolation', fallbackPattern: 'isolation_bicep',
      preferred: [
        'fed-Barbell_Curl',
        'fed-Dumbbell_Bicep_Curl',
        'fed-Standing_Biceps_Cable_Curl',
      ],
    },
    {
      muscle: 'biceps', tier: 'isolation', fallbackPattern: 'isolation_bicep',
      preferred: [
        'fed-Alternate_Hammer_Curl',
        'fed-Cable_Hammer_Curls_-_Rope_Attachment',
        'fed-Cross_Body_Hammer_Curl',
      ],
    },
    {
      muscle: 'forearms', tier: 'isolation', fallbackPattern: 'isolation_forearm',
      preferred: [
        'fed-Palms-Up_Barbell_Wrist_Curl_Over_A_Bench',
        'fed-Palms-Up_Dumbbell_Wrist_Curl_Over_A_Bench',
        'fed-Reverse_Barbell_Curl',
      ],
    },
  ],
};

/** Pull B — lat width (pull-up-heavy) + preacher variants. */
const pullB: SessionTemplate = {
  key: 'pull_b',
  name: 'Çekiş B · Sırt Genişliği',
  slots: [
    {
      muscle: 'back_lats', tier: 'primary', fallbackPattern: 'pull_vertical',
      preferred: [
        'fed-Chin-Up',
        'fed-Close-Grip_Front_Lat_Pulldown',
        'fed-Full_Range-Of-Motion_Lat_Pulldown',
        'fed-Band_Assisted_Pull-Up',
      ],
      required: true,
    },
    {
      muscle: 'back_upper', tier: 'primary', fallbackPattern: 'pull_horizontal',
      preferred: [
        'fed-One-Arm_Dumbbell_Row',
        'fed-Seated_Cable_Rows',
        'fed-Reverse_Grip_Bent-Over_Rows',
        'fed-Inverted_Row',
      ],
      required: true,
    },
    {
      muscle: 'back_upper', tier: 'secondary', fallbackPattern: 'pull_horizontal',
      preferred: [
        'fed-Lying_T-Bar_Row',
        'fed-Bent_Over_Two-Dumbbell_Row',
      ],
    },
    {
      muscle: 'delts_rear', tier: 'isolation', fallbackPattern: 'isolation_delt_rear',
      preferred: [
        'fed-Cable_Rear_Delt_Fly',
        'fed-Reverse_Flyes',
        'fed-Bent_Over_Dumbbell_Rear_Delt_Raise_With_Head_On_Bench',
      ],
    },
    {
      muscle: 'biceps', tier: 'isolation', fallbackPattern: 'isolation_bicep',
      preferred: [
        'fed-Preacher_Curl',
        'fed-Machine_Preacher_Curls',
        'fed-Cable_Preacher_Curl',
      ],
    },
    {
      muscle: 'biceps', tier: 'isolation', fallbackPattern: 'isolation_bicep',
      preferred: [
        'fed-Incline_Dumbbell_Curl',
        'fed-Concentration_Curls',
        'fed-High_Cable_Curls',
      ],
    },
  ],
};

/* -------------------------------------------------------------------------- */
/* LEGS                                                                       */
/* -------------------------------------------------------------------------- */

/** Legs A — quad-dominant. */
const legsA: SessionTemplate = {
  key: 'legs_a',
  name: 'Bacak A · Quad Ağırlıklı',
  slots: [
    {
      muscle: 'quads', tier: 'primary', fallbackPattern: 'squat',
      preferred: [
        'fed-Barbell_Squat',
        'fed-Leg_Press',
        'fed-Goblet_Squat',
        'fed-Dumbbell_Squat',
        'fed-Bodyweight_Squat',
      ],
      required: true,
    },
    {
      muscle: 'hamstrings', tier: 'primary', fallbackPattern: 'hinge',
      preferred: [
        'fed-Romanian_Deadlift',
        'fed-Romanian_Deadlift_from_Deficit',
      ],
    },
    {
      muscle: 'quads', tier: 'secondary', fallbackPattern: 'lunge',
      preferred: [
        'fed-Barbell_Walking_Lunge',
        'fed-Dumbbell_Lunges',
        'fed-Dumbbell_Step_Ups',
        'fed-Bodyweight_Walking_Lunge',
      ],
    },
    {
      muscle: 'quads', tier: 'isolation', fallbackPattern: 'isolation_quad',
      preferred: ['fed-Leg_Extensions', 'fed-Single-Leg_Leg_Extension'],
    },
    {
      muscle: 'hamstrings', tier: 'isolation', fallbackPattern: 'isolation_hamstring',
      preferred: ['fed-Lying_Leg_Curls', 'fed-Seated_Leg_Curl', 'fed-Standing_Leg_Curl'],
    },
    {
      muscle: 'calves', tier: 'isolation', fallbackPattern: 'isolation_calf',
      preferred: [
        'fed-Standing_Barbell_Calf_Raise',
        'fed-Calf_Press_On_The_Leg_Press_Machine',
        'fed-Calf_Raise_On_A_Dumbbell',
      ],
    },
  ],
};

/** Legs B — posterior-chain-dominant (hip thrust/deadlift/glute). */
const legsB: SessionTemplate = {
  key: 'legs_b',
  name: 'Bacak B · Kalça/Hamstring Ağırlıklı',
  slots: [
    {
      muscle: 'glutes', tier: 'primary', fallbackPattern: 'hinge',
      preferred: [
        'fed-Barbell_Hip_Thrust',
        'fed-Barbell_Glute_Bridge',
        'fed-Single_Leg_Glute_Bridge',
        'fed-Butt_Lift_Bridge',
      ],
      required: true,
    },
    {
      muscle: 'hamstrings', tier: 'primary', fallbackPattern: 'hinge',
      preferred: [
        'fed-Romanian_Deadlift',
        'fed-Romanian_Deadlift_from_Deficit',
      ],
    },
    {
      muscle: 'quads', tier: 'primary', fallbackPattern: 'squat',
      preferred: [
        'fed-Front_Barbell_Squat',
        'fed-Goblet_Squat',
        'fed-Dumbbell_Squat',
        'fed-Narrow_Stance_Leg_Press',
      ],
    },
    {
      muscle: 'hamstrings', tier: 'isolation', fallbackPattern: 'isolation_hamstring',
      preferred: ['fed-Seated_Leg_Curl', 'fed-Lying_Leg_Curls', 'fed-Ball_Leg_Curl'],
    },
    {
      muscle: 'glutes', tier: 'isolation', fallbackPattern: 'isolation_glute',
      preferred: ['fed-Glute_Kickback', 'fed-One-Legged_Cable_Kickback'],
    },
    {
      muscle: 'calves', tier: 'isolation', fallbackPattern: 'isolation_calf',
      preferred: [
        'fed-Barbell_Seated_Calf_Raise',
        'fed-Calf_Press',
        'fed-Dumbbell_Seated_One-Leg_Calf_Raise',
        'fed-Calf_Raises_-_With_Bands',
      ],
    },
  ],
};

/* -------------------------------------------------------------------------- */
/* UPPER                                                                      */
/* -------------------------------------------------------------------------- */

/** Upper A — push-heavy bias. */
const upperA: SessionTemplate = {
  key: 'upper_a',
  name: 'Üst Gövde A · İtiş Ağırlıklı',
  slots: [
    {
      muscle: 'chest', tier: 'primary', fallbackPattern: 'push_horizontal',
      preferred: [
        'fed-Barbell_Bench_Press_-_Medium_Grip',
        'fed-Dumbbell_Bench_Press',
        'fed-Leverage_Chest_Press',
        'fed-Pushups',
      ],
      required: true,
    },
    {
      muscle: 'back_lats', tier: 'primary', fallbackPattern: 'pull_vertical',
      preferred: [
        'fed-Pullups',
        'fed-Wide-Grip_Lat_Pulldown',
        'fed-Band_Assisted_Pull-Up',
      ],
      required: true,
    },
    {
      muscle: 'delts_front', tier: 'primary', fallbackPattern: 'push_vertical',
      preferred: [
        'fed-Seated_Dumbbell_Press',
        'fed-Dumbbell_Shoulder_Press',
        'fed-Standing_Military_Press',
      ],
    },
    {
      muscle: 'back_upper', tier: 'primary', fallbackPattern: 'pull_horizontal',
      preferred: [
        'fed-Bent_Over_Barbell_Row',
        'fed-Bent_Over_Two-Dumbbell_Row',
        'fed-Seated_Cable_Rows',
      ],
    },
    {
      muscle: 'delts_side', tier: 'isolation', fallbackPattern: 'isolation_delt_side',
      preferred: ['fed-Side_Lateral_Raise', 'fed-Cable_Seated_Lateral_Raise'],
    },
    {
      muscle: 'biceps', tier: 'isolation', fallbackPattern: 'isolation_bicep',
      preferred: ['fed-Barbell_Curl', 'fed-Dumbbell_Bicep_Curl', 'fed-Alternate_Hammer_Curl'],
    },
    {
      muscle: 'triceps', tier: 'isolation', fallbackPattern: 'isolation_tricep',
      preferred: ['fed-Triceps_Pushdown_-_Rope_Attachment', 'fed-Triceps_Pushdown', 'fed-Bench_Dips'],
    },
  ],
};

/** Upper B — pull-heavy bias. */
const upperB: SessionTemplate = {
  key: 'upper_b',
  name: 'Üst Gövde B · Çekiş Ağırlıklı',
  slots: [
    {
      muscle: 'back_lats', tier: 'primary', fallbackPattern: 'pull_vertical',
      preferred: [
        'fed-Chin-Up',
        'fed-Close-Grip_Front_Lat_Pulldown',
        'fed-Full_Range-Of-Motion_Lat_Pulldown',
        'fed-Band_Assisted_Pull-Up',
      ],
      required: true,
    },
    {
      muscle: 'chest', tier: 'primary', fallbackPattern: 'push_horizontal',
      preferred: [
        'fed-Barbell_Incline_Bench_Press_-_Medium_Grip',
        'fed-Incline_Dumbbell_Press',
        'fed-Leverage_Incline_Chest_Press',
      ],
      required: true,
    },
    {
      muscle: 'back_upper', tier: 'primary', fallbackPattern: 'pull_horizontal',
      preferred: [
        'fed-One-Arm_Dumbbell_Row',
        'fed-Seated_Cable_Rows',
        'fed-Lying_T-Bar_Row',
      ],
    },
    {
      muscle: 'delts_front', tier: 'primary', fallbackPattern: 'push_vertical',
      preferred: [
        'fed-Arnold_Dumbbell_Press',
        'fed-Dumbbell_Shoulder_Press',
        'fed-Seated_Dumbbell_Press',
      ],
    },
    {
      muscle: 'delts_rear', tier: 'isolation', fallbackPattern: 'isolation_delt_rear',
      preferred: ['fed-Face_Pull', 'fed-Reverse_Flyes', 'fed-Cable_Rear_Delt_Fly'],
    },
    {
      muscle: 'biceps', tier: 'isolation', fallbackPattern: 'isolation_bicep',
      preferred: ['fed-Preacher_Curl', 'fed-Incline_Dumbbell_Curl', 'fed-Cable_Preacher_Curl'],
    },
    {
      muscle: 'triceps', tier: 'isolation', fallbackPattern: 'isolation_tricep',
      preferred: [
        'fed-Cable_Rope_Overhead_Triceps_Extension',
        'fed-Lying_Triceps_Press',
        'fed-Standing_Overhead_Barbell_Triceps_Extension',
      ],
    },
  ],
};

/* -------------------------------------------------------------------------- */
/* LOWER                                                                      */
/* -------------------------------------------------------------------------- */

const lowerA: SessionTemplate = {
  key: 'lower_a',
  name: 'Alt Gövde A · Quad Ağırlıklı',
  slots: [
    {
      muscle: 'quads', tier: 'primary', fallbackPattern: 'squat',
      preferred: [
        'fed-Barbell_Squat',
        'fed-Leg_Press',
        'fed-Goblet_Squat',
        'fed-Dumbbell_Squat',
      ],
      required: true,
    },
    {
      muscle: 'hamstrings', tier: 'primary', fallbackPattern: 'hinge',
      preferred: ['fed-Romanian_Deadlift', 'fed-Romanian_Deadlift_from_Deficit'],
      required: true,
    },
    {
      muscle: 'quads', tier: 'secondary', fallbackPattern: 'lunge',
      preferred: [
        'fed-Dumbbell_Lunges',
        'fed-Barbell_Walking_Lunge',
        'fed-Bodyweight_Walking_Lunge',
      ],
    },
    {
      muscle: 'quads', tier: 'isolation', fallbackPattern: 'isolation_quad',
      preferred: ['fed-Leg_Extensions', 'fed-Single-Leg_Leg_Extension'],
    },
    {
      muscle: 'hamstrings', tier: 'isolation', fallbackPattern: 'isolation_hamstring',
      preferred: ['fed-Lying_Leg_Curls', 'fed-Seated_Leg_Curl'],
    },
    {
      muscle: 'calves', tier: 'isolation', fallbackPattern: 'isolation_calf',
      preferred: [
        'fed-Standing_Barbell_Calf_Raise',
        'fed-Calf_Press_On_The_Leg_Press_Machine',
      ],
    },
    {
      muscle: 'core', tier: 'isolation', fallbackPattern: 'core_brace',
      preferred: ['fed-Plank', 'fed-Pallof_Press', 'fed-Dead_Bug'],
    },
  ],
};

const lowerB: SessionTemplate = {
  key: 'lower_b',
  name: 'Alt Gövde B · Hinge Ağırlıklı',
  slots: [
    {
      muscle: 'glutes', tier: 'primary', fallbackPattern: 'hinge',
      preferred: [
        'fed-Barbell_Hip_Thrust',
        'fed-Barbell_Glute_Bridge',
        'fed-Single_Leg_Glute_Bridge',
      ],
      required: true,
    },
    {
      muscle: 'hamstrings', tier: 'primary', fallbackPattern: 'hinge',
      preferred: ['fed-Romanian_Deadlift', 'fed-Romanian_Deadlift_from_Deficit'],
      required: true,
    },
    {
      muscle: 'quads', tier: 'primary', fallbackPattern: 'squat',
      preferred: [
        'fed-Front_Barbell_Squat',
        'fed-Goblet_Squat',
        'fed-Dumbbell_Squat',
        'fed-Narrow_Stance_Leg_Press',
      ],
    },
    {
      muscle: 'hamstrings', tier: 'isolation', fallbackPattern: 'isolation_hamstring',
      preferred: ['fed-Seated_Leg_Curl', 'fed-Lying_Leg_Curls'],
    },
    {
      muscle: 'glutes', tier: 'isolation', fallbackPattern: 'isolation_glute',
      preferred: ['fed-Glute_Kickback', 'fed-One-Legged_Cable_Kickback'],
    },
    {
      muscle: 'calves', tier: 'isolation', fallbackPattern: 'isolation_calf',
      preferred: ['fed-Barbell_Seated_Calf_Raise', 'fed-Calf_Press'],
    },
    {
      muscle: 'core', tier: 'isolation', fallbackPattern: 'core_flexion',
      preferred: ['fed-Cable_Crunch', 'fed-Crunches', 'fed-Hanging_Leg_Raise'],
    },
  ],
};

/* -------------------------------------------------------------------------- */
/* FULL BODY                                                                  */
/* -------------------------------------------------------------------------- */

const fullA: SessionTemplate = {
  key: 'full_a',
  name: 'Full Body A · Squat & Bench Günü',
  slots: [
    {
      muscle: 'quads', tier: 'primary', fallbackPattern: 'squat',
      preferred: ['fed-Barbell_Squat', 'fed-Goblet_Squat', 'fed-Dumbbell_Squat', 'fed-Leg_Press'],
      required: true,
    },
    {
      muscle: 'chest', tier: 'primary', fallbackPattern: 'push_horizontal',
      preferred: [
        'fed-Barbell_Bench_Press_-_Medium_Grip',
        'fed-Dumbbell_Bench_Press',
        'fed-Pushups',
      ],
      required: true,
    },
    {
      muscle: 'back_upper', tier: 'primary', fallbackPattern: 'pull_horizontal',
      preferred: ['fed-Bent_Over_Barbell_Row', 'fed-Bent_Over_Two-Dumbbell_Row', 'fed-Seated_Cable_Rows'],
      required: true,
    },
    {
      muscle: 'hamstrings', tier: 'primary', fallbackPattern: 'hinge',
      preferred: ['fed-Romanian_Deadlift', 'fed-Barbell_Hip_Thrust'],
    },
    {
      muscle: 'delts_front', tier: 'secondary', fallbackPattern: 'push_vertical',
      preferred: ['fed-Seated_Dumbbell_Press', 'fed-Dumbbell_Shoulder_Press', 'fed-Standing_Military_Press'],
    },
    {
      muscle: 'biceps', tier: 'isolation', fallbackPattern: 'isolation_bicep',
      preferred: ['fed-Barbell_Curl', 'fed-Dumbbell_Bicep_Curl', 'fed-Alternate_Hammer_Curl'],
    },
    {
      muscle: 'core', tier: 'isolation', fallbackPattern: 'core_brace',
      preferred: ['fed-Plank', 'fed-Pallof_Press'],
    },
  ],
};

const fullB: SessionTemplate = {
  key: 'full_b',
  name: 'Full Body B · Hinge & OHP Günü',
  slots: [
    {
      muscle: 'hamstrings', tier: 'primary', fallbackPattern: 'hinge',
      preferred: ['fed-Romanian_Deadlift', 'fed-Barbell_Hip_Thrust'],
      required: true,
    },
    {
      muscle: 'back_lats', tier: 'primary', fallbackPattern: 'pull_vertical',
      preferred: ['fed-Pullups', 'fed-Chin-Up', 'fed-Wide-Grip_Lat_Pulldown', 'fed-Band_Assisted_Pull-Up'],
      required: true,
    },
    {
      muscle: 'delts_front', tier: 'primary', fallbackPattern: 'push_vertical',
      preferred: ['fed-Standing_Military_Press', 'fed-Seated_Dumbbell_Press', 'fed-Dumbbell_Shoulder_Press'],
      required: true,
    },
    {
      muscle: 'quads', tier: 'secondary', fallbackPattern: 'lunge',
      preferred: ['fed-Dumbbell_Lunges', 'fed-Barbell_Walking_Lunge', 'fed-Bodyweight_Walking_Lunge'],
    },
    {
      muscle: 'chest', tier: 'secondary', fallbackPattern: 'push_horizontal',
      preferred: ['fed-Incline_Dumbbell_Press', 'fed-Barbell_Incline_Bench_Press_-_Medium_Grip', 'fed-Incline_Push-Up'],
    },
    {
      muscle: 'triceps', tier: 'isolation', fallbackPattern: 'isolation_tricep',
      preferred: ['fed-Triceps_Pushdown', 'fed-Dumbbell_One-Arm_Triceps_Extension', 'fed-Bench_Dips'],
    },
    {
      muscle: 'core', tier: 'isolation', fallbackPattern: 'core_rotation',
      preferred: ['fed-Russian_Twist', 'fed-Cable_Russian_Twists', 'fed-Pallof_Press_With_Rotation'],
    },
  ],
};

/* -------------------------------------------------------------------------- */
/* Registry                                                                   */
/* -------------------------------------------------------------------------- */

export const SESSION_TEMPLATES: Record<string, SessionTemplate> = {
  push_a: pushA,
  push_b: pushB,
  pull_a: pullA,
  pull_b: pullB,
  legs_a: legsA,
  legs_b: legsB,
  upper_a: upperA,
  upper_b: upperB,
  lower_a: lowerA,
  lower_b: lowerB,
  full_a: fullA,
  full_b: fullB,
};

/**
 * Split patterns emit the ordered sequence of session template keys. When
 * the same *logical* day type repeats we alternate A/B so the week looks
 * like a coach planned it (PushA → Pull → Legs → PushB → Pull → Legs).
 */
export interface Split {
  id: string;
  label: string;
  days: string[]; // session template keys
}

export const SPLITS: Record<number, Split[]> = {
  2: [{ id: 'fb2', label: 'Full Body 2 gün', days: ['full_a', 'full_b'] }],
  3: [
    { id: 'ppl3', label: 'PPL 3 gün', days: ['push_a', 'pull_a', 'legs_a'] },
    { id: 'fb3', label: 'Full Body 3 gün', days: ['full_a', 'full_b', 'full_a'] },
  ],
  4: [
    { id: 'ul4', label: 'Upper/Lower 4 gün', days: ['upper_a', 'lower_a', 'upper_b', 'lower_b'] },
  ],
  5: [
    {
      id: 'ulppl5',
      label: 'U/L + PPL 5 gün',
      days: ['upper_a', 'lower_a', 'push_b', 'pull_b', 'legs_b'],
    },
  ],
  6: [
    {
      id: 'ppl6',
      label: 'PPL 6 gün',
      days: ['push_a', 'pull_a', 'legs_a', 'push_b', 'pull_b', 'legs_b'],
    },
  ],
};
