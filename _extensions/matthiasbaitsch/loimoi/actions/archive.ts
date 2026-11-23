import { copySync, ensureDirSync, existsSync, walkSync } from "jsr:@std/fs@1";
import { basename, dirname, join, relative } from "jsr:@std/path@1";
import { zipSync } from "npm:fflate@0.8";
import { Basket } from "../basket.ts";
import { replacePlaceholders, studentFiles, Yaml } from "../utilities.ts";
import { Action, Placeholders } from "./action.ts";

// An entry of `add`: a path, or a path with a new name
type Entry = string | Record<string, string>;

export class Archive extends Action {
  readonly add: Entry[];

  constructor(settings: Yaml) {
    super(settings);
    this.add = (settings.add ?? []) as Entry[];
  }

  file(placeholders: Placeholders): string {
    return `${replacePlaceholders(this.name, placeholders)}.zip`;
  }

  run(basket: Basket, placeholders: Placeholders, folder: string): void {
    const archive = join(folder, replacePlaceholders(this.name, placeholders));
    ensureDirSync(archive);
    for (const entry of this.add) {
      const [source, newName] = typeof entry === "string" ? [entry, undefined] : Object.entries(entry)[0];
      const target = join(archive, replacePlaceholders(newName ?? basename(source), placeholders));
      for (const path of sources(basket, source)) copy(path, target);
    }
    zipFolder(archive, folder);
    Deno.removeSync(archive, { recursive: true });
  }
}

// A folder only with its files for students; a file as it is, even if its name starts with `_`
function copy(source: string, target: string): void {
  if (Deno.statSync(source).isDirectory) {
    for (const file of studentFiles(source)) {
      const path = join(target, relative(source, file));
      ensureDirSync(dirname(path));
      copySync(file, path, { overwrite: true });
    }
  } else {
    copySync(source, target, { overwrite: true });
  }
}

// A leading `/` means relative to `building-blocks/`, otherwise relative to the ingredients of the product
function sources(basket: Basket, source: string): string[] {
  if (source.startsWith("/")) return [join(basket.ingredients[0].rootFolder, source)];
  return basket.ingredients.map((ingredient) => ingredient.absolutePath(source)).filter((path) => existsSync(path));
}

// The zip contains the folder itself
function zipFolder(archive: string, folder: string): void {
  const files: Record<string, Uint8Array> = {};
  for (const entry of walkSync(archive, { includeDirs: false })) {
    files[relative(folder, entry.path)] = Deno.readFileSync(entry.path);
  }
  Deno.writeFileSync(`${archive}.zip`, zipSync(files));
}
