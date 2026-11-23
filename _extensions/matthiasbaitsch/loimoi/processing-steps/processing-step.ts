import { QmdDocument } from "../qmd-document.ts";

export interface ProcessingStep {
  run(doc: QmdDocument): QmdDocument;
}
