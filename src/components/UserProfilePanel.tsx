import { User, LogOut, Crown } from 'lucide-react';
import { useAuth } from '../contexts/AuthContext';

export function UserProfilePanel() {
  const { user, signOut } = useAuth();

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
      case 'operator':
        return <User className="text-blue-600" size={20} />;
      default:
        return <User className="text-gray-600" size={20} />;
    }
  };

  const getRoleLabel = (role: string) => {
    switch (role) {
      case 'admin':
        return 'Administrador';
      case 'operator':
        return 'Operador';
      default:
        return 'Usuario';
    }
  };

  if (!user) return null;

  return (
    <div className="bg-white border-b border-gray-200 px-6 py-3">
      <div className="flex items-center justify-between">
        <div className="flex items-center gap-4">
          <div className="flex items-center gap-2 px-3 py-1.5 bg-gray-50 rounded-lg">
            {getRoleIcon(user.role)}
            <span className="text-sm font-medium text-gray-700">
              {getRoleLabel(user.role)}
            </span>
          </div>

          <div>
            <p className="text-sm font-semibold text-gray-800">{user.full_name}</p>
            <p className="text-xs text-gray-600">{user.email}</p>
          </div>
        </div>

        <button
          onClick={handleSignOut}
          className="flex items-center gap-2 px-4 py-2 text-sm text-red-600 hover:bg-red-50 rounded-lg transition-colors"
        >
          <LogOut size={18} />
          Cerrar Sesión
        </button>
      </div>
    </div>
  );
}
