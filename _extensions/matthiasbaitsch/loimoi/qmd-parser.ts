// Pandoc finds divs and code cells with their line ranges; the nodes are cut from the original lines

import { parse as parseYaml } from "jsr:@std/yaml@1";
import { QmdCodeCell, QmdDiv, QmdNode, QmdText } from "./qmd-node.ts";
import { Yaml } from "./utilities.ts";

type PandocAttr = [string, string[], [string, string][]]; // id, classes, attributes

interface PandocBlock {
  t: string; // type, e.g. `Div`
  c: [PandocAttr, PandocBlock[]]; // for divs and code blocks, attributes come first
}

// The body without leading blank lines
export function splitHeader(text: string): { header: Yaml; body: string } {
  const match = text.match(/^---\n([\s\S]*?)\n---\n/);
  if (match === null) return { header: {}, body: text.replace(/^\n+/, "") };
  return { header: (parseYaml(match[1]) ?? {}) as Yaml, body: text.slice(match[0].length).replace(/^\n+/, "") };
}

export function parseBody(body: string): QmdNode[] {
  const lines = body.split("\n");
  return nodes(lines, 0, lines.length, pandoc(body));
}

function pandoc(text: string): PandocBlock[] {
  const file = Deno.makeTempFileSync({ suffix: ".md" });
  Deno.writeTextFileSync(file, text);
  const output = new Deno.Command("quarto", {
    args: ["pandoc", "-f", "commonmark_x+sourcepos", "-t", "json", file],
  }).outputSync();
  Deno.removeSync(file);
  if (!output.success) throw new Error(`Pandoc failed: ${new TextDecoder().decode(output.stderr)}`);
  return JSON.parse(new TextDecoder().decode(output.stdout)).blocks;
}

// The nodes for the lines from `first` to `end`: divs and code cells, and text in between
function nodes(lines: string[], first: number, end: number, blocks: PandocBlock[]): QmdNode[] {
  const result: QmdNode[] = [];
  let line = first;
  for (const block of divsAndCode(blocks)) {
    const [blockFirst, blockEnd] = range(block);
    if (blockFirst > line) result.push(new QmdText(lines.slice(line, blockFirst)));
    result.push(node(lines, block, blockFirst, blockEnd));
    line = blockEnd;
  }
  if (end > line) result.push(new QmdText(lines.slice(line, end)));
  return result;
}

// Divs without id and class are Pandoc's wrappers for positions; their content counts as if it stood outside
function divsAndCode(blocks: PandocBlock[]): PandocBlock[] {
  const result: PandocBlock[] = [];
  for (const block of blocks) {
    const wrapper = block.t === "Div" && block.c[0][0] === "" && block.c[0][1].length === 0;
    if (wrapper) result.push(...divsAndCode(block.c[1]));
    else if (block.t === "Div" || block.t === "CodeBlock") result.push(block);
  }
  return result;
}

function node(lines: string[], block: PandocBlock, first: number, end: number): QmdNode {
  const [id, classes] = block.c[0];
  if (block.t === "Div") {
    const children = nodes(lines, first + 1, end - 1, block.c[1]);
    return new QmdDiv(lines[first], lines[end - 1], id, classes, children);
  }
  const cellLines = lines.slice(first, end);
  const info = classes[0] ?? ""; // `{r}` for an executable cell, `r` for ```{.r}
  const options = cellLines.filter((line) => line.startsWith("#|")).map((line) => line.slice(2).trim());
  const yaml = (parseYaml(options.join("\n")) ?? {}) as Yaml;
  return new QmdCodeCell(cellLines, info.replace(/[{}]/g, ""), info.startsWith("{"), yaml);
}

// First line and line after the block, counted from 0, from `data-pos`, e.g. `file.md@10:1-44:1`
function range(block: PandocBlock): [number, number] {
  const position = block.c[0][2].find(([key]) => key === "data-pos")?.[1] ?? "";
  const match = position.match(/@(\d+):\d+-(\d+):\d+$/);
  if (match === null) throw new Error(`No position: ${position}`);
  return [Number(match[1]) - 1, Number(match[2]) - 1];
}
