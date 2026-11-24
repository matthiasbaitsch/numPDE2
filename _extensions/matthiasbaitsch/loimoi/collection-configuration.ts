import { existsSync } from "jsr:@std/fs@1";
import { basename, dirname, join } from "jsr:@std/path@1";
import { BuildingBlockTree } from "./building-block-tree.ts";
import { ProductConfiguration, ProductNaming } from "./product-configuration.ts";
import { conventions, gitHubPages, mergeYamlAlongPath, readYaml, resolve, Yaml } from "./utilities.ts";

const settingsFile = new URL("./config/settings.yml", import.meta.url).pathname;

// The configuration of a collection: `loimoi.yml` merged along the path, every default filled in; all checks here
export class CollectionConfiguration {
  readonly output: string;
  readonly fileName: string;
  readonly options: Record<string, string>;
  readonly lang: string;
  readonly site: string;
  readonly tree: BuildingBlockTree;
  readonly recipe: string;
  readonly products: ProductConfiguration[];

  constructor(collectionFolder: string) {
    const learningMaterialFolder = dirname(collectionFolder);
    const name = basename(collectionFolder);
    const rules = conventions();
    const defaults = readYaml(settingsFile);
    const own = mergeYamlAlongPath(learningMaterialFolder, name, "loimoi.yml");

    const unknown = Object.keys(own).filter((key) => !(key in defaults));
    if (unknown.length > 0) throw new Error(`Unknown settings in loimoi.yml: ${unknown.join(", ")}`);

    const yaml = { ...defaults, ...own };

    this.output = yaml.output as string;
    this.fileName = yaml["file-name"] as string;
    this.options = yaml.options as Record<string, string>;

    const productNaming = yaml["product-naming"] as ProductNaming;
    if (productNaming !== "path" && productNaming !== "titles") {
      throw new Error(`product-naming must be path or titles, not ${productNaming}`);
    }

    const languages = (rules["collection-languages"] ?? {}) as Record<string, string>;
    this.lang = (yaml.lang ?? languages[name] ?? "en") as string;

    this.site = (yaml.site ?? gitHubPages(collectionFolder) ?? "site-not-set") as string;

    let buildingBlocksFolder: string;
    if (yaml["building-blocks"] === null) {
      const names = (rules.names ?? {}) as Record<string, string[]>;
      buildingBlocksFolder = resolve(names["building-blocks"] ?? [], collectionFolder);
    } else {
      buildingBlocksFolder = join(learningMaterialFolder, yaml["building-blocks"] as string);
      if (!existsSync(buildingBlocksFolder)) {
        throw new Error(`building-blocks in loimoi.yml: no folder ${buildingBlocksFolder}`);
      }
    }
    this.tree = new BuildingBlockTree(buildingBlocksFolder);

    const recipes = (rules["collection-recipes"] ?? {}) as Record<string, string>;
    const recipe = (yaml.recipe as string | null) ?? recipes[name];
    if (recipe === undefined) throw new Error(`No recipe for collection ${name} in conventions.yml`);
    this.recipe = recipe;

    let entries: Yaml[];
    if (yaml.products !== null) {
      entries = yaml.products as Yaml[];
    } else {
      const folders = (rules["ingredient-folders"] ?? {}) as Record<string, Record<string, string>>;
      const ingredientFolder = folders[recipe]?.[name];
      if (ingredientFolder === undefined) {
        throw new Error(`No ingredient folder for collection ${name} in conventions.yml`);
      }
      entries = this.tree.defaultPaths(ingredientFolder).map((ingredients) => ({ ingredients }));
    }
    const firstNumber = yaml["first-number"] as number;
    this.products = entries.map((entry, i) =>
      new ProductConfiguration(entry, firstNumber + i, this.tree, productNaming)
    );
  }
}
