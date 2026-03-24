import { createClient } from '@supabase/supabase-js';

const supabaseUrl = process.env.SUPABASE_URL;
const supabaseKey = process.env.SUPABASE_SERVICE_ROLE_KEY;

export const supabase = createClient(supabaseUrl, supabaseKey);

export async function testConnection() {
  try {
    const { error } = await supabase
      .from('publishers')
      .select('id')
      .limit(1);

    if (error) {
      console.error('Supabase error:', error.message);
      return false;
    }

    return true;
  } catch (err) {
    console.error('Connection failed:', err.message);
    return false;
  }
}
