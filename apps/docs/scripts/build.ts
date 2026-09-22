import assert from "node:assert/strict";
import { cp, mkdir, readFile, readdir, rm, writeFile } from "node:fs/promises";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";

const appDirectory = dirname(dirname(fileURLToPath(import.meta.url)));
const sourceDirectory = join(appDirectory, "src");
const publicDirectory = join(appDirectory, "public");
const outputDirectory = join(appDirectory, "dist");

function normalizeBasePath(value: string): string {
  const segments = value.trim().split("/").filter(Boolean);

  if (segments.some((segment) => !/^[A-Za-z0-9._-]+$/.test(segment) || segment === "." || segment === "..")) {
    throw new Error(`Invalid Pages base path: ${value}`);
  }

  return segments.length === 0 ? "/" : `/${segments.join("/")}/`;
}

function inferredBasePath(): string {
  if (process.env.PAGES_BASE_PATH) return normalizeBasePath(process.env.PAGES_BASE_PATH);

  const [owner, repository] = (process.env.GITHUB_REPOSITORY ?? "").split("/");
  if (!owner || !repository || process.env.GITHUB_ACTIONS !== "true") return "/";

  return repository.toLowerCase() === `${owner}.github.io`.toLowerCase()
    ? "/"
    : normalizeBasePath(repository);
}

async function renderHtml(directory: string, replacements: ReadonlyMap<string, string>): Promise<number> {
  let renderedFiles = 0;

  for (const entry of await readdir(directory, { withFileTypes: true })) {
    const path = join(directory, entry.name);

    if (entry.isDirectory()) {
      renderedFiles += await renderHtml(path, replacements);
      continue;
    }

    if (!entry.name.endsWith(".html")) continue;

    let html = await readFile(path, "utf8");
    for (const [token, value] of replacements) html = html.replaceAll(token, value);
    assert(!html.includes("__BASE_PATH__"), `${path} contains an unresolved base-path token`);
    await writeFile(path, html);
    renderedFiles += 1;
  }

  return renderedFiles;
}

const basePath = inferredBasePath();
const repositoryUrl = process.env.GITHUB_REPOSITORY
  ? `https://github.com/${process.env.GITHUB_REPOSITORY}`
  : "https://github.com/MrDemonWolf/sonapin";

await rm(outputDirectory, { recursive: true, force: true });
await mkdir(outputDirectory, { recursive: true });
await cp(sourceDirectory, outputDirectory, { recursive: true });
await cp(publicDirectory, outputDirectory, { recursive: true });

const renderedFiles = await renderHtml(outputDirectory, new Map([
  ["__BASE_PATH__", basePath],
  ["__REPOSITORY_URL__", repositoryUrl],
]));

const moodScript = await Bun.build({
  entrypoints: [join(sourceDirectory, "moods.ts")],
  outdir: outputDirectory,
  target: "browser",
  minify: true,
});
assert(moodScript.success, "Failed to build the landing-page interaction");
await rm(join(outputDirectory, "moods.ts"));

assert(renderedFiles >= 6, "Expected the landing page and five supporting pages");
console.log(`Built ${renderedFiles} pages at ${basePath}`);
