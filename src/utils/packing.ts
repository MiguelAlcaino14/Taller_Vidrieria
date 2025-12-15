import { Cut, PlacedCut, Sheet, PackingResult } from '../types';
import { getBestPacking, getBestPackingWithDetails } from './algorithms/optimizer';
import { calculateRemnants } from './remnants';

export function packCuts(cuts: Cut[], sheet: Sheet): PlacedCut[] {
  try {
    const optimizedResult = getBestPacking(cuts, sheet);

    if (optimizedResult.length > 0) {
      return optimizedResult;
    }
  } catch (error) {
    console.error('Optimization failed, falling back to basic algorithm:', error);
  }

  return packCutsBasic(cuts, sheet);
}

export function packCutsWithDetails(cuts: Cut[], sheet: Sheet): PackingResult {
  try {
    const result = getBestPackingWithDetails(cuts, sheet);

    if (result.placedCuts.length > 0) {
      const remnants = calculateRemnants(result.placedCuts, sheet);
      return {
        ...result,
        remnants
      };
    }
  } catch (error) {
    console.error('Optimization failed, falling back to basic algorithm:', error);
  }

  const basicResult = packCutsBasic(cuts, sheet);
  const remnants = calculateRemnants(basicResult, sheet);
  return {
    placedCuts: basicResult,
    utilization: calculateUtilization(basicResult, sheet),
    method: 'basic',
    remnants
  };
}

function packCutsBasic(cuts: Cut[], sheet: Sheet): PlacedCut[] {
  const placedCuts: PlacedCut[] = [];
  const expandedCuts: Array<Cut & { originalId: string }> = [];

  cuts.forEach(cut => {
    for (let i = 0; i < cut.quantity; i++) {
      expandedCuts.push({
        ...cut,
        id: `${cut.id}_${i}`,
        originalId: cut.id,
        quantity: 1
      });
    }
  });

  expandedCuts.sort((a, b) => {
    const areaA = a.width * a.height;
    const areaB = b.width * b.height;
    return areaB - areaA;
  });

  const levels: Array<{ y: number; height: number; x: number }> = [];

  for (const cut of expandedCuts) {
    let placed = false;

    for (const rotation of [false, true]) {
      if (placed) break;

      const width = rotation ? cut.height : cut.width;
      const height = rotation ? cut.width : cut.height;

      if (width > sheet.width || height > sheet.height) {
        continue;
      }

      for (let i = 0; i < levels.length; i++) {
        const level = levels[i];

        if (level.x + width <= sheet.width && level.height >= height) {
          placedCuts.push({
            cut,
            x: level.x,
            y: level.y,
            width,
            height,
            rotated: rotation
          });

          level.x += width + sheet.cutThickness;
          placed = true;
          break;
        }
      }

      if (!placed) {
        const nextY = levels.length === 0 ? 0 : Math.max(...levels.map(l => l.y + l.height)) + sheet.cutThickness;

        if (nextY + height <= sheet.height) {
          placedCuts.push({
            cut,
            x: 0,
            y: nextY,
            width,
            height,
            rotated: rotation
          });

          levels.push({
            y: nextY,
            height: height,
            x: width + sheet.cutThickness
          });

          placed = true;
        }
      }
    }

    if (!placed) {
      break;
    }
  }

  return placedCuts;
}

export function calculateUtilization(placedCuts: PlacedCut[], sheet: Sheet): number {
  const totalArea = sheet.width * sheet.height;
  const usedArea = placedCuts.reduce((sum, pc) => sum + (pc.width * pc.height), 0);
  return totalArea > 0 ? (usedArea / totalArea) * 100 : 0;
}
