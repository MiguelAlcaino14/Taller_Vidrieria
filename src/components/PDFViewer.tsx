import { useState, useEffect, useRef } from 'react';
import { ChevronLeft, ChevronRight, Loader2 } from 'lucide-react';
import * as pdfjsLib from 'pdfjs-dist';

pdfjsLib.GlobalWorkerOptions.workerSrc = `//cdnjs.cloudflare.com/ajax/libs/pdf.js/${pdfjsLib.version}/pdf.worker.min.js`;

interface PDFViewerProps {
  file: File | string;
  className?: string;
}

export function PDFViewer({ file, className = '' }: PDFViewerProps) {
  const [numPages, setNumPages] = useState<number>(0);
  const [currentPage, setCurrentPage] = useState<number>(1);
  const [loading, setLoading] = useState<boolean>(true);
  const [error, setError] = useState<string | null>(null);
  const canvasRef = useRef<HTMLCanvasElement>(null);
  const [pdfDoc, setPdfDoc] = useState<pdfjsLib.PDFDocumentProxy | null>(null);

  useEffect(() => {
    loadPDF();
  }, [file]);

  useEffect(() => {
    if (pdfDoc && currentPage) {
      renderPage(currentPage);
    }
  }, [pdfDoc, currentPage]);

  const loadPDF = async () => {
    try {
      setLoading(true);
      setError(null);

      let pdfData: string | ArrayBuffer;

      if (typeof file === 'string') {
        pdfData = file;
      } else {
        pdfData = await file.arrayBuffer();
      }

      const loadingTask = pdfjsLib.getDocument(pdfData);
      const pdf = await loadingTask.promise;

      setPdfDoc(pdf);
      setNumPages(pdf.numPages);
      setCurrentPage(1);
      setLoading(false);
    } catch (err) {
      console.error('Error loading PDF:', err);
      setError('Error al cargar el PDF. Verifica que el archivo sea válido.');
      setLoading(false);
    }
  };

  const renderPage = async (pageNum: number) => {
    if (!pdfDoc || !canvasRef.current) return;

    try {
      const page = await pdfDoc.getPage(pageNum);
      const canvas = canvasRef.current;
      const context = canvas.getContext('2d');

      if (!context) return;

      const viewport = page.getViewport({ scale: 1.5 });

      canvas.height = viewport.height;
      canvas.width = viewport.width;

      const renderContext = {
        canvasContext: context,
        viewport: viewport,
      };

      await page.render(renderContext).promise;
    } catch (err) {
      console.error('Error rendering page:', err);
      setError('Error al renderizar la página del PDF.');
    }
  };

  const goToPreviousPage = () => {
    if (currentPage > 1) {
      setCurrentPage(currentPage - 1);
    }
  };

  const goToNextPage = () => {
    if (currentPage < numPages) {
      setCurrentPage(currentPage + 1);
    }
  };

  if (loading) {
    return (
      <div className={`flex flex-col items-center justify-center h-full bg-gray-50 rounded-lg ${className}`}>
        <Loader2 className="animate-spin text-blue-600 mb-2" size={32} />
        <p className="text-sm text-gray-600">Cargando PDF...</p>
      </div>
    );
  }

  if (error) {
    return (
      <div className={`flex flex-col items-center justify-center h-full bg-red-50 rounded-lg p-4 ${className}`}>
        <p className="text-sm text-red-600 text-center">{error}</p>
      </div>
    );
  }

  return (
    <div className={`flex flex-col h-full ${className}`}>
      <div className="flex-1 overflow-auto bg-gray-100 rounded-lg p-4 flex items-center justify-center">
        <canvas ref={canvasRef} className="max-w-full h-auto shadow-lg" />
      </div>

      {numPages > 1 && (
        <div className="flex items-center justify-between mt-4 px-2">
          <button
            onClick={goToPreviousPage}
            disabled={currentPage === 1}
            className="p-2 rounded-lg hover:bg-gray-100 disabled:opacity-50 disabled:cursor-not-allowed transition-colors"
            title="Página anterior"
          >
            <ChevronLeft size={20} />
          </button>

          <span className="text-sm text-gray-700 font-medium">
            Página {currentPage} de {numPages}
          </span>

          <button
            onClick={goToNextPage}
            disabled={currentPage === numPages}
            className="p-2 rounded-lg hover:bg-gray-100 disabled:opacity-50 disabled:cursor-not-allowed transition-colors"
            title="Página siguiente"
          >
            <ChevronRight size={20} />
          </button>
        </div>
      )}
    </div>
  );
}
