import { basename, dirname, join } from "jsr:@std/path@1";
import { BuildingBlockTree } from "./building-block-tree.ts";
import { ProductConfiguration, ProductNaming } from "./product-configuration.ts";
import { Recipe } from "./recipe.ts";
import { configFile, conventions, gitHubPages, mergeYamlAlongPath, readYaml, Yaml } from "./utilities.ts";

export class CollectionConfiguration {
  private readonly collectionFolder: string;

  private readonly conventions: Yaml;
  private readonly settings: Yaml;

  private readonly firstNumber: number;
  private readonly outputFolderName: string;
  private readonly productNaming: ProductNaming;
  private readonly tree: BuildingBlockTree;

  constructor(collectionFolder: string, tree: BuildingBlockTree) {
    this.collectionFolder = collectionFolder;
    this.conventions = conventions();
    this.settings = mergeYamlAlongPath(this.learningMaterialFolder(), this.collectionFolderName(), "loimoi.yml");
    this.firstNumber = (this.settings["first-number"] ?? 1) as number;
    this.outputFolderName = (this.settings.output ?? "c") as string;
    this.productNaming = (this.settings["product-naming"] ?? "path") as ProductNaming;
    if (this.productNaming !== "path" && this.productNaming !== "titles") {
      throw new Error(`product-naming must be path or titles, not ${this.productNaming}`);
    }
    this.tree = tree;
  }

  outputFolder(): string {
    return join(this.collectionFolder, this.outputFolderName);
  }

  site(): string | undefined {
    return (this.settings.site as string | undefined) ?? gitHubPages(this.collectionFolder);
  }

  recipe(): Recipe {
    const file = configFile(`recipes/${this.recipeName()}.yml`, this.learningMaterialFolder());
    const options = (this.settings.options ?? {}) as Record<string, string>;
    return Recipe.read(file, options, this.outputFolder());
  }

  // Words for recipes and steps from `words/<language>.yml`; the language from `lang` in `loimoi.yml`, otherwise
  // from the name of the collection
  words(): Record<string, string> {
    const languages = (this.conventions["collection-languages"] ?? {}) as Record<string, string>;
    const language = (this.settings.lang as string | undefined) ?? languages[this.collectionFolderName()] ?? "en";
    return readYaml(configFile(`words/${language}.yml`, this.learningMaterialFolder())) as Record<string, string>;
  }

  productConfigurations(): ProductConfiguration[] {
    const entries = this.productEntries();
    return entries.map((entry, i) =>
      new ProductConfiguration(entry, this.firstNumber + i, this.tree, this.productNaming)
    );
  }

  private productEntries(): Yaml[] {
    if (this.settings.products !== undefined) {
      return this.settings.products as Yaml[];
    } else {
      const paths = this.tree.defaultPaths(this.ingredientFolderName());
      return paths.map((ingredients) => ({ ingredients }));
    }
  }

  private ingredientFolderName(): string {
    const folders = (this.conventions["ingredient-folders"] ?? {}) as Record<string, Record<string, string>>;
    const name = folders[this.recipeName()]?.[this.collectionFolderName()];
    if (name === undefined) {
      throw new Error(`No ingredient folder for collection ${this.collectionFolderName()} in conventions.yml`);
    }
    return name;
  }

  private collectionFolderName(): string {
    return basename(this.collectionFolder);
  }

  // Where Quarto writes the rendered collection: `output-dir` from `_quarto.yml`
  renderFolder(): string {
    const file = join(this.collectionFolder, "_quarto.yml");
    const project = (readYaml(file).project ?? {}) as Yaml;
    const outputDir = project["output-dir"] as string | undefined;
    if (outputDir === undefined) throw new Error(`No output-dir in ${file}`);
    return join(this.collectionFolder, outputDir);
  }

  private learningMaterialFolder(): string {
    return dirname(this.collectionFolder);
  }

  private recipeName(): string {
    const collectionRecipes = (this.conventions["collection-recipes"] ?? {}) as Record<string, string>;
    const name = (this.settings.recipe as string | undefined) ?? collectionRecipes[this.collectionFolderName()];
    if (name === undefined) {
      throw new Error(`No recipe for collection ${this.collectionFolderName()} in conventions.yml`);
    }
    return name;
  }
}
