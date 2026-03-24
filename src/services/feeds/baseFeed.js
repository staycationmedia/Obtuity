import { XMLParser } from 'fast-xml-parser';

export class BaseFeed {
  constructor(partnerId, name, endpointUrl, timeoutMs = 250) {
    this.partnerId = partnerId;
    this.name = name;
    this.endpointUrl = endpointUrl;
    this.timeoutMs = timeoutMs;
    this.parser = new XMLParser({
      ignoreAttributes: false,
      attributeNamePrefix: '@_'
    });
  }

  async fetch(params) {
    const startTime = Date.now();

    try {
      const url = this.buildUrl(params);

      const controller = new AbortController();
      const timeout = setTimeout(() => controller.abort(), this.timeoutMs);

      const response = await fetch(url, {
        method: 'GET',
        signal: controller.signal,
        headers: {
          'User-Agent': 'ArbitrageRouter/1.0'
        }
      });

      clearTimeout(timeout);

      const responseTimeMs = Date.now() - startTime;

      if (!response.ok) {
        return {
          partnerId: this.partnerId,
          fill: false,
          error: `HTTP ${response.status}`,
          responseTimeMs
        };
      }

      const xmlText = await response.text();
      const parsed = this.parser.parse(xmlText);

      return this.parseResponse(parsed, responseTimeMs);

    } catch (error) {
      const responseTimeMs = Date.now() - startTime;

      if (error.name === 'AbortError') {
        return {
          partnerId: this.partnerId,
          fill: false,
          error: 'timeout',
          responseTimeMs
        };
      }

      return {
        partnerId: this.partnerId,
        fill: false,
        error: error.message,
        responseTimeMs
      };
    }
  }

  buildUrl(params) {
    throw new Error('buildUrl must be implemented by subclass');
  }

  parseResponse(parsed, responseTimeMs) {
    throw new Error('parseResponse must be implemented by subclass');
  }
}
