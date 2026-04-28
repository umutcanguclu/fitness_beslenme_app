import type { Locale, PrismaClient, User, UserRole } from '@prisma/client';
import { prisma } from '../lib/prisma.js';

export interface CreateUserInput {
  email: string;
  passwordHash: string;
  fullName: string;
  role: UserRole;
  locale?: Locale;
  phone?: string;
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
        fullName: input.fullName,
        role: input.role,
        locale: input.locale ?? 'tr',
        phone: input.phone,
      },
    });
  }
}

export const userRepository = new UserRepository();
