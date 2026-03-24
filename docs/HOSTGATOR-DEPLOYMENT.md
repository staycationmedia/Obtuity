# HostGator VPS Deployment Guide

Complete step-by-step guide to deploy your XML Pop Arbitrage Router to HostGator VPS.

---

## Prerequisites

- HostGator VPS with root/sudo access
- Domain: obtuity.com (DNS already configured ✓)
- SSH access to your VPS

---

## Step 1: Connect to Your VPS

```bash
ssh root@your-vps-ip-address
# Or use the SSH terminal in HostGator's control panel (WHM/cPanel)
```

---

## Step 2: Install Node.js

```bash
# Update system packages
sudo apt update
sudo apt upgrade -y

# Install Node.js 20.x (LTS)
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
sudo apt install -y nodejs

# Verify installation
node --version
npm --version
```

---

## Step 3: Install Nginx

```bash
# Install Nginx
sudo apt install -y nginx

# Start and enable Nginx
sudo systemctl start nginx
sudo systemctl enable nginx

# Check status
sudo systemctl status nginx
```

---

## Step 4: Install PM2 Globally

```bash
# Install PM2 (process manager)
sudo npm install -g pm2

# Verify installation
pm2 --version
```

---

## Step 5: Create Application Directory

```bash
# Create directory for your app
sudo mkdir -p /var/www/obtuity
cd /var/www/obtuity

# Set ownership (replace 'your-user' with your actual username, or use root)
sudo chown -R $USER:$USER /var/www/obtuity
```

---

## Step 6: Upload Your Application Files

**Option A: Using SFTP/SCP (Recommended)**

From your local machine:
```bash
# Zip your project (excluding node_modules)
cd /tmp/cc-agent/64030199/project
tar -czf arbitrage-router.tar.gz \
  --exclude='node_modules' \
  --exclude='.git' \
  .

# Upload to VPS
scp arbitrage-router.tar.gz root@your-vps-ip:/var/www/obtuity/

# On VPS, extract files
cd /var/www/obtuity
tar -xzf arbitrage-router.tar.gz
rm arbitrage-router.tar.gz
```

**Option B: Using Git**

```bash
cd /var/www/obtuity
git clone <your-git-repo-url> .
```

**Option C: Using HostGator File Manager**

1. Zip your project files locally
2. Upload via WHM/cPanel File Manager to `/var/www/obtuity`
3. Extract using File Manager

---

## Step 7: Configure Environment Variables

```bash
cd /var/www/obtuity

# Create .env file
nano .env
```

Add your configuration:
```env
NODE_ENV=production
PORT=3000
HOST=0.0.0.0

# Supabase Configuration
SUPABASE_URL=your_supabase_url_here
SUPABASE_ANON_KEY=your_supabase_anon_key_here

# Feed Configuration (add your actual feed URLs)
FEED_1_URL=https://your-feed-1-url.com/feed.xml
FEED_2_URL=https://your-feed-2-url.com/feed.xml
```

**Save and exit**: Press `Ctrl+X`, then `Y`, then `Enter`

---

## Step 8: Install Dependencies

```bash
cd /var/www/obtuity

# Install production dependencies
npm install --production

# If you need to run the database seed
npm run seed
```

---

## Step 9: Configure Nginx

```bash
# Create Nginx configuration
sudo nano /etc/nginx/sites-available/obtuity.com
```

Paste this configuration:
```nginx
server {
    listen 80;
    listen [::]:80;
    server_name obtuity.com www.obtuity.com;

    # For Let's Encrypt verification
    location /.well-known/acme-challenge/ {
        root /var/www/certbot;
    }

    location / {
        return 301 https://$server_name$request_uri;
    }
}

server {
    listen 443 ssl http2;
    listen [::]:443 ssl http2;
    server_name obtuity.com www.obtuity.com;

    # SSL certificates (will be added by Certbot)
    # ssl_certificate /etc/letsencrypt/live/obtuity.com/fullchain.pem;
    # ssl_certificate_key /etc/letsencrypt/live/obtuity.com/privkey.pem;

    # Security headers
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-XSS-Protection "1; mode=block" always;

    # Proxy to Node.js application
    location / {
        proxy_pass http://127.0.0.1:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_cache_bypass $http_upgrade;

        # Timeout settings
        proxy_connect_timeout 60s;
        proxy_send_timeout 60s;
        proxy_read_timeout 60s;
    }

    # Health check endpoint
    location /health {
        proxy_pass http://127.0.0.1:3000/health;
        access_log off;
    }
}
```

**Save and exit**: Press `Ctrl+X`, then `Y`, then `Enter`

```bash
# Enable the site
sudo ln -s /etc/nginx/sites-available/obtuity.com /etc/nginx/sites-enabled/

# Remove default site if it exists
sudo rm -f /etc/nginx/sites-enabled/default

# Test Nginx configuration
sudo nginx -t

# Reload Nginx
sudo systemctl reload nginx
```

---

## Step 10: Install SSL Certificate (Let's Encrypt)

```bash
# Install Certbot
sudo apt install -y certbot python3-certbot-nginx

# Create directory for certbot challenges
sudo mkdir -p /var/www/certbot

# Get SSL certificate
sudo certbot --nginx -d obtuity.com -d www.obtuity.com
```

**During the process**:
- Enter your email address
- Agree to terms of service (Y)
- Choose whether to share email with EFF (optional)
- Certbot will automatically configure SSL in your Nginx config

```bash
# Test automatic renewal
sudo certbot renew --dry-run

# Reload Nginx with SSL
sudo systemctl reload nginx
```

---

## Step 11: Start Application with PM2

```bash
cd /var/www/obtuity

# Start the application
pm2 start ecosystem.config.cjs

# Save PM2 process list
pm2 save

# Setup PM2 to start on system boot
pm2 startup systemd
# Copy and run the command that PM2 outputs

# Check application status
pm2 status
pm2 logs
```

---

## Step 12: Configure Firewall

```bash
# Check if UFW is installed
sudo ufw status

# If not active, configure it
sudo ufw allow 22/tcp      # SSH
sudo ufw allow 80/tcp      # HTTP
sudo ufw allow 443/tcp     # HTTPS
sudo ufw enable

# Verify
sudo ufw status
```

---

## Step 13: Verify Deployment

1. **Check application health**:
```bash
curl http://localhost:3000/health
```

2. **Check from browser**:
- Visit: https://obtuity.com/health
- Should return JSON with status info

3. **Test click endpoint**:
```bash
curl -X POST https://obtuity.com/click \
  -H "Content-Type: application/json" \
  -d '{
    "campaignId": "test123",
    "feed": "feed1",
    "searchId": "abc",
    "feedRank": 1,
    "externalData": {"ip": "8.8.8.8"}
  }'
```

4. **Monitor logs**:
```bash
pm2 logs
```

---

## Step 14: Ongoing Maintenance

**View application logs**:
```bash
pm2 logs obtuity-router
```

**Restart application**:
```bash
pm2 restart obtuity-router
```

**View application status**:
```bash
pm2 status
```

**Update application**:
```bash
cd /var/www/obtuity
git pull  # or upload new files
npm install --production
pm2 restart obtuity-router
```

**Monitor system resources**:
```bash
pm2 monit
```

---

## Troubleshooting

**Port already in use**:
```bash
sudo lsof -i :3000
sudo kill -9 <PID>
```

**Nginx won't start**:
```bash
sudo nginx -t
sudo systemctl status nginx
sudo journalctl -xe
```

**Application crashes**:
```bash
pm2 logs obtuity-router --err
```

**SSL issues**:
```bash
sudo certbot certificates
sudo certbot renew
```

**Check if app is running**:
```bash
pm2 list
curl http://localhost:3000/health
```

---

## Security Best Practices

1. **Keep system updated**:
```bash
sudo apt update && sudo apt upgrade -y
```

2. **Setup automatic security updates**:
```bash
sudo apt install unattended-upgrades
sudo dpkg-reconfigure -plow unattended-upgrades
```

3. **Monitor logs regularly**:
```bash
pm2 logs
sudo tail -f /var/log/nginx/access.log
sudo tail -f /var/log/nginx/error.log
```

4. **Backup your database** (Supabase handles this)

5. **Monitor application health** at https://obtuity.com/health

---

## Next Steps

After successful deployment:

1. Add your actual XML feed URLs to `.env`
2. Configure feed update schedules in your codebase
3. Monitor initial traffic and performance
4. Set up monitoring/alerting (optional)
5. Test the auction system with real feeds

---

Your application should now be live at:
- **https://obtuity.com**
- **https://www.obtuity.com**

Both HTTP and HTTPS should work, with HTTP redirecting to HTTPS automatically.
