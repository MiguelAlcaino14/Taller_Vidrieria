import { Cut, PlacedCut, Sheet, CutLine, CutInstruction, PackingResult } from '../../types';
import { packMaxRects, MaxRectsFitRule } from './maxrects';
import { packSkyline, SkylineFitRule } from './skyline';
import { packGuillotine, GuillotineSplitRule, GuillotineFitRule } from './guillotine';

interface Pattern {
  rows: number;
  cols: number;
  pieceWidth: number;
  pieceHeight: number;
  rotated: boolean;
  totalPieces: number;
  utilization: number;
}

interface RemainingSpace {
  x: number;
  y: number;
  width: number;
  height: number;
}

export function packPatternGuillotine(cuts: Cut[], sheet: Sheet): PackingResult {
  const allPatterns: PackingResult[] = [];

  for (const cut of cuts) {
    if (cut.quantity === 0) continue;

    const patterns = explorePatternsForCut(cut, sheet);

    for (const pattern of patterns) {
      const result = generateHybridPackingFromPattern(pattern, cut, cuts, sheet);
      if (result.placedCuts.length > 0) {
        allPatterns.push(result);
      }
    }
  }

  if (allPatterns.length === 0) {
    return {
      placedCuts: [],
      cutLines: [],
      cutInstructions: [],
      utilization: 0,
      method: 'hybrid-pattern'
    };
  }

  allPatterns.sort((a, b) => {
    const utilDiff = b.utilization - a.utilization;
    if (Math.abs(utilDiff) > 0.01) return utilDiff;
    return b.placedCuts.length - a.placedCuts.length;
  });

  return allPatterns[0];
}

function explorePatternsForCut(cut: Cut, sheet: Sheet): Pattern[] {
  const patterns: Pattern[] = [];
  const cutThickness = sheet.cutThickness;

  for (const rotated of [false, true]) {
    const pieceWidth = rotated ? cut.height : cut.width;
    const pieceHeight = rotated ? cut.width : cut.height;

    if (pieceWidth > sheet.width || pieceHeight > sheet.height) {
      continue;
    }

    const maxCols = Math.floor((sheet.width + cutThickness) / (pieceWidth + cutThickness));
    const maxRows = Math.floor((sheet.height + cutThickness) / (pieceHeight + cutThickness));

    if (maxCols <= 0 || maxRows <= 0) continue;

    const totalPieces = maxCols * maxRows;
    const piecesToPlace = Math.min(totalPieces, cut.quantity);

    const usedWidth = maxCols * pieceWidth + (maxCols - 1) * cutThickness;
    const usedHeight = maxRows * pieceHeight + (maxRows - 1) * cutThickness;
    const usedArea = piecesToPlace * pieceWidth * pieceHeight;
    const totalArea = sheet.width * sheet.height;
    const utilization = (usedArea / totalArea) * 100;

    patterns.push({
      rows: maxRows,
      cols: maxCols,
      pieceWidth,
      pieceHeight,
      rotated,
      totalPieces: piecesToPlace,
      utilization
    });

    for (let cols = 1; cols <= maxCols; cols++) {
      for (let rows = 1; rows <= maxRows; rows++) {
        const pieces = cols * rows;
        if (pieces >= cut.quantity || pieces > totalPieces) continue;

        const width = cols * pieceWidth + (cols - 1) * cutThickness;
        const height = rows * pieceHeight + (rows - 1) * cutThickness;

        if (width <= sheet.width && height <= sheet.height) {
          const area = pieces * pieceWidth * pieceHeight;
          const util = (area / totalArea) * 100;

          patterns.push({
            rows,
            cols,
            pieceWidth,
            pieceHeight,
            rotated,
            totalPieces: pieces,
            utilization: util
          });
        }
      }
    }
  }

  return patterns;
}

function generateHybridPackingFromPattern(
  pattern: Pattern,
  cut: Cut,
  allCuts: Cut[],
  sheet: Sheet
): PackingResult {
  const placedCuts: PlacedCut[] = [];
  const cutLines: CutLine[] = [];
  let cutLineId = 0;

  const { rows, cols, pieceWidth, pieceHeight, rotated } = pattern;
  const cutThickness = sheet.cutThickness;

  let piecesPlaced = 0;
  const maxPieces = Math.min(pattern.totalPieces, cut.quantity);

  for (let row = 0; row < rows && piecesPlaced < maxPieces; row++) {
    for (let col = 0; col < cols && piecesPlaced < maxPieces; col++) {
      const x = col * (pieceWidth + cutThickness);
      const y = row * (pieceHeight + cutThickness);

      placedCuts.push({
        cut: {
          ...cut,
          id: `${cut.id}_pattern_${piecesPlaced}`,
          quantity: 1
        },
        x,
        y,
        width: pieceWidth,
        height: pieceHeight,
        rotated,
        isPattern: true
      });

      piecesPlaced++;
    }
  }

  if (cols > 1) {
    for (let col = 1; col < cols; col++) {
      const position = col * pieceWidth + (col - 1) * cutThickness + cutThickness / 2;
      const actualRows = Math.min(rows, Math.ceil(maxPieces / cols));
      const lineHeight = actualRows * pieceHeight + (actualRows - 1) * cutThickness;

      cutLines.push({
        id: `cut_${cutLineId++}`,
        type: 'vertical',
        position,
        start: 0,
        end: lineHeight,
        order: col
      });
    }
  }

  if (rows > 1) {
    for (let strip = 0; strip < Math.min(cols, Math.ceil(maxPieces / cols)); strip++) {
      const stripX = strip * (pieceWidth + cutThickness);
      const piecesInStrip = Math.min(rows, maxPieces - strip * rows);

      for (let row = 1; row < piecesInStrip; row++) {
        const position = row * pieceHeight + (row - 1) * cutThickness + cutThickness / 2;

        cutLines.push({
          id: `cut_${cutLineId++}`,
          type: 'horizontal',
          position,
          start: stripX,
          end: stripX + pieceWidth,
          order: cols + row
        });
      }
    }
  }

  const patternWidth = cols * pieceWidth + (cols - 1) * cutThickness;
  const patternHeight = rows * pieceHeight + (rows - 1) * cutThickness;

  const remainingSpaces: RemainingSpace[] = [];

  if (patternWidth < sheet.width) {
    remainingSpaces.push({
      x: patternWidth + cutThickness,
      y: 0,
      width: sheet.width - patternWidth - cutThickness,
      height: sheet.height
    });
  }

  if (patternHeight < sheet.height) {
    remainingSpaces.push({
      x: 0,
      y: patternHeight + cutThickness,
      width: patternWidth,
      height: sheet.height - patternHeight - cutThickness
    });
  }

  const remainingCuts = allCuts.filter(c => c.id !== cut.id || piecesPlaced < c.quantity);
  const updatedCuts = remainingCuts.map(c => {
    if (c.id === cut.id) {
      return { ...c, quantity: c.quantity - piecesPlaced };
    }
    return c;
  }).filter(c => c.quantity > 0);

  for (const space of remainingSpaces) {
    if (space.width < 5 || space.height < 5) continue;

    const spaceSheet: Sheet = {
      ...sheet,
      width: space.width,
      height: space.height
    };

    const optimizedInSpace = optimizeInSpace(updatedCuts, spaceSheet);

    for (const pc of optimizedInSpace) {
      placedCuts.push({
        ...pc,
        x: pc.x + space.x,
        y: pc.y + space.y,
        isPattern: false
      });
    }
  }

  const usedArea = placedCuts.reduce((sum, pc) => sum + (pc.width * pc.height), 0);
  const totalArea = sheet.width * sheet.height;
  const utilization = (usedArea / totalArea) * 100;

  return {
    placedCuts,
    cutLines,
    cutInstructions: [],
    utilization,
    method: 'hybrid-pattern'
  };
}

function optimizeInSpace(cuts: Cut[], sheet: Sheet): PlacedCut[] {
  const expandedCuts: Array<Cut & { originalId: string }> = [];

  cuts.forEach(cut => {
    for (let i = 0; i < cut.quantity; i++) {
      expandedCuts.push({
        ...cut,
        id: `${cut.id}_opt_${i}`,
        originalId: cut.id,
        quantity: 1
      });
    }
  });

  const strategies: PlacedCut[][] = [];

  try {
    strategies.push(packMaxRects(expandedCuts, sheet, MaxRectsFitRule.BestShortSideFit));
  } catch (e) {}

  try {
    strategies.push(packMaxRects(expandedCuts, sheet, MaxRectsFitRule.BestAreaFit));
  } catch (e) {}

  try {
    strategies.push(packSkyline(expandedCuts, sheet, SkylineFitRule.MinWasteFit));
  } catch (e) {}

  try {
    strategies.push(packGuillotine(expandedCuts, sheet, GuillotineSplitRule.MinimizeArea, GuillotineFitRule.BestAreaFit));
  } catch (e) {}

  if (strategies.length === 0) {
    return [];
  }

  strategies.sort((a, b) => {
    const areaA = a.reduce((sum, pc) => sum + (pc.width * pc.height), 0);
    const areaB = b.reduce((sum, pc) => sum + (pc.width * pc.height), 0);
    return areaB - areaA;
  });

  return strategies[0];
}
