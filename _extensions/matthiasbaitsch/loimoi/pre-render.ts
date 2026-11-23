// Quarto runs this in the collection folder, before rendering

import { existsSync } from "jsr:@std/fs@1";
import { dirname } from "jsr:@std/path@1";
import { CollectionConfiguration } from "./collection-configuration.ts";
import { LinkPages } from "./link-pages.ts";

const collectionFolder = Deno.cwd();
const configuration = new CollectionConfiguration(collectionFolder);
const tree = configuration.tree;

const outputFolder = configuration.outputFolder();
if (existsSync(outputFolder)) Deno.removeSync(outputFolder, { recursive: true });
Deno.mkdirSync(outputFolder);

const recipe = configuration.recipe();
const site = configuration.site();
const words = configuration.words();
for (const product of configuration.productConfigurations()) {
  recipe.run(tree.ingredients(product.ingredients), { ...words, ...product.placeholders(site) });
}

new LinkPages(dirname(collectionFolder)).write();
