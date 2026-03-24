import { supabase } from '../../config/database.js';
import { ExampleFeed1 } from './exampleFeed1.js';
import { ExampleFeed2 } from './exampleFeed2.js';

export class FeedManager {
  constructor() {
    this.feeds = [];
  }

  async loadFeeds() {
    const { data: partners, error } = await supabase
      .from('partners')
      .select('*')
      .eq('status', 'active');

    if (error) {
      console.error('Error loading partners:', error);
      return;
    }

    this.feeds = partners.map(partner => {
      if (partner.name.includes('Feed1') || partner.id === 1) {
        return new ExampleFeed1(
          partner.id,
          partner.name,
          partner.endpoint_url,
          partner.timeout_ms
        );
      } else {
        return new ExampleFeed2(
          partner.id,
          partner.name,
          partner.endpoint_url,
          partner.timeout_ms
        );
      }
    });

    console.log(`Loaded ${this.feeds.length} active feeds`);
  }

  async fetchAllFeeds(params) {
    if (this.feeds.length === 0) {
      await this.loadFeeds();
    }

    const promises = this.feeds.map(feed => feed.fetch(params));

    const results = await Promise.all(promises);

    return results;
  }

  async reloadFeeds() {
    await this.loadFeeds();
  }
}

export const feedManager = new FeedManager();
