import React, { useState, useEffect } from 'react';
import { X } from 'lucide-react';
import { supabase } from '../lib/supabase';
import { MaterialSheet, MaterialType, GlassType } from '../types';
import { useAuth } from '../contexts/AuthContext';

interface AddSheetModalProps {
  isOpen: boolean;
  onClose: () => void;
  onSuccess: () => void;
  editSheet?: MaterialSheet | null;
}

export default function AddSheetModal({ isOpen, onClose, onSuccess, editSheet }: AddSheetModalProps) {
  const { user } = useAuth();
  const [glassTypes, setGlassTypes] = useState<GlassType[]>([]);
  const [formData, setFormData] = useState({
    material_type: 'glass' as MaterialType,
    glass_type_id: '',
    thickness: '',
    width: '',
    height: '',
    purchase_cost: '',
    supplier: '',
    notes: '',
  });
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState('');

  useEffect(() => {
    if (isOpen) {
      loadGlassTypes();
      if (editSheet) {
        setFormData({
          material_type: editSheet.material_type,
          glass_type_id: editSheet.glass_type_id || '',
          thickness: editSheet.thickness.toString(),
          width: (editSheet.width / 10).toString(),
          height: (editSheet.height / 10).toString(),
          purchase_cost: editSheet.purchase_cost?.toString() || '',
          supplier: editSheet.supplier || '',
          notes: editSheet.notes || '',
        });
      } else {
        resetForm();
      }
    }
  }, [isOpen, editSheet]);

  const loadGlassTypes = async () => {
    try {
      const { data, error } = await supabase
        .from('glass_types')
        .select('*')
        .eq('is_active', true)
        .order('name');

      if (error) throw error;
      setGlassTypes(data || []);
    } catch (error) {
      console.error('Error loading glass types:', error);
    }
  };

  const resetForm = () => {
    setFormData({
      material_type: 'glass',
      glass_type_id: '',
      thickness: '',
      width: '',
      height: '',
      purchase_cost: '',
      supplier: '',
      notes: '',
    });
    setError('');
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setError('');

    if (!formData.thickness || !formData.width || !formData.height) {
      setError('Por favor complete todos los campos requeridos');
      return;
    }

    setLoading(true);

    try {
      const sheetData = {
        user_id: user!.id,
        material_type: formData.material_type,
        glass_type_id: formData.glass_type_id || null,
        thickness: parseFloat(formData.thickness),
        width: parseFloat(formData.width) * 10,
        height: parseFloat(formData.height) * 10,
        purchase_cost: formData.purchase_cost ? parseFloat(formData.purchase_cost) : 0,
        supplier: formData.supplier || '',
        notes: formData.notes || '',
        status: 'available',
        origin: 'purchase',
      };

      if (editSheet) {
        const { error } = await supabase
          .from('material_sheets')
          .update(sheetData)
          .eq('id', editSheet.id);

        if (error) throw error;
      } else {
        const { error } = await supabase
          .from('material_sheets')
          .insert([sheetData]);

        if (error) throw error;
      }

      onSuccess();
      onClose();
      resetForm();
    } catch (error: any) {
      console.error('Error saving sheet:', error);
      setError(error.message || 'Error al guardar la plancha');
    } finally {
      setLoading(false);
    }
  };

  if (!isOpen) return null;

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center bg-black bg-opacity-50">
      <div className="w-full max-w-2xl p-6 bg-white rounded-lg shadow-xl max-h-[90vh] overflow-y-auto">
        <div className="flex items-center justify-between mb-6">
          <h2 className="text-2xl font-bold text-gray-900">
            {editSheet ? 'Editar Plancha' : 'Agregar Plancha al Inventario'}
          </h2>
          <button
            onClick={onClose}
            className="p-2 text-gray-400 hover:text-gray-600"
          >
            <X className="w-6 h-6" />
          </button>
        </div>

        {error && (
          <div className="p-4 mb-4 text-red-800 bg-red-100 border border-red-200 rounded-lg">
            {error}
          </div>
        )}

        <form onSubmit={handleSubmit} className="space-y-6">
          <div className="grid grid-cols-1 gap-6 md:grid-cols-2">
            <div>
              <label className="block mb-2 text-sm font-medium text-gray-700">
                Tipo de Material *
              </label>
              <select
                value={formData.material_type}
                onChange={(e) => setFormData({ ...formData, material_type: e.target.value as MaterialType })}
                className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent"
                required
              >
                <option value="glass">Vidrio</option>
                <option value="mirror">Espejo</option>
                <option value="aluminum">Aluminio</option>
              </select>
            </div>

            {(formData.material_type === 'glass' || formData.material_type === 'mirror') && (
              <div>
                <label className="block mb-2 text-sm font-medium text-gray-700">
                  Tipo de Vidrio
                </label>
                <select
                  value={formData.glass_type_id}
                  onChange={(e) => setFormData({ ...formData, glass_type_id: e.target.value })}
                  className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent"
                >
                  <option value="">Seleccione tipo (opcional)</option>
                  {glassTypes.map((type) => (
                    <option key={type.id} value={type.id}>
                      {type.name}
                    </option>
                  ))}
                </select>
              </div>
            )}

            <div>
              <label className="block mb-2 text-sm font-medium text-gray-700">
                Espesor (mm) *
              </label>
              <input
                type="number"
                step="0.1"
                value={formData.thickness}
                onChange={(e) => setFormData({ ...formData, thickness: e.target.value })}
                className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent"
                placeholder="Ej: 6"
                required
              />
            </div>

            <div>
              <label className="block mb-2 text-sm font-medium text-gray-700">
                Ancho (cm) *
              </label>
              <input
                type="number"
                step="0.1"
                value={formData.width}
                onChange={(e) => setFormData({ ...formData, width: e.target.value })}
                className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent"
                placeholder="Ej: 240"
                required
              />
            </div>

            <div>
              <label className="block mb-2 text-sm font-medium text-gray-700">
                Alto (cm) *
              </label>
              <input
                type="number"
                step="0.1"
                value={formData.height}
                onChange={(e) => setFormData({ ...formData, height: e.target.value })}
                className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent"
                placeholder="Ej: 320"
                required
              />
            </div>

            <div>
              <label className="block mb-2 text-sm font-medium text-gray-700">
                Costo de Compra ($)
              </label>
              <input
                type="number"
                step="0.01"
                value={formData.purchase_cost}
                onChange={(e) => setFormData({ ...formData, purchase_cost: e.target.value })}
                className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent"
                placeholder="Ej: 150.00"
              />
            </div>

            <div>
              <label className="block mb-2 text-sm font-medium text-gray-700">
                Proveedor
              </label>
              <input
                type="text"
                value={formData.supplier}
                onChange={(e) => setFormData({ ...formData, supplier: e.target.value })}
                className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent"
                placeholder="Nombre del proveedor"
              />
            </div>
          </div>

          <div>
            <label className="block mb-2 text-sm font-medium text-gray-700">
              Notas
            </label>
            <textarea
              value={formData.notes}
              onChange={(e) => setFormData({ ...formData, notes: e.target.value })}
              rows={3}
              className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent"
              placeholder="Notas adicionales sobre la plancha..."
            />
          </div>

          {formData.width && formData.height && (
            <div className="p-4 bg-blue-50 border border-blue-200 rounded-lg">
              <p className="text-sm font-medium text-blue-900">
                Área total: {((parseFloat(formData.width) * parseFloat(formData.height)) / 10000).toFixed(2)} m²
              </p>
            </div>
          )}

          <div className="flex justify-end gap-3 pt-4 border-t border-gray-200">
            <button
              type="button"
              onClick={onClose}
              className="px-4 py-2 text-gray-700 bg-gray-100 rounded-lg hover:bg-gray-200"
              disabled={loading}
            >
              Cancelar
            </button>
            <button
              type="submit"
              className="px-4 py-2 text-white bg-blue-600 rounded-lg hover:bg-blue-700 disabled:bg-blue-300"
              disabled={loading}
            >
              {loading ? 'Guardando...' : editSheet ? 'Actualizar' : 'Agregar'}
            </button>
          </div>
        </form>
      </div>
    </div>
  );
}
