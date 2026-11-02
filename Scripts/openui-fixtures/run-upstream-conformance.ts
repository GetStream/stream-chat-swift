// Runs upstream's own packages/lang-core/src/__tests__/conformance.test.ts (vitest shimmed) against the
// clone's spec/fixtures/1.0, to confirm this harness (zod version, loader, telemetry stub) runs 1.0 faithfully.
// Usage: node --experimental-transform-types --no-warnings --import ./register.mjs run-upstream-conformance.ts --clone <openui-clone>
import path from "node:path";
import { pathToFileURL } from "node:url";
import { parseArgs } from "./common.ts";
import { runAll } from "./vitest-shim.ts";

const args = parseArgs(["clone"]);
process.env.OPENUI_FIXTURES = path.join(args.clone, "spec/fixtures/1.0");
await import(pathToFileURL(path.join(args.clone, "packages/lang-core/src/__tests__/conformance.test.ts")).href);
process.exitCode = (await runAll()) ? 1 : 0;
