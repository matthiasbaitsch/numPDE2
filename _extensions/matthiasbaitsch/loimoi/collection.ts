import { createHash } from "node:crypto";
import { dirname, join } from "jsr:@std/path@1";
import { Placeholders } from "./actions/action.ts";
import { CodeReplacement } from "./code-replacement.ts";
import { ProductConfiguration } from "./product-configuration.ts";
import { Recipe } from "./recipe.ts";
import { CollectionConfiguration } from "./collection-configuration.ts";
import { configFile, readYaml, replacePlaceholders, Yaml } from "./utilities.ts";

export class Collection {
  readonly configuration: CollectionConfiguration;
  private readonly collectionFolder: string;

  constructor(collectionFolder: string) {
    this.collectionFolder = collectionFolder;
    this.configuration = new CollectionConfiguration(collectionFolder);
  }

  outputFolder(): string {
    return join(this.collectionFolder, this.configuration.output);
  }

  renderFolder(): string {
    const project = (readYaml(join(this.collectionFolder, "_quarto.yml")).project ?? {}) as Yaml;
    return join(this.collectionFolder, (project["output-dir"] ?? ".") as string);
  }

  recipe(): Recipe {
    const file = configFile(`recipes/${this.configuration.recipe}.yml`, this.learningMaterialFolder());
    const replacements = CodeReplacement.read(configFile("code-replacements.yml", this.learningMaterialFolder()));
    return Recipe.read(file, this.configuration.options, this.outputFolder(), replacements);
  }

  words(): Record<string, string> {
    const file = configFile(`words/${this.configuration.lang}.yml`, this.learningMaterialFolder());
    return readYaml(file) as Record<string, string>;
  }

  // The words and the values of the product; without `group-title` if the product has none; `file-name` contains
  // placeholders itself
  placeholders(product: ProductConfiguration): Placeholders {
    const nn = String(product.number).padStart(2, "0");
    const nnName = `${nn}-${product.name}`;
    const values: Placeholders = {
      ...this.words(),
      "n": String(product.number),
      "nn": nn,
      "name": product.name,
      "nn-name": nnName,
      "hash": createHash("sha1").update(`87362-${nnName}`).digest("hex").slice(0, 8),
      "product-title": product.title,
      "full-title": product.fullTitle,
      "site": this.configuration.site,
    };
    if (product.groupTitle !== undefined) values["group-title"] = product.groupTitle;
    return { ...values, "file-name": replacePlaceholders(this.configuration.fileName, values) };
  }

  private learningMaterialFolder(): string {
    return dirname(this.collectionFolder);
  }
}
