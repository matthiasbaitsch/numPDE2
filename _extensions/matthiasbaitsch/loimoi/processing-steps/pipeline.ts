import { QmdDocument } from "../qmd-document.ts";
import { ExerciseScaffold } from "./exercise-scaffold.ts";
import { ExerciseSheet } from "./exercise-sheet.ts";
import { ExerciseSolution } from "./exercise-solution.ts";
import { ProcessingStep } from "./processing-step.ts";
import { ShowMarkers } from "./show-markers.ts";

// Steps that can be added by their name in `process`
const steps: Record<string, () => ProcessingStep> = {
  "exercise-sheet": () => new ExerciseSheet(),
  "exercise-scaffold": () => new ExerciseScaffold(),
  "exercise-solution": () => new ExerciseSolution(),
  "show-markers": () => new ShowMarkers(),
};

export class Pipeline {
  readonly steps: ProcessingStep[] = [];

  addStep(step: ProcessingStep | string): void {
    if (typeof step === "string") {
      const create = steps[step];
      if (create === undefined) throw new Error(`Unknown processing step: ${step}`);
      this.steps.push(create());
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
