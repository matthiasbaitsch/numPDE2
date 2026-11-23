import { Folder } from "./folder.ts";
import { mergeYamlAlongPath } from "./utilities.ts";

export class BuildingBlock extends Folder {
  readonly title?: string;
  readonly groupTitle?: string;

  constructor(rootFolder: string, path: string) {
    super(rootFolder, path);
    const about = mergeYamlAlongPath(rootFolder, path, "about.yml");
    this.title = about["block-title"] as string | undefined;
    this.groupTitle = about["group-title"] as string | undefined;
  }
}
