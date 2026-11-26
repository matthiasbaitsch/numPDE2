import { BuildingBlockTree } from "./building-block-tree.ts";
import { replacePlaceholders, slug, Yaml } from "./utilities.ts";

export class ProductConfiguration {
  readonly number: number;
  readonly name: string;
  readonly title: string;
  readonly groupTitle?: string;
  readonly fullTitle: string;
  readonly ingredients: string[];
  readonly blockPlaceholders: Record<string, string>;

  // `entry`: an entry of `products` in `loimoi.yml`; name and titles not given come from the first building block,
  // the name from `nameTemplate` with the placeholders of the building block
  constructor(entry: Yaml, number: number, tree: BuildingBlockTree, nameTemplate: string) {
    this.number = number;
    this.ingredients = entry.ingredients as string[];
    const basket = tree.ingredients(this.ingredients);
    const name = entry.name as string | undefined;
    const title = (entry["product-title"] as string | undefined) ?? basket.title();
    if (title === undefined) {
      const product = name ?? basket.name();
      throw new Error(`No title for product ${product}: set product-title in loimoi.yml or block-title in about.yml`);
    }
    this.title = title;
    this.groupTitle = (entry["group-title"] as string | undefined) ?? basket.groupTitle();
    const titles = [this.groupTitle, this.title].filter((part) => part !== undefined);
    this.fullTitle = titles.join(": ");
    this.blockPlaceholders = {
      "block-path": basket.name(),
      "block-folder": basket.name({ full: false }),
      "title-slug": slug(...titles),
    };
    this.name = name ?? replacePlaceholders(nameTemplate, this.blockPlaceholders);
  }
}
