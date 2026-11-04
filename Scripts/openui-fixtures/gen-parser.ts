// Parser conformance fixtures (parser-conformance.json) from the upstream reference parser.
// Usage: node --experimental-transform-types --no-warnings --import ./register.mjs gen-parser.ts \
//          --clone <openui-clone> --corpus corpus/base-corpus.json --out <parser-conformance.json>
import { writeFileSync } from "node:fs";
import { librarySpecs, loadUpstream, MINI_SCHEMA, parseArgs, readJSON, specFixtureCases } from "./common.ts";
import { edgeCases } from "./edge-cases.ts";
import { v1ParserCases } from "./v1-cases.ts";

const args = parseArgs(["clone", "corpus", "out"]);
const up = await loadUpstream(args.clone);
const { compileSchema, createStreamParser, parse } = up.parser;
const specs = librarySpecs(args.clone);

const libraries: Record<string, { cat: any; root?: string }> = {
  chat: { cat: compileSchema(specs.chat.schema), root: specs.chat.root },
  playground: { cat: compileSchema(specs.playground.schema), root: specs.playground.root },
  mini: { cat: compileSchema(MINI_SCHEMA as any), root: undefined },
};
// The spec library is parsed with library.json's schema as it is (conformance.test.ts).
if (up.v1) libraries.spec = { cat: compileSchema(specs.spec.schema), root: specs.spec.root };

/** `chunks`: the chunks to stream (spec chunks.json cases); `everyStep`: record every step. */
type Case = { name: string; library: string; input: string; chunks?: string[]; everyStep?: boolean };
const cases: Case[] = [];

// ─── The pre-1.0 corpus (frozen: corpus/base-corpus.json, extracted from 69f6783) ───
const raw = readJSON(args.corpus);
raw.docs.forEach((block: { source: string; code: string }, i: number) => {
  // Docs mostly use the playground library (Stack root) — parse against both to widen coverage.
  cases.push({ name: `docs-${i}-playground`, library: "playground", input: block.code });
  cases.push({ name: `docs-${i}-chat`, library: "chat", input: block.code });
});
raw.examples.forEach((example: string, i: number) => {
  const body = example.replace(/^Example \d+ —[^\n]*\n\n?/, "");
  cases.push({ name: `prompt-example-${i}`, library: i < 6 ? "playground" : "chat", input: body });
});
for (const { file, input } of raw.benchmarks) cases.push({ name: `benchmark-${file}`, library: "playground", input });
for (const [name, library, input] of edgeCases) cases.push({ name: `edge-${name}`, library, input });

// ─── 1.0 additions ───
if (up.v1) {
  for (const [name, library, input] of v1ParserCases) cases.push({ name: `v1-${name}`, library, input });
  for (const { id, files } of specFixtureCases(args.clone)) {
    if (files["chunks.json"]) {
      const chunks: string[] = JSON.parse(files["chunks.json"]);
      cases.push({ name: `v1-spec/${id}`, library: "spec", input: chunks.join(""), chunks, everyStep: true });
    } else if (files["input.oui"] !== undefined) {
      cases.push({ name: `v1-spec/${id}`, library: "spec", input: files["input.oui"] });
      if (files["patch.oui"] !== undefined) {
        const merged = up.merge.mergeStatements(files["input.oui"], files["patch.oui"]);
        cases.push({ name: `v1-spec/${id}/merged`, library: "spec", input: merged });
      }
    }
  }
}

// Deterministic chunking that never splits a surrogate pair (the original generator's, unchanged:
// the float products lose precision, which is why chunk sizes cluster on 1, 5 and 9).
function chunk(input: string, seed: number): string[] {
  let state = seed * 2654435761 % 4294967296 || 1;
  const next = () => (state = (state * 1103515245 + 12345) % 2147483648);
  const chunks: string[] = [];
  let i = 0;
  while (i < input.length) {
    let size = 1 + (next() % 12);
    let end = Math.min(input.length, i + size);
    const code = input.charCodeAt(end - 1);
    if (end < input.length && code >= 0xd800 && code <= 0xdbff) end += 1;
    chunks.push(input.slice(i, end));
    i = end;
  }
  return chunks;
}

/** A plain-JSON snapshot taken when the parser returns it (later pushes cannot alias into it). */
const snapshot = (value: unknown) => (value === undefined ? undefined : JSON.parse(JSON.stringify(value)));

const out = cases.map((c, index) => {
  const lib = libraries[c.library];
  const result = parse(c.input, lib.cat, lib.root);
  const chunks = c.chunks ?? chunk(c.input, index + 1);
  const sp = createStreamParser(lib.cat, lib.root);
  const wanted = new Set<number>();
  const count = chunks.length;
  if (c.everyStep) chunks.forEach((_, step) => wanted.add(step));
  for (let k = 1; k <= 8; k++) wanted.add(Math.floor((k * count) / 9));
  wanted.add(count - 1);
  const checkpoints: number[] = [];
  const streamResults: unknown[] = [];
  chunks.forEach((ch, step) => {
    const r = sp.push(ch);
    if (wanted.has(step)) {
      checkpoints.push(step);
      streamResults.push(snapshot(r));
    }
  });
  const fixture: Record<string, unknown> = {
    name: c.name,
    library: c.library,
    input: c.input,
    result: snapshot(result),
    chunks,
    checkpoints,
    streamResults,
  };
  if (up.v1) {
    // The same chunks with `complete: true` on the last push (getResult(true) for an empty input).
    const done = createStreamParser(lib.cat, lib.root);
    let last = done.getResult(true);
    chunks.forEach((ch, step) => {
      last = done.push(ch, step === chunks.length - 1);
    });
    fixture.completeResult = snapshot(last);
  }
  return fixture;
});

writeFileSync(args.out, JSON.stringify(out));
console.log(`${out.length} parser cases written to ${args.out}`);
