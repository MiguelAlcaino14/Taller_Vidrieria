import { X, Download, ExternalLink } from 'lucide-react';
import { PDFViewer } from './PDFViewer';

interface PDFViewerModalProps {
  pdfUrl: string;
  orderName: string;
  isOpen: boolean;
  onClose: () => void;
}

export function PDFViewerModal({ pdfUrl, orderName, isOpen, onClose }: PDFViewerModalProps) {
  if (!isOpen) return null;

  const handleDownload = () => {
    const link = document.createElement('a');
    link.href = pdfUrl;
    link.download = `${orderName}.pdf`;
    document.body.appendChild(link);
    link.click();
    document.body.removeChild(link);
  };

  const handleOpenInNewTab = () => {
    window.open(pdfUrl, '_blank');
  };

  return (
    <div className="fixed inset-0 bg-black bg-opacity-75 flex items-center justify-center z-50 p-4">
      <div className="bg-white rounded-lg shadow-xl w-full max-w-6xl h-[90vh] flex flex-col">
        <div className="flex justify-between items-center p-4 border-b bg-gray-50">
          <div>
            <h2 className="text-xl font-bold text-gray-800">Documento Original</h2>
            <p className="text-sm text-gray-600 mt-1">{orderName}</p>
          </div>

          <div className="flex items-center gap-2">
            <button
              onClick={handleDownload}
              className="flex items-center gap-2 px-3 py-2 bg-blue-600 hover:bg-blue-700 text-white rounded-lg transition-colors text-sm font-medium"
              title="Descargar PDF"
            >
              <Download size={16} />
              Descargar
            </button>

            <button
              onClick={handleOpenInNewTab}
              className="flex items-center gap-2 px-3 py-2 bg-gray-600 hover:bg-gray-700 text-white rounded-lg transition-colors text-sm font-medium"
              title="Abrir en nueva pestaña"
            >
              <ExternalLink size={16} />
              Abrir
            </button>

            <button
              onClick={onClose}
              className="p-2 hover:bg-gray-200 rounded-full transition-colors"
              title="Cerrar"
            >
              <X size={24} />
            </button>
          </div>
        </div>

        <div className="flex-1 p-4 overflow-hidden">
          <PDFViewer file={pdfUrl} className="h-full" />
        </div>
      </div>
    </div>
  );
}
