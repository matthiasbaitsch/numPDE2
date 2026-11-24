import { existsSync } from "jsr:@std/fs@1";
import { join, relative } from "jsr:@std/path@1";
import { QuartoFile } from "./actions/quarto-file.ts";
import { Collection } from "./collection.ts";
import { replacePlaceholders } from "./utilities.ts";

interface LinkedFile {
  label: string;
  file: string; // rendered HTML file, absolute
}

interface ProductLinks {
  title: string;
  files: LinkedFile[];
}

interface CollectionLinks {
  name: string;
  site: string;
  products: ProductLinks[];
}

// Pages with the links to the products of all collections, for the teacher, not published
export class LinkPages {
  readonly learningMaterialFolder: string;

  constructor(learningMaterialFolder: string) {
    this.learningMaterialFolder = learningMaterialFolder;
  }

  // Links into the rendered output, relative to the learning material folder
  localPage(): string {
    return this.page("Links", (_, file) => relative(this.learningMaterialFolder, file));
  }

  // The published URLs
  sitePage(): string {
    return this.page("Links (site)", siteUrl);
  }

  write(): void {
    Deno.writeTextFileSync(join(this.learningMaterialFolder, "links.html"), this.localPage());
    Deno.writeTextFileSync(join(this.learningMaterialFolder, "links-site.html"), this.sitePage());
  }

  // One table per collection, one row per product; `href` makes the link to a rendered file
  private page(title: string, href: (collection: CollectionLinks, file: string) => string): string {
    const sections = this.collections().map((collection) => {
      const rows = collection.products.map((product) => {
        const cells = product.files.map((file) =>
          `<td><a href="${escape(href(collection, file.file))}">${escape(file.label)}</a></td>`
        );
        return `<tr><td>${escape(product.title)}</td>${cells.join("")}</tr>`;
      });
      return `<h2>${escape(collection.name)}</h2>\n<table>\n${rows.join("\n")}\n</table>`;
    });
    return `<!doctype html>
<html>
<head>
<meta charset="utf-8">
<title>${title}</title>
<style>
  body { font-family: system-ui, sans-serif; margin: 2rem; }
  td { padding: 0.3rem 1rem 0.3rem 0; }
</style>
</head>
<body>
${sections.join("\n\n")}
</body>
</html>
`;
  }

  // Collections: the folders with a `_quarto.yml`, in name order
  private collections(): CollectionLinks[] {
    const names = [...Deno.readDirSync(this.learningMaterialFolder)]
      .filter((entry) => entry.isDirectory && existsSync(join(this.learningMaterialFolder, entry.name, "_quarto.yml")))
      .map((entry) => entry.name)
      .sort();
    return names.map((name) => this.collection(name));
  }

  private collection(name: string): CollectionLinks {
    const collectionFolder = join(this.learningMaterialFolder, name);
    const collection = new Collection(collectionFolder);
    const linked = collection.recipe().actions.filter((action): action is QuartoFile =>
      action instanceof QuartoFile && action.link !== undefined
    );
    // `c/` as rendered by Quarto
    const renderedFolder = join(collection.renderFolder(), relative(collectionFolder, collection.outputFolder()));
    const products = collection.configuration.products.map((product) => {
      const values = collection.placeholders(product);
      const files = linked.map((action) => ({
        label: replacePlaceholders(action.link as string, values),
        file: join(renderedFolder, values["nn-name"], action.file(values).replace(/\.qmd$/, ".html")),
      }));
      return { title: `${String(product.number).padStart(2, "0")} ${product.fullTitle}`, files };
    });
    return { name, site: collection.configuration.site, products };
  }
}

// `site` stands for the folder `__output/`
function siteUrl(collection: CollectionLinks, file: string): string {
  const parts = file.split("/__output/");
  if (parts.length !== 2) throw new Error(`No folder __output in ${file}`);
  return `${collection.site}/${parts[1]}`;
}

function escape(text: string): string {
  return text.replaceAll("&", "&amp;").replaceAll("<", "&lt;").replaceAll(">", "&gt;").replaceAll('"', "&quot;");
}
