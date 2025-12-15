import { createClient } from 'npm:@supabase/supabase-js@2.57.4';

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
  'Access-Control-Allow-Headers': 'Content-Type, Authorization, X-Client-Info, Apikey',
};

interface UserPassword {
  email: string;
  password: string;
}

const DEMO_PASSWORDS: UserPassword[] = [
  { email: 'admin@vidrios.com', password: 'Admin123!' },
  { email: 'manager@vidrios.com', password: 'Manager123!' },
  { email: 'usuario1@vidrios.com', password: 'Usuario123!' },
  { email: 'usuario2@vidrios.com', password: 'Usuario123!' },
  { email: 'malcaino@vidrios.com', password: 'Miguel123!' }
];

Deno.serve(async (req: Request) => {
  if (req.method === 'OPTIONS') {
    return new Response(null, { status: 200, headers: corsHeaders });
  }

  try {
    const supabaseAdmin = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? '',
      {
        auth: {
          autoRefreshToken: false,
          persistSession: false
        }
      }
    );

    const results = [];

    for (const userPassword of DEMO_PASSWORDS) {
      const { data: users } = await supabaseAdmin.auth.admin.listUsers();
      const user = users?.users.find(u => u.email === userPassword.email);

      if (!user) {
        results.push({
          email: userPassword.email,
          status: 'not_found',
          message: 'Usuario no encontrado'
        });
        continue;
      }

      const { error } = await supabaseAdmin.auth.admin.updateUserById(
        user.id,
        { password: userPassword.password }
      );

      if (error) {
        results.push({
          email: userPassword.email,
          status: 'error',
          message: error.message
        });
      } else {
        results.push({
          email: userPassword.email,
          status: 'success',
          message: 'Contraseña actualizada exitosamente'
        });
      }
    }

    return new Response(
      JSON.stringify({
        success: true,
        message: 'Proceso de actualización de contraseñas completado',
        results
      }),
      {
        status: 200,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      }
    );

  } catch (error) {
    return new Response(
      JSON.stringify({
        success: false,
        error: error instanceof Error ? error.message : 'Error desconocido'
      }),
      {
        status: 500,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      }
    );
  }
});