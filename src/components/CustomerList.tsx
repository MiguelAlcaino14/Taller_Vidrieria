import { useState, useEffect } from 'react';
import { User, Building2, Phone, Mail, MapPin, Edit2, Trash2, Plus, Search } from 'lucide-react';
import { Customer } from '../types';
import { supabase } from '../lib/supabase';
import { useAuth } from '../contexts/AuthContext';
import { CustomerModal } from './CustomerModal';

export function CustomerList() {
  const { profile } = useAuth();
  const [customers, setCustomers] = useState<Customer[]>([]);
  const [filteredCustomers, setFilteredCustomers] = useState<Customer[]>([]);
  const [searchQuery, setSearchQuery] = useState('');
  const [loading, setLoading] = useState(true);
  const [modalOpen, setModalOpen] = useState(false);
  const [selectedCustomer, setSelectedCustomer] = useState<Customer | null>(null);

  useEffect(() => {
    if (profile) {
      loadCustomers();
    }
  }, [profile]);

  useEffect(() => {
    if (searchQuery.trim() === '') {
      setFilteredCustomers(customers);
    } else {
      const query = searchQuery.toLowerCase();
      const filtered = customers.filter(
        (c) =>
          c.name.toLowerCase().includes(query) ||
          c.phone.includes(query) ||
          c.email.toLowerCase().includes(query)
      );
      setFilteredCustomers(filtered);
    }
  }, [searchQuery, customers]);

  const loadCustomers = async () => {
    try {
      setLoading(true);
      const { data, error } = await supabase
        .from('customers')
        .select('*')
        .order('name', { ascending: true });

      if (error) throw error;
      setCustomers(data || []);
      setFilteredCustomers(data || []);
    } catch (error) {
      console.error('Error loading customers:', error);
    } finally {
      setLoading(false);
    }
  };

  const handleDelete = async (customer: Customer) => {
    if (!confirm(`¿Estás seguro de eliminar el cliente ${customer.name}?`)) {
      return;
    }

    try {
      const { error } = await supabase
        .from('customers')
        .delete()
        .eq('id', customer.id);

      if (error) throw error;
      loadCustomers();
    } catch (error) {
      console.error('Error deleting customer:', error);
      alert('Error al eliminar el cliente');
    }
  };

  const handleEdit = (customer: Customer) => {
    setSelectedCustomer(customer);
    setModalOpen(true);
  };

  const handleNew = () => {
    setSelectedCustomer(null);
    setModalOpen(true);
  };

  const handleModalClose = () => {
    setModalOpen(false);
    setSelectedCustomer(null);
  };

  const handleModalSave = () => {
    loadCustomers();
  };

  if (!profile) {
    return (
      <div className="flex items-center justify-center h-64">
        <p className="text-gray-500">Debes iniciar sesión para ver los clientes</p>
      </div>
    );
  }

  return (
    <div className="h-full flex flex-col bg-gray-50">
      <div className="bg-white border-b px-6 py-4">
        <div className="flex items-center justify-between mb-4">
          <h2 className="text-2xl font-bold text-gray-800">Clientes</h2>
          <button
            onClick={handleNew}
            className="flex items-center gap-2 px-4 py-2 bg-blue-600 hover:bg-blue-700 text-white rounded-lg font-medium transition-colors"
          >
            <Plus size={20} />
            Nuevo Cliente
          </button>
        </div>

        <div className="relative">
          <Search className="absolute left-3 top-1/2 transform -translate-y-1/2 text-gray-400" size={20} />
          <input
            type="text"
            value={searchQuery}
            onChange={(e) => setSearchQuery(e.target.value)}
            placeholder="Buscar por nombre, teléfono o email..."
            className="w-full pl-10 pr-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent"
          />
        </div>
      </div>

      <div className="flex-1 overflow-y-auto p-6">
        {loading ? (
          <div className="text-center py-12">
            <p className="text-gray-500">Cargando clientes...</p>
          </div>
        ) : filteredCustomers.length === 0 ? (
          <div className="text-center py-12">
            <p className="text-gray-500">
              {searchQuery ? 'No se encontraron clientes' : 'No hay clientes registrados'}
            </p>
          </div>
        ) : (
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
            {filteredCustomers.map((customer) => (
              <div
                key={customer.id}
                className="bg-white rounded-lg shadow-sm border border-gray-200 hover:shadow-md transition-shadow"
              >
                <div className="p-5">
                  <div className="flex items-start justify-between mb-3">
                    <div className="flex items-center gap-2">
                      {customer.customer_type === 'company' ? (
                        <Building2 className="text-blue-600" size={20} />
                      ) : (
                        <User className="text-blue-600" size={20} />
                      )}
                      <h3 className="font-bold text-gray-800 text-lg">{customer.name}</h3>
                    </div>
                    <span className="text-xs text-gray-500 bg-gray-100 px-2 py-1 rounded">
                      {customer.customer_type === 'company' ? 'Empresa' : 'Particular'}
                    </span>
                  </div>

                  <div className="space-y-2 mb-4">
                    <div className="flex items-center gap-2 text-sm text-gray-600">
                      <Phone size={16} className="text-gray-400" />
                      <span>{customer.phone}</span>
                    </div>
                    {customer.email && (
                      <div className="flex items-center gap-2 text-sm text-gray-600">
                        <Mail size={16} className="text-gray-400" />
                        <span className="truncate">{customer.email}</span>
                      </div>
                    )}
                    {customer.address && (
                      <div className="flex items-center gap-2 text-sm text-gray-600">
                        <MapPin size={16} className="text-gray-400" />
                        <span className="truncate">{customer.address}</span>
                      </div>
                    )}
                  </div>

                  {customer.notes && (
                    <p className="text-sm text-gray-500 mb-4 line-clamp-2">{customer.notes}</p>
                  )}

                  <div className="flex gap-2">
                    <button
                      onClick={() => handleEdit(customer)}
                      className="flex-1 flex items-center justify-center gap-2 px-3 py-2 border border-gray-300 text-gray-700 rounded-lg hover:bg-gray-50 transition-colors text-sm font-medium"
                    >
                      <Edit2 size={16} />
                      Editar
                    </button>
                    <button
                      onClick={() => handleDelete(customer)}
                      className="flex items-center justify-center gap-2 px-3 py-2 border border-red-300 text-red-600 rounded-lg hover:bg-red-50 transition-colors text-sm font-medium"
                    >
                      <Trash2 size={16} />
                    </button>
                  </div>
                </div>
              </div>
            ))}
          </div>
        )}
      </div>

      <CustomerModal
        isOpen={modalOpen}
        customer={selectedCustomer}
        onClose={handleModalClose}
        onSave={handleModalSave}
      />
    </div>
  );
}
