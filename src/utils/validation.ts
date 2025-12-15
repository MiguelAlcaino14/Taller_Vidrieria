import { Sheet, Cut, CutValidation } from '../types';

interface MinDimensionRule {
  thickness: number;
  minDimension: number;
}

const MANUAL_RULES: MinDimensionRule[] = [
  { thickness: 3, minDimension: 15 },
  { thickness: 4, minDimension: 15 },
  { thickness: 5, minDimension: 18 },
  { thickness: 6, minDimension: 18 },
  { thickness: 8, minDimension: 20 },
  { thickness: 10, minDimension: 25 },
];

const MACHINE_RULES: MinDimensionRule[] = [
  { thickness: 3, minDimension: 10 },
  { thickness: 4, minDimension: 12 },
  { thickness: 5, minDimension: 15 },
  { thickness: 6, minDimension: 18 },
  { thickness: 8, minDimension: 22 },
  { thickness: 10, minDimension: 25 },
];

export function getMinimumDimension(glassThickness: number, cuttingMethod: 'manual' | 'machine'): number {
  const rules = cuttingMethod === 'manual' ? MANUAL_RULES : MACHINE_RULES;

  for (let i = 0; i < rules.length; i++) {
    if (glassThickness <= rules[i].thickness) {
      return rules[i].minDimension;
    }
  }

  return rules[rules.length - 1].minDimension;
}

export function validateCutDimensions(cut: Cut, sheet: Sheet): CutValidation {
  const minDimension = getMinimumDimension(sheet.glassThickness, sheet.cuttingMethod);
  const smallestDimension = Math.min(cut.width, cut.height);

  const warningThreshold = minDimension * 1.1;

  if (smallestDimension < minDimension) {
    return {
      status: 'danger',
      message: `Dimensión muy pequeña para ${sheet.cuttingMethod === 'manual' ? 'corte manual (toyo)' : 'máquina'}. Mínimo recomendado: ${minDimension}cm`,
      minDimension
    };
  } else if (smallestDimension < warningThreshold) {
    return {
      status: 'warning',
      message: `Cerca del límite mínimo (${minDimension}cm). Cortar con precaución.`,
      minDimension
    };
  } else {
    return {
      status: 'safe',
      message: 'Dimensiones seguras para corte',
      minDimension
    };
  }
}

export function getMethodRecommendation(cuts: Cut[], sheet: Sheet): string | null {
  if (sheet.cuttingMethod === 'machine') {
    return null;
  }

  const minDimension = getMinimumDimension(sheet.glassThickness, 'manual');
  const problematicCuts = cuts.filter(cut => {
    const smallestDimension = Math.min(cut.width, cut.height);
    return smallestDimension < minDimension;
  });

  if (problematicCuts.length > 0) {
    return `${problematicCuts.length} corte(s) son difíciles con toyo. Considera usar máquina automática para mayor precisión.`;
  }

  return null;
}

export function getStandardThicknesses(): number[] {
  return [3, 4, 5, 6, 8, 10, 12];
}

export function getDimensionRulesTable(): { manual: MinDimensionRule[], machine: MinDimensionRule[] } {
  return {
    manual: MANUAL_RULES,
    machine: MACHINE_RULES
  };
}
