import { useState, useEffect } from 'react';
import { Plus, Filter, FileUp } from 'lucide-react';
import { Order, OrderStatus, Customer } from '../types';
import { supabase } from '../lib/supabase';
import { useAuth } from '../contexts/AuthContext';
import { OrderCard } from './OrderCard';
import { SVGOrderImportModal } from './SVGOrderImportModal';

interface OrderBoardProps {
  onNewOrder: () => void;
  onEditOrder: (order: Order) => void;
  onViewOrder: (order: Order) => void;
  onAssignMaterial: (order: Order) => void;
  onStartCutting: (order: Order) => void;
  onViewPDF?: (pdfUrl: string, orderName: string) => void;
}

const columns: { status: OrderStatus; label: string; color: string }[] = [
  { status: 'quoted', label: 'Presupuestados', color: 'bg-gray-100' },
  { status: 'approved', label: 'Aprobados', color: 'bg-blue-100' },
  { status: 'in_production', label: 'En Producción', color: 'bg-yellow-100' },
  { status: 'ready', label: 'Listos', color: 'bg-green-100' },
  { status: 'delivered', label: 'Entregados', color: 'bg-emerald-100' }
];

export function OrderBoard({ onNewOrder, onEditOrder, onViewOrder, onAssignMaterial, onStartCutting, onViewPDF }: OrderBoardProps) {
  const { profile } = useAuth();
  const [orders, setOrders] = useState<Order[]>([]);
  const [customers, setCustomers] = useState<Map<string, Customer>>(new Map());
  const [loading, setLoading] = useState(true);
  const [showCancelled, setShowCancelled] = useState(false);
  const [showImportModal, setShowImportModal] = useState(false);

  useEffect(() => {
    if (profile) {
      loadData();
    }
  }, [profile]);

  const loadData = async () => {
    try {
      setLoading(true);

      const [ordersResult, customersResult] = await Promise.all([
        supabase
          .from('glass_projects')
          .select('*')
          .order('created_at', { ascending: false }),
        supabase.from('customers').select('*')
      ]);

      if (ordersResult.error) throw ordersResult.error;
      if (customersResult.error) throw customersResult.error;

      const ordersData = (ordersResult.data || []).map((order) => ({
        ...order,
        cuts: order.cuts || []
      })) as Order[];

      setOrders(ordersData);

      const customersMap = new Map<string, Customer>();
      (customersResult.data || []).forEach((customer) => {
        customersMap.set(customer.id, customer as Customer);
      });
      setCustomers(customersMap);
    } catch (error) {
      console.error('Error loading data:', error);
    } finally {
      setLoading(false);
    }
  };

  const handleStatusChange = async (orderId: string, newStatus: OrderStatus) => {
    try {
      const updateData: any = {
        status: newStatus,
        updated_at: new Date().toISOString()
      };

      if (newStatus === 'approved' && !orders.find((o) => o.id === orderId)?.approved_date) {
        updateData.approved_date = new Date().toISOString();
      }

      if (newStatus === 'delivered' && !orders.find((o) => o.id === orderId)?.delivered_date) {
        updateData.delivered_date = new Date().toISOString();
      }

      const { error } = await supabase
        .from('glass_projects')
        .update(updateData)
        .eq('id', orderId);

      if (error) throw error;

      loadData();
    } catch (error) {
      console.error('Error updating order status:', error);
      alert('Error al cambiar el estado del pedido');
    }
  };

  const getOrdersByStatus = (status: OrderStatus) => {
    return orders.filter((order) => order.status === status);
  };

  const cancelledOrders = orders.filter((order) => order.status === 'cancelled');

  const handleImportSuccess = async (orderId: string) => {
    setShowImportModal(false);
    await loadData();
    const importedOrder = orders.find(o => o.id === orderId);
    if (importedOrder) {
      onEditOrder(importedOrder);
    }
  };

  if (!profile) {
    return (
      <div className="flex items-center justify-center h-64">
        <p className="text-gray-500">Debes iniciar sesión para ver los pedidos</p>
      </div>
    );
  }

  return (
    <div className="h-full flex flex-col bg-gray-50">
      <div className="bg-white border-b px-6 py-4">
        <div className="flex items-center justify-between">
          <h2 className="text-2xl font-bold text-gray-800">Tablero de Pedidos</h2>
          <div className="flex items-center gap-3">
            <button
              onClick={() => setShowImportModal(true)}
              className="flex items-center gap-2 px-4 py-2 bg-green-600 text-white hover:bg-green-700 rounded-lg font-medium transition-colors"
            >
              <FileUp size={20} />
              Importar PDF
            </button>
            <button
              onClick={() => setShowCancelled(!showCancelled)}
              className={`flex items-center gap-2 px-4 py-2 rounded-lg font-medium transition-colors ${
                showCancelled
                  ? 'bg-red-100 text-red-700 border border-red-300'
                  : 'border border-gray-300 text-gray-700 hover:bg-gray-50'
              }`}
            >
              <Filter size={20} />
              {showCancelled ? 'Ocultar' : 'Ver'} Cancelados ({cancelledOrders.length})
            </button>
            <button
              onClick={onNewOrder}
              className="flex items-center gap-2 px-4 py-2 bg-blue-600 hover:bg-blue-700 text-white rounded-lg font-medium transition-colors"
            >
              <Plus size={20} />
              Nuevo Pedido
            </button>
          </div>
        </div>
      </div>

      <div className="flex-1 overflow-x-auto overflow-y-hidden">
        {loading ? (
          <div className="flex items-center justify-center h-full">
            <p className="text-gray-500">Cargando pedidos...</p>
          </div>
        ) : (
          <div className="h-full p-6">
            <div className="flex gap-4 h-full">
              {columns.map((column) => {
                const columnOrders = getOrdersByStatus(column.status);
                return (
                  <div
                    key={column.status}
                    className="flex-shrink-0 w-80 flex flex-col bg-white rounded-lg shadow-sm border border-gray-200"
                  >
                    <div className={`${column.color} px-4 py-3 rounded-t-lg border-b`}>
                      <h3 className="font-bold text-gray-800">
                        {column.label}
                        <span className="ml-2 text-sm font-normal text-gray-600">
                          ({columnOrders.length})
                        </span>
                      </h3>
                    </div>
                    <div className="flex-1 overflow-y-auto p-3 space-y-3">
                      {columnOrders.map((order) => (
                        <OrderCard
                          key={order.id}
                          order={order}
                          customer={
                            order.customer_id ? customers.get(order.customer_id) || null : null
                          }
                          onStatusChange={handleStatusChange}
                          onEdit={onEditOrder}
                          onView={onViewOrder}
                          onAssignMaterial={onAssignMaterial}
                          onStartCutting={onStartCutting}
                          onViewPDF={onViewPDF}
                        />
                      ))}
                      {columnOrders.length === 0 && (
                        <p className="text-center text-gray-400 text-sm py-8">
                          No hay pedidos en este estado
                        </p>
                      )}
                    </div>
                  </div>
                );
              })}

              {showCancelled && (
                <div className="flex-shrink-0 w-80 flex flex-col bg-white rounded-lg shadow-sm border border-gray-200">
                  <div className="bg-red-100 px-4 py-3 rounded-t-lg border-b">
                    <h3 className="font-bold text-gray-800">
                      Cancelados
                      <span className="ml-2 text-sm font-normal text-gray-600">
                        ({cancelledOrders.length})
                      </span>
                    </h3>
                  </div>
                  <div className="flex-1 overflow-y-auto p-3 space-y-3">
                    {cancelledOrders.map((order) => (
                      <OrderCard
                        key={order.id}
                        order={order}
                        customer={
                          order.customer_id ? customers.get(order.customer_id) || null : null
                        }
                        onStatusChange={handleStatusChange}
                        onEdit={onEditOrder}
                        onView={onViewOrder}
                        onAssignMaterial={onAssignMaterial}
                        onStartCutting={onStartCutting}
                        onViewPDF={onViewPDF}
                      />
                    ))}
                    {cancelledOrders.length === 0 && (
                      <p className="text-center text-gray-400 text-sm py-8">
                        No hay pedidos cancelados
                      </p>
                    )}
                  </div>
                </div>
              )}
            </div>
          </div>
        )}
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
