// Node module hooks that let the generator run upstream OpenUI TypeScript straight from a clone:
// - extensionless relative imports resolve to `.ts` / `index.ts` (upstream uses bundler-style imports);
// - `lang-core/src/telemetry/runtime.ts` is replaced by a no-op stub (same as the original harness);
// - bare specifiers (zod) resolve from this generator's node_modules, so the clone needs no install;
// - `vitest` maps to a tiny shim, so upstream's conformance.test.ts runs under plain Node.
import { existsSync, statSync } from "node:fs";
import path from "node:path";
import { fileURLToPath, pathToFileURL } from "node:url";

const here = path.dirname(fileURLToPath(import.meta.url));
const telemetryStub = pathToFileURL(path.join(here, "telemetry-stub.ts")).href;
const vitestShim = pathToFileURL(path.join(here, "vitest-shim.ts")).href;
const generatorParent = pathToFileURL(path.join(here, "package.json")).href;

function redirect(url) {
  return url.endsWith("/packages/lang-core/src/telemetry/runtime.ts") ? telemetryStub : url;
}

export async function resolve(specifier, context, nextResolve) {
  if ((specifier.startsWith("./") || specifier.startsWith("../")) && context.parentURL?.startsWith("file:")) {
    const base = path.resolve(path.dirname(fileURLToPath(context.parentURL)), specifier);
    for (const candidate of [base, base + ".ts", path.join(base, "index.ts")]) {
      if (existsSync(candidate) && statSync(candidate).isFile()) {
        return nextResolve(redirect(pathToFileURL(candidate).href), context);
      }
    }
  }
  if (specifier === "vitest") return { url: vitestShim, shortCircuit: true };
  if (/^zod(\/|$)/.test(specifier)) {
    return nextResolve(specifier, { ...context, parentURL: generatorParent });
  }
  return nextResolve(specifier, context);
}
