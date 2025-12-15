import { Cut, PlacedCut, Sheet } from '../../types';

interface SkylineNode {
  x: number;
  y: number;
  width: number;
}

export enum SkylineFitRule {
  MinWasteFit,
  BottomLeftFit
}

export function packSkyline(
  cuts: Array<Cut & { originalId: string }>,
  sheet: Sheet,
  fitRule: SkylineFitRule = SkylineFitRule.MinWasteFit
): PlacedCut[] {
  const placedCuts: PlacedCut[] = [];
  const skyline: SkylineNode[] = [{ x: 0, y: 0, width: sheet.width }];

  for (const cut of cuts) {
    let bestY = Infinity;
    let bestScore = Infinity;
    let bestIndex = -1;
    let bestRotated = false;
    let bestX = 0;
    let bestWidth = 0;
    let bestHeight = 0;

    for (const rotated of [false, true]) {
      const width = rotated ? cut.height : cut.width;
      const height = rotated ? cut.width : cut.height;

      for (let i = 0; i < skyline.length; i++) {
        const result = canFitAtPosition(i, width, height, skyline, sheet);
        if (!result.canFit) continue;

        const y = result.y;
        const score =
          fitRule === SkylineFitRule.MinWasteFit
            ? calculateWaste(i, width, height, skyline, result.y)
            : y;

        if (y < bestY || (y === bestY && score < bestScore)) {
          bestY = y;
          bestScore = score;
          bestIndex = i;
          bestRotated = rotated;
          bestX = skyline[i].x;
          bestWidth = width;
          bestHeight = height;
        }
      }
    }

    if (bestIndex === -1 || bestY + bestHeight > sheet.height) {
      break;
    }

    placedCuts.push({
      cut,
      x: bestX,
      y: bestY,
      width: bestWidth,
      height: bestHeight,
      rotated: bestRotated
    });

    addSkylineLevel(bestIndex, bestX, bestY, bestWidth, bestHeight, skyline, sheet.cutThickness);
  }

  return placedCuts;
}

function canFitAtPosition(
  index: number,
  width: number,
  height: number,
  skyline: SkylineNode[],
  sheet: Sheet
): { canFit: boolean; y: number } {
  const x = skyline[index].x;
  if (x + width > sheet.width) {
    return { canFit: false, y: 0 };
  }

  let widthLeft = width;
  let i = index;
  let y = skyline[index].y;

  while (widthLeft > 0) {
    if (i >= skyline.length) {
      return { canFit: false, y: 0 };
    }

    y = Math.max(y, skyline[i].y);

    if (y + height > sheet.height) {
      return { canFit: false, y: 0 };
    }

    widthLeft -= skyline[i].width;
    i++;
  }

  return { canFit: true, y };
}

function calculateWaste(
  index: number,
  width: number,
  _height: number,
  skyline: SkylineNode[],
  y: number
): number {
  let waste = 0;
  let widthLeft = width;
  let i = index;

  while (widthLeft > 0 && i < skyline.length) {
    if (skyline[i].y < y) {
      waste += (y - skyline[i].y) * Math.min(widthLeft, skyline[i].width);
    }
    widthLeft -= skyline[i].width;
    i++;
  }

  return waste;
}

function addSkylineLevel(
  index: number,
  x: number,
  y: number,
  width: number,
  height: number,
  skyline: SkylineNode[],
  cutThickness: number
): void {
  const newNode: SkylineNode = {
    x,
    y: y + height + cutThickness,
    width
  };

  skyline.splice(index, 0, newNode);

  let i = index + 1;
  while (i < skyline.length) {
    if (skyline[i].x < skyline[i - 1].x + skyline[i - 1].width) {
      const shrink = skyline[i - 1].x + skyline[i - 1].width - skyline[i].x;

      skyline[i].x += shrink;
      skyline[i].width -= shrink;

      if (skyline[i].width <= 0) {
        skyline.splice(i, 1);
        i--;
      } else {
        break;
      }
    } else {
      break;
    }
    i++;
  }

  mergeSkylines(skyline);
}

function mergeSkylines(skyline: SkylineNode[]): void {
  for (let i = 0; i < skyline.length - 1; i++) {
    if (skyline[i].y === skyline[i + 1].y) {
      skyline[i].width += skyline[i + 1].width;
      skyline.splice(i + 1, 1);
      i--;
    }
  }
}
