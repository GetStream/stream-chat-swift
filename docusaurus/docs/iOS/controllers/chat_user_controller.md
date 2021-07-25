---
title: ChatUserController
---

`ChatUserController` allows you to observe and mutate the current user.

## ChatUserControllerDelegate

Classes that conform to this protocol will receive changes to chat users. 

```swift
func userController(
    _ controller: ChatUserController,
    didUpdateUser change: EntityChange<ChatUser>
)
```
