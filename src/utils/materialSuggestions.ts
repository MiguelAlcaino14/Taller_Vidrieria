import { MaterialSheet, Cut, PlacedCut, OptimizationSuggestion, SheetWithCuts } from '../types';
import { getBestPackingWithDetails } from './algorithms/optimizer';

export interface MaterialSuggestionOptions {
  cuts: Cut[];
  availableSheets: MaterialSheet[];
  materialType: string;
  thickness: number;
  cutThickness: number;
  cuttingMethod: 'manual' | 'machine';
  maxSuggestions?: number;
}

export interface SuggestionResult {
  suggestions: OptimizationSuggestion[];
  bestSuggestion: OptimizationSuggestion | null;
}

export async function generateMaterialSuggestions(
  options: MaterialSuggestionOptions
): Promise<SuggestionResult> {
  const {
    cuts,
    availableSheets,
    materialType,
    thickness,
    cutThickness,
    cuttingMethod,
    maxSuggestions = 5
  } = options;

  const filteredSheets = availableSheets.filter(
    sheet =>
      sheet.status === 'available' &&
      sheet.material_type === materialType &&
      Math.abs(sheet.thickness - thickness) < 0.5
  );

  if (filteredSheets.length === 0) {
    return { suggestions: [], bestSuggestion: null };
  }

  const remnants = filteredSheets.filter(s => s.origin === 'remnant');
  const fullSheets = filteredSheets.filter(s => s.origin === 'purchase');

  const suggestions: OptimizationSuggestion[] = [];
  let suggestionNumber = 1;

  const tryStrategy1 = await tryRemnantsOnly(
    cuts,
    remnants,
    cutThickness,
    cuttingMethod,
    suggestionNumber
  );
  if (tryStrategy1) {
    suggestions.push(tryStrategy1);
    suggestionNumber++;
  }

  const tryStrategy2 = await tryFullSheetOnly(
    cuts,
    fullSheets,
    cutThickness,
    cuttingMethod,
    suggestionNumber
  );
  if (tryStrategy2) {
    suggestions.push(tryStrategy2);
    suggestionNumber++;
  }

  const tryStrategy3 = await tryRemnantsAndFullSheet(
    cuts,
    remnants,
    fullSheets,
    cutThickness,
    cuttingMethod,
    suggestionNumber
  );
  if (tryStrategy3) {
    suggestions.push(tryStrategy3);
    suggestionNumber++;
  }

  const tryStrategy4 = await tryMultipleFullSheets(
    cuts,
    fullSheets,
    cutThickness,
    cuttingMethod,
    suggestionNumber
  );
  if (tryStrategy4) {
    suggestions.push(tryStrategy4);
    suggestionNumber++;
  }

  suggestions.sort((a, b) => {
    if (a.uses_remnants !== b.uses_remnants) {
      return a.uses_remnants ? -1 : 1;
    }

    if (Math.abs(a.total_utilization - b.total_utilization) > 5) {
      return b.total_utilization - a.total_utilization;
    }

    return a.total_cost - b.total_cost;
  });

  const limitedSuggestions = suggestions.slice(0, maxSuggestions);

  return {
    suggestions: limitedSuggestions,
    bestSuggestion: limitedSuggestions[0] || null
  };
}

async function tryRemnantsOnly(
  cuts: Cut[],
  remnants: MaterialSheet[],
  cutThickness: number,
  cuttingMethod: 'manual' | 'machine',
  suggestionNumber: number
): Promise<OptimizationSuggestion | null> {
  if (remnants.length === 0) return null;

  const sortedRemnants = [...remnants].sort((a, b) => b.area_total - a.area_total);

  const sheetsUsed: SheetWithCuts[] = [];
  const remainingCuts = [...cuts];

  for (const remnant of sortedRemnants) {
    if (remainingCuts.length === 0) break;

    const result = getBestPackingWithDetails(
      remainingCuts,
      {
        width: remnant.width,
        height: remnant.height,
        cutThickness,
        glassThickness: remnant.thickness,
        cuttingMethod
      }
    );

    if (result.placedCuts.length > 0) {
      sheetsUsed.push({
        sheet_id: remnant.id,
        sheet: remnant,
        cuts: result.placedCuts,
        utilization: result.utilization,
        waste_area: remnant.area_total * (1 - result.utilization / 100)
      });

      const placedCutIds = new Set(result.placedCuts.map(pc => pc.cut.id));
      remainingCuts.splice(0, remainingCuts.length,
        ...remainingCuts.filter(c => !placedCutIds.has(c.id))
      );
    }
  }

  if (remainingCuts.length > 0) {
    return null;
  }

  const totalWaste = sheetsUsed.reduce((sum, s) => sum + s.waste_area, 0);
  const totalArea = sheetsUsed.reduce((sum, s) => sum + s.sheet.area_total, 0);
  const totalCost = sheetsUsed.reduce((sum, s) => sum + (s.sheet.purchase_cost || 0), 0);
  const totalUtilization = totalArea > 0 ? ((totalArea - totalWaste) / totalArea) * 100 : 0;

  return {
    id: crypto.randomUUID(),
    order_id: '',
    suggestion_number: suggestionNumber,
    sheets_used: sheetsUsed.map(s => s.sheet_id),
    sheet_details: sheetsUsed,
    total_utilization: totalUtilization,
    total_waste: totalWaste,
    estimated_remnants: [],
    total_cost: totalCost,
    uses_remnants: true,
    created_at: new Date().toISOString()
  };
}

async function tryFullSheetOnly(
  cuts: Cut[],
  fullSheets: MaterialSheet[],
  cutThickness: number,
  cuttingMethod: 'manual' | 'machine',
  suggestionNumber: number
): Promise<OptimizationSuggestion | null> {
  if (fullSheets.length === 0) return null;

  const bestSheet = fullSheets.reduce((best, sheet) => {
    return sheet.area_total < best.area_total ? sheet : best;
  });

  const result = getBestPackingWithDetails(
    cuts,
    {
      width: bestSheet.width,
      height: bestSheet.height,
      cutThickness,
      glassThickness: bestSheet.thickness,
      cuttingMethod
    }
  );

  if (result.placedCuts.length !== cuts.length) {
    return null;
  }

  const wasteArea = bestSheet.area_total * (1 - result.utilization / 100);

  return {
    id: crypto.randomUUID(),
    order_id: '',
    suggestion_number: suggestionNumber,
    sheets_used: [bestSheet.id],
    sheet_details: [{
      sheet_id: bestSheet.id,
      sheet: bestSheet,
      cuts: result.placedCuts,
      utilization: result.utilization,
      waste_area: wasteArea
    }],
    total_utilization: result.utilization,
    total_waste: wasteArea,
    estimated_remnants: result.remnants || [],
    total_cost: bestSheet.purchase_cost || 0,
    uses_remnants: false,
    created_at: new Date().toISOString()
  };
}

async function tryRemnantsAndFullSheet(
  cuts: Cut[],
  remnants: MaterialSheet[],
  fullSheets: MaterialSheet[],
  cutThickness: number,
  cuttingMethod: 'manual' | 'machine',
  suggestionNumber: number
): Promise<OptimizationSuggestion | null> {
  if (remnants.length === 0 || fullSheets.length === 0) return null;

  const sortedRemnants = [...remnants].sort((a, b) => b.area_total - a.area_total);

  const sheetsUsed: SheetWithCuts[] = [];
  let remainingCuts = [...cuts];

  for (const remnant of sortedRemnants) {
    if (remainingCuts.length === 0) break;

    const result = getBestPackingWithDetails(
      remainingCuts,
      {
        width: remnant.width,
        height: remnant.height,
        cutThickness,
        glassThickness: remnant.thickness,
        cuttingMethod
      }
    );

    if (result.placedCuts.length > 0) {
      sheetsUsed.push({
        sheet_id: remnant.id,
        sheet: remnant,
        cuts: result.placedCuts,
        utilization: result.utilization,
        waste_area: remnant.area_total * (1 - result.utilization / 100)
      });

      const placedCutIds = new Set(result.placedCuts.map(pc => pc.cut.id));
      remainingCuts = remainingCuts.filter(c => !placedCutIds.has(c.id));
    }
  }

  if (remainingCuts.length === 0) {
    return null;
  }

  const bestSheet = fullSheets.reduce((best, sheet) => {
    return sheet.area_total < best.area_total ? sheet : best;
  });

  const result = optimizeCutting(
    remainingCuts,
    bestSheet.width,
    bestSheet.height,
    cutThickness,
    bestSheet.thickness,
    cuttingMethod
  );

  if (result.placedCuts.length !== remainingCuts.length) {
    return null;
  }

  sheetsUsed.push({
    sheet_id: bestSheet.id,
    sheet: bestSheet,
    cuts: result.placedCuts,
    utilization: result.utilization,
    waste_area: bestSheet.area_total * (1 - result.utilization / 100)
  });

  const totalWaste = sheetsUsed.reduce((sum, s) => sum + s.waste_area, 0);
  const totalArea = sheetsUsed.reduce((sum, s) => sum + s.sheet.area_total, 0);
  const totalCost = sheetsUsed.reduce((sum, s) => sum + (s.sheet.purchase_cost || 0), 0);
  const totalUtilization = totalArea > 0 ? ((totalArea - totalWaste) / totalArea) * 100 : 0;

  return {
    id: crypto.randomUUID(),
    order_id: '',
    suggestion_number: suggestionNumber,
    sheets_used: sheetsUsed.map(s => s.sheet_id),
    sheet_details: sheetsUsed,
    total_utilization: totalUtilization,
    total_waste: totalWaste,
    estimated_remnants: result.remnants || [],
    total_cost: totalCost,
    uses_remnants: true,
    created_at: new Date().toISOString()
  };
}

async function tryMultipleFullSheets(
  cuts: Cut[],
  fullSheets: MaterialSheet[],
  cutThickness: number,
  cuttingMethod: 'manual' | 'machine',
  suggestionNumber: number
): Promise<OptimizationSuggestion | null> {
  if (fullSheets.length === 0) return null;

  const sortedSheets = [...fullSheets].sort((a, b) => a.area_total - b.area_total);

  const sheetsUsed: SheetWithCuts[] = [];
  let remainingCuts = [...cuts];
  let sheetsAdded = 0;
  const maxSheets = 3;

  for (const sheet of sortedSheets) {
    if (remainingCuts.length === 0 || sheetsAdded >= maxSheets) break;

    const result = optimizeCutting(
      remainingCuts,
      sheet.width,
      sheet.height,
      cutThickness,
      sheet.thickness,
      cuttingMethod
    );

    if (result.placedCuts.length > 0) {
      sheetsUsed.push({
        sheet_id: sheet.id,
        sheet: sheet,
        cuts: result.placedCuts,
        utilization: result.utilization,
        waste_area: sheet.area_total * (1 - result.utilization / 100)
      });

      const placedCutIds = new Set(result.placedCuts.map(pc => pc.cut.id));
      remainingCuts = remainingCuts.filter(c => !placedCutIds.has(c.id));
      sheetsAdded++;
    }
  }

  if (remainingCuts.length > 0) {
    return null;
  }

  const totalWaste = sheetsUsed.reduce((sum, s) => sum + s.waste_area, 0);
  const totalArea = sheetsUsed.reduce((sum, s) => sum + s.sheet.area_total, 0);
  const totalCost = sheetsUsed.reduce((sum, s) => sum + (s.sheet.purchase_cost || 0), 0);
  const totalUtilization = totalArea > 0 ? ((totalArea - totalWaste) / totalArea) * 100 : 0;

  return {
    id: crypto.randomUUID(),
    order_id: '',
    suggestion_number: suggestionNumber,
    sheets_used: sheetsUsed.map(s => s.sheet_id),
    sheet_details: sheetsUsed,
    total_utilization: totalUtilization,
    total_waste: totalWaste,
    estimated_remnants: [],
    total_cost: totalCost,
    uses_remnants: false,
    created_at: new Date().toISOString()
  };
}
