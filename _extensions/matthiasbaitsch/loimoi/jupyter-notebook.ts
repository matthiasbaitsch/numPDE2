// Executable cells become code cells, everything else markdown

import { stringify as stringifyYaml } from "jsr:@std/yaml@1";
import { QmdCodeCell, QmdDiv, QmdNode } from "./qmd-node.ts";
import { Yaml } from "./utilities.ts";

interface Cell {
  cell_type: "markdown" | "code" | "raw";
  metadata: Record<string, unknown>;
  source: string[];
  outputs?: unknown[];
  execution_count?: null;
}

export function jupyterNotebook(header: Yaml, nodes: QmdNode[]): Record<string, unknown> {
  const cells: Cell[] = [];
  let language = "";
  let markdown: string[] = [];

  const flush = () => {
    if (markdown.some((line) => line.trim() !== "")) cells.push(cell("markdown", markdown));
    markdown = [];
  };

  const visit = (node: QmdNode) => {
    if (node instanceof QmdCodeCell && node.executable) {
      flush();
      language ||= node.language;
      cells.push({ ...cell("code", node.lines.slice(1, -1)), outputs: [], execution_count: null });
    } else if (node instanceof QmdDiv) {
      node.children.forEach(visit); // a notebook has no divs
    } else {
      markdown.push(...node.text().split("\n"));
    }
  };

  if (Object.keys(header).length > 0) cells.push(cell("raw", `---\n${stringifyYaml(header)}---`.split("\n")));
  nodes.forEach(visit);
  flush();
  const metadata = { kernelspec: { name: language, language, display_name: language } };
  return { cells, metadata, nbformat: 4, nbformat_minor: 5 };
}

function cell(type: Cell["cell_type"], lines: string[]): Cell {
  const source = lines.map((line, i) => i < lines.length - 1 ? line + "\n" : line);
  return { cell_type: type, metadata: {}, source };
}
