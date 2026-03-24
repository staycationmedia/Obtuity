import { testConnection } from '../config/database.js';
import { feedManager } from '../services/feeds/feedManager.js';

export async function healthHandler(request, reply) {
  const health = {
    status: 'ok',
    timestamp: new Date().toISOString(),
    uptime: process.uptime(),
    database: 'unknown',
    feeds: 0
  };

  try {
    const dbConnected = await testConnection();
    health.database = dbConnected ? 'connected' : 'disconnected';

    if (!dbConnected) {
      health.status = 'degraded';
    }

    health.feeds = feedManager.feeds.length;

    if (health.feeds === 0) {
      health.status = 'degraded';
      health.warning = 'No active feeds loaded';
    }

    const statusCode = health.status === 'ok' ? 200 : 503;

    return reply.code(statusCode).send(health);

  } catch (error) {
    health.status = 'error';
    health.error = error.message;
    return reply.code(503).send(health);
  }
}

export async function reloadFeedsHandler(request, reply) {
  try {
    await feedManager.reloadFeeds();

    return reply.send({
      status: 'success',
      message: 'Feeds reloaded',
      count: feedManager.feeds.length
    });
  } catch (error) {
    return reply.code(500).send({
      status: 'error',
      message: error.message
    });
  }
}
