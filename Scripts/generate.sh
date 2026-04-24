#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
OUTPUT_DIR_CHAT="$REPO_ROOT/Sources/StreamChat/Generated/OpenAPI"
CHAT_DIR="$REPO_ROOT/../chat"
rm -rf "$OUTPUT_DIR_CHAT"
( cd "$CHAT_DIR" ; make openapi ; go run ./cmd/chat-manager openapi generate-client --language swift --spec ./releases/v2/chat-clientside-api.yaml --output "$OUTPUT_DIR_CHAT" )

# Strip public/open so generated types default to internal.
find "$OUTPUT_DIR_CHAT" -name '*.swift' -exec sed -i '' -E 's/^([[:space:]]*)(public|open) /\1/' {} +

rename_generated_filename() {
  local old="$1"
  local new="$2"
  local old_path="$OUTPUT_DIR_CHAT/models/${old}.swift"
  local new_path="$OUTPUT_DIR_CHAT/models/${new}.swift"

  [[ -f "$old_path" ]] && mv "$old_path" "$new_path"
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
rename_generated APIError APIErrorModel
rename_generated SharedLocation SharedLocationModel
rename_generated ThreadParticipant ThreadParticipantModel
rename_generated SortParamRequest SortParamRequestModel
rename_generated ChannelConfig ChannelConfigModel
rename_generated Command CommandModel
rename_generated DeliveredMessagePayload DeliveredMessagePayloadModel
rename_generated DraftPayloadResponse DraftPayloadResponseModel
rename_generated PollOptionResponse PollOptionResponseModel
rename_generated SendMessageResponse SendMessageResponseModel
rename_generated UpdatePollOptionRequest UpdatePollOptionRequestModel

# Event collisions with public event types in WebSocketClient/Events.
rename_generated AIIndicatorClearEvent AIIndicatorClearEventModel
rename_generated AIIndicatorStopEvent AIIndicatorStopEventModel
rename_generated AIIndicatorUpdateEvent AIIndicatorUpdateEventModel
rename_generated ChannelDeletedEvent ChannelDeletedEventModel
rename_generated ChannelHiddenEvent ChannelHiddenEventModel
rename_generated ChannelTruncatedEvent ChannelTruncatedEventModel
rename_generated ChannelUpdatedEvent ChannelUpdatedEventModel
rename_generated ChannelVisibleEvent ChannelVisibleEventModel
rename_generated DraftDeletedEvent DraftDeletedEventModel
rename_generated DraftUpdatedEvent DraftUpdatedEventModel
rename_generated HealthCheckEvent HealthCheckEventModel
rename_generated MemberAddedEvent MemberAddedEventModel
rename_generated MemberRemovedEvent MemberRemovedEventModel
rename_generated MemberUpdatedEvent MemberUpdatedEventModel
rename_generated MessageDeletedEvent MessageDeletedEventModel
rename_generated MessageDeliveredEvent MessageDeliveredEventModel
rename_generated MessageNewEvent MessageNewEventModel
rename_generated MessageReadEvent MessageReadEventModel
rename_generated MessageUpdatedEvent MessageUpdatedEventModel
rename_generated NotificationAddedToChannelEvent NotificationAddedToChannelEventModel
rename_generated NotificationChannelDeletedEvent NotificationChannelDeletedEventModel
rename_generated NotificationChannelMutesUpdatedEvent NotificationChannelMutesUpdatedEventModel
rename_generated NotificationInviteAcceptedEvent NotificationInviteAcceptedEventModel
rename_generated NotificationInvitedEvent NotificationInvitedEventModel
rename_generated NotificationInviteRejectedEvent NotificationInviteRejectedEventModel
rename_generated NotificationMarkReadEvent NotificationMarkReadEventModel
rename_generated NotificationMarkUnreadEvent NotificationMarkUnreadEventModel
rename_generated NotificationMutesUpdatedEvent NotificationMutesUpdatedEventModel
rename_generated NotificationRemovedFromChannelEvent NotificationRemovedFromChannelEventModel
rename_generated PollClosedEvent PollClosedEventModel
rename_generated PollDeletedEvent PollDeletedEventModel
rename_generated PollUpdatedEvent PollUpdatedEventModel
rename_generated PollVoteCastedEvent PollVoteCastedEventModel
rename_generated PollVoteChangedEvent PollVoteChangedEventModel
rename_generated PollVoteRemovedEvent PollVoteRemovedEventModel
rename_generated ReactionDeletedEvent ReactionDeletedEventModel
rename_generated ReactionNewEvent ReactionNewEventModel
rename_generated ReactionUpdatedEvent ReactionUpdatedEventModel
rename_generated ThreadUpdatedEvent ThreadUpdatedEventModel
rename_generated UserBannedEvent UserBannedEventModel
rename_generated UserMessagesDeletedEvent UserMessagesDeletedEventModel
rename_generated UserPresenceChangedEvent UserPresenceChangedEventModel
rename_generated UserUnbannedEvent UserUnbannedEventModel
rename_generated UserUpdatedEvent UserUpdatedEventModel

escape_swift_keywords_in_cases
fix_invalid_empty_enum_cases
fix_untyped_arrays
qualify_stream_core_types

swiftformat --config "$REPO_ROOT/.swiftformat" "$OUTPUT_DIR_CHAT"
