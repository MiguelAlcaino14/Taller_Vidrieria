import { PlacedCut, Sheet, Remnant } from '../types';

const MIN_USABLE_SIZE = 10;

export function calculateRemnants(placedCuts: PlacedCut[], sheet: Sheet): Remnant[] {
  if (placedCuts.length === 0) {
    return [{
      x: 0,
      y: 0,
      width: sheet.width,
      height: sheet.height,
      area: sheet.width * sheet.height
    }];
  }

  const remnants: Remnant[] = [];
  const occupiedRects: Array<{ x: number; y: number; width: number; height: number }> = [];

  placedCuts.forEach(pc => {
    occupiedRects.push({
      x: pc.x,
      y: pc.y,
      width: pc.width + sheet.cutThickness,
      height: pc.height + sheet.cutThickness
    });
  });

  const freeSpaces = findFreeSpaces(occupiedRects, sheet);

  freeSpaces.forEach(space => {
    if (space.width >= MIN_USABLE_SIZE && space.height >= MIN_USABLE_SIZE) {
      remnants.push({
        x: space.x,
        y: space.y,
        width: space.width,
        height: space.height,
        area: space.width * space.height
      });
    }
  });

  remnants.sort((a, b) => b.area - a.area);

  return remnants;
}

function findFreeSpaces(
  occupiedRects: Array<{ x: number; y: number; width: number; height: number }>,
  sheet: Sheet
): Array<{ x: number; y: number; width: number; height: number }> {
  const grid: boolean[][] = [];
  const resolution = 1;
  const cols = Math.ceil(sheet.width / resolution);
  const rows = Math.ceil(sheet.height / resolution);

  for (let y = 0; y < rows; y++) {
    grid[y] = [];
    for (let x = 0; x < cols; x++) {
      grid[y][x] = false;
    }
  }

  occupiedRects.forEach(rect => {
    const startX = Math.floor(rect.x / resolution);
    const startY = Math.floor(rect.y / resolution);
    const endX = Math.min(cols, Math.ceil((rect.x + rect.width) / resolution));
    const endY = Math.min(rows, Math.ceil((rect.y + rect.height) / resolution));

    for (let y = startY; y < endY; y++) {
      for (let x = startX; x < endX; x++) {
        if (y < rows && x < cols) {
          grid[y][x] = true;
        }
      }
    }
  });

  const freeSpaces: Array<{ x: number; y: number; width: number; height: number }> = [];
  const visited: boolean[][] = [];
  for (let y = 0; y < rows; y++) {
    visited[y] = [];
    for (let x = 0; x < cols; x++) {
      visited[y][x] = false;
    }
  }

  for (let y = 0; y < rows; y++) {
    for (let x = 0; x < cols; x++) {
      if (!grid[y][x] && !visited[y][x]) {
        const rect = findLargestRectangle(grid, visited, x, y, cols, rows);
        if (rect) {
          freeSpaces.push({
            x: rect.x * resolution,
            y: rect.y * resolution,
            width: rect.width * resolution,
            height: rect.height * resolution
          });
        }
      }
    }
  }

  return freeSpaces;
}

function findLargestRectangle(
  grid: boolean[][],
  visited: boolean[][],
  startX: number,
  startY: number,
  cols: number,
  rows: number
): { x: number; y: number; width: number; height: number } | null {
  let width = 0;
  for (let x = startX; x < cols && !grid[startY][x]; x++) {
    width++;
  }

  let height = 0;
  for (let y = startY; y < rows; y++) {
    let canExtend = true;
    for (let x = startX; x < startX + width; x++) {
      if (grid[y][x]) {
        canExtend = false;
        break;
      }
    }
    if (canExtend) {
      height++;
    } else {
      break;
    }
  }

  for (let y = startY; y < startY + height; y++) {
    for (let x = startX; x < startX + width; x++) {
      visited[y][x] = true;
    }
  }

  if (width > 0 && height > 0) {
    return { x: startX, y: startY, width, height };
  }

  return null;
}

export function formatRemnant(remnant: Remnant): string {
  return `${remnant.width.toFixed(1)} × ${remnant.height.toFixed(1)} cm (${remnant.area.toFixed(0)} cm²)`;
}
