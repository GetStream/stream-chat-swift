#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
OUTPUT_DIR_CHAT="$REPO_ROOT/Sources/StreamChat/Generated/OpenAPI"
SOURCERY_CONFIG="$REPO_ROOT/Sources/StreamChat/.openapi.sourcery.yml"
CHAT_DIR="$REPO_ROOT/../chat"
ALLOWED_FILE="$SCRIPT_DIR/openapi-allowed.json"

source "$SCRIPT_DIR/openapi_generate_helpers.sh"

command -v jq > /dev/null || { echo "jq not found (brew install jq)" >&2; exit 1; }
jq -e . "$ALLOWED_FILE" > /dev/null || { echo "Invalid $ALLOWED_FILE" >&2; exit 1; }

allowed_endpoints=($(jq -r '.allowedEndpoints[]' "$ALLOWED_FILE"))
allowed_events=($(jq -r '.allowedEvents[]' "$ALLOWED_FILE"))
allowed_hashable_models=($(jq -r '.allowedHashableModels[]' "$ALLOWED_FILE"))
allowed_models=($(jq -r '.allowedModels[]' "$ALLOWED_FILE"))
codable_models=($(jq -r '.codableModels[]' "$ALLOWED_FILE"))
decodable_only_models=($(jq -r '.decodableOnlyModels[]' "$ALLOWED_FILE"))
encodable_only_models=($(jq -r '.encodableOnlyModels[]' "$ALLOWED_FILE"))

# 1. Clean + generate.
rm -rf "$OUTPUT_DIR_CHAT"
( cd "$CHAT_DIR" ; make openapi ; make -C tools/openapi build ; \
  ./build/openapi generate-client --language swift \
    --opt immutable_models=true --opt access_modifier=internal \
    --opt encodable_filter_conditions=true \
    --opt nested_embedded_models=true \
    --opt raw_representable_over_enum=true \
    --opt string_coding_keys=true \
    --spec ./releases/v2/chat-clientside-api.yaml --output "$OUTPUT_DIR_CHAT" )

# Drop the generated async API client — the SDK ships its own APIClient.
# DefaultEndpoints.swift stays under APIs/ as the generator emits it.
rm -f "$OUTPUT_DIR_CHAT/APIs/DefaultAPI.swift"

# 2. Prune endpoints, endpoint paths, models and WSEvent cases.
prune_endpoint_factories
prune_generated_endpoint_paths
prune_models
prune_wsevent_cases

# 3. Property fixes on the generator's original names.
for model in "${allowed_models[@]}"; do
  remove_property "$model" duration
done

# Remove in the next major.
optionalize_property Role createdAt
optionalize_property Role updatedAt
optionalize_property UnreadCountsChannel lastRead
optionalize_property UnreadCountsThread lastRead
optionalize_property UnreadCountsThread lastReadMessageId

retype_property ReactionRequest type String MessageReactionType
retype_property ReactionResponse type String MessageReactionType
retype_property SharedLocationResponseData channelCid String ChannelId
retype_property SharedLocationResponseData createdByDeviceId String DeviceId
retype_property SharedLocationResponseData latitude Float Double
retype_property SharedLocationResponseData longitude Float Double
retype_property SharedLocationResponseData messageId String MessageId
retype_property SharedLocationResponseData userId String UserId
retype_property UnreadCountsChannel channelId String ChannelId
retype_property UnreadCountsChannelType channelType String ChannelType

# 4. Rename selected generated models for clarity and to avoid generic-name
#    pollution / collisions with hand-written SDK types. Runs AFTER prune_models
#    so allowed_models above still matches the generator's original names.
rename_generated_events
shape_wsevent

# Order-sensitive: their old names are rename targets below.
rename_generated SharedLocation NewLocationRequestPayload
rename_generated UserGroupResponse UserGroup

rename_generated Action AttachmentActionPayload
rename_generated AppResponseFields AppSettings
rename_generated Attachment MessageAttachmentPayload
rename_generated CastPollVoteRequest CastPollVoteRequestBody
rename_generated ChannelMemberPartialResponse MemberInfoPayload
rename_generated ChannelMemberResponse MemberPayload
rename_generated ChannelMute MutedChannelPayload
rename_generated ChannelOwnCapability ChannelCapability
rename_generated ChannelResponse ChannelDetailPayload
rename_generated CreatePollOptionRequest CreatePollOptionRequestBody
rename_generated CreatePollRequest CreatePollRequestBody
rename_generated DraftPayloadResponse DraftMessagePayload
rename_generated DraftResponse DraftPayload
rename_generated Field AttachmentFieldPayload
rename_generated FileUploadConfig UploadConfig
rename_generated GetReactionsResponse MessageReactionsPayload
rename_generated GetUserGroupResponse UserGroupResponse
rename_generated ImageData GiphyImageData
rename_generated Images GiphyImages
rename_generated MarkDeliveredRequest ChannelDeliveredRequestPayload
rename_generated ModerationV2Response MessageModerationDetailsPayload
rename_generated MuteChannelResponse MutedChannelPayloadResponse
rename_generated PollOptionInput PollOptionRequestBody
rename_generated PollOptionResponseData PollOptionPayload
rename_generated PollResponse PollPayloadResponse
rename_generated PollResponseData PollPayload
rename_generated PollVoteResponse PollVotePayloadResponse
rename_generated PollVoteResponseData PollVotePayload
rename_generated PollVotesResponse PollVoteListResponse
rename_generated PushPreferencesResponse PushPreference
rename_generated QueryPollVotesRequest QueryPollVotesRequestBody
rename_generated ReactionGroupResponse MessageReactionGroupPayload
rename_generated ReactionResponse MessageReactionPayload
rename_generated ReminderResponseData ReminderPayload
# The SDK's ScheduledMessageStatus merges the local and server states.
rename_generated ScheduledMessageStatus ScheduledMessageServerStatus
rename_generated SendMessageResponse SendMessageResponsePayload
rename_generated SharedLocationResponseData SharedLocation
rename_generated ThreadParticipant ThreadParticipantPayload
rename_generated UnmuteResponse UnmuteUsersResponse
rename_generated UnreadCountsChannel UnreadChannel
rename_generated UnreadCountsChannelType UnreadChannelByType
rename_generated UnreadCountsThread UnreadThread
rename_generated UpdatePollPartialRequest UpdatePollPartialRequestBody
rename_generated UserMuteResponse MutedUserPayload
rename_generated UserResponse UserPayload
rename_generated VoteData VoteDataRequestBody
rename_generated WrappedUnreadCountsResponse CurrentUserUnreads

rename_generated_type AddUserGroupMembersResponse UserGroupResponse
rename_generated_type ChannelPushPreferencesResponse PushPreference
rename_generated_type ChannelStateResponse ChannelStateResponseFields
rename_generated_type CreateUserGroupResponse UserGroupResponse
rename_generated_type QueryReactionsResponse MessageReactionsPayload
rename_generated_type RemoveUserGroupMembersResponse UserGroupResponse
rename_generated_type SearchUserGroupsResponse ListUserGroupsResponse
rename_generated_type SharedLocationResponse SharedLocation
rename_generated_type UpdateUserGroupResponse UserGroupResponse
# These are equal
rename_generated_type UserResponseCommonFields UserPayload
# Has isInvisible and privacySettings, but SDK never consumes these
rename_generated_type UserResponsePrivacyFields UserPayload

rename_generated_type CreatePollRequestVotingVisibility VotingVisibility
rename_generated_type PushPreferenceInputChatLevel PushPreferenceLevel
rename_generated_type TranslateMessageRequestLanguage TranslationLanguage

# Hand-written public models; only point the references at their names.
rename_generated_type PushScheduleResponse PushSchedule

# StreamCore provides the device and privacy settings models; only point the references at its names.
rename_generated_type DeliveryReceiptsResponse DeliveryReceiptsPrivacySettings
rename_generated_type DeviceResponse Device
rename_generated_type PrivacySettingsResponse UserPrivacySettings
rename_generated_type ReadReceiptsResponse ReadReceiptsPrivacySettings
rename_generated_type TypingIndicatorsResponse TypingIndicatorPrivacySettings

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

# 5. Property fixes on the renamed models.
retype_property ChannelDetailPayload cid String ChannelId
retype_property ChannelDetailPayload config ChannelConfigWithInfo ChannelConfig
retype_property ChannelPartialUpdateResponse cid String ChannelId
retype_property PushPreference chatLevel String PushPreferenceLevel
retype_property QuietHoursRuleInput days "[String]" "[QuietHoursDay]"
for f in "$OUTPUT_DIR_CHAT"/models/*EventDTO.swift; do
  [ -e "$f" ] || continue
  base="$(basename "$f" .swift)"
  [[ "$base" == "HealthCheckEventDTO" ]] && continue
  retype_property "$base" cid String ChannelId
done
# CHA-5587
retype_property MessageDeliveredEventDTO lastDeliveredAt String Date

rename_property PushPreference chatLevel level

restore_nonoptional_property PushPreference level PushPreferenceLevel .all
restore_nonoptional_property UserGroup members "[UserGroupMember]" "[]"

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

optionalize_property ThreadResponse createdByUserId
optionalize_property UserPayload blockedUserIds

# Will be changed on the generation side later
# CHA-4621
require_property ChannelDetailPayload config
# CHA-5028
require_property ChannelStateResponseFields channel
# CHA-5105
require_property SearchResult message
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

remove_properties

remove_type BanRequest BanRequestDeleteMessages
remove_type PushPreferenceInput PushPreferenceInputCallLevel
remove_type PushPreferenceInput PushPreferenceInputFeedsLevel

# 6. Expose selected generated models as public API.
publicize_model AppSettings
publicize_model CurrentUserUnreads
publicize_model PushPreference
publicize_model Role
publicize_model SharedLocation
publicize_model UnmuteUsersResponse
publicize_model UnreadChannel
publicize_model UnreadChannelByType
publicize_model UnreadThread
publicize_model UploadConfig
publicize_model UserGroup
publicize_model UserGroupMember

publicize_raw_representable ChannelCapability
publicize_raw_representable CreatePollRequestBody VotingVisibility
publicize_raw_representable PushPreferenceInput PushPreferenceLevel
publicize_raw_representable ScheduledMessageFailureReason
publicize_raw_representable TranslateMessageRequest TranslationLanguage

# 7. Coding conformances and cleanup.
apply_directional_coding_conformances
strip_hashable_conformance
strip_streamcore_imports

# 8. Format, splice the generated decoders, prune unused StringCodingKey lets and wrap
#    long declarations.
swiftformat --config "$REPO_ROOT/.swiftformat" "$OUTPUT_DIR_CHAT"

sourcery --config "$SOURCERY_CONFIG"
splice_generated_decoders
prune_string_coding_keys

swiftformat "$OUTPUT_DIR_CHAT" \
  --rules wrapArguments \
  --wrapparameters before-first \
  --wraparguments preserve \
  --maxwidth 100

# 9. Report the endpoints the generator emitted but allowed_endpoints prunes.
echo "Unused endpoints (${#pruned_endpoints[@]}):"
printf '  %s\n' ${pruned_endpoints[@]+"${pruned_endpoints[@]}"} | sort
