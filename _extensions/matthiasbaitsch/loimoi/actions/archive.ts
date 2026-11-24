import { existsSync } from "jsr:@std/fs@1";
import { basename, join, relative } from "jsr:@std/path@1";
import { Basket } from "../basket.ts";
import { ProductFolder } from "../product-folder.ts";
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

  // Zips the folder `name`, which other actions may have filled, with the files of `add`
  run(basket: Basket, placeholders: Placeholders, folder: ProductFolder): void {
    const name = replacePlaceholders(this.name, placeholders);
    for (const entry of this.add) {
      const [source, newName] = typeof entry === "string" ? [entry, undefined] : Object.entries(entry)[0];
      const path = join(name, replacePlaceholders(newName ?? basename(source), placeholders));
      for (const file of sources(basket, source)) copy(file, folder, path);
    }
    folder.zipFolder(name);
  }
}

// A folder only with its files for students; a file as it is, even if its name starts with `_`
function copy(source: string, folder: ProductFolder, path: string): void {
  if (Deno.statSync(source).isDirectory) {
    for (const file of studentFiles(source)) folder.copy(file, join(path, relative(source, file)));
  } else {
    folder.copy(source, path);
  }
}

// A leading `/` means relative to `building-blocks/`, otherwise relative to the ingredients of the product
function sources(basket: Basket, source: string): string[] {
  if (source.startsWith("/")) return [join(basket.ingredients[0].rootFolder, source)];
  return basket.ingredients.map((ingredient) => ingredient.absolutePath(source)).filter((path) => existsSync(path));
}
