import { existsSync, walkSync } from "jsr:@std/fs@1";
import { dirname, join } from "jsr:@std/path@1";
import { parse } from "jsr:@std/yaml@1";

export type Yaml = Record<string, unknown>;

export function readYaml(file: string): Yaml {
  return existsSync(file) ? parse(Deno.readTextFileSync(file)) as Yaml : {};
}

// Merges the files with the given name from `rootFolder` down to `rootFolder/path`; later ones override earlier ones
export function mergeYamlAlongPath(rootFolder: string, path: string, fileName: string): Yaml {
  let folder = rootFolder;
  let merged = readYaml(join(folder, fileName));
  for (const part of path.split("/")) {
    folder = join(folder, part);
    merged = { ...merged, ...readYaml(join(folder, fileName)) };
  }
  return merged;
}

// The files below `folder` meant for students: without names starting with `_` or `.` and without Quarto's
// `…_files` folders
export function studentFiles(folder: string): string[] {
  const excluded = /\/([_.][^/]*|[^/]*_files)$/;
  return [...walkSync(folder, { includeDirs: false, skip: [excluded] })].map((entry) => entry.path);
}

const umlauts: Record<string, string> = { "ä": "ae", "ö": "oe", "ü": "ue", "ß": "ss" };

// `Stabtragwerke`, `Stabendkräfte` becomes `stabtragwerke-stabendkraefte`
export function slug(...parts: string[]): string {
  return parts.join(" ").toLowerCase()
    .replace(/[äöüß]/g, (letter) => umlauts[letter])
    .replace(/[^a-z0-9]+/g, "-")
    .replace(/^-|-$/g, "");
}

// `${key}` replaced by its value; unknown keys stay unchanged
export function replacePlaceholders(text: string, values: Record<string, string>): string {
  return text.replace(/\$\{([\w-]+)\}/g, (match, key) => values[key] ?? match);
}

const builtInConfig = new URL("./config/", import.meta.url).pathname;

// The user's file in `learning-material/_loimoi/` if it exists, otherwise the built-in one
export function configFile(path: string, learningMaterialFolder: string): string {
  const own = join(learningMaterialFolder, "_loimoi", path);
  return existsSync(own) ? own : join(builtInConfig, path);
}

// Upward from `folder`, the first folder containing one of `names`; error if none or several in the same folder
export function resolve(names: string[], folder: string): string {
  const matches = ancestors(folder)
    .map((folder) => names.map((name) => join(folder, name)).filter((path) => existsSync(path)))
    .find((found) => found.length > 0) ?? [];
  if (matches.length !== 1) {
    throw new Error(`Expected one of ${names.join(", ")} upward from ${folder}, found ${matches.length}`);
  }
  return matches[0];
}

// The first `_loimoi/conventions.yml` upward from the working directory, otherwise the built-in one
export function conventions(): Yaml {
  const files = ancestors(Deno.cwd()).map((folder) => join(folder, "_loimoi/conventions.yml"));
  return readYaml(files.find((file) => existsSync(file)) ?? join(builtInConfig, "conventions.yml"));
}

// `folder` and all folders above it, up to the root
function ancestors(folder: string): string[] {
  const parent = dirname(folder);
  return parent === folder ? [folder] : [folder, ...ancestors(parent)];
}

// `git@github.com:user/repo.git` or `https://github.com/user/repo` → `https://user.github.io/repo`;
// undefined without Git or without a GitHub remote
export function gitHubPages(folder: string): string | undefined {
  try {
    const output = new Deno.Command("git", { args: ["remote", "get-url", "origin"], cwd: folder }).outputSync();
    const url = new TextDecoder().decode(output.stdout).trim();
    const match = url.match(/github\.com[:/]([^/]+)\/(.+?)(\.git)?$/);
    return output.success && match !== null ? `https://${match[1]}.github.io/${match[2]}` : undefined;
  } catch {
    return undefined;
  }
}
