import type { FastifyInstance, FastifyRequest, preHandlerAsyncHookHandler } from 'fastify';
import fp from 'fastify-plugin';
import { AppError } from '../lib/errors.js';
import { verifyAccessToken, type AccessTokenPayload } from '../lib/tokens.js';

declare module 'fastify' {
  interface FastifyRequest {
    authUser?: AccessTokenPayload;
  }
  interface FastifyInstance {
    requireAuth: preHandlerAsyncHookHandler;
  }
}

async function authPlugin(app: FastifyInstance): Promise<void> {
  app.decorate('requireAuth', async (request: FastifyRequest) => {
    const header = request.headers.authorization;
    if (!header || !header.startsWith('Bearer ')) {
      throw AppError.unauthorized('Missing Bearer token');
    }
    const token = header.slice('Bearer '.length).trim();
    try {
      request.authUser = verifyAccessToken(token);
    } catch {
      throw AppError.unauthorized('Invalid or expired access token');
    }
  });
}

export default fp(authPlugin, { name: 'auth-plugin' });
