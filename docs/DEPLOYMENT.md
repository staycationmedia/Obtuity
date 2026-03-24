# Deployment Guide

Complete step-by-step guide to deploy the XML Pop Arbitrage Router to production.

## Prerequisites

- CentOS VPS with root access
- Domain: rt.smartdailyoptions.com
- Node.js 18+ installed
- Nginx installed
- Supabase database configured

## Step 1: DNS Configuration

Create an A record for your subdomain:

```
Type: A
Name: rt
Value: YOUR_VPS_IP
TTL: 3600
```

Verify DNS propagation:
```bash
dig rt.smartdailyoptions.com
```

## Step 2: Server Preparation

### Update System

```bash
sudo yum update -y
sudo yum install -y git nginx certbot python3-certbot-nginx
```

### Install Node.js (if not installed)

```bash
curl -fsSL https://rpm.nodesource.com/setup_20.x | sudo bash -
sudo yum install -y nodejs
node --version  # Should be v20.x or higher
```

### Create Application Directory

```bash
sudo mkdir -p /var/www/arbitrage-router
sudo chown $USER:$USER /var/www/arbitrage-router
cd /var/www/arbitrage-router
```

## Step 3: Deploy Application Code

### Clone Repository

```bash
git clone <your-repo-url> .
```

Or upload files via SCP:

```bash
# From your local machine
scp -r /path/to/project/* user@your-vps:/var/www/arbitrage-router/
```

### Install Dependencies

```bash
cd /var/www/arbitrage-router
npm install --production
```

### Configure Environment

Edit `.env` file with your Supabase credentials:

```bash
nano .env
```

Ensure it contains:
```
VITE_SUPABASE_URL=https://your-project.supabase.co
VITE_SUPABASE_ANON_KEY=your-anon-key
SUPABASE_SERVICE_ROLE_KEY=your-service-role-key
```

## Step 4: Configure Nginx

### Copy Configuration

```bash
sudo cp nginx.conf /etc/nginx/sites-available/rt.smartdailyoptions.com
```

If `sites-available` doesn't exist on CentOS:

```bash
sudo mkdir -p /etc/nginx/sites-available
sudo mkdir -p /etc/nginx/sites-enabled

# Add to /etc/nginx/nginx.conf in the http block:
# include /etc/nginx/sites-enabled/*;
```

### Enable Site

```bash
sudo ln -s /etc/nginx/sites-available/rt.smartdailyoptions.com /etc/nginx/sites-enabled/
```

### Test Configuration

```bash
sudo nginx -t
```

### Start/Reload Nginx

```bash
sudo systemctl enable nginx
sudo systemctl start nginx
sudo systemctl reload nginx
```

## Step 5: SSL Certificate

Install Let's Encrypt SSL certificate:

```bash
sudo certbot --nginx -d rt.smartdailyoptions.com
```

Follow the prompts and choose to redirect HTTP to HTTPS.

Verify SSL:
```bash
curl -I https://rt.smartdailyoptions.com
```

## Step 6: Database Setup

The database schema should already be created via Supabase migrations. Verify:

```bash
# Check if tables exist
# Login to Supabase dashboard and verify tables:
# - publishers
# - partners
# - clicks
# - feed_attempts
# - rules_margins
# - blacklist_subids
```

Seed data should already be inserted. If not, use the Supabase SQL editor to run the seed script.

## Step 7: PM2 Process Manager

### Install PM2 Globally

```bash
sudo npm install -g pm2
```

### Start Application

```bash
cd /var/www/arbitrage-router
pm2 start ecosystem.config.cjs
```

### Save PM2 Configuration

```bash
pm2 save
```

### Configure PM2 Startup

```bash
pm2 startup
# Copy and run the command that PM2 outputs
```

### Verify Application

```bash
pm2 status
pm2 logs arbitrage-router
```

## Step 8: Configure Firewall

Allow HTTP, HTTPS, and SSH:

```bash
sudo firewall-cmd --permanent --add-service=http
sudo firewall-cmd --permanent --add-service=https
sudo firewall-cmd --permanent --add-service=ssh
sudo firewall-cmd --reload
```

Or if using iptables:

```bash
sudo iptables -A INPUT -p tcp --dport 80 -j ACCEPT
sudo iptables -A INPUT -p tcp --dport 443 -j ACCEPT
sudo iptables -A INPUT -p tcp --dport 22 -j ACCEPT
sudo service iptables save
```

## Step 9: Create Logs Directory

```bash
mkdir -p /var/www/arbitrage-router/logs
```

## Step 10: Test the System

### Health Check

```bash
curl https://rt.smartdailyoptions.com/health
```

Expected response:
```json
{
  "status": "ok",
  "timestamp": "2026-02-23T19:45:00Z",
  "uptime": 12345,
  "database": "connected",
  "feeds": 3
}
```

### Test Click Endpoint

```bash
curl -I "https://rt.smartdailyoptions.com/click?pub=1&subid=test123"
```

Expected response:
- 302 redirect (if feeds are properly configured and responding)
- 204 no content (if no fill or validation issue)

## Step 11: Monitoring Setup

### PM2 Monitoring

```bash
pm2 monit
```

### View Logs

```bash
pm2 logs arbitrage-router --lines 100
```

### Set Up External Monitoring

Configure uptime monitoring service to check:
- `https://rt.smartdailyoptions.com/health` every 1 minute

### Database Monitoring

Monitor Supabase dashboard for:
- Query performance
- Connection pool usage
- Storage usage
- Error logs

## Step 12: Configure Partners

Add your real partner endpoints to the database:

```sql
-- Update partner endpoints
UPDATE partners
SET endpoint_url = 'https://real-feed.com/api/offer'
WHERE id = 1;

-- Or insert new partners
INSERT INTO partners (name, endpoint_url, timeout_ms, status)
VALUES ('Real Feed Name', 'https://feed.example.com/xml', 250, 'active');
```

Reload feeds without restarting:

```bash
curl -X POST https://rt.smartdailyoptions.com/admin/reload-feeds
```

## Maintenance Commands

### Restart Application

```bash
pm2 restart arbitrage-router
```

### Reload Application (zero-downtime)

```bash
pm2 reload arbitrage-router
```

### Stop Application

```bash
pm2 stop arbitrage-router
```

### View Logs

```bash
pm2 logs arbitrage-router
pm2 logs arbitrage-router --lines 100
pm2 logs arbitrage-router --err
```

### Update Application Code

```bash
cd /var/www/arbitrage-router
git pull origin main
npm install
pm2 reload arbitrage-router
```

### Renew SSL Certificate (automatic)

Certbot will auto-renew. Test renewal:

```bash
sudo certbot renew --dry-run
```

## Troubleshooting

### Application Won't Start

Check logs:
```bash
pm2 logs arbitrage-router --err
```

Common issues:
- Missing environment variables
- Database connection failed
- Port 3000 already in use
- Node.js version incompatibility

### 502 Bad Gateway

Check if application is running:
```bash
pm2 status
curl http://127.0.0.1:3000/health
```

Check Nginx error logs:
```bash
sudo tail -f /var/log/nginx/error.log
```

### Database Connection Issues

Verify credentials:
```bash
cat .env
```

Test connection:
```bash
node -e "import('./src/config/database.js').then(m => m.testConnection())"
```

### No Fills

Check feed endpoints:
```bash
pm2 logs arbitrage-router | grep -i "feed"
```

Review feed_attempts table for errors:
```sql
SELECT partner_id, error, COUNT(*) as count
FROM feed_attempts
WHERE created_at >= NOW() - INTERVAL '1 hour'
GROUP BY partner_id, error;
```

## Production Checklist

- [ ] DNS A record configured and propagated
- [ ] Nginx installed and configured
- [ ] SSL certificate installed and auto-renewal enabled
- [ ] Firewall rules configured
- [ ] Node.js installed (v18+)
- [ ] Application code deployed
- [ ] Dependencies installed
- [ ] Environment variables configured
- [ ] Database accessible and seeded
- [ ] PM2 installed and configured
- [ ] PM2 startup script enabled
- [ ] Application running via PM2
- [ ] Health check returning 200 OK
- [ ] Test click endpoint working
- [ ] Logs directory created
- [ ] External monitoring configured
- [ ] Partner endpoints configured
- [ ] Margin rules configured
- [ ] Daily analysis queries saved

## Backup Strategy

### Database Backups

Supabase automatically backs up your database. Configure retention in Supabase dashboard.

### Application Backups

```bash
# Backup application directory
tar -czf arbitrage-router-backup-$(date +%Y%m%d).tar.gz /var/www/arbitrage-router

# Backup to remote location
rsync -avz /var/www/arbitrage-router/ backup-server:/backups/arbitrage-router/
```

### Configuration Backups

```bash
# Backup Nginx config
sudo cp /etc/nginx/sites-available/rt.smartdailyoptions.com ~/nginx-backup.conf

# Backup environment file
cp /var/www/arbitrage-router/.env ~/env-backup
```

## Security Recommendations

- Keep Node.js and npm updated
- Regularly update dependencies: `npm audit fix`
- Monitor logs for suspicious activity
- Use strong Supabase credentials
- Never commit `.env` to version control
- Restrict database access to VPS IP only
- Enable fail2ban for SSH protection
- Regular security audits

## Support

For issues or questions:
1. Check logs: `pm2 logs arbitrage-router`
2. Review Supabase logs
3. Check Nginx error logs
4. Verify database connectivity
5. Review feed_attempts table for feed-specific errors
