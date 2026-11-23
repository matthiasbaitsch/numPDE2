import { ensureDirSync, existsSync } from "jsr:@std/fs@1";
import { basename, dirname, join, relative } from "jsr:@std/path@1";
import { unzipSync, zipSync } from "npm:fflate@0.8";
import { Basket } from "../basket.ts";
import { AttachSrc } from "../processing-steps/attach-src.ts";
import { MergeSetupCells } from "../processing-steps/merge-setup-cells.ts";
import { Pipeline } from "../processing-steps/pipeline.ts";
import { ReplacePlaceholders } from "../processing-steps/replace-placeholders.ts";
import { QmdDocument } from "../qmd-document.ts";
import { replacePlaceholders, studentFiles, Yaml } from "../utilities.ts";
import { Action, Placeholders } from "./action.ts";

export class QuartoFile extends Action {
  readonly title?: string;
  readonly subtitle?: string;
  readonly process: string[];
  readonly format: string; // `qmd` or `ipynb`
  readonly zip: boolean; // the file zipped and deleted
  readonly link?: string; // label on the link pages, with placeholders

  constructor(settings: Yaml) {
    super(settings);
    this.title = settings.title as string | undefined;
    this.subtitle = settings.subtitle as string | undefined;
    this.process = (settings.process ?? []) as string[];
    this.format = (settings.format ?? "qmd") as string;
    this.zip = (settings.zip ?? false) as boolean;
    this.link = settings.link as string | undefined;
  }

  file(placeholders: Placeholders): string {
    return `${replacePlaceholders(this.name, placeholders)}.${this.zip ? "zip" : this.format}`;
  }

  run(basket: Basket, placeholders: Placeholders, folder: string): void {
    const pipeline = new Pipeline();
    pipeline.addStep(new ReplacePlaceholders(placeholders));
    pipeline.addStep(new MergeSetupCells());
    for (const step of this.process) {
      pipeline.addStep(
        step === "attach-src" ? new AttachSrc(basket.files("src/*", { absolute: true }), placeholders.appendix) : step,
      );
    }
    const doc = pipeline.run(QmdDocument.read(...basket.files("*.qmd", { absolute: true })));

    const header = { ...doc.header };
    if (this.title !== undefined) header.title = replacePlaceholders(this.title, placeholders);
    if (this.subtitle !== undefined) header.subtitle = replacePlaceholders(this.subtitle, placeholders);
    const path = join(folder, replacePlaceholders(this.name, placeholders));
    ensureDirSync(dirname(path));
    const file = `${path}.${this.format}`;
    new QmdDocument(header, doc.nodes).write(file);
    if (this.zip) {
      Deno.writeFileSync(`${path}.zip`, zipSync({ [basename(file)]: Deno.readFileSync(file) }));
      Deno.removeSync(file);
    }
    copyImages(doc, basket, dirname(path));
    copyFolders(basket, dirname(path), this.process.includes("exercise-scaffold"));
  }
}

// The folders of the ingredients next to the written file. Folders with a special meaning, neither of them into
// work files: `src/` holds the code of the solution, copied; `zip/<name>/` is an extra download, becomes
// `<name>.zip`. All other folders copied.
function copyFolders(basket: Basket, folder: string, workFiles: boolean): void {
  const zips: Record<string, Record<string, Uint8Array>> = {};
  for (const [path, source] of folderFiles(basket)) {
    const [top, name] = path.split("/");
    if (top === "zip") {
      zips[name] ??= {};
      zips[name][relative("zip", path)] = Deno.readFileSync(source);
    } else if (top !== "src") {
      copyChecked(source, folder, path);
    } else if (!workFiles) {
      copyChecked(source, folder, path);
    }
  }
  if (!workFiles) {
    for (const [name, files] of Object.entries(zips)) zipChecked(files, folder, `${name}.zip`);
  }
}

// Images referenced with a relative path, e.g. `![](images/sequence.svg)`, copied next to the written file
function copyImages(doc: QmdDocument, basket: Basket, folder: string): void {
  for (const [, image] of doc.text().matchAll(/!\[[^\]]*\]\(([^)\s]+)/g)) {
    if (!image.includes("://") && !image.startsWith("/")) {
      const source = basket.ingredients.map((ingredient) => ingredient.absolutePath(image)).find((path) =>
        existsSync(path)
      );
      if (source === undefined) throw new Error(`Image not found: ${image}`);
      copyChecked(source, folder, image);
    }
  }
}

// The files in the folders of every ingredient as pairs (e.g. `data/fibonacci.csv`, absolute path), copied next to
// the written file so code like `read.csv("data/…")` runs there; not the files directly in the ingredient folder.
// Pairs, not a record: two ingredients may have a file with the same path
function folderFiles(basket: Basket): [string, string][] {
  return basket.ingredients.flatMap((ingredient) => {
    const root = ingredient.absolutePath();
    const paths = studentFiles(root).map((source): [string, string] => [relative(root, source), source]);
    return paths.filter(([path]) => dirname(path) !== ".");
  });
}

function copyChecked(source: string, folder: string, path: string): void {
  writeChecked(Deno.readFileSync(source), folder, path);
}

// `path` relative to `folder`; error if a different file with the same name is already there
function writeChecked(content: Uint8Array, folder: string, path: string): void {
  const target = join(folder, path);
  if (existsSync(target) && !sameBytes(content, Deno.readFileSync(target))) {
    throw new Error(`Different files with the same name: ${path}`);
  }
  ensureDirSync(dirname(target));
  Deno.writeFileSync(target, content);
}

// Written only once; an existing zip is compared by its content, the bytes of a zip contain timestamps
function zipChecked(files: Record<string, Uint8Array>, folder: string, path: string): void {
  const target = join(folder, path);
  if (existsSync(target)) {
    if (!sameFiles(unzipSync(Deno.readFileSync(target)), files)) {
      throw new Error(`Different files with the same name: ${path}`);
    }
  } else {
    Deno.writeFileSync(target, zipSync(files));
  }
}

function sameFiles(a: Record<string, Uint8Array>, b: Record<string, Uint8Array>): boolean {
  const names = Object.keys(a).sort();
  const sameNames = names.join("\n") === Object.keys(b).sort().join("\n");
  return sameNames && names.every((name) => sameBytes(a[name], b[name]));
}

function sameBytes(a: Uint8Array, b: Uint8Array): boolean {
  return a.length === b.length && a.every((byte, i) => byte === b[i]);
}
