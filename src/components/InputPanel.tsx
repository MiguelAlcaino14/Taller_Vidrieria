import { useState, useMemo } from 'react';
import { Plus, Trash2, Save, FolderOpen, Info, AlertTriangle, AlertCircle } from 'lucide-react';
import { Cut, Sheet } from '../types';
import { DimensionReferenceModal } from './DimensionReferenceModal';
import { validateCutDimensions, getStandardThicknesses, getMethodRecommendation } from '../utils/validation';

interface InputPanelProps {
  sheet: Sheet;
  cuts: Cut[];
  onSheetChange: (sheet: Sheet) => void;
  onAddCut: (cut: Cut) => void;
  onRemoveCut: (id: string) => void;
  onClearAll: () => void;
  onSave: () => void;
  onLoad: () => void;
}

export function InputPanel({
  sheet,
  cuts,
  onSheetChange,
  onAddCut,
  onRemoveCut,
  onClearAll,
  onSave,
  onLoad
}: InputPanelProps) {
  const [cutWidth, setCutWidth] = useState('');
  const [cutHeight, setCutHeight] = useState('');
  const [cutQuantity, setCutQuantity] = useState('1');
  const [cutLabel, setCutLabel] = useState('');
  const [showReferenceModal, setShowReferenceModal] = useState(false);

  const standardThicknesses = getStandardThicknesses();
  const recommendation = getMethodRecommendation(cuts, sheet);

  const currentValidation = useMemo(() => {
    const width = parseFloat(cutWidth);
    const height = parseFloat(cutHeight);

    if (width > 0 && height > 0) {
      const tempCut: Cut = {
        id: 'temp',
        width,
        height,
        quantity: 1,
        label: ''
      };
      return validateCutDimensions(tempCut, sheet);
    }
    return null;
  }, [cutWidth, cutHeight, sheet.glassThickness, sheet.cuttingMethod]);

  const handleAddCut = () => {
    const width = parseFloat(cutWidth);
    const height = parseFloat(cutHeight);
    const quantity = parseInt(cutQuantity);

    if (width > 0 && height > 0 && quantity > 0) {
      const newCut: Cut = {
        id: Date.now().toString(),
        width,
        height,
        quantity,
        label: cutLabel || `Corte ${cuts.length + 1}`
      };

      onAddCut(newCut);

      setCutWidth('');
      setCutHeight('');
      setCutQuantity('1');
      setCutLabel('');
    }
  };

  const handleKeyPress = (e: React.KeyboardEvent) => {
    if (e.key === 'Enter') {
      handleAddCut();
    }
  };

  return (
    <div className="h-full overflow-y-auto bg-white p-4 sm:p-6">
      <div className="space-y-6">
        <div>
          <h2 className="text-xl sm:text-2xl font-bold text-gray-800 mb-4">Configuración de Plancha</h2>

          <div className="space-y-4">
            <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">
                  Ancho (cm)
                </label>
                <input
                  type="number"
                  value={sheet.width}
                  onChange={(e) => onSheetChange({ ...sheet, width: parseFloat(e.target.value) || 0 })}
                  className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent"
                  min="0"
                  step="0.1"
                />
              </div>
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">
                  Alto (cm)
                </label>
                <input
                  type="number"
                  value={sheet.height}
                  onChange={(e) => onSheetChange({ ...sheet, height: parseFloat(e.target.value) || 0 })}
                  className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent"
                  min="0"
                  step="0.1"
                />
              </div>
            </div>

            {sheet.cuttingMethod === 'machine' && (
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">
                  Grosor de Corte (cm)
                </label>
                <input
                  type="number"
                  value={sheet.cutThickness}
                  onChange={(e) => onSheetChange({ ...sheet, cutThickness: parseFloat(e.target.value) || 0 })}
                  className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent"
                  min="0"
                  step="0.1"
                />
              </div>
            )}

            <div className="border-t border-gray-200 pt-4 mt-4">
              <div className="flex items-center justify-between mb-3">
                <h3 className="text-sm font-semibold text-gray-700">Configuración de Corte</h3>
                <button
                  onClick={() => setShowReferenceModal(true)}
                  className="text-xs text-blue-600 hover:text-blue-700 font-medium flex items-center gap-1"
                >
                  <Info size={14} />
                  Ver Tabla de Referencia
                </button>
              </div>

              <div className="space-y-4">
                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-1">
                    Grosor del Vidrio
                  </label>
                  <select
                    value={sheet.glassThickness}
                    onChange={(e) => onSheetChange({ ...sheet, glassThickness: parseFloat(e.target.value) })}
                    className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent bg-white"
                  >
                    {standardThicknesses.map(thickness => (
                      <option key={thickness} value={thickness}>
                        {thickness}mm
                      </option>
                    ))}
                  </select>
                </div>

                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-1">
                    Método de Corte
                  </label>
                  <div className="grid grid-cols-2 gap-2">
                    <button
                      onClick={() => onSheetChange({ ...sheet, cuttingMethod: 'manual', cutThickness: 0 })}
                      className={`px-4 py-3 rounded-lg font-medium transition-all ${
                        sheet.cuttingMethod === 'manual'
                          ? 'bg-orange-600 text-white shadow-md'
                          : 'bg-gray-100 text-gray-700 hover:bg-gray-200'
                      }`}
                    >
                      Manual (Toyo)
                    </button>
                    <button
                      onClick={() => onSheetChange({ ...sheet, cuttingMethod: 'machine', cutThickness: 0.3 })}
                      className={`px-4 py-3 rounded-lg font-medium transition-all ${
                        sheet.cuttingMethod === 'machine'
                          ? 'bg-green-600 text-white shadow-md'
                          : 'bg-gray-100 text-gray-700 hover:bg-gray-200'
                      }`}
                    >
                      Máquina
                    </button>
                  </div>
                </div>

                {recommendation && (
                  <div className="bg-yellow-50 border border-yellow-200 rounded-lg p-3 flex gap-2">
                    <AlertTriangle size={18} className="text-yellow-600 flex-shrink-0 mt-0.5" />
                    <p className="text-xs text-yellow-900">{recommendation}</p>
                  </div>
                )}
              </div>
            </div>

            <div className="flex flex-wrap gap-2 mt-4">
              <button
                onClick={() => onSheetChange({ ...sheet, width: 200, height: 300 })}
                className="px-3 py-1 text-xs bg-gray-200 hover:bg-gray-300 rounded transition-colors"
              >
                200×300
              </button>
              <button
                onClick={() => onSheetChange({ ...sheet, width: 244, height: 183 })}
                className="px-3 py-1 text-xs bg-gray-200 hover:bg-gray-300 rounded transition-colors"
              >
                244×183
              </button>
              <button
                onClick={() => onSheetChange({ ...sheet, width: 300, height: 200 })}
                className="px-3 py-1 text-xs bg-gray-200 hover:bg-gray-300 rounded transition-colors"
              >
                300×200
              </button>
            </div>
          </div>
        </div>

        <div className="border-t pt-6">
          <h2 className="text-xl sm:text-2xl font-bold text-gray-800 mb-4">Agregar Cortes</h2>

          <div className="space-y-4">
            <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">
                  Ancho (cm)
                </label>
                <input
                  type="number"
                  value={cutWidth}
                  onChange={(e) => setCutWidth(e.target.value)}
                  onKeyPress={handleKeyPress}
                  className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-green-500 focus:border-transparent"
                  placeholder="50"
                  min="0"
                  step="0.1"
                />
              </div>
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">
                  Alto (cm)
                </label>
                <input
                  type="number"
                  value={cutHeight}
                  onChange={(e) => setCutHeight(e.target.value)}
                  onKeyPress={handleKeyPress}
                  className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-green-500 focus:border-transparent"
                  placeholder="30"
                  min="0"
                  step="0.1"
                />
              </div>
            </div>

            {currentValidation && currentValidation.status !== 'safe' && (
              <div className={`flex items-start gap-2 p-3 rounded-lg ${
                currentValidation.status === 'danger'
                  ? 'bg-red-50 border border-red-200'
                  : 'bg-yellow-50 border border-yellow-200'
              }`}>
                <AlertCircle
                  size={18}
                  className={`flex-shrink-0 mt-0.5 ${
                    currentValidation.status === 'danger' ? 'text-red-600' : 'text-yellow-600'
                  }`}
                />
                <div className="flex-1">
                  <p className={`text-xs font-medium ${
                    currentValidation.status === 'danger' ? 'text-red-900' : 'text-yellow-900'
                  }`}>
                    {currentValidation.message}
                  </p>
                  <p className={`text-xs mt-1 ${
                    currentValidation.status === 'danger' ? 'text-red-700' : 'text-yellow-700'
                  }`}>
                    Puedes agregar este corte, pero ten precaución al cortar.
                  </p>
                </div>
              </div>
            )}

            <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">
                  Cantidad
                </label>
                <input
                  type="number"
                  value={cutQuantity}
                  onChange={(e) => setCutQuantity(e.target.value)}
                  onKeyPress={handleKeyPress}
                  className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-green-500 focus:border-transparent"
                  placeholder="1"
                  min="1"
                />
              </div>
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">
                  Etiqueta (opcional)
                </label>
                <input
                  type="text"
                  value={cutLabel}
                  onChange={(e) => setCutLabel(e.target.value)}
                  onKeyPress={handleKeyPress}
                  className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-green-500 focus:border-transparent"
                  placeholder="Espejo"
                />
              </div>
            </div>

            <button
              onClick={handleAddCut}
              className="w-full px-4 py-2 bg-green-600 hover:bg-green-700 text-white rounded-lg font-medium flex items-center justify-center gap-2 transition-colors"
            >
              <Plus size={20} />
              Agregar Corte
            </button>
          </div>
        </div>

        <div className="border-t pt-6">
          <div className="flex justify-between items-center mb-4">
            <h2 className="text-xl font-bold text-gray-800">Lista de Cortes</h2>
            {cuts.length > 0 && (
              <button
                onClick={onClearAll}
                className="text-sm text-red-600 hover:text-red-700 font-medium"
              >
                Limpiar Todo
              </button>
            )}
          </div>

          {cuts.length === 0 ? (
            <p className="text-gray-500 text-center py-8">No hay cortes agregados</p>
          ) : (
            <div className="space-y-2">
              {cuts.map((cut) => {
                const validation = validateCutDimensions(cut, sheet);
                return (
                  <div
                    key={cut.id}
                    className="flex items-center justify-between p-3 bg-gray-50 rounded-lg hover:bg-gray-100 transition-colors"
                  >
                    <div className="flex items-start gap-2 flex-1">
                      {validation.status !== 'safe' && (
                        <div className="relative group">
                          <AlertCircle
                            size={18}
                            className={`mt-0.5 flex-shrink-0 ${
                              validation.status === 'danger' ? 'text-red-600' : 'text-yellow-600'
                            }`}
                          />
                          <div className="absolute left-0 top-6 hidden group-hover:block z-10 w-48 p-2 bg-gray-900 text-white text-xs rounded shadow-lg">
                            {validation.message}
                          </div>
                        </div>
                      )}
                      <div className="flex-1">
                        <p className="font-medium text-gray-800">{cut.label}</p>
                        <p className="text-sm text-gray-600">
                          {cut.width} × {cut.height} cm • Cant: {cut.quantity}
                        </p>
                      </div>
                    </div>
                    <button
                      onClick={() => onRemoveCut(cut.id)}
                      className="p-2 text-red-600 hover:bg-red-50 rounded transition-colors"
                    >
                      <Trash2 size={18} />
                    </button>
                  </div>
                );
              })}
            </div>
          )}
        </div>

        <div className="border-t pt-6 flex flex-col sm:flex-row gap-3">
          <button
            onClick={onSave}
            className="flex-1 px-4 py-2 bg-blue-600 hover:bg-blue-700 text-white rounded-lg font-medium flex items-center justify-center gap-2 transition-colors"
          >
            <Save size={20} />
            Guardar
          </button>
          <button
            onClick={onLoad}
            className="flex-1 px-4 py-2 bg-gray-600 hover:bg-gray-700 text-white rounded-lg font-medium flex items-center justify-center gap-2 transition-colors"
          >
            <FolderOpen size={20} />
            Cargar
          </button>
        </div>
      </div>

      <DimensionReferenceModal
        isOpen={showReferenceModal}
        onClose={() => setShowReferenceModal(false)}
      />
    </div>
  );
}
