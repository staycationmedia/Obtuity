import { BaseFeed } from './baseFeed.js';

export class ExampleFeed1 extends BaseFeed {
  buildUrl(params) {
    const url = new URL(this.endpointUrl);
    url.searchParams.append('pub_id', params.publisherId);
    url.searchParams.append('sub_id', params.subid);
    url.searchParams.append('country', params.country);
    url.searchParams.append('device', params.device);
    url.searchParams.append('ip', params.ip);
    return url.toString();
  }

  parseResponse(parsed, responseTimeMs) {
    try {
      const response = parsed.response || parsed.offer;

      if (!response || response.status === 'no-fill' || !response.redirect_url) {
        return {
          partnerId: this.partnerId,
          fill: false,
          error: null,
          responseTimeMs
        };
      }

      const payout = parseFloat(response.payout || response.price || 0);
      const redirectUrl = response.redirect_url || response.url;

      return {
        partnerId: this.partnerId,
        payout,
        redirectUrl,
        fill: true,
        error: null,
        responseTimeMs
      };
    } catch (error) {
      return {
        partnerId: this.partnerId,
        fill: false,
        error: `parse_error: ${error.message}`,
        responseTimeMs
      };
    }
  }
}
