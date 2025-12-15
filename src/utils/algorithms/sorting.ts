import { Cut } from '../../types';

export enum SortStrategy {
  ByArea,
  ByPerimeter,
  ByWidth,
  ByHeight,
  BySideRatio,
  ByLongerSide,
  ByShorterSide,
  ByDiagonal
}

export function sortCuts(
  cuts: Array<Cut & { originalId: string }>,
  strategy: SortStrategy
): Array<Cut & { originalId: string }> {
  const sorted = [...cuts];

  switch (strategy) {
    case SortStrategy.ByArea:
      sorted.sort((a, b) => {
        const areaA = a.width * a.height;
        const areaB = b.width * b.height;
        return areaB - areaA;
      });
      break;

    case SortStrategy.ByPerimeter:
      sorted.sort((a, b) => {
        const perimeterA = 2 * (a.width + a.height);
        const perimeterB = 2 * (b.width + b.height);
        return perimeterB - perimeterA;
      });
      break;

    case SortStrategy.ByWidth:
      sorted.sort((a, b) => b.width - a.width);
      break;

    case SortStrategy.ByHeight:
      sorted.sort((a, b) => b.height - a.height);
      break;

    case SortStrategy.BySideRatio:
      sorted.sort((a, b) => {
        const ratioA = Math.max(a.width, a.height) / Math.min(a.width, a.height);
        const ratioB = Math.max(b.width, b.height) / Math.min(b.width, b.height);
        return ratioB - ratioA;
      });
      break;

    case SortStrategy.ByLongerSide:
      sorted.sort((a, b) => {
        const longerA = Math.max(a.width, a.height);
        const longerB = Math.max(b.width, b.height);
        return longerB - longerA;
      });
      break;

    case SortStrategy.ByShorterSide:
      sorted.sort((a, b) => {
        const shorterA = Math.min(a.width, a.height);
        const shorterB = Math.min(b.width, b.height);
        return shorterB - shorterA;
      });
      break;

    case SortStrategy.ByDiagonal:
      sorted.sort((a, b) => {
        const diagonalA = Math.sqrt(a.width * a.width + a.height * a.height);
        const diagonalB = Math.sqrt(b.width * b.width + b.height * b.height);
        return diagonalB - diagonalA;
      });
      break;
  }

  return sorted;
}

export function getAllSortStrategies(): SortStrategy[] {
  return [
    SortStrategy.ByArea,
    SortStrategy.ByPerimeter,
    SortStrategy.ByLongerSide,
    SortStrategy.ByShorterSide,
    SortStrategy.BySideRatio,
    SortStrategy.ByDiagonal
  ];
}
