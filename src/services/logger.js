import { supabase } from '../config/database.js';

export async function logClick(clickData) {
  const { data, error } = await supabase
    .from('clicks')
    .insert([{
      publisher_id: clickData.publisherId,
      subid: clickData.subid,
      ip_hash: clickData.ipHash,
      country: clickData.country,
      device: clickData.device,
      user_agent: clickData.userAgent,
      winner_partner_id: clickData.winnerPartnerId,
      raw_payout: clickData.rawPayout,
      margin_applied: clickData.marginApplied,
      net_payout: clickData.netPayout,
      outcome: clickData.outcome,
      router_time_ms: clickData.routerTimeMs,
      redirect_url: clickData.redirectUrl
    }])
    .select()
    .single();

  if (error) {
    console.error('Error logging click:', error);
    return null;
  }

  return data;
}

export async function logFeedAttempts(clickId, feedResults) {
  const attempts = feedResults.map(result => ({
    click_id: clickId,
    partner_id: result.partnerId,
    response_time_ms: result.responseTimeMs,
    payout: result.payout || null,
    fill: result.fill,
    error: result.error
  }));

  const { error } = await supabase
    .from('feed_attempts')
    .insert(attempts);

  if (error) {
    console.error('Error logging feed attempts:', error);
  }
}

export async function logTransaction(normalized, winner, feedResults, routerTimeMs, outcome) {
  const clickData = {
    publisherId: normalized.publisherId,
    subid: normalized.subid,
    ipHash: normalized.ipHash,
    country: normalized.country,
    device: normalized.device,
    userAgent: normalized.userAgent,
    winnerPartnerId: winner?.partnerId || null,
    rawPayout: winner?.rawPayout || null,
    marginApplied: winner?.marginApplied || null,
    netPayout: winner?.netPayout || null,
    outcome: outcome,
    routerTimeMs: routerTimeMs,
    redirectUrl: winner?.redirectUrl || null
  };

  const click = await logClick(clickData);

  if (click && feedResults.length > 0) {
    await logFeedAttempts(click.id, feedResults);
  }

  return click;
}
