import { beforeEach, describe, expect, it, vi } from 'vitest';
import { WorkoutService } from '../../src/services/workout.service.js';
import type { Workout, WorkoutSet } from '@prisma/client';

function workout(overrides: Partial<Workout> = {}): Workout & { sets: WorkoutSet[] } {
  return {
    id: 'w-1',
    userId: 'user-1',
    templateId: null,
    name: null,
    notes: null,
    startedAt: new Date('2026-01-01'),
    finishedAt: null,
    createdAt: new Date('2026-01-01'),
    sets: [],
    ...overrides,
  };
}

function stubRepo() {
  return {
    list: vi.fn(),
    findById: vi.fn(),
    start: vi.fn(),
    update: vi.fn(),
    delete: vi.fn(),
    nextSetOrder: vi.fn(),
    addSet: vi.fn(),
  };
}

describe('WorkoutService', () => {
  beforeEach(() => vi.clearAllMocks());

  it('list — splits page and returns nextCursor when there is more', async () => {
    const repo = stubRepo();
    const items = Array.from({ length: 3 }, (_, i) => workout({ id: `w-${i}` }));
    repo.list.mockResolvedValue(items); // limit 2 → 3 items means hasMore
    const service = new WorkoutService(repo as never);
    const result = await service.list('user-1', 2);
    expect(result.items).toHaveLength(2);
    expect(result.nextCursor).toBe('w-1');
  });

  it('list — null cursor when no more pages', async () => {
    const repo = stubRepo();
    repo.list.mockResolvedValue([workout()]);
    const service = new WorkoutService(repo as never);
    const result = await service.list('user-1', 20);
    expect(result.items).toHaveLength(1);
    expect(result.nextCursor).toBeNull();
  });

  it('get — throws 404 when workout missing', async () => {
    const repo = stubRepo();
    repo.findById.mockResolvedValue(null);
    const service = new WorkoutService(repo as never);
    await expect(service.get('w-1', 'user-1')).rejects.toMatchObject({
      code: 'NOT_FOUND',
    });
  });

  it('finish — sets finishedAt on update', async () => {
    const repo = stubRepo();
    repo.findById.mockResolvedValue(workout());
    repo.update.mockImplementation(async (_id, _userId, data) => ({ ...workout(), ...data }));
    const service = new WorkoutService(repo as never);
    await service.finish('w-1', 'user-1', {});
    const payload = repo.update.mock.calls[0][2];
    expect(payload.finishedAt).toBeInstanceOf(Date);
  });

  it('addSet — auto-assigns order from nextSetOrder when omitted', async () => {
    const repo = stubRepo();
    repo.findById.mockResolvedValue(workout());
    repo.nextSetOrder.mockResolvedValue(3);
    repo.addSet.mockResolvedValue({ id: 'set-1' } as never);
    const service = new WorkoutService(repo as never);
    await service.addSet('w-1', 'user-1', { exerciseId: 'x', weightKg: 60, reps: 5 });
    expect(repo.addSet.mock.calls[0][0].order).toBe(3);
  });
});
