import jsPDF from 'jspdf';
import { PlacedCut, Sheet, CutLine, Remnant, Order } from '../types';
import { validateCutDimensions } from './validation';

interface PDFGenerationOptions {
  sheet: Sheet;
  placedCuts: PlacedCut[];
  utilization: number;
  cutLines?: CutLine[];
  method?: string;
  remnants?: Remnant[];
  order?: Order;
  customerName?: string;
}

const COLORS = [
  { r: 59, g: 130, b: 246 },
  { r: 16, g: 185, b: 129 },
  { r: 245, g: 158, b: 11 },
  { r: 239, g: 68, b: 68 },
  { r: 139, g: 92, b: 246 },
  { r: 236, g: 72, b: 153 },
  { r: 20, g: 184, b: 166 },
  { r: 249, g: 115, b: 22 },
  { r: 99, g: 102, b: 241 },
  { r: 132, g: 204, b: 22 }
];

export function generateCuttingDiagramPDF(options: PDFGenerationOptions): void {
  const {
    sheet,
    placedCuts,
    utilization,
    cutLines = [],
    method,
    remnants = [],
    order,
    customerName
  } = options;

  const isLandscape = sheet.width > sheet.height;
  const doc = new jsPDF({
    orientation: isLandscape ? 'landscape' : 'portrait',
    unit: 'mm',
    format: 'a4'
  });

  const pageWidth = doc.internal.pageSize.getWidth();
  const pageHeight = doc.internal.pageSize.getHeight();

  const margin = 15;
  const headerHeight = 40;
  const diagramStartY = headerHeight + margin;

  const availableWidth = pageWidth - (margin * 2);
  const availableHeight = pageHeight - diagramStartY - margin - 60;

  const scale = Math.min(
    availableWidth / sheet.width,
    availableHeight / sheet.height
  );

  const diagramWidth = sheet.width * scale;
  const diagramHeight = sheet.height * scale;
  const diagramX = margin + (availableWidth - diagramWidth) / 2;
  const diagramY = diagramStartY;

  doc.setFillColor(240, 240, 240);
  doc.rect(0, 0, pageWidth, headerHeight, 'F');

  doc.setFontSize(18);
  doc.setFont('helvetica', 'bold');
  doc.text('Diagrama de Corte', margin, 12);

  doc.setFontSize(10);
  doc.setFont('helvetica', 'normal');
  let infoY = 20;

  if (order) {
    doc.text(`Pedido: ${order.order_number} - ${order.name}`, margin, infoY);
    infoY += 5;
  }

  if (customerName) {
    doc.text(`Cliente: ${customerName}`, margin, infoY);
    infoY += 5;
  }

  const currentDate = new Date().toLocaleDateString('es-ES', {
    year: 'numeric',
    month: 'long',
    day: 'numeric'
  });
  doc.text(`Fecha: ${currentDate}`, margin, infoY);

  doc.setFontSize(9);
  const methodText = sheet.cuttingMethod === 'manual' ? 'Manual (Toyo)' : 'Máquina Automática';
  doc.text(`Método: ${methodText} • Grosor: ${sheet.glassThickness}mm`, pageWidth - margin, 12, { align: 'right' });

  doc.setDrawColor(100, 100, 100);
  doc.setLineWidth(0.5);
  doc.rect(diagramX, diagramY, diagramWidth, diagramHeight);

  doc.setFontSize(8);
  doc.setFont('helvetica', 'bold');
  doc.text(`${sheet.width} cm`, diagramX + diagramWidth / 2, diagramY - 3, { align: 'center' });
  doc.text(`${sheet.height} cm`, diagramX - 3, diagramY + diagramHeight / 2, {
    angle: 90,
    align: 'center'
  });

  const colorMap = new Map<string, typeof COLORS[0]>();
  let colorIndex = 0;

  placedCuts.forEach((pc) => {
    const originalId = pc.cut.id.split('_')[0];
    if (!colorMap.has(originalId)) {
      colorMap.set(originalId, COLORS[colorIndex % COLORS.length]);
      colorIndex++;
    }
    const color = colorMap.get(originalId)!;

    const validation = validateCutDimensions(pc.cut, sheet);

    const x = diagramX + pc.x * scale;
    const y = diagramY + pc.y * scale;
    const width = pc.width * scale;
    const height = pc.height * scale;

    doc.setFillColor(color.r, color.g, color.b);
    doc.setDrawColor(color.r, color.g, color.b);

    const opacity = pc.isPattern === false ? 0.3 : 0.5;
    doc.setGState(new doc.GState({ opacity: opacity }));
    doc.rect(x, y, width, height, 'F');
    doc.setGState(new doc.GState({ opacity: 1 }));

    if (validation.status === 'danger') {
      doc.setDrawColor(220, 38, 38);
      doc.setLineWidth(0.8);
    } else if (validation.status === 'warning') {
      doc.setDrawColor(245, 158, 11);
      doc.setLineWidth(0.6);
    } else {
      doc.setLineWidth(0.4);
    }

    if (pc.isPattern === false) {
      doc.setLineDash([1, 1], 0);
    }

    doc.rect(x, y, width, height);
    doc.setLineDash([], 0);

    if (validation.status !== 'safe') {
      const indicatorColor = validation.status === 'danger' ? [220, 38, 38] : [245, 158, 11];
      doc.setFillColor(indicatorColor[0], indicatorColor[1], indicatorColor[2]);
      doc.circle(x + width - 2, y + 2, 1.5, 'F');
    }

    doc.setFontSize(7);
    doc.setFont('helvetica', 'bold');
    doc.setTextColor(255, 255, 255);

    const labelY = y + height / 2 - 1;
    doc.text(pc.cut.label, x + width / 2, labelY, { align: 'center' });

    const dimensionsText = `${pc.width.toFixed(1)} × ${pc.height.toFixed(1)}`;
    doc.setFont('helvetica', 'normal');
    doc.text(dimensionsText, x + width / 2, labelY + 3, { align: 'center' });

    if (pc.rotated) {
      doc.setFont('helvetica', 'italic');
      doc.setFontSize(6);
      doc.text('(rotado)', x + width / 2, labelY + 6, { align: 'center' });
    }

    doc.setTextColor(0, 0, 0);
  });

  cutLines.forEach((cutLine) => {
    const x1 = cutLine.type === 'vertical'
      ? diagramX + cutLine.position * scale
      : diagramX + cutLine.start * scale;
    const y1 = cutLine.type === 'horizontal'
      ? diagramY + cutLine.position * scale
      : diagramY + cutLine.start * scale;
    const x2 = cutLine.type === 'vertical'
      ? diagramX + cutLine.position * scale
      : diagramX + cutLine.end * scale;
    const y2 = cutLine.type === 'horizontal'
      ? diagramY + cutLine.position * scale
      : diagramY + cutLine.end * scale;

    doc.setDrawColor(cutLine.type === 'vertical' ? 220 : 37, cutLine.type === 'vertical' ? 38 : 99, cutLine.type === 'vertical' ? 38 : 235);
    doc.setLineWidth(0.4);
    doc.setLineDash([2, 2], 0);
    doc.line(x1, y1, x2, y2);
    doc.setLineDash([], 0);

    const circleX = cutLine.type === 'vertical' ? x1 : (x1 + x2) / 2;
    const circleY = cutLine.type === 'horizontal' ? y1 : (y1 + y2) / 2;

    doc.setFillColor(cutLine.type === 'vertical' ? 220 : 37, cutLine.type === 'vertical' ? 38 : 99, cutLine.type === 'vertical' ? 38 : 235);
    doc.circle(circleX, circleY, 2.5, 'F');

    doc.setFontSize(7);
    doc.setFont('helvetica', 'bold');
    doc.setTextColor(255, 255, 255);
    doc.text(cutLine.order.toString(), circleX, circleY + 1, { align: 'center' });
    doc.setTextColor(0, 0, 0);
  });

  const statsY = diagramY + diagramHeight + 10;
  const totalCuts = placedCuts.length;
  const totalArea = sheet.width * sheet.height;
  const usedArea = placedCuts.reduce((sum, pc) => sum + (pc.width * pc.height), 0);
  const wasteArea = totalArea - usedArea;

  doc.setFillColor(245, 245, 245);
  doc.roundedRect(margin, statsY, availableWidth, 25, 2, 2, 'F');

  doc.setFontSize(9);
  doc.setFont('helvetica', 'bold');
  doc.text('Estadísticas:', margin + 3, statsY + 6);

  const col1X = margin + 5;
  const col2X = margin + availableWidth / 3;
  const col3X = margin + (2 * availableWidth / 3);

  doc.setFont('helvetica', 'normal');
  doc.setFontSize(8);

  doc.text('Aprovechamiento:', col1X, statsY + 12);
  doc.setFont('helvetica', 'bold');
  doc.setTextColor(22, 163, 74);
  doc.text(`${utilization.toFixed(1)}%`, col1X, statsY + 17);

  doc.setTextColor(0, 0, 0);
  doc.setFont('helvetica', 'normal');
  doc.text('Cortes Colocados:', col2X, statsY + 12);
  doc.setFont('helvetica', 'bold');
  doc.setTextColor(37, 99, 235);
  doc.text(`${totalCuts}`, col2X, statsY + 17);

  doc.setTextColor(0, 0, 0);
  doc.setFont('helvetica', 'normal');
  doc.text('Desperdicio:', col3X, statsY + 12);
  doc.setFont('helvetica', 'bold');
  doc.setTextColor(220, 38, 38);
  doc.text(`${wasteArea.toFixed(0)} cm²`, col3X, statsY + 17);

  doc.setTextColor(0, 0, 0);

  const detailsY = statsY + 30;
  doc.setFont('helvetica', 'bold');
  doc.setFontSize(9);
  doc.text('Detalles:', margin, detailsY);

  doc.setFont('helvetica', 'normal');
  doc.setFontSize(8);
  let detailY = detailsY + 5;

  const details = [
    { label: 'Tamaño de plancha:', value: `${sheet.width} × ${sheet.height} cm` },
    { label: 'Área total:', value: `${totalArea.toFixed(0)} cm²` },
    { label: 'Área utilizada:', value: `${usedArea.toFixed(0)} cm²` },
    { label: 'Grosor del vidrio:', value: `${sheet.glassThickness}mm` },
    { label: 'Método de corte:', value: methodText }
  ];

  if (sheet.cuttingMethod === 'machine') {
    details.splice(4, 0, { label: 'Grosor de corte:', value: `${sheet.cutThickness} cm` });
  }

  if (method) {
    details.push({ label: 'Algoritmo:', value: method });
  }

  details.forEach((detail) => {
    doc.text(detail.label, margin + 5, detailY);
    doc.text(detail.value, margin + 60, detailY);
    detailY += 4;
  });

  if (remnants.length > 0) {
    const remnantsY = detailY + 3;
    doc.setFont('helvetica', 'bold');
    doc.setFontSize(9);
    doc.text('Material Sobrante Aprovechable:', margin, remnantsY);

    doc.setFont('helvetica', 'normal');
    doc.setFontSize(8);
    let remY = remnantsY + 5;

    doc.setFillColor(220, 252, 231);
    doc.roundedRect(margin + 5, remY - 2, 80, 8, 1, 1, 'F');

    doc.setFont('helvetica', 'bold');
    doc.setTextColor(21, 128, 61);
    doc.text(`Mejor: ${remnants[0].width.toFixed(1)} × ${remnants[0].height.toFixed(1)} cm`, margin + 7, remY + 2);
    doc.text(`(${remnants[0].area.toFixed(0)} cm²)`, margin + 7, remY + 6);
    doc.setTextColor(0, 0, 0);
    doc.setFont('helvetica', 'normal');

    if (remnants.length > 1) {
      remY += 11;
      doc.setFontSize(7);
      const remnantsToShow = remnants.slice(1, 4);
      remnantsToShow.forEach((remnant, index) => {
        doc.text(`• ${remnant.width.toFixed(1)} × ${remnant.height.toFixed(1)} cm (${remnant.area.toFixed(0)} cm²)`, margin + 7, remY);
        remY += 3.5;
      });

      if (remnants.length > 4) {
        doc.setFontSize(6);
        doc.setTextColor(100, 100, 100);
        doc.text(`+${remnants.length - 4} retales más pequeños`, margin + 7, remY);
        doc.setTextColor(0, 0, 0);
      }
    }
  }

  const legendY = pageHeight - 15;
  doc.setFontSize(7);
  doc.setFont('helvetica', 'normal');

  let legendX = margin;

  doc.setDrawColor(22, 163, 74);
  doc.setLineWidth(0.6);
  doc.rect(legendX, legendY - 2, 3, 3);
  doc.text('Seguro', legendX + 5, legendY);
  legendX += 20;

  doc.setDrawColor(245, 158, 11);
  doc.rect(legendX, legendY - 2, 3, 3);
  doc.text('Precaución', legendX + 5, legendY);
  legendX += 25;

  doc.setDrawColor(220, 38, 38);
  doc.rect(legendX, legendY - 2, 3, 3);
  doc.text('Peligroso', legendX + 5, legendY);
  legendX += 25;

  if (cutLines.length > 0) {
    doc.setDrawColor(37, 99, 235);
    doc.setLineWidth(0.6);
    doc.line(legendX, legendY - 0.5, legendX + 3, legendY - 0.5);
    doc.text('Corte H', legendX + 5, legendY);
    legendX += 20;

    doc.setDrawColor(220, 38, 38);
    doc.line(legendX, legendY - 2, legendX, legendY + 1);
    doc.text('Corte V', legendX + 3, legendY);
  }

  const fileName = order
    ? `diagrama-corte-${order.order_number}.pdf`
    : `diagrama-corte-${new Date().getTime()}.pdf`;

  doc.save(fileName);
}
