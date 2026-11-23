import { QmdDocument } from "../qmd-document.ts";
import { QmdCodeCell, QmdNode, QmdText } from "../qmd-node.ts";
import {
  blankLines,
  checkStructure,
  hasClass,
  headings,
  isExecutable,
  isExercise,
  tidy,
  withChildren,
} from "./exercise.ts";
import { ProcessingStep } from "./processing-step.ts";

export class ExerciseSolution implements ProcessingStep {
  run(doc: QmdDocument): QmdDocument {
    checkStructure(doc.nodes);
    return new QmdDocument(doc.header, tidy(solution(doc.nodes)));
  }
}

function solution(nodes: QmdNode[]): QmdNode[] {
  return nodes.flatMap((node): QmdNode[] => {
    if (isExercise(node)) return [withChildren(node, inExercise(node.children))];
    if (isExecutable(node)) return [hidden(node)];
    if (hasClass(node, "lm-solution")) return [node];
    if (node instanceof QmdText) return [blankLines(node)];
    return [];
  });
}

function inExercise(nodes: QmdNode[]): QmdNode[] {
  return nodes.flatMap((node): QmdNode[] => {
    if (node instanceof QmdText) return [headings(node)];
    if (isExecutable(node)) return [hidden(node)];
    if (hasClass(node, "lm-solution")) return [node];
    return [];
  });
}

// Given code: the students have it, the solution needs it to run
function hidden(cell: QmdCodeCell): QmdCodeCell {
  if ("include" in cell.options) return cell;
  const [fence, ...rest] = cell.lines;
  const lines = [fence, "#| include: false", ...rest];
  return new QmdCodeCell(lines, cell.language, cell.executable, { ...cell.options, include: false });
}
