import { QmdDocument } from "../qmd-document.ts";
import { QmdDiv, QmdNode } from "../qmd-node.ts";
import { checkStructure, hasClass, isExecutable, isSetup, tidy, withChildren } from "./exercise.ts";
import { ProcessingStep } from "./processing-step.ts";

export class ExerciseSheet implements ProcessingStep {
  run(doc: QmdDocument): QmdDocument {
    checkStructure(doc.nodes);
    return new QmdDocument(doc.header, tidy(sheet(doc.nodes)));
  }
}

function sheet(nodes: QmdNode[]): QmdNode[] {
  return nodes.flatMap((node): QmdNode[] => {
    if (hasClass(node, "lm-sheet")) return [node];
    if (hasClass(node, "lm-solution") || hasClass(node, "lm-scaffold")) return [];
    if (node instanceof QmdDiv) return [withChildren(node, sheet(node.children))];
    if (isExecutable(node) && !isSetup(node)) return [];
    return [node];
  });
}
