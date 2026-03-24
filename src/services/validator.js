import { supabase } from '../config/database.js';

export async function validateRequest(normalized) {
  if (!normalized.publisherId) {
    return { valid: false, reason: 'missing_publisher_id' };
  }

  const { data: publisher, error: pubError } = await supabase
    .from('publishers')
    .select('id, status')
    .eq('id', normalized.publisherId)
    .maybeSingle();

  if (pubError) {
    console.error('Error fetching publisher:', pubError);
    return { valid: false, reason: 'database_error' };
  }

  if (!publisher) {
    return { valid: false, reason: 'publisher_not_found' };
  }

  if (publisher.status !== 'active') {
    return { valid: false, reason: 'publisher_not_active' };
  }

  const { data: blacklisted } = await supabase
    .from('blacklist_subids')
    .select('id')
    .eq('publisher_id', normalized.publisherId)
    .eq('subid', normalized.subid)
    .maybeSingle();

  if (blacklisted) {
    return { valid: false, reason: 'subid_blacklisted' };
  }

  return { valid: true };
}
