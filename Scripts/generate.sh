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

# The generated async API client is unused — the SDK ships its own APIClient + Endpoint factories.
rm -rf "$OUTPUT_DIR_CHAT/APIs"

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

make_channel_member_response_partial_fields_optional() {
  # INTERIM: ChannelMemberResponse is reused as the partial `member` on messages (MessageResponse.member,
  # ChatMessageResponse.member, SearchResultMessage.member). There the server sends only `channel_role` +
  # `notifications_muted`, but the spec marks banned/created_at/updated_at/custom/shadow_banned as required,
  # so synthesized Codable throws keyNotFound("banned") and the whole channels response fails to decode.
  # Make those 5 optional so the partial decodes; full members (channel.members, member events) still
  # populate them. Proper fix belongs upstream (separate partial schema, or drop these from the schema's
  # required list). Must run AFTER strip_public_open_access_modifiers so the property line has no `public `.
  local file="$OUTPUT_DIR_CHAT/models/ChannelMemberResponse.swift"
  # Property declarations (anchored to end-of-line; `shadowBanned`/`banExpires` are not matched by `banned`).
  sed -i '' -E 's/^([[:space:]]*)var banned: Bool$/\1var banned: Bool?/' "$file"
  sed -i '' -E 's/^([[:space:]]*)var createdAt: Date$/\1var createdAt: Date?/' "$file"
  sed -i '' -E 's/^([[:space:]]*)var custom: \[String: RawJSON\]$/\1var custom: [String: RawJSON]?/' "$file"
  sed -i '' -E 's/^([[:space:]]*)var shadowBanned: Bool$/\1var shadowBanned: Bool?/' "$file"
  sed -i '' -E 's/^([[:space:]]*)var updatedAt: Date$/\1var updatedAt: Date?/' "$file"
  # Initializer params (followed by `,` or `)`): add `? = nil` default.
  sed -i '' -E 's/banned: Bool([,)])/banned: Bool? = nil\1/' "$file"
  sed -i '' -E 's/createdAt: Date([,)])/createdAt: Date? = nil\1/' "$file"
  sed -i '' -E 's/custom: \[String: RawJSON\]([,)])/custom: [String: RawJSON]? = nil\1/' "$file"
  sed -i '' -E 's/shadowBanned: Bool([,)])/shadowBanned: Bool? = nil\1/' "$file"
  sed -i '' -E 's/updatedAt: Date([,)])/updatedAt: Date? = nil\1/' "$file"
}

make_message_delivered_last_delivered_at_date() {
  # INTERIM: The upstream OpenAPI source currently describes message.delivered
  # last_delivered_at as a plain string, while the wire value is an RFC3339
  # timestamp and ReadStateResponse.last_delivered_at is already generated as Date?.
  # Keep this local workaround until ../chat fixes the schema/runtime source.
  local file="$OUTPUT_DIR_CHAT/models/MessageDeliveredEventDTO.swift"
  sed -i '' -E 's/^([[:space:]]*)var lastDeliveredAt: String\?$/\1var lastDeliveredAt: Date?/' "$file"
  sed -i '' -E 's/lastDeliveredAt: String\? = nil/lastDeliveredAt: Date? = nil/' "$file"
}

make_member_event_channel_optional() {
  # INTERIM: The backend sends member.added/member.updated/member.removed without
  # the full `channel` object (only cid/channel_id/channel_type/channel_last_message_at),
  # but the spec marks `channel` required, so synthesized Codable throws
  # keyNotFound("channel") and the whole WSEvent fails to decode. Member events
  # only — Notification*/Reaction*/Channel* events do receive the channel and
  # middlewares rely on it. Proper fix belongs upstream (drop `channel` from the
  # member event schemas' required lists).
  # Must run AFTER strip_public_open_access_modifiers so the lines have no `public `.
  local file
  for file in \
    "$OUTPUT_DIR_CHAT/models/MemberAddedEventDTO.swift" \
    "$OUTPUT_DIR_CHAT/models/MemberRemovedEventDTO.swift" \
    "$OUTPUT_DIR_CHAT/models/MemberUpdatedEventDTO.swift"; do
    # Property declaration (anchored to end-of-line; `channelCustom:` etc. are not matched).
    sed -i '' -E 's/^([[:space:]]*)var channel: ChannelResponse$/\1var channel: ChannelResponse?/' "$file"
    # Initializer param (followed by `,` or `)`): add `? = nil` default.
    sed -i '' -E 's/channel: ChannelResponse([,)])/channel: ChannelResponse? = nil\1/' "$file"
  done
}

make_user_response_team_fields_optional() {
  # INTERIM: The backend's custom JSON encoder drops nil slices/maps regardless of
  # `omitempty`, so user objects can arrive without `teams`/`blocked_user_ids` even
  # though the spec marks them required (member events' top-level `user` and
  # `member.user` do in practice; message.new users include them). Make both
  # optional on every UserResponseFields conformer: the protocol's `teams`
  # requirement becomes `[String]?` and a non-optional stored property cannot
  # witness an optional requirement, so all five models must change together.
  # (OwnUserResponse.blockedUserIds is already optional — that sed is a no-op there.)
  # Must run AFTER strip_public_open_access_modifiers so the lines have no `public `.
  local file
  for file in \
    "$OUTPUT_DIR_CHAT/models/FullUserResponse.swift" \
    "$OUTPUT_DIR_CHAT/models/OwnUserResponse.swift" \
    "$OUTPUT_DIR_CHAT/models/UserResponse.swift" \
    "$OUTPUT_DIR_CHAT/models/UserResponseCommonFields.swift" \
    "$OUTPUT_DIR_CHAT/models/UserResponsePrivacyFields.swift"; do
    # Property declarations (anchored to end-of-line; `teamsRole: [String: String]?`
    # and `latestHiddenChannels: [String]?` are not matched).
    sed -i '' -E 's/^([[:space:]]*)var blockedUserIds: \[String\]$/\1var blockedUserIds: [String]?/' "$file"
    sed -i '' -E 's/^([[:space:]]*)var teams: \[String\]$/\1var teams: [String]?/' "$file"
    # Initializer params (followed by `,` or `)`): add `? = nil` default.
    sed -i '' -E 's/blockedUserIds: \[String\]([,)])/blockedUserIds: [String]? = nil\1/' "$file"
    sed -i '' -E 's/teams: \[String\]([,)])/teams: [String]? = nil\1/' "$file"
  done
}

make_sync_replayed_event_fields_optional() {
  # INTERIM: /chat/sync replays events stored as the backend's generic event type
  # where enrichment fields carry `omitempty`, while the spec is generated from the
  # typed live-WS event structs that mark them required. Replayed events therefore
  # arrive without `message_id`/`watcher_count`/`hard_delete`/`clear_history`/
  # reaction `channel`, and one such event throws keyNotFound and fails the whole
  # SyncResponse decode. Make those fields optional on every event type /sync can
  # replay (message.*, reaction.*, channel.hidden); channel.*/notification.*
  # replays do carry `channel`/`member`, so those stay required. Proper fix
  # belongs upstream (drop the enrichment-only fields from the event schemas'
  # required lists, or re-enrich replayed events).
  # Must run AFTER strip_public_open_access_modifiers so the lines have no `public `.
  local file

  for file in \
    "$OUTPUT_DIR_CHAT/models/MessageNewEventDTO.swift" \
    "$OUTPUT_DIR_CHAT/models/MessageUpdatedEventDTO.swift" \
    "$OUTPUT_DIR_CHAT/models/MessageDeletedEventDTO.swift" \
    "$OUTPUT_DIR_CHAT/models/MessageUndeletedEventDTO.swift" \
    "$OUTPUT_DIR_CHAT/models/ReactionUpdatedEventDTO.swift"; do
    # Property declaration (anchored to end-of-line; `parentMessageId` etc. are not matched).
    sed -i '' -E 's/^([[:space:]]*)var messageId: String$/\1var messageId: String?/' "$file"
    # Initializer param (followed by `,` or `)`): add `? = nil` default.
    sed -i '' -E 's/messageId: String([,)])/messageId: String? = nil\1/' "$file"
  done

  # Reaction events: replayed without the full `channel` object (reaction.new/
  # reaction.deleted already generate `messageId` as optional).
  for file in \
    "$OUTPUT_DIR_CHAT/models/ReactionNewEventDTO.swift" \
    "$OUTPUT_DIR_CHAT/models/ReactionUpdatedEventDTO.swift" \
    "$OUTPUT_DIR_CHAT/models/ReactionDeletedEventDTO.swift"; do
    sed -i '' -E 's/^([[:space:]]*)var channel: ChannelResponse$/\1var channel: ChannelResponse?/' "$file"
    sed -i '' -E 's/channel: ChannelResponse([,)])/channel: ChannelResponse? = nil\1/' "$file"
  done

  file="$OUTPUT_DIR_CHAT/models/MessageNewEventDTO.swift"
  sed -i '' -E 's/^([[:space:]]*)var watcherCount: Int$/\1var watcherCount: Int?/' "$file"
  sed -i '' -E 's/watcherCount: Int([,)])/watcherCount: Int? = nil\1/' "$file"

  file="$OUTPUT_DIR_CHAT/models/MessageDeletedEventDTO.swift"
  sed -i '' -E 's/^([[:space:]]*)var hardDelete: Bool$/\1var hardDelete: Bool?/' "$file"
  sed -i '' -E 's/hardDelete: Bool([,)])/hardDelete: Bool? = nil\1/' "$file"

  file="$OUTPUT_DIR_CHAT/models/ChannelHiddenEventDTO.swift"
  sed -i '' -E 's/^([[:space:]]*)var clearHistory: Bool$/\1var clearHistory: Bool?/' "$file"
  sed -i '' -E 's/clearHistory: Bool([,)])/clearHistory: Bool? = nil\1/' "$file"
}

make_channel_config_with_info_fields_optional() {
  # INTERIM: channel.hidden sync replays embed the channel with an empty config
  # (`"config": {}`) because the backend builds the stored event via the legacy
  # event constructor, so every spec-required config field throws keyNotFound and
  # the whole SyncResponse decode fails (channel.created/updated replays and all
  # live events carry the full config). Make every required field optional so the
  # hollow object decodes; the single consumer (`asChannelConfig`) falls back to
  # the domain ChannelConfig defaults. Proper fix belongs upstream (store/replay
  # the full channel for channel.hidden, or drop config from the schema's
  # required list).
  # Must run AFTER strip_public_open_access_modifiers so the lines have no `public `.
  local file="$OUTPUT_DIR_CHAT/models/ChannelConfigWithInfo.swift"
  local field
  for field in \
    automod automodBehavior commands connectEvents countMessages createdAt \
    customEvents deliveryEvents markMessagesPending maxMessageLength mutes name \
    polls pushNotifications quotes reactions readEvents reminders replies search \
    sharedLocations skipLastMsgUpdateForSystemMsgs typingEvents updatedAt uploads \
    urlEnrichment userMessageReminders; do
    # Property declaration: append `?` to the type (already-optional lines end
    # with `?` and are not matched).
    sed -i '' -E "s/^([[:space:]]*)var ${field}: ([^?]+)\$/\1var ${field}: \2?/" "$file"
    # Initializer param (followed by `,` or `)`): add `? = nil` default. None of
    # the matched fields' types contain `,` or `)`.
    sed -i '' -E "s/${field}: ([^,)]+)([,)])/${field}: \1? = nil\2/" "$file"
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

# Endpoint factories the SDK never calls. Deleting one removes the factory
# function, its `EndpointPath` case, and the case's `value` switch entry.
# If the SDK starts using one of these, remove it from the list and regenerate.
delete_unused_endpoint_factory() {
  local name="$1"
  local file="$OUTPUT_DIR_CHAT/DefaultEndpoints.swift"
  sed -i '' -E "/^[[:space:]]+static func ${name}\(/,/^[[:space:]]+\}[[:space:]]*$/d" "$file"
  sed -i '' -E "/^[[:space:]]+case ${name}(\(|[[:space:]]*$)/d" "$file"
  sed -i '' -E "/^[[:space:]]+case (let )?\.${name}[(:]/,/^[[:space:]]+return /d" "$file"
}

UNUSED_ENDPOINT_FACTORIES=(
  addUserGroupMembers appeal bulkActionAppeals bulkDeleteActionConfig
  bulkUpsertActionConfig createBlockList createUserGroup deleteActionConfig
  deleteBlockList deleteChannels deleteConfig deletePollOption deleteUserGroup
  getActionConfig getAppeal getConfig getManyMessages getPoll getPollOption
  getUserGroup listBlockLists listUserGroups longPoll queryAppeals
  queryBannedUsers queryFutureChannelBans queryMessageFlags
  queryModerationConfigs queryPolls queryReviewQueue removeUserGroupMembers
  searchRoles searchUserGroups submitAction updateBlockList updatePoll
  updatePollOption updateUserGroup updateUsers upsertActionConfig upsertConfig
)
for factory in "${UNUSED_ENDPOINT_FACTORIES[@]}"; do
  delete_unused_endpoint_factory "$factory"
done

# Models that are not referenced from non-generated Sources nor reachable from
# the kept endpoint factories, transitively over cross-model references.
# If the SDK starts using one of these (directly or via a newly kept factory),
# remove it — and anything it references — from the list and regenerate.
UNUSED_MODELS=(
  AIImageConfig AIImageLabelDefinition AITextConfig AIVideoConfig
  AWSRekognitionRule ActionSequence AddUserGroupMembersRequest
  AddUserGroupMembersResponse AppealRequest AppealResponse
  AutomodDetailsResponse AutomodPlatformCircumventionConfig AutomodRule
  AutomodSemanticFiltersConfig AutomodSemanticFiltersRule AutomodToxicityConfig
  BanActionRequestPayload BanOptions BlockActionRequestPayload BlockListConfig
  BlockListResponse BlockListRule BodyguardProfileSummary BodyguardRule
  BodyguardSeverityRule BulkActionAppealsRequest BulkActionAppealsResponse
  BulkAppealError BulkAppealResult BulkDeleteActionConfigRequest
  BulkDeleteActionConfigResponse BulkUpsertActionConfigRequest
  BulkUpsertActionConfigResponse BypassActionRequest CallActionOptions
  CallCustomPropertyParameters CallRuleActionSequence CallTypeRuleParameters
  CallViolationCountParameters ChannelMessageCountRuleParameters
  ClosedCaptionRuleParameters ConfigResponse ContentCountRuleParameters
  CreateBlockListRequest CreateBlockListResponse CreateUserGroupRequest
  CreateUserGroupResponse CustomActionRequestPayload DeleteActionConfigResponse
  DeleteActivityRequestPayload DeleteChannelsRequest DeleteChannelsResponse
  DeleteChannelsResultResponse DeleteCommentRequestPayload
  DeleteMessageRequestPayload DeleteModerationConfigResponse
  DeleteReactionRequestPayload DeleteUserRequestPayload EscalatePayload
  FilterConfigResponse FlagCountRuleParameters FlagDetailsResponse
  FlagFeedbackResponse FlagMessageDetailsResponse FlagUserOptions FloodConfig
  FloodIdenticalConfig FloodSimilarConfig FutureChannelBanResponse
  GetActionConfigResponse GetAppealResponse GetConfigResponse
  GetManyMessagesResponse GetUserGroupResponse GoogleVisionConfig HarmConfig
  ImageContentParameters ImageRuleParameters KeyframeRuleParameters LLMConfig
  LLMRule LabelResponse ListBlockListResponse ListUserGroupsResponse
  MarkReviewedRequestPayload MessageFlagResponse MessageModerationResult
  ModerationActionConfigResponse ModerationResponse OCRRule PollOptionRequest
  QueryAppealsRequest QueryAppealsResponse QueryBannedUsersPayload
  QueryBannedUsersResponse QueryFutureChannelBansPayload
  QueryFutureChannelBansResponse QueryMessageFlagsPayload
  QueryMessageFlagsResponse QueryModerationConfigsRequest
  QueryModerationConfigsResponse QueryPollsRequest QueryPollsResponse
  QueryReviewQueueRequest QueryReviewQueueResponse RejectAppealRequestPayload
  RemoveUserGroupMembersRequest RemoveUserGroupMembersResponse
  RestoreActionRequestPayload RuleBuilderAction RuleBuilderCondition
  RuleBuilderConditionGroup RuleBuilderConfig RuleBuilderRule
  SearchRolesResponse SearchUserGroupsResponse ShadowBlockActionRequestPayload
  SubmitActionRequest SubmitActionResponse TextContentParameters
  TextRuleParameters UnbanActionRequestPayload UnblockActionRequestPayload
  UpdateBlockListRequest UpdateBlockListResponse UpdatePollOptionRequest
  UpdatePollRequest UpdateUserGroupRequest UpdateUserGroupResponse
  UpdateUsersRequest UpsertActionConfigItem UpsertActionConfigRequest
  UpsertActionConfigResponse UpsertConfigRequest UpsertConfigResponse
  UserCreatedWithinParameters UserCustomPropertyParameters
  UserIdenticalContentCountParameters UserRoleParameters UserRuleParameters
  VelocityFilterConfig VelocityFilterConfigRule VideoCallRuleConfig
  VideoContentParameters VideoRuleParameters WSClientEvent
)
for model in "${UNUSED_MODELS[@]}"; do
  delete_generated_filename "$model"
done

escape_swift_keywords_in_cases
fix_invalid_empty_enum_cases
strip_public_open_access_modifiers
make_channel_member_response_partial_fields_optional
make_message_delivered_last_delivered_at_date
make_member_event_channel_optional
make_user_response_team_fields_optional
make_sync_replayed_event_fields_optional
make_channel_config_with_info_fields_optional

swiftformat --config "$REPO_ROOT/.swiftformat" "$OUTPUT_DIR_CHAT"
