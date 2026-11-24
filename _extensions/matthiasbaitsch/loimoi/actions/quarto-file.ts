import { ensureDirSync, existsSync } from "jsr:@std/fs@1";
import { basename, dirname, relative } from "jsr:@std/path@1";
import { Basket } from "../basket.ts";
import { CodeReplacement } from "../code-replacement.ts";
import { MergeSetupCells } from "../processing-steps/merge-setup-cells.ts";
import { Pipeline } from "../processing-steps/pipeline.ts";
import { ReplaceCode } from "../processing-steps/replace-code.ts";
import { ReplacePlaceholders } from "../processing-steps/replace-placeholders.ts";
import { ProductFolder } from "../product-folder.ts";
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
  readonly replacements: CodeReplacement[];

  constructor(settings: Yaml, replacements: CodeReplacement[]) {
    super(settings);
    this.replacements = replacements;
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

  run(basket: Basket, placeholders: Placeholders, folder: ProductFolder): void {
    const pipeline = new Pipeline({
      srcFiles: basket.files("src/*", { absolute: true }),
      appendix: placeholders.appendix,
    });
    pipeline.addStep(new ReplacePlaceholders(placeholders));
    pipeline.addStep(new MergeSetupCells());
    for (const step of this.process) {
      pipeline.addStep(step);
      pipeline.addStep(new ReplaceCode(step, this.replacements));
    }
    const doc = pipeline.run(QmdDocument.read(...basket.files("*.qmd", { absolute: true })));

    const header = { ...doc.header };
    if (this.title !== undefined) header.title = replacePlaceholders(this.title, placeholders);
    if (this.subtitle !== undefined) header.subtitle = replacePlaceholders(this.subtitle, placeholders);
    const name = replacePlaceholders(this.name, placeholders);
    const file = folder.path(`${name}.${this.format}`);
    ensureDirSync(dirname(file));
    new QmdDocument(header, doc.nodes).write(file);
    if (this.zip) {
      folder.zip({ [basename(file)]: Deno.readFileSync(file) }, `${name}.zip`);
      Deno.removeSync(file);
    }
    const target = folder.sub(dirname(name));
    copyImages(doc, basket, target);
    copyFolders(basket, target, this.process.includes("exercise-scaffold"));
  }
}

// The folders of the ingredients next to the written file. Folders with a special meaning, neither of them into
// work files: `src/` holds the code of the solution, copied; `zip/<name>/` is an extra download, becomes
// `<name>.zip`. All other folders copied.
function copyFolders(basket: Basket, folder: ProductFolder, workFiles: boolean): void {
  const zips: Record<string, Record<string, Uint8Array>> = {};
  for (const [path, source] of folderFiles(basket)) {
    const [top, name] = path.split("/");
    if (top === "zip") {
      zips[name] ??= {};
      zips[name][relative("zip", path)] = Deno.readFileSync(source);
    } else if (top !== "src") {
      folder.copy(source, path);
    } else if (!workFiles) {
      folder.copy(source, path);
    }
  }
  if (!workFiles) {
    for (const [name, files] of Object.entries(zips)) folder.zip(files, `${name}.zip`);
  }
}

// Images referenced with a relative path, e.g. `![](images/sequence.svg)`, copied next to the written file
function copyImages(doc: QmdDocument, basket: Basket, folder: ProductFolder): void {
  for (const [, image] of doc.text().matchAll(/!\[[^\]]*\]\(([^)\s]+)/g)) {
    if (!image.includes("://") && !image.startsWith("/")) {
      const source = basket.ingredients.map((ingredient) => ingredient.absolutePath(image)).find((path) =>
        existsSync(path)
      );
      if (source === undefined) throw new Error(`Image not found: ${image}`);
      folder.copy(source, image);
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
