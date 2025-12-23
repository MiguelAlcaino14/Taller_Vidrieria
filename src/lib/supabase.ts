import { createClient } from '@supabase/supabase-js';

const supabaseUrl = import.meta.env.VITE_SUPABASE_URL;
const supabaseAnonKey = import.meta.env.VITE_SUPABASE_ANON_KEY;

if (!supabaseUrl || !supabaseAnonKey) {
  const missing = [];
  if (!supabaseUrl) missing.push('VITE_SUPABASE_URL');
  if (!supabaseAnonKey) missing.push('VITE_SUPABASE_ANON_KEY');

  throw new Error(
    `Faltan variables de entorno de Supabase: ${missing.join(', ')}.\n\n` +
    'En Netlify, ve a: Site settings > Environment variables y agrega:\n' +
    '- VITE_SUPABASE_URL: https://qydplrdlzfskkogosewa.supabase.co\n' +
    '- VITE_SUPABASE_ANON_KEY: [tu clave anon key]'
  );
}

export const supabase = createClient(supabaseUrl, supabaseAnonKey);
