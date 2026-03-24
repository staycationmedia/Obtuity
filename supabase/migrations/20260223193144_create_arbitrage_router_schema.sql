/*
  # Create XML Pop Arbitrage Router Schema

  1. New Tables
    - publishers: Manages traffic sources
    - partners: Manages demand feed endpoints
    - clicks: Stores every request with outcome
    - feed_attempts: Stores every feed response attempt
    - rules_margins: Defines margin rules by precedence
    - blacklist_subids: Blocks low-quality subid sources

  2. Security
    - Enable RLS on all tables
    - Service role only access (internal system)

  3. Indexes
    - Performance indexes for timestamp queries
    - Foreign key indexes
*/

-- Publishers table
CREATE TABLE IF NOT EXISTS publishers (
  id SERIAL PRIMARY KEY,
  name TEXT NOT NULL,
  status TEXT NOT NULL DEFAULT 'active' CHECK (status IN ('active', 'paused', 'blocked')),
  rate_limit_per_minute INTEGER DEFAULT 1000,
  created_at TIMESTAMPTZ DEFAULT now()
);

-- Partners (demand feeds) table
CREATE TABLE IF NOT EXISTS partners (
  id SERIAL PRIMARY KEY,
  name TEXT NOT NULL,
  endpoint_url TEXT NOT NULL,
  timeout_ms INTEGER DEFAULT 250,
  status TEXT NOT NULL DEFAULT 'active' CHECK (status IN ('active', 'paused')),
  created_at TIMESTAMPTZ DEFAULT now()
);

-- Clicks table (one row per request)
CREATE TABLE IF NOT EXISTS clicks (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  timestamp TIMESTAMPTZ DEFAULT now(),
  publisher_id INTEGER REFERENCES publishers(id),
  subid TEXT,
  ip_hash TEXT NOT NULL,
  country TEXT,
  device TEXT CHECK (device IN ('mobile', 'desktop', 'tablet', 'unknown')),
  user_agent TEXT,
  winner_partner_id INTEGER REFERENCES partners(id),
  raw_payout NUMERIC(10,4),
  margin_applied NUMERIC(10,4),
  net_payout NUMERIC(10,4),
  outcome TEXT NOT NULL CHECK (outcome IN ('fill', 'no-fill', 'error', 'blacklist', 'invalid')),
  router_time_ms INTEGER,
  redirect_url TEXT
);

-- Feed attempts table (one row per feed per click)
CREATE TABLE IF NOT EXISTS feed_attempts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  click_id UUID REFERENCES clicks(id),
  partner_id INTEGER REFERENCES partners(id),
  response_time_ms INTEGER,
  payout NUMERIC(10,4),
  fill BOOLEAN DEFAULT false,
  error TEXT,
  created_at TIMESTAMPTZ DEFAULT now()
);

-- Margin rules table
CREATE TABLE IF NOT EXISTS rules_margins (
  id SERIAL PRIMARY KEY,
  rule_type TEXT NOT NULL CHECK (rule_type IN ('geo+partner', 'geo', 'publisher', 'partner', 'global')),
  geo TEXT,
  partner_id INTEGER REFERENCES partners(id),
  publisher_id INTEGER REFERENCES publishers(id),
  margin_percent NUMERIC(5,2) NOT NULL,
  priority INTEGER NOT NULL,
  active BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT now()
);

-- Blacklist subids table
CREATE TABLE IF NOT EXISTS blacklist_subids (
  id SERIAL PRIMARY KEY,
  publisher_id INTEGER REFERENCES publishers(id),
  subid TEXT NOT NULL,
  reason TEXT,
  created_at TIMESTAMPTZ DEFAULT now(),
  UNIQUE(publisher_id, subid)
);

-- Indexes for performance
CREATE INDEX IF NOT EXISTS idx_clicks_timestamp ON clicks(timestamp DESC);
CREATE INDEX IF NOT EXISTS idx_clicks_publisher ON clicks(publisher_id, timestamp DESC);
CREATE INDEX IF NOT EXISTS idx_clicks_country ON clicks(country, timestamp DESC);
CREATE INDEX IF NOT EXISTS idx_clicks_outcome ON clicks(outcome, timestamp DESC);
CREATE INDEX IF NOT EXISTS idx_feed_attempts_click ON feed_attempts(click_id);
CREATE INDEX IF NOT EXISTS idx_feed_attempts_partner ON feed_attempts(partner_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_blacklist_lookup ON blacklist_subids(publisher_id, subid);

-- Enable RLS
ALTER TABLE publishers ENABLE ROW LEVEL SECURITY;
ALTER TABLE partners ENABLE ROW LEVEL SECURITY;
ALTER TABLE clicks ENABLE ROW LEVEL SECURITY;
ALTER TABLE feed_attempts ENABLE ROW LEVEL SECURITY;
ALTER TABLE rules_margins ENABLE ROW LEVEL SECURITY;
ALTER TABLE blacklist_subids ENABLE ROW LEVEL SECURITY;

-- Policies for service role access
CREATE POLICY "Service role full access to publishers"
  ON publishers FOR ALL
  TO service_role
  USING (true)
  WITH CHECK (true);

CREATE POLICY "Service role full access to partners"
  ON partners FOR ALL
  TO service_role
  USING (true)
  WITH CHECK (true);

CREATE POLICY "Service role full access to clicks"
  ON clicks FOR ALL
  TO service_role
  USING (true)
  WITH CHECK (true);

CREATE POLICY "Service role full access to feed_attempts"
  ON feed_attempts FOR ALL
  TO service_role
  USING (true)
  WITH CHECK (true);

CREATE POLICY "Service role full access to rules_margins"
  ON rules_margins FOR ALL
  TO service_role
  USING (true)
  WITH CHECK (true);

CREATE POLICY "Service role full access to blacklist_subids"
  ON blacklist_subids FOR ALL
  TO service_role
  USING (true)
  WITH CHECK (true);