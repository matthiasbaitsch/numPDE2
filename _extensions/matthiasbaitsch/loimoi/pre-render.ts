// Quarto runs this in the collection folder, before rendering

import { existsSync } from "jsr:@std/fs@1";
import { dirname } from "jsr:@std/path@1";
import { BuildingBlockTree } from "./building-block-tree.ts";
import { CollectionConfiguration } from "./collection-configuration.ts";
import { LinkPages } from "./link-pages.ts";
import { resolve } from "./utilities.ts";

const collectionFolder = Deno.cwd();
const tree = new BuildingBlockTree(resolve("building-blocks"));
const configuration = new CollectionConfiguration(collectionFolder, tree);

const outputFolder = configuration.outputFolder();
if (existsSync(outputFolder)) Deno.removeSync(outputFolder, { recursive: true });
Deno.mkdirSync(outputFolder);

const recipe = configuration.recipe();
const site = configuration.site();
const words = configuration.words();
for (const product of configuration.productConfigurations()) {
  recipe.run(tree.ingredients(product.ingredients), { ...words, ...product.placeholders(site) });
}

new LinkPages(dirname(collectionFolder), tree).write();
