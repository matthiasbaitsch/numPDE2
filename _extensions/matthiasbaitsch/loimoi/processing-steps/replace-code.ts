import { CodeReplacement } from "../code-replacement.ts";
import { QmdDocument } from "../qmd-document.ts";
import { QmdCodeCell } from "../qmd-node.ts";
import { ProcessingStep } from "./processing-step.ts";

// The replacements for `step` in the code of executable cells, not in fence and cell options
export class ReplaceCode implements ProcessingStep {
  readonly step: string;
  readonly replacements: CodeReplacement[];

  constructor(step: string, replacements: CodeReplacement[]) {
    this.step = step;
    this.replacements = replacements;
  }

  run(doc: QmdDocument): QmdDocument {
    return doc.map((node) => {
      if (!(node instanceof QmdCodeCell) || !node.executable) return [node];
      const replacements = this.replacements.filter((r) => r.applies(this.step, node.language));
      const lines = node.lines.map((line, i) =>
        i === 0 || i === node.lines.length - 1 || line.startsWith("#|")
          ? line
          : replacements.reduce((result, r) => r.apply(result), line)
      );
      return [new QmdCodeCell(lines, node.language, node.executable, node.options)];
    });
  }
}
