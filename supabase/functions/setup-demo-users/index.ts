import { createClient } from 'npm:@supabase/supabase-js@2.57.4';

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
  'Access-Control-Allow-Headers': 'Content-Type, Authorization, X-Client-Info, Apikey',
};

interface DemoUser {
  email: string;
  password: string;
  fullName: string;
  role: 'user' | 'manager' | 'admin';
}

const DEMO_USERS: DemoUser[] = [
  {
    email: 'admin@vidrios.com',
    password: 'Admin123!',
    fullName: 'Administrador Sistema',
    role: 'admin'
  },
  {
    email: 'manager@vidrios.com',
    password: 'Manager123!',
    fullName: 'Manager Regional',
    role: 'manager'
  },
  {
    email: 'usuario1@vidrios.com',
    password: 'Usuario123!',
    fullName: 'Juan Pérez',
    role: 'user'
  },
  {
    email: 'usuario2@vidrios.com',
    password: 'Usuario123!',
    fullName: 'María González',
    role: 'user'
  }
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

    for (const demoUser of DEMO_USERS) {
      const { data: existingUser } = await supabaseAdmin.auth.admin.listUsers();
      const userExists = existingUser?.users.some(u => u.email === demoUser.email);

      if (userExists) {
        results.push({
          email: demoUser.email,
          status: 'already_exists',
          message: 'Usuario ya existe'
        });
        continue;
      }

      const { data: authData, error: authError } = await supabaseAdmin.auth.admin.createUser({
        email: demoUser.email,
        password: demoUser.password,
        email_confirm: true,
        user_metadata: {
          full_name: demoUser.fullName
        }
      });

      if (authError) {
        results.push({
          email: demoUser.email,
          status: 'error',
          message: authError.message
        });
        continue;
      }

      await new Promise(resolve => setTimeout(resolve, 500));

      const { error: roleError } = await supabaseAdmin
        .from('user_profiles')
        .update({ role: demoUser.role, full_name: demoUser.fullName })
        .eq('id', authData.user.id);

      if (roleError) {
        results.push({
          email: demoUser.email,
          status: 'partial_success',
          message: 'Usuario creado pero error al asignar rol: ' + roleError.message
        });
      } else {
        results.push({
          email: demoUser.email,
          status: 'success',
          role: demoUser.role,
          message: 'Usuario creado exitosamente'
        });
      }
    }

    const managerUser = results.find(r => r.email === 'manager@vidrios.com' && r.status === 'success');
    const user1 = results.find(r => r.email === 'usuario1@vidrios.com');
    const user2 = results.find(r => r.email === 'usuario2@vidrios.com');

    if (managerUser && user1 && user2) {
      const { data: managerProfile } = await supabaseAdmin
        .from('user_profiles')
        .select('id')
        .eq('email', 'manager@vidrios.com')
        .single();

      const { data: user1Profile } = await supabaseAdmin
        .from('user_profiles')
        .select('id')
        .eq('email', 'usuario1@vidrios.com')
        .single();

      const { data: user2Profile } = await supabaseAdmin
        .from('user_profiles')
        .select('id')
        .eq('email', 'usuario2@vidrios.com')
        .single();

      if (managerProfile && user1Profile && user2Profile) {
        await supabaseAdmin.from('manager_assignments').insert([
          { manager_id: managerProfile.id, user_id: user1Profile.id },
          { manager_id: managerProfile.id, user_id: user2Profile.id }
        ]);
      }
    }

    return new Response(
      JSON.stringify({
        success: true,
        message: 'Proceso de creación de usuarios completado',
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