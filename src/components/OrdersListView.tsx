import { useState } from 'react';
import {
  Package,
  Search,
  Filter,
  Clock,
  CheckCircle2,
  AlertTriangle,
  Eye,
  Edit,
  Calendar,
  User,
  Layers,
  ChevronDown,
  ChevronUp
} from 'lucide-react';
import { Order, OrderStatus } from '../types';
import { useOrders } from '../hooks/useOrders';

interface OrdersListViewProps {
  onEditOrder: (order: Order) => void;
  onViewOrder: (order: Order) => void;
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

const statusIcons: Record<OrderStatus, React.ReactNode> = {
  quoted: <Clock size={14} />,
  approved: <CheckCircle2 size={14} />,
  in_production: <Package size={14} />,
  ready: <CheckCircle2 size={14} />,
  delivered: <CheckCircle2 size={14} />,
  cancelled: <AlertTriangle size={14} />
};

export function OrdersListView({ onEditOrder, onViewOrder }: OrdersListViewProps) {
  const { orders, customers, loading } = useOrders();
  const [searchTerm, setSearchTerm] = useState('');
  const [filterStatus, setFilterStatus] = useState<OrderStatus | 'all'>('all');
  const [showFilters, setShowFilters] = useState(false);
  const [expandedOrderId, setExpandedOrderId] = useState<string | null>(null);
  const [sortBy, setSortBy] = useState<'date' | 'urgency' | 'status'>('urgency');

  const getUrgencyLevel = (order: Order): { level: string; color: string; label: string; icon: React.ReactNode } => {
    if (!order.promised_date || order.status === 'delivered' || order.status === 'cancelled') {
      return { level: 'none', color: 'text-gray-400', label: 'Sin fecha', icon: <Clock size={14} /> };
    }

    const now = new Date();
    const promised = new Date(order.promised_date);
    const diffHours = (promised.getTime() - now.getTime()) / (1000 * 60 * 60);

    if (diffHours < 0) {
      return { level: 'overdue', color: 'text-red-600', label: 'Atrasado', icon: <AlertTriangle size={14} /> };
    } else if (diffHours < 24) {
      return { level: 'urgent', color: 'text-red-600', label: 'Urgente (< 24h)', icon: <AlertTriangle size={14} /> };
    } else if (diffHours < 48) {
      return { level: 'soon', color: 'text-orange-600', label: 'Próximo (< 48h)', icon: <Clock size={14} /> };
    }
    return { level: 'ok', color: 'text-green-600', label: 'A tiempo', icon: <CheckCircle2 size={14} /> };
  };

  const getSortedOrders = () => {
    let filtered = orders.filter(order => {
      const matchesSearch =
        order.name.toLowerCase().includes(searchTerm.toLowerCase()) ||
        order.order_number?.toLowerCase().includes(searchTerm.toLowerCase()) ||
        (order.customer_id && customers.get(order.customer_id)?.name.toLowerCase().includes(searchTerm.toLowerCase()));

      const matchesStatus = filterStatus === 'all' || order.status === filterStatus;

      return matchesSearch && matchesStatus;
    });

    if (sortBy === 'urgency') {
      filtered = filtered.sort((a, b) => {
        const urgencyA = getUrgencyLevel(a);
        const urgencyB = getUrgencyLevel(b);

        const urgencyOrder = { overdue: 0, urgent: 1, soon: 2, ok: 3, none: 4 };
        return urgencyOrder[urgencyA.level as keyof typeof urgencyOrder] - urgencyOrder[urgencyB.level as keyof typeof urgencyOrder];
      });
    } else if (sortBy === 'date') {
      filtered = filtered.sort((a, b) => {
        if (!a.promised_date) return 1;
        if (!b.promised_date) return -1;
        return new Date(a.promised_date).getTime() - new Date(b.promised_date).getTime();
      });
    } else if (sortBy === 'status') {
      const statusOrder = { quoted: 0, approved: 1, in_production: 2, ready: 3, delivered: 4, cancelled: 5 };
      filtered = filtered.sort((a, b) => statusOrder[a.status] - statusOrder[b.status]);
    }

    return filtered;
  };

  const getTotalCuts = (order: Order): number => {
    return order.cuts.reduce((sum, cut) => sum + cut.quantity, 0);
  };

  const sortedOrders = getSortedOrders();
  const activeOrders = orders.filter(o => o.status !== 'cancelled' && o.status !== 'delivered');
  const urgentOrders = activeOrders.filter(o => {
    const urgency = getUrgencyLevel(o);
    return urgency.level === 'urgent' || urgency.level === 'overdue';
  });

  if (loading) {
    return (
      <div className="flex items-center justify-center h-full">
        <p className="text-gray-500">Cargando pedidos...</p>
      </div>
    );
  }

  return (
    <div className="h-full flex flex-col bg-gray-50">
      <div className="bg-white border-b px-6 py-4">
        <div className="flex flex-col gap-4">
          <div className="flex items-center justify-between">
            <div>
              <h2 className="text-2xl font-bold text-gray-800">Mis Pedidos</h2>
              <p className="text-sm text-gray-600 mt-1">
                {activeOrders.length} pedidos activos
                {urgentOrders.length > 0 && (
                  <span className="ml-2 text-red-600 font-medium">
                    • {urgentOrders.length} urgentes
                  </span>
                )}
              </p>
            </div>
          </div>

          <div className="flex flex-col sm:flex-row gap-3">
            <div className="flex-1 relative">
              <Search className="absolute left-3 top-1/2 transform -translate-y-1/2 text-gray-400" size={20} />
              <input
                type="text"
                placeholder="Buscar por nombre, número de pedido o cliente..."
                value={searchTerm}
                onChange={(e) => setSearchTerm(e.target.value)}
                className="w-full pl-10 pr-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent"
              />
            </div>

            <button
              onClick={() => setShowFilters(!showFilters)}
              className={`flex items-center gap-2 px-4 py-2 rounded-lg font-medium transition-colors ${
                showFilters
                  ? 'bg-blue-100 text-blue-700 border border-blue-300'
                  : 'border border-gray-300 text-gray-700 hover:bg-gray-50'
              }`}
            >
              <Filter size={20} />
              Filtros
              {showFilters ? <ChevronUp size={16} /> : <ChevronDown size={16} />}
            </button>
          </div>

          {showFilters && (
            <div className="flex flex-wrap gap-3 p-4 bg-gray-50 rounded-lg border border-gray-200">
              <div className="flex flex-col gap-2">
                <label className="text-sm font-medium text-gray-700">Estado:</label>
                <select
                  value={filterStatus}
                  onChange={(e) => setFilterStatus(e.target.value as OrderStatus | 'all')}
                  className="px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500"
                >
                  <option value="all">Todos</option>
                  <option value="quoted">Presupuestado</option>
                  <option value="approved">Aprobado</option>
                  <option value="in_production">En Producción</option>
                  <option value="ready">Listo</option>
                  <option value="delivered">Entregado</option>
                  <option value="cancelled">Cancelado</option>
                </select>
              </div>

              <div className="flex flex-col gap-2">
                <label className="text-sm font-medium text-gray-700">Ordenar por:</label>
                <select
                  value={sortBy}
                  onChange={(e) => setSortBy(e.target.value as 'date' | 'urgency' | 'status')}
                  className="px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500"
                >
                  <option value="urgency">Urgencia</option>
                  <option value="date">Fecha prometida</option>
                  <option value="status">Estado</option>
                </select>
              </div>
            </div>
          )}
        </div>
      </div>

      <div className="flex-1 overflow-y-auto p-6">
        {sortedOrders.length === 0 ? (
          <div className="flex flex-col items-center justify-center h-64 text-gray-400">
            <Package size={64} className="mb-4" />
            <p className="text-lg">No se encontraron pedidos</p>
          </div>
        ) : (
          <div className="space-y-3">
            {sortedOrders.map((order) => {
              const customer = order.customer_id ? customers.get(order.customer_id) : null;
              const urgency = getUrgencyLevel(order);
              const totalCuts = getTotalCuts(order);
              const isExpanded = expandedOrderId === order.id;

              return (
                <div
                  key={order.id}
                  className="bg-white rounded-lg shadow-sm border border-gray-200 hover:shadow-md transition-shadow"
                >
                  <div className="p-4">
                    <div className="flex items-start justify-between gap-4">
                      <div className="flex-1 min-w-0">
                        <div className="flex items-start gap-3 mb-3">
                          <div className="flex-1">
                            <div className="flex items-center gap-2 mb-1">
                              <h3 className="font-bold text-lg text-gray-800 truncate">{order.name}</h3>
                              {urgency.level === 'urgent' || urgency.level === 'overdue' ? (
                                <span className={`flex items-center gap-1 px-2 py-1 rounded text-xs font-bold ${urgency.color} bg-red-50 border border-red-200`}>
                                  {urgency.icon}
                                  {urgency.label}
                                </span>
                              ) : null}
                            </div>
                            <p className="text-sm text-gray-600">#{order.order_number}</p>
                          </div>
                          <span className={`flex items-center gap-1 px-3 py-1 rounded-full text-xs font-medium border ${statusColors[order.status]}`}>
                            {statusIcons[order.status]}
                            {statusLabels[order.status]}
                          </span>
                        </div>

                        <div className="grid grid-cols-2 md:grid-cols-4 gap-3 text-sm">
                          {customer && (
                            <div className="flex items-center gap-2 text-gray-600">
                              <User size={16} className="text-gray-400" />
                              <span className="truncate">{customer.name}</span>
                            </div>
                          )}

                          <div className="flex items-center gap-2 text-gray-600">
                            <Layers size={16} className="text-gray-400" />
                            <span>{totalCuts} corte{totalCuts !== 1 ? 's' : ''}</span>
                          </div>

                          {order.promised_date && (
                            <div className={`flex items-center gap-2 ${urgency.color}`}>
                              <Calendar size={16} />
                              <span>
                                {new Date(order.promised_date).toLocaleDateString('es-ES', {
                                  day: 'numeric',
                                  month: 'short',
                                  year: 'numeric'
                                })}
                              </span>
                            </div>
                          )}

                          <div className="flex items-center gap-2 text-gray-600">
                            <Clock size={16} className="text-gray-400" />
                            <span className="text-xs">
                              {new Date(order.created_at).toLocaleDateString('es-ES', {
                                day: 'numeric',
                                month: 'short'
                              })}
                            </span>
                          </div>
                        </div>

                        {isExpanded && (
                          <div className="mt-4 pt-4 border-t border-gray-200">
                            <h4 className="font-semibold text-sm text-gray-700 mb-2">Detalles de cortes:</h4>
                            <div className="grid grid-cols-1 md:grid-cols-2 gap-2">
                              {order.cuts.map((cut, idx) => (
                                <div key={idx} className="text-sm bg-gray-50 rounded p-2">
                                  <span className="font-medium">{cut.label || `Corte ${idx + 1}`}</span>
                                  <span className="text-gray-600 ml-2">
                                    {cut.width} × {cut.height} cm ({cut.quantity} pz)
                                  </span>
                                </div>
                              ))}
                            </div>
                            {order.notes && (
                              <div className="mt-3">
                                <h4 className="font-semibold text-sm text-gray-700 mb-1">Notas:</h4>
                                <p className="text-sm text-gray-600">{order.notes}</p>
                              </div>
                            )}
                          </div>
                        )}
                      </div>
                    </div>

                    <div className="flex items-center gap-2 mt-4 pt-3 border-t border-gray-100">
                      <button
                        onClick={() => setExpandedOrderId(isExpanded ? null : order.id)}
                        className="flex-1 flex items-center justify-center gap-2 px-3 py-2 text-sm text-gray-700 hover:bg-gray-50 rounded transition-colors"
                      >
                        {isExpanded ? <ChevronUp size={16} /> : <ChevronDown size={16} />}
                        {isExpanded ? 'Menos' : 'Más'} detalles
                      </button>
                      <button
                        onClick={() => onViewOrder(order)}
                        className="flex-1 flex items-center justify-center gap-2 px-3 py-2 text-sm bg-blue-50 text-blue-700 hover:bg-blue-100 rounded transition-colors"
                      >
                        <Eye size={16} />
                        Ver
                      </button>
                      <button
                        onClick={() => onEditOrder(order)}
                        className="flex-1 flex items-center justify-center gap-2 px-3 py-2 text-sm bg-gray-50 text-gray-700 hover:bg-gray-100 rounded transition-colors"
                      >
                        <Edit size={16} />
                        Editar
                      </button>
                    </div>
                  </div>
                </div>
              );
            })}
          </div>
        )}
      </div>
    </div>
  );
}
