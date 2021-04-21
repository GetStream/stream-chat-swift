---
title: Controllers Overview
---

This page contains a list of all available controllers within `StreamChat`, including their short description and typical use-cases.

---
#### `CurrentChatUserController`
Used for operations related to the current user, like setting the current user, observing its changes, etc.

*Typical usage:* Current user profile screen, a log-in screen, ...

&nbsp;

#### `ChatConnectionController`
Used for observing a connection status of the system and handling the connection manually if `config.shouldConnectAutomatically` is set to false.

*Typical usage:* connection status banner (connecting/connected), ...

&nbsp;

#### `ChatUserController`
Used for operations related to any user of a chat, like muting, getting user info, and observing its changes.

*Typical usage:* User profile screen, quick actions on a user ("Mute user"), ...

&nbsp;

#### `ChatUserListController`
Used to get a list of all users in the chat app. You can also specify `UserListQuery` to filter the users. Supports pagination.

*Typical usage:* Show list of all users in the app.

&nbsp;

#### `ChatChannelListController`
Used to get a list of all channels in the app matching the provided `ChannelListQuery`. Supports pagination.

*Typical usage:* Show a list of channels (the main page of most chat apps)

&nbsp;

#### `ChatChannelController`
Used for operations related to a channel, like getting all messages, sending new messages, but also adding/removing members or editing the channel details and deleting it.

*Typical usage:* Messages screen, channel quick actions ("Delete channel", etc.

&nbsp;

#### `ChatChannelMemberController`
Used for operations related to a member of a channel, like banning, getting member info, and observing its changes.

*Typical usage:* Member profile screen, quick actions on a member ("Ban user"), ...

&nbsp;

#### `ChatChannelMemberListController`
Used to get a list of all members of a channel. You can also specify `MemberListQuery` to filter the members. Supports pagination.

*Typical usage:* Show list of all members in the channel.

&nbsp;

#### `ChatMessageController`
Used for operations related to a message, like deleting the message, adding reacting, and observing its changes.

*Typical usage:* Message detail screen, quick actions on a message ("Add Reaction"), ...

&nbsp;

#### `ChatUserSearchController`
Used for performing a full-text search in available users by their name and id.

*Typical usage:* User mention suggestion, add to channel suggestion, search users screen, ...

&nbsp;
