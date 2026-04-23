import type { Locale, PrismaClient, User } from '@prisma/client';
import { prisma } from '../lib/prisma.js';

export interface CreateUserInput {
  email: string;
  passwordHash: string;
  name: string;
  locale?: Locale;
}

export class UserRepository {
  constructor(private readonly db: PrismaClient = prisma) {}

  findByEmail(email: string): Promise<User | null> {
    return this.db.user.findUnique({ where: { email: email.toLowerCase() } });
  }

  findById(id: string): Promise<User | null> {
    return this.db.user.findUnique({ where: { id } });
  }

  create(input: CreateUserInput): Promise<User> {
    return this.db.user.create({
      data: {
        email: input.email.toLowerCase(),
        passwordHash: input.passwordHash,
        name: input.name,
        locale: input.locale ?? 'en',
      },
    });
  }
}

export const userRepository = new UserRepository();
