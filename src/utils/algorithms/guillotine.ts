import { Cut, PlacedCut, Sheet } from '../../types';

interface Rectangle {
  x: number;
  y: number;
  width: number;
  height: number;
}

export enum GuillotineSplitRule {
  ShorterLeftoverAxis,
  LongerLeftoverAxis,
  MinimizeArea,
  MaximizeArea,
  ShorterAxis,
  LongerAxis
}

export enum GuillotineFitRule {
  BestAreaFit,
  BestShortSideFit,
  BestLongSideFit,
  WorstAreaFit,
  WorstShortSideFit,
  WorstLongSideFit
}

export function packGuillotine(
  cuts: Array<Cut & { originalId: string }>,
  sheet: Sheet,
  splitRule: GuillotineSplitRule = GuillotineSplitRule.MinimizeArea,
  fitRule: GuillotineFitRule = GuillotineFitRule.BestAreaFit
): PlacedCut[] {
  const placedCuts: PlacedCut[] = [];
  const freeRectangles: Rectangle[] = [
    { x: 0, y: 0, width: sheet.width, height: sheet.height }
  ];

  for (const cut of cuts) {
    let bestRect: Rectangle | null = null;
    let bestScore = Infinity;
    let bestRotated = false;
    let bestRectIndex = -1;

    for (let i = 0; i < freeRectangles.length; i++) {
      const rect = freeRectangles[i];

      for (const rotated of [false, true]) {
        const width = rotated ? cut.height : cut.width;
        const height = rotated ? cut.width : cut.height;

        if (width <= rect.width && height <= rect.height) {
          const score = calculateFitScore(width, height, rect, fitRule);
          if (score < bestScore) {
            bestScore = score;
            bestRect = rect;
            bestRotated = rotated;
            bestRectIndex = i;
          }
        }
      }
    }

    if (!bestRect) {
      break;
    }

    const width = bestRotated ? cut.height : cut.width;
    const height = bestRotated ? cut.width : cut.height;

    placedCuts.push({
      cut,
      x: bestRect.x,
      y: bestRect.y,
      width,
      height,
      rotated: bestRotated
    });

    const newRects = splitFreeRectangle(bestRect, width, height, splitRule, sheet.cutThickness);
    freeRectangles.splice(bestRectIndex, 1, ...newRects);

    pruneFreeRectangles(freeRectangles);
  }

  return placedCuts;
}

function calculateFitScore(
  width: number,
  height: number,
  rect: Rectangle,
  fitRule: GuillotineFitRule
): number {
  const leftoverHoriz = rect.width - width;
  const leftoverVert = rect.height - height;
  const shortSideFit = Math.min(leftoverHoriz, leftoverVert);
  const longSideFit = Math.max(leftoverHoriz, leftoverVert);
  const areaFit = rect.width * rect.height - width * height;

  switch (fitRule) {
    case GuillotineFitRule.BestAreaFit:
      return areaFit;
    case GuillotineFitRule.BestShortSideFit:
      return shortSideFit;
    case GuillotineFitRule.BestLongSideFit:
      return longSideFit;
    case GuillotineFitRule.WorstAreaFit:
      return -areaFit;
    case GuillotineFitRule.WorstShortSideFit:
      return -shortSideFit;
    case GuillotineFitRule.WorstLongSideFit:
      return -longSideFit;
  }
}

function splitFreeRectangle(
  rect: Rectangle,
  placedWidth: number,
  placedHeight: number,
  splitRule: GuillotineSplitRule,
  cutThickness: number
): Rectangle[] {
  const result: Rectangle[] = [];

  const rightWidth = rect.width - placedWidth - cutThickness;
  const topHeight = rect.height - placedHeight - cutThickness;

  const canSplitHorizontal = topHeight > 0;
  const canSplitVertical = rightWidth > 0;

  if (!canSplitHorizontal && !canSplitVertical) {
    return result;
  }

  if (!canSplitHorizontal) {
    result.push({
      x: rect.x + placedWidth + cutThickness,
      y: rect.y,
      width: rightWidth,
      height: rect.height
    });
    return result;
  }

  if (!canSplitVertical) {
    result.push({
      x: rect.x,
      y: rect.y + placedHeight + cutThickness,
      width: rect.width,
      height: topHeight
    });
    return result;
  }

  const splitHorizontally = shouldSplitHorizontally(
    rect,
    placedWidth,
    placedHeight,
    rightWidth,
    topHeight,
    splitRule
  );

  if (splitHorizontally) {
    result.push({
      x: rect.x + placedWidth + cutThickness,
      y: rect.y,
      width: rightWidth,
      height: placedHeight
    });
    result.push({
      x: rect.x,
      y: rect.y + placedHeight + cutThickness,
      width: rect.width,
      height: topHeight
    });
  } else {
    result.push({
      x: rect.x,
      y: rect.y + placedHeight + cutThickness,
      width: placedWidth,
      height: topHeight
    });
    result.push({
      x: rect.x + placedWidth + cutThickness,
      y: rect.y,
      width: rightWidth,
      height: rect.height
    });
  }

  return result;
}

function shouldSplitHorizontally(
  rect: Rectangle,
  placedWidth: number,
  placedHeight: number,
  rightWidth: number,
  topHeight: number,
  splitRule: GuillotineSplitRule
): boolean {
  switch (splitRule) {
    case GuillotineSplitRule.ShorterLeftoverAxis:
      return rightWidth <= topHeight;
    case GuillotineSplitRule.LongerLeftoverAxis:
      return rightWidth > topHeight;
    case GuillotineSplitRule.MinimizeArea: {
      const horizArea = rightWidth * placedHeight + rect.width * topHeight;
      const vertArea = placedWidth * topHeight + rightWidth * rect.height;
      return horizArea <= vertArea;
    }
    case GuillotineSplitRule.MaximizeArea: {
      const horizArea = rightWidth * placedHeight + rect.width * topHeight;
      const vertArea = placedWidth * topHeight + rightWidth * rect.height;
      return horizArea > vertArea;
    }
    case GuillotineSplitRule.ShorterAxis:
      return rect.width <= rect.height;
    case GuillotineSplitRule.LongerAxis:
      return rect.width > rect.height;
  }
}

function pruneFreeRectangles(freeRectangles: Rectangle[]): void {
  for (let i = 0; i < freeRectangles.length; i++) {
    for (let j = i + 1; j < freeRectangles.length; ) {
      if (isContainedIn(freeRectangles[i], freeRectangles[j])) {
        freeRectangles.splice(i, 1);
        i--;
        break;
      }
      if (isContainedIn(freeRectangles[j], freeRectangles[i])) {
        freeRectangles.splice(j, 1);
      } else {
        j++;
      }
    }
  }
}

function isContainedIn(a: Rectangle, b: Rectangle): boolean {
  return (
    a.x >= b.x &&
    a.y >= b.y &&
    a.x + a.width <= b.x + b.width &&
    a.y + a.height <= b.y + b.height
  );
}
