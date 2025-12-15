import { X, Scissors, Cog } from 'lucide-react';
import { getDimensionRulesTable } from '../utils/validation';

interface DimensionReferenceModalProps {
  isOpen: boolean;
  onClose: () => void;
}

export function DimensionReferenceModal({ isOpen, onClose }: DimensionReferenceModalProps) {
  if (!isOpen) return null;

  const { manual, machine } = getDimensionRulesTable();

  return (
    <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50 p-4">
      <div className="bg-white rounded-xl shadow-2xl max-w-4xl w-full max-h-[90vh] overflow-y-auto">
        <div className="sticky top-0 bg-white border-b px-6 py-4 flex items-center justify-between">
          <h2 className="text-2xl font-bold text-gray-800">
            Tabla de Referencia: Dimensiones Mínimas
          </h2>
          <button
            onClick={onClose}
            className="p-2 hover:bg-gray-100 rounded-lg transition-colors"
          >
            <X size={24} />
          </button>
        </div>

        <div className="p-6 space-y-6">
          <div className="bg-blue-50 border border-blue-200 rounded-lg p-4">
            <p className="text-sm text-blue-900">
              <strong>Importante:</strong> Las dimensiones mínimas varían según el grosor del vidrio
              y el método de corte utilizado. El corte manual (toyo) requiere piezas más grandes
              para poder sostener y quebrar el vidrio de forma segura.
            </p>
          </div>

          <div className="grid md:grid-cols-2 gap-6">
            <div className="border-2 border-orange-200 rounded-lg overflow-hidden">
              <div className="bg-orange-100 px-4 py-3 flex items-center gap-2">
                <Scissors className="text-orange-700" size={24} />
                <h3 className="text-lg font-bold text-orange-900">
                  Corte Manual (Toyo)
                </h3>
              </div>
              <div className="p-4">
                <table className="w-full">
                  <thead>
                    <tr className="border-b">
                      <th className="text-left py-2 px-2 text-sm font-semibold text-gray-700">
                        Grosor
                      </th>
                      <th className="text-right py-2 px-2 text-sm font-semibold text-gray-700">
                        Mínimo
                      </th>
                    </tr>
                  </thead>
                  <tbody>
                    {manual.map((rule, index) => (
                      <tr key={index} className="border-b last:border-b-0 hover:bg-orange-50">
                        <td className="py-3 px-2 text-gray-800">{rule.thickness}mm</td>
                        <td className="py-3 px-2 text-right font-semibold text-orange-700">
                          {rule.minDimension}cm
                        </td>
                      </tr>
                    ))}
                  </tbody>
                </table>
                <div className="mt-4 bg-orange-50 rounded p-3 text-xs text-orange-900">
                  <strong>Limitaciones del toyo:</strong>
                  <ul className="mt-2 space-y-1 list-disc list-inside">
                    <li>Necesitas espacio para sostener la pieza</li>
                    <li>Piezas pequeñas se rompen mal al quebrar</li>
                    <li>Mayor riesgo de accidentes con piezas chicas</li>
                    <li>Vidrios gruesos son casi imposibles si son muy pequeños</li>
                  </ul>
                </div>
              </div>
            </div>

            <div className="border-2 border-green-200 rounded-lg overflow-hidden">
              <div className="bg-green-100 px-4 py-3 flex items-center gap-2">
                <Cog className="text-green-700" size={24} />
                <h3 className="text-lg font-bold text-green-900">
                  Máquina Automática
                </h3>
              </div>
              <div className="p-4">
                <table className="w-full">
                  <thead>
                    <tr className="border-b">
                      <th className="text-left py-2 px-2 text-sm font-semibold text-gray-700">
                        Grosor
                      </th>
                      <th className="text-right py-2 px-2 text-sm font-semibold text-gray-700">
                        Mínimo
                      </th>
                    </tr>
                  </thead>
                  <tbody>
                    {machine.map((rule, index) => (
                      <tr key={index} className="border-b last:border-b-0 hover:bg-green-50">
                        <td className="py-3 px-2 text-gray-800">{rule.thickness}mm</td>
                        <td className="py-3 px-2 text-right font-semibold text-green-700">
                          {rule.minDimension}cm
                        </td>
                      </tr>
                    ))}
                  </tbody>
                </table>
                <div className="mt-4 bg-green-50 rounded p-3 text-xs text-green-900">
                  <strong>Ventajas de la máquina:</strong>
                  <ul className="mt-2 space-y-1 list-disc list-inside">
                    <li>Permite piezas más pequeñas con seguridad</li>
                    <li>Cortes más precisos y limpios</li>
                    <li>Menor desperdicio de material</li>
                    <li>Más rápido para múltiples cortes</li>
                  </ul>
                </div>
              </div>
            </div>
          </div>

          <div className="bg-yellow-50 border border-yellow-200 rounded-lg p-4">
            <h4 className="font-bold text-yellow-900 mb-2">Recomendaciones Generales:</h4>
            <ul className="text-sm text-yellow-900 space-y-1 list-disc list-inside">
              <li>Si tienes muchos cortes pequeños, considera usar máquina automática</li>
              <li>Para vidrios de 8mm o más con piezas pequeñas, la máquina es prácticamente necesaria</li>
              <li>El toyo es excelente para piezas grandes y trabajos simples</li>
              <li>Siempre añade un margen de seguridad a las dimensiones mínimas</li>
            </ul>
          </div>
        </div>

        <div className="sticky bottom-0 bg-gray-50 border-t px-6 py-4">
          <button
            onClick={onClose}
            className="w-full px-4 py-2 bg-gray-600 hover:bg-gray-700 text-white rounded-lg font-medium transition-colors"
          >
            Cerrar
          </button>
        </div>
      </div>
    </div>
  );
}
