---
id: notificationmessagenewevent 
title: NotificationMessageNewEvent
--- 

``` swift
public struct NotificationMessageNewEvent: MessageSpecificEvent 
```

## Inheritance

[`MessageSpecificEvent`](MessageSpecificEvent)

## Properties

### `userId`

``` swift
public let userId: UserId
```

### `cid`

``` swift
public let cid: ChannelId
```

### `messageId`

``` swift
public let messageId: MessageId
```

### `createdAt`

``` swift
public let createdAt: Date
```

### `unreadCount`

``` swift
public let unreadCount: UnreadCount?
```
