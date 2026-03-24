import { BaseFeed } from './baseFeed.js';

export class ExampleFeed2 extends BaseFeed {
  buildUrl(params) {
    const url = new URL(this.endpointUrl);
    url.searchParams.append('publisher', params.publisherId);
    url.searchParams.append('subid', params.subid);
    url.searchParams.append('geo', params.country);
    url.searchParams.append('device_type', params.device);
    url.searchParams.append('user_ip', params.ip);
    return url.toString();
  }

  parseResponse(parsed, responseTimeMs) {
    try {
      const offer = parsed.xml?.offer || parsed.offer || parsed.ad;

      if (!offer || offer['@_status'] === 'empty') {
        return {
          partnerId: this.partnerId,
          fill: false,
          error: null,
          responseTimeMs
        };
      }

      const payout = parseFloat(offer.bid || offer.payout || offer.revenue || 0);
      const redirectUrl = offer.clickUrl || offer.click_url || offer.link;

      if (!redirectUrl || payout <= 0) {
        return {
          partnerId: this.partnerId,
          fill: false,
          error: null,
          responseTimeMs
        };
      }

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
