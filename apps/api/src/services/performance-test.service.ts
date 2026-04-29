import type { PerformanceTestResult, PerformanceTestType } from '@prisma/client';
import { prisma } from '../lib/prisma.js';

export interface CreatePerformanceTestInput {
  type: PerformanceTestType;
  value: number;
  unit: string;
  testedAt?: Date;
  notes?: string | null;
}

export const performanceTestService = {
  async create(playerId: string, input: CreatePerformanceTestInput): Promise<PerformanceTestResult> {
    return prisma.performanceTestResult.create({
      data: {
        playerId,
        type: input.type,
        value: input.value,
        unit: input.unit,
        testedAt: input.testedAt ?? new Date(),
        notes: input.notes ?? null,
      },
    });
  },

  async list(
    playerId: string,
    filter: { type?: PerformanceTestType },
  ): Promise<PerformanceTestResult[]> {
    return prisma.performanceTestResult.findMany({
      where: { playerId, ...(filter.type ? { type: filter.type } : {}) },
      orderBy: { testedAt: 'desc' },
    });
  },
};
