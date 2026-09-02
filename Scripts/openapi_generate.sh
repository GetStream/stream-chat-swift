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
    blockUsers
    castPollVote
    createDevice
    createDraft
    createPoll
    createPollOption
    createReminder
    createUserGroup
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
    getApp
    getDraft
    getBlockedUsers
    getOG
    getPinnedMessages
    getReactions
    getThread
    getUserGroup
    getUserLiveLocations
    hideChannel
    listDevices
    listUserGroups
    markDelivered
    mute
    muteChannel
    queryDrafts
    queryMembers
    queryPollVotes
    queryReactions
    queryReminders
    queryThreads
    queryUsers
    removeUserGroupMembers
    searchRoles
    searchUserGroups
    sendMessage
    sendReaction
    showChannel
    stopWatchingChannel
    translateMessage
    truncateChannel
    unblockUsers
    unmute
    unmuteChannel
    unreadCounts
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
  BlockedUserResponse
  BlockUsersRequest
  BlockUsersResponse
  CastPollVoteRequest
  ChannelMemberPartialResponse
  ChannelMemberRequest
  ChannelMemberResponse
  ChannelMute
  ChannelOwnCapability
  ChannelResponse
  CreateDeviceRequest
  CreateDraftRequest
  CreateDraftResponse
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
  Field
  FileUploadConfig
  FileUploadResponse
  FullUserResponse
  GetApplicationResponse
  GetBlockedUsersResponse
  GetDraftResponse
  GetOGResponse
  GetPinnedMessagesResponse
  GetReactionsResponse
  GetThreadResponse
  GetUserGroupResponse
  HideChannelRequest
  ImageData
  Images
  ImageSize
  ImageUploadResponse
  ListDevicesResponse
  ListUserGroupsResponse
  MarkDeliveredRequest
  MemberUserRequest
  MembersResponse
  MessageRequest
  MessageResponse
  ModerationV2Response
  MuteChannelRequest
  MuteChannelResponse
  MuteRequest
  MuteResponse
  OwnUserResponse
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
  SearchResultMessage
  SearchRolesResponse
  SendMessageRequest
  SendMessageResponse
  SendReactionRequest
  SendReactionResponse
  SharedLocation
  SharedLocationResponseData
  SharedLocationsResponse
  SortParamRequest
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
  UserResponse
  VoteData
  WrappedUnreadCountsResponse
)

# Models that keep the generated Hashable conformance; every other model has its
# Hashable extension stripped in step 4d. Uses the post-rename names (step 4b),
# unlike allowed_models above which uses the generator's original names.
allowed_hashable_models=(
  AppSettings
  Device
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
  BlockUsersRequest
  CastPollVoteRequestBody
  ChannelDeliveredRequestPayload
  ChannelMemberRequest
  CreateDeviceRequest
  CreateDraftRequest
  CreatePollOptionRequestBody
  CreatePollRequestBody
  CreateReminderRequest
  CreateUserGroupRequest
  DeliveredMessagePayload
  HideChannelRequest
  MessageRequest
  MuteChannelRequest
  MuteRequest
  NewLocationRequestPayload
  PollOptionRequestBody
  PushPreferenceInput
  QueryDraftsRequest
  QueryMembersPayload
  QueryPollVotesRequestBody
  QueryReactionsRequest
  QueryRemindersRequest
  QueryThreadsRequest
  QueryUsersPayload
  ReactionRequest
  RemoveUserGroupMembersRequest
  SendMessageRequest
  SendReactionRequest
  SortParamRequest
  TranslateMessageRequest
  TruncateChannelRequest
  UnblockUsersRequest
  UnmuteChannelRequest
  UnmuteRequest
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
  VoteDataRequestBody
)

decodable_only_models=(
  AppSettings
  BlockUsersResponse
  BlockedUserResponse
  ChannelDetailPayload
  CreateDraftResponse
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
  GetOGResponse
  GetPinnedMessagesResponse
  GetThreadResponse
  ImageSize
  ImageUploadResponse
  ListDevicesResponse
  ListUserGroupsResponse
  MemberInfoPayload
  MemberPayload
  MembersResponse
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
  PollOptionPayload
  PollOptionResponse
  PollPayload
  PollPayloadResponse
  PollVoteListResponse
  PollVotePayload
  PollVotePayloadResponse
  PushPreference
  QueryDraftsResponse
  QueryRemindersResponse
  QueryThreadsResponse
  QueryUsersResponse
  ReadStateResponse
  ReminderPayload
  SearchResultMessage
  SearchRolesResponse
  SendMessageResponsePayload
  SendReactionResponse
  SharedLocation
  SharedLocationsResponse
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
)

codable_models=(
  AttachmentActionPayload
  AttachmentFieldPayload
  ChannelCapability
  DeliveryReceiptsPrivacySettings
  Device
  GiphyImageData
  GiphyImages
  MemberUserRequest
  MessageAttachmentPayload
  ReadReceiptsPrivacySettings
  Role
  TypingIndicatorPrivacySettings
  UserPayload
  UserPrivacySettings
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

# Remove a generated property (declaration, doc comment, init param, assignment,
#     CodingKeys case). Runs before publicize, so there are no access modifiers to
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
rename_generated_type HideChannelResponse EmptyResponse
rename_generated_type MarkDeliveredResponse EmptyResponse
rename_generated_type Response EmptyResponse
rename_generated_type ShowChannelResponse EmptyResponse

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

# Unused channel context (cid, createdBy, id, type)
remove_property SendMessageRequest includeChannelContext
remove_property SendMessageResponsePayload channelContext

# TODO: reaction group reactors need CoreData and public API design first
remove_property MessageReactionGroupPayload latestReactionsBy

retype_property ChannelDetailPayload cid String ChannelId
retype_property ChannelDetailPayload config ChannelConfigWithInfo ChannelConfig
# Will be changed on the generation side later
require_property ChannelDetailPayload config

# TODO: Legacy v1 payloads may contain null; keep optional until legacy compatibility is removed.
optionalize_property MessageResponse reactionCounts
optionalize_property SearchResultMessage reactionCounts

# v1 payloads may omit the count when it is zero.
optionalize_property ThreadResponse activeParticipantCount
optionalize_property ThreadStateResponse activeParticipantCount

# v1 read events may omit it.
optionalize_property ThreadResponse createdByUserId

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
  decodable_csv="$(IFS=,; echo "${decodable_only_models[*]}")"
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
    case custom(String)
    case connect
    case sync
    case guest
    case search

    case markThreadRead(cid: ChannelId)
    case markThreadUnread(cid: ChannelId)

    case channels
    case groupedChannels
    case createChannel(String)
    case updateChannel(String)
    case channelUpdate(String)
    case markChannelRead(String)
    case markChannelUnread(String)
    case markAllChannelsRead
    case channelEvent(String)

    case message(MessageId)
    case replies(MessageId)
    case messageAction(MessageId)

    case banMember
    case flagUser
    case flagMessage

EOF

  cat > "$values_file" <<'EOF'
        case let .custom(path): return path
        case .connect: return "connect"
        case .sync: return "sync"
        case .guest: return "guest"
        case .search: return "search"

        case let .markThreadRead(cid):
            return "channels/\(cid.apiPath)/read"
        case let .markThreadUnread(cid):
            return "channels/\(cid.apiPath)/unread"

        case .channels: return "channels"
        case .groupedChannels: return "channels/grouped"
        case let .createChannel(queryString): return "channels/\(queryString)/query"
        case let .updateChannel(queryString): return "channels/\(queryString)/query"
        case let .channelUpdate(payloadPath): return "channels/\(payloadPath)"
        case let .markChannelRead(channelId): return "channels/\(channelId)/read"
        case let .markChannelUnread(channelId): return "channels/\(channelId)/unread"
        case .markAllChannelsRead: return "channels/read"
        case let .channelEvent(channelId): return "channels/\(channelId)/event"

        case let .message(messageId): return "messages/\(messageId)"
        case let .replies(messageId): return "messages/\(messageId)/replies"
        case let .messageAction(messageId): return "messages/\(messageId)/action"

        case .banMember: return "moderation/ban"
        case .flagUser: return "moderation/flag"
        case .flagMessage: return "moderation/flag"

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
