import { Order, OrderStatus, Customer, OrderWithMaterial, MaterialStatus } from '../types';
import { Calendar, User, Package, DollarSign, Edit2, Eye, Clipboard, Scissors, FileText } from 'lucide-react';

interface OrderCardProps {
  order: Order | OrderWithMaterial;
  customer: Customer | null;
  onStatusChange: (orderId: string, newStatus: OrderStatus) => void;
  onEdit: (order: Order) => void;
  onView: (order: Order) => void;
  onAssignMaterial: (order: Order) => void;
  onStartCutting: (order: Order) => void;
  onViewPDF?: (pdfUrl: string, orderName: string) => void;
}

const statusColors: Record<OrderStatus, string> = {
  quoted: 'bg-gray-100 text-gray-800 border-gray-300',
  approved: 'bg-blue-100 text-blue-800 border-blue-300',
  in_production: 'bg-yellow-100 text-yellow-800 border-yellow-300',
  ready: 'bg-green-100 text-green-800 border-green-300',
  delivered: 'bg-emerald-100 text-emerald-800 border-emerald-300',
  cancelled: 'bg-red-100 text-red-800 border-red-300'
};

const statusLabels: Record<OrderStatus, string> = {
  quoted: 'Presupuestado',
  approved: 'Aprobado',
  in_production: 'En Producción',
  ready: 'Listo',
  delivered: 'Entregado',
  cancelled: 'Cancelado'
};

const materialStatusColors: Record<MaterialStatus, string> = {
  pending: 'bg-gray-100 text-gray-700',
  assigned: 'bg-blue-100 text-blue-700',
  cutting: 'bg-yellow-100 text-yellow-700',
  completed: 'bg-green-100 text-green-700'
};

const materialStatusLabels: Record<MaterialStatus, string> = {
  pending: 'Sin material',
  assigned: 'Material asignado',
  cutting: 'Cortando',
  completed: 'Corte completo'
};

export function OrderCard({ order, customer, onStatusChange, onEdit, onView, onAssignMaterial, onStartCutting, onViewPDF }: OrderCardProps) {
  const orderWithMaterial = order as OrderWithMaterial;
  const materialStatus = orderWithMaterial.material_status || 'pending';
  const formatCurrency = (amount: number) => {
    return new Intl.NumberFormat('es-AR', {
      style: 'currency',
      currency: 'ARS',
      minimumFractionDigits: 0
    }).format(amount);
  };

  const formatDate = (dateString: string | null) => {
    if (!dateString) return '-';
    return new Date(dateString).toLocaleDateString('es-AR', {
      day: '2-digit',
      month: '2-digit',
      year: 'numeric'
    });
  };

  const getNextStatuses = (currentStatus: OrderStatus): OrderStatus[] => {
    switch (currentStatus) {
      case 'quoted':
        return ['approved', 'cancelled'];
      case 'approved':
        return ['in_production', 'cancelled'];
      case 'in_production':
        return ['ready', 'cancelled'];
      case 'ready':
        return ['delivered', 'cancelled'];
      case 'delivered':
        return [];
      case 'cancelled':
        return [];
      default:
        return [];
    }
  };

  const nextStatuses = getNextStatuses(order.status);

  return (
    <div className="bg-white rounded-lg shadow-sm border border-gray-200 hover:shadow-md transition-shadow">
      <div className="p-4">
        <div className="flex items-start justify-between mb-3">
          <div>
            <div className="flex items-center gap-2 mb-1">
              <span className="font-bold text-gray-900">{order.order_number}</span>
              <span className={`text-xs px-2 py-1 rounded border ${statusColors[order.status]}`}>
                {statusLabels[order.status]}
              </span>
            </div>
            <h3 className="font-semibold text-gray-800 text-sm">{order.name}</h3>
          </div>
        </div>

        {customer && (
          <div className="flex items-center gap-2 text-sm text-gray-600 mb-2">
            <User size={14} className="text-gray-400" />
            <span>{customer.name}</span>
          </div>
        )}

        <div className="flex items-center gap-2 text-sm text-gray-600 mb-2">
          <Package size={14} className="text-gray-400" />
          <span>{order.cuts.length} corte{order.cuts.length !== 1 ? 's' : ''}</span>
        </div>

        {order.svg_source_url && order.svg_source_url.endsWith('.pdf') && onViewPDF && (
          <button
            onClick={(e) => {
              e.stopPropagation();
              onViewPDF(order.svg_source_url!, order.name);
            }}
            className="flex items-center gap-1 text-xs text-blue-600 hover:text-blue-700 mb-2 font-medium"
          >
            <FileText size={14} />
            Ver PDF Original
          </button>
        )}

        {order.promised_date && (
          <div className="flex items-center gap-2 text-sm text-gray-600 mb-2">
            <Calendar size={14} className="text-gray-400" />
            <span>Entrega: {formatDate(order.promised_date)}</span>
          </div>
        )}

        <div className="flex items-center gap-2 text-sm font-semibold text-gray-800 mb-3">
          <DollarSign size={14} className="text-gray-400" />
          <span>{formatCurrency(order.total_amount)}</span>
        </div>

        {(order.status === 'approved' || order.status === 'in_production') && (
          <div className="mb-3">
            <span className={`inline-flex items-center gap-1 text-xs px-2 py-1 rounded ${materialStatusColors[materialStatus]}`}>
              <Package size={12} />
              {materialStatusLabels[materialStatus]}
            </span>
          </div>
        )}

        {order.status === 'approved' && materialStatus === 'pending' && (
          <button
            onClick={() => onAssignMaterial(order)}
            className="w-full flex items-center justify-center gap-2 px-3 py-2 mb-3 bg-purple-600 hover:bg-purple-700 text-white rounded-lg transition-colors text-sm font-medium"
          >
            <Clipboard size={16} />
            Asignar Material
          </button>
        )}

        {order.status === 'approved' && materialStatus === 'assigned' && (
          <button
            onClick={() => onStartCutting(order)}
            className="w-full flex items-center justify-center gap-2 px-3 py-2 mb-3 bg-orange-600 hover:bg-orange-700 text-white rounded-lg transition-colors text-sm font-medium"
          >
            <Scissors size={16} />
            Iniciar Corte
          </button>
        )}

        {order.status === 'in_production' && (materialStatus === 'assigned' || materialStatus === 'cutting') && (
          <button
            onClick={() => onStartCutting(order)}
            className="w-full flex items-center justify-center gap-2 px-3 py-2 mb-3 bg-orange-600 hover:bg-orange-700 text-white rounded-lg transition-colors text-sm font-medium"
          >
            <Scissors size={16} />
            {materialStatus === 'cutting' ? 'Continuar Corte' : 'Iniciar Corte'}
          </button>
        )}

        {nextStatuses.length > 0 && (
          <div className="mb-3">
            <label className="block text-xs font-medium text-gray-600 mb-1">
              Cambiar estado:
            </label>
            <div className="flex gap-2">
              {nextStatuses.map((status) => (
                <button
                  key={status}
                  onClick={() => onStatusChange(order.id, status)}
                  className={`flex-1 text-xs px-2 py-1 rounded border font-medium transition-colors ${
                    statusColors[status]
                  } hover:opacity-80`}
                >
                  {statusLabels[status]}
                </button>
              ))}
            </div>
          </div>
        )}

        <div className="flex gap-2">
          <button
            onClick={() => onView(order)}
            className="flex-1 flex items-center justify-center gap-1 px-3 py-2 bg-blue-600 hover:bg-blue-700 text-white rounded-lg transition-colors text-sm font-medium"
          >
            <Eye size={16} />
            Ver
          </button>
          <button
            onClick={() => onEdit(order)}
            className="flex items-center justify-center gap-1 px-3 py-2 border border-gray-300 text-gray-700 rounded-lg hover:bg-gray-50 transition-colors text-sm font-medium"
          >
            <Edit2 size={16} />
          </button>
        </div>
      </div>
    </div>
  );
}
