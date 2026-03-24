-- Daily Analysis Queries for XML Pop Arbitrage Router
-- Run these queries daily to optimize margins and performance

-- 1. FILL RATE BY PARTNER (Last 24 Hours)
-- Shows which feeds are performing best
SELECT
  p.name as partner_name,
  COUNT(*) as total_attempts,
  SUM(CASE WHEN fa.fill THEN 1 ELSE 0 END) as fills,
  ROUND(AVG(CASE WHEN fa.fill THEN 1.0 ELSE 0.0 END) * 100, 2) as fill_rate_percent,
  ROUND(AVG(fa.response_time_ms), 2) as avg_response_time_ms,
  ROUND(AVG(fa.payout), 4) as avg_payout,
  ROUND(SUM(fa.payout), 2) as total_revenue
FROM feed_attempts fa
JOIN partners p ON fa.partner_id = p.id
WHERE fa.created_at >= NOW() - INTERVAL '1 day'
GROUP BY p.id, p.name
ORDER BY fill_rate_percent DESC;

-- 2. REVENUE BY GEO (Last 24 Hours)
-- Identify most profitable geos
SELECT
  country,
  COUNT(*) as total_requests,
  SUM(CASE WHEN outcome = 'fill' THEN 1 ELSE 0 END) as fills,
  ROUND(AVG(CASE WHEN outcome = 'fill' THEN 1.0 ELSE 0.0 END) * 100, 2) as fill_rate_percent,
  ROUND(SUM(raw_payout), 2) as gross_revenue,
  ROUND(SUM(margin_applied), 2) as total_margin,
  ROUND(SUM(net_payout), 2) as net_revenue,
  ROUND(AVG(router_time_ms), 2) as avg_latency_ms
FROM clicks
WHERE timestamp >= NOW() - INTERVAL '1 day'
GROUP BY country
ORDER BY net_revenue DESC
LIMIT 20;

-- 3. PUBLISHER PERFORMANCE (Last 24 Hours)
-- Monitor publisher quality and revenue
SELECT
  pub.name as publisher_name,
  COUNT(*) as total_requests,
  SUM(CASE WHEN c.outcome = 'fill' THEN 1 ELSE 0 END) as fills,
  ROUND(AVG(CASE WHEN c.outcome = 'fill' THEN 1.0 ELSE 0.0 END) * 100, 2) as fill_rate_percent,
  ROUND(AVG(c.router_time_ms), 2) as avg_latency_ms,
  ROUND(SUM(c.net_payout), 2) as net_revenue,
  ROUND(AVG(c.net_payout), 4) as avg_net_payout
FROM clicks c
JOIN publishers pub ON c.publisher_id = pub.id
WHERE c.timestamp >= NOW() - INTERVAL '1 day'
GROUP BY pub.id, pub.name
ORDER BY net_revenue DESC;

-- 4. HOURLY TRENDS (Last 24 Hours)
-- Understand traffic patterns
SELECT
  DATE_TRUNC('hour', timestamp) as hour,
  COUNT(*) as requests,
  SUM(CASE WHEN outcome = 'fill' THEN 1 ELSE 0 END) as fills,
  ROUND(AVG(CASE WHEN outcome = 'fill' THEN 1.0 ELSE 0.0 END) * 100, 2) as fill_rate_percent,
  ROUND(SUM(net_payout), 2) as revenue
FROM clicks
WHERE timestamp >= NOW() - INTERVAL '1 day'
GROUP BY hour
ORDER BY hour DESC;

-- 5. SUBID PERFORMANCE (Last 7 Days)
-- Identify low-quality subids for blacklisting
SELECT
  publisher_id,
  subid,
  COUNT(*) as requests,
  SUM(CASE WHEN outcome = 'fill' THEN 1 ELSE 0 END) as fills,
  ROUND(AVG(CASE WHEN outcome = 'fill' THEN 1.0 ELSE 0.0 END) * 100, 2) as fill_rate_percent,
  ROUND(SUM(net_payout), 2) as revenue,
  ROUND(AVG(net_payout), 4) as avg_revenue
FROM clicks
WHERE timestamp >= NOW() - INTERVAL '7 days'
  AND subid IS NOT NULL
  AND subid != ''
GROUP BY publisher_id, subid
HAVING COUNT(*) >= 100
ORDER BY fill_rate_percent ASC, requests DESC
LIMIT 50;

-- 6. FEED RESPONSE TIME ANALYSIS (Last 24 Hours)
-- Identify slow or timing out feeds
SELECT
  p.name as partner_name,
  COUNT(*) as attempts,
  ROUND(AVG(fa.response_time_ms), 2) as avg_response_ms,
  ROUND(MIN(fa.response_time_ms), 2) as min_response_ms,
  ROUND(MAX(fa.response_time_ms), 2) as max_response_ms,
  SUM(CASE WHEN fa.error = 'timeout' THEN 1 ELSE 0 END) as timeouts,
  ROUND(AVG(CASE WHEN fa.error = 'timeout' THEN 1.0 ELSE 0.0 END) * 100, 2) as timeout_rate_percent
FROM feed_attempts fa
JOIN partners p ON fa.partner_id = p.id
WHERE fa.created_at >= NOW() - INTERVAL '1 day'
GROUP BY p.id, p.name
ORDER BY timeout_rate_percent DESC;

-- 7. MARGIN RULE EFFECTIVENESS (Last 7 Days)
-- Analyze which margin rules are most profitable
SELECT
  country,
  winner_partner_id,
  COUNT(*) as fills,
  ROUND(AVG(raw_payout), 4) as avg_raw_payout,
  ROUND(AVG(margin_applied), 4) as avg_margin,
  ROUND(AVG(net_payout), 4) as avg_net_payout,
  ROUND(AVG(margin_applied / NULLIF(raw_payout, 0) * 100), 2) as effective_margin_percent,
  ROUND(SUM(net_payout), 2) as total_net_revenue
FROM clicks
WHERE timestamp >= NOW() - INTERVAL '7 days'
  AND outcome = 'fill'
GROUP BY country, winner_partner_id
ORDER BY total_net_revenue DESC
LIMIT 30;

-- 8. NO-FILL ANALYSIS (Last 24 Hours)
-- Understand why traffic isn't filling
SELECT
  outcome,
  COUNT(*) as count,
  ROUND(AVG(router_time_ms), 2) as avg_latency_ms,
  country,
  device
FROM clicks
WHERE timestamp >= NOW() - INTERVAL '1 day'
  AND outcome != 'fill'
GROUP BY outcome, country, device
ORDER BY count DESC
LIMIT 50;

-- 9. WINNING PARTNER DISTRIBUTION (Last 24 Hours)
-- See which partners are winning most auctions
SELECT
  p.name as partner_name,
  COUNT(*) as wins,
  ROUND(AVG(c.raw_payout), 4) as avg_winning_payout,
  ROUND(SUM(c.net_payout), 2) as total_revenue,
  ROUND(AVG(c.router_time_ms), 2) as avg_latency_ms
FROM clicks c
JOIN partners p ON c.winner_partner_id = p.id
WHERE c.timestamp >= NOW() - INTERVAL '1 day'
  AND c.outcome = 'fill'
GROUP BY p.id, p.name
ORDER BY wins DESC;

-- 10. BLACKLIST EFFECTIVENESS (Since Blacklisted)
-- Monitor blocked traffic volume
SELECT
  b.publisher_id,
  b.subid,
  b.reason,
  b.created_at as blacklisted_at,
  COUNT(c.id) as blocked_requests
FROM blacklist_subids b
LEFT JOIN clicks c ON c.publisher_id = b.publisher_id
  AND c.subid = b.subid
  AND c.timestamp >= b.created_at
  AND c.outcome = 'blacklist'
GROUP BY b.id, b.publisher_id, b.subid, b.reason, b.created_at
ORDER BY blocked_requests DESC;

-- 11. DAILY SPREAD SUMMARY (Last 7 Days)
-- High-level profitability overview
SELECT
  DATE(timestamp) as date,
  COUNT(*) as total_requests,
  SUM(CASE WHEN outcome = 'fill' THEN 1 ELSE 0 END) as fills,
  ROUND(AVG(CASE WHEN outcome = 'fill' THEN 1.0 ELSE 0.0 END) * 100, 2) as fill_rate_percent,
  ROUND(SUM(raw_payout), 2) as gross_revenue,
  ROUND(SUM(margin_applied), 2) as margin_captured,
  ROUND(SUM(net_payout), 2) as net_revenue,
  ROUND(AVG(margin_applied / NULLIF(raw_payout, 0) * 100), 2) as avg_margin_percent
FROM clicks
WHERE timestamp >= NOW() - INTERVAL '7 days'
GROUP BY DATE(timestamp)
ORDER BY date DESC;

-- 12. GEO + PARTNER COMBINATIONS (Last 7 Days)
-- Identify best geo-partner combinations for targeted margins
SELECT
  c.country,
  p.name as partner_name,
  COUNT(*) as fills,
  ROUND(AVG(c.raw_payout), 4) as avg_payout,
  ROUND(SUM(c.net_payout), 2) as total_revenue,
  ROUND(AVG(c.margin_applied / NULLIF(c.raw_payout, 0) * 100), 2) as current_margin_percent
FROM clicks c
JOIN partners p ON c.winner_partner_id = p.id
WHERE c.timestamp >= NOW() - INTERVAL '7 days'
  AND c.outcome = 'fill'
GROUP BY c.country, p.id, p.name
HAVING COUNT(*) >= 50
ORDER BY total_revenue DESC
LIMIT 30;
