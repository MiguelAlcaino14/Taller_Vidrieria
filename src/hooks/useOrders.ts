import { useState, useEffect, useCallback } from 'react';
import { Order, Customer } from '../types';
import { supabase } from '../lib/supabase';
import { useAuth } from '../contexts/AuthContext';

export function useOrders() {
  const { profile } = useAuth();
  const [orders, setOrders] = useState<Order[]>([]);
  const [customers, setCustomers] = useState<Map<string, Customer>>(new Map());
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<Error | null>(null);

  const loadData = useCallback(async () => {
    if (!profile) {
      setOrders([]);
      setCustomers(new Map());
      setLoading(false);
      return;
    }

    try {
      setLoading(true);
      setError(null);

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
    } catch (err) {
      console.error('Error loading orders and customers:', err);
      setError(err as Error);
    } finally {
      setLoading(false);
    }
  }, [profile]);

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
