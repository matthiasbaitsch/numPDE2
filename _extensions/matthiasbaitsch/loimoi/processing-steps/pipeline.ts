import { QmdDocument } from "../qmd-document.ts";
import { AttachSrc } from "./attach-src.ts";
import { ExerciseScaffold } from "./exercise-scaffold.ts";
import { ExerciseSheet } from "./exercise-sheet.ts";
import { ExerciseSolution } from "./exercise-solution.ts";
import { ProcessingStep } from "./processing-step.ts";
import { ShowMarkers } from "./show-markers.ts";

// What steps added by their name may need
export interface StepContext {
  srcFiles: string[]; // the files of `src/`, absolute
  appendix: string; // heading of the appendix
}

// Steps that can be added by their name in `process`
const steps: Record<string, (context: StepContext) => ProcessingStep> = {
  "attach-src": (context) => new AttachSrc(context.srcFiles, context.appendix),
  "exercise-sheet": () => new ExerciseSheet(),
  "exercise-scaffold": () => new ExerciseScaffold(),
  "exercise-solution": () => new ExerciseSolution(),
  "show-markers": () => new ShowMarkers(),
};

export class Pipeline {
  readonly steps: ProcessingStep[] = [];
  readonly context: StepContext;

  constructor(context: StepContext) {
    this.context = context;
  }

  addStep(step: ProcessingStep | string): void {
    if (typeof step === "string") {
      const create = steps[step];
      if (create === undefined) throw new Error(`Unknown processing step: ${step}`);
      this.steps.push(create(this.context));
    } else {
      this.steps.push(step);
    }
  }

  run(doc: QmdDocument): QmdDocument {
    let result = doc;
    for (const step of this.steps) result = step.run(result);
    return result;
  }
}
