// Quarto runs this in the collection folder, before rendering

import { existsSync } from "jsr:@std/fs@1";
import { dirname } from "jsr:@std/path@1";
import { Collection } from "./collection.ts";
import { LinkPages } from "./link-pages.ts";

const collectionFolder = Deno.cwd();
const collection = new Collection(collectionFolder);
const tree = collection.configuration.tree;

const outputFolder = collection.outputFolder();
if (existsSync(outputFolder)) Deno.removeSync(outputFolder, { recursive: true });
Deno.mkdirSync(outputFolder);

const recipe = collection.recipe();
for (const product of collection.configuration.products) {
  recipe.run(tree.ingredients(product.ingredients), collection.placeholders(product));
}

new LinkPages(dirname(collectionFolder)).write();
