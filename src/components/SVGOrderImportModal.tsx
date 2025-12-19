import { useState, useRef } from 'react';
import { X, Upload, FileText, AlertCircle, CheckCircle2, User, Phone, Package, Ruler, Hash } from 'lucide-react';
import { parsePDFOrder, validateParsedOrder } from '../utils/pdfOrderParser';
import { supabase } from '../lib/supabase';
import { useAuth } from '../contexts/AuthContext';
import { Customer, Cut } from '../types';

interface SVGOrderImportModalProps {
  onClose: () => void;
  onImportSuccess: (orderId: string) => void;
  customers: Customer[];
}

interface ParsedPiece {
  code: string;
  width: number;
  height: number;
  quantity: number;
  thickness: number;
  isMirror: boolean;
  aluminumColor: string | null;
  materialType: 'glass' | 'mirror' | 'aluminum';
  label: string;
}

interface ParsedOrder {
  orderCode: string;
  orderNumber: string;
  date: string;
  customerName: string;
  customerPhone: string;
  pieces: ParsedPiece[];
  totalPieces: number;
  totalArea: number;
  estimatedTime: number;
}

export function SVGOrderImportModal({ onClose, onImportSuccess, customers }: SVGOrderImportModalProps) {
  const { profile } = useAuth();
  const [isDragging, setIsDragging] = useState(false);
  const [selectedFile, setSelectedFile] = useState<File | null>(null);
  const [parsedOrder, setParsedOrder] = useState<ParsedOrder | null>(null);
  const [validationErrors, setValidationErrors] = useState<string[]>([]);
  const [selectedCustomerId, setSelectedCustomerId] = useState<string>('');
  const [isCreatingCustomer, setIsCreatingCustomer] = useState(false);
  const [newCustomerName, setNewCustomerName] = useState('');
  const [newCustomerPhone, setNewCustomerPhone] = useState('');
  const [isImporting, setIsImporting] = useState(false);
  const [importError, setImportError] = useState<string>('');
  const fileInputRef = useRef<HTMLInputElement>(null);

  const handleDragEnter = (e: React.DragEvent) => {
    e.preventDefault();
    e.stopPropagation();
    setIsDragging(true);
  };

  const handleDragLeave = (e: React.DragEvent) => {
    e.preventDefault();
    e.stopPropagation();
    setIsDragging(false);
  };

  const handleDragOver = (e: React.DragEvent) => {
    e.preventDefault();
    e.stopPropagation();
  };

  const handleDrop = (e: React.DragEvent) => {
    e.preventDefault();
    e.stopPropagation();
    setIsDragging(false);

    const files = e.dataTransfer.files;
    if (files.length > 0) {
      handleFileSelection(files[0]);
    }
  };

  const handleFileInputChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    const files = e.target.files;
    if (files && files.length > 0) {
      handleFileSelection(files[0]);
    }
  };

  const handleFileSelection = async (file: File) => {
    const fileName = file.name.toLowerCase();
    const isPDF = fileName.endsWith('.pdf');

    if (!isPDF) {
      setImportError('Por favor selecciona un archivo PDF válido');
      return;
    }

    setSelectedFile(file);
    setImportError('');

    try {
      const parsed = await parsePDFOrder(file);
      const validation = validateParsedOrder(parsed);

      setParsedOrder(parsed);
      setValidationErrors(validation.errors);

      if (parsed && parsed.customerName) {
        const matchingCustomer = customers.find(
          c => c.name.toLowerCase() === parsed.customerName.toLowerCase()
        );
        if (matchingCustomer) {
          setSelectedCustomerId(matchingCustomer.id);
        } else {
          setNewCustomerName(parsed.customerName);
          setNewCustomerPhone(parsed.customerPhone);
        }
      }
    } catch (error) {
      setImportError('Error al leer el archivo PDF');
      console.error(error);
    }
  };

  const handleImport = async () => {
    if (!parsedOrder || !profile) return;

    setIsImporting(true);
    setImportError('');

    try {
      let customerId = selectedCustomerId;

      if (isCreatingCustomer && newCustomerName) {
        const { data: newCustomer, error: customerError } = await supabase
          .from('customers')
          .insert({
            user_id: profile.id,
            name: newCustomerName,
            phone: newCustomerPhone,
            email: '',
            address: '',
            customer_type: 'individual',
            notes: ''
          })
          .select()
          .single();

        if (customerError) throw customerError;
        customerId = newCustomer.id;
      }

      let pdfUrl = '';
      if (selectedFile) {
        const timestamp = Date.now();
        const fileName = `${profile.id}/${timestamp}_${parsedOrder.orderCode}.pdf`;

        const { error: uploadError } = await supabase.storage
          .from('order_documents')
          .upload(fileName, selectedFile, {
            contentType: 'application/pdf',
            upsert: false
          });

        if (uploadError) {
          console.error('Storage upload error:', uploadError);
        } else {
          const { data: { publicUrl } } = supabase.storage
            .from('order_documents')
            .getPublicUrl(fileName);
          pdfUrl = publicUrl;
        }
      }

      const cuts: Cut[] = parsedOrder.pieces.map(piece => ({
        id: crypto.randomUUID(),
        width: piece.width,
        height: piece.height,
        quantity: piece.quantity,
        label: piece.label
      }));

      const avgThickness = parsedOrder.pieces.length > 0
        ? parsedOrder.pieces.reduce((sum, p) => sum + p.thickness, 0) / parsedOrder.pieces.length
        : 4;

      const cuttingMethod = avgThickness >= 6 ? 'machine' : 'manual';

      const { data: newOrder, error: orderError } = await supabase
        .from('glass_projects')
        .insert({
          user_id: profile.id,
          customer_id: customerId || null,
          name: parsedOrder.orderCode,
          order_number: parsedOrder.orderNumber,
          status: 'quoted',
          notes: `Importado desde PDF - ${parsedOrder.date}`,
          sheet_width: 244,
          sheet_height: 183,
          cut_thickness: 0.3,
          glass_thickness: avgThickness,
          cutting_method: cuttingMethod,
          cuts: cuts,
          svg_source_url: pdfUrl || null,
          original_order_code: parsedOrder.orderCode,
          import_date: new Date().toISOString(),
          import_metadata: {
            source: 'pdf',
            original_code: parsedOrder.orderCode,
            pieces_count: parsedOrder.pieces.length,
            total_area: parsedOrder.totalArea,
            estimated_time: parsedOrder.estimatedTime,
            customer_name: parsedOrder.customerName,
            customer_phone: parsedOrder.customerPhone
          }
        })
        .select()
        .single();

      if (orderError) throw orderError;

      onImportSuccess(newOrder.id);
    } catch (error) {
      console.error('Import error:', error);
      setImportError('Error al importar el pedido. Por favor intenta nuevamente.');
    } finally {
      setIsImporting(false);
    }
  };

  const canImport = parsedOrder && validationErrors.length === 0 &&
    (selectedCustomerId || (isCreatingCustomer && newCustomerName));

  return (
    <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50 p-4">
      <div className="bg-white rounded-lg shadow-xl w-full max-w-4xl max-h-[90vh] flex flex-col">
        <div className="flex items-center justify-between p-6 border-b">
          <div>
            <h2 className="text-2xl font-bold text-gray-800">Importar Orden</h2>
            <p className="text-sm text-gray-600 mt-1">Carga un archivo PDF de orden de fabricación</p>
          </div>
          <button
            onClick={onClose}
            className="p-2 hover:bg-gray-100 rounded-lg transition-colors"
          >
            <X size={24} className="text-gray-600" />
          </button>
        </div>

        <div className="flex-1 overflow-y-auto p-6 space-y-6">
          {!parsedOrder ? (
            <div
              onDragEnter={handleDragEnter}
              onDragOver={handleDragOver}
              onDragLeave={handleDragLeave}
              onDrop={handleDrop}
              className={`border-2 border-dashed rounded-lg p-12 text-center transition-colors ${
                isDragging
                  ? 'border-blue-500 bg-blue-50'
                  : 'border-gray-300 hover:border-gray-400'
              }`}
            >
              <Upload size={48} className="mx-auto text-gray-400 mb-4" />
              <p className="text-lg font-medium text-gray-700 mb-2">
                Arrastra un archivo PDF aquí
              </p>
              <p className="text-sm text-gray-500 mb-4">o</p>
              <button
                onClick={() => fileInputRef.current?.click()}
                className="px-6 py-3 bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition-colors"
              >
                Seleccionar Archivo
              </button>
              <input
                ref={fileInputRef}
                type="file"
                accept=".pdf"
                onChange={handleFileInputChange}
                className="hidden"
              />
            </div>
          ) : (
            <div className="space-y-6">
              {validationErrors.length > 0 && (
                <div className="bg-red-50 border border-red-200 rounded-lg p-4">
                  <div className="flex items-start gap-3">
                    <AlertCircle className="text-red-600 flex-shrink-0 mt-0.5" size={20} />
                    <div>
                      <p className="font-medium text-red-800 mb-2">Errores de validación:</p>
                      <ul className="list-disc list-inside space-y-1 text-sm text-red-700">
                        {validationErrors.map((error, i) => (
                          <li key={i}>{error}</li>
                        ))}
                      </ul>
                    </div>
                  </div>
                </div>
              )}

              {validationErrors.length === 0 && (
                <div className="bg-green-50 border border-green-200 rounded-lg p-4">
                  <div className="flex items-center gap-3">
                    <CheckCircle2 className="text-green-600" size={20} />
                    <p className="font-medium text-green-800">Archivo procesado correctamente</p>
                  </div>
                </div>
              )}

              <div className="bg-gray-50 rounded-lg p-6 space-y-4">
                <h3 className="font-semibold text-gray-800 flex items-center gap-2">
                  <FileText size={20} />
                  Información de la Orden
                </h3>
                <div className="grid grid-cols-2 gap-4">
                  <div>
                    <p className="text-sm text-gray-600">Código de Orden</p>
                    <p className="font-medium text-gray-800">{parsedOrder.orderCode}</p>
                  </div>
                  <div>
                    <p className="text-sm text-gray-600">Número de Pedido</p>
                    <p className="font-medium text-gray-800">#{parsedOrder.orderNumber}</p>
                  </div>
                  <div>
                    <p className="text-sm text-gray-600">Cliente</p>
                    <p className="font-medium text-gray-800">{parsedOrder.customerName}</p>
                  </div>
                  <div>
                    <p className="text-sm text-gray-600">Teléfono</p>
                    <p className="font-medium text-gray-800">{parsedOrder.customerPhone}</p>
                  </div>
                </div>
              </div>

              <div className="bg-gray-50 rounded-lg p-6">
                <h3 className="font-semibold text-gray-800 mb-4 flex items-center gap-2">
                  <User size={20} />
                  Seleccionar Cliente
                </h3>

                {customers.length > 0 && (
                  <div className="mb-4">
                    <label className="block text-sm font-medium text-gray-700 mb-2">
                      Cliente Existente
                    </label>
                    <select
                      value={selectedCustomerId}
                      onChange={(e) => {
                        setSelectedCustomerId(e.target.value);
                        setIsCreatingCustomer(false);
                      }}
                      className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent"
                    >
                      <option value="">Seleccionar cliente...</option>
                      {customers.map((customer) => (
                        <option key={customer.id} value={customer.id}>
                          {customer.name} - {customer.phone}
                        </option>
                      ))}
                    </select>
                  </div>
                )}

                <button
                  onClick={() => {
                    setIsCreatingCustomer(!isCreatingCustomer);
                    setSelectedCustomerId('');
                  }}
                  className="text-sm text-blue-600 hover:text-blue-700 font-medium mb-4"
                >
                  {isCreatingCustomer ? 'Seleccionar cliente existente' : '+ Crear nuevo cliente'}
                </button>

                {isCreatingCustomer && (
                  <div className="space-y-4 pt-4 border-t">
                    <div>
                      <label className="block text-sm font-medium text-gray-700 mb-2">
                        Nombre *
                      </label>
                      <input
                        type="text"
                        value={newCustomerName}
                        onChange={(e) => setNewCustomerName(e.target.value)}
                        className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent"
                        placeholder="Nombre del cliente"
                      />
                    </div>
                    <div>
                      <label className="block text-sm font-medium text-gray-700 mb-2">
                        Teléfono
                      </label>
                      <input
                        type="text"
                        value={newCustomerPhone}
                        onChange={(e) => setNewCustomerPhone(e.target.value)}
                        className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent"
                        placeholder="Teléfono del cliente"
                      />
                    </div>
                  </div>
                )}
              </div>

              <div className="bg-gray-50 rounded-lg p-6">
                <h3 className="font-semibold text-gray-800 mb-4 flex items-center gap-2">
                  <Package size={20} />
                  Piezas a Importar ({parsedOrder.pieces.length})
                </h3>
                <div className="space-y-3 max-h-64 overflow-y-auto">
                  {parsedOrder.pieces.map((piece, index) => (
                    <div key={index} className="bg-white rounded-lg p-4 border border-gray-200">
                      <div className="flex items-start justify-between mb-2">
                        <p className="font-medium text-gray-800">{piece.label}</p>
                        <span className="px-2 py-1 bg-blue-100 text-blue-800 text-xs rounded">
                          {piece.materialType === 'glass' ? 'Vidrio' : piece.materialType === 'mirror' ? 'Espejo' : 'Aluminio'}
                        </span>
                      </div>
                      <div className="grid grid-cols-3 gap-2 text-sm">
                        <div>
                          <Ruler size={14} className="inline mr-1 text-gray-500" />
                          <span className="text-gray-600">{piece.width} × {piece.height} cm</span>
                        </div>
                        <div>
                          <Hash size={14} className="inline mr-1 text-gray-500" />
                          <span className="text-gray-600">Cantidad: {piece.quantity}</span>
                        </div>
                        <div>
                          <span className="text-gray-600">Espesor: {piece.thickness}mm</span>
                        </div>
                      </div>
                    </div>
                  ))}
                </div>
              </div>
            </div>
          )}

          {importError && (
            <div className="bg-red-50 border border-red-200 rounded-lg p-4">
              <div className="flex items-center gap-3">
                <AlertCircle className="text-red-600" size={20} />
                <p className="text-red-800">{importError}</p>
              </div>
            </div>
          )}
        </div>

        <div className="border-t p-6 flex justify-end gap-3">
          <button
            onClick={onClose}
            className="px-6 py-2 border border-gray-300 text-gray-700 rounded-lg hover:bg-gray-50 transition-colors"
          >
            Cancelar
          </button>
          {parsedOrder && (
            <button
              onClick={() => {
                setSelectedFile(null);
                setParsedOrder(null);
                setValidationErrors([]);
                setSelectedCustomerId('');
                setIsCreatingCustomer(false);
                setImportError('');
              }}
              className="px-6 py-2 border border-gray-300 text-gray-700 rounded-lg hover:bg-gray-50 transition-colors"
            >
              Cargar Otro Archivo
            </button>
          )}
          {parsedOrder && (
            <button
              onClick={handleImport}
              disabled={!canImport || isImporting}
              className="px-6 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition-colors disabled:opacity-50 disabled:cursor-not-allowed"
            >
              {isImporting ? 'Importando...' : 'Importar Pedido'}
            </button>
          )}
        </div>
      </div>
    </div>
  );
}
