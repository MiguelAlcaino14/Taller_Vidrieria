import { PlacedCut, Sheet, CutLine, CutInstruction, Remnant, Order } from '../types';
import { validateCutDimensions } from '../utils/validation';
import { Scissors, Cog, Package, FileDown } from 'lucide-react';
import { generateCuttingDiagramPDF } from '../utils/generateCuttingDiagramPDF';

interface VisualizationPanelProps {
  sheet: Sheet;
  placedCuts: PlacedCut[];
  utilization: number;
  cutLines?: CutLine[];
  cutInstructions?: CutInstruction[];
  method?: string;
  remnants?: Remnant[];
  order?: Order;
  customerName?: string;
}

const COLORS = [
  '#3b82f6', '#10b981', '#f59e0b', '#ef4444', '#8b5cf6',
  '#ec4899', '#14b8a6', '#f97316', '#6366f1', '#84cc16'
];

export function VisualizationPanel({ sheet, placedCuts, utilization, cutLines = [], cutInstructions = [], method, remnants = [], order, customerName }: VisualizationPanelProps) {
  const padding = 40;
  const maxWidth = typeof window !== 'undefined' ? Math.min(800, window.innerWidth - 100) : 800;
  const maxHeight = 600;

  const scale = Math.min(
    (maxWidth - padding * 2) / sheet.width,
    (maxHeight - padding * 2) / sheet.height,
    3
  );

  const scaledWidth = sheet.width * scale;
  const scaledHeight = sheet.height * scale;
  const viewWidth = scaledWidth + padding * 2;
  const viewHeight = scaledHeight + padding * 2;

  const totalCuts = placedCuts.length;
  const totalArea = sheet.width * sheet.height;
  const usedArea = placedCuts.reduce((sum, pc) => sum + (pc.width * pc.height), 0);
  const wasteArea = totalArea - usedArea;

  const colorMap = new Map<string, string>();
  let colorIndex = 0;

  const handleExportPDF = () => {
    generateCuttingDiagramPDF({
      sheet,
      placedCuts,
      utilization,
      cutLines,
      method,
      remnants,
      order,
      customerName
    });
  };

  return (
    <div className="h-full overflow-y-auto bg-gray-50 p-4 sm:p-6">
      <div className="space-y-4 sm:space-y-6">
        <div>
          <div className="flex flex-col sm:flex-row items-start sm:items-center justify-between mb-4 gap-2">
            <h2 className="text-xl sm:text-2xl font-bold text-gray-800">Diagrama de Corte</h2>
            <div className="flex items-center gap-2">
              <button
                onClick={handleExportPDF}
                className="flex items-center gap-2 px-3 py-1.5 bg-blue-600 hover:bg-blue-700 text-white rounded-lg font-medium text-sm transition-colors"
              >
                <FileDown size={16} />
                Exportar PDF
              </button>
              <div className={`flex items-center gap-2 px-3 py-1.5 rounded-lg font-medium text-sm ${
                sheet.cuttingMethod === 'manual'
                  ? 'bg-orange-100 text-orange-800 border border-orange-300'
                  : 'bg-green-100 text-green-800 border border-green-300'
              }`}>
                {sheet.cuttingMethod === 'manual' ? (
                  <>
                    <Scissors size={16} />
                    Manual (Toyo)
                  </>
                ) : (
                  <>
                    <Cog size={16} />
                    Máquina
                  </>
                )}
                <span className="mx-1">•</span>
                {sheet.glassThickness}mm
              </div>
            </div>
          </div>

          <div className="grid grid-cols-1 sm:grid-cols-3 gap-4 mb-6">
            <div className="bg-white p-4 rounded-lg shadow-sm">
              <p className="text-sm text-gray-600 mb-1">Aprovechamiento</p>
              <p className="text-2xl font-bold text-green-600">{utilization.toFixed(1)}%</p>
            </div>
            <div className="bg-white p-4 rounded-lg shadow-sm">
              <p className="text-sm text-gray-600 mb-1">Cortes Colocados</p>
              <p className="text-2xl font-bold text-blue-600">{totalCuts}</p>
            </div>
            <div className="bg-white p-4 rounded-lg shadow-sm">
              <p className="text-sm text-gray-600 mb-1">Desperdicio</p>
              <p className="text-2xl font-bold text-red-600">{wasteArea.toFixed(0)} cm²</p>
            </div>
          </div>
        </div>

        <div className="bg-white rounded-lg shadow-sm p-4 sm:p-6 overflow-x-auto">
          <svg
            width={viewWidth}
            height={viewHeight}
            className="mx-auto max-w-full"
            style={{ maxWidth: '100%', height: 'auto' }}
          >
            <rect
              x={padding}
              y={padding}
              width={scaledWidth}
              height={scaledHeight}
              fill="#f9fafb"
              stroke="#9ca3af"
              strokeWidth="2"
            />

            <text
              x={padding + scaledWidth / 2}
              y={padding - 15}
              textAnchor="middle"
              className="text-sm font-medium"
              fill="#374151"
            >
              {sheet.width} cm
            </text>

            <text
              x={padding - 15}
              y={padding + scaledHeight / 2}
              textAnchor="middle"
              transform={`rotate(-90, ${padding - 15}, ${padding + scaledHeight / 2})`}
              className="text-sm font-medium"
              fill="#374151"
            >
              {sheet.height} cm
            </text>

            {cutLines.map((cutLine) => {
              const x1 = cutLine.type === 'vertical'
                ? padding + cutLine.position * scale
                : padding + cutLine.start * scale;
              const y1 = cutLine.type === 'horizontal'
                ? padding + cutLine.position * scale
                : padding + cutLine.start * scale;
              const x2 = cutLine.type === 'vertical'
                ? padding + cutLine.position * scale
                : padding + cutLine.end * scale;
              const y2 = cutLine.type === 'horizontal'
                ? padding + cutLine.position * scale
                : padding + cutLine.end * scale;

              return (
                <g key={cutLine.id}>
                  <line
                    x1={x1}
                    y1={y1}
                    x2={x2}
                    y2={y2}
                    stroke={cutLine.type === 'vertical' ? '#dc2626' : '#2563eb'}
                    strokeWidth="2"
                    strokeDasharray="5,5"
                    opacity="0.8"
                  />
                  <circle
                    cx={cutLine.type === 'vertical' ? x1 : (x1 + x2) / 2}
                    cy={cutLine.type === 'horizontal' ? y1 : (y1 + y2) / 2}
                    r="12"
                    fill={cutLine.type === 'vertical' ? '#dc2626' : '#2563eb'}
                    opacity="0.9"
                  />
                  <text
                    x={cutLine.type === 'vertical' ? x1 : (x1 + x2) / 2}
                    y={cutLine.type === 'horizontal' ? y1 + 4 : (y1 + y2) / 2 + 4}
                    textAnchor="middle"
                    className="text-xs font-bold"
                    fill="white"
                  >
                    {cutLine.order}
                  </text>
                </g>
              );
            })}

            {placedCuts.map((pc, index) => {
              const originalId = pc.cut.id.split('_')[0];
              if (!colorMap.has(originalId)) {
                colorMap.set(originalId, COLORS[colorIndex % COLORS.length]);
                colorIndex++;
              }
              const color = colorMap.get(originalId)!;

              const validation = validateCutDimensions(pc.cut, sheet);

              const x = padding + pc.x * scale;
              const y = padding + pc.y * scale;
              const width = pc.width * scale;
              const height = pc.height * scale;

              let strokeColor = color;
              let strokeWidth = 2;
              let strokeDasharray = 'none';

              if (validation.status === 'danger') {
                strokeColor = '#dc2626';
                strokeWidth = 4;
              } else if (validation.status === 'warning') {
                strokeColor = '#f59e0b';
                strokeWidth = 3;
              }

              if (pc.isPattern === false) {
                strokeDasharray = '4,4';
                strokeWidth = strokeWidth + 1;
              }

              return (
                <g key={index}>
                  <rect
                    x={x}
                    y={y}
                    width={width}
                    height={height}
                    fill={color}
                    fillOpacity={pc.isPattern === false ? '0.5' : '0.7'}
                    stroke={strokeColor}
                    strokeWidth={strokeWidth}
                    strokeDasharray={strokeDasharray}
                  />

                  {validation.status !== 'safe' && (
                    <circle
                      cx={x + width - 8}
                      cy={y + 8}
                      r="6"
                      fill={validation.status === 'danger' ? '#dc2626' : '#f59e0b'}
                    />
                  )}

                  <text
                    x={x + width / 2}
                    y={y + height / 2 - 8}
                    textAnchor="middle"
                    className="text-xs font-bold"
                    fill="white"
                  >
                    {pc.cut.label}
                  </text>

                  <text
                    x={x + width / 2}
                    y={y + height / 2 + 8}
                    textAnchor="middle"
                    className="text-xs font-medium"
                    fill="white"
                  >
                    {pc.width.toFixed(1)} × {pc.height.toFixed(1)}
                  </text>

                  {pc.rotated && (
                    <text
                      x={x + width / 2}
                      y={y + height / 2 + 22}
                      textAnchor="middle"
                      className="text-xs italic"
                      fill="white"
                    >
                      (rotado)
                    </text>
                  )}
                </g>
              );
            })}
          </svg>

          <div className="mt-4 flex flex-wrap gap-4 text-xs">
            <div className="flex items-center gap-2">
              <div className="w-4 h-4 border-2 border-green-600 rounded"></div>
              <span className="text-gray-700">Seguro</span>
            </div>
            <div className="flex items-center gap-2">
              <div className="w-4 h-4 border-2 border-yellow-500 rounded"></div>
              <span className="text-gray-700">Precaución</span>
            </div>
            <div className="flex items-center gap-2">
              <div className="w-4 h-4 border-2 border-red-600 rounded"></div>
              <span className="text-gray-700">Peligroso</span>
            </div>
            {cutLines.length > 0 && (
              <>
                <div className="flex items-center gap-2">
                  <div className="w-4 h-1 bg-blue-600"></div>
                  <span className="text-gray-700">Corte H</span>
                </div>
                <div className="flex items-center gap-2">
                  <div className="w-1 h-4 bg-red-600"></div>
                  <span className="text-gray-700">Corte V</span>
                </div>
                <div className="flex items-center gap-2">
                  <div className="w-6 h-4 bg-blue-400 opacity-70 border-2 border-blue-600 rounded"></div>
                  <span className="text-gray-700">Patrón</span>
                </div>
                <div className="flex items-center gap-2">
                  <div className="w-6 h-4 bg-blue-400 opacity-50 border-2 border-blue-600 border-dashed rounded"></div>
                  <span className="text-gray-700">Optimizado</span>
                </div>
              </>
            )}
          </div>
        </div>

        <div className="bg-white rounded-lg shadow-sm p-4">
          <h3 className="font-semibold text-gray-800 mb-3">Detalles del Proyecto</h3>
          <div className="space-y-2 text-sm">
            <div className="flex justify-between">
              <span className="text-gray-600">Tamaño de plancha:</span>
              <span className="font-medium">{sheet.width} × {sheet.height} cm</span>
            </div>
            <div className="flex justify-between">
              <span className="text-gray-600">Área total:</span>
              <span className="font-medium">{totalArea.toFixed(0)} cm²</span>
            </div>
            <div className="flex justify-between">
              <span className="text-gray-600">Área utilizada:</span>
              <span className="font-medium text-green-600">{usedArea.toFixed(0)} cm²</span>
            </div>
            <div className="flex justify-between">
              <span className="text-gray-600">Área desperdiciada:</span>
              <span className="font-medium text-red-600">{wasteArea.toFixed(0)} cm²</span>
            </div>
            {sheet.cuttingMethod === 'machine' && (
              <div className="flex justify-between">
                <span className="text-gray-600">Grosor de corte:</span>
                <span className="font-medium">{sheet.cutThickness} cm</span>
              </div>
            )}
            <div className="flex justify-between">
              <span className="text-gray-600">Grosor del vidrio:</span>
              <span className="font-medium">{sheet.glassThickness}mm</span>
            </div>
            <div className="flex justify-between">
              <span className="text-gray-600">Método de corte:</span>
              <span className={`font-medium ${sheet.cuttingMethod === 'manual' ? 'text-orange-600' : 'text-green-600'}`}>
                {sheet.cuttingMethod === 'manual' ? 'Manual (Toyo)' : 'Máquina Automática'}
              </span>
            </div>
            {method && (
              <div className="flex justify-between">
                <span className="text-gray-600">Algoritmo:</span>
                <span className="font-medium text-gray-800">{method}</span>
              </div>
            )}
          </div>
        </div>

        {remnants.length > 0 && (
          <div className="bg-white rounded-lg shadow-sm p-4">
            <div className="flex items-center gap-2 mb-3">
              <Package size={20} className="text-green-600" />
              <h3 className="font-semibold text-gray-800">Material Sobrante Aprovechable</h3>
            </div>
            <p className="text-sm text-gray-600 mb-4">
              Retales de vidrio o espejo que pueden guardarse para futuros proyectos
            </p>

            {remnants.length > 0 && (
              <div className="mb-4 p-3 bg-green-50 border border-green-200 rounded-lg">
                <p className="text-sm font-medium text-green-900 mb-1">
                  Mejor Aprovechamiento:
                </p>
                <p className="text-lg font-bold text-green-700">
                  {remnants[0].width.toFixed(1)} × {remnants[0].height.toFixed(1)} cm
                </p>
                <p className="text-sm text-green-600">
                  Área: {remnants[0].area.toFixed(0)} cm²
                </p>
              </div>
            )}

            {remnants.length > 1 && (
              <div className="space-y-2">
                <p className="text-sm font-medium text-gray-700 mb-2">
                  Otros retales aprovechables:
                </p>
                <div className="grid grid-cols-1 sm:grid-cols-2 gap-2">
                  {remnants.slice(1, 5).map((remnant, index) => (
                    <div key={index} className="p-2 bg-gray-50 rounded border border-gray-200">
                      <p className="text-sm font-medium text-gray-800">
                        {remnant.width.toFixed(1)} × {remnant.height.toFixed(1)} cm
                      </p>
                      <p className="text-xs text-gray-600">
                        {remnant.area.toFixed(0)} cm²
                      </p>
                    </div>
                  ))}
                </div>
                {remnants.length > 5 && (
                  <p className="text-xs text-gray-500 mt-2 text-center">
                    +{remnants.length - 5} retales más pequeños
                  </p>
                )}
              </div>
            )}
          </div>
        )}
      </div>
    </div>
  );
}
