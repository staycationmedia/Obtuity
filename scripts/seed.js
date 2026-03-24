import { supabase } from '../src/config/database.js';

async function seed() {
  console.log('Seeding database...');

  console.log('\n1. Creating publishers...');
  const { data: publishers, error: pubError } = await supabase
    .from('publishers')
    .insert([
      { id: 1, name: 'Publisher A', status: 'active', rate_limit_per_minute: 1000 },
      { id: 2, name: 'Publisher B', status: 'active', rate_limit_per_minute: 500 },
      { id: 3, name: 'Publisher C (Paused)', status: 'paused', rate_limit_per_minute: 1000 }
    ])
    .select();

  if (pubError && pubError.code !== '23505') {
    console.error('Error creating publishers:', pubError);
  } else {
    console.log(`Created ${publishers?.length || 0} publishers`);
  }

  console.log('\n2. Creating partners (demand feeds)...');
  const { data: partners, error: partError } = await supabase
    .from('partners')
    .insert([
      {
        id: 1,
        name: 'ExampleFeed1 - High Payout',
        endpoint_url: 'https://example-feed-1.com/api/offer',
        timeout_ms: 250,
        status: 'active'
      },
      {
        id: 2,
        name: 'ExampleFeed2 - Medium Payout',
        endpoint_url: 'https://example-feed-2.com/xml',
        timeout_ms: 200,
        status: 'active'
      },
      {
        id: 3,
        name: 'ExampleFeed3 - Fast Response',
        endpoint_url: 'https://example-feed-3.com/get',
        timeout_ms: 300,
        status: 'active'
      }
    ])
    .select();

  if (partError && partError.code !== '23505') {
    console.error('Error creating partners:', partError);
  } else {
    console.log(`Created ${partners?.length || 0} partners`);
  }

  console.log('\n3. Creating margin rules...');
  const { data: margins, error: marginError } = await supabase
    .from('rules_margins')
    .insert([
      {
        rule_type: 'global',
        margin_percent: 10.00,
        priority: 1,
        active: true
      },
      {
        rule_type: 'geo',
        geo: 'US',
        margin_percent: 15.00,
        priority: 10,
        active: true
      },
      {
        rule_type: 'geo',
        geo: 'GB',
        margin_percent: 12.00,
        priority: 10,
        active: true
      },
      {
        rule_type: 'partner',
        partner_id: 1,
        margin_percent: 8.00,
        priority: 5,
        active: true
      },
      {
        rule_type: 'geo+partner',
        geo: 'US',
        partner_id: 1,
        margin_percent: 20.00,
        priority: 100,
        active: true
      },
      {
        rule_type: 'publisher',
        publisher_id: 1,
        margin_percent: 5.00,
        priority: 3,
        active: true
      }
    ])
    .select();

  if (marginError && marginError.code !== '23505') {
    console.error('Error creating margin rules:', marginError);
  } else {
    console.log(`Created ${margins?.length || 0} margin rules`);
  }

  console.log('\n4. Creating example blacklist entries...');
  const { data: blacklist, error: blacklistError } = await supabase
    .from('blacklist_subids')
    .insert([
      {
        publisher_id: 1,
        subid: 'bad-source-1',
        reason: 'Low quality traffic'
      },
      {
        publisher_id: 2,
        subid: 'fraud-test',
        reason: 'Fraudulent activity detected'
      }
    ])
    .select();

  if (blacklistError && blacklistError.code !== '23505') {
    console.error('Error creating blacklist:', blacklistError);
  } else {
    console.log(`Created ${blacklist?.length || 0} blacklist entries`);
  }

  console.log('\n✅ Database seeded successfully!\n');

  console.log('Summary:');
  console.log('- Publishers: 3 (2 active, 1 paused)');
  console.log('- Partners: 3 (all active)');
  console.log('- Margin Rules: 6 (global, geo, partner, geo+partner, publisher)');
  console.log('- Blacklist Entries: 2');
  console.log('\nMargin Rules Precedence:');
  console.log('  1. geo+partner (priority 100) - US + Partner 1 = 20%');
  console.log('  2. geo (priority 10) - US = 15%, GB = 12%');
  console.log('  3. partner (priority 5) - Partner 1 = 8%');
  console.log('  4. publisher (priority 3) - Publisher 1 = 5%');
  console.log('  5. global (priority 1) - All others = 10%');

  process.exit(0);
}

seed().catch(error => {
  console.error('Seed failed:', error);
  process.exit(1);
});
