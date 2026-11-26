import { QmdDocument } from "../qmd-document.ts";
import { QmdDiv, QmdNode, QmdText } from "../qmd-node.ts";
import { blankLines, hasClass, headings, isExecutable, isExercise, tidy } from "./exercise.ts";
import { ProcessingStep } from "./processing-step.ts";

export class ExerciseScaffold implements ProcessingStep {
  run(doc: QmdDocument): QmdDocument {
    return new QmdDocument(doc.header, tidy(scaffold(doc.nodes)));
  }
}

function scaffold(nodes: QmdNode[]): QmdNode[] {
  return nodes.flatMap((node): QmdNode[] => {
    if (isExercise(node)) return exercise(node);
    if (isExecutable(node)) return [node];
    if (hasClass(node, "lm-scaffold")) return node.children;
    if (node instanceof QmdText) return [blankLines(node)];
    return [];
  });
}

// Only the content, after a blank line instead of the div; an exercise with nothing left but headings is dropped,
// e.g. one on paper
function exercise(div: QmdDiv): QmdNode[] {
  const children = inExercise(div);
  return children.some((node) => !(node instanceof QmdText)) ? [new QmdText([""]), ...children] : [];
}

function inExercise(exercise: QmdDiv): QmdNode[] {
  return exercise.children.flatMap((node): QmdNode[] => {
    if (node instanceof QmdText) return [headings(node)];
    if (isExecutable(node)) return [node];
    if (hasClass(node, "lm-scaffold")) return node.children;
    return [];
  });
}
