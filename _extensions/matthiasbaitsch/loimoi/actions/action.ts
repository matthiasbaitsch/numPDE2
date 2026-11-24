import { Basket } from "../basket.ts";
import { ProductFolder } from "../product-folder.ts";
import { Yaml } from "../utilities.ts";

export type Placeholders = Record<string, string>;

export abstract class Action {
  readonly name: string;
  readonly provides?: string; // placeholder whose value is the file this action writes

  constructor(settings: Yaml) {
    this.name = settings.name as string;
    this.provides = settings.provides as string | undefined;
  }

  // The file this action writes, relative to the folder
  abstract file(placeholders: Placeholders): string;

  abstract run(basket: Basket, placeholders: Placeholders, folder: ProductFolder): void;
}
