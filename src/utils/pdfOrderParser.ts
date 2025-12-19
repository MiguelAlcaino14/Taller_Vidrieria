import { pdfjsLib } from '../lib/pdfConfig';

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

export async function parsePDFOrder(file: File): Promise<ParsedOrder | null> {
  try {
    const arrayBuffer = await file.arrayBuffer();
    const pdf = await pdfjsLib.getDocument({ data: arrayBuffer }).promise;

    let fullText = '';

    for (let i = 1; i <= pdf.numPages; i++) {
      const page = await pdf.getPage(i);
      const textContent = await page.getTextContent();
      const pageText = textContent.items
        .map((item: any) => item.str)
        .join(' ');
      fullText += pageText + '\n';
    }

    return parseOrderFromText(fullText);
  } catch (error) {
    console.error('Error parsing PDF:', error);
    return null;
  }
}

function parseOrderFromText(text: string): ParsedOrder | null {
  try {
    const orderCodeMatch = text.match(/Código:\s*(CR-[a-f0-9]+)/i);
    const orderNumberMatch = text.match(/Pedido:\s*#?([a-f0-9]+)/i);
    const dateMatch = text.match(/Fecha:\s*([^\n]+)/i);
    const customerNameMatch = text.match(/Cliente:\s*([^\n]+?)(?:\s+Teléfono:|$)/i);
    const customerPhoneMatch = text.match(/Teléfono:\s*([^\n]+)/i);

    if (!orderCodeMatch || !orderNumberMatch) {
      throw new Error('Could not extract order code or number from PDF');
    }

    const pieces = extractPiecesFromText(text);

    const totalPiecesMatch = text.match(/Total de piezas:\s*(\d+)/i);
    const totalAreaMatch = text.match(/Área total:\s*([\d.]+)\s*m/i);
    const estimatedTimeMatch = text.match(/Tiempo estimado:\s*([\d.]+)\s*horas/i);

    return {
      orderCode: orderCodeMatch[1],
      orderNumber: orderNumberMatch[1],
      date: dateMatch ? dateMatch[1].trim() : new Date().toISOString(),
      customerName: customerNameMatch ? customerNameMatch[1].trim() : '',
      customerPhone: customerPhoneMatch ? customerPhoneMatch[1].trim() : '',
      pieces,
      totalPieces: totalPiecesMatch ? parseInt(totalPiecesMatch[1]) : pieces.length,
      totalArea: totalAreaMatch ? parseFloat(totalAreaMatch[1]) : 0,
      estimatedTime: estimatedTimeMatch ? parseFloat(estimatedTimeMatch[1]) : 0
    };
  } catch (error) {
    console.error('Error parsing order text:', error);
    return null;
  }
}

function extractPiecesFromText(text: string): ParsedPiece[] {
  const pieces: ParsedPiece[] = [];

  const pieceCodeRegex = /(CR-[a-f0-9]+-\d+)/gi;
  const codeMatches = text.match(pieceCodeRegex);

  if (!codeMatches) {
    return pieces;
  }

  const uniqueCodes = [...new Set(codeMatches)];

  for (const code of uniqueCodes) {
    const codeIndex = text.indexOf(code);
    if (codeIndex === -1) continue;

    const nextCodeIndex = text.indexOf('CR-', codeIndex + code.length);
    const sectionEnd = nextCodeIndex !== -1 ? nextCodeIndex : text.length;
    const section = text.substring(codeIndex, sectionEnd);

    const labelMatch = section.match(new RegExp(`${code}\\s+([^\\d\\n]+)`, 'i'));
    const label = labelMatch ? labelMatch[1].trim() : code;

    const dimensionMatch = section.match(/(\d+(?:\.\d+)?)\s*cm\s*[×x]\s*(\d+(?:\.\d+)?)\s*cm/i);
    if (!dimensionMatch) continue;

    const width = parseFloat(dimensionMatch[1]);
    const height = parseFloat(dimensionMatch[2]);

    const thicknessMatch = section.match(/Espesor:\s*([\d.]+)/i);
    let thickness = 4;
    if (thicknessMatch) {
      thickness = parseFloat(thicknessMatch[1]);
    }

    const isMirrorMatch = section.match(/Es Espejo:\s*(SI|SÍ|NO)/i);
    const isMirror = isMirrorMatch ? (isMirrorMatch[1].toUpperCase() === 'SI' || isMirrorMatch[1].toUpperCase() === 'SÍ') : false;

    const aluminumColorMatch = section.match(/Color Aluminio:\s*([^\n]+)/i);
    let aluminumColor: string | null = aluminumColorMatch ? aluminumColorMatch[1].trim() : null;
    if (aluminumColor === 'N/A' || aluminumColor === '') {
      aluminumColor = null;
    }

    const quantityMatch = section.match(/Cantidad:\s*(\d+)/i);
    const quantity = quantityMatch ? parseInt(quantityMatch[1]) : 1;

    let materialType: 'glass' | 'mirror' | 'aluminum' = 'glass';
    if (isMirror || label.toLowerCase().includes('espejo')) {
      materialType = 'mirror';
    } else if (aluminumColor && aluminumColor !== 'N/A') {
      materialType = 'aluminum';
    }

    pieces.push({
      code,
      width,
      height,
      quantity,
      thickness,
      isMirror,
      aluminumColor,
      materialType,
      label: label || code
    });
  }

  return pieces;
}

export function validateParsedOrder(order: ParsedOrder | null): { valid: boolean; errors: string[] } {
  const errors: string[] = [];

  if (!order) {
    errors.push('No se pudo leer el archivo');
    return { valid: false, errors };
  }

  if (!order.orderCode) {
    errors.push('No se encontró el código de orden');
  }

  if (!order.customerName) {
    errors.push('No se encontró el nombre del cliente');
  }

  if (order.pieces.length === 0) {
    errors.push('No se encontraron piezas en el documento');
  }

  order.pieces.forEach((piece, index) => {
    if (piece.width <= 0 || piece.height <= 0) {
      errors.push(`Pieza ${index + 1}: Dimensiones inválidas`);
    }
    if (piece.quantity <= 0) {
      errors.push(`Pieza ${index + 1}: Cantidad inválida`);
    }
  });

  return { valid: errors.length === 0, errors };
}
