import { readYaml, Yaml } from "./utilities.ts";

export class CodeReplacement {
  readonly steps?: string[]; // all steps if missing
  readonly languages?: string[]; // all languages if missing
  readonly replace: string;
  readonly with: string;

  constructor(settings: Yaml) {
    const scope = (settings.scope ?? {}) as Yaml;
    this.steps = scope.steps as string[] | undefined;
    this.languages = scope.languages as string[] | undefined;
    this.replace = settings.replace as string;
    this.with = settings.with as string;
  }

  static read(file: string): CodeReplacement[] {
    const entries = (readYaml(file).replacements ?? []) as Yaml[];
    return entries.map((entry) => new CodeReplacement(entry));
  }

  applies(step: string, language: string): boolean {
    return (this.steps?.includes(step) ?? true) && (this.languages?.includes(language) ?? true);
  }

  apply(line: string): string {
    return line.replaceAll(this.replace, this.with);
  }
}
