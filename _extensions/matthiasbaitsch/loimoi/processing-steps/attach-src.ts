import { basename, extname } from "jsr:@std/path@1";
import { QmdDocument } from "../qmd-document.ts";
import { ProcessingStep } from "./processing-step.ts";

const languages: Record<string, string> = { ".jl": "julia", ".py": "python", ".R": "r", ".r": "r" };

export class AttachSrc implements ProcessingStep {
  readonly files: string[]; // absolute paths
  readonly heading: string; // e.g. "Appendix"

  constructor(files: string[], heading: string) {
    this.files = files;
    this.heading = heading;
  }

  run(doc: QmdDocument): QmdDocument {
    const files = this.files.filter((file) => !Deno.readTextFileSync(file).split("\n", 1)[0].includes("lm-no-attach"));
    if (files.length === 0) return doc;
    const sections = files.map((file) => {
      const language = languages[extname(file)];
      if (language === undefined) throw new Error(`Unknown language of ${file}`);
      const code = Deno.readTextFileSync(file).replace(/\n?$/, "\n");
      return `### \`src/${basename(file)}\`\n\n\`\`\`{.${language} .number-lines}\n${code}\`\`\``;
    });
    return QmdDocument.parse(`${doc.text()}\n## ${this.heading}\n\n${sections.join("\n\n")}\n`);
  }
}
