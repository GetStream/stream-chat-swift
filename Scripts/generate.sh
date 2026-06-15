#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
OUTPUT_DIR_CHAT="$REPO_ROOT/Sources/StreamChat/Generated/OpenAPI"
CHAT_DIR="$REPO_ROOT/../chat"

# Incremental OpenAPI adoption: keep ONLY the endpoints/models being migrated right
# now (app settings); everything else the generator emits is pruned below.
# allowed_models must hold the FULL transitive model closure of every factory in
# allowed_paths or the kept code won't compile — the build is the safety net.
allowed_paths=(getApp)
allowed_models=(
  AppResponseFields
  FileUploadConfig
  GetApplicationResponse
)

# Exact membership test (macOS bash 3.2 — no associative arrays).
contains() {
  local needle="$1"; shift
  printf '%s\n' "$@" | grep -qxF "$needle"
}

# 1. Clean + generate.
rm -rf "$OUTPUT_DIR_CHAT"
( cd "$CHAT_DIR" ; make openapi ; \
  ./build/chat-manager openapi generate-client --language swift \
    --spec ./releases/v2/chat-clientside-api.yaml --output "$OUTPUT_DIR_CHAT" )

# 2. Drop the generated async API client — the SDK ships its own APIClient.
rm -f "$OUTPUT_DIR_CHAT/Api/DefaultAPI.swift"
rmdir "$OUTPUT_DIR_CHAT/Api" 2>/dev/null || true

# 3. Prune endpoint factories: keep only allowed_paths, delete the rest.
prune_endpoint_factories() {
  local file="$OUTPUT_DIR_CHAT/DefaultEndpoints.swift"
  local name
  while IFS= read -r name; do
    contains "$name" "${allowed_paths[@]}" && continue
    sed -i '' -E "/^[[:space:]]+static func ${name}\(/,/^[[:space:]]+\}[[:space:]]*$/d" "$file"
  done < <(sed -nE 's/^[[:space:]]+static func ([A-Za-z0-9_]+)\(.*/\1/p' "$file")
}
prune_endpoint_factories

# 4. Prune models: keep only allowed_models, delete the rest.
prune_models() {
  local f base
  for f in "$OUTPUT_DIR_CHAT"/models/*.swift; do
    [ -e "$f" ] || continue
    base="$(basename "$f" .swift)"
    contains "$base" "${allowed_models[@]}" && continue
    rm -f "$f"
  done
}
prune_models

# 5. Generated code is internal to the SDK — strip public/open.
find "$OUTPUT_DIR_CHAT" -name '*.swift' -print0 | while IFS= read -r -d '' file; do
  sed -i '' -E 's/^([[:space:]]*)(public|open) /\1/' "$file"
done

# 6. Format.
swiftformat --config "$REPO_ROOT/.swiftformat" "$OUTPUT_DIR_CHAT"
