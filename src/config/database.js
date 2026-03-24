import { createClient } from '@supabase/supabase-js';
import dotenv from 'dotenv';

dotenv.config();

const supabaseUrl = process.env.VITE_SUPABASE_URL;
const supabaseKey = process.env.SUPABASE_SERVICE_ROLE_KEY;

if (!supabaseUrl || !supabaseKey) {
  throw new Error('Missing Supabase credentials in .env file');
}

export const supabase = createClient(supabaseUrl, supabaseKey, {
  auth: {
    autoRefreshToken: false,
    persistSession: false
  }
});

export async function testConnection() {
  try {
    const { data, error } = await supabase.from('publishers').select('count').single();
    if (error && error.code !== 'PGRST116') {
      throw error;
    }
    return true;
  } catch (error) {
    console.error('Database connection test failed:', error);
    return false;
  }
}
