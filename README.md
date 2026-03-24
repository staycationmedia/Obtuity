# XML Pop Arbitrage Router

A production-ready arbitrage routing system that accepts pop traffic, fans out to multiple XML demand feeds in parallel, selects the highest payout, applies configurable margin rules, and redirects users via 302.

## Architecture

- **Node.js** with Fastify for high-performance HTTP handling
- **Supabase** (PostgreSQL) for data persistence and logging
- **Nginx** as reverse proxy with SSL termination
- **PM2** for process management and clustering
- **GeoIP** for country detection
- **Parallel XML fetching** with strict timeouts (200-300ms)

## Domain

Production endpoint: `https://rt.smartdailyoptions.com/click`

## Key Features

- Accepts pop traffic at `/click` endpoint
- Normalizes request parameters (IP, UA, publisher_id, subid)
- Fans out to 2-3 XML feeds in parallel with strict timeouts
- Auction logic selects highest compliant payout
- Configurable margin rules with precedence
- 302 redirects to winning offer
- Comprehensive logging of every request and feed attempt
- Manual daily spread optimization support

## Request Flow

```
Publisher → /click → normalize → validate → fan-out feeds →
auction → margin → redirect → log
```

## Installation

### 1. Clone and Install

```bash
git clone <your-repo>
cd xml-pop-arbitrage-router
npm install
```

### 2. Configure Environment

The `.env` file contains your Supabase credentials.

### 3. Database Setup

The database schema is already created via Supabase migrations. Seed data has been inserted with example publishers, partners, and margin rules.

### 4. Configure Nginx

Copy the Nginx configuration:

```bash
sudo cp nginx.conf /etc/nginx/sites-available/rt.smartdailyoptions.com
sudo ln -s /etc/nginx/sites-available/rt.smartdailyoptions.com /etc/nginx/sites-enabled/
```

Test and reload Nginx:

```bash
sudo nginx -t
sudo systemctl reload nginx
```

### 5. SSL Setup

Install SSL certificate using Let's Encrypt:

```bash
sudo certbot --nginx -d rt.smartdailyoptions.com
```

### 6. Start Application

**Development:**
```bash
npm run dev
```

**Production (PM2):**
```bash
npm install -g pm2
pm2 start ecosystem.config.cjs
pm2 save
pm2 startup
```

View logs:
```bash
pm2 logs arbitrage-router
```

## API Endpoints

### Click Endpoint

```
GET /click?pub=123&subid=abc
```

**Parameters:**
- `pub` - Publisher ID (required)
- `subid` - Sub ID for tracking (optional)

**Response:**
- `302 Redirect` - To winning offer
- `204 No Content` - No fill or validation failure

### Health Check

```
GET /health
```

**Response:**
```json
{
  "status": "ok",
  "timestamp": "2026-02-23T19:45:00Z",
  "uptime": 12345,
  "database": "connected",
  "feeds": 3
}
```

### Reload Feeds

```
POST /admin/reload-feeds
```

Reloads active feeds from database without restarting the server.

## Database Schema

### Tables

1. **publishers** - Traffic sources
2. **partners** - Demand feed endpoints
3. **clicks** - Every request with outcome
4. **feed_attempts** - Every feed response attempt
5. **rules_margins** - Margin rules by precedence
6. **blacklist_subids** - Blocked subid sources

## Margin Rules

Margin precedence (highest to lowest):

1. **geo+partner** (priority 100) - Specific geo + partner combination
2. **geo** (priority 10) - Country-specific margins
3. **publisher** (priority 3) - Publisher-specific margins
4. **partner** (priority 5) - Partner-specific margins
5. **global** (priority 1) - Default margin for all traffic

Example margin calculation:
- Raw payout: $1.00
- Margin rule: 15% (US traffic)
- Margin applied: $0.15
- Net payout: $0.85

## Feed Integration

### Adding a New Feed

1. Create a new feed class in `src/services/feeds/`:

```javascript
import { BaseFeed } from './baseFeed.js';

export class MyNewFeed extends BaseFeed {
  buildUrl(params) {
    const url = new URL(this.endpointUrl);
    url.searchParams.append('pub', params.publisherId);
    url.searchParams.append('country', params.country);
    return url.toString();
  }

  parseResponse(parsed, responseTimeMs) {
    // Parse your XML structure
    return {
      partnerId: this.partnerId,
      payout: parseFloat(parsed.offer.price),
      redirectUrl: parsed.offer.url,
      fill: true,
      error: null,
      responseTimeMs
    };
  }
}
```

2. Add the partner to the database:

```sql
INSERT INTO partners (name, endpoint_url, timeout_ms, status)
VALUES ('My New Feed', 'https://feed.example.com/api', 250, 'active');
```

3. Update `feedManager.js` to include your new feed class.

4. Reload feeds:

```bash
curl -X POST https://rt.smartdailyoptions.com/admin/reload-feeds
```

## Daily Analysis Queries

### Fill Rate by Partner

```sql
SELECT
  p.name,
  COUNT(*) as attempts,
  SUM(CASE WHEN fa.fill THEN 1 ELSE 0 END) as fills,
  ROUND(AVG(CASE WHEN fa.fill THEN 1.0 ELSE 0.0 END) * 100, 2) as fill_rate,
  ROUND(AVG(fa.payout), 4) as avg_payout
FROM feed_attempts fa
JOIN partners p ON fa.partner_id = p.id
WHERE fa.created_at >= NOW() - INTERVAL '1 day'
GROUP BY p.id, p.name
ORDER BY fill_rate DESC;
```

### Revenue by Geo

```sql
SELECT
  country,
  COUNT(*) as requests,
  SUM(CASE WHEN outcome = 'fill' THEN 1 ELSE 0 END) as fills,
  ROUND(SUM(raw_payout), 2) as gross_revenue,
  ROUND(SUM(margin_applied), 2) as margin,
  ROUND(SUM(net_payout), 2) as net_revenue
FROM clicks
WHERE timestamp >= NOW() - INTERVAL '1 day'
GROUP BY country
ORDER BY gross_revenue DESC;
```

### Publisher Performance

```sql
SELECT
  pub.name,
  COUNT(*) as requests,
  ROUND(AVG(c.router_time_ms), 2) as avg_latency_ms,
  SUM(CASE WHEN c.outcome = 'fill' THEN 1 ELSE 0 END) as fills,
  ROUND(SUM(c.net_payout), 2) as revenue
FROM clicks c
JOIN publishers pub ON c.publisher_id = pub.id
WHERE c.timestamp >= NOW() - INTERVAL '1 day'
GROUP BY pub.id, pub.name
ORDER BY revenue DESC;
```

## Manual Optimization (First 30 Days)

During the first 30 days, manually adjust margins based on daily analysis:

1. Review daily performance metrics
2. Identify profitable geos and partners
3. Adjust margins in `rules_margins` table
4. Monitor impact next day
5. Blacklist low-performing subids

**Example: Increase US margin for Partner 1**

```sql
UPDATE rules_margins
SET margin_percent = 22.00
WHERE rule_type = 'geo+partner' AND geo = 'US' AND partner_id = 1;
```

**Example: Blacklist a subid**

```sql
INSERT INTO blacklist_subids (publisher_id, subid, reason)
VALUES (1, 'low-quality-source', 'High bounce rate');
```

## Scaling

### Current (100k-500k clicks/day)
- Single VPS with PM2 cluster mode (2-4 instances)
- Supabase handles database load

### 1M clicks/day
- Increase PM2 instances to 4-8
- Consider dedicated Supabase plan
- Add read replicas if needed

### 3-5M clicks/day
- Multiple VPS instances behind load balancer
- Separate logging queue (Redis/RabbitMQ)
- Dedicated reporting database
- CDN for static assets

## Monitoring

### PM2 Monitoring

```bash
pm2 monit
pm2 status
pm2 logs --lines 100
```

### Health Check Monitoring

Set up external monitoring to check `/health` endpoint every minute:

```bash
curl https://rt.smartdailyoptions.com/health
```

### Database Monitoring

Monitor Supabase dashboard for:
- Query performance
- Connection pool usage
- Disk space
- Error logs

## Troubleshooting

### No Fills

1. Check feed endpoints are accessible
2. Verify XML parsing logic matches feed response structure
3. Check timeout settings (may need to increase)
4. Review feed_attempts table for errors

### High Latency

1. Check feed response times in feed_attempts table
2. Verify network connectivity to feed endpoints
3. Consider reducing timeout values
4. Check database query performance

### Database Connection Errors

1. Verify Supabase credentials in `.env`
2. Check Supabase dashboard for connection limits
3. Review connection pool settings

## Production Checklist

- [ ] DNS A record pointing to VPS IP
- [ ] Nginx configured and tested
- [ ] SSL certificate installed
- [ ] Environment variables configured
- [ ] Database schema created
- [ ] Seed data loaded
- [ ] PM2 running and saved
- [ ] PM2 startup script enabled
- [ ] Health check returning 200
- [ ] Test click endpoint with sample traffic
- [ ] Monitoring alerts configured
- [ ] Daily analysis queries saved
- [ ] Backup strategy implemented

## Security

- All passwords and API keys in `.env` (never commit)
- Nginx with SSL/TLS 1.2+
- Rate limiting enabled (100 req/min per IP)
- Input validation on all endpoints
- IP hashing for privacy
- RLS policies on database tables

## License

Proprietary - All Rights Reserved
