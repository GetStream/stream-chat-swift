// Shared helpers: argument parsing, loading the upstream sources from a clone, and the libraries.
import { existsSync, readdirSync, readFileSync } from "node:fs";
import path from "node:path";
import { fileURLToPath, pathToFileURL } from "node:url";

export const GENERATOR_DIR = path.dirname(fileURLToPath(import.meta.url));

/** `--clone <dir> --out <file>` style arguments. */
export function parseArgs(required: string[]): Record<string, string> {
  const out: Record<string, string> = {};
  const argv = process.argv.slice(2);
  for (let i = 0; i < argv.length; i++) {
    const key = argv[i];
    if (!key.startsWith("--")) throw new Error(`Unexpected argument ${key}`);
    out[key.slice(2)] = argv[++i];
  }
  for (const key of required) {
    if (!out[key]) throw new Error(`Missing --${key}`);
  }
  out.clone = path.resolve(out.clone);
  return out;
}

export function readJSON(file: string): any {
  return JSON.parse(readFileSync(file, "utf8"));
}

/** The upstream lang-core modules, imported straight from the clone's TypeScript sources. */
export async function loadUpstream(clone: string) {
  const src = path.join(clone, "packages/lang-core/src");
  if (!existsSync(src)) throw new Error(`No lang-core sources under ${clone}`);
  const load = (file: string) => import(pathToFileURL(path.join(src, file)).href);
  const v1 = existsSync(path.join(src, "functions.ts"));
  return {
    /** True from OpenUI 1.0 on (functions, actions, entry rule, `complete`). */
    v1,
    parser: await load("parser/parser.ts"),
    merge: await load("parser/merge.ts"),
    prompt: await load("parser/prompt.ts"),
    evaluator: await load("runtime/evaluator.ts"),
    evaluateTree: await load("runtime/evaluate-tree.ts"),
    reactive: await load("reactive.ts"),
    library: v1 ? await load("library.ts") : undefined,
    promptOptions: await import(
      pathToFileURL(path.join(clone, "packages/react-ui/src/genui-lib/prompt-options/index.ts")).href
    ),
  };
}

export type Upstream = Awaited<ReturnType<typeof loadUpstream>>;

/** The library spec files the fixtures are generated against. */
export function librarySpecs(clone: string): Record<string, any> {
  const specs: Record<string, any> = {
    chat: readJSON(path.join(clone, "docs/generated/chat-library.spec.json")),
    playground: readJSON(path.join(clone, "docs/generated/playground-library.spec.json")),
  };
  const specLibrary = path.join(clone, "spec/fixtures/1.0/library.json");
  if (existsSync(specLibrary)) specs.spec = readJSON(specLibrary);
  return specs;
}

export const MINI_SCHEMA = {
  $defs: {
    Stack: { properties: { children: {} }, required: ["children"] },
    Title: { properties: { text: { type: "string" } }, required: ["text"] },
  },
};

/** Implementations of the spec library's functions, which a runner supplies (conformance.test.ts). */
export const SPEC_FUNCTIONS: Record<string, (args: Record<string, unknown>) => unknown> = {
  Upper: ({ text }) => String(text ?? "").toUpperCase(),
};

/** The spec library's `functions` / `actions` for an EvaluationContext, as conformance.test.ts builds them. */
export function specRuntime(spec: any) {
  const functions = Object.fromEntries(
    Object.entries<any>(spec.schema.functions ?? {}).map(([name, f]) => [name, { ...f, fn: SPEC_FUNCTIONS[name] }]),
  );
  return { functions, actions: spec.schema.actions };
}

/** spec/fixtures/1.0/<area>/<case> folders, sorted like the upstream runner. */
export function specFixtureCases(clone: string): { id: string; files: Record<string, string> }[] {
  const root = path.join(clone, "spec/fixtures/1.0");
  if (!existsSync(root)) return [];
  const dirs = (dir: string) =>
    readdirSync(dir, { withFileTypes: true })
      .filter((d) => d.isDirectory())
      .map((d) => d.name)
      .sort();
  const out: { id: string; files: Record<string, string> }[] = [];
  for (const area of dirs(root)) {
    for (const name of dirs(path.join(root, area))) {
      const dir = path.join(root, area, name);
      const files = Object.fromEntries(readdirSync(dir).map((f) => [f, readFileSync(path.join(dir, f), "utf8")]));
      out.push({ id: `${area}/${name}`, files });
    }
  }
  return out;
}
