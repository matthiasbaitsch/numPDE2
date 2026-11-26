import { QmdDocument } from "../qmd-document.ts";
import { QmdCodeCell } from "../qmd-node.ts";
import { isSetup } from "./exercise.ts";
import { ProcessingStep } from "./processing-step.ts";

export class MergeSetupCells implements ProcessingStep {
  run(doc: QmdDocument): QmdDocument {
    const setupCells: QmdCodeCell[] = [];
    doc.forEach((node) => {
      if (isSetup(node)) setupCells.push(node as QmdCodeCell);
    });
    const other = setupCells.find((cell) => cell.language !== setupCells[0].language);
    if (other !== undefined) {
      throw new Error(`Setup cells in different languages: ${setupCells[0].language} and ${other.language}`);
    }
    if (setupCells.length < 2) return doc;

    const merged = merge(setupCells);
    let first = true;
    return doc.map((node) => {
      if (!isSetup(node)) return [node];
      const replacement = first ? [merged] : [];
      first = false;
      return replacement;
    });
  }
}

// Fence and options of the first cell, the code of all cells, each line once
function merge(cells: QmdCodeCell[]): QmdCodeCell {
  const first = cells[0];
  const options = first.lines.filter((line) => line.startsWith("#|"));
  const code = cells.flatMap((cell) => cell.lines.slice(1, -1).filter((line) => !line.startsWith("#|")));
  const lines = [first.lines[0], ...options, ...new Set(code), first.lines.at(-1)!];
  return new QmdCodeCell(lines, first.language, first.executable);
}
