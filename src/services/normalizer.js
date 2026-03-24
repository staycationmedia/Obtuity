import geoip from 'geoip-lite';
import crypto from 'crypto';

export function normalizeRequest(request) {
  const query = request.query;
  const headers = request.headers;

  const ip = headers['x-forwarded-for']?.split(',')[0].trim() ||
              headers['x-real-ip'] ||
              request.ip;

  const userAgent = headers['user-agent'] || 'unknown';

  const publisherId = parseInt(query.pub) || null;
  const subid = query.subid || '';

  const ipHash = crypto.createHash('sha256').update(ip).digest('hex').substring(0, 16);

  const geo = geoip.lookup(ip);
  const country = geo?.country || 'XX';

  const device = detectDevice(userAgent);

  return {
    publisherId,
    subid,
    ip,
    ipHash,
    country,
    device,
    userAgent,
    timestamp: new Date()
  };
}

export function detectDevice(userAgent) {
  const ua = userAgent.toLowerCase();

  if (/(tablet|ipad|playbook|silk)|(android(?!.*mobi))/i.test(userAgent)) {
    return 'tablet';
  }

  if (/mobile|iphone|ipod|blackberry|iemobile|opera mini/i.test(userAgent)) {
    return 'mobile';
  }

  if (/windows|macintosh|linux|ubuntu/i.test(userAgent)) {
    return 'desktop';
  }

  return 'unknown';
}

export function hashIp(ip) {
  return crypto.createHash('sha256').update(ip).digest('hex').substring(0, 16);
}
