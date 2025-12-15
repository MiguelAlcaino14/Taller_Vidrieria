import React, { useState, useEffect } from 'react';
import { X, Package, TrendingUp, DollarSign, Sparkles, CheckCircle } from 'lucide-react';
import { supabase } from '../lib/supabase';
import { Order, MaterialSheet, OptimizationSuggestion } from '../types';
import { generateMaterialSuggestions } from '../utils/materialSuggestions';
import { useAuth } from '../contexts/AuthContext';

interface MaterialAssignmentProps {
  order: Order;
  onClose: () => void;
  onSuccess: () => void;
}

export default function MaterialAssignment({ order, onClose, onSuccess }: MaterialAssignmentProps) {
  const { user } = useAuth();
  const [loading, setLoading] = useState(true);
  const [assigning, setAssigning] = useState(false);
  const [suggestions, setSuggestions] = useState<OptimizationSuggestion[]>([]);
  const [selectedSuggestion, setSelectedSuggestion] = useState<OptimizationSuggestion | null>(null);
  const [error, setError] = useState('');

  useEffect(() => {
    loadSuggestions();
  }, [order]);

  const loadSuggestions = async () => {
    setLoading(true);
    setError('');

    try {
      const { data: sheets, error: sheetsError } = await supabase
        .from('material_sheets')
        .select('*')
        .eq('status', 'available');

      if (sheetsError) throw sheetsError;

      const result = await generateMaterialSuggestions({
        cuts: order.cuts,
        availableSheets: sheets as MaterialSheet[],
        materialType: 'glass',
        thickness: order.glass_thickness,
        cutThickness: order.cut_thickness,
        cuttingMethod: order.cutting_method,
        maxSuggestions: 5
      });

      if (result.suggestions.length === 0) {
        setError('No se encontraron combinaciones de material disponibles para completar este pedido. Necesita agregar más planchas al inventario.');
      } else {
        setSuggestions(result.suggestions);
        setSelectedSuggestion(result.bestSuggestion);
      }
    } catch (error: any) {
      console.error('Error generating suggestions:', error);
      setError('Error al generar sugerencias de material');
    } finally {
      setLoading(false);
    }
  };

  const handleAssignMaterial = async () => {
    if (!selectedSuggestion) return;

    setAssigning(true);
    setError('');

    try {
      const { data: savedSuggestion, error: suggestionError } = await supabase
        .from('optimization_suggestions')
        .insert([{
          order_id: order.id,
          suggestion_number: selectedSuggestion.suggestion_number,
          sheets_used: selectedSuggestion.sheets_used,
          sheet_details: selectedSuggestion.sheet_details,
          total_utilization: selectedSuggestion.total_utilization,
          total_waste: selectedSuggestion.total_waste,
          estimated_remnants: selectedSuggestion.estimated_remnants,
          total_cost: selectedSuggestion.total_cost,
          uses_remnants: selectedSuggestion.uses_remnants
        }])
        .select()
        .single();

      if (suggestionError) throw suggestionError;

      for (const sheetDetail of selectedSuggestion.sheet_details) {
        const { error: assignmentError } = await supabase
          .from('sheet_assignments')
          .insert([{
            order_id: order.id,
            sheet_id: sheetDetail.sheet_id,
            assigned_by: user!.id,
            cuts_assigned: sheetDetail.cuts,
            status: 'pending',
            utilization_percentage: sheetDetail.utilization,
            waste_area: sheetDetail.waste_area
          }]);

        if (assignmentError) throw assignmentError;

        const { error: sheetUpdateError } = await supabase
          .from('material_sheets')
          .update({ status: 'reserved' })
          .eq('id', sheetDetail.sheet_id);

        if (sheetUpdateError) throw sheetUpdateError;
      }

      const { error: orderUpdateError } = await supabase
        .from('glass_projects')
        .update({
          material_status: 'assigned',
          optimization_id: savedSuggestion.id,
          assigned_sheets: selectedSuggestion.sheets_used,
          estimated_waste: selectedSuggestion.total_waste,
          material_cost: selectedSuggestion.total_cost
        })
        .eq('id', order.id);

      if (orderUpdateError) throw orderUpdateError;

      onSuccess();
      onClose();
    } catch (error: any) {
      console.error('Error assigning material:', error);
      setError(error.message || 'Error al asignar material');
    } finally {
      setAssigning(false);
    }
  };

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center bg-black bg-opacity-50 p-4">
      <div className="w-full max-w-6xl bg-white rounded-lg shadow-xl max-h-[90vh] overflow-y-auto">
        <div className="sticky top-0 z-10 flex items-center justify-between p-6 bg-white border-b border-gray-200">
          <div>
            <h2 className="text-2xl font-bold text-gray-900">Asignación de Material</h2>
            <p className="mt-1 text-sm text-gray-500">
              Orden #{order.order_number} - {order.name}
            </p>
          </div>
          <button
            onClick={onClose}
            className="p-2 text-gray-400 hover:text-gray-600"
          >
            <X className="w-6 h-6" />
          </button>
        </div>

        <div className="p-6">
          {error && (
            <div className="p-4 mb-6 text-red-800 bg-red-100 border border-red-200 rounded-lg">
              {error}
            </div>
          )}

          {loading ? (
            <div className="flex items-center justify-center py-12">
              <div className="text-center">
                <div className="w-12 h-12 mx-auto mb-4 border-4 border-blue-600 border-t-transparent rounded-full animate-spin"></div>
                <p className="text-gray-500">Analizando inventario y generando sugerencias...</p>
              </div>
            </div>
          ) : suggestions.length === 0 ? (
            <div className="py-12 text-center">
              <Package className="w-16 h-16 mx-auto text-gray-400" />
              <h3 className="mt-4 text-lg font-medium text-gray-900">
                No hay material suficiente
              </h3>
              <p className="mt-2 text-sm text-gray-500">
                No se encontraron combinaciones de material disponibles para completar este pedido.
              </p>
            </div>
          ) : (
            <>
              <div className="mb-6">
                <h3 className="text-lg font-semibold text-gray-900 mb-2">
                  Sugerencias de Material (se encontraron {suggestions.length})
                </h3>
                <p className="text-sm text-gray-600">
                  Seleccione la mejor opción según disponibilidad, costo y aprovechamiento
                </p>
              </div>

              <div className="space-y-4">
                {suggestions.map((suggestion, index) => (
                  <div
                    key={suggestion.id}
                    className={`border-2 rounded-lg p-4 cursor-pointer transition-all ${
                      selectedSuggestion?.id === suggestion.id
                        ? 'border-blue-600 bg-blue-50'
                        : 'border-gray-200 hover:border-blue-300'
                    }`}
                    onClick={() => setSelectedSuggestion(suggestion)}
                  >
                    <div className="flex items-start justify-between">
                      <div className="flex-1">
                        <div className="flex items-center gap-3 mb-3">
                          <h4 className="text-lg font-semibold text-gray-900">
                            Opción {index + 1}
                            {index === 0 && (
                              <span className="ml-2 text-sm font-normal text-blue-600">
                                (Recomendada)
                              </span>
                            )}
                          </h4>
                          {suggestion.uses_remnants && (
                            <span className="px-2 py-1 text-xs font-medium text-purple-800 bg-purple-100 rounded-full flex items-center gap-1">
                              <Sparkles className="w-3 h-3" />
                              Usa sobrantes
                            </span>
                          )}
                        </div>

                        <div className="grid grid-cols-2 gap-4 mb-4 sm:grid-cols-4">
                          <div className="flex items-center gap-2">
                            <Package className="w-5 h-5 text-gray-400" />
                            <div>
                              <p className="text-xs text-gray-500">Planchas</p>
                              <p className="text-lg font-semibold text-gray-900">
                                {suggestion.sheets_used.length}
                              </p>
                            </div>
                          </div>

                          <div className="flex items-center gap-2">
                            <TrendingUp className="w-5 h-5 text-gray-400" />
                            <div>
                              <p className="text-xs text-gray-500">Aprovechamiento</p>
                              <p className="text-lg font-semibold text-green-600">
                                {suggestion.total_utilization.toFixed(1)}%
                              </p>
                            </div>
                          </div>

                          <div className="flex items-center gap-2">
                            <Package className="w-5 h-5 text-gray-400" />
                            <div>
                              <p className="text-xs text-gray-500">Desperdicio</p>
                              <p className="text-lg font-semibold text-orange-600">
                                {(suggestion.total_waste / 1000000).toFixed(2)} m²
                              </p>
                            </div>
                          </div>

                          <div className="flex items-center gap-2">
                            <DollarSign className="w-5 h-5 text-gray-400" />
                            <div>
                              <p className="text-xs text-gray-500">Costo Material</p>
                              <p className="text-lg font-semibold text-gray-900">
                                ${suggestion.total_cost.toFixed(2)}
                              </p>
                            </div>
                          </div>
                        </div>

                        <div className="space-y-2">
                          <p className="text-sm font-medium text-gray-700">
                            Material a utilizar:
                          </p>
                          {suggestion.sheet_details.map((sheetDetail, sheetIndex) => (
                            <div
                              key={sheetDetail.sheet_id}
                              className="p-3 bg-gray-50 rounded border border-gray-200"
                            >
                              <div className="flex items-center justify-between">
                                <div>
                                  <p className="font-medium text-gray-900">
                                    Plancha {sheetIndex + 1}:{' '}
                                    <span className="capitalize">{sheetDetail.sheet.material_type}</span>
                                    {' '}
                                    {(sheetDetail.sheet.width / 10).toFixed(0)} x{' '}
                                    {(sheetDetail.sheet.height / 10).toFixed(0)} cm
                                    {' '}
                                    ({sheetDetail.sheet.thickness}mm)
                                  </p>
                                  <p className="text-sm text-gray-600">
                                    {sheetDetail.sheet.origin === 'purchase' ? 'Plancha completa' : 'Sobrante'} •
                                    {' '}{sheetDetail.cuts.length} cortes asignados •
                                    {' '}Aprovechamiento: {sheetDetail.utilization.toFixed(1)}%
                                  </p>
                                </div>
                              </div>
                            </div>
                          ))}
                        </div>
                      </div>

                      {selectedSuggestion?.id === suggestion.id && (
                        <div className="ml-4">
                          <div className="p-2 bg-blue-600 rounded-full">
                            <CheckCircle className="w-6 h-6 text-white" />
                          </div>
                        </div>
                      )}
                    </div>
                  </div>
                ))}
              </div>

              <div className="flex justify-end gap-3 pt-6 mt-6 border-t border-gray-200">
                <button
                  onClick={onClose}
                  className="px-6 py-2 text-gray-700 bg-gray-100 rounded-lg hover:bg-gray-200"
                  disabled={assigning}
                >
                  Cancelar
                </button>
                <button
                  onClick={handleAssignMaterial}
                  className="px-6 py-2 text-white bg-blue-600 rounded-lg hover:bg-blue-700 disabled:bg-blue-300 flex items-center gap-2"
                  disabled={!selectedSuggestion || assigning}
                >
                  {assigning ? (
                    <>
                      <div className="w-4 h-4 border-2 border-white border-t-transparent rounded-full animate-spin"></div>
                      Asignando...
                    </>
                  ) : (
                    'Asignar Material Seleccionado'
                  )}
                </button>
              </div>
            </>
          )}
        </div>
      </div>
    </div>
  );
}
