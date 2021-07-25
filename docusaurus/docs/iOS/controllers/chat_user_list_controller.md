---
title: ChatUserListController
---

`ChatUserListController` allows you to observe a list of users based on the provided query.

## ChatUserListControllerDelegate

Classes that conform to this protocol will receive changes to the queries list of users.

```swift
func controller(
    _ controller: ChatUserListController,
    didChangeUsers changes: [ListChange<ChatUser>]
)
```
