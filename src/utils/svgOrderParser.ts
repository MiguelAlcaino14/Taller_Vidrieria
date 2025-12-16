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

export function parseSVGOrder(svgContent: string): ParsedOrder | null {
  try {
    const parser = new DOMParser();
    const doc = parser.parseFromString(svgContent, 'image/svg+xml');

    const parserError = doc.querySelector('parsererror');
    if (parserError) {
      throw new Error('Invalid SVG file');
    }

    const textElements = Array.from(doc.querySelectorAll('text'));

    const orderCode = extractPattern(textElements, /Código:\s*<tspan[^>]*>(CR-[a-f0-9]+)<\/tspan>/i);
    const orderNumber = extractPattern(textElements, /Pedido:\s*<tspan[^>]*>(#[a-f0-9]+)<\/tspan>/i);
    const dateText = extractPattern(textElements, /Fecha:\s*<tspan[^>]*>([^<]+)<\/tspan>/i);
    const customerName = extractPattern(textElements, /Cliente:\s*<tspan[^>]*>([^<]+)<\/tspan>/i);
    const customerPhone = extractPattern(textElements, /Teléfono:\s*<tspan[^>]*>([^<]+)<\/tspan>/i);

    if (!orderCode || !orderNumber) {
      throw new Error('Could not extract order code or number');
    }

    const pieces = extractPieces(doc);

    const totalPieces = extractFromSummary(textElements, /Total de piezas:\s*<tspan[^>]*>(\d+)<\/tspan>/i);
    const totalArea = extractFromSummary(textElements, /Área total:\s*<tspan[^>]*>([\d.]+)\s*m²<\/tspan>/i);
    const estimatedTime = extractFromSummary(textElements, /Tiempo estimado:\s*<tspan[^>]*>([\d.]+)\s*horas<\/tspan>/i);

    return {
      orderCode: orderCode || '',
      orderNumber: orderNumber?.replace('#', '') || '',
      date: dateText || new Date().toISOString(),
      customerName: customerName || '',
      customerPhone: customerPhone || '',
      pieces,
      totalPieces: totalPieces || pieces.length,
      totalArea: totalArea || 0,
      estimatedTime: estimatedTime || 0
    };
  } catch (error) {
    console.error('Error parsing SVG:', error);
    return null;
  }
}

function extractPattern(elements: Element[], pattern: RegExp): string | null {
  for (const element of elements) {
    const match = element.innerHTML.match(pattern);
    if (match) {
      return match[1];
    }
  }
  return null;
}

function extractFromSummary(elements: Element[], pattern: RegExp): number | null {
  const match = extractPattern(elements, pattern);
  return match ? parseFloat(match) : null;
}

function extractPieces(doc: Document): ParsedPiece[] {
  const pieces: ParsedPiece[] = [];
  const pieceGroups = doc.querySelectorAll('g[id^="piece-"]');

  pieceGroups.forEach((group) => {
    try {
      const textElements = Array.from(group.querySelectorAll('text'));
      const allText = textElements.map(el => el.textContent || '').join('\n');

      const pieceCode = extractTextValue(textElements, /^(CR-[a-f0-9]+-\d+)$/i);

      const dimensionMatch = allText.match(/(\d+(?:\.\d+)?)\s*cm\s*[×x]\s*(\d+(?:\.\d+)?)\s*cm/i);
      const width = dimensionMatch ? parseFloat(dimensionMatch[1]) : 0;
      const height = dimensionMatch ? parseFloat(dimensionMatch[2]) : 0;

      const quantityMatch = allText.match(/Cantidad:\s*.*?(\d+)/s);
      const quantity = quantityMatch ? parseInt(quantityMatch[1]) : 1;

      const thicknessMatch = allText.match(/Espesor:\s*([\d.]+)\s*mm/i);
      const thickness = thicknessMatch ? parseFloat(thicknessMatch[1]) : 4;

      const isMirrorMatch = allText.match(/Es Espejo:\s*(SI|NO)/i);
      const isMirror = isMirrorMatch ? isMirrorMatch[1].toUpperCase() === 'SI' : false;

      const aluminumColorMatch = allText.match(/Color Aluminio:\s*([^\n]+)/i);
      let aluminumColor = aluminumColorMatch ? aluminumColorMatch[1].trim() : null;
      if (aluminumColor === 'N/A' || aluminumColor === '') {
        aluminumColor = null;
      }

      const materialBadges = Array.from(group.querySelectorAll('rect[fill*="#3b82f6"]'))
        .map(rect => {
          const nextText = rect.nextElementSibling;
          return nextText?.textContent?.trim() || '';
        });

      let materialType: 'glass' | 'mirror' | 'aluminum' = 'glass';
      const materialText = materialBadges.join(' ').toUpperCase();
      if (materialText.includes('ESPEJO')) {
        materialType = 'mirror';
      } else if (materialText.includes('ALUMINIO')) {
        materialType = 'aluminum';
      }

      if (width > 0 && height > 0 && pieceCode) {
        pieces.push({
          code: pieceCode,
          width,
          height,
          quantity,
          thickness,
          isMirror,
          aluminumColor,
          materialType,
          label: pieceCode
        });
      }
    } catch (error) {
      console.error('Error parsing piece:', error);
    }
  });

  return pieces;
}

function extractTextValue(elements: Element[], pattern: RegExp): string | null {
  for (const element of elements) {
    const text = element.textContent?.trim() || '';
    const match = text.match(pattern);
    if (match) {
      return match[1] || match[0];
    }
  }
  return null;
}

export function validateParsedOrder(order: ParsedOrder | null): { valid: boolean; errors: string[] } {
  const errors: string[] = [];

  if (!order) {
    errors.push('No se pudo leer el archivo SVG');
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
    if (piece.thickness <= 0) {
      errors.push(`Pieza ${index + 1}: Espesor inválido`);
    }
  });

  return { valid: errors.length === 0, errors };
}
