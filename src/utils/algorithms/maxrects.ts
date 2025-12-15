import { Cut, PlacedCut, Sheet } from '../../types';

interface Rectangle {
  x: number;
  y: number;
  width: number;
  height: number;
}

export enum MaxRectsFitRule {
  BestShortSideFit,
  BestLongSideFit,
  BestAreaFit,
  BottomLeftRule,
  ContactPointRule
}

export function packMaxRects(
  cuts: Array<Cut & { originalId: string }>,
  sheet: Sheet,
  fitRule: MaxRectsFitRule = MaxRectsFitRule.BestShortSideFit
): PlacedCut[] {
  const placedCuts: PlacedCut[] = [];
  const freeRectangles: Rectangle[] = [
    { x: 0, y: 0, width: sheet.width, height: sheet.height }
  ];
  const usedRectangles: Rectangle[] = [];

  for (const cut of cuts) {
    let bestRect: Rectangle | null = null;
    let bestScore = Infinity;
    let bestSecondaryScore = Infinity;
    let bestRotated = false;
    let bestX = 0;
    let bestY = 0;
    let bestWidth = 0;
    let bestHeight = 0;

    for (const rect of freeRectangles) {
      for (const rotated of [false, true]) {
        const width = rotated ? cut.height : cut.width;
        const height = rotated ? cut.width : cut.height;

        if (width <= rect.width && height <= rect.height) {
          const [score, secondaryScore] = calculateMaxRectsScore(
            width,
            height,
            rect,
            fitRule,
            usedRectangles
          );

          if (
            score < bestScore ||
            (score === bestScore && secondaryScore < bestSecondaryScore)
          ) {
            bestScore = score;
            bestSecondaryScore = secondaryScore;
            bestRect = rect;
            bestRotated = rotated;
            bestX = rect.x;
            bestY = rect.y;
            bestWidth = width;
            bestHeight = height;
          }
        }
      }
    }

    if (!bestRect) {
      break;
    }

    const placedRect: Rectangle = {
      x: bestX,
      y: bestY,
      width: bestWidth,
      height: bestHeight
    };

    placedCuts.push({
      cut,
      x: bestX,
      y: bestY,
      width: bestWidth,
      height: bestHeight,
      rotated: bestRotated
    });

    usedRectangles.push(placedRect);

    const numRectanglesToProcess = freeRectangles.length;
    for (let i = 0; i < numRectanglesToProcess; i++) {
      if (splitFreeNode(freeRectangles[i], placedRect, freeRectangles, sheet.cutThickness)) {
        freeRectangles.splice(i, 1);
        i--;
      }
    }

    pruneFreeList(freeRectangles);
  }

  return placedCuts;
}

function calculateMaxRectsScore(
  width: number,
  height: number,
  rect: Rectangle,
  fitRule: MaxRectsFitRule,
  usedRectangles: Rectangle[]
): [number, number] {
  const leftoverHoriz = rect.width - width;
  const leftoverVert = rect.height - height;
  const shortSideFit = Math.min(leftoverHoriz, leftoverVert);
  const longSideFit = Math.max(leftoverHoriz, leftoverVert);

  switch (fitRule) {
    case MaxRectsFitRule.BestShortSideFit:
      return [shortSideFit, longSideFit];
    case MaxRectsFitRule.BestLongSideFit:
      return [longSideFit, shortSideFit];
    case MaxRectsFitRule.BestAreaFit: {
      const areaFit = rect.width * rect.height - width * height;
      return [areaFit, Math.min(leftoverHoriz, leftoverVert)];
    }
    case MaxRectsFitRule.BottomLeftRule:
      return [rect.y, rect.x];
    case MaxRectsFitRule.ContactPointRule: {
      let contactPoints = 0;
      const rectRight = rect.x + width;
      const rectTop = rect.y + height;

      if (rect.x === 0 || rect.y === 0) {
        contactPoints++;
      }

      for (const used of usedRectangles) {
        if (used.x === rectRight || used.x + used.width === rect.x) {
          if (
            (used.y >= rect.y && used.y < rectTop) ||
            (used.y + used.height > rect.y && used.y + used.height <= rectTop)
          ) {
            contactPoints++;
          }
        }
        if (used.y === rectTop || used.y + used.height === rect.y) {
          if (
            (used.x >= rect.x && used.x < rectRight) ||
            (used.x + used.width > rect.x && used.x + used.width <= rectRight)
          ) {
            contactPoints++;
          }
        }
      }
      return [-contactPoints, 0];
    }
  }
}

function splitFreeNode(
  freeNode: Rectangle,
  usedNode: Rectangle,
  freeRectangles: Rectangle[],
  cutThickness: number
): boolean {
  const usedRight = usedNode.x + usedNode.width + cutThickness;
  const usedTop = usedNode.y + usedNode.height + cutThickness;

  if (
    usedNode.x >= freeNode.x + freeNode.width ||
    usedRight <= freeNode.x ||
    usedNode.y >= freeNode.y + freeNode.height ||
    usedTop <= freeNode.y
  ) {
    return false;
  }

  if (usedNode.x < freeNode.x + freeNode.width && usedRight > freeNode.x) {
    if (usedNode.y > freeNode.y && usedNode.y < freeNode.y + freeNode.height) {
      const newNode: Rectangle = { ...freeNode };
      newNode.height = usedNode.y - newNode.y;
      freeRectangles.push(newNode);
    }

    if (usedTop < freeNode.y + freeNode.height) {
      const newNode: Rectangle = { ...freeNode };
      newNode.y = usedTop;
      newNode.height = freeNode.y + freeNode.height - usedTop;
      freeRectangles.push(newNode);
    }
  }

  if (usedNode.y < freeNode.y + freeNode.height && usedTop > freeNode.y) {
    if (usedNode.x > freeNode.x && usedNode.x < freeNode.x + freeNode.width) {
      const newNode: Rectangle = { ...freeNode };
      newNode.width = usedNode.x - newNode.x;
      freeRectangles.push(newNode);
    }

    if (usedRight < freeNode.x + freeNode.width) {
      const newNode: Rectangle = { ...freeNode };
      newNode.x = usedRight;
      newNode.width = freeNode.x + freeNode.width - usedRight;
      freeRectangles.push(newNode);
    }
  }

  return true;
}

function pruneFreeList(freeRectangles: Rectangle[]): void {
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
