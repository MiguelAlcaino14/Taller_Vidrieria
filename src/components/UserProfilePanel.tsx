import { useState, useEffect } from 'react';
import { User, LogOut, Shield, Users, Crown } from 'lucide-react';
import { useAuth, UserProfile } from '../contexts/AuthContext';
import { supabase } from '../lib/supabase';

export function UserProfilePanel() {
  const { profile, signOut } = useAuth();
  const [managedUsers, setManagedUsers] = useState<UserProfile[]>([]);
  const [loading, setLoading] = useState(false);

  useEffect(() => {
    if (profile?.role === 'manager') {
      loadManagedUsers();
    }
  }, [profile]);

  const loadManagedUsers = async () => {
    setLoading(true);
    try {
      const { data, error } = await supabase
        .from('manager_assignments')
        .select(`
          user_id,
          user_profiles!manager_assignments_user_id_fkey (
            id,
            email,
            full_name,
            role
          )
        `)
        .eq('manager_id', profile?.id);

      if (error) throw error;

      const users = data
        ?.map((assignment: any) => assignment.user_profiles)
        .filter(Boolean) || [];

      setManagedUsers(users);
    } catch (error) {
      console.error('Error loading managed users:', error);
    } finally {
      setLoading(false);
    }
  };

  const handleSignOut = async () => {
    try {
      await signOut();
    } catch (error) {
      console.error('Error signing out:', error);
    }
  };

  const getRoleIcon = (role: string) => {
    switch (role) {
      case 'admin':
        return <Crown className="text-yellow-600" size={20} />;
      case 'manager':
        return <Shield className="text-blue-600" size={20} />;
      default:
        return <User className="text-gray-600" size={20} />;
    }
  };

  const getRoleLabel = (role: string) => {
    switch (role) {
      case 'admin':
        return 'Administrador';
      case 'manager':
        return 'Manager';
      default:
        return 'Usuario';
    }
  };

  if (!profile) return null;

  return (
    <div className="bg-white border-b border-gray-200 px-6 py-3">
      <div className="flex items-center justify-between">
        <div className="flex items-center gap-4">
          <div className="flex items-center gap-2 px-3 py-1.5 bg-gray-50 rounded-lg">
            {getRoleIcon(profile.role)}
            <span className="text-sm font-medium text-gray-700">
              {getRoleLabel(profile.role)}
            </span>
          </div>

          <div>
            <p className="text-sm font-semibold text-gray-800">{profile.full_name}</p>
            <p className="text-xs text-gray-600">{profile.email}</p>
          </div>

          {profile.role === 'manager' && managedUsers.length > 0 && (
            <div className="flex items-center gap-2 px-3 py-1.5 bg-blue-50 rounded-lg">
              <Users size={16} className="text-blue-600" />
              <span className="text-xs text-blue-800">
                Gestionas {managedUsers.length} usuario{managedUsers.length !== 1 ? 's' : ''}
              </span>
            </div>
          )}
        </div>

        <button
          onClick={handleSignOut}
          className="flex items-center gap-2 px-4 py-2 text-sm text-red-600 hover:bg-red-50 rounded-lg transition-colors"
        >
          <LogOut size={18} />
          Cerrar Sesión
        </button>
      </div>

      {profile.role === 'manager' && managedUsers.length > 0 && (
        <div className="mt-3 pt-3 border-t border-gray-100">
          <p className="text-xs font-medium text-gray-600 mb-2">Usuarios bajo tu gestión:</p>
          <div className="flex flex-wrap gap-2">
            {managedUsers.map((user) => (
              <div
                key={user.id}
                className="flex items-center gap-1.5 px-2.5 py-1 bg-gray-100 rounded text-xs text-gray-700"
              >
                <User size={12} />
                {user.full_name}
              </div>
            ))}
          </div>
        </div>
      )}
    </div>
  );
}
