import { Action, Placeholders } from "./actions/action.ts";
import { Archive } from "./actions/archive.ts";
import { QuartoFile } from "./actions/quarto-file.ts";
import { Basket } from "./basket.ts";
import { CodeReplacement } from "./code-replacement.ts";
import { ProductFolder } from "./product-folder.ts";
import { existsSync } from "jsr:@std/fs@1";
import { join } from "jsr:@std/path@1";
import { readYaml, Yaml } from "./utilities.ts";

interface Option {
  values: string[];
  default: string;
}

export class Recipe {
  readonly actions: Action[];
  readonly folder: string;

  constructor(actions: Action[], folder: string) {
    this.actions = actions;
    this.folder = folder;
  }

  // Only the actions whose `when` matches the options
  static read(
    file: string,
    options: Record<string, string>,
    folder: string,
    replacements: CodeReplacement[],
  ): Recipe {
    if (!existsSync(file)) throw new Error(`Recipe not found: ${file}`);
    const yaml = readYaml(file);
    const chosen = choose((yaml.options ?? {}) as Record<string, Option>, options, file);
    const matches = (entry: Yaml) =>
      Object.entries((entry.when ?? {}) as Yaml).every(([option, value]) => chosen[option] === value);
    const quartoFiles = ((yaml["quarto-files"] ?? []) as Yaml[]).filter(matches);
    const archives = ((yaml.archives ?? []) as Yaml[]).filter(matches);
    const actions = [
      ...quartoFiles.map((entry) => new QuartoFile(entry, replacements)),
      ...archives.map((entry) => new Archive(entry)),
    ];
    return new Recipe(actions, folder);
  }

  // In the folder of the product; the placeholders from `provides` are known before the first action runs
  run(basket: Basket, placeholders: Placeholders): void {
    const folder = new ProductFolder(join(this.folder, placeholders["nn-name"]));
    Deno.mkdirSync(folder.folder);
    const values = { ...placeholders };
    for (const action of this.actions) {
      if (action.provides !== undefined) values[action.provides] = action.file(values);
    }
    for (const action of this.actions) action.run(basket, values, folder);
  }
}

// Given options checked against the declared ones, defaults for the others
function choose(declared: Record<string, Option>, given: Record<string, string>, file: string) {
  for (const [name, value] of Object.entries(given)) {
    if (!(name in declared)) throw new Error(`Unknown option ${name} for recipe ${file}`);
    if (!declared[name].values.includes(value)) throw new Error(`Unknown value ${value} of option ${name}`);
  }
  const chosen: Record<string, string> = {};
  for (const [name, option] of Object.entries(declared)) chosen[name] = given[name] ?? option.default;
  return chosen;
}
