import { basename, extname } from "jsr:@std/path@1";
import { QmdDocument } from "../qmd-document.ts";
import { QmdText } from "../qmd-node.ts";
import { ProcessingStep } from "./processing-step.ts";

const languages: Record<string, string> = { ".jl": "julia", ".py": "python", ".R": "r", ".r": "r" };

export class AttachSrc implements ProcessingStep {
  readonly heading: string;
  readonly files: string[];

  constructor(heading: string, files: string[]) {
    this.heading = heading;
    this.files = files;
  }

  run(doc: QmdDocument): QmdDocument {
    const sections = this.files.filter(isAttached).map(section);
    if (sections.length === 0) return doc;
    return doc.appendNode(new QmdText([`## ${this.heading}`, "", ...sections.flat()]));
  }
}

function isAttached(file: string): boolean {
  const firstLine = Deno.readTextFileSync(file).split("\n", 1)[0];
  return !firstLine.includes("lm-no-attach");
}

function section(file: string): string[] {
  const language = languages[extname(file)];
  if (language === undefined) throw new Error(`Unknown language of ${file}`);
  const code = Deno.readTextFileSync(file).replace(/\n?$/, "").split("\n");
  return [`### \`src/${basename(file)}\``, "", `\`\`\`{.${language} .number-lines}`, ...code, "```", ""];
}
