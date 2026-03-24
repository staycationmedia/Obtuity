# Manual Optimization Guide (First 30 Days)

This guide outlines the daily manual optimization process for the first 30 days of operation.

## Philosophy

**DO NOT automate anything in the first 30 days.**

This period is for learning:
- Which geos are profitable
- Which partners perform best
- What margins the market will bear
- Publisher quality patterns
- Subid quality indicators

Only after 30 days of stable positive spread and clean reconciliation should you consider automation.

## Daily Routine

### Morning (9 AM)

Run these analysis queries for previous day's data.

#### 1. Overall Performance

```sql
-- Yesterday's summary
SELECT
  COUNT(*) as total_requests,
  SUM(CASE WHEN outcome = 'fill' THEN 1 ELSE 0 END) as fills,
  ROUND(AVG(CASE WHEN outcome = 'fill' THEN 1.0 ELSE 0.0 END) * 100, 2) as fill_rate,
  ROUND(SUM(raw_payout), 2) as gross_revenue,
  ROUND(SUM(margin_applied), 2) as margin,
  ROUND(SUM(net_payout), 2) as net_revenue,
  ROUND(AVG(margin_applied / NULLIF(raw_payout, 0) * 100), 2) as avg_margin_pct
FROM clicks
WHERE timestamp >= CURRENT_DATE - INTERVAL '1 day'
  AND timestamp < CURRENT_DATE;
```

**Action Items:**
- Record these numbers in spreadsheet
- Compare to previous days
- Note any significant changes

#### 2. Feed Performance

```sql
-- Partner fill rates and revenue
SELECT
  p.name,
  COUNT(*) as attempts,
  SUM(CASE WHEN fa.fill THEN 1 ELSE 0 END) as fills,
  ROUND(AVG(CASE WHEN fa.fill THEN 1.0 ELSE 0.0 END) * 100, 2) as fill_rate,
  ROUND(AVG(fa.response_time_ms), 2) as avg_response_ms,
  ROUND(AVG(fa.payout), 4) as avg_payout,
  SUM(CASE WHEN fa.error = 'timeout' THEN 1 ELSE 0 END) as timeouts
FROM feed_attempts fa
JOIN partners p ON fa.partner_id = p.id
WHERE fa.created_at >= CURRENT_DATE - INTERVAL '1 day'
  AND fa.created_at < CURRENT_DATE
GROUP BY p.id, p.name;
```

**Action Items:**
- If fill rate < 20%: Investigate partner endpoint
- If avg_response_ms > 200ms: Consider lowering timeout
- If timeouts > 30%: Contact partner or increase timeout
- Note which partner has highest avg_payout

#### 3. Geo Performance

```sql
-- Revenue by country
SELECT
  country,
  COUNT(*) as requests,
  SUM(CASE WHEN outcome = 'fill' THEN 1 ELSE 0 END) as fills,
  ROUND(SUM(raw_payout), 2) as gross,
  ROUND(SUM(margin_applied), 2) as margin,
  ROUND(SUM(net_payout), 2) as net,
  ROUND(AVG(margin_applied / NULLIF(raw_payout, 0) * 100), 2) as margin_pct
FROM clicks
WHERE timestamp >= CURRENT_DATE - INTERVAL '1 day'
  AND timestamp < CURRENT_DATE
  AND outcome = 'fill'
GROUP BY country
ORDER BY net DESC
LIMIT 20;
```

**Action Items:**
- Identify top 5 profitable geos
- Check if high-volume geos have low margins
- Consider increasing margins on high-performing geos

### Afternoon (2 PM)

#### 4. Margin Adjustment Decision Matrix

Use this decision tree:

**High Volume + High Fill Rate + Good Revenue**
→ Increase margin by 2-5%

**High Volume + Low Fill Rate**
→ Investigate feed issues, don't adjust margin yet

**Low Volume + High Payout**
→ Monitor, consider decreasing margin to increase volume

**Any Geo with > 10% more revenue than others**
→ Increase margin by 5-10%

#### 5. Execute Margin Adjustments

Example: Increase US margin for Partner 1

```sql
-- Check current margin
SELECT * FROM rules_margins
WHERE rule_type = 'geo+partner' AND geo = 'US' AND partner_id = 1;

-- Update margin (if exists)
UPDATE rules_margins
SET margin_percent = 22.00
WHERE rule_type = 'geo+partner' AND geo = 'US' AND partner_id = 1;

-- Or insert new rule (if doesn't exist)
INSERT INTO rules_margins (rule_type, geo, partner_id, margin_percent, priority, active)
VALUES ('geo+partner', 'US', 1, 22.00, 100, true);
```

Example: Adjust global margin

```sql
UPDATE rules_margins
SET margin_percent = 12.00
WHERE rule_type = 'global';
```

#### 6. Check for Low-Quality Subids

```sql
-- Subids with low fill rates (last 3 days)
SELECT
  publisher_id,
  subid,
  COUNT(*) as requests,
  SUM(CASE WHEN outcome = 'fill' THEN 1 ELSE 0 END) as fills,
  ROUND(AVG(CASE WHEN outcome = 'fill' THEN 1.0 ELSE 0.0 END) * 100, 2) as fill_rate,
  ROUND(SUM(net_payout), 2) as revenue
FROM clicks
WHERE timestamp >= CURRENT_DATE - INTERVAL '3 days'
  AND subid IS NOT NULL
  AND subid != ''
GROUP BY publisher_id, subid
HAVING COUNT(*) >= 100
  AND ROUND(AVG(CASE WHEN outcome = 'fill' THEN 1.0 ELSE 0.0 END) * 100, 2) < 10
ORDER BY requests DESC;
```

**Action Items:**
- Blacklist subids with < 10% fill rate and > 100 requests

```sql
INSERT INTO blacklist_subids (publisher_id, subid, reason)
VALUES (1, 'bad-source-1', 'Fill rate < 10% over 3 days');
```

### Evening (6 PM)

#### 7. Check Impact of Changes

Compare afternoon performance to morning baseline:

```sql
-- Today's hourly performance
SELECT
  DATE_TRUNC('hour', timestamp) as hour,
  COUNT(*) as requests,
  SUM(CASE WHEN outcome = 'fill' THEN 1 ELSE 0 END) as fills,
  ROUND(SUM(net_payout), 2) as revenue,
  ROUND(AVG(margin_applied / NULLIF(raw_payout, 0) * 100), 2) as margin_pct
FROM clicks
WHERE timestamp >= CURRENT_DATE
GROUP BY hour
ORDER BY hour;
```

**Action Items:**
- Note if margin changes affected fill rate
- If fill rate dropped > 5%, consider reverting margin increase

## Weekly Review (Every Monday)

### 1. Week-over-Week Trends

```sql
-- Last 7 days summary by day
SELECT
  DATE(timestamp) as date,
  COUNT(*) as requests,
  SUM(CASE WHEN outcome = 'fill' THEN 1 ELSE 0 END) as fills,
  ROUND(SUM(net_payout), 2) as revenue,
  ROUND(AVG(margin_applied / NULLIF(raw_payout, 0) * 100), 2) as avg_margin
FROM clicks
WHERE timestamp >= CURRENT_DATE - INTERVAL '7 days'
GROUP BY DATE(timestamp)
ORDER BY date;
```

**Action Items:**
- Identify day-of-week patterns
- Note any declining trends
- Celebrate improvements

### 2. Publisher Review

```sql
-- Publisher performance last 7 days
SELECT
  pub.name,
  COUNT(*) as requests,
  ROUND(AVG(CASE WHEN c.outcome = 'fill' THEN 1.0 ELSE 0.0 END) * 100, 2) as fill_rate,
  ROUND(SUM(c.net_payout), 2) as revenue,
  ROUND(AVG(c.net_payout), 4) as avg_revenue_per_fill
FROM clicks c
JOIN publishers pub ON c.publisher_id = pub.id
WHERE c.timestamp >= CURRENT_DATE - INTERVAL '7 days'
GROUP BY pub.id, pub.name
ORDER BY revenue DESC;
```

**Action Items:**
- Contact publishers with declining fill rates
- Negotiate better rates with high-volume publishers
- Consider pausing low-performing publishers

### 3. Feed Reconciliation

Compare your logged revenue with partner reporting:

```sql
-- Your view of partner revenue (last 7 days)
SELECT
  p.name,
  COUNT(*) as your_fill_count,
  ROUND(SUM(c.raw_payout), 2) as your_total_revenue
FROM clicks c
JOIN partners p ON c.winner_partner_id = p.id
WHERE c.timestamp >= CURRENT_DATE - INTERVAL '7 days'
  AND c.outcome = 'fill'
GROUP BY p.id, p.name;
```

**Action Items:**
- Compare to partner's reporting dashboard
- Investigate any > 5% discrepancies
- Check for click ID mismatches
- Verify payout parsing accuracy

## Optimization Levers

### Margin Adjustments

**When to Increase:**
- High volume + stable fill rate
- Geo consistently outperforms others
- Partner has monopoly on certain geos
- Publisher sending premium traffic

**When to Decrease:**
- Fill rate declining
- Testing new geo/partner combination
- Publisher threatening to leave
- Trying to gain market share

**How Much:**
- Start with 2-5% adjustments
- Never adjust more than 10% at once
- Wait 24 hours to measure impact
- Document reasoning in spreadsheet

### Timeout Adjustments

**When to Increase:**
- Partner has high payouts but frequent timeouts
- Only during low-traffic hours initially
- After confirming partner latency issue is temporary

**When to Decrease:**
- Partner consistently responds quickly
- Need to improve overall latency
- Testing faster partner priority

### Blacklisting

**Aggressive Blacklisting (first 14 days):**
- < 5% fill rate after 100+ requests
- Suspected fraud patterns
- Subid sending only certain geos

**Conservative Blacklisting (days 15-30):**
- < 2% fill rate after 500+ requests
- Confirmed fraud with publisher
- Repeated pattern of no-fills

## Tracking Spreadsheet

Create a Google Sheet with these tabs:

### Daily Summary
| Date | Requests | Fills | Fill Rate | Gross | Margin | Net | Avg Margin % |
|------|----------|-------|-----------|-------|--------|-----|--------------|
| ... | ... | ... | ... | ... | ... | ... | ... |

### Margin Changes Log
| Date | Rule Type | Geo | Partner | Old % | New % | Reason |
|------|-----------|-----|---------|-------|-------|--------|
| ... | ... | ... | ... | ... | ... | ... |

### Blacklist Log
| Date | Publisher | Subid | Reason | Requests Before |
|------|-----------|-------|--------|----------------|
| ... | ... | ... | ... | ... |

### Partner Performance
| Date | Partner | Attempts | Fills | Fill Rate | Avg Payout | Timeouts |
|------|---------|----------|-------|-----------|------------|----------|
| ... | ... | ... | ... | ... | ... | ... |

### Geo Performance
| Date | Geo | Requests | Fills | Fill Rate | Net Revenue | Margin % |
|------|-----|----------|-------|-----------|-------------|----------|
| ... | ... | ... | ... | ... | ... | ... |

## Red Flags

Stop and investigate if:

- Fill rate drops > 10% day-over-day
- Any partner has 0 fills for > 2 hours during peak traffic
- Margin capture rate drops below 5%
- Net revenue negative for any day
- Database logging stops (check disk space)
- Feed response times increase > 50%
- Any publisher sending > 50% of traffic from one subid

## Success Metrics (30-day targets)

- Overall fill rate: > 40%
- Average margin capture: > 10%
- Net positive revenue: every day
- Reconciliation accuracy: > 95% with all partners
- Publisher retention: > 90%
- Feed timeout rate: < 10%

## After 30 Days

Once you hit these targets consistently:

1. Document your optimal margin ranges by geo
2. Document optimal timeout values per partner
3. Identify patterns that could be automated
4. Consider implementing:
   - Auto-throttling of low-quality subids
   - Dynamic margin adjustments (with caps)
   - Auto-alerting for anomalies
   - A/B testing framework

But remember: Automation should enhance manual control, not replace it.

## Tools

### Quick Margin Check Script

Create `check-margins.sh`:

```bash
#!/bin/bash
psql $DATABASE_URL -c "
SELECT
  rule_type,
  COALESCE(geo, 'ALL') as geo,
  COALESCE(partner_id::text, 'ALL') as partner,
  margin_percent,
  priority
FROM rules_margins
WHERE active = true
ORDER BY priority DESC;
"
```

### Quick Performance Check

Create `daily-check.sh`:

```bash
#!/bin/bash
echo "=== Yesterday's Performance ==="
psql $DATABASE_URL -c "
SELECT
  COUNT(*) as requests,
  SUM(CASE WHEN outcome = 'fill' THEN 1 ELSE 0 END) as fills,
  ROUND(SUM(net_payout), 2) as revenue
FROM clicks
WHERE timestamp >= CURRENT_DATE - INTERVAL '1 day'
  AND timestamp < CURRENT_DATE;
"
```

## Best Practices

1. Always document why you made a change
2. Only change one variable at a time
3. Wait 24 hours to measure impact
4. Never make margin changes during weekends initially
5. Start conservative (lower margins), increase gradually
6. Trust the data, not your gut
7. Reconcile with partners weekly
8. Back up margin rules before major changes
