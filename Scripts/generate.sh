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
#    DefaultEndpoints.swift stays under APIs/ as the generator emits it.
rm -f "$OUTPUT_DIR_CHAT/APIs/DefaultAPI.swift"

# 3. Prune endpoint factories: keep only allowed_paths, delete the rest.
prune_endpoint_factories() {
  local file="$OUTPUT_DIR_CHAT/APIs/DefaultEndpoints.swift"
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

# 7. Inject the existing v1 SDK endpoint paths into the generated EndpointPath enum.
#    The OpenAPI generator owns v2 paths; these v1 cases keep the hand-written
#    endpoint factories compiling while each endpoint migrates incrementally.
inject_v1_endpoint_paths() {
  local file="$OUTPUT_DIR_CHAT/APIs/DefaultEndpoints.swift"
  local cases_file values_file
  cases_file="$(mktemp)"
  values_file="$(mktemp)"
  trap 'rm -f "$cases_file" "$values_file"' RETURN

  cat > "$cases_file" <<'EOF'
    case connect
    case sync
    case users
    case guest
    case search
    case devices
    case og
    case unread
    case pushPreferences

    case members
    case partialMemberUpdate(userId: UserId, cid: ChannelId)

    case threads
    case thread(messageId: MessageId)
    case markThreadRead(cid: ChannelId)
    case markThreadUnread(cid: ChannelId)

    case channels
    case groupedChannels
    case createChannel(String)
    case updateChannel(String)
    case deleteChannel(String)
    case channelUpdate(String)
    case muteChannel(Bool)
    case showChannel(String, Bool)
    case truncateChannel(String)
    case markChannelRead(String)
    case markChannelUnread(String)
    case markAllChannelsRead
    case markChannelsDelivered
    case channelEvent(String)
    case stopWatchingChannel(String)
    case pinnedMessages(String)
    case uploadChannelAttachment(channelId: String, type: String)
    case uploadAttachment(String)

    case sendMessage(ChannelId)
    case message(MessageId)
    case editMessage(MessageId)
    case deleteMessage(MessageId)
    case pinMessage(MessageId)
    case unpinMessage(MessageId)
    case replies(MessageId)
    case reactions(MessageId)
    case addReaction(MessageId)
    case deleteReaction(MessageId, MessageReactionType)
    case messageAction(MessageId)
    case translateMessage(MessageId)

    // Drafts
    case drafts
    case draftMessage(ChannelId)

    // Reminders
    case reminders
    case reminder(MessageId)

    case banMember
    case flagUser(Bool)
    case flagMessage(Bool)
    case muteUser(Bool)
    case blockUser
    case unblockUser

    case callToken(String)
    case createCall(String)

    case deleteFile(String)
    case deleteImage(String)

    case liveLocations

    case polls
    case pollsQuery
    case poll(pollId: String)
    case pollOption(pollId: String, optionId: String)
    case pollOptions(pollId: String)
    case pollVotes(pollId: String)
    case pollVoteInMessage(messageId: MessageId, pollId: String)
    case pollVote(messageId: MessageId, pollId: String, voteId: String)

EOF

  cat > "$values_file" <<'EOF'
        case .connect: return "connect"
        case .sync: return "sync"
        case .users: return "users"
        case .guest: return "guest"
        case .search: return "search"
        case .devices: return "devices"
        case .og: return "og"
        case .unread: return "unread"
        case .pushPreferences: return "push_preferences"

        case .members: return "members"
        case let .partialMemberUpdate(userId, cid):
            return "channels/\(cid.apiPath)/member/\(userId)"

        case .threads:
            return "threads"
        case let .thread(threadId):
            return "threads/\(threadId)"
        case let .markThreadRead(cid):
            return "channels/\(cid.apiPath)/read"
        case let .markThreadUnread(cid):
            return "channels/\(cid.apiPath)/unread"

        case .liveLocations: return "users/live_locations"

        case .channels: return "channels"
        case .groupedChannels: return "channels/grouped"
        case let .createChannel(queryString): return "channels/\(queryString)/query"
        case let .updateChannel(queryString): return "channels/\(queryString)/query"
        case let .deleteChannel(payloadPath): return "channels/\(payloadPath)"
        case let .channelUpdate(payloadPath): return "channels/\(payloadPath)"
        case let .muteChannel(mute): return "moderation/\(mute ? "mute" : "unmute")/channel"
        case let .showChannel(channelId, show): return "channels/\(channelId)/\(show ? "show" : "hide")"
        case let .truncateChannel(channelId): return "channels/\(channelId)/truncate"
        case let .markChannelRead(channelId): return "channels/\(channelId)/read"
        case let .markChannelUnread(channelId): return "channels/\(channelId)/unread"
        case .markAllChannelsRead: return "channels/read"
        case .markChannelsDelivered: return "channels/delivered"
        case let .channelEvent(channelId): return "channels/\(channelId)/event"
        case let .stopWatchingChannel(channelId): return "channels/\(channelId)/stop-watching"
        case let .pinnedMessages(channelId): return "channels/\(channelId)/pinned_messages"
        case let .uploadChannelAttachment(channelId, type): return "channels/\(channelId)/\(type)"
        case let .uploadAttachment(type): return "uploads/\(type)"

        case let .sendMessage(channelId): return "channels/\(channelId.apiPath)/message"
        case let .message(messageId): return "messages/\(messageId)"
        case let .editMessage(messageId): return "messages/\(messageId)"
        case let .deleteMessage(messageId): return "messages/\(messageId)"
        case let .pinMessage(messageId): return "messages/\(messageId)"
        case let .unpinMessage(messageId): return "messages/\(messageId)"
        case let .replies(messageId): return "messages/\(messageId)/replies"
        case let .reactions(messageId): return "messages/\(messageId)/reactions"
        case let .addReaction(messageId): return "messages/\(messageId)/reaction"
        case let .deleteReaction(messageId, reaction): return "messages/\(messageId)/reaction/\(reaction.rawValue)"
        case let .messageAction(messageId): return "messages/\(messageId)/action"
        case let .translateMessage(messageId): return "messages/\(messageId)/translate"

        case .drafts: return "drafts/query"
        case let .draftMessage(channelId): return "channels/\(channelId.apiPath)/draft"

        case .reminders: return "reminders/query"
        case let .reminder(messageId): return "messages/\(messageId)/reminders"

        case .banMember: return "moderation/ban"
        case let .flagUser(flag): return "moderation/\(flag ? "flag" : "unflag")"
        case let .flagMessage(flag): return "moderation/\(flag ? "flag" : "unflag")"
        case let .muteUser(mute): return "moderation/\(mute ? "mute" : "unmute")"
        case .blockUser: return "users/block"
        case .unblockUser: return "users/unblock"
        case let .callToken(callId): return "calls/\(callId)"
        case let .createCall(queryString): return "channels/\(queryString)/call"
        case let .deleteFile(channelId): return "channels/\(channelId)/file"
        case let .deleteImage(channelId): return "channels/\(channelId)/image"
        case .polls: return "polls"
        case .pollsQuery: return "polls/query"
        case let .poll(pollId: pollId): return "polls/\(pollId)"
        case let .pollOption(pollId: pollId, optionId: optionId): return "polls/\(pollId)/options/\(optionId)"
        case let .pollOptions(pollId: pollId): return "polls/\(pollId)/options"
        case let .pollVotes(pollId: pollId): return "polls/\(pollId)/votes"
        case let .pollVoteInMessage(messageId: messageId, pollId: pollId): return "messages/\(messageId)/polls/\(pollId)/vote"
        case let .pollVote(messageId: messageId, pollId: pollId, voteId: voteId): return "messages/\(messageId)/polls/\(pollId)/vote/\(voteId)"

EOF

  local allowed_paths_csv
  allowed_paths_csv="$(IFS=,; echo "${allowed_paths[*]}")"

  python3 - "$file" "$cases_file" "$values_file" "$allowed_paths_csv" <<'PY'
import pathlib
import sys

file_path = pathlib.Path(sys.argv[1])
cases = pathlib.Path(sys.argv[2]).read_text()
values = pathlib.Path(sys.argv[3]).read_text()
allowed_paths = [name for name in sys.argv[4].split(",") if name]
text = file_path.read_text()

enum_marker = "enum EndpointPath: Codable {\n"
switch_marker = "        switch self {\n"
class_marker = "\n}\n\nfinal class Endpoint"

def declaration_name(line):
    stripped = line.strip()
    if not stripped.startswith("case "):
        return None
    name = stripped[len("case "):]
    return name.split("(", 1)[0].split(" ", 1)[0]

def switch_case_name(line):
    stripped = line.strip()
    if not stripped.startswith("case "):
        return None
    pattern = stripped[len("case "):]
    if pattern.startswith("let "):
        pattern = pattern[len("let "):]
    if pattern.startswith("."):
        pattern = pattern[1:]
    return pattern.split("(", 1)[0].split(":", 1)[0]

enum_start = text.index(enum_marker)
enum_end = text.index(class_marker, enum_start) + len("\n}\n")
enum_text = text[enum_start:enum_end]

value_marker = "\n    var value: String {\n        switch self {\n"
case_region_end = enum_text.index(value_marker)
case_region = enum_text[len(enum_marker):case_region_end]

switch_region_start = enum_text.index(switch_marker) + len(switch_marker)
switch_region_end = enum_text.rindex("        }\n    }\n")
switch_region = enum_text[switch_region_start:switch_region_end]

kept_case_lines = []
kept_case_names = []
for line in case_region.splitlines(keepends=True):
    name = declaration_name(line)
    if name in allowed_paths:
        kept_case_lines.append(line)
        kept_case_names.append(name)

switch_blocks = {}
current_name = None
current_block = []
for line in switch_region.splitlines(keepends=True):
    name = switch_case_name(line)
    if name is not None:
        if current_name in allowed_paths:
            switch_blocks[current_name] = current_block
        current_name = name
        current_block = [line]
    elif current_name is not None:
        current_block.append(line)
if current_name in allowed_paths:
    switch_blocks[current_name] = current_block

missing_cases = [name for name in allowed_paths if name not in kept_case_names]
missing_values = [name for name in allowed_paths if name not in switch_blocks]
if missing_cases or missing_values:
    sys.exit(f"missing generated EndpointPath entries: cases={missing_cases}, values={missing_values}")

kept_switch_blocks = []
for name in kept_case_names:
    kept_switch_blocks.extend(switch_blocks[name])

new_enum = (
    enum_marker
    + cases
    + "".join(kept_case_lines)
    + "\n    var value: String {\n"
    + switch_marker
    + values
    + "".join(kept_switch_blocks)
    + "        }\n"
    + "    }\n"
    + "}\n"
)

file_path.write_text(text[:enum_start] + new_enum + text[enum_end:])
PY
}
inject_v1_endpoint_paths
