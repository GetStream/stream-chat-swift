#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
OUTPUT_DIR_CHAT="$REPO_ROOT/Sources/StreamChat/Generated/OpenAPI"
CHAT_DIR="$REPO_ROOT/../chat"
STRIP_ACCESS_MODIFIERS_EXCLUDED_FILES=(
  "$OUTPUT_DIR_CHAT/models/Command.swift"
)
rm -rf "$OUTPUT_DIR_CHAT"
# `make openapi` builds the chat-manager binary into ./build/chat-manager and regenerates the specs.
( cd "$CHAT_DIR" ; make openapi ; \
  ./build/chat-manager openapi generate-client --language swift           --spec ./releases/v2/chat-clientside-api.yaml --output "$OUTPUT_DIR_CHAT" ; \
  ./build/chat-manager openapi generate-client --language swift-endpoints --spec ./releases/v2/chat-clientside-api.yaml --output "$OUTPUT_DIR_CHAT" )

is_access_modifier_stripping_excluded() {
  local file="$1"
  local excluded_file

  for excluded_file in "${STRIP_ACCESS_MODIFIERS_EXCLUDED_FILES[@]}"; do
    [[ "$file" == "$excluded_file" ]] && return 0
  done

  return 1
}

strip_public_open_access_modifiers() {
  find "$OUTPUT_DIR_CHAT" -name '*.swift' -print0 | while IFS= read -r -d '' file; do
    is_access_modifier_stripping_excluded "$file" && continue
    sed -i '' -E 's/^([[:space:]]*)(public|open) /\1/' "$file"
  done
}

rename_generated_filename() {
  local old="$1"
  local new="$2"
  local old_path="$OUTPUT_DIR_CHAT/models/${old}.swift"
  local new_path="$OUTPUT_DIR_CHAT/models/${new}.swift"

  [[ -f "$old_path" ]] && mv "$old_path" "$new_path"
}

delete_generated_filename() {
  local name="$1"
  local path="$OUTPUT_DIR_CHAT/models/${name}.swift"

  rm -f "$path"
}

rename_generated_type() {
  local old="$1"
  local new="$2"
  find "$OUTPUT_DIR_CHAT" -name '*.swift' -exec sed -i '' -E "s/[[:<:]]$old[[:>:]]/$new/g" {} +
}

# Rename both the model file and every reference to the type.
rename_generated() {
  rename_generated_filename "$1" "$2"
  rename_generated_type "$1" "$2"
}

escape_swift_keywords_in_cases() {
  # `default` is only escaped in enum case declarations — it's a valid identifier elsewhere (e.g. JSONDecoder.default).
  find "$OUTPUT_DIR_CHAT" -name '*.swift' -exec sed -i '' -E 's/^([[:space:]]*case)[[:space:]]+default[[:>:]]/\1 `default`/' {} +
  # `operator` is escaped everywhere it appears as a bare identifier — it shows up as a property, init param, and member access, and never appears legitimately unquoted in generated models.
  find "$OUTPUT_DIR_CHAT" -name '*.swift' -exec sed -i '' -E 's/[[:<:]]operator[[:>:]]/`operator`/g' {} +
}

fix_invalid_empty_enum_cases() {
  # OpenAPI generator can emit an empty case identifier for the raw value "''".
  find "$OUTPUT_DIR_CHAT" -name '*.swift' -exec sed -i '' -E "s/^([[:space:]]*)case[[:space:]]*=[[:space:]]*\"''\"/\\1case empty = \"''\"/" {} +
}

fix_untyped_arrays() {
  # The OpenAPI spec has fields whose schema lacks an `items` entry, so the generator emits `Array` with no
  # element type. Replace these bare occurrences with `[RawJSON]` so the model stays compilable.
  find "$OUTPUT_DIR_CHAT" -name '*.swift' -exec sed -i '' -E 's/[[:<:]]Array[[:>:]]/[RawJSON]/g' {} +
}

qualify_stream_core_types() {
  # StreamChat defines a local `EmptyResponse` that only conforms to Decodable and shadows StreamCore's Codable
  # variant required by the generated `send<Response: Codable>`. Qualify with the module name so the Codable
  # variant is used in generated APIs.
  find "$OUTPUT_DIR_CHAT/APIs" -name '*.swift' -exec sed -i '' -E 's/[[:<:]]EmptyResponse[[:>:]]/StreamCore.EmptyResponse/g' {} +
  # Add `import StreamCore` to any generated file that uses a StreamCore-qualified type.
  find "$OUTPUT_DIR_CHAT/APIs" -name '*.swift' | while IFS= read -r file; do
    if grep -q 'StreamCore\.' "$file" && ! grep -qE '^import StreamCore$' "$file"; then
      sed -i '' -E $'/^import Foundation$/a\\\nimport StreamCore
' "$file"
    fi
  done
}

# Hardcoded clashes while StreamChat source models remain the default.
# Model collisions.
delete_generated_filename APIError
rename_generated SharedLocation SharedLocationPayload
rename_generated Command CommandPayload
rename_generated ThreadParticipant ThreadParticipantPayload
rename_generated ChannelConfig ChannelConfigPayload
rename_generated SendMessageResponse SendMessageResponsePayload

# Event collisions with public event types in WebSocketClient/Events.
# Every generated *Event type gets a DTO suffix so it doesn't collide with the
# hand-written public Event class of the same base name. WSEvent and
# WSClientEvent are wrapper/union types and are excluded.
while IFS= read -r event_type; do
  rename_generated "$event_type" "${event_type}DTO"
done < <(find "$OUTPUT_DIR_CHAT/models" -name '*Event.swift' ! -name 'WSEvent.swift' ! -name 'WSClientEvent.swift' -exec basename {} .swift \; | sort)

escape_swift_keywords_in_cases
fix_invalid_empty_enum_cases
fix_untyped_arrays
qualify_stream_core_types
strip_public_open_access_modifiers

swiftformat --config "$REPO_ROOT/.swiftformat" "$OUTPUT_DIR_CHAT"
