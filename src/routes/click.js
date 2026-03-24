import { normalizeRequest } from '../services/normalizer.js';
import { validateRequest } from '../services/validator.js';
import { feedManager } from '../services/feeds/feedManager.js';
import { selectWinner, categorizeResults } from '../services/auction.js';
import { applyMargin } from '../services/margin.js';
import { logTransaction } from '../services/logger.js';

export async function clickHandler(request, reply) {
  const requestStartTime = Date.now();

  try {
    const normalized = normalizeRequest(request);

    const validation = await validateRequest(normalized);

    if (!validation.valid) {
      const routerTimeMs = Date.now() - requestStartTime;

      await logTransaction(normalized, null, [], routerTimeMs, validation.reason);

      return reply.code(204).send();
    }

    const feedResults = await feedManager.fetchAllFeeds({
      publisherId: normalized.publisherId,
      subid: normalized.subid,
      country: normalized.country,
      device: normalized.device,
      ip: normalized.ip
    });

    const stats = categorizeResults(feedResults);

    const winner = selectWinner(feedResults);

    if (!winner) {
      const routerTimeMs = Date.now() - requestStartTime;

      await logTransaction(normalized, null, feedResults, routerTimeMs, 'no-fill');

      return reply.code(204).send();
    }

    const marginResult = await applyMargin(winner.payout, {
      country: normalized.country,
      partnerId: winner.partnerId,
      publisherId: normalized.publisherId
    });

    const enrichedWinner = {
      ...winner,
      rawPayout: marginResult.rawPayout,
      marginApplied: marginResult.marginApplied,
      netPayout: marginResult.netPayout
    };

    const routerTimeMs = Date.now() - requestStartTime;

    await logTransaction(normalized, enrichedWinner, feedResults, routerTimeMs, 'fill');

    return reply.redirect(302, enrichedWinner.redirectUrl);

  } catch (error) {
    console.error('Error in click handler:', error);

    const routerTimeMs = Date.now() - requestStartTime;

    try {
      const normalized = normalizeRequest(request);
      await logTransaction(normalized, null, [], routerTimeMs, 'error');
    } catch (logError) {
      console.error('Error logging transaction:', logError);
    }

    return reply.code(500).send({ error: 'Internal server error' });
  }
}
