// Helpers for the exercise steps: an exercise is a div with an id `exr-…`, its title the heading line in it

import { QmdCodeCell, QmdDiv, QmdNode, QmdText } from "../qmd-node.ts";

export function isExercise(node: QmdNode): node is QmdDiv {
  return node instanceof QmdDiv && node.id.startsWith("exr-");
}

export function hasClass(node: QmdNode, name: string): node is QmdDiv {
  return node instanceof QmdDiv && node.classes.includes(name);
}

export function isExecutable(node: QmdNode): node is QmdCodeCell {
  return node instanceof QmdCodeCell && node.executable;
}

export function isSetup(node: QmdNode): boolean {
  return node instanceof QmdCodeCell && node.options.label === "setup";
}

const markers = ["lm-sheet", "lm-scaffold", "lm-solution"];

// Errors: an exercise inside another div, a marker or a setup cell inside a marker
export function checkStructure(nodes: QmdNode[], inDiv = false, inMarker = false): void {
  for (const node of nodes) {
    if (isSetup(node) && inMarker) throw new Error("Setup cell inside a marker, it applies to all documents");
    if (node instanceof QmdDiv) {
      if (isExercise(node) && inDiv) throw new Error(`Exercise inside another div: ${node.id}`);
      const marker = markers.find((name) => node.classes.includes(name));
      if (marker !== undefined && inMarker) throw new Error(`Marker .${marker} inside another marker: ${node.open}`);
      checkStructure(node.children, true, inMarker || marker !== undefined);
    }
  }
}

export function withChildren(div: QmdDiv, children: QmdNode[]): QmdDiv {
  return new QmdDiv(div.open, div.close, div.id, div.classes, children);
}

// Text in an exercise reduced to its headings, the title and subheadings; blank lines keep the remaining parts apart
export function headings(text: QmdText): QmdText {
  return new QmdText(text.lines.filter((line) => line.startsWith("#") || isBlank(line)));
}

export function blankLines(text: QmdText): QmdText {
  return new QmdText(text.lines.filter(isBlank));
}

// Removing parts leaves blank lines behind: neighbouring texts joined, runs of blank lines reduced to one,
// no blank lines at the start, none before the end of a div
export function tidy(nodes: QmdNode[]): QmdNode[] {
  const joined: QmdNode[] = [];
  for (const node of nodes) {
    const last = joined.at(-1);
    if (node instanceof QmdText && last instanceof QmdText) {
      joined[joined.length - 1] = new QmdText([...last.lines, ...node.lines]);
    } else if (node instanceof QmdDiv) {
      joined.push(withChildren(node, withoutTrailingBlankLines(tidy(node.children))));
    } else {
      joined.push(node);
    }
  }
  const tidied = joined.map((node) => node instanceof QmdText ? new QmdText(singleBlankLines(node.lines)) : node);
  return withoutLeadingBlankLines(tidied);
}

function isBlank(line: string): boolean {
  return line.trim() === "";
}

function singleBlankLines(lines: string[]): string[] {
  return lines.filter((line, i) => !isBlank(line) || i === 0 || !isBlank(lines[i - 1]));
}

function withoutLeadingBlankLines(nodes: QmdNode[]): QmdNode[] {
  const first = nodes[0];
  if (!(first instanceof QmdText)) return nodes;
  const lines = [...first.lines];
  while (lines.length > 0 && isBlank(lines[0])) lines.shift();
  const rest = nodes.slice(1);
  return lines.length === 0 ? rest : [new QmdText(lines), ...rest];
}

function withoutTrailingBlankLines(nodes: QmdNode[]): QmdNode[] {
  const last = nodes.at(-1);
  if (!(last instanceof QmdText)) return nodes;
  const lines = [...last.lines];
  while (lines.length > 0 && isBlank(lines.at(-1)!)) lines.pop();
  const rest = nodes.slice(0, -1);
  return lines.length === 0 ? rest : [...rest, new QmdText(lines)];
}
