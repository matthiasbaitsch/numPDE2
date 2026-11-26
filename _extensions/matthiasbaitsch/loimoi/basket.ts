// The ingredients for one product, from one or more building blocks

import { BuildingBlock } from "./building-block.ts";
import { Folder, NameOptions, PathOptions } from "./folder.ts";
import { QmdDocument } from "./qmd-document.ts";

export class Basket {
  readonly blocks: BuildingBlock[]; // the building block of each ingredient
  readonly ingredients: Folder[]; // the ingredient folders, in the order given
  private qmd?: QmdDocument; // read on first use

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

  // The `.qmd` files of all ingredients as one document, read and validated once for all actions
  document(): QmdDocument {
    if (this.qmd === undefined) {
      this.qmd = QmdDocument.read(...this.files("*.qmd", { absolute: true }));
      this.qmd.validate();
    }
    return this.qmd;
  }

  files(pattern: string, options: PathOptions = {}): string[] {
    return this.ingredients.flatMap((ingredient) => ingredient.files(pattern, options));
  }

  folders(pattern: string, options: PathOptions = {}): string[] {
    return this.ingredients.flatMap((ingredient) => ingredient.folders(pattern, options));
  }
}
