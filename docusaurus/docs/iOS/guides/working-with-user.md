---
title: Working with User
---

The User object is accessed through a `UserController`. 

There is a special type of user object which is `CurrentUser`, accessed through `CurrentUserController`, representing the currently signed-in user. 

`CurrentUser` have some extra parameters (such as registered devices, muted and flagged users or unread counts) specific only for signed-in user. 

```swift
/// User id of the user you want to work with
let userId = "yourUserId"

/// User controller for the intended user
let userController = chatClient.userController(userId: userId)

/// Current user controller
let currentUserController = chatClient.currentUserController()
```

## Standard User

`ChatUser` is a simple object, you can access the information and (un)mute and (un)flag the user.
```swift
let user = userController.user
print(user.name)
```

### Muting/unmuting user
```swift 
userController.mute()
userController.unmute()
```
Both functions have an optional completion block to be called when the network request is finished.
```swift 
userController.mute {
    if let error = error {
        print(error)
        return
    }
    // Successfully finished
}
```

### Flagging/Unflagging user
```swift 
userController.flag()
userController.unflag()
```
Both functions have an optional completion block to be called when the network request is finished.
```swift 
userController.flag {
    if let error = error {
        print(error)
        return
    }
    // Successfully finished
}
```

## Updating current user data

To change the user data, you can call update user data function on the current user controller.

```swift 
currentUserController.updateUserData(name: "Luke Skywalker")
```

#### Delegate
You can observe the changes in user data with delegate.
```swift 
class YourViewController: CurrentChatUserControllerDelegate {
    override func viewDidLoad() {
        super.viewDidLoad()

        currentUserController.delegate = self
        currentUserController.updateUserData(name: "Luke Skywalker")
    }

    func currentUserController(
        _ controller: _CurrentChatUserController<ExtraData>,
        didChangeCurrentUser: EntityChange<_CurrentChatUser<ExtraData>>
    ) {
        if case let .update(user) = didChangeCurrentUser {
            print(user.name) // Luke Skywalker
        }
    }
}
```

#### Publisher
You can use Combine publisher to observe the changes too.
```swift
currentUserController
    .currentUserChangePublisher
    .compactMap({ (change: EntityChange<CurrentChatUser>) -> CurrentChatUser? in
        if case let .update(user) = change { return user } else { return nil }
    })
    .sink { print($0.name) } // Luke Skywalker
    .store(in: &cancellables)
```

## Observing unread count for user
#### Delegate
To observe unread count on current user controller, you need to set a delegate. 
```swift
class YourViewController: CurrentChatUserControllerDelegate {
    override func viewDidLoad() {
        super.viewDidLoad()

        currentUserController.delegate = self
    }

    func currentUserController(
        _ controller: CurrentChatUserController, 
        didChangeCurrentUserUnreadCount count: UnreadCount
    ) {
        /// Handle the undread count
        UIApplication.shared.applicationIconBadgeNumber = count.messages
    }
}
```

#### Publisher
You can use Combine publisher to observe unread counts too.
```swift
currentUserController
    .unreadCountPublisher
    .map(\.messages)
    .sink { UIApplication.shared.applicationIconBadgeNumber = $0 }
    .store(in: &cancellables)
```

## Changing user
To change the logged in user, simply change token provider of the chatClient and call `reloadUserIfNeeded`.
```swift 
let token = ... // Obtain the chat token from your system
chatClient.tokenProvider = .static(token)
chatClient.currentUserController().reloadUserIfNeeded()
```