import { join, relative } from "jsr:@std/path@1";
import { existsSync, expandGlobSync } from "jsr:@std/fs@1";

export interface NameOptions {
  // Use full path or folder name only
  full?: boolean;
  // Seperator
  sep?: string;
}

export interface PathOptions {
  absolute?: boolean;
}

export class Folder {
  readonly rootFolder: string;
  readonly path: string; // relative to `rootFolder`

  constructor(rootFolder: string, path: string) {
    this.rootFolder = rootFolder;
    this.path = path;
    if (!existsSync(this.absolutePath())) throw new Error(`Folder not found: ${path}`);
  }

  absolutePath(path = ""): string {
    return join(this.rootFolder, this.path, path);
  }

  name({ full = true, sep = "-" }: NameOptions = {}): string {
    const parts = this.path.split("/").map((part) => part.replace(/^\d+-/, ""));
    const used = full ? parts : parts.slice(-1);
    return used.join(sep);
  }

  files(pattern: string, options: PathOptions = {}): string[] {
    return this.find(pattern, false, options);
  }

  folders(pattern: string, options: PathOptions = {}): string[] {
    return this.find(pattern, true, options);
  }

  private find(pattern: string, directories: boolean, { absolute = false }: PathOptions): string[] {
    const paths: string[] = [];
    for (const entry of expandGlobSync(pattern, { root: this.absolutePath() })) {
      const path = absolute ? entry.path : relative(this.rootFolder, entry.path);
      if (entry.isDirectory === directories) paths.push(path);
    }
    return paths.sort();
  }
}
