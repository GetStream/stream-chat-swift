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

# Remove generated properties (declaration, doc comment, init param, assignment,
#     CodingKeys case, encode(to:) line). Runs before publicize, so there are no access modifiers to
#     handle. Assumes the single-line init the generator emits (step 7 re-wraps).
remove_property() {
  local file="$OUTPUT_DIR_CHAT/models/$1.swift"
  local p
  for p in "${@:2}"; do
    awk -v p="$p" '
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
  done
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
remove_property AIIndicatorClearEventDTO channelId channelType custom receivedAt
remove_property AIIndicatorStopEventDTO channelId channelType custom receivedAt
remove_property AIIndicatorUpdateEventDTO channelId channelType custom receivedAt
remove_property BanRequest deleteMessages ipBan
remove_property ChannelDeletedEventDTO channelCustom channelId channelMemberCount channelMessageCount channelType cid custom receivedAt team
remove_property ChannelGetOrCreateRequest hideForCreator memberCustomInclude threadUnreadCounts
remove_property ChannelHiddenEventDTO channelCustom channelId channelMemberCount channelMessageCount channelType custom receivedAt team
remove_property ChannelInput autoTranslationEnabled autoTranslationLanguage configOverrides createdBy createdById disabled frozen truncatedById
remove_property ChannelInputRequest autoTranslationEnabled autoTranslationLanguage configOverrides createdBy disabled frozen
remove_property ChannelMemberRequest channelRole user
remove_property ChannelStateResponse hideMessagesBefore
remove_property ChannelTruncatedEventDTO channelCustom channelId channelMemberCount channelType cid custom messageId receivedAt team
remove_property ChannelUpdatedEventDTO channelCustom channelId channelMemberCount channelType cid custom messageId receivedAt team
remove_property ChannelVisibleEventDTO channelCustom channelId channelMemberCount channelMessageCount channelType custom receivedAt team
remove_property CreateDeviceRequest hardwareId voipToken
remove_property CreatePollRequestBody team
remove_property DraftDeletedEventDTO custom parentId receivedAt
remove_property DraftUpdatedEventDTO custom parentId receivedAt
remove_property FlagRequest entityCreatorId moderationPayload
remove_property FullUserResponse banExpires deletedAt latestHiddenChannels revokeTokensIssuedBefore
remove_property GetOGResponse actions authorIcon authorLink color fallback fields footer footerIcon giphy originalHeight originalWidth pretext type
remove_property GroupedChannelsGroupRequest prev
remove_property HealthCheckEventDTO cid custom receivedAt
remove_property MarkReadRequest messageId
remove_property MemberAddedEventDTO channelCustom channelId channelMemberCount channelMessageCount channelType custom receivedAt team
remove_property MemberRemovedEventDTO channelCustom channelId channelMemberCount channelMessageCount channelType custom member receivedAt team
remove_property MemberUpdatedEventDTO channelCustom channelId channelMemberCount channelMessageCount channelType custom receivedAt team
remove_property MessageDeletedEventDTO channelCustom channelId channelMemberCount channelType custom messageId receivedAt team
remove_property MessageDeliveredEventDTO channelCustom channelId channelMemberCount channelMessageCount channelType custom receivedAt team
remove_property MessageModerationDetailsPayload blocklistMatched
remove_property MessageNewEventDTO channelCustom channelId channelMemberCount channelType custom messageId parentAuthor receivedAt team threadParticipants unreadCount
remove_property MessagePaginationParams createdAtAfter createdAtAfterOrEqual createdAtAround createdAtBefore createdAtBeforeOrEqual
remove_property MessageReactionGroupPayload latestReactionsBy
remove_property MessageReadEventDTO channelCustom channelId channelMemberCount channelMessageCount channelType custom lastReadMessageId receivedAt
remove_property MessageRequest mml pinnedAt
remove_property MessageUpdatedEventDTO channelCustom channelId channelMemberCount channelType custom messageId messageUpdate receivedAt team
remove_property MutedChannelPayloadResponse channelMutes ownUser
remove_property MutedUserPayload user
remove_property NotificationAddedToChannelEventDTO channelCustom channelId channelMemberCount channelMessageCount channelType cid custom receivedAt team
remove_property NotificationChannelDeletedEventDTO channelCustom channelId channelMemberCount channelMessageCount channelType custom receivedAt team unreadCount
remove_property NotificationChannelMutesUpdatedEventDTO custom receivedAt
remove_property NotificationInviteAcceptedEventDTO channelCustom channelId channelMemberCount channelMessageCount channelType cid custom receivedAt team
remove_property NotificationInviteRejectedEventDTO channelCustom channelId channelMemberCount channelMessageCount channelType cid custom receivedAt team
remove_property NotificationInvitedEventDTO channelCustom channelId channelMemberCount channelMessageCount channelType custom receivedAt team
remove_property NotificationMarkReadEventDTO channelCustom channelId channelMemberCount channelMessageCount channelType custom receivedAt team threadId unreadCount unreadThreadMessages
remove_property NotificationMarkUnreadEventDTO channelCustom channelId channelMemberCount channelMessageCount channelType custom receivedAt team threadId unreadCount unreadThreadMessages
remove_property NotificationMutesUpdatedEventDTO custom receivedAt
remove_property NotificationNewMessageEventDTO channelCustom channelId channelMemberCount channelType cid custom messageId parentAuthor receivedAt team threadParticipants unreadCount watcherCount
remove_property NotificationRemovedFromChannelEventDTO channelCustom channelId channelMemberCount channelMessageCount channelType custom receivedAt team
remove_property NotificationThreadMessageNewEventDTO channelCustom channelId channelMemberCount channelType custom messageId parentAuthor receivedAt team threadId threadParticipants unreadThreadMessages watcherCount
remove_property OwnUserResponse unreadCount
remove_property PaginationParams idGt idGte idLt idLte
remove_property PendingMessageResponse channel user
remove_property PollClosedEventDTO activityId cid custom messageId receivedAt
remove_property PollDeletedEventDTO activityId cid custom messageId receivedAt
remove_property PollOptionPayload textI18n
remove_property PollPayload descriptionI18n nameI18n
remove_property PollUpdatedEventDTO activityId cid custom messageId receivedAt
remove_property PollVoteCastedEventDTO activityId cid custom messageId receivedAt
remove_property PollVoteChangedEventDTO activityId cid custom messageId receivedAt
remove_property PollVotePayload answerTextI18n
remove_property PollVoteRemovedEventDTO activityId cid custom messageId receivedAt
remove_property PushPreference callLevel chatPreferences feedsLevel feedsPreferences
remove_property PushPreferenceInput callLevel chatPreferences feedsLevel feedsPreferences userId
remove_property QueryBannedUsersPayload createdAtAfter createdAtAfterOrEqual createdAtBefore createdAtBeforeOrEqual
remove_property QueryChannelsRequest memberCustomInclude
remove_property QueryDraftsRequest prev
remove_property QueryDraftsResponse prev
remove_property QueryMembersPayload createdAtAfter createdAtAfterOrEqual createdAtBefore createdAtBeforeOrEqual members userIdGt userIdGte userIdLt userIdLte
remove_property QueryReactionsRequest next prev sort
remove_property QueryRemindersRequest prev
remove_property QueryRemindersResponse prev
remove_property QueryThreadsRequest prev
remove_property QueryUsersPayload idGt idGte idLt idLte includeDeactivatedUsers
remove_property ReactionDeletedEventDTO channelCustom channelId channelMemberCount channelType custom messageId receivedAt team threadParticipants
remove_property ReactionNewEventDTO channelCustom channelId channelMemberCount channelType custom messageId receivedAt team threadParticipants
remove_property ReactionRequest createdAt updatedAt
remove_property ReactionUpdatedEventDTO channelCustom channelId channelMemberCount channelType custom messageId receivedAt team
remove_property ReminderCreatedEventDTO cid custom parentId receivedAt userId
remove_property ReminderDeletedEventDTO cid custom parentId receivedAt userId
remove_property ReminderNotificationEventDTO cid custom parentId receivedAt userId
remove_property ReminderPayload user
remove_property ReminderUpdatedEventDTO cid custom parentId receivedAt userId
remove_property SearchPayload forceDefaultSearch forceSqlV2Backend messageOptions query
remove_property SearchResponse previous resultsWarning
remove_property SendMessageRequest includeChannelContext includeMentionedMembers keepChannelHidden
remove_property SendMessageResponsePayload channelContext mentionedMembers
remove_property SharedLocation channel message
remove_property ThreadUpdatedEventDTO channelId channelType cid custom receivedAt
remove_property TruncateChannelRequest memberIds truncatedAt
remove_property TypingStartEventDTO channelId channelType custom receivedAt
remove_property TypingStopEventDTO channelId channelType custom receivedAt
remove_property UnmuteChannelRequest expiration
remove_property UpdateChannelRequest cooldown removeFilterTags skipPush
remove_property UpdateMessagePartialRequest skipEnrichUrl skipPush
remove_property UpdateUsersResponse membershipDeletionTaskId
remove_property UserBannedEventDTO channelCustom channelId channelMemberCount channelMessageCount channelType custom receivedAt reviewQueueItemId team totalBans
remove_property UserGroupMember appPk
remove_property UserMessagesDeletedEventDTO channelCustom channelId channelMemberCount channelMessageCount channelType cid custom receivedAt team
remove_property UserPayload blockedUserIds
remove_property UserPresenceChangedEventDTO custom receivedAt
remove_property UserRequest invisible language privacySettings
remove_property UserUnbannedEventDTO channelCustom channelId channelMemberCount channelMessageCount channelType createdBy custom receivedAt shadow team
remove_property UserUpdatedEventDTO custom receivedAt
remove_property UserWatchingStartEventDTO channelId channelType custom receivedAt
remove_property UserWatchingStopEventDTO channelId channelType custom receivedAt

remove_type() {
  local file="$OUTPUT_DIR_CHAT/models/$1.swift"
  awk -v e="$2" '
    $0 ~ "^final class " e ":" { skip = 1; next }
    skip && /^}$/               { skip = 0; next }
    skip                        { next }
    { print }
  ' "$file" > "$file.tmp" && mv "$file.tmp" "$file"
}
remove_type BanRequest BanRequestDeleteMessages
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
