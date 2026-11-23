import { createHash } from "node:crypto";
import { Placeholders } from "./actions/action.ts";
import { BuildingBlockTree } from "./building-block-tree.ts";
import { slug, Yaml } from "./utilities.ts";

export type ProductNaming = "path" | "titles";

export class ProductConfiguration {
  readonly number: number;
  readonly name: string;
  readonly title: string;
  readonly groupTitle?: string;
  readonly fullTitle: string;
  readonly ingredients: string[];

  // `entry`: an entry of `products` in `loimoi.yml`; name and titles not given come from the first building block,
  // the name from its path or, with `productNaming` `titles`, from the titles
  constructor(entry: Yaml, number: number, tree: BuildingBlockTree, productNaming: ProductNaming) {
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
    this.name = name ?? (productNaming === "titles" ? slug(...titles) : basket.name());
  }

  // Without `group-title` and `site` if they are missing, so `${site}` stays visible in the output
  placeholders(site?: string): Placeholders {
    const nnName = `${String(this.number).padStart(2, "0")}-${this.name}`;
    const values: Placeholders = {
      "n": String(this.number),
      "name": this.name,
      "nn-name": nnName,
      "hash": createHash("sha1").update(`87362-${nnName}`).digest("hex").slice(0, 8),
      "product-title": this.title,
      "full-title": this.fullTitle,
    };
    if (this.groupTitle !== undefined) values["group-title"] = this.groupTitle;
    if (site !== undefined) values["site"] = site;
    return values;
  }
}
