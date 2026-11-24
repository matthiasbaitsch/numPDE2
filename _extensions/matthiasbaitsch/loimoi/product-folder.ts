import { ensureDirSync, existsSync, walkSync } from "jsr:@std/fs@1";
import { dirname, join, relative } from "jsr:@std/path@1";
import { unzipSync, zipSync } from "npm:fflate@0.8";

// The folder of a product in `c/`; writing a file whose name is taken by a different file is an error, as several
// building blocks may bring a file of the same name
export class ProductFolder {
  readonly folder: string;

  constructor(folder: string) {
    this.folder = folder;
  }

  path(path: string): string {
    return join(this.folder, path);
  }

  sub(path: string): ProductFolder {
    return new ProductFolder(this.path(path));
  }

  copy(source: string, path: string): void {
    this.write(Deno.readFileSync(source), path);
  }

  write(content: Uint8Array, path: string): void {
    const target = this.path(path);
    if (existsSync(target) && !sameBytes(content, Deno.readFileSync(target))) {
      throw new Error(`Different files with the same name: ${path}`);
    }
    ensureDirSync(dirname(target));
    Deno.writeFileSync(target, content);
  }

  // An existing zip is compared by its content, the bytes of a zip contain timestamps
  zip(files: Record<string, Uint8Array>, path: string): void {
    const target = this.path(path);
    if (existsSync(target)) {
      if (!sameFiles(unzipSync(Deno.readFileSync(target)), files)) {
        throw new Error(`Different files with the same name: ${path}`);
      }
    } else {
      Deno.writeFileSync(target, zipSync(files));
    }
  }

  // `path.zip` containing the folder itself; the folder is removed
  zipFolder(path: string): void {
    const files: Record<string, Uint8Array> = {};
    for (const entry of walkSync(this.path(path), { includeDirs: false })) {
      files[relative(this.folder, entry.path)] = Deno.readFileSync(entry.path);
    }
    this.zip(files, `${path}.zip`);
    Deno.removeSync(this.path(path), { recursive: true });
  }
}

function sameFiles(a: Record<string, Uint8Array>, b: Record<string, Uint8Array>): boolean {
  const names = Object.keys(a).sort();
  const sameNames = names.join("\n") === Object.keys(b).sort().join("\n");
  return sameNames && names.every((name) => sameBytes(a[name], b[name]));
}

function sameBytes(a: Uint8Array, b: Uint8Array): boolean {
  return a.length === b.length && a.every((byte, i) => byte === b[i]);
}
