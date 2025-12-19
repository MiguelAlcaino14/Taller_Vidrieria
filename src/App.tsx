import { useState } from 'react';
import { Scissors, LogIn, Users, ClipboardList, Layout, LayoutDashboard, Package } from 'lucide-react';
import { InputPanel } from './components/InputPanel';
import { VisualizationPanel } from './components/VisualizationPanel';
import { ProjectModal } from './components/ProjectModal';
import { AuthModal } from './components/AuthModal';
import { UserProfilePanel } from './components/UserProfilePanel';
import { CustomerList } from './components/CustomerList';
import { OrderBoard } from './components/OrderBoard';
import { Dashboard } from './components/Dashboard';
import InventoryManagement from './components/InventoryManagement';
import AddSheetModal from './components/AddSheetModal';
import MaterialAssignment from './components/MaterialAssignment';
import CuttingExecution from './components/CuttingExecution';
import { PDFViewerModal } from './components/PDFViewerModal';
import { Cut, Sheet, Order, MaterialSheet } from './types';
import { packCutsWithDetails } from './utils/packing';
import { supabase } from './lib/supabase';
import { useAuth } from './contexts/AuthContext';

type View = 'dashboard' | 'customers' | 'orders' | 'optimizer' | 'inventory';

function AppContent() {
  const { profile } = useAuth();
  const [currentView, setCurrentView] = useState<View>('dashboard');
  const [sheet, setSheet] = useState<Sheet>({
    width: 200,
    height: 300,
    cutThickness: 0,
    glassThickness: 4,
    cuttingMethod: 'manual'
  });

  const [cuts, setCuts] = useState<Cut[]>([]);
  const [modalOpen, setModalOpen] = useState(false);
  const [modalMode, setModalMode] = useState<'save' | 'load'>('save');
  const [currentProjectId, setCurrentProjectId] = useState<string | null>(null);
  const [authModalOpen, setAuthModalOpen] = useState(false);
  const [addSheetModalOpen, setAddSheetModalOpen] = useState(false);
  const [editingSheet, setEditingSheet] = useState<MaterialSheet | null>(null);
  const [materialAssignmentOrder, setMaterialAssignmentOrder] = useState<Order | null>(null);
  const [cuttingExecutionOrder, setCuttingExecutionOrder] = useState<Order | null>(null);
  const [refreshInventory, setRefreshInventory] = useState(0);
  const [pdfViewerOpen, setPdfViewerOpen] = useState(false);
  const [currentPdfUrl, setCurrentPdfUrl] = useState<string>('');
  const [currentPdfOrderName, setCurrentPdfOrderName] = useState<string>('');

  const packingResult = packCutsWithDetails(cuts, sheet);
  const { placedCuts, utilization, cutLines, cutInstructions, method, remnants } = packingResult;

  const handleAddCut = (cut: Cut) => {
    setCuts([...cuts, cut]);
  };

  const handleRemoveCut = (id: string) => {
    setCuts(cuts.filter(c => c.id !== id));
  };

  const handleClearAll = () => {
    if (confirm('¿Estás seguro de eliminar todos los cortes?')) {
      setCuts([]);
    }
  };

  const handleSave = async (name: string) => {
    if (!profile) {
      alert('Debes iniciar sesión para guardar proyectos');
      setAuthModalOpen(true);
      return;
    }

    try {
      const projectData = {
        name,
        user_id: profile.id,
        sheet_width: sheet.width,
        sheet_height: sheet.height,
        cut_thickness: sheet.cutThickness,
        glass_thickness: sheet.glassThickness,
        cutting_method: sheet.cuttingMethod,
        cuts: cuts.map(c => ({
          width: c.width,
          height: c.height,
          quantity: c.quantity,
          label: c.label
        })),
        updated_at: new Date().toISOString()
      };

      if (currentProjectId) {
        const { error } = await supabase
          .from('glass_projects')
          .update(projectData)
          .eq('id', currentProjectId);

        if (error) throw error;
      } else {
        const { data, error } = await supabase
          .from('glass_projects')
          .insert([projectData])
          .select()
          .single();

        if (error) throw error;
        setCurrentProjectId(data.id);
      }

      alert('Proyecto guardado exitosamente');
    } catch (error) {
      console.error('Error saving project:', error);
      alert('Error al guardar el proyecto');
    }
  };

  const handleLoad = async (projectId: string) => {
    try {
      const { data, error } = await supabase
        .from('glass_projects')
        .select('*')
        .eq('id', projectId)
        .maybeSingle();

      if (error) throw error;
      if (!data) return;

      setSheet({
        width: data.sheet_width,
        height: data.sheet_height,
        cutThickness: data.cut_thickness,
        glassThickness: data.glass_thickness || 4,
        cuttingMethod: data.cutting_method || 'manual'
      });

      setCuts(data.cuts.map((c: any, index: number) => ({
        id: Date.now() + index + '',
        width: c.width,
        height: c.height,
        quantity: c.quantity,
        label: c.label
      })));

      setCurrentProjectId(data.id);
    } catch (error) {
      console.error('Error loading project:', error);
      alert('Error al cargar el proyecto');
    }
  };

  const openSaveModal = () => {
    setModalMode('save');
    setModalOpen(true);
  };

  const openLoadModal = () => {
    if (!profile) {
      alert('Debes iniciar sesión para cargar proyectos');
      setAuthModalOpen(true);
      return;
    }
    setModalMode('load');
    setModalOpen(true);
  };

  const handleNewOrder = () => {
    setCurrentView('optimizer');
    setCuts([]);
    setCurrentProjectId(null);
  };

  const handleEditOrder = (order: Order) => {
    setSheet({
      width: order.sheet_width,
      height: order.sheet_height,
      cutThickness: order.cut_thickness,
      glassThickness: order.glass_thickness,
      cuttingMethod: order.cutting_method
    });

    setCuts(order.cuts.map((c: any, index: number) => ({
      id: Date.now() + index + '',
      width: c.width,
      height: c.height,
      quantity: c.quantity,
      label: c.label
    })));

    setCurrentProjectId(order.id);
    setCurrentView('optimizer');
  };

  const handleViewOrder = (order: Order) => {
    handleEditOrder(order);
  };

  const handleAddSheet = () => {
    setEditingSheet(null);
    setAddSheetModalOpen(true);
  };

  const handleEditSheet = (sheet: MaterialSheet) => {
    setEditingSheet(sheet);
    setAddSheetModalOpen(true);
  };

  const handleSheetModalSuccess = () => {
    setRefreshInventory(prev => prev + 1);
  };

  const handleAssignMaterial = (order: Order) => {
    setMaterialAssignmentOrder(order);
  };

  const handleStartCutting = (order: Order) => {
    setCuttingExecutionOrder(order);
  };

  const handleMaterialAssignmentSuccess = () => {
    setRefreshInventory(prev => prev + 1);
  };

  const handleCuttingExecutionSuccess = () => {
    setRefreshInventory(prev => prev + 1);
  };

  const handleViewPDF = (pdfUrl: string, orderName: string) => {
    setCurrentPdfUrl(pdfUrl);
    setCurrentPdfOrderName(orderName);
    setPdfViewerOpen(true);
  };

  return (
    <div className="h-screen flex flex-col bg-gray-100">
      <header className="bg-white shadow-sm">
        <div className="px-4 sm:px-6 py-4 flex flex-col sm:flex-row items-start sm:items-center justify-between border-b gap-4">
          <div className="flex items-center gap-3">
            <Scissors className="text-blue-600 flex-shrink-0" size={32} />
            <div>
              <h1 className="text-xl sm:text-2xl font-bold text-gray-800">
                Gestión Vidriería
              </h1>
              <p className="text-xs sm:text-sm text-gray-600 hidden sm:block">
                Gestión completa de clientes, pedidos y optimización de cortes
              </p>
            </div>
          </div>
          {!profile && (
            <button
              onClick={() => setAuthModalOpen(true)}
              className="flex items-center gap-2 px-4 py-2 bg-blue-600 hover:bg-blue-700 text-white rounded-lg font-medium transition-colors text-sm"
            >
              <LogIn size={18} />
              <span className="hidden sm:inline">Iniciar Sesión</span>
              <span className="sm:hidden">Ingresar</span>
            </button>
          )}
        </div>
        {profile && <UserProfilePanel />}

        {profile && (
          <div className="grid grid-cols-2 sm:flex border-b">
            <button
              onClick={() => setCurrentView('dashboard')}
              className={`flex items-center justify-center gap-2 px-3 sm:px-6 py-3 font-medium transition-colors whitespace-nowrap ${
                currentView === 'dashboard'
                  ? 'text-blue-600 border-b-2 border-blue-600 bg-blue-50'
                  : 'text-gray-600 hover:text-gray-800 hover:bg-gray-50'
              }`}
            >
              <LayoutDashboard size={18} />
              <span className="text-sm sm:text-base">Dashboard</span>
            </button>
            <button
              onClick={() => setCurrentView('customers')}
              className={`flex items-center justify-center gap-2 px-3 sm:px-6 py-3 font-medium transition-colors whitespace-nowrap ${
                currentView === 'customers'
                  ? 'text-blue-600 border-b-2 border-blue-600 bg-blue-50'
                  : 'text-gray-600 hover:text-gray-800 hover:bg-gray-50'
              }`}
            >
              <Users size={18} />
              <span className="text-sm sm:text-base">Clientes</span>
            </button>
            <button
              onClick={() => setCurrentView('orders')}
              className={`flex items-center justify-center gap-2 px-3 sm:px-6 py-3 font-medium transition-colors whitespace-nowrap ${
                currentView === 'orders'
                  ? 'text-blue-600 border-b-2 border-blue-600 bg-blue-50'
                  : 'text-gray-600 hover:text-gray-800 hover:bg-gray-50'
              }`}
            >
              <ClipboardList size={18} />
              <span className="text-sm sm:text-base">Pedidos</span>
            </button>
            <button
              onClick={() => setCurrentView('optimizer')}
              className={`flex items-center justify-center gap-2 px-3 sm:px-6 py-3 font-medium transition-colors whitespace-nowrap ${
                currentView === 'optimizer'
                  ? 'text-blue-600 border-b-2 border-blue-600 bg-blue-50'
                  : 'text-gray-600 hover:text-gray-800 hover:bg-gray-50'
              }`}
            >
              <Layout size={18} />
              <span className="text-sm sm:text-base">Optimizador</span>
            </button>
            <button
              onClick={() => setCurrentView('inventory')}
              className={`flex items-center justify-center gap-2 px-3 sm:px-6 py-3 font-medium transition-colors whitespace-nowrap ${
                currentView === 'inventory'
                  ? 'text-blue-600 border-b-2 border-blue-600 bg-blue-50'
                  : 'text-gray-600 hover:text-gray-800 hover:bg-gray-50'
              }`}
            >
              <Package size={18} />
              <span className="text-sm sm:text-base">Inventario</span>
            </button>
          </div>
        )}
      </header>

      <div className="flex-1 overflow-hidden">
        {!profile ? (
          <div className="h-full flex items-center justify-center">
            <div className="text-center">
              <Scissors className="mx-auto text-gray-300 mb-4" size={64} />
              <h2 className="text-2xl font-bold text-gray-800 mb-2">
                Bienvenido al Sistema de Gestión de Vidriería
              </h2>
              <p className="text-gray-600 mb-6">
                Inicia sesión para acceder a todas las funcionalidades
              </p>
              <button
                onClick={() => setAuthModalOpen(true)}
                className="px-6 py-3 bg-blue-600 hover:bg-blue-700 text-white rounded-lg font-medium transition-colors"
              >
                Iniciar Sesión
              </button>
            </div>
          </div>
        ) : currentView === 'dashboard' ? (
          <Dashboard
            onNavigateToOrders={() => setCurrentView('orders')}
            onNavigateToCustomers={() => setCurrentView('customers')}
            onEditOrder={handleEditOrder}
            onViewOrder={handleViewOrder}
          />
        ) : currentView === 'customers' ? (
          <CustomerList />
        ) : currentView === 'orders' ? (
          <OrderBoard
            onNewOrder={handleNewOrder}
            onEditOrder={handleEditOrder}
            onViewOrder={handleViewOrder}
            onAssignMaterial={handleAssignMaterial}
            onStartCutting={handleStartCutting}
            onViewPDF={handleViewPDF}
          />
        ) : currentView === 'inventory' ? (
          <InventoryManagement
            key={refreshInventory}
            onAddSheet={handleAddSheet}
            onEditSheet={handleEditSheet}
          />
        ) : (
          <div className="h-full flex flex-col lg:grid lg:grid-cols-2 gap-0">
            <div className="h-1/2 lg:h-full overflow-hidden border-b lg:border-b-0 lg:border-r border-gray-200">
              <InputPanel
                sheet={sheet}
                cuts={cuts}
                onSheetChange={setSheet}
                onAddCut={handleAddCut}
                onRemoveCut={handleRemoveCut}
                onClearAll={handleClearAll}
                onSave={openSaveModal}
                onLoad={openLoadModal}
              />
            </div>

            <div className="h-1/2 lg:h-full overflow-hidden">
              <VisualizationPanel
                sheet={sheet}
                placedCuts={placedCuts}
                utilization={utilization}
                cutLines={cutLines}
                cutInstructions={cutInstructions}
                method={method}
                remnants={remnants}
              />
            </div>
          </div>
        )}
      </div>

      <ProjectModal
        isOpen={modalOpen}
        mode={modalMode}
        onClose={() => setModalOpen(false)}
        onSave={handleSave}
        onLoad={handleLoad}
      />

      <AuthModal
        isOpen={authModalOpen}
        onClose={() => setAuthModalOpen(false)}
      />

      <AddSheetModal
        isOpen={addSheetModalOpen}
        onClose={() => {
          setAddSheetModalOpen(false);
          setEditingSheet(null);
        }}
        onSuccess={handleSheetModalSuccess}
        editSheet={editingSheet}
      />

      {materialAssignmentOrder && (
        <MaterialAssignment
          order={materialAssignmentOrder}
          onClose={() => setMaterialAssignmentOrder(null)}
          onSuccess={handleMaterialAssignmentSuccess}
        />
      )}

      {cuttingExecutionOrder && (
        <CuttingExecution
          order={cuttingExecutionOrder}
          onClose={() => setCuttingExecutionOrder(null)}
          onSuccess={handleCuttingExecutionSuccess}
        />
      )}

      <PDFViewerModal
        pdfUrl={currentPdfUrl}
        orderName={currentPdfOrderName}
        isOpen={pdfViewerOpen}
        onClose={() => setPdfViewerOpen(false)}
      />
    </div>
  );
}

export default AppContent;
