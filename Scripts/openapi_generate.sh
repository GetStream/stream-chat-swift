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
    addUserGroupMembers
    ban
    blockUsers
    castPollVote
    createDevice
    createDraft
    createGuest
    createPoll
    createPollOption
    createReminder
    createUserGroup
    custom
    deleteChannel
    deleteChannelFile
    deleteChannelImage
    deleteDevice
    deleteDraft
    deletePoll
    deletePollVote
    deleteFile
    deleteImage
    deleteMessage
    deleteReaction
    deleteReminder
    deleteUserGroup
    flag
    getApp
    getDraft
    getBlockedUsers
    getMessage
    getOG
    getOrCreateChannel
    getOrCreateDistinctChannel
    getPinnedMessages
    getReactions
    getReplies
    getThread
    getUserGroup
    getUserLiveLocations
    groupedQueryChannels
    hideChannel
    listDevices
    listUserGroups
    markChannelsRead
    markDelivered
    markRead
    markUnread
    mute
    muteChannel
    queryBannedUsers
    queryChannels
    queryDrafts
    queryMembers
    queryPollVotes
    queryReactions
    queryReminders
    queryThreads
    queryUsers
    removeUserGroupMembers
    runMessageAction
    search
    searchRoles
    searchUserGroups
    sendEvent
    sendMessage
    sendReaction
    showChannel
    stopWatchingChannel
    sync
    translateMessage
    truncateChannel
    unban
    unblockUsers
    unmute
    unmuteChannel
    unreadCounts
    updateChannel
    updateChannelPartial
    updateLiveLocation
    updateMemberPartial
    updateMessage
    updateMessagePartial
    updatePollPartial
    updatePushNotificationPreferences
    updateReminder
    updateThreadPartial
    updateUserGroup
    updateUsersPartial
    uploadChannelFile
    uploadChannelImage
    uploadFile
    uploadImage
)
allowed_models=(
  Action
  AddUserGroupMembersRequest
  AppResponseFields
  Attachment
  BanRequest
  BanResponse
  BlockedUserResponse
  BlockUsersRequest
  BlockUsersResponse
  CastPollVoteRequest
  ChannelGetOrCreateRequest
  ChannelInput
  ChannelInputRequest
  ChannelMemberPartialResponse
  ChannelMemberRequest
  ChannelMemberResponse
  ChannelMute
  ChannelOwnCapability
  ChannelResponse
  ChannelStateResponse
  ConnectUserDetailsRequest
  CreateDeviceRequest
  CreateDraftRequest
  CreateDraftResponse
  CreateGuestRequest
  CreateGuestResponse
  CreatePollOptionRequest
  CreatePollRequest
  CreateReminderRequest
  CreateReminderResponse
  CreateUserGroupRequest
  DeleteChannelResponse
  DeleteMessageResponse
  DeleteReactionResponse
  DeliveredMessagePayload
  DeliveryReceiptsResponse
  DeviceResponse
  DraftPayloadResponse
  DraftResponse
  EventRequest
  Field
  FileUploadConfig
  FileUploadResponse
  FlagRequest
  FullUserResponse
  GetApplicationResponse
  GetBlockedUsersResponse
  GetDraftResponse
  GetMessageResponse
  GetOGResponse
  GetPinnedMessagesResponse
  GetReactionsResponse
  GetRepliesResponse
  GetThreadResponse
  GetUserGroupResponse
  GroupedChannelsBucket
  GroupedChannelsGroupRequest
  GroupedQueryChannelsRequest
  GroupedQueryChannelsResponse
  HideChannelRequest
  ImageData
  Images
  ImageSize
  ImageUploadResponse
  ListDevicesResponse
  ListUserGroupsResponse
  MarkChannelsReadRequest
  MarkDeliveredRequest
  MarkReadRequest
  MarkUnreadRequest
  MemberUserRequest
  MembersResponse
  MessageActionRequest
  MessageActionResponse
  MessagePaginationParams
  MessageRequest
  MessageResponse
  ModerationV2Response
  MuteChannelRequest
  MuteChannelResponse
  MuteRequest
  MuteResponse
  OwnUserResponse
  PaginationParams
  ParsedPredefinedFilterResponse
  PendingMessageResponse
  PollOptionInput
  PollOptionResponse
  PollOptionResponseData
  PollResponse
  PollResponseData
  PollVoteResponse
  PollVoteResponseData
  PollVotesResponse
  PrivacySettingsResponse
  PushPreferenceInput
  PushPreferencesResponse
  QueryBannedUsersPayload
  QueryBannedUsersResponse
  QueryChannelsRequest
  QueryChannelsResponse
  QueryDraftsRequest
  QueryDraftsResponse
  QueryMembersPayload
  QueryPollVotesRequest
  QueryReactionsRequest
  QueryRemindersRequest
  QueryRemindersResponse
  QueryThreadsRequest
  QueryThreadsResponse
  QueryUsersPayload
  QueryUsersResponse
  ReactionGroupResponse
  ReactionRequest
  ReactionResponse
  ReadReceiptsResponse
  ReadStateResponse
  ReminderResponseData
  RemoveUserGroupMembersRequest
  Role
  SearchPayload
  SearchResponse
  SearchResult
  SearchResultMessage
  SearchRolesResponse
  SendEventRequest
  SendMessageRequest
  SendMessageResponse
  SendReactionRequest
  SendReactionResponse
  SharedLocation
  SharedLocationResponseData
  SharedLocationsResponse
  SortParamRequest
  SyncRequest
  SyncResponse
  ThreadParticipant
  ThreadResponse
  ThreadStateResponse
  TranslateMessageRequest
  TranslateMessageResponse
  TruncateChannelRequest
  TruncateChannelResponse
  TypingIndicatorsResponse
  UnblockUsersRequest
  UnblockUsersResponse
  UnmuteChannelRequest
  UnmuteRequest
  UnmuteResponse
  UnreadCountsChannel
  UnreadCountsChannelType
  UnreadCountsThread
  UpdateChannelPartialRequest
  UpdateChannelPartialResponse
  UpdateChannelRequest
  UpdateChannelResponse
  UpdateLiveLocationRequest
  UpdateMemberPartialRequest
  UpdateMemberPartialResponse
  UpdateMessagePartialRequest
  UpdateMessagePartialResponse
  UpdateMessageRequest
  UpdateMessageResponse
  UpdatePollPartialRequest
  UpdateReminderRequest
  UpdateReminderResponse
  UpdateThreadPartialRequest
  UpdateThreadPartialResponse
  UpdateUserGroupRequest
  UpdateUserPartialRequest
  UpdateUsersPartialRequest
  UpdateUsersResponse
  UploadChannelFileResponse
  UploadChannelResponse
  UpsertPushPreferencesRequest
  UpsertPushPreferencesResponse
  UserGroupMember
  UserGroupResponse
  UserMuteResponse
  UserRequest
  UserResponse
  VoteData
  WrappedUnreadCountsResponse
  WSAuthMessage
  WSEvent
)
allowed_events=(
  AIIndicatorClearEvent
  AIIndicatorStopEvent
  AIIndicatorUpdateEvent
  ChannelDeletedEvent
  ChannelHiddenEvent
  ChannelTruncatedEvent
  ChannelUpdatedEvent
  ChannelVisibleEvent
  DraftDeletedEvent
  DraftUpdatedEvent
  HealthCheckEvent
  MemberAddedEvent
  MemberRemovedEvent
  MemberUpdatedEvent
  MessageDeletedEvent
  MessageDeliveredEvent
  MessageNewEvent
  MessageReadEvent
  MessageUpdatedEvent
  NotificationAddedToChannelEvent
  NotificationChannelDeletedEvent
  NotificationChannelMutesUpdatedEvent
  NotificationInviteAcceptedEvent
  NotificationInvitedEvent
  NotificationInviteRejectedEvent
  NotificationMarkReadEvent
  NotificationMarkUnreadEvent
  NotificationMutesUpdatedEvent
  NotificationNewMessageEvent
  NotificationRemovedFromChannelEvent
  NotificationThreadMessageNewEvent
  PollClosedEvent
  PollDeletedEvent
  PollUpdatedEvent
  PollVoteCastedEvent
  PollVoteChangedEvent
  PollVoteRemovedEvent
  ReactionDeletedEvent
  ReactionNewEvent
  ReactionUpdatedEvent
  ReminderCreatedEvent
  ReminderDeletedEvent
  ReminderNotificationEvent
  ReminderUpdatedEvent
  ThreadUpdatedEvent
  TypingStartEvent
  TypingStopEvent
  UserBannedEvent
  UserMessagesDeletedEvent
  UserPresenceChangedEvent
  UserUnbannedEvent
  UserUpdatedEvent
  UserWatchingStartEvent
  UserWatchingStopEvent
)

# Models that keep the generated Hashable conformance; every other model has its
# Hashable extension stripped in step 4d. Uses the post-rename names (step 4b),
# unlike allowed_models above which uses the generator's original names.
allowed_hashable_models=(
  AppSettings
  Device
  MarkUnreadRequest
  PushPreference
  PushPreferenceInput
  Role
  SharedLocation
  UploadConfig
  UserGroup
  UserGroupMember
)

# Coding conformances for retained models after the renames in step 4b. Every
# generated model must belong to exactly one group so new models fail closed until
# their request/response direction is classified.
# Required because OpenAPI generator does not currently support emitting models
# with Encodable or Decodable based on how they are used in API calls. Every model
# is Codable which makes the SDK size larger.
encodable_only_models=(
  AddUserGroupMembersRequest
  BanRequest
  BlockUsersRequest
  CastPollVoteRequestBody
  ChannelDeliveredRequestPayload
  ChannelGetOrCreateRequest
  ChannelInput
  ChannelInputRequest
  ChannelMemberRequest
  CreateDeviceRequest
  CreateDraftRequest
  CreateGuestRequest
  CreatePollOptionRequestBody
  CreatePollRequestBody
  CreateReminderRequest
  CreateUserGroupRequest
  DeliveredMessagePayload
  EventRequest
  FlagRequest
  GroupedChannelsGroupRequest
  GroupedQueryChannelsRequest
  HideChannelRequest
  MarkChannelsReadRequest
  MarkReadRequest
  MarkUnreadRequest
  MessageActionRequest
  MessagePaginationParams
  MessageRequest
  MuteChannelRequest
  MuteRequest
  NewLocationRequestPayload
  PaginationParams
  PollOptionRequestBody
  PushPreferenceInput
  QueryBannedUsersPayload
  QueryChannelsRequest
  QueryDraftsRequest
  QueryMembersPayload
  QueryPollVotesRequestBody
  QueryReactionsRequest
  QueryRemindersRequest
  QueryThreadsRequest
  QueryUsersPayload
  ReactionRequest
  RemoveUserGroupMembersRequest
  SearchPayload
  SendEventRequest
  SendMessageRequest
  SendReactionRequest
  SyncRequest
  TranslateMessageRequest
  TruncateChannelRequest
  UnblockUsersRequest
  UnmuteChannelRequest
  UnmuteRequest
  UpdateChannelPartialRequest
  UpdateChannelRequest
  UpdateLiveLocationRequest
  UpdateMemberPartialRequest
  UpdateMessagePartialRequest
  UpdateMessageRequest
  UpdatePollPartialRequestBody
  UpdateReminderRequest
  UpdateThreadPartialRequest
  UpdateUserGroupRequest
  UpdateUserPartialRequest
  UpdateUsersPartialRequest
  UpsertPushPreferencesRequest
  UserRequest
  VoteDataRequestBody
)

decodable_only_models=(
  AppSettings
  BanResponse
  BlockUsersResponse
  BlockedUserResponse
  ChannelDetailPayload
  ChannelStateResponse
  CreateDraftResponse
  CreateGuestResponse
  CreateReminderResponse
  CurrentUserUnreads
  DeleteChannelResponse
  DeleteMessageResponse
  DeleteReactionResponse
  DraftMessagePayload
  DraftPayload
  FileUploadResponse
  FullUserResponse
  GetApplicationResponse
  GetBlockedUsersResponse
  GetDraftResponse
  GetMessageResponse
  GetOGResponse
  GetPinnedMessagesResponse
  GetRepliesResponse
  GetThreadResponse
  GroupedChannelsBucket
  GroupedQueryChannelsResponse
  ImageSize
  ImageUploadResponse
  ListDevicesResponse
  ListUserGroupsResponse
  MemberPayload
  MembersResponse
  MessageActionResponse
  MessageModerationDetailsPayload
  MessageReactionGroupPayload
  MessageReactionPayload
  MessageReactionsPayload
  MessageResponse
  MuteResponse
  MutedChannelPayload
  MutedChannelPayloadResponse
  MutedUserPayload
  OwnUserResponse
  ParsedPredefinedFilterResponse
  PendingMessageResponse
  PollOptionPayload
  PollOptionResponse
  PollPayload
  PollPayloadResponse
  PollVoteListResponse
  PollVotePayload
  PollVotePayloadResponse
  PushPreference
  QueryBannedUsersResponse
  QueryChannelsResponse
  QueryDraftsResponse
  QueryRemindersResponse
  QueryThreadsResponse
  QueryUsersResponse
  ReadStateResponse
  ReminderPayload
  SearchResponse
  SearchResult
  SearchResultMessage
  SearchRolesResponse
  SendMessageResponsePayload
  SendReactionResponse
  SharedLocation
  SharedLocationsResponse
  SyncResponse
  ThreadParticipantPayload
  ThreadResponse
  ThreadStateResponse
  TranslateMessageResponse
  TruncateChannelResponse
  UnblockUsersResponse
  UnmuteUsersResponse
  UnreadChannel
  UnreadChannelByType
  UnreadThread
  UpdateChannelPartialResponse
  UpdateChannelResponse
  UpdateMemberPartialResponse
  UpdateMessagePartialResponse
  UpdateMessageResponse
  UpdateReminderResponse
  UpdateThreadPartialResponse
  UpdateUsersResponse
  UploadChannelFileResponse
  UploadChannelResponse
  UploadConfig
  UpsertPushPreferencesResponse
  UserGroup
  UserGroupMember
  UserGroupResponse
  WSEvent
)

codable_models=(
  AttachmentActionPayload
  AttachmentFieldPayload
  ChannelCapability
  ConnectUserDetailsRequest
  DeliveryReceiptsPrivacySettings
  Device
  GiphyImageData
  GiphyImages
  MemberInfoPayload
  MemberUserRequest
  MessageAttachmentPayload
  ReadReceiptsPrivacySettings
  Role
  SortParamRequest
  TypingIndicatorPrivacySettings
  UserPayload
  UserPrivacySettings
  WSAuthMessage
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
    --opt encodable_filter_conditions=true \
    --opt raw_representable_over_enum=true \
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

# Keep generated v2 EndpointPath cases aligned with allowed_endpoints.
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
    contains "$base" "${allowed_models[@]}" "${allowed_events[@]}" && continue
    rm -f "$f"
  done
}
prune_models

prune_wsevent_cases() {
  local file="$OUTPUT_DIR_CHAT/models/WSEvent.swift"
  local allowed_events_csv
  allowed_events_csv="$(IFS=,; echo "${allowed_events[*]}")"

  python3 - "$file" "$allowed_events_csv" <<'PY'
import pathlib
import re
import sys

path = pathlib.Path(sys.argv[1])
allowed = set(filter(None, sys.argv[2].split(",")))
text = path.read_text()

cases = dict(re.findall(r"^    case (\w+)\((\w+)\)$", text, flags=re.M))
missing = allowed - set(cases.values())
if missing:
    raise SystemExit(f"Allowed events missing from WSEvent: {sorted(missing)}")

for name, model in cases.items():
    if model in allowed:
        continue
    text = re.sub(rf"^    case {name}\({model}\)\n", "", text, flags=re.M)
    text = re.sub(rf"^        case \.{name}\(let value\):\n.*\n", "", text, flags=re.M)
    text = re.sub(
        rf"^        (\}} else )?if dto\.type == \"[^\"]*\" \{{\n"
        rf"            let value = try container\.decode\({model}\.self\)\n"
        rf"            self = \.{name}\(value\)\n",
        "",
        text,
        flags=re.M,
    )
text = re.sub(r"(WSEventMapping\.self\)\n        )\} else if", r"\1if", text)

path.write_text(text)
PY
}
prune_wsevent_cases

# Remove a generated property (declaration, doc comment, init param, assignment,
#     CodingKeys case, encode(to:) line). Runs before publicize, so there are no access modifiers to
#     handle. Assumes the single-line init the generator emits (step 7 re-wraps).
remove_property() {
  local file="$OUTPUT_DIR_CHAT/models/$1.swift"
  awk -v p="$2" '
    function flush() { for (i = 1; i <= n; i++) print b[i]; n = 0 }
    { s = $0; sub(/^[[:space:]]+/, "", s) }
    s ~ /^(\/\/\/|@available)/         { b[++n] = $0; next }
    s ~ "^let " p ": "                 { n = 0; next }
    s ~ "^self\\." p " = " p "$"       { next }
    s ~ "^case " p "( =|$)"            { next }
    s ~ "^lhs\\." p " == rhs\\." p "( &&)?$" { next }
    s ~ "^hasher\\.combine\\(" p "\\)$"      { next }
    s ~ "^try container\\.encode(IfPresent)?\\(" p ", forKey: \\." p "\\)$" { next }
    s ~ /^init\(/ { sub("\\(" p ": [^,)]*, ", "("); sub(", " p ": [^,)]*", ""); sub("\\(" p ": [^,)]*\\)", "()") }
    { flush(); print }
  ' "$file" > "$file.tmp" && mv "$file.tmp" "$file"
  # Drop a trailing `&&` left dangling when the removed field was last in an == chain.
  perl -0777 -pi -e 's/ &&(\n\s*\})/$1/g' "$file"
  perl -0777 -pi -e 's/\n\h*enum CodingKeys: String, CodingKey, CaseIterable \{\n\h*\}\n//' "$file"
}

for model in "${allowed_models[@]}"; do
  remove_property "$model" duration
done

# Relax selected generated stored properties back to optional. Some models are
#     exposed as public API where a property was historically optional (e.g.
#     Device.createdAt was Date? before the OpenAPI migration). The memberwise init
#     parameter is relaxed too.
# Remove in the next major.
optionalize_property() {
  local file="$OUTPUT_DIR_CHAT/models/$1.swift"
  P="$2" perl -0777 -pi -e '
    my $p = $ENV{P};
    s/^(    let \Q$p\E: [^?\n]+)$/$1?/m;
    s/([(,]\s*)\Q$p\E: ([^,)\n]+)(?=[,)])/${1}$p: $2? = nil/;
  ' "$file"
}
optionalize_property DeviceResponse createdAt
optionalize_property PollOptionResponseData custom
optionalize_property PollResponseData custom
optionalize_property PollResponseData latestAnswers
optionalize_property PollResponseData latestVotesByOption
optionalize_property PollResponseData ownVotes
optionalize_property PollResponseData voteCountsByOption
optionalize_property PollResponseData votingVisibility
optionalize_property PollVoteResponseData optionId
optionalize_property Role createdAt
optionalize_property Role updatedAt
optionalize_property UnreadCountsChannel lastRead
optionalize_property UnreadCountsThread lastRead
optionalize_property UnreadCountsThread lastReadMessageId

require_property() {
  local file="$OUTPUT_DIR_CHAT/models/$1.swift"
  P="$2" perl -0777 -pi -e '
    my $p = $ENV{P};
    s/^(    let \Q$p\E: [^\n]+)\?$/$1/m;
    s/([(,]\s*)\Q$p\E: ([^,)\n]+?)\? = nil(?=[,)])/${1}$p: $2/;
  ' "$file"
}

retype_property() {
  local file="$OUTPUT_DIR_CHAT/models/$1.swift"
  P="$2" O="$3" N="$4" perl -0777 -pi -e '
    my ($p, $o, $n) = ($ENV{P}, $ENV{O}, $ENV{N});
    s/(?<!\w)\Q$p\E: \Q$o\E(?!\w)/$p: $n/g;
  ' "$file"
}
retype_property PollResponseData latestAnswers "[PollVoteResponseData]" "[PollVoteResponseData?]"
retype_property PollResponseData options "[PollOptionResponseData]" "[PollOptionResponseData?]"
retype_property PollResponseData ownVotes "[PollVoteResponseData]" "[PollVoteResponseData?]"
retype_property PollVotesResponse votes "[PollVoteResponseData]" "[PollVoteResponseData?]"
retype_property ReactionRequest type String MessageReactionType
retype_property ReactionResponse type String MessageReactionType
retype_property UnreadCountsChannel channelId String ChannelId
retype_property UnreadCountsChannelType channelType String ChannelType
retype_property SharedLocationResponseData channelCid String ChannelId
retype_property SharedLocationResponseData createdByDeviceId String DeviceId
retype_property SharedLocationResponseData latitude Float Double
retype_property SharedLocationResponseData longitude Float Double
retype_property SharedLocationResponseData messageId String MessageId
retype_property SharedLocationResponseData userId String UserId

# Workaround for non-optional public property being backed with optional property
# Remove in the next major.
restore_nonoptional_property() {
  local file="$OUTPUT_DIR_CHAT/models/$1.swift"
  P="$2" T="$3" D="$4" perl -0777 -pi -e '
    my ($p, $t, $d) = ($ENV{P}, $ENV{T}, $ENV{D});
    s/^    let \Q$p\E: \Q$t\E\?$/    private let _$p: $t?\n    public var $p: $t { _$p ?? $d }/m;
    s/^        self\.\Q$p\E = \Q$p\E$/        self._$p = $p/m;
    s{^    case \Q$p\E( = "[^"]*")?$}{"    case _$p" . (defined $1 ? $1 : " = \"$p\"")}me;
  ' "$file"
}

rename_property() {
  local file="$OUTPUT_DIR_CHAT/models/$1.swift"
  O="$2" N="$3" perl -0777 -pi -e '
    my ($o, $n) = ($ENV{O}, $ENV{N});
    s/^(\s*(?:public )?let )\Q$o\E:/$1$n:/mg;
    s/([(,]\s*)\Q$o\E:/$1$n:/g;
    s/^(\s*self\.)\Q$o\E = \Q$o\E$/$1$n = $n/mg;
    s{^(\s*)case \Q$o\E( = "[^"]*")?$}{"$1case $n" . (defined $2 ? $2 : " = \"$o\"")}mge;
    s/(lhs\.)\Q$o\E( == rhs\.)\Q$o\E/${1}$n${2}$n/g;
    s/(hasher\.combine\()\Q$o\E(\))/$1$n$2/g;
  ' "$file"
}

# 4b. Rename selected generated models for clarity and to avoid generic-name
#     pollution / collisions with hand-written SDK types. Runs AFTER prune_models
#     so allowed_models above still matches the generator's original names.
rename_generated_events() {
  local f base
  for f in "$OUTPUT_DIR_CHAT"/models/*Event.swift; do
    [ -e "$f" ] || continue
    base="$(basename "$f" .swift)"
    [[ "$base" == "WSEvent" ]] && continue
    rename_generated "$base" "${base}DTO"
  done
}
rename_generated_events

shape_wsevent() {
  local file="$OUTPUT_DIR_CHAT/models/WSEvent.swift"
  sed -i '' -E 's/^enum WSEvent: Codable, Hashable \{[[:space:]]*$/enum WSEvent: Codable {/' "$file"
  sed -i '' -E 's/^    var rawValue: Event \{[[:space:]]*$/    var rawValue: EventDTO {/' "$file"
  perl -0777 -pi -e 's/\n    func encode\(to encoder: Encoder\) throws \{\n.*?\n    \}\n//s' "$file"
}
shape_wsevent

rename_generated Action AttachmentActionPayload
rename_generated AppResponseFields AppSettings
rename_generated PushPreferencesResponse PushPreference
rename_generated DeviceResponse Device
rename_generated Field AttachmentFieldPayload
rename_generated FileUploadConfig UploadConfig
rename_generated ImageData GiphyImageData
rename_generated Images GiphyImages
rename_generated UnreadCountsChannel UnreadChannel
rename_generated UnreadCountsChannelType UnreadChannelByType
rename_generated UnreadCountsThread UnreadThread
rename_generated WrappedUnreadCountsResponse CurrentUserUnreads
rename_generated UserGroupResponse UserGroup
rename_generated GetUserGroupResponse UserGroupResponse
rename_generated UserResponse UserPayload
# These are equal
rename_generated_type UserResponseCommonFields UserPayload
# Has isInvisible and privacySettings, but SDK never consumes these
rename_generated_type UserResponsePrivacyFields UserPayload
rename_generated_type ChannelPushPreferencesResponse PushPreference
rename_generated_type AddUserGroupMembersResponse UserGroupResponse
rename_generated_type CreateUserGroupResponse UserGroupResponse
rename_generated_type RemoveUserGroupMembersResponse UserGroupResponse
rename_generated_type UpdateUserGroupResponse UserGroupResponse
rename_generated_type SearchUserGroupsResponse ListUserGroupsResponse
rename_generated SharedLocation NewLocationRequestPayload
rename_generated SharedLocationResponseData SharedLocation
rename_generated_type SharedLocationResponse SharedLocation
rename_generated MarkDeliveredRequest ChannelDeliveredRequestPayload
rename_generated CastPollVoteRequest CastPollVoteRequestBody
rename_generated CreatePollOptionRequest CreatePollOptionRequestBody
rename_generated CreatePollRequest CreatePollRequestBody
rename_generated PollOptionInput PollOptionRequestBody
rename_generated PollOptionResponseData PollOptionPayload
rename_generated PollResponse PollPayloadResponse
rename_generated PollResponseData PollPayload
rename_generated PollVoteResponse PollVotePayloadResponse
rename_generated PollVoteResponseData PollVotePayload
rename_generated PollVotesResponse PollVoteListResponse
rename_generated QueryPollVotesRequest QueryPollVotesRequestBody
rename_generated UpdatePollPartialRequest UpdatePollPartialRequestBody
rename_generated VoteData VoteDataRequestBody
rename_generated GetReactionsResponse MessageReactionsPayload
rename_generated ReactionResponse MessageReactionPayload
rename_generated_type QueryReactionsResponse MessageReactionsPayload
rename_generated ChannelMemberResponse MemberPayload
rename_generated ChannelMute MutedChannelPayload
rename_generated ChannelOwnCapability ChannelCapability
rename_generated ChannelResponse ChannelDetailPayload
# CHA-5170
rename_generated_type ChannelStateResponseFields ChannelStateResponse
rename_generated MuteChannelResponse MutedChannelPayloadResponse
rename_generated Attachment MessageAttachmentPayload
rename_generated ChannelMemberPartialResponse MemberInfoPayload
rename_generated DraftPayloadResponse DraftMessagePayload
rename_generated DraftResponse DraftPayload
rename_generated ModerationV2Response MessageModerationDetailsPayload
rename_generated ReactionGroupResponse MessageReactionGroupPayload
rename_generated ReminderResponseData ReminderPayload
rename_generated SendMessageResponse SendMessageResponsePayload
rename_generated UnmuteResponse UnmuteUsersResponse
rename_generated UserMuteResponse MutedUserPayload
rename_generated DeliveryReceiptsResponse DeliveryReceiptsPrivacySettings
rename_generated PrivacySettingsResponse UserPrivacySettings
rename_generated ReadReceiptsResponse ReadReceiptsPrivacySettings
rename_generated TypingIndicatorsResponse TypingIndicatorPrivacySettings
rename_generated ThreadParticipant ThreadParticipantPayload

rename_generated_type CreatePollRequestVotingVisibility VotingVisibility
rename_generated_type PushPreferenceInputChatLevel PushPreferenceLevel
rename_generated_type TranslateMessageRequestLanguage TranslationLanguage

rename_generated_type DeleteReminderResponse EmptyResponse
rename_generated_type EventResponse EmptyResponse
rename_generated_type FlagItemResponse EmptyResponse
rename_generated_type HideChannelResponse EmptyResponse
rename_generated_type MarkDeliveredResponse EmptyResponse
rename_generated_type MarkReadResponse EmptyResponse
rename_generated_type ModerationBanResponse EmptyResponse
rename_generated_type Response EmptyResponse
rename_generated_type ShowChannelResponse EmptyResponse
rename_generated_type UnbanResponse EmptyResponse

retype_property PushPreference chatLevel String PushPreferenceLevel
rename_property PushPreference chatLevel level
restore_nonoptional_property PushPreference level PushPreferenceLevel .all
restore_nonoptional_property UserGroup members "[UserGroupMember]" "[]"

optionalize_property UserPayload banned
optionalize_property UserPayload language
optionalize_property UserPayload teams

optionalize_property MemberPayload banned
optionalize_property MemberPayload channelRole
optionalize_property MemberPayload notificationsMuted
optionalize_property MemberPayload shadowBanned

optionalize_property OwnUserResponse banned
optionalize_property OwnUserResponse channelMutes
optionalize_property OwnUserResponse devices
optionalize_property OwnUserResponse invisible
optionalize_property OwnUserResponse language
optionalize_property OwnUserResponse mutes
optionalize_property OwnUserResponse teams
optionalize_property OwnUserResponse totalUnreadCount
optionalize_property OwnUserResponse unreadChannels
optionalize_property OwnUserResponse unreadThreads

# /sync replays events without fields the spec marks required.
# Remove when fixed: CHA-3482
optionalize_property ChannelHiddenEventDTO clearHistory
optionalize_property MessageDeletedEventDTO hardDelete
optionalize_property MessageNewEventDTO watcherCount

# member.* events sent from UpdateMembers lack the channel the spec marks required.
# Remove when fixed: CHA-5608
optionalize_property MemberAddedEventDTO channel
optionalize_property MemberRemovedEventDTO channel
optionalize_property MemberUpdatedEventDTO channel

remove_property PushPreferenceInput callLevel
remove_property PushPreferenceInput chatPreferences
remove_property PushPreferenceInput feedsLevel
remove_property PushPreferenceInput feedsPreferences
remove_property PushPreference callLevel
remove_property PushPreference chatPreferences
remove_property PushPreference feedsLevel
remove_property PushPreference feedsPreferences
remove_property UpdateUsersResponse membershipDeletionTaskId
remove_property UserGroupMember appPk
remove_property UserPayload blockedUserIds
remove_property SharedLocation channel
remove_property SharedLocation message
remove_property MutedChannelPayloadResponse channelMutes
remove_property MutedChannelPayloadResponse ownUser
remove_property OwnUserResponse unreadCount
# CHA-5096
remove_property ChannelGetOrCreateRequest hideForCreator
# CHA-5096
remove_property ChannelInput configOverrides
# CHA-5096
remove_property ChannelInput createdBy
# CHA-5096
remove_property ChannelInputRequest configOverrides
# CHA-5096
remove_property ChannelInputRequest createdBy
# CHA-5068
remove_property BanRequest ipBan
remove_property FlagRequest entityCreatorId
remove_property FlagRequest moderationPayload

# Unused channel context (cid, createdBy, id, type)
remove_property SendMessageRequest includeChannelContext
remove_property SendMessageResponsePayload channelContext

# TODO: reaction group reactors need CoreData and public API design first
remove_property MessageReactionGroupPayload latestReactionsBy

# CHA-5106
remove_property SearchPayload forceDefaultSearch
remove_property SearchPayload forceSqlV2Backend

# Unused
remove_property SearchPayload messageOptions
# Unused
remove_property SearchResponse resultsWarning

retype_property ChannelDetailPayload cid String ChannelId
retype_property ChannelDetailPayload config ChannelConfigWithInfo ChannelConfig
# Will be changed on the generation side later
# CHA-4621
require_property ChannelDetailPayload config
# CHA-5028
require_property ChannelStateResponse channel
# CHA-5105
require_property SearchResult message

# TODO: Legacy v1 payloads may contain null; keep optional until legacy compatibility is removed.
optionalize_property MessageResponse reactionCounts
optionalize_property SearchResultMessage reactionCounts

# v1 payloads may omit the count when it is zero.
optionalize_property ThreadResponse activeParticipantCount
optionalize_property ThreadStateResponse activeParticipantCount

# v1 read events may omit it.
optionalize_property ThreadResponse createdByUserId

for f in "$OUTPUT_DIR_CHAT"/models/*EventDTO.swift; do
  [ -e "$f" ] || continue
  base="$(basename "$f" .swift)"
  [[ "$base" == "HealthCheckEventDTO" ]] && continue
  retype_property "$base" cid String ChannelId
done
# CHA-5607
require_property ChannelHiddenEventDTO cid
require_property ChannelVisibleEventDTO cid
require_property DraftDeletedEventDTO cid
require_property DraftUpdatedEventDTO cid
require_property MemberAddedEventDTO cid
require_property MemberRemovedEventDTO cid
require_property MemberUpdatedEventDTO cid
require_property MessageDeletedEventDTO cid
require_property MessageDeliveredEventDTO cid
require_property MessageNewEventDTO cid
require_property MessageReadEventDTO cid
require_property MessageUpdatedEventDTO cid
require_property NotificationChannelDeletedEventDTO cid
require_property NotificationInvitedEventDTO cid
require_property NotificationMarkUnreadEventDTO cid
require_property NotificationRemovedFromChannelEventDTO cid
require_property NotificationThreadMessageNewEventDTO cid
require_property ReactionDeletedEventDTO cid
require_property ReactionNewEventDTO cid
require_property ReactionUpdatedEventDTO cid
require_property TypingStartEventDTO cid
require_property TypingStopEventDTO cid
require_property UserWatchingStartEventDTO cid
require_property UserWatchingStopEventDTO cid
# CHA-5587
retype_property MessageDeliveredEventDTO lastDeliveredAt String Date

# Unread by the SDK
remove_property AIIndicatorClearEventDTO channelId
remove_property AIIndicatorClearEventDTO channelType
remove_property AIIndicatorClearEventDTO custom
remove_property AIIndicatorClearEventDTO receivedAt
remove_property AIIndicatorStopEventDTO channelId
remove_property AIIndicatorStopEventDTO channelType
remove_property AIIndicatorStopEventDTO custom
remove_property AIIndicatorStopEventDTO receivedAt
remove_property AIIndicatorUpdateEventDTO channelId
remove_property AIIndicatorUpdateEventDTO channelType
remove_property AIIndicatorUpdateEventDTO custom
remove_property AIIndicatorUpdateEventDTO receivedAt
remove_property ChannelDeletedEventDTO channelCustom
remove_property ChannelDeletedEventDTO channelId
remove_property ChannelDeletedEventDTO channelMemberCount
remove_property ChannelDeletedEventDTO channelMessageCount
remove_property ChannelDeletedEventDTO channelType
remove_property ChannelDeletedEventDTO cid
remove_property ChannelDeletedEventDTO custom
remove_property ChannelDeletedEventDTO receivedAt
remove_property ChannelDeletedEventDTO team
remove_property ChannelHiddenEventDTO channelCustom
remove_property ChannelHiddenEventDTO channelId
remove_property ChannelHiddenEventDTO channelMemberCount
remove_property ChannelHiddenEventDTO channelMessageCount
remove_property ChannelHiddenEventDTO channelType
remove_property ChannelHiddenEventDTO custom
remove_property ChannelHiddenEventDTO receivedAt
remove_property ChannelHiddenEventDTO team
remove_property ChannelTruncatedEventDTO channelCustom
remove_property ChannelTruncatedEventDTO channelId
remove_property ChannelTruncatedEventDTO channelMemberCount
remove_property ChannelTruncatedEventDTO channelType
remove_property ChannelTruncatedEventDTO cid
remove_property ChannelTruncatedEventDTO custom
remove_property ChannelTruncatedEventDTO messageId
remove_property ChannelTruncatedEventDTO receivedAt
remove_property ChannelTruncatedEventDTO team
remove_property ChannelUpdatedEventDTO channelCustom
remove_property ChannelUpdatedEventDTO channelId
remove_property ChannelUpdatedEventDTO channelMemberCount
remove_property ChannelUpdatedEventDTO channelType
remove_property ChannelUpdatedEventDTO cid
remove_property ChannelUpdatedEventDTO custom
remove_property ChannelUpdatedEventDTO messageId
remove_property ChannelUpdatedEventDTO receivedAt
remove_property ChannelUpdatedEventDTO team
remove_property ChannelVisibleEventDTO channelCustom
remove_property ChannelVisibleEventDTO channelId
remove_property ChannelVisibleEventDTO channelMemberCount
remove_property ChannelVisibleEventDTO channelMessageCount
remove_property ChannelVisibleEventDTO channelType
remove_property ChannelVisibleEventDTO custom
remove_property ChannelVisibleEventDTO receivedAt
remove_property ChannelVisibleEventDTO team
remove_property DraftDeletedEventDTO custom
remove_property DraftDeletedEventDTO parentId
remove_property DraftDeletedEventDTO receivedAt
remove_property DraftUpdatedEventDTO custom
remove_property DraftUpdatedEventDTO parentId
remove_property DraftUpdatedEventDTO receivedAt
remove_property HealthCheckEventDTO cid
remove_property HealthCheckEventDTO custom
remove_property HealthCheckEventDTO receivedAt
remove_property MemberAddedEventDTO channelCustom
remove_property MemberAddedEventDTO channelId
remove_property MemberAddedEventDTO channelMemberCount
remove_property MemberAddedEventDTO channelMessageCount
remove_property MemberAddedEventDTO channelType
remove_property MemberAddedEventDTO custom
remove_property MemberAddedEventDTO receivedAt
remove_property MemberAddedEventDTO team
remove_property MemberRemovedEventDTO channelCustom
remove_property MemberRemovedEventDTO channelId
remove_property MemberRemovedEventDTO channelMemberCount
remove_property MemberRemovedEventDTO channelMessageCount
remove_property MemberRemovedEventDTO channelType
remove_property MemberRemovedEventDTO custom
remove_property MemberRemovedEventDTO member
remove_property MemberRemovedEventDTO receivedAt
remove_property MemberRemovedEventDTO team
remove_property MemberUpdatedEventDTO channelCustom
remove_property MemberUpdatedEventDTO channelId
remove_property MemberUpdatedEventDTO channelMemberCount
remove_property MemberUpdatedEventDTO channelMessageCount
remove_property MemberUpdatedEventDTO channelType
remove_property MemberUpdatedEventDTO custom
remove_property MemberUpdatedEventDTO receivedAt
remove_property MemberUpdatedEventDTO team
remove_property MessageDeletedEventDTO channelCustom
remove_property MessageDeletedEventDTO channelId
remove_property MessageDeletedEventDTO channelMemberCount
remove_property MessageDeletedEventDTO channelType
remove_property MessageDeletedEventDTO custom
remove_property MessageDeletedEventDTO messageId
remove_property MessageDeletedEventDTO receivedAt
remove_property MessageDeletedEventDTO team
remove_property MessageDeliveredEventDTO channelCustom
remove_property MessageDeliveredEventDTO channelId
remove_property MessageDeliveredEventDTO channelMemberCount
remove_property MessageDeliveredEventDTO channelMessageCount
remove_property MessageDeliveredEventDTO channelType
remove_property MessageDeliveredEventDTO custom
remove_property MessageDeliveredEventDTO receivedAt
remove_property MessageDeliveredEventDTO team
remove_property MessageNewEventDTO channelCustom
remove_property MessageNewEventDTO channelId
remove_property MessageNewEventDTO channelMemberCount
remove_property MessageNewEventDTO channelType
remove_property MessageNewEventDTO custom
remove_property MessageNewEventDTO messageId
remove_property MessageNewEventDTO parentAuthor
remove_property MessageNewEventDTO receivedAt
remove_property MessageNewEventDTO team
remove_property MessageNewEventDTO threadParticipants
remove_property MessageNewEventDTO unreadCount
remove_property MessageReadEventDTO channelCustom
remove_property MessageReadEventDTO channelId
remove_property MessageReadEventDTO channelMemberCount
remove_property MessageReadEventDTO channelMessageCount
remove_property MessageReadEventDTO channelType
remove_property MessageReadEventDTO custom
remove_property MessageReadEventDTO lastReadMessageId
remove_property MessageReadEventDTO receivedAt
remove_property MessageUpdatedEventDTO channelCustom
remove_property MessageUpdatedEventDTO channelId
remove_property MessageUpdatedEventDTO channelMemberCount
remove_property MessageUpdatedEventDTO channelType
remove_property MessageUpdatedEventDTO custom
remove_property MessageUpdatedEventDTO messageId
remove_property MessageUpdatedEventDTO messageUpdate
remove_property MessageUpdatedEventDTO receivedAt
remove_property MessageUpdatedEventDTO team
remove_property NotificationAddedToChannelEventDTO channelCustom
remove_property NotificationAddedToChannelEventDTO channelId
remove_property NotificationAddedToChannelEventDTO channelMemberCount
remove_property NotificationAddedToChannelEventDTO channelMessageCount
remove_property NotificationAddedToChannelEventDTO channelType
remove_property NotificationAddedToChannelEventDTO cid
remove_property NotificationAddedToChannelEventDTO custom
remove_property NotificationAddedToChannelEventDTO receivedAt
remove_property NotificationAddedToChannelEventDTO team
remove_property NotificationChannelDeletedEventDTO channelCustom
remove_property NotificationChannelDeletedEventDTO channelId
remove_property NotificationChannelDeletedEventDTO channelMemberCount
remove_property NotificationChannelDeletedEventDTO channelMessageCount
remove_property NotificationChannelDeletedEventDTO channelType
remove_property NotificationChannelDeletedEventDTO custom
remove_property NotificationChannelDeletedEventDTO receivedAt
remove_property NotificationChannelDeletedEventDTO team
remove_property NotificationChannelDeletedEventDTO unreadCount
remove_property NotificationChannelMutesUpdatedEventDTO custom
remove_property NotificationChannelMutesUpdatedEventDTO receivedAt
remove_property NotificationInviteAcceptedEventDTO channelCustom
remove_property NotificationInviteAcceptedEventDTO channelId
remove_property NotificationInviteAcceptedEventDTO channelMemberCount
remove_property NotificationInviteAcceptedEventDTO channelMessageCount
remove_property NotificationInviteAcceptedEventDTO channelType
remove_property NotificationInviteAcceptedEventDTO cid
remove_property NotificationInviteAcceptedEventDTO custom
remove_property NotificationInviteAcceptedEventDTO receivedAt
remove_property NotificationInviteAcceptedEventDTO team
remove_property NotificationInviteRejectedEventDTO channelCustom
remove_property NotificationInviteRejectedEventDTO channelId
remove_property NotificationInviteRejectedEventDTO channelMemberCount
remove_property NotificationInviteRejectedEventDTO channelMessageCount
remove_property NotificationInviteRejectedEventDTO channelType
remove_property NotificationInviteRejectedEventDTO cid
remove_property NotificationInviteRejectedEventDTO custom
remove_property NotificationInviteRejectedEventDTO receivedAt
remove_property NotificationInviteRejectedEventDTO team
remove_property NotificationInvitedEventDTO channelCustom
remove_property NotificationInvitedEventDTO channelId
remove_property NotificationInvitedEventDTO channelMemberCount
remove_property NotificationInvitedEventDTO channelMessageCount
remove_property NotificationInvitedEventDTO channelType
remove_property NotificationInvitedEventDTO custom
remove_property NotificationInvitedEventDTO receivedAt
remove_property NotificationInvitedEventDTO team
remove_property NotificationMarkReadEventDTO channelCustom
remove_property NotificationMarkReadEventDTO channelId
remove_property NotificationMarkReadEventDTO channelMemberCount
remove_property NotificationMarkReadEventDTO channelMessageCount
remove_property NotificationMarkReadEventDTO channelType
remove_property NotificationMarkReadEventDTO custom
remove_property NotificationMarkReadEventDTO receivedAt
remove_property NotificationMarkReadEventDTO team
remove_property NotificationMarkReadEventDTO threadId
remove_property NotificationMarkReadEventDTO unreadCount
remove_property NotificationMarkReadEventDTO unreadThreadMessages
remove_property NotificationMarkUnreadEventDTO channelCustom
remove_property NotificationMarkUnreadEventDTO channelId
remove_property NotificationMarkUnreadEventDTO channelMemberCount
remove_property NotificationMarkUnreadEventDTO channelMessageCount
remove_property NotificationMarkUnreadEventDTO channelType
remove_property NotificationMarkUnreadEventDTO custom
remove_property NotificationMarkUnreadEventDTO receivedAt
remove_property NotificationMarkUnreadEventDTO team
remove_property NotificationMarkUnreadEventDTO threadId
remove_property NotificationMarkUnreadEventDTO unreadCount
remove_property NotificationMarkUnreadEventDTO unreadThreadMessages
remove_property NotificationMutesUpdatedEventDTO custom
remove_property NotificationMutesUpdatedEventDTO receivedAt
remove_property NotificationNewMessageEventDTO channelCustom
remove_property NotificationNewMessageEventDTO channelId
remove_property NotificationNewMessageEventDTO channelMemberCount
remove_property NotificationNewMessageEventDTO channelType
remove_property NotificationNewMessageEventDTO cid
remove_property NotificationNewMessageEventDTO custom
remove_property NotificationNewMessageEventDTO messageId
remove_property NotificationNewMessageEventDTO parentAuthor
remove_property NotificationNewMessageEventDTO receivedAt
remove_property NotificationNewMessageEventDTO team
remove_property NotificationNewMessageEventDTO threadParticipants
remove_property NotificationNewMessageEventDTO unreadCount
remove_property NotificationNewMessageEventDTO watcherCount
remove_property NotificationRemovedFromChannelEventDTO channelCustom
remove_property NotificationRemovedFromChannelEventDTO channelId
remove_property NotificationRemovedFromChannelEventDTO channelMemberCount
remove_property NotificationRemovedFromChannelEventDTO channelMessageCount
remove_property NotificationRemovedFromChannelEventDTO channelType
remove_property NotificationRemovedFromChannelEventDTO custom
remove_property NotificationRemovedFromChannelEventDTO receivedAt
remove_property NotificationRemovedFromChannelEventDTO team
remove_property NotificationThreadMessageNewEventDTO channelCustom
remove_property NotificationThreadMessageNewEventDTO channelId
remove_property NotificationThreadMessageNewEventDTO channelMemberCount
remove_property NotificationThreadMessageNewEventDTO channelType
remove_property NotificationThreadMessageNewEventDTO custom
remove_property NotificationThreadMessageNewEventDTO messageId
remove_property NotificationThreadMessageNewEventDTO parentAuthor
remove_property NotificationThreadMessageNewEventDTO receivedAt
remove_property NotificationThreadMessageNewEventDTO team
remove_property NotificationThreadMessageNewEventDTO threadId
remove_property NotificationThreadMessageNewEventDTO threadParticipants
remove_property NotificationThreadMessageNewEventDTO unreadThreadMessages
remove_property NotificationThreadMessageNewEventDTO watcherCount
remove_property PollClosedEventDTO activityId
remove_property PollClosedEventDTO cid
remove_property PollClosedEventDTO custom
remove_property PollClosedEventDTO messageId
remove_property PollClosedEventDTO receivedAt
remove_property PollDeletedEventDTO activityId
remove_property PollDeletedEventDTO cid
remove_property PollDeletedEventDTO custom
remove_property PollDeletedEventDTO messageId
remove_property PollDeletedEventDTO receivedAt
remove_property PollUpdatedEventDTO activityId
remove_property PollUpdatedEventDTO cid
remove_property PollUpdatedEventDTO custom
remove_property PollUpdatedEventDTO messageId
remove_property PollUpdatedEventDTO receivedAt
remove_property PollVoteCastedEventDTO activityId
remove_property PollVoteCastedEventDTO cid
remove_property PollVoteCastedEventDTO custom
remove_property PollVoteCastedEventDTO messageId
remove_property PollVoteCastedEventDTO receivedAt
remove_property PollVoteChangedEventDTO activityId
remove_property PollVoteChangedEventDTO cid
remove_property PollVoteChangedEventDTO custom
remove_property PollVoteChangedEventDTO messageId
remove_property PollVoteChangedEventDTO receivedAt
remove_property PollVoteRemovedEventDTO activityId
remove_property PollVoteRemovedEventDTO cid
remove_property PollVoteRemovedEventDTO custom
remove_property PollVoteRemovedEventDTO messageId
remove_property PollVoteRemovedEventDTO receivedAt
remove_property ReactionDeletedEventDTO channelCustom
remove_property ReactionDeletedEventDTO channelId
remove_property ReactionDeletedEventDTO channelMemberCount
remove_property ReactionDeletedEventDTO channelType
remove_property ReactionDeletedEventDTO custom
remove_property ReactionDeletedEventDTO messageId
remove_property ReactionDeletedEventDTO receivedAt
remove_property ReactionDeletedEventDTO team
remove_property ReactionDeletedEventDTO threadParticipants
remove_property ReactionNewEventDTO channelCustom
remove_property ReactionNewEventDTO channelId
remove_property ReactionNewEventDTO channelMemberCount
remove_property ReactionNewEventDTO channelType
remove_property ReactionNewEventDTO custom
remove_property ReactionNewEventDTO messageId
remove_property ReactionNewEventDTO receivedAt
remove_property ReactionNewEventDTO team
remove_property ReactionNewEventDTO threadParticipants
remove_property ReactionUpdatedEventDTO channelCustom
remove_property ReactionUpdatedEventDTO channelId
remove_property ReactionUpdatedEventDTO channelMemberCount
remove_property ReactionUpdatedEventDTO channelType
remove_property ReactionUpdatedEventDTO custom
remove_property ReactionUpdatedEventDTO messageId
remove_property ReactionUpdatedEventDTO receivedAt
remove_property ReactionUpdatedEventDTO team
remove_property ReminderCreatedEventDTO cid
remove_property ReminderCreatedEventDTO custom
remove_property ReminderCreatedEventDTO parentId
remove_property ReminderCreatedEventDTO receivedAt
remove_property ReminderCreatedEventDTO userId
remove_property ReminderDeletedEventDTO cid
remove_property ReminderDeletedEventDTO custom
remove_property ReminderDeletedEventDTO parentId
remove_property ReminderDeletedEventDTO receivedAt
remove_property ReminderDeletedEventDTO userId
remove_property ReminderNotificationEventDTO cid
remove_property ReminderNotificationEventDTO custom
remove_property ReminderNotificationEventDTO parentId
remove_property ReminderNotificationEventDTO receivedAt
remove_property ReminderNotificationEventDTO userId
remove_property ReminderUpdatedEventDTO cid
remove_property ReminderUpdatedEventDTO custom
remove_property ReminderUpdatedEventDTO parentId
remove_property ReminderUpdatedEventDTO receivedAt
remove_property ReminderUpdatedEventDTO userId
remove_property ThreadUpdatedEventDTO channelId
remove_property ThreadUpdatedEventDTO channelType
remove_property ThreadUpdatedEventDTO cid
remove_property ThreadUpdatedEventDTO custom
remove_property ThreadUpdatedEventDTO receivedAt
remove_property TypingStartEventDTO channelId
remove_property TypingStartEventDTO channelType
remove_property TypingStartEventDTO custom
remove_property TypingStartEventDTO receivedAt
remove_property TypingStopEventDTO channelId
remove_property TypingStopEventDTO channelType
remove_property TypingStopEventDTO custom
remove_property TypingStopEventDTO receivedAt
remove_property UserBannedEventDTO channelCustom
remove_property UserBannedEventDTO channelId
remove_property UserBannedEventDTO channelMemberCount
remove_property UserBannedEventDTO channelMessageCount
remove_property UserBannedEventDTO channelType
remove_property UserBannedEventDTO custom
remove_property UserBannedEventDTO receivedAt
remove_property UserBannedEventDTO reviewQueueItemId
remove_property UserBannedEventDTO team
remove_property UserBannedEventDTO totalBans
remove_property UserMessagesDeletedEventDTO channelCustom
remove_property UserMessagesDeletedEventDTO channelId
remove_property UserMessagesDeletedEventDTO channelMemberCount
remove_property UserMessagesDeletedEventDTO channelMessageCount
remove_property UserMessagesDeletedEventDTO channelType
remove_property UserMessagesDeletedEventDTO cid
remove_property UserMessagesDeletedEventDTO custom
remove_property UserMessagesDeletedEventDTO receivedAt
remove_property UserMessagesDeletedEventDTO team
remove_property UserPresenceChangedEventDTO custom
remove_property UserPresenceChangedEventDTO receivedAt
remove_property UserUnbannedEventDTO channelCustom
remove_property UserUnbannedEventDTO channelId
remove_property UserUnbannedEventDTO channelMemberCount
remove_property UserUnbannedEventDTO channelMessageCount
remove_property UserUnbannedEventDTO channelType
remove_property UserUnbannedEventDTO createdBy
remove_property UserUnbannedEventDTO custom
remove_property UserUnbannedEventDTO receivedAt
remove_property UserUnbannedEventDTO shadow
remove_property UserUnbannedEventDTO team
remove_property UserUpdatedEventDTO custom
remove_property UserUpdatedEventDTO receivedAt
remove_property UserWatchingStartEventDTO channelId
remove_property UserWatchingStartEventDTO channelType
remove_property UserWatchingStartEventDTO custom
remove_property UserWatchingStartEventDTO receivedAt
remove_property UserWatchingStopEventDTO channelId
remove_property UserWatchingStopEventDTO channelType
remove_property UserWatchingStopEventDTO custom
remove_property UserWatchingStopEventDTO receivedAt

remove_type() {
  local file="$OUTPUT_DIR_CHAT/models/$1.swift"
  awk -v e="$2" '
    $0 ~ "^final class " e ":" { skip = 1; next }
    skip && /^}$/               { skip = 0; next }
    skip                        { next }
    { print }
  ' "$file" > "$file.tmp" && mv "$file.tmp" "$file"
}
remove_type PushPreferenceInput PushPreferenceInputCallLevel
remove_type PushPreferenceInput PushPreferenceInputFeedsLevel

# Give a generated model mutable stored properties, so it can replace a hand-written
#     public type whose properties were var. Mutable state rules out checked Sendable,
#     hence the relaxed conformance. Runs before publicize_model, which anchors on the
#     resulting var lines.
make_model_mutable() {
  local file="$OUTPUT_DIR_CHAT/models/$1.swift"
  sed -i '' -E \
    -e 's/^(final class [A-Za-z0-9_]+): Sendable,/\1: @unchecked Sendable,/' \
    -e 's/^    let /    var /' \
    "$file"
}
make_model_mutable DeliveryReceiptsPrivacySettings
make_model_mutable ReadReceiptsPrivacySettings
make_model_mutable TypingIndicatorPrivacySettings
make_model_mutable UserPrivacySettings

# 4c. Expose selected generated models as public API. The type and its stored
#     properties become public, along with the generated Hashable conformance
#     (== and hash(into:)); the memberwise init and CodingKeys stay internal.
publicize_model() {
  local file="$OUTPUT_DIR_CHAT/models/$1.swift"
  sed -i '' -E \
    -e 's/^final class /public final class /' \
    -e 's/^    let /    public let /' \
    -e 's/^    var /    public var /' \
    -e 's/^    static func == /    public static func == /' \
    -e 's/^    func hash\(into /    public func hash(into /' \
    "$file"
}
publicize_model AppSettings
publicize_model CurrentUserUnreads
publicize_model DeliveryReceiptsPrivacySettings
publicize_model Device
publicize_model PushPreference
publicize_model ReadReceiptsPrivacySettings
publicize_model Role
publicize_model SharedLocation
publicize_model TypingIndicatorPrivacySettings
publicize_model UnmuteUsersResponse
publicize_model UnreadChannel
publicize_model UnreadChannelByType
publicize_model UnreadThread
publicize_model UploadConfig
publicize_model UserGroup
publicize_model UserGroupMember
publicize_model UserPrivacySettings

# Expose a generated RawRepresentable class as public API. Unlike publicize_model, the
#     init must be public too — it is the RawRepresentable requirement — along with every
#     static let holding a known value. The class is looked up by name, since the file
#     named after a model also holds the classes generated for its string properties.
publicize_raw_representable() {
  local file="$OUTPUT_DIR_CHAT/models/$1.swift"
  awk -v n="${2:-$1}" '
    $0 ~ "^final class " n ":" { sub(/^final class /, "public final class "); inside = 1; print; next }
    inside && /^}$/       { inside = 0; print; next }
    inside {
      sub(/^    let /, "    public let ")
      sub(/^    init\(/, "    public init(")
      sub(/^    static let /, "    public static let ")
    }
    { print }
  ' "$file" > "$file.tmp" && mv "$file.tmp" "$file"
}
publicize_raw_representable ChannelCapability
publicize_raw_representable CreatePollRequestBody VotingVisibility
publicize_raw_representable PushPreferenceInput PushPreferenceLevel
publicize_raw_representable TranslateMessageRequest TranslationLanguage

# Mark a generated RawRepresentable value as deprecated while keeping its legacy
# raw value available. Fail if the generated declaration changes so the annotation
# cannot silently disappear from the public API.
deprecate_raw_representable_value() {
  local file="$OUTPUT_DIR_CHAT/models/$1.swift"
  local type="$2"
  local value="$3"
  local renamed="$4"
  if ! awk -v t="$type" -v v="$value" -v r="$renamed" '
    $0 ~ "^public final class " t ":" { inside = 1 }
    inside && $0 ~ "^    public static let " v " = " {
      print "    @available(*, deprecated, renamed: \"" r "\")"
      matches++
    }
    { print }
    inside && /^}$/ { inside = 0 }
    END {
      if (matches != 1) {
        print "Expected exactly one " t "." v " declaration, found " matches > "/dev/stderr"
        exit 1
      }
    }
  ' "$file" > "$file.tmp"; then
    rm -f "$file.tmp"
    return 1
  fi
  mv "$file.tmp" "$file"
}
deprecate_raw_representable_value PushPreferenceInput PushPreferenceLevel mentions directMentions

# Expose a generated model's memberwise init, for models whose hand-written public
#     counterpart had a public init.
publicize_init() {
  local file="$OUTPUT_DIR_CHAT/models/$1.swift"
  sed -i '' -E 's/^    init\(/    public init(/' "$file"
}
publicize_init DeliveryReceiptsPrivacySettings
publicize_init ReadReceiptsPrivacySettings
publicize_init TypingIndicatorPrivacySettings

# Give a generated memberwise init parameter a default value, restoring one the
#     hand-written public init had.
default_init_parameter() {
  local file="$OUTPUT_DIR_CHAT/models/$1.swift"
  P="$2" D="$3" perl -0777 -pi -e '
    my ($p, $d) = ($ENV{P}, $ENV{D});
    s/([(,]\s*)\Q$p\E: ([^,)\n=]+)(?=[,)])/${1}$p: $2 = $d/;
  ' "$file"
}
default_init_parameter DeliveryReceiptsPrivacySettings enabled true
default_init_parameter ReadReceiptsPrivacySettings enabled true
default_init_parameter TypingIndicatorPrivacySettings enabled true

# 4d. Keep only the coding direction each internal model needs.
# Required because OpenAPI generator emits all models with Codable conformance
# even when it is used for decoding or encoding only. This helps to save
# SDK size when Codable is reduced to Encodable or Decodable.
# Requires bigger change in the generator for applying it there.
apply_directional_coding_conformances() {
  local encodable_csv decodable_csv codable_csv
  encodable_csv="$(IFS=,; echo "${encodable_only_models[*]}")"
  decodable_csv="$(IFS=,; echo "${decodable_only_models[*]},${allowed_events[*]/%/DTO}")"
  codable_csv="$(IFS=,; echo "${codable_models[*]}")"

  python3 - \
    "$OUTPUT_DIR_CHAT/models" \
    "$encodable_csv" \
    "$decodable_csv" \
    "$codable_csv" <<'PY'
import pathlib
import re
import sys

models_dir = pathlib.Path(sys.argv[1])
groups = {
    "Encodable": set(filter(None, sys.argv[2].split(","))),
    "Decodable": set(filter(None, sys.argv[3].split(","))),
    "Codable": set(filter(None, sys.argv[4].split(","))),
}

all_classified = set()
for direction, names in groups.items():
    overlap = all_classified.intersection(names)
    if overlap:
        raise SystemExit(f"Models classified more than once: {sorted(overlap)}")
    all_classified.update(names)

generated = {path.stem for path in models_dir.glob("*.swift")}
unclassified = generated - all_classified
missing = all_classified - generated
if unclassified:
    raise SystemExit(f"Unclassified generated models: {sorted(unclassified)}")
if missing:
    raise SystemExit(f"Classified models missing from generated output: {sorted(missing)}")

declaration = re.compile(
    r"^(\s*(?:public )?(?:final )?(?:class|struct|enum)\s+([A-Za-z0-9_]+)[^:\n]*:\s*)(.*)$"
)

for direction, names in groups.items():
    for name in sorted(names):
        path = models_dir / f"{name}.swift"
        lines = path.read_text().splitlines(keepends=True)
        output = []
        top_level_conformances = None

        for line in lines:
            ending = "\n" if line.endswith("\n") else ""
            content = line[:-1] if ending else line
            match = declaration.match(content)
            if match:
                prefix, declared_name, conformances = match.groups()
                if declared_name == name:
                    if direction != "Codable":
                        conformances = re.sub(r"\bCodable\b", direction, conformances)
                        if direction == "Decodable":
                            conformances = re.sub(r",\s*JSONEncodable\b", "", conformances)
                    content = f"{prefix}{conformances}"
                    top_level_conformances = conformances
            output.append(content + ending)

        if top_level_conformances is None:
            raise SystemExit(f"Could not find the top-level declaration for {name}")
        if not re.search(rf"\b{direction}\b", top_level_conformances):
            raise SystemExit(f"{name} does not conform to {direction}")
        if direction == "Decodable" and re.search(
            r"\bEncodable\b|\bJSONEncodable\b", top_level_conformances
        ):
            raise SystemExit(f"{name} retains an encoding conformance")

        path.write_text("".join(output))
PY
}
apply_directional_coding_conformances

# 4e. Strip the generated Hashable conformance from every model not in
#     allowed_hashable_models. The Hashable extension is always the last block in
#     the file (opening at column 0, running to EOF), so delete from its opening
#     line to end of file; swiftformat (step 5) tidies the leftover blank line.
strip_hashable_conformance() {
  local f base
  for f in "$OUTPUT_DIR_CHAT"/models/*.swift; do
    [ -e "$f" ] || continue
    base="$(basename "$f" .swift)"
    contains "$base" "${allowed_hashable_models[@]}" && continue
    sed -i '' -E "/^extension ${base}: Hashable \{\$/,\$d" "$f"
  done
}
strip_hashable_conformance

strip_streamcore_imports() {
  find "$OUTPUT_DIR_CHAT" -name '*.swift' -exec sed -i '' '/^import StreamCore$/d' {} +
}
strip_streamcore_imports

# 5. Format.
swiftformat --config "$REPO_ROOT/.swiftformat" "$OUTPUT_DIR_CHAT"

# 7. Generate a v1/v2 compatible `init(from:)` and splice it into the model's class
#    body, where a `required` initializer is allowed.
splice_generated_decoders() {
  local generated="$OUTPUT_DIR_CHAT/OpenAPIDecoders.generated.swift"
  python3 - "$generated" "$OUTPUT_DIR_CHAT/models" <<'PY'
import pathlib
import re
import sys

generated = pathlib.Path(sys.argv[1])
models_dir = pathlib.Path(sys.argv[2])
blocks = re.split(r"^// sourcery:decoder:(\w+)$", generated.read_text(), flags=re.M)

for name, body in zip(blocks[1::2], blocks[2::2]):
    path = models_dir / f"{name}.swift"
    lines = path.read_text().splitlines(keepends=True)
    closing = max(i for i, line in enumerate(lines) if line.rstrip() == "}")
    lines[closing:closing] = ["\n"] + [f"{line}\n" for line in body.strip("\n").splitlines()]
    path.write_text("".join(lines))

generated.unlink()
PY
}
sourcery --config "$REPO_ROOT/Sources/StreamChat/.openapi.sourcery.yml"
splice_generated_decoders

# 8. Wrap generated OpenAPI function declarations that exceed the maximum width.
swiftformat "$OUTPUT_DIR_CHAT" \
  --rules wrapArguments \
  --wrapparameters before-first \
  --wraparguments preserve \
  --maxwidth 100
