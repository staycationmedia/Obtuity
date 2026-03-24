import { fetch, Headers, Request, Response } from 'undici';

globalThis.fetch = fetch;
globalThis.Headers = Headers;
globalThis.Request = Request;
globalThis.Response = Response;
import Fastify from 'fastify';
import cors from '@fastify/cors';
import rateLimit from '@fastify/rate-limit';
import dotenv from 'dotenv';
import { testConnection } from './config/database.js';
import { feedManager } from './services/feeds/feedManager.js';
import { clickHandler } from './routes/click.js';
import { healthHandler, reloadFeedsHandler } from './routes/health.js';

dotenv.config();

const PORT = process.env.PORT || 3000;
const HOST = process.env.HOST || '0.0.0.0';

const fastify = Fastify({
  logger: {
    transport: {
      target: 'pino-pretty',
      options: {
        translateTime: 'HH:MM:ss Z',
        ignore: 'pid,hostname'
      }
    }
  },
  trustProxy: true
});

await fastify.register(cors, {
  origin: '*'
});

await fastify.register(rateLimit, {
  max: 100,
  timeWindow: '1 minute',
  errorResponseBuilder: function (request, context) {
    return {
      code: 429,
      error: 'Too Many Requests',
      message: `Rate limit exceeded. Try again in ${context.after}`
    };
  }
});

fastify.get('/click', clickHandler);

fastify.get('/health', healthHandler);

fastify.post('/admin/reload-feeds', reloadFeedsHandler);

fastify.get('/', async (request, reply) => {
  return {
    service: 'XML Pop Arbitrage Router',
    version: '1.0.0',
    endpoints: {
      click: '/click?pub=123&subid=abc',
      health: '/health',
      reloadFeeds: '/admin/reload-feeds'
    }
  };
});

async function start() {
  try {
    console.log('Starting XML Pop Arbitrage Router...');

    const dbConnected = await testConnection();
    if (!dbConnected) {
      console.error('Failed to connect to database');
      process.exit(1);
    }
    console.log('Database connected');

    await feedManager.loadFeeds();
    console.log(`Loaded ${feedManager.feeds.length} active feeds`);

    await fastify.listen({ port: PORT, host: HOST });

    console.log(`Server listening on ${HOST}:${PORT}`);
    console.log(`Health check: http://${HOST}:${PORT}/health`);
    console.log(`Click endpoint: http://${HOST}:${PORT}/click?pub=123&subid=abc`);

  } catch (err) {
    fastify.log.error(err);
    process.exit(1);
  }
}

if (process.env.VERCEL !== '1') {
  start();
}

export default async function handler(req, res) {
  await fastify.ready();
  fastify.server.emit('request', req, res);
}
