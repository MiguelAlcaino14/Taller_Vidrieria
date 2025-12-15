import React, { useState, useEffect } from 'react';
import { X, CheckCircle, Square, Scissors, AlertCircle, Package } from 'lucide-react';
import { supabase } from '../lib/supabase';
import { Order, SheetAssignment, MaterialSheet, GeneratedRemnant } from '../types';
import { useAuth } from '../contexts/AuthContext';
import { calculateRemnants } from '../utils/remnants';

interface CuttingExecutionProps {
  order: Order;
  onClose: () => void;
  onSuccess: () => void;
}

export default function CuttingExecution({ order, onClose, onSuccess }: CuttingExecutionProps) {
  const { user } = useAuth();
  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);
  const [assignments, setAssignments] = useState<(SheetAssignment & { sheet: MaterialSheet })[]>([]);
  const [completedCuts, setCompletedCuts] = useState<Set<string>>(new Set());
  const [failedPieces, setFailedPieces] = useState(0);
  const [notes, setNotes] = useState('');

  useEffect(() => {
    loadAssignments();
  }, [order]);

  const loadAssignments = async () => {
    setLoading(true);
    try {
      const { data, error } = await supabase
        .from('sheet_assignments')
        .select(`
          *,
          sheet:material_sheets(*)
        `)
        .eq('order_id', order.id)
        .neq('status', 'cancelled');

      if (error) throw error;

      setAssignments(data as any || []);
    } catch (error) {
      console.error('Error loading assignments:', error);
    } finally {
      setLoading(false);
    }
  };

  const toggleCut = (assignmentId: string, cutId: string) => {
    const key = `${assignmentId}-${cutId}`;
    const newCompleted = new Set(completedCuts);

    if (newCompleted.has(key)) {
      newCompleted.delete(key);
    } else {
      newCompleted.add(key);
    }

    setCompletedCuts(newCompleted);
  };

  const handleCompleteCutting = async () => {
    setSaving(true);
    try {
      const totalCuts = assignments.reduce((sum, a) => sum + a.cuts_assigned.length, 0);
      const successful = completedCuts.size - failedPieces;

      for (const assignment of assignments) {
        const assignmentCuts = assignment.cuts_assigned.map(c => c.cut.id);
        const assignmentCompleted = assignmentCuts.every(
          cutId => completedCuts.has(`${assignment.id}-${cutId}`)
        );

        if (assignmentCompleted) {
          const sheetForCalculation = {
            width: assignment.sheet.width,
            height: assignment.sheet.height,
            cutThickness: 3,
            glassThickness: assignment.sheet.thickness,
            cuttingMethod: 'manual' as const
          };

          const remnants = calculateRemnants(
            assignment.cuts_assigned,
            sheetForCalculation
          );

          const generatedRemnants: GeneratedRemnant[] = remnants.map(r => ({
            x: r.x,
            y: r.y,
            width: r.width,
            height: r.height
          }));

          const { error: logError } = await supabase
            .from('cut_logs')
            .insert([{
              order_id: order.id,
              sheet_id: assignment.sheet_id,
              assignment_id: assignment.id,
              operator_id: user!.id,
              successful_pieces: assignment.cuts_assigned.length,
              failed_pieces: 0,
              generated_remnants: generatedRemnants,
              notes: notes
            }]);

          if (logError) throw logError;

          const { error: assignmentError } = await supabase
            .from('sheet_assignments')
            .update({
              status: 'completed',
              completed_date: new Date().toISOString()
            })
            .eq('id', assignment.id);

          if (assignmentError) throw assignmentError;

          const { error: sheetError } = await supabase
            .from('material_sheets')
            .update({ status: 'used' })
            .eq('id', assignment.sheet_id);

          if (sheetError) throw sheetError;

          for (const remnant of remnants) {
            if (remnant.width >= 200 && remnant.height >= 200) {
              const { error: remnantError } = await supabase
                .from('material_sheets')
                .insert([{
                  user_id: user!.id,
                  material_type: assignment.sheet.material_type,
                  glass_type_id: assignment.sheet.glass_type_id,
                  thickness: assignment.sheet.thickness,
                  width: remnant.width,
                  height: remnant.height,
                  origin: 'remnant',
                  parent_sheet_id: assignment.sheet_id,
                  source_order_id: order.id,
                  status: 'available',
                  purchase_cost: 0,
                  supplier: assignment.sheet.supplier,
                  notes: `Sobrante generado de orden #${order.order_number}`
                }]);

              if (remnantError) throw remnantError;
            }
          }
        }
      }

      const allCompleted = assignments.every(a => {
        const assignmentCuts = a.cuts_assigned.map(c => c.cut.id);
        return assignmentCuts.every(cutId => completedCuts.has(`${a.id}-${cutId}`));
      });

      if (allCompleted) {
        const { error: orderError } = await supabase
          .from('glass_projects')
          .update({
            material_status: 'completed',
            status: 'in_production'
          })
          .eq('id', order.id);

        if (orderError) throw orderError;
      } else {
        const { error: orderError } = await supabase
          .from('glass_projects')
          .update({
            material_status: 'cutting'
          })
          .eq('id', order.id);

        if (orderError) throw orderError;
      }

      onSuccess();
      onClose();
    } catch (error: any) {
      console.error('Error completing cutting:', error);
      alert('Error al completar el corte: ' + error.message);
    } finally {
      setSaving(false);
    }
  };

  const getProgress = () => {
    const total = assignments.reduce((sum, a) => sum + a.cuts_assigned.length, 0);
    const completed = completedCuts.size;
    return { completed, total, percentage: total > 0 ? (completed / total) * 100 : 0 };
  };

  const progress = getProgress();

  if (loading) {
    return (
      <div className="fixed inset-0 z-50 flex items-center justify-center bg-black bg-opacity-50">
        <div className="p-8 bg-white rounded-lg">
          <div className="text-center">
            <div className="w-12 h-12 mx-auto mb-4 border-4 border-blue-600 border-t-transparent rounded-full animate-spin"></div>
            <p className="text-gray-500">Cargando plan de corte...</p>
          </div>
        </div>
      </div>
    );
  }

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center bg-black bg-opacity-50 p-4">
      <div className="w-full max-w-4xl bg-white rounded-lg shadow-xl max-h-[90vh] overflow-y-auto">
        <div className="sticky top-0 z-10 flex items-center justify-between p-6 bg-white border-b border-gray-200">
          <div>
            <h2 className="text-2xl font-bold text-gray-900">Ejecución de Corte</h2>
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
          <div className="mb-6">
            <div className="flex items-center justify-between mb-2">
              <h3 className="text-lg font-semibold text-gray-900">
                Progreso de Corte
              </h3>
              <span className="text-sm font-medium text-gray-600">
                {progress.completed} de {progress.total} cortes ({progress.percentage.toFixed(0)}%)
              </span>
            </div>
            <div className="w-full h-4 bg-gray-200 rounded-full overflow-hidden">
              <div
                className="h-full bg-blue-600 transition-all duration-300"
                style={{ width: `${progress.percentage}%` }}
              />
            </div>
          </div>

          {assignments.length === 0 ? (
            <div className="py-12 text-center">
              <AlertCircle className="w-12 h-12 mx-auto text-gray-400" />
              <h3 className="mt-2 text-lg font-medium text-gray-900">
                No hay material asignado
              </h3>
              <p className="mt-1 text-sm text-gray-500">
                Esta orden aún no tiene material asignado para corte.
              </p>
            </div>
          ) : (
            <div className="space-y-6">
              {assignments.map((assignment, index) => (
                <div
                  key={assignment.id}
                  className="p-4 border-2 border-gray-200 rounded-lg"
                >
                  <div className="flex items-start justify-between mb-4">
                    <div>
                      <h4 className="text-lg font-semibold text-gray-900 flex items-center gap-2">
                        <Package className="w-5 h-5" />
                        Plancha {index + 1}
                      </h4>
                      <p className="text-sm text-gray-600">
                        {(assignment.sheet.width / 10).toFixed(0)} x{' '}
                        {(assignment.sheet.height / 10).toFixed(0)} cm •{' '}
                        {assignment.sheet.thickness}mm •{' '}
                        <span className="capitalize">{assignment.sheet.material_type}</span>
                      </p>
                      <p className="text-sm text-gray-500">
                        {assignment.sheet.origin === 'purchase' ? 'Plancha completa' : 'Sobrante'} •
                        Aprovechamiento: {assignment.utilization_percentage.toFixed(1)}%
                      </p>
                    </div>
                    <span className={`px-3 py-1 text-sm font-medium rounded-full ${
                      assignment.status === 'completed'
                        ? 'bg-green-100 text-green-800'
                        : assignment.status === 'in_progress'
                        ? 'bg-blue-100 text-blue-800'
                        : 'bg-gray-100 text-gray-800'
                    }`}>
                      {assignment.status === 'completed' ? 'Completada' :
                       assignment.status === 'in_progress' ? 'En Progreso' : 'Pendiente'}
                    </span>
                  </div>

                  <div className="space-y-2">
                    <p className="text-sm font-medium text-gray-700 flex items-center gap-2">
                      <Scissors className="w-4 h-4" />
                      Cortes a realizar ({assignment.cuts_assigned.length}):
                    </p>
                    {assignment.cuts_assigned.map((placedCut, cutIndex) => {
                      const isCompleted = completedCuts.has(`${assignment.id}-${placedCut.cut.id}`);
                      return (
                        <div
                          key={placedCut.cut.id}
                          className={`flex items-center gap-3 p-3 rounded border-2 cursor-pointer transition-all ${
                            isCompleted
                              ? 'border-green-500 bg-green-50'
                              : 'border-gray-200 hover:border-blue-300'
                          }`}
                          onClick={() => toggleCut(assignment.id, placedCut.cut.id)}
                        >
                          {isCompleted ? (
                            <CheckCircle className="w-6 h-6 text-green-600 flex-shrink-0" />
                          ) : (
                            <Square className="w-6 h-6 text-gray-400 flex-shrink-0" />
                          )}
                          <div className="flex-1">
                            <p className="font-medium text-gray-900">
                              {placedCut.cut.label || `Corte ${cutIndex + 1}`}
                            </p>
                            <p className="text-sm text-gray-600">
                              {(placedCut.cut.width / 10).toFixed(1)} x{' '}
                              {(placedCut.cut.height / 10).toFixed(1)} cm
                              {placedCut.cut.quantity > 1 && ` × ${placedCut.cut.quantity}`}
                            </p>
                          </div>
                        </div>
                      );
                    })}
                  </div>
                </div>
              ))}

              <div className="p-4 bg-yellow-50 border border-yellow-200 rounded-lg">
                <label className="block mb-2 text-sm font-medium text-gray-700">
                  Piezas Fallidas (opcional)
                </label>
                <input
                  type="number"
                  min="0"
                  value={failedPieces}
                  onChange={(e) => setFailedPieces(parseInt(e.target.value) || 0)}
                  className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent"
                  placeholder="0"
                />
                <p className="mt-1 text-xs text-gray-500">
                  Número de piezas que no salieron correctamente
                </p>
              </div>

              <div>
                <label className="block mb-2 text-sm font-medium text-gray-700">
                  Notas (opcional)
                </label>
                <textarea
                  value={notes}
                  onChange={(e) => setNotes(e.target.value)}
                  rows={3}
                  className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent"
                  placeholder="Observaciones sobre el corte..."
                />
              </div>
            </div>
          )}

          {assignments.length > 0 && (
            <div className="flex justify-end gap-3 pt-6 mt-6 border-t border-gray-200">
              <button
                onClick={onClose}
                className="px-6 py-2 text-gray-700 bg-gray-100 rounded-lg hover:bg-gray-200"
                disabled={saving}
              >
                Cancelar
              </button>
              <button
                onClick={handleCompleteCutting}
                className="px-6 py-2 text-white bg-blue-600 rounded-lg hover:bg-blue-700 disabled:bg-blue-300 flex items-center gap-2"
                disabled={completedCuts.size === 0 || saving}
              >
                {saving ? (
                  <>
                    <div className="w-4 h-4 border-2 border-white border-t-transparent rounded-full animate-spin"></div>
                    Guardando...
                  </>
                ) : (
                  <>
                    <CheckCircle className="w-5 h-5" />
                    Confirmar Cortes Completados
                  </>
                )}
              </button>
            </div>
          )}
        </div>
      </div>
    </div>
  );
}
