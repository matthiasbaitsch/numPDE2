import { QmdDocument } from "../qmd-document.ts";
import { QmdDiv, QmdNode, QmdText } from "../qmd-node.ts";
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

export class ExerciseScaffold implements ProcessingStep {
  run(doc: QmdDocument): QmdDocument {
    checkStructure(doc.nodes);
    return new QmdDocument(doc.header, tidy(scaffold(doc.nodes)));
  }
}

function scaffold(nodes: QmdNode[]): QmdNode[] {
  return nodes.flatMap((node): QmdNode[] => {
    if (isExercise(node)) return exercise(node);
    if (isExecutable(node) || hasClass(node, "lm-scaffold")) return [node];
    if (node instanceof QmdText) return [blankLines(node)];
    return [];
  });
}

// An exercise with nothing left but headings is dropped, e.g. one on paper
function exercise(div: QmdDiv): QmdNode[] {
  const children = inExercise(div);
  return children.some((node) => !(node instanceof QmdText)) ? [withChildren(div, children)] : [];
}

function inExercise(exercise: QmdDiv): QmdNode[] {
  return exercise.children.flatMap((node): QmdNode[] => {
    if (node instanceof QmdText) return [headings(node)];
    if (isExecutable(node) || hasClass(node, "lm-scaffold")) return [node];
    return [];
  });
}
