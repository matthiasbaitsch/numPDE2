import { dirname, relative } from "jsr:@std/path@1";
import { walkSync } from "jsr:@std/fs@1";
import { Basket } from "./basket.ts";
import { BuildingBlock } from "./building-block.ts";
import { Folder } from "./folder.ts";

export class BuildingBlockTree {
  readonly rootFolder: string;

  constructor(rootFolder: string) {
    this.rootFolder = rootFolder;
  }

  ingredients(paths: string[]): Basket {
    const ingredients = paths.map((path) => new Folder(this.rootFolder, path));
    const blocks = paths.map((path) => new BuildingBlock(this.rootFolder, dirname(path)));
    return new Basket(blocks, ingredients);
  }

  defaultPaths(folderName: string): string[][] {
    const hidden = /\/[_.][^/]*$/; // last part of the path starts with `_` or `.`
    const paths: string[] = [];
    for (const folder of walkSync(this.rootFolder, { includeFiles: false, skip: [hidden] })) {
      if (folder.name === folderName) paths.push(relative(this.rootFolder, folder.path));
    }
    return paths.sort().map((path) => [path]);
  }
}
