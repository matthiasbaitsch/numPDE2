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
    setupCells.forEach(checkSingleLines);
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

// Merging keeps each line once, which is only right for single-line statements; indented lines and lines that only
// close something (`end`, `)`, …) are a sign of a statement over several lines
function checkSingleLines(cell: QmdCodeCell): void {
  const code = cell.lines.slice(1, -1);
  const multiLine = code.find((line) => /^\s+\S/.test(line) || /^\s*(end|\)|\]|\})\s*$/.test(line));
  if (multiLine !== undefined) {
    throw new Error(`Setup cell: only single-line statements allowed: \`${multiLine}\``);
  }
}

// Fence and options of the first cell, the code of all cells, each line once
function merge(cells: QmdCodeCell[]): QmdCodeCell {
  const first = cells[0];
  const options = first.lines.filter((line) => line.startsWith("#|"));
  const code = cells.flatMap((cell) => cell.lines.slice(1, -1).filter((line) => !line.startsWith("#|")));
  const lines = [first.lines[0], ...options, ...new Set(code), first.lines.at(-1)!];
  return new QmdCodeCell(lines, first.language, first.executable, first.options);
}
