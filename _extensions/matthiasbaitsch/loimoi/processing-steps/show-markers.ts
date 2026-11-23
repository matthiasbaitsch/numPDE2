import { QmdDocument } from "../qmd-document.ts";
import { ProcessingStep } from "./processing-step.ts";

// The filter `loimoi-markers.lua` of the extension, referred to by the name of the extension
export class ShowMarkers implements ProcessingStep {
  run(doc: QmdDocument): QmdDocument {
    const filters = (doc.header.filters ?? []) as string[];
    return new QmdDocument({ ...doc.header, filters: [...filters, "loimoi"] }, doc.nodes);
  }
}
