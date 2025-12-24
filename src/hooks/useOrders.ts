import { useState, useEffect, useCallback } from 'react';
import { Order, Customer } from '../types';
import { api } from '../lib/api';
import { useAuth } from '../contexts/AuthContext';

export function useOrders() {
  const { user } = useAuth();
  const [orders, setOrders] = useState<Order[]>([]);
  const [customers, setCustomers] = useState<Map<string, Customer>>(new Map());
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<Error | null>(null);

  const loadData = useCallback(async () => {
    if (!user) {
      setOrders([]);
      setCustomers(new Map());
      setLoading(false);
      return;
    }

    try {
      setLoading(true);
      setError(null);

      const [ordersData, customersData] = await Promise.all([
        api.get<Order[]>('/api/orders'),
        api.get<Customer[]>('/api/customers')
      ]);

      const ordersWithCuts = ordersData.map((order) => ({
        ...order,
        cuts: order.cuts || []
      }));

      setOrders(ordersWithCuts);

      const customersMap = new Map<string, Customer>();
      customersData.forEach((customer) => {
        customersMap.set(customer.id, customer);
      });
      setCustomers(customersMap);
    } catch (err) {
      console.error('Error loading orders and customers:', err);
      setError(err as Error);
    } finally {
      setLoading(false);
    }
  }, [user]);

  useEffect(() => {
    loadData();
  }, [loadData]);

  const refetch = useCallback(() => {
    return loadData();
  }, [loadData]);

  return {
    orders,
    customers,
    loading,
    error,
    refetch
  };
}
