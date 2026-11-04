#!/bin/sh
# Generates the five Swift conformance fixture files from an OpenUI clone.
# Usage: ./generate.sh <openui-clone> <out-dir>
set -eu
[ $# -eq 2 ] || { echo "usage: $0 <openui-clone> <out-dir>" >&2; exit 2; }
here=$(cd "$(dirname "$0")" && pwd)
clone=$(cd "$1" && pwd)
mkdir -p "$2"
out=$(cd "$2" && pwd)
[ -d "$here/node_modules/zod" ] || (cd "$here" && npm ci --no-audit --no-fund)
run() { (cd "$here" && node --experimental-transform-types --no-warnings --import ./register.mjs "$@"); }
run gen-parser.ts --clone "$clone" --corpus "$here/corpus/base-corpus.json" --out "$out/parser-conformance.json"
run gen-eval.ts --clone "$clone" --parser-fixtures "$out/parser-conformance.json" --out "$out/evaluator-conformance.json"
run gen-prompt.ts --clone "$clone" --out "$out/prompt-goldens.json"
cp "$clone/docs/generated/chat-library.spec.json" "$out/upstream-chat-library.spec.json"
cp "$clone/docs/generated/playground-library.spec.json" "$out/upstream-playground-library.spec.json"
echo "fixtures from $(git -C "$clone" rev-parse --short HEAD) written to $out"
