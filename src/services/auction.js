export function selectWinner(feedResults) {
  const validOffers = feedResults.filter(result =>
    result.fill === true &&
    result.payout > 0 &&
    result.redirectUrl
  );

  if (validOffers.length === 0) {
    return null;
  }

  validOffers.sort((a, b) => b.payout - a.payout);

  return validOffers[0];
}

export function categorizeResults(feedResults) {
  const fills = feedResults.filter(r => r.fill === true);
  const noFills = feedResults.filter(r => r.fill === false && !r.error);
  const errors = feedResults.filter(r => r.error);
  const timeouts = feedResults.filter(r => r.error === 'timeout');

  return {
    fills,
    noFills,
    errors,
    timeouts,
    totalAttempts: feedResults.length,
    fillRate: fills.length / feedResults.length
  };
}
