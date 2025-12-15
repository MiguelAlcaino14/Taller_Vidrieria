import { Cut, PlacedCut, Sheet, PackingResult } from '../../types';
import { packGuillotine, GuillotineSplitRule, GuillotineFitRule } from './guillotine';
import { packMaxRects, MaxRectsFitRule } from './maxrects';
import { packSkyline, SkylineFitRule } from './skyline';
import { sortCuts, getAllSortStrategies, SortStrategy } from './sorting';
import { packPatternGuillotine } from './patternGuillotine';

export interface PackingStrategy {
  name: string;
  algorithm: string;
  sortStrategy: string;
  utilization: number;
  placedCuts: PlacedCut[];
}

function expandCuts(cuts: Cut[]): Array<Cut & { originalId: string }> {
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

  return expandedCuts;
}

function calculateUtilization(placedCuts: PlacedCut[], sheet: Sheet): number {
  const totalArea = sheet.width * sheet.height;
  const usedArea = placedCuts.reduce((sum, pc) => sum + (pc.width * pc.height), 0);
  return totalArea > 0 ? (usedArea / totalArea) * 100 : 0;
}

export function optimizePacking(cuts: Cut[], sheet: Sheet): PackingStrategy[] {
  const expandedCuts = expandCuts(cuts);
  const strategies: PackingStrategy[] = [];
  const partialStrategies: PackingStrategy[] = [];

  const sortStrategies = getAllSortStrategies();

  for (const sortStrategy of sortStrategies) {
    const sortedCuts = sortCuts(expandedCuts, sortStrategy);

    const guillotineSplitRules = [
      GuillotineSplitRule.MinimizeArea,
      GuillotineSplitRule.MaximizeArea,
      GuillotineSplitRule.ShorterLeftoverAxis,
      GuillotineSplitRule.LongerLeftoverAxis
    ];

    const guillotineFitRules = [
      GuillotineFitRule.BestAreaFit,
      GuillotineFitRule.BestShortSideFit,
      GuillotineFitRule.BestLongSideFit
    ];

    for (const splitRule of guillotineSplitRules) {
      for (const fitRule of guillotineFitRules) {
        try {
          const placedCuts = packGuillotine(sortedCuts, sheet, splitRule, fitRule);
          const utilization = calculateUtilization(placedCuts, sheet);
          const strategy = {
            name: `Guillotine (${GuillotineSplitRule[splitRule]}, ${GuillotineFitRule[fitRule]})`,
            algorithm: 'Guillotine',
            sortStrategy: SortStrategy[sortStrategy],
            utilization,
            placedCuts
          };

          if (placedCuts.length === expandedCuts.length) {
            strategies.push(strategy);
          } else if (placedCuts.length > 0) {
            partialStrategies.push(strategy);
          }
        } catch (error) {
          console.error('Guillotine packing error:', error);
        }
      }
    }

    const maxRectsFitRules = [
      MaxRectsFitRule.BestShortSideFit,
      MaxRectsFitRule.BestLongSideFit,
      MaxRectsFitRule.BestAreaFit,
      MaxRectsFitRule.BottomLeftRule,
      MaxRectsFitRule.ContactPointRule
    ];

    for (const fitRule of maxRectsFitRules) {
      try {
        const placedCuts = packMaxRects(sortedCuts, sheet, fitRule);
        const utilization = calculateUtilization(placedCuts, sheet);
        const strategy = {
          name: `MaxRects (${MaxRectsFitRule[fitRule]})`,
          algorithm: 'MaxRects',
          sortStrategy: SortStrategy[sortStrategy],
          utilization,
          placedCuts
        };

        if (placedCuts.length === expandedCuts.length) {
          strategies.push(strategy);
        } else if (placedCuts.length > 0) {
          partialStrategies.push(strategy);
        }
      } catch (error) {
        console.error('MaxRects packing error:', error);
      }
    }

    const skylineFitRules = [SkylineFitRule.MinWasteFit, SkylineFitRule.BottomLeftFit];

    for (const fitRule of skylineFitRules) {
      try {
        const placedCuts = packSkyline(sortedCuts, sheet, fitRule);
        const utilization = calculateUtilization(placedCuts, sheet);
        const strategy = {
          name: `Skyline (${SkylineFitRule[fitRule]})`,
          algorithm: 'Skyline',
          sortStrategy: SortStrategy[sortStrategy],
          utilization,
          placedCuts
        };

        if (placedCuts.length === expandedCuts.length) {
          strategies.push(strategy);
        } else if (placedCuts.length > 0) {
          partialStrategies.push(strategy);
        }
      } catch (error) {
        console.error('Skyline packing error:', error);
      }
    }
  }

  if (strategies.length > 0) {
    strategies.sort((a, b) => b.utilization - a.utilization);
    return strategies;
  }

  if (partialStrategies.length > 0) {
    partialStrategies.sort((a, b) => {
      const countDiff = b.placedCuts.length - a.placedCuts.length;
      if (countDiff !== 0) return countDiff;
      return b.utilization - a.utilization;
    });
    return partialStrategies;
  }

  return [];
}

export function getBestPacking(cuts: Cut[], sheet: Sheet): PlacedCut[] {
  const strategies = optimizePacking(cuts, sheet);

  if (strategies.length === 0) {
    return [];
  }

  return strategies[0].placedCuts;
}

export function getBestPackingWithDetails(cuts: Cut[], sheet: Sheet): PackingResult {
  if (sheet.cuttingMethod === 'manual') {
    return packPatternGuillotine(cuts, sheet);
  }

  const strategies = optimizePacking(cuts, sheet);

  if (strategies.length === 0) {
    return {
      placedCuts: [],
      utilization: 0,
      method: 'none'
    };
  }

  const best = strategies[0];
  return {
    placedCuts: best.placedCuts,
    utilization: best.utilization,
    method: best.algorithm
  };
}
