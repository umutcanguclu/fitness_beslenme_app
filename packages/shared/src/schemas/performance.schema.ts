import { z } from 'zod';
import { PerformanceTestTypeSchema } from './enums.schema.js';

export const PerformanceTestResultSchema = z.object({
  id: z.string().uuid(),
  playerId: z.string().uuid(),
  type: PerformanceTestTypeSchema,
  value: z.number(),
  unit: z.string().min(1).max(16),
  testedAt: z.coerce.date(),
  notes: z.string().max(500).nullable().optional(),
});
export type PerformanceTestResult = z.infer<typeof PerformanceTestResultSchema>;

export const RecordPerformanceTestInputSchema = PerformanceTestResultSchema.omit({
  id: true,
  testedAt: true,
}).extend({
  testedAt: z.coerce.date().optional(),
});
export type RecordPerformanceTestInput = z.infer<typeof RecordPerformanceTestInputSchema>;
