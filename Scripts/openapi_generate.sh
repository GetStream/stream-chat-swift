#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
OUTPUT_DIR_CHAT="$REPO_ROOT/Sources/StreamChat/Generated/OpenAPI"
CHAT_DIR="$REPO_ROOT/../chat"

# Incremental OpenAPI adoption: keep ONLY the endpoints/models being migrated right
# now; everything else the generator emits is pruned below.
# allowed_models must hold the FULL transitive model closure of every endpoint in
# allowed_endpoints or the kept code won't compile — the build is the safety net.
allowed_endpoints=(
    blockUsers
    createDevice
    deleteDevice
    getApp
    getBlockedUsers
    getOG
    listDevices
    stopWatchingChannel
    unblockUsers
)
allowed_models=(
  Action
  AppResponseFields
  BlockedUserResponse
  BlockUsersRequest
  BlockUsersResponse
  CreateDeviceRequest
  DeviceResponse
  Field
  FileUploadConfig
  GetApplicationResponse
  GetBlockedUsersResponse
  GetOGResponse
  ImageData
  Images
  ListDevicesResponse
  UnblockUsersRequest
  UnblockUsersResponse
  UserResponse
)

# Exact membership test (macOS bash 3.2 — no associative arrays).
contains() {
  local needle="$1"; shift
  printf '%s\n' "$@" | grep -qxF "$needle"
}

# Rename helpers. rename_generated_filename only moves the model definition file
# (models/ holds those); rename_generated_type rewrites every whole-word reference
# across the entire generated tree (models/ AND APIs/, so endpoint factories in
# DefaultEndpoints.swift are covered now and for any future references).
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

# 1. Clean + generate.
rm -rf "$OUTPUT_DIR_CHAT"
( cd "$CHAT_DIR" ; make openapi ; \
  ./build/chat-manager openapi generate-client --language swift \
    --opt immutable_models=true --opt access_modifier=internal \
    --spec ./releases/v2/chat-clientside-api.yaml --output "$OUTPUT_DIR_CHAT" )

# 2. Drop the generated async API client — the SDK ships its own APIClient.
#    DefaultEndpoints.swift stays under APIs/ as the generator emits it.
rm -f "$OUTPUT_DIR_CHAT/APIs/DefaultAPI.swift"

# 3. Prune endpoint factories: keep only allowed_endpoints, delete the rest.
prune_endpoint_factories() {
  local file="$OUTPUT_DIR_CHAT/APIs/DefaultEndpoints.swift"
  local name
  while IFS= read -r name; do
    contains "$name" "${allowed_endpoints[@]}" && continue
    sed -i '' -E "/^[[:space:]]+static func ${name}\(/,/^[[:space:]]+\}[[:space:]]*$/d" "$file"
  done < <(sed -nE 's/^[[:space:]]+static func ([A-Za-z0-9_]+)\(.*/\1/p' "$file")
}
prune_endpoint_factories

# Keep generated v2 EndpointPath cases aligned with allowed_endpoints before v1
# cases are injected. Future migrations should remove matching v1 cases when
# adding a generated v2 path with the same case name.
prune_generated_endpoint_paths() {
  local file="$OUTPUT_DIR_CHAT/APIs/DefaultEndpoints.swift"
  local allowed_endpoints_csv
  allowed_endpoints_csv="$(IFS=,; echo "${allowed_endpoints[*]}")"

  python3 - "$file" "$allowed_endpoints_csv" <<'PY'
import pathlib
import sys

path = pathlib.Path(sys.argv[1])
allowed = set(filter(None, sys.argv[2].split(",")))

def case_name(line):
    stripped = line.strip()
    if not stripped.startswith("case "):
        return None
    pattern = stripped[len("case "):]
    if pattern.startswith("let "):
        pattern = pattern[len("let "):]
    if pattern.startswith("."):
        pattern = pattern[1:]
    return pattern.split("(", 1)[0].split(" ", 1)[0].split(":", 1)[0]

# Within the EndpointPath enum, drop every `case` line and its (possibly multi-line)
# switch arm whose name isn't allowed; keep every structural line. swiftformat tidies
# the leftover blank lines afterwards.
out, in_enum, keep = [], False, True
for line in path.read_text().splitlines(keepends=True):
    if line.startswith("enum EndpointPath"):
        in_enum = True
    elif line.startswith("final class Endpoint"):
        in_enum = False
    if in_enum:
        name = case_name(line)
        if name is not None:                                     # `case …`: opens a block
            keep = name in allowed
        elif not line.lstrip().startswith(("return ", "let ")):  # structural line
            keep = True                                          # (arm bodies inherit keep)
        if not keep:
            continue
    out.append(line)

path.write_text("".join(out))
PY
}
prune_generated_endpoint_paths

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

# 4b. Rename selected generated models for clarity and to avoid generic-name
#     pollution / collisions with hand-written SDK types. Runs AFTER prune_models
#     so allowed_models above still matches the generator's original names.
rename_generated Action AttachmentActionPayload
rename_generated AppResponseFields AppSettings
rename_generated Field AttachmentFieldPayload
rename_generated FileUploadConfig UploadConfig
rename_generated ImageData GiphyImageData
rename_generated Images GiphyImages

rename_generated_type Response EmptyResponse

# 4c. Expose selected generated models as public API. The class and its stored
#     properties become public, along with the generated Hashable conformance
#     (== and hash(into:)); the memberwise init and CodingKeys stay internal.
publicize_model() {
  local file="$OUTPUT_DIR_CHAT/models/$1.swift"
  sed -i '' -E \
    -e 's/^final class /public final class /' \
    -e 's/^    let /    public let /' \
    -e 's/^    static func == /    public static func == /' \
    -e 's/^    func hash\(into /    public func hash(into /' \
    "$file"
}
publicize_model AppSettings
publicize_model UploadConfig

# 5. Format.
swiftformat --config "$REPO_ROOT/.swiftformat" "$OUTPUT_DIR_CHAT"

# 6. Inject the existing v1 SDK endpoint paths into the generated EndpointPath enum.
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

    case userGroups
    case userGroupSearch
    case userGroup(id: String)
    case userGroupMembers(id: String)
    case userGroupMembersDelete(id: String)

    case rolesSearch

EOF

  cat > "$values_file" <<'EOF'
        case .connect: return "connect"
        case .sync: return "sync"
        case .users: return "users"
        case .guest: return "guest"
        case .search: return "search"
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

        case .userGroups: return "usergroups"
        case .userGroupSearch: return "usergroups/search"
        case let .userGroup(id): return "usergroups/\(id)"
        case let .userGroupMembers(id): return "usergroups/\(id)/members"
        case let .userGroupMembersDelete(id): return "usergroups/\(id)/members/delete"

        case .rolesSearch: return "roles/search"

EOF

  python3 - "$file" "$cases_file" "$values_file" <<'PY'
import pathlib
import sys

file_path = pathlib.Path(sys.argv[1])
cases = pathlib.Path(sys.argv[2]).read_text()
values = pathlib.Path(sys.argv[3]).read_text()
text = file_path.read_text()

enum_marker = "enum EndpointPath: Codable {\n"
switch_marker = "        switch self {\n"

text = text.replace(enum_marker, enum_marker + cases, 1)
text = text.replace(switch_marker, switch_marker + values, 1)
file_path.write_text(text)
PY
}
inject_v1_endpoint_paths
