#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
OUTPUT_DIR_CHAT="$REPO_ROOT/Sources/StreamChat/Generated/OpenAPI"
CHAT_DIR="$REPO_ROOT/../chat"

source "$SCRIPT_DIR/openapi_generate_helpers.sh"

# Keep ONLY the endpoints/models the SDK uses; everything else the generator emits is
# pruned below.
# allowed_models must hold the FULL transitive model closure of every endpoint in
# allowed_endpoints or the kept code won't compile — the build is the safety net.
allowed_endpoints=(
    addUserGroupMembers
    ban
    blockUsers
    castPollVote
    connect
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
    deleteFile
    deleteImage
    deleteMessage
    deletePoll
    deletePollVote
    deleteReaction
    deleteReminder
    deleteUserGroup
    flag
    getApp
    getBlockedUsers
    getDraft
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
  ConnectedEvent
  ConnectionErrorEvent
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
# Hashable extension stripped in step 7. Uses the post-rename names (step 4),
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

# Coding conformances for retained models after the renames in step 4. Every
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
  MutedChannelPayload
  MutedChannelPayloadResponse
  MutedUserPayload
  MuteResponse
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
  Device
  GiphyImageData
  GiphyImages
  MemberInfoPayload
  MessageAttachmentPayload
  Role
  SortParamRequest
  UserPayload
)

# 1. Clean + generate.
rm -rf "$OUTPUT_DIR_CHAT"
( cd "$CHAT_DIR" ; make openapi ; make -C tools/openapi build ; \
  ./build/openapi generate-client --language swift \
    --opt immutable_models=true --opt access_modifier=internal \
    --opt encodable_filter_conditions=true \
    --opt raw_representable_over_enum=true \
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
optionalize_property DeviceResponse createdAt
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
rename_generated DeviceResponse Device
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
# CHA-5170
rename_generated_type ChannelStateResponseFields ChannelStateResponse
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

# StreamCore provides the privacy settings models; only point the references at its names.
rename_generated_type DeliveryReceiptsResponse DeliveryReceiptsPrivacySettings
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
retype_property PushPreference chatLevel String PushPreferenceLevel
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

# Will be changed on the generation side later
# CHA-4621
require_property ChannelDetailPayload config
# CHA-5028
require_property ChannelStateResponse channel
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

# Unread by the SDK
remove_property AIIndicatorClearEventDTO channelId channelType custom receivedAt
remove_property AIIndicatorStopEventDTO channelId channelType custom receivedAt
remove_property AIIndicatorUpdateEventDTO channelId channelType custom receivedAt
remove_property BanRequest deleteMessages ipBan
remove_property BlockedUserResponse blockedUser user userId
remove_property ChannelDeletedEventDTO channelCustom channelId channelMemberCount channelMessageCount channelType cid custom receivedAt team
remove_property ChannelDetailPayload hideMessagesBefore muteExpiresAt muted
remove_property ChannelGetOrCreateRequest hideForCreator memberCustomInclude threadUnreadCounts
remove_property ChannelHiddenEventDTO channelCustom channelId channelMemberCount channelMessageCount channelType custom receivedAt team
remove_property ChannelInput autoTranslationEnabled autoTranslationLanguage configOverrides createdBy createdById disabled frozen truncatedById
remove_property ChannelInputRequest autoTranslationEnabled autoTranslationLanguage configOverrides createdBy disabled frozen
remove_property ChannelMemberRequest channelRole user
remove_property ChannelStateResponse hideMessagesBefore
remove_property ChannelTruncatedEventDTO channelCustom channelId channelMemberCount channelType cid custom messageId receivedAt team
remove_property ChannelUpdatedEventDTO channelCustom channelId channelMemberCount channelType cid custom messageId receivedAt team
remove_property ChannelVisibleEventDTO channelCustom channelId channelMemberCount channelMessageCount channelType custom receivedAt team
remove_property CreatePollRequestBody id isClosed team
remove_property CreateReminderRequest expiresAt
remove_property DraftDeletedEventDTO custom parentId receivedAt
remove_property DraftMessagePayload html mml
remove_property DraftUpdatedEventDTO custom parentId receivedAt
remove_property FlagRequest entityCreatorId moderationPayload
remove_property FullUserResponse banExpires deletedAt latestHiddenChannels revokeTokensIssuedBefore shadowBanned unreadCount
remove_property GetOGResponse actions authorIcon authorLink color custom fallback fields footer footerIcon giphy originalHeight originalWidth pretext type
remove_property HealthCheckEventDTO cid custom receivedAt
remove_property ImageUploadResponse uploadSizes
remove_property MarkChannelsReadRequest readByChannel
remove_property MarkReadRequest messageId
remove_property MemberAddedEventDTO channelCustom channelId channelMemberCount channelMessageCount channelType custom receivedAt team
remove_property MemberPayload banFromFutureChannels deletedMessages futureChannelBanExpires isModerator role
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
remove_property MessageResponse deletedReplyCount html imageLabels mml
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
remove_property OwnUserResponse deletedAt latestHiddenChannels revokeTokensIssuedBefore unreadCount
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
remove_property QueryMembersPayload createdAtAfter createdAtAfterOrEqual createdAtBefore createdAtBeforeOrEqual members userIdGt userIdGte userIdLt userIdLte
remove_property QueryUsersPayload idGt idGte idLt idLte includeDeactivatedUsers
remove_property ReactionDeletedEventDTO channelCustom channelId channelMemberCount channelType custom messageId receivedAt team threadParticipants
remove_property ReactionNewEventDTO channelCustom channelId channelMemberCount channelType custom messageId receivedAt team threadParticipants
remove_property ReactionRequest createdAt updatedAt
remove_property ReactionUpdatedEventDTO channelCustom channelId channelMemberCount channelType custom messageId receivedAt team
remove_property ReminderCreatedEventDTO cid custom parentId receivedAt userId
remove_property ReminderDeletedEventDTO cid custom parentId receivedAt userId
remove_property ReminderNotificationEventDTO cid custom parentId receivedAt userId
remove_property ReminderPayload expiresAt user
remove_property ReminderUpdatedEventDTO cid custom parentId receivedAt userId
remove_property SearchPayload forceDefaultSearch forceSqlV2Backend messageOptions query
remove_property SearchResponse previous resultsWarning
remove_property SearchResultMessage deletedReplyCount html imageLabels mml
remove_property SendMessageRequest includeChannelContext includeMentionedMembers keepChannelHidden
remove_property SendMessageResponsePayload channelContext mentionedMembers
remove_property SharedLocation channel message
remove_property SyncResponse inaccessibleCids
remove_property ThreadParticipantPayload channelCid custom lastThreadMessageAt leftThreadAt threadId userId
remove_property ThreadResponse channelCid createdByUserId deletedAt threadParticipants
remove_property ThreadStateResponse channelCid createdByUserId deletedAt
remove_property ThreadUpdatedEventDTO channelId channelType cid custom receivedAt
remove_property TruncateChannelRequest memberIds truncatedAt
remove_property TypingStartEventDTO channelId channelType custom receivedAt
remove_property TypingStopEventDTO channelId channelType custom receivedAt
remove_property UnmuteChannelRequest expiration
remove_property UpdateChannelRequest cooldown removeFilterTags skipPush
remove_property UpdateMessagePartialRequest skipEnrichUrl skipPush
remove_property UpdateReminderRequest expiresAt
remove_property UpdateUsersResponse membershipDeletionTaskId
remove_property UploadChannelFileResponse moderationAction
remove_property UploadChannelResponse moderationAction uploadSizes
remove_property UserBannedEventDTO channelCustom channelId channelMemberCount channelMessageCount channelType custom receivedAt reviewQueueItemId team totalBans
remove_property UserGroupMember appPk
remove_property UserMessagesDeletedEventDTO channelCustom channelId channelMemberCount channelMessageCount channelType cid custom receivedAt team
remove_property UserPayload blockedUserIds deletedAt revokeTokensIssuedBefore
remove_property UserPresenceChangedEventDTO custom receivedAt
remove_property UserRequest invisible language privacySettings
remove_property UserUnbannedEventDTO channelCustom channelId channelMemberCount channelMessageCount channelType createdBy custom receivedAt shadow team
remove_property UserUpdatedEventDTO custom receivedAt
remove_property UserWatchingStartEventDTO channelId channelType custom receivedAt
remove_property UserWatchingStopEventDTO channelId channelType custom receivedAt

remove_type BanRequest BanRequestDeleteMessages
remove_type PushPreferenceInput PushPreferenceInputCallLevel
remove_type PushPreferenceInput PushPreferenceInputFeedsLevel

# 6. Expose selected generated models as public API.
publicize_model AppSettings
publicize_model CurrentUserUnreads
publicize_model Device
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
publicize_raw_representable TranslateMessageRequest TranslationLanguage

# 7. Coding conformances and cleanup.
apply_directional_coding_conformances
strip_hashable_conformance
strip_streamcore_imports

# 8. Format, splice the generated decoders and wrap long declarations.
swiftformat --config "$REPO_ROOT/.swiftformat" "$OUTPUT_DIR_CHAT"

sourcery --config "$REPO_ROOT/Sources/StreamChat/.openapi.sourcery.yml"
splice_generated_decoders

swiftformat "$OUTPUT_DIR_CHAT" \
  --rules wrapArguments \
  --wrapparameters before-first \
  --wraparguments preserve \
  --maxwidth 100

# 9. Report the endpoints the generator emitted but allowed_endpoints prunes.
echo "Unused endpoints (${#pruned_endpoints[@]}):"
printf '  %s\n' ${pruned_endpoints[@]+"${pruned_endpoints[@]}"} | sort
