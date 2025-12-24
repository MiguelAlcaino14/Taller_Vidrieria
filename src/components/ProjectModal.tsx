import { useState, useEffect } from 'react';
import { X, Trash2 } from 'lucide-react';
import { api } from '../lib/api';
import { useAuth } from '../contexts/AuthContext';

interface ProjectModalProps {
  isOpen: boolean;
  mode: 'save' | 'load';
  onClose: () => void;
  onSave: (name: string) => void;
  onLoad: (projectId: string) => void;
}

interface SavedProject {
  id: string;
  name: string;
  sheet_width: number;
  sheet_height: number;
  created_at: string;
  cuts: any[];
}

export function ProjectModal({ isOpen, mode, onClose, onSave, onLoad }: ProjectModalProps) {
  const { user } = useAuth();
  const [projectName, setProjectName] = useState('');
  const [projects, setProjects] = useState<SavedProject[]>([]);
  const [loading, setLoading] = useState(false);

  useEffect(() => {
    if (isOpen && mode === 'load') {
      loadProjects();
    }
  }, [isOpen, mode]);

  const loadProjects = async () => {
    if (!user) return;

    setLoading(true);
    try {
      const data = await api.get<SavedProject[]>('/api/orders');
      setProjects(data || []);
    } catch (error) {
      console.error('Error loading projects:', error);
    } finally {
      setLoading(false);
    }
  };

  const handleDelete = async (id: string) => {
    if (!confirm('¿Estás seguro de eliminar este proyecto?')) return;

    try {
      await api.delete(`/api/orders/${id}`);
      setProjects(projects.filter(p => p.id !== id));
    } catch (error) {
      console.error('Error deleting project:', error);
    }
  };

  const handleSave = () => {
    if (projectName.trim()) {
      onSave(projectName.trim());
      setProjectName('');
      onClose();
    }
  };

  const handleLoad = (projectId: string) => {
    onLoad(projectId);
    onClose();
  };

  if (!isOpen) return null;

  return (
    <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50">
      <div className="bg-white rounded-lg shadow-xl max-w-2xl w-full mx-4 max-h-[80vh] overflow-hidden flex flex-col">
        <div className="flex justify-between items-center p-6 border-b">
          <h2 className="text-2xl font-bold text-gray-800">
            {mode === 'save' ? 'Guardar Proyecto' : 'Cargar Proyecto'}
          </h2>
          <button
            onClick={onClose}
            className="p-2 hover:bg-gray-100 rounded-full transition-colors"
          >
            <X size={24} />
          </button>
        </div>

        <div className="p-6 overflow-y-auto flex-1">
          {mode === 'save' ? (
            <div className="space-y-4">
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-2">
                  Nombre del proyecto
                </label>
                <input
                  type="text"
                  value={projectName}
                  onChange={(e) => setProjectName(e.target.value)}
                  onKeyPress={(e) => e.key === 'Enter' && handleSave()}
                  className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent"
                  placeholder="Ej: Proyecto Baño Principal"
                  autoFocus
                />
              </div>
              <button
                onClick={handleSave}
                disabled={!projectName.trim()}
                className="w-full px-4 py-2 bg-blue-600 hover:bg-blue-700 disabled:bg-gray-300 disabled:cursor-not-allowed text-white rounded-lg font-medium transition-colors"
              >
                Guardar Proyecto
              </button>
            </div>
          ) : (
            <div className="space-y-3">
              {loading ? (
                <p className="text-center text-gray-600 py-8">Cargando proyectos...</p>
              ) : projects.length === 0 ? (
                <p className="text-center text-gray-600 py-8">No hay proyectos guardados</p>
              ) : (
                projects.map((project) => (
                  <div
                    key={project.id}
                    className="flex items-center justify-between p-4 bg-gray-50 hover:bg-gray-100 rounded-lg transition-colors"
                  >
                    <div className="flex-1 cursor-pointer" onClick={() => handleLoad(project.id)}>
                      <div className="flex items-center gap-2 mb-1">
                        <p className="font-semibold text-gray-800">{project.name}</p>
                      </div>
                      <p className="text-sm text-gray-600">
                        Plancha: {project.sheet_width} × {project.sheet_height} cm • {project.cuts.length} cortes
                      </p>
                      <p className="text-xs text-gray-500 mt-1">
                        {new Date(project.created_at).toLocaleDateString('es-ES', {
                          year: 'numeric',
                          month: 'long',
                          day: 'numeric',
                          hour: '2-digit',
                          minute: '2-digit'
                        })}
                      </p>
                    </div>
                    <button
                      onClick={() => handleDelete(project.id)}
                      className="p-2 text-red-600 hover:bg-red-50 rounded transition-colors ml-3"
                    >
                      <Trash2 size={18} />
                    </button>
                  </div>
                ))
              )}
            </div>
          )}
        </div>
      </div>
    </div>
  );
}
