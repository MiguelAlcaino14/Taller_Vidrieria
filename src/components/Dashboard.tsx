import { useState, useEffect } from 'react';
import {
  LayoutDashboard,
  ShoppingBag,
  Users,
  Clock,
  TrendingUp,
  AlertCircle,
  Calendar,
  CheckCircle2,
  Package,
  Eye,
  Edit,
  ArrowRight,
  List,
  Grid,
  FileUp
} from 'lucide-react';
import { Order, Customer, OrderStatus } from '../types';
import { supabase } from '../lib/supabase';
import { useAuth } from '../contexts/AuthContext';
import { OrdersListView } from './OrdersListView';
import { SVGOrderImportModal } from './SVGOrderImportModal';

interface DashboardProps {
  onNavigateToOrders: () => void;
  onNavigateToCustomers: () => void;
  onEditOrder: (order: Order) => void;
  onViewOrder: (order: Order) => void;
}

interface Statistics {
  totalOrders: number;
  totalCustomers: number;
  pendingApproval: number;
  inProduction: number;
  readyForDelivery: number;
}

interface RecentActivity {
  id: string;
  type: 'order_created' | 'order_status_changed' | 'customer_created';
  description: string;
  timestamp: string;
  relatedId?: string;
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

export function Dashboard({ onNavigateToOrders, onNavigateToCustomers, onEditOrder, onViewOrder }: DashboardProps) {
  const { profile } = useAuth();
  const [viewMode, setViewMode] = useState<'summary' | 'list'>('list');
  const [statistics, setStatistics] = useState<Statistics>({
    totalOrders: 0,
    totalCustomers: 0,
    pendingApproval: 0,
    inProduction: 0,
    readyForDelivery: 0
  });
  const [recentProjects, setRecentProjects] = useState<Order[]>([]);
  const [recentCustomers, setRecentCustomers] = useState<Customer[]>([]);
  const [upcomingOrders, setUpcomingOrders] = useState<Order[]>([]);
  const [recentActivity, setRecentActivity] = useState<RecentActivity[]>([]);
  const [customers, setCustomers] = useState<Map<string, Customer>>(new Map());
  const [loading, setLoading] = useState(true);
  const [showImportModal, setShowImportModal] = useState(false);

  useEffect(() => {
    if (profile) {
      loadDashboardData();
    }
  }, [profile]);

  const loadDashboardData = async () => {
    try {
      setLoading(true);

      const [ordersResult, customersResult] = await Promise.all([
        supabase
          .from('glass_projects')
          .select('*')
          .order('created_at', { ascending: false }),
        supabase
          .from('customers')
          .select('*')
          .order('created_at', { ascending: false })
      ]);

      if (ordersResult.error) throw ordersResult.error;
      if (customersResult.error) throw customersResult.error;

      const orders = (ordersResult.data || []) as Order[];
      const customersData = (customersResult.data || []) as Customer[];

      const customersMap = new Map<string, Customer>();
      customersData.forEach((customer) => {
        customersMap.set(customer.id, customer);
      });
      setCustomers(customersMap);

      const activeOrders = orders.filter(o => o.status !== 'cancelled' && o.status !== 'delivered');

      setStatistics({
        totalOrders: activeOrders.length,
        totalCustomers: customersData.length,
        pendingApproval: orders.filter(o => o.status === 'quoted').length,
        inProduction: orders.filter(o => o.status === 'in_production').length,
        readyForDelivery: orders.filter(o => o.status === 'ready').length
      });

      setRecentProjects(orders.slice(0, 6));
      setRecentCustomers(customersData.slice(0, 5));

      const now = new Date();
      const twoDaysFromNow = new Date(now.getTime() + 2 * 24 * 60 * 60 * 1000);
      const upcoming = orders.filter(o => {
        if (!o.promised_date || o.status === 'delivered' || o.status === 'cancelled') return false;
        const promisedDate = new Date(o.promised_date);
        return promisedDate <= twoDaysFromNow && promisedDate >= now;
      }).sort((a, b) => {
        const dateA = new Date(a.promised_date!);
        const dateB = new Date(b.promised_date!);
        return dateA.getTime() - dateB.getTime();
      });
      setUpcomingOrders(upcoming);

      const activities: RecentActivity[] = [];

      orders.slice(0, 10).forEach(order => {
        activities.push({
          id: `order-${order.id}`,
          type: 'order_created',
          description: `Pedido "${order.name}" creado`,
          timestamp: order.created_at,
          relatedId: order.id
        });
      });

      customersData.slice(0, 5).forEach(customer => {
        activities.push({
          id: `customer-${customer.id}`,
          type: 'customer_created',
          description: `Cliente "${customer.name}" agregado`,
          timestamp: customer.created_at,
          relatedId: customer.id
        });
      });

      activities.sort((a, b) => new Date(b.timestamp).getTime() - new Date(a.timestamp).getTime());
      setRecentActivity(activities.slice(0, 10));

    } catch (error) {
      console.error('Error loading dashboard data:', error);
    } finally {
      setLoading(false);
    }
  };

  const getRelativeTime = (timestamp: string): string => {
    const now = new Date();
    const past = new Date(timestamp);
    const diffMs = now.getTime() - past.getTime();
    const diffMins = Math.floor(diffMs / 60000);
    const diffHours = Math.floor(diffMs / 3600000);
    const diffDays = Math.floor(diffMs / 86400000);

    if (diffMins < 1) return 'Ahora mismo';
    if (diffMins < 60) return `Hace ${diffMins} minuto${diffMins > 1 ? 's' : ''}`;
    if (diffHours < 24) return `Hace ${diffHours} hora${diffHours > 1 ? 's' : ''}`;
    if (diffDays < 7) return `Hace ${diffDays} día${diffDays > 1 ? 's' : ''}`;
    return past.toLocaleDateString('es-ES', { day: 'numeric', month: 'short' });
  };

  const getUrgencyLevel = (promisedDate: string): { level: string; color: string; label: string } => {
    const now = new Date();
    const promised = new Date(promisedDate);
    const diffHours = (promised.getTime() - now.getTime()) / (1000 * 60 * 60);

    if (diffHours < 24) {
      return { level: 'urgent', color: 'bg-red-100 border-red-300 text-red-800', label: 'Urgente' };
    } else if (diffHours < 48) {
      return { level: 'soon', color: 'bg-yellow-100 border-yellow-300 text-yellow-800', label: 'Próximo' };
    }
    return { level: 'ok', color: 'bg-green-100 border-green-300 text-green-800', label: 'A tiempo' };
  };

  const handleImportSuccess = async (orderId: string) => {
    setShowImportModal(false);
    await loadDashboardData();
    const importedOrder = recentProjects.find(o => o.id === orderId);
    if (importedOrder) {
      onEditOrder(importedOrder);
    }
  };

  if (!profile) {
    return null;
  }

  if (loading) {
    return (
      <div className="flex items-center justify-center h-full">
        <p className="text-gray-500">Cargando dashboard...</p>
      </div>
    );
  }

  if (viewMode === 'list') {
    return (
      <div className="h-full flex flex-col bg-gray-50">
        <div className="bg-white border-b px-6 py-4">
          <div className="flex items-center justify-between">
            <div>
              <h1 className="text-2xl font-bold text-gray-800">Dashboard</h1>
              <p className="text-sm text-gray-600 mt-1">Vista completa de tus pedidos</p>
            </div>
            <div className="flex items-center gap-2">
              <button
                onClick={() => setShowImportModal(true)}
                className="flex items-center gap-2 px-4 py-2 bg-green-600 text-white hover:bg-green-700 rounded-lg transition-colors"
              >
                <FileUp size={18} />
                <span className="hidden sm:inline">Importar SVG</span>
              </button>
              <button
                onClick={() => setViewMode('summary')}
                className="flex items-center gap-2 px-4 py-2 border border-gray-300 text-gray-700 hover:bg-gray-50 rounded-lg transition-colors"
              >
                <Grid size={18} />
                <span className="hidden sm:inline">Vista Resumen</span>
              </button>
              <button
                className="flex items-center gap-2 px-4 py-2 bg-blue-600 text-white rounded-lg"
              >
                <List size={18} />
                <span className="hidden sm:inline">Vista Lista</span>
              </button>
            </div>
          </div>
        </div>
        <div className="flex-1 overflow-hidden">
          <OrdersListView onEditOrder={onEditOrder} onViewOrder={onViewOrder} />
        </div>
        {showImportModal && (
          <SVGOrderImportModal
            onClose={() => setShowImportModal(false)}
            onImportSuccess={handleImportSuccess}
            customers={Array.from(customers.values())}
          />
        )}
      </div>
    );
  }

  return (
    <div className="h-full overflow-y-auto bg-gray-50">
      <div className="max-w-7xl mx-auto p-6 space-y-6">
        <div className="flex items-center justify-between">
          <div>
            <h1 className="text-3xl font-bold text-gray-800">Dashboard</h1>
            <p className="text-gray-600 mt-1">Resumen de tu actividad reciente</p>
          </div>
          <div className="flex items-center gap-4">
            <div className="flex items-center gap-2">
              <button
                onClick={() => setShowImportModal(true)}
                className="flex items-center gap-2 px-4 py-2 bg-green-600 text-white hover:bg-green-700 rounded-lg transition-colors"
              >
                <FileUp size={18} />
                <span className="hidden sm:inline">Importar SVG</span>
              </button>
              <button
                className="flex items-center gap-2 px-4 py-2 bg-blue-600 text-white rounded-lg"
              >
                <Grid size={18} />
                <span className="hidden sm:inline">Vista Resumen</span>
              </button>
              <button
                onClick={() => setViewMode('list')}
                className="flex items-center gap-2 px-4 py-2 border border-gray-300 text-gray-700 hover:bg-gray-50 rounded-lg transition-colors"
              >
                <List size={18} />
                <span className="hidden sm:inline">Vista Lista</span>
              </button>
            </div>
            <LayoutDashboard className="text-blue-600" size={40} />
          </div>
        </div>

        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-5 gap-4">
          <div
            onClick={onNavigateToOrders}
            className="bg-white p-6 rounded-lg shadow-sm border border-gray-200 hover:shadow-md transition-shadow cursor-pointer"
          >
            <div className="flex items-center justify-between">
              <div>
                <p className="text-sm text-gray-600 font-medium">Pedidos Activos</p>
                <p className="text-3xl font-bold text-gray-800 mt-2">{statistics.totalOrders}</p>
              </div>
              <ShoppingBag className="text-blue-600" size={32} />
            </div>
          </div>

          <div
            onClick={onNavigateToCustomers}
            className="bg-white p-6 rounded-lg shadow-sm border border-gray-200 hover:shadow-md transition-shadow cursor-pointer"
          >
            <div className="flex items-center justify-between">
              <div>
                <p className="text-sm text-gray-600 font-medium">Total Clientes</p>
                <p className="text-3xl font-bold text-gray-800 mt-2">{statistics.totalCustomers}</p>
              </div>
              <Users className="text-green-600" size={32} />
            </div>
          </div>

          <div
            onClick={onNavigateToOrders}
            className="bg-white p-6 rounded-lg shadow-sm border border-gray-200 hover:shadow-md transition-shadow cursor-pointer"
          >
            <div className="flex items-center justify-between">
              <div>
                <p className="text-sm text-gray-600 font-medium">Por Aprobar</p>
                <p className="text-3xl font-bold text-gray-800 mt-2">{statistics.pendingApproval}</p>
              </div>
              <Clock className="text-orange-600" size={32} />
            </div>
          </div>

          <div
            onClick={onNavigateToOrders}
            className="bg-white p-6 rounded-lg shadow-sm border border-gray-200 hover:shadow-md transition-shadow cursor-pointer"
          >
            <div className="flex items-center justify-between">
              <div>
                <p className="text-sm text-gray-600 font-medium">En Producción</p>
                <p className="text-3xl font-bold text-gray-800 mt-2">{statistics.inProduction}</p>
              </div>
              <TrendingUp className="text-yellow-600" size={32} />
            </div>
          </div>

          <div
            onClick={onNavigateToOrders}
            className="bg-white p-6 rounded-lg shadow-sm border border-gray-200 hover:shadow-md transition-shadow cursor-pointer"
          >
            <div className="flex items-center justify-between">
              <div>
                <p className="text-sm text-gray-600 font-medium">Listos</p>
                <p className="text-3xl font-bold text-gray-800 mt-2">{statistics.readyForDelivery}</p>
              </div>
              <CheckCircle2 className="text-emerald-600" size={32} />
            </div>
          </div>
        </div>

        <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
          <div className="lg:col-span-2 space-y-6">
            <div className="bg-white rounded-lg shadow-sm border border-gray-200">
              <div className="p-6 border-b border-gray-200">
                <div className="flex items-center justify-between">
                  <h2 className="text-xl font-bold text-gray-800">Proyectos Recientes</h2>
                  <button
                    onClick={onNavigateToOrders}
                    className="text-sm text-blue-600 hover:text-blue-700 font-medium flex items-center gap-1"
                  >
                    Ver todos
                    <ArrowRight size={16} />
                  </button>
                </div>
              </div>
              <div className="p-6">
                {recentProjects.length === 0 ? (
                  <p className="text-center text-gray-400 py-8">No hay proyectos recientes</p>
                ) : (
                  <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                    {recentProjects.map((order) => (
                      <div
                        key={order.id}
                        className="border border-gray-200 rounded-lg p-4 hover:shadow-md transition-shadow"
                      >
                        <div className="flex items-start justify-between mb-3">
                          <div className="flex-1">
                            <h3 className="font-semibold text-gray-800 truncate">{order.name}</h3>
                            <p className="text-sm text-gray-500">#{order.order_number}</p>
                          </div>
                          <span className={`px-2 py-1 rounded text-xs font-medium border ${statusColors[order.status]}`}>
                            {statusLabels[order.status]}
                          </span>
                        </div>
                        {order.customer_id && customers.get(order.customer_id) && (
                          <p className="text-sm text-gray-600 mb-2">
                            {customers.get(order.customer_id)?.name}
                          </p>
                        )}
                        <p className="text-xs text-gray-500 mb-3">
                          {getRelativeTime(order.created_at)}
                        </p>
                        <div className="flex gap-2">
                          <button
                            onClick={() => onViewOrder(order)}
                            className="flex-1 flex items-center justify-center gap-1 px-3 py-1.5 text-sm bg-blue-50 text-blue-700 hover:bg-blue-100 rounded transition-colors"
                          >
                            <Eye size={14} />
                            Ver
                          </button>
                          <button
                            onClick={() => onEditOrder(order)}
                            className="flex-1 flex items-center justify-center gap-1 px-3 py-1.5 text-sm bg-gray-50 text-gray-700 hover:bg-gray-100 rounded transition-colors"
                          >
                            <Edit size={14} />
                            Editar
                          </button>
                        </div>
                      </div>
                    ))}
                  </div>
                )}
              </div>
            </div>

            {upcomingOrders.length > 0 && (
              <div className="bg-white rounded-lg shadow-sm border border-gray-200">
                <div className="p-6 border-b border-gray-200">
                  <div className="flex items-center gap-2">
                    <AlertCircle className="text-orange-600" size={24} />
                    <h2 className="text-xl font-bold text-gray-800">Pedidos Próximos a Vencer</h2>
                  </div>
                </div>
                <div className="p-6">
                  <div className="space-y-3">
                    {upcomingOrders.map((order) => {
                      const urgency = getUrgencyLevel(order.promised_date!);
                      return (
                        <div
                          key={order.id}
                          className={`border rounded-lg p-4 ${urgency.color}`}
                        >
                          <div className="flex items-center justify-between">
                            <div className="flex-1">
                              <h3 className="font-semibold">{order.name}</h3>
                              <p className="text-sm opacity-75">#{order.order_number}</p>
                              <div className="flex items-center gap-2 mt-2">
                                <Calendar size={14} />
                                <span className="text-sm">
                                  {new Date(order.promised_date!).toLocaleDateString('es-ES', {
                                    day: 'numeric',
                                    month: 'long',
                                    hour: '2-digit',
                                    minute: '2-digit'
                                  })}
                                </span>
                              </div>
                            </div>
                            <div className="text-right">
                              <span className="text-xs font-bold">{urgency.label}</span>
                              <button
                                onClick={() => onViewOrder(order)}
                                className="mt-2 px-3 py-1 bg-white border border-current rounded text-sm hover:bg-opacity-20 transition-colors"
                              >
                                Ver
                              </button>
                            </div>
                          </div>
                        </div>
                      );
                    })}
                  </div>
                </div>
              </div>
            )}
          </div>

          <div className="space-y-6">
            <div className="bg-white rounded-lg shadow-sm border border-gray-200">
              <div className="p-6 border-b border-gray-200">
                <h2 className="text-xl font-bold text-gray-800">Actividad Reciente</h2>
              </div>
              <div className="p-6">
                {recentActivity.length === 0 ? (
                  <p className="text-center text-gray-400 py-8">No hay actividad reciente</p>
                ) : (
                  <div className="space-y-4">
                    {recentActivity.map((activity) => (
                      <div key={activity.id} className="flex gap-3">
                        <div className="flex-shrink-0">
                          {activity.type === 'order_created' && (
                            <div className="w-8 h-8 bg-blue-100 rounded-full flex items-center justify-center">
                              <Package className="text-blue-600" size={16} />
                            </div>
                          )}
                          {activity.type === 'customer_created' && (
                            <div className="w-8 h-8 bg-green-100 rounded-full flex items-center justify-center">
                              <Users className="text-green-600" size={16} />
                            </div>
                          )}
                        </div>
                        <div className="flex-1">
                          <p className="text-sm text-gray-800">{activity.description}</p>
                          <p className="text-xs text-gray-500 mt-1">
                            {getRelativeTime(activity.timestamp)}
                          </p>
                        </div>
                      </div>
                    ))}
                  </div>
                )}
              </div>
            </div>

            <div className="bg-white rounded-lg shadow-sm border border-gray-200">
              <div className="p-6 border-b border-gray-200">
                <div className="flex items-center justify-between">
                  <h2 className="text-xl font-bold text-gray-800">Clientes Recientes</h2>
                  <button
                    onClick={onNavigateToCustomers}
                    className="text-sm text-blue-600 hover:text-blue-700 font-medium flex items-center gap-1"
                  >
                    Ver todos
                    <ArrowRight size={16} />
                  </button>
                </div>
              </div>
              <div className="p-6">
                {recentCustomers.length === 0 ? (
                  <p className="text-center text-gray-400 py-8">No hay clientes recientes</p>
                ) : (
                  <div className="space-y-3">
                    {recentCustomers.map((customer) => (
                      <div
                        key={customer.id}
                        className="flex items-center gap-3 p-3 rounded-lg hover:bg-gray-50 transition-colors cursor-pointer"
                        onClick={onNavigateToCustomers}
                      >
                        <div className="w-10 h-10 bg-blue-100 rounded-full flex items-center justify-center flex-shrink-0">
                          <Users className="text-blue-600" size={20} />
                        </div>
                        <div className="flex-1 min-w-0">
                          <p className="font-medium text-gray-800 truncate">{customer.name}</p>
                          <p className="text-sm text-gray-500 truncate">{customer.phone}</p>
                        </div>
                        <span className={`px-2 py-1 rounded text-xs font-medium ${
                          customer.customer_type === 'company'
                            ? 'bg-blue-100 text-blue-800'
                            : 'bg-gray-100 text-gray-800'
                        }`}>
                          {customer.customer_type === 'company' ? 'Empresa' : 'Particular'}
                        </span>
                      </div>
                    ))}
                  </div>
                )}
              </div>
            </div>
          </div>
        </div>
      </div>
      {showImportModal && (
        <SVGOrderImportModal
          onClose={() => setShowImportModal(false)}
          onImportSuccess={handleImportSuccess}
          customers={Array.from(customers.values())}
        />
      )}
    </div>
  );
}
