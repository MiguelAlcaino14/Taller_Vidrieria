import React, { useState, useEffect } from 'react';
import { Package, Plus, Filter, Search, Edit2, Trash2, AlertCircle, CheckCircle } from 'lucide-react';
import { supabase } from '../lib/supabase';
import { MaterialSheet, GlassType, MaterialType, SheetStatus, SheetOrigin } from '../types';
import { useAuth } from '../contexts/AuthContext';

interface InventoryManagementProps {
  onAddSheet: () => void;
  onEditSheet: (sheet: MaterialSheet) => void;
}

export default function InventoryManagement({ onAddSheet, onEditSheet }: InventoryManagementProps) {
  const { user, profile } = useAuth();
  const [sheets, setSheets] = useState<MaterialSheet[]>([]);
  const [glassTypes, setGlassTypes] = useState<GlassType[]>([]);
  const [loading, setLoading] = useState(true);
  const [searchTerm, setSearchTerm] = useState('');
  const [filterTab, setFilterTab] = useState<'all' | 'full' | 'remnants'>('all');
  const [filterMaterial, setFilterMaterial] = useState<MaterialType | 'all'>('all');
  const [filterStatus, setFilterStatus] = useState<SheetStatus | 'all'>('all');

  const isAdmin = profile?.role === 'admin' || profile?.role === 'manager';

  useEffect(() => {
    loadInventory();
    loadGlassTypes();
  }, []);

  const loadInventory = async () => {
    try {
      const { data, error } = await supabase
        .from('material_sheets')
        .select('*')
        .order('created_at', { ascending: false });

      if (error) throw error;
      setSheets(data || []);
    } catch (error) {
      console.error('Error loading inventory:', error);
    } finally {
      setLoading(false);
    }
  };

  const loadGlassTypes = async () => {
    try {
      const { data, error } = await supabase
        .from('glass_types')
        .select('*')
        .eq('is_active', true);

      if (error) throw error;
      setGlassTypes(data || []);
    } catch (error) {
      console.error('Error loading glass types:', error);
    }
  };

  const handleDeleteSheet = async (sheetId: string) => {
    if (!confirm('¿Está seguro de eliminar esta plancha del inventario?')) return;

    try {
      const { error } = await supabase
        .from('material_sheets')
        .delete()
        .eq('id', sheetId);

      if (error) throw error;
      loadInventory();
    } catch (error) {
      console.error('Error deleting sheet:', error);
      alert('Error al eliminar la plancha');
    }
  };

  const getGlassTypeName = (glassTypeId: string | null) => {
    if (!glassTypeId) return 'N/A';
    const glassType = glassTypes.find(gt => gt.id === glassTypeId);
    return glassType?.name || 'Desconocido';
  };

  const filteredSheets = sheets.filter(sheet => {
    if (filterTab === 'full' && sheet.origin !== 'purchase') return false;
    if (filterTab === 'remnants' && sheet.origin !== 'remnant') return false;
    if (filterMaterial !== 'all' && sheet.material_type !== filterMaterial) return false;
    if (filterStatus !== 'all' && sheet.status !== filterStatus) return false;

    if (searchTerm) {
      const term = searchTerm.toLowerCase();
      return (
        sheet.material_type.toLowerCase().includes(term) ||
        sheet.supplier?.toLowerCase().includes(term) ||
        sheet.notes?.toLowerCase().includes(term) ||
        sheet.thickness.toString().includes(term)
      );
    }

    return true;
  });

  const calculateStats = () => {
    const availableSheets = sheets.filter(s => s.status === 'available');
    const totalArea = availableSheets.reduce((sum, s) => sum + s.area_total, 0);
    const totalValue = availableSheets.reduce((sum, s) => sum + (s.purchase_cost || 0), 0);
    const fullSheets = availableSheets.filter(s => s.origin === 'purchase').length;
    const remnants = availableSheets.filter(s => s.origin === 'remnant').length;

    return { availableSheets: availableSheets.length, totalArea, totalValue, fullSheets, remnants };
  };

  const stats = calculateStats();

  const getStatusBadge = (status: SheetStatus) => {
    const styles = {
      available: 'bg-green-100 text-green-800',
      reserved: 'bg-yellow-100 text-yellow-800',
      used: 'bg-gray-100 text-gray-800',
      damaged: 'bg-red-100 text-red-800',
    };

    const labels = {
      available: 'Disponible',
      reserved: 'Reservada',
      used: 'Usada',
      damaged: 'Dañada',
    };

    return (
      <span className={`px-2 py-1 text-xs font-medium rounded-full ${styles[status]}`}>
        {labels[status]}
      </span>
    );
  };

  const getOriginBadge = (origin: SheetOrigin) => {
    return origin === 'purchase' ? (
      <span className="px-2 py-1 text-xs font-medium rounded-full bg-blue-100 text-blue-800">
        Completa
      </span>
    ) : (
      <span className="px-2 py-1 text-xs font-medium rounded-full bg-purple-100 text-purple-800">
        Sobrante
      </span>
    );
  };

  if (loading) {
    return (
      <div className="flex items-center justify-center h-64">
        <div className="text-gray-500">Cargando inventario...</div>
      </div>
    );
  }

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-3xl font-bold text-gray-900">Inventario de Material</h1>
          <p className="mt-1 text-sm text-gray-500">
            Gestión de planchas y sobrantes disponibles
          </p>
        </div>
        {isAdmin && (
          <button
            onClick={onAddSheet}
            className="flex items-center gap-2 px-4 py-2 text-white bg-blue-600 rounded-lg hover:bg-blue-700"
          >
            <Plus className="w-5 h-5" />
            Agregar Plancha
          </button>
        )}
      </div>

      <div className="grid grid-cols-1 gap-4 sm:grid-cols-2 lg:grid-cols-5">
        <div className="p-4 bg-white rounded-lg shadow">
          <div className="flex items-center gap-3">
            <div className="p-2 bg-blue-100 rounded-lg">
              <Package className="w-6 h-6 text-blue-600" />
            </div>
            <div>
              <p className="text-sm text-gray-500">Total Disponibles</p>
              <p className="text-2xl font-bold text-gray-900">{stats.availableSheets}</p>
            </div>
          </div>
        </div>

        <div className="p-4 bg-white rounded-lg shadow">
          <div className="flex items-center gap-3">
            <div className="p-2 bg-green-100 rounded-lg">
              <CheckCircle className="w-6 h-6 text-green-600" />
            </div>
            <div>
              <p className="text-sm text-gray-500">Planchas Completas</p>
              <p className="text-2xl font-bold text-gray-900">{stats.fullSheets}</p>
            </div>
          </div>
        </div>

        <div className="p-4 bg-white rounded-lg shadow">
          <div className="flex items-center gap-3">
            <div className="p-2 bg-purple-100 rounded-lg">
              <Package className="w-6 h-6 text-purple-600" />
            </div>
            <div>
              <p className="text-sm text-gray-500">Sobrantes</p>
              <p className="text-2xl font-bold text-gray-900">{stats.remnants}</p>
            </div>
          </div>
        </div>

        <div className="p-4 bg-white rounded-lg shadow">
          <div>
            <p className="text-sm text-gray-500">Área Total</p>
            <p className="text-2xl font-bold text-gray-900">
              {(stats.totalArea / 1000000).toFixed(2)} m²
            </p>
          </div>
        </div>

        <div className="p-4 bg-white rounded-lg shadow">
          <div>
            <p className="text-sm text-gray-500">Valor Inventario</p>
            <p className="text-2xl font-bold text-gray-900">
              ${stats.totalValue.toFixed(2)}
            </p>
          </div>
        </div>
      </div>

      <div className="bg-white rounded-lg shadow">
        <div className="p-6 border-b border-gray-200">
          <div className="flex flex-col gap-4 sm:flex-row sm:items-center sm:justify-between">
            <div className="flex gap-2">
              <button
                onClick={() => setFilterTab('all')}
                className={`px-4 py-2 text-sm font-medium rounded-lg ${
                  filterTab === 'all'
                    ? 'bg-blue-600 text-white'
                    : 'bg-gray-100 text-gray-700 hover:bg-gray-200'
                }`}
              >
                Todas ({sheets.length})
              </button>
              <button
                onClick={() => setFilterTab('full')}
                className={`px-4 py-2 text-sm font-medium rounded-lg ${
                  filterTab === 'full'
                    ? 'bg-blue-600 text-white'
                    : 'bg-gray-100 text-gray-700 hover:bg-gray-200'
                }`}
              >
                Completas ({sheets.filter(s => s.origin === 'purchase').length})
              </button>
              <button
                onClick={() => setFilterTab('remnants')}
                className={`px-4 py-2 text-sm font-medium rounded-lg ${
                  filterTab === 'remnants'
                    ? 'bg-blue-600 text-white'
                    : 'bg-gray-100 text-gray-700 hover:bg-gray-200'
                }`}
              >
                Sobrantes ({sheets.filter(s => s.origin === 'remnant').length})
              </button>
            </div>

            <div className="flex gap-2">
              <div className="relative flex-1 sm:w-64">
                <Search className="absolute w-5 h-5 text-gray-400 left-3 top-2.5" />
                <input
                  type="text"
                  placeholder="Buscar..."
                  value={searchTerm}
                  onChange={(e) => setSearchTerm(e.target.value)}
                  className="w-full py-2 pl-10 pr-4 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent"
                />
              </div>
              <select
                value={filterMaterial}
                onChange={(e) => setFilterMaterial(e.target.value as MaterialType | 'all')}
                className="px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent"
              >
                <option value="all">Todos los materiales</option>
                <option value="glass">Vidrio</option>
                <option value="mirror">Espejo</option>
                <option value="aluminum">Aluminio</option>
              </select>
              <select
                value={filterStatus}
                onChange={(e) => setFilterStatus(e.target.value as SheetStatus | 'all')}
                className="px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent"
              >
                <option value="all">Todos los estados</option>
                <option value="available">Disponible</option>
                <option value="reserved">Reservada</option>
                <option value="used">Usada</option>
                <option value="damaged">Dañada</option>
              </select>
            </div>
          </div>
        </div>

        <div className="p-6">
          {filteredSheets.length === 0 ? (
            <div className="py-12 text-center">
              <Package className="w-12 h-12 mx-auto text-gray-400" />
              <h3 className="mt-2 text-sm font-medium text-gray-900">No hay planchas</h3>
              <p className="mt-1 text-sm text-gray-500">
                {isAdmin
                  ? 'Comience agregando planchas al inventario.'
                  : 'No hay material disponible en el inventario.'}
              </p>
            </div>
          ) : (
            <div className="grid grid-cols-1 gap-4 md:grid-cols-2 lg:grid-cols-3">
              {filteredSheets.map((sheet) => (
                <div
                  key={sheet.id}
                  className="p-4 border border-gray-200 rounded-lg hover:shadow-md transition-shadow"
                >
                  <div className="flex items-start justify-between mb-3">
                    <div className="flex gap-2">
                      {getOriginBadge(sheet.origin)}
                      {getStatusBadge(sheet.status)}
                    </div>
                    {isAdmin && sheet.status !== 'used' && (
                      <div className="flex gap-1">
                        <button
                          onClick={() => onEditSheet(sheet)}
                          className="p-1 text-gray-400 hover:text-blue-600"
                          title="Editar"
                        >
                          <Edit2 className="w-4 h-4" />
                        </button>
                        <button
                          onClick={() => handleDeleteSheet(sheet.id)}
                          className="p-1 text-gray-400 hover:text-red-600"
                          title="Eliminar"
                        >
                          <Trash2 className="w-4 h-4" />
                        </button>
                      </div>
                    )}
                  </div>

                  <div className="space-y-2">
                    <div>
                      <p className="text-lg font-semibold text-gray-900 capitalize">
                        {sheet.material_type === 'glass' ? 'Vidrio' : sheet.material_type === 'mirror' ? 'Espejo' : 'Aluminio'}
                        {sheet.glass_type_id && ` - ${getGlassTypeName(sheet.glass_type_id)}`}
                      </p>
                      <p className="text-sm text-gray-500">
                        Espesor: {sheet.thickness}mm
                      </p>
                    </div>

                    <div className="p-3 bg-gray-50 rounded">
                      <p className="text-2xl font-bold text-center text-gray-900">
                        {(sheet.width / 10).toFixed(0)} x {(sheet.height / 10).toFixed(0)} cm
                      </p>
                      <p className="text-xs text-center text-gray-500 mt-1">
                        Área: {(sheet.area_total / 1000000).toFixed(2)} m²
                      </p>
                    </div>

                    {sheet.supplier && (
                      <p className="text-sm text-gray-600">
                        <span className="font-medium">Proveedor:</span> {sheet.supplier}
                      </p>
                    )}

                    {sheet.purchase_cost > 0 && (
                      <p className="text-sm text-gray-600">
                        <span className="font-medium">Costo:</span> ${sheet.purchase_cost.toFixed(2)}
                      </p>
                    )}

                    {sheet.notes && (
                      <p className="text-xs text-gray-500 italic">
                        {sheet.notes}
                      </p>
                    )}

                    <p className="text-xs text-gray-400">
                      Agregada: {new Date(sheet.purchase_date).toLocaleDateString()}
                    </p>
                  </div>
                </div>
              ))}
            </div>
          )}
        </div>
      </div>
    </div>
  );
}
