import { createClient } from '@supabase/supabase-js';

const supabaseUrl = process.env.https://uaukcstlscurtfuugyij.supabase.co;
const supabaseKey = process.env.eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InVhdWtjc3Rsc2N1dHJmdXVneWp2Iiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc3NDM1OTg2OSwiZXhwIjoyMDg5OTM1ODY5fQ.pbcfiOgihbEKpVh3IYGRMrcdclXryhyYpvJQFGmeRUQ;

export const supabase = createClient(supabaseUrl, supabaseKey);

export async function testConnection() {
  try {
    const { data, error } = await supabase
      .from('_test_connection')
      .select('*')
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
