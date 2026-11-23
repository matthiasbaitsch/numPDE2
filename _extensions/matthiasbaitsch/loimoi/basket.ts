// The ingredients for one product, from one or more building blocks

import { BuildingBlock } from "./building-block.ts";
import { Folder, NameOptions, PathOptions } from "./folder.ts";

export class Basket {
  readonly blocks: BuildingBlock[]; // the building block of each ingredient
  readonly ingredients: Folder[]; // the ingredient folders, in the order given

  constructor(blocks: BuildingBlock[], ingredients: Folder[]) {
    this.blocks = blocks;
    this.ingredients = ingredients;
  }

  name(options: NameOptions = {}): string {
    return this.blocks[0].name(options);
  }

  title(): string | undefined {
    return this.blocks[0].title;
  }

  groupTitle(): string | undefined {
    return this.blocks[0].groupTitle;
  }

  isEmpty(): boolean {
    return this.ingredients.length === 0;
  }

  files(pattern: string, options: PathOptions = {}): string[] {
    return this.ingredients.flatMap((ingredient) => ingredient.files(pattern, options));
  }

  folders(pattern: string, options: PathOptions = {}): string[] {
    return this.ingredients.flatMap((ingredient) => ingredient.folders(pattern, options));
  }
}
