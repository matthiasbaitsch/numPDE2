import { Yaml } from "./utilities.ts";

export abstract class QmdNode {
  abstract text(): string;

  map(f: (node: QmdNode) => QmdNode[]): QmdNode[] {
    return f(this);
  }

  forEach(f: (node: QmdNode) => void): void {
    f(this);
  }
}

export class QmdText extends QmdNode {
  readonly lines: string[];

  constructor(lines: string[]) {
    super();
    this.lines = lines;
  }

  text(): string {
    return this.lines.join("\n");
  }
}

export class QmdCodeCell extends QmdNode {
  readonly lines: string[];
  readonly language: string;
  readonly executable: boolean;
  readonly options: Yaml;

  constructor(lines: string[], language: string, executable: boolean, options: Yaml) {
    super();
    this.lines = lines;
    this.language = language;
    this.executable = executable;
    this.options = options;
  }

  text(): string {
    return this.lines.join("\n");
  }
}

export class QmdDiv extends QmdNode {
  readonly open: string;
  readonly close: string;
  readonly id: string;
  readonly classes: string[];
  readonly children: QmdNode[];

  constructor(open: string, close: string, id: string, classes: string[], children: QmdNode[]) {
    super();
    this.open = open;
    this.close = close;
    this.id = id;
    this.classes = classes;
    this.children = children;
  }

  text(): string {
    return [this.open, ...this.children.map((child) => child.text()), this.close].join("\n");
  }

  override map(f: (node: QmdNode) => QmdNode[]): QmdNode[] {
    const children = this.children.flatMap((child) => child.map(f));
    return f(new QmdDiv(this.open, this.close, this.id, this.classes, children));
  }

  override forEach(f: (node: QmdNode) => void): void {
    this.children.forEach((child) => child.forEach(f));
    f(this);
  }
}
