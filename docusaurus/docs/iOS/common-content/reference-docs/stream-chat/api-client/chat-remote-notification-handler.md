---
title: ChatRemoteNotificationHandler
---

``` swift
public class ChatRemoteNotificationHandler 
```

## Initializers

### `init(client:content:)`

``` swift
public init(client: ChatClient, content: UNNotificationContent) 
```

## Methods

### `handleNotification(completion:)`

``` swift
public func handleNotification(completion: @escaping (ChatPushNotificationContent) -> Void) -> Bool 
```
