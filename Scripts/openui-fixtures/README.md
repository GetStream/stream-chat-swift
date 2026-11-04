# OpenUI conformance fixture generator

Runs the upstream OpenUI TypeScript (`packages/lang-core/src`, plus the react-ui prompt options) straight
from a clone and writes the five fixture files the Swift port tests against
(`Tests/StreamChatOpenUITests/Fixtures/`). The clone is never modified and needs no `pnpm install`.

## Requirements

- Node 22.12+ (tested with 24.11), which runs `.ts` with `--experimental-transform-types`
- `npm ci` in this folder, which installs `zod@4.4.3`, the version upstream's lockfile pins (1.0's parser imports zod)
- Python 3 for the helper scripts

## Run

```sh
cd generator
npm ci                                              # once
git -C <openui-clone> worktree add ../openui-1.0 <commit>   # any checkout of upstream works

./generate.sh <openui-clone> <out-dir>              # the 5 fixture files
./copy-spec.sh <openui-clone> <dest-dir>            # upstream spec/ (*.md + fixtures/1.0) unchanged
```

Regenerate the Swift fixtures (`Tests/StreamChatOpenUITests/Fixtures/`) from a checkout of upstream:

```sh
./generate.sh <clone> ../../Tests/StreamChatOpenUITests/Fixtures
python3 -I spec-fixtures.py <clone> ../../Tests/StreamChatOpenUITests/Fixtures   # spec-library.json, spec-interactions.json
```

The current fixtures come from upstream `729ac8b` (OpenUI 1.0.1). The same scripts against `69f6783`
(pre-1.0) reproduce the earlier fixtures byte for byte.

The scripts detect 1.0 by the presence of `packages/lang-core/src/functions.ts`. Against a pre-1.0 clone they
write the old format exactly. Against 1.0 they add the `v1-` cases, the `spec` library, and the new keys
(`completeResult`, `runtimeErrors`). `generate.sh` runs the scripts in this order:

| Script | Output | Notes |
| --- | --- | --- |
| `gen-parser.ts --clone --corpus --out` | `parser-conformance.json` | `parse()` plus streaming snapshots |
| `gen-eval.ts --clone --parser-fixtures --out` | `evaluator-conformance.json` | Needs the parser file: each non-`mini` parser case is evaluated as `corpus-<name>` |
| `gen-prompt.ts --clone --out` | `prompt-goldens.json` | `generateSystemPrompt({ library, promptOptions })` |
| `cp docs/generated/{chat,playground}-library.spec.json` | `upstream-*-library.spec.json` | Copied unchanged |

Run a single script with
`node --experimental-transform-types --no-warnings --import ./register.mjs <script>.ts --clone … --out …`.

## Files

- `loader.mjs`, `register.mjs`: Node module hooks. Extensionless relative imports resolve to `.ts` or `index.ts`. `telemetry/runtime.ts` is swapped for `telemetry-stub.ts`. `zod` resolves from this folder, and `vitest` from `vitest-shim.ts`.
- `common.ts`: argument parsing, loading the upstream modules from the clone, the library specs, the `mini` schema, and the spec library's runtime (`@Upper` implementation, `actions`).
- `corpus/base-corpus.json`: the frozen pre-1.0 corpus: 18 doc code blocks, 11 prompt examples and 7 benchmark samples, extracted from 69f6783 by `extract-corpus.py`. Every run reads this file, so a newer upstream keeps the same case names and inputs (HEAD's docs have 31 blocks and changed examples). To check it: `python3 -I extract-corpus.py <clone @ 69f6783> /tmp/c.json` gives the same content.
- `edge-cases.ts`: the original hand-written edge cases, unchanged.
- `v1-cases.ts`: the 1.0 parser and evaluator cases.
- `run-upstream-conformance.ts`: runs upstream's own `packages/lang-core/src/__tests__/conformance.test.ts` with vitest shimmed. It checks that this harness runs 1.0 faithfully: 59/59 cases pass at 729ac8b.
- `diff-fixtures.py <old-dir> <new-dir>` and `analyze-parser-changes.py <old> <new>`: summarize how two sets of fixtures differ, such as before and after an upstream update.
- `spec-fixtures.py <clone> <fixtures-dir>`: `spec-library.json` and `spec-interactions.json` from upstream's `spec/fixtures/1.0`.

## Determinism

- Chunking is the original generator's LCG, seeded with `case index + 1`. Its float products lose precision on purpose, which is why chunk sizes cluster on 1, 5 and 9. It never splits a surrogate pair. New cases are appended, so the chunks of existing cases don't change.
- Checkpoints are `floor(k * n / 9)` for k = 1…8, plus `n - 1`. `v1-spec/*` cases from `chunks.json` use upstream's chunks and record every step.
- Stream results are snapshotted as JSON when `push` returns. For the old cases the output is byte-identical to snapshotting at the end, as the original did.
- Two runs against the same commit give byte-identical files.
