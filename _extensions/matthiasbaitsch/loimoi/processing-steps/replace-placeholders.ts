import { parse as parseYaml, stringify as stringifyYaml } from "jsr:@std/yaml@1";
import { QmdDocument } from "../qmd-document.ts";
import { replacePlaceholders, Yaml } from "../utilities.ts";
import { ProcessingStep } from "./processing-step.ts";

// In the header and in the text
export class ReplacePlaceholders implements ProcessingStep {
  readonly values: Record<string, string>;

  constructor(values: Record<string, string>) {
    this.values = values;
  }

  run(doc: QmdDocument): QmdDocument {
    const replace = (text: string) => replacePlaceholders(text, this.values);
    const header = (parseYaml(replace(stringifyYaml(doc.header))) ?? {}) as Yaml;
    return new QmdDocument(header, doc.nodes.map((node) => node.transformText(replace)));
  }
}
