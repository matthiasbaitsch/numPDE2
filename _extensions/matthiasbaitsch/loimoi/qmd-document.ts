import { stringify as stringifyYaml } from "jsr:@std/yaml@1";
import { jupyterNotebook } from "./jupyter-notebook.ts";
import { QmdNode } from "./qmd-node.ts";
import { parseBody, splitHeader } from "./qmd-parser.ts";
import { Yaml } from "./utilities.ts";

export class QmdDocument {
  readonly header: Yaml;
  readonly nodes: QmdNode[];

  constructor(header: Yaml, nodes: QmdNode[]) {
    this.header = header;
    this.nodes = nodes;
  }

  static parse(text: string): QmdDocument {
    const { header, body } = splitHeader(text);
    return new QmdDocument(header, parseBody(body));
  }

  static read(...files: string[]): QmdDocument {
    const header: Yaml = {};
    const bodies: string[] = [];
    for (const file of files) {
      const parts = splitHeader(Deno.readTextFileSync(file));
      for (const [key, value] of Object.entries(parts.header)) {
        const clash = key in header && JSON.stringify(header[key]) !== JSON.stringify(value);
        if (clash) throw new Error(`Header value ${key} in ${file} clashes with a previous file`);
        header[key] = value;
      }
      bodies.push(parts.body.replace(/\n+$/, ""));
    }
    // A blank line between the files: a fence right after a paragraph would belong to the paragraph
    return new QmdDocument(header, parseBody(bodies.join("\n\n") + "\n"));
  }

  body(): string {
    return this.nodes.map((node) => node.text()).join("\n");
  }

  text(): string {
    if (Object.keys(this.header).length === 0) return this.body();
    return `---\n${stringifyYaml(this.header)}---\n\n${this.body()}`;
  }

  ipynb(): string {
    return JSON.stringify(jupyterNotebook(this.header, this.nodes), null, 1);
  }

  forEach(f: (node: QmdNode) => void): void {
    this.nodes.forEach((node) => node.forEach(f));
  }

  map(f: (node: QmdNode) => QmdNode[]): QmdDocument {
    return new QmdDocument(this.header, this.nodes.flatMap((node) => node.map(f)));
  }

  // A Jupyter notebook for `.ipynb`, otherwise Quarto
  write(file: string): void {
    Deno.writeTextFileSync(file, file.endsWith(".ipynb") ? this.ipynb() : this.text());
  }
}
