---
title: Navigation
---

The StreamChatUI SDK not only provides reusable UI Components, but also it comes with navigation flows out of the box, that you can customize.

## Routers

The navigation of StreamChatUI SDK is handled by `NavigationRouter`'s. Currently, the available routers in the SDK are the following:

- `ChatChannelListRouter`: The Channel List Router is responsible to handle the navigation of the Channel List, like showing the Channel View.
- `ChatMessageListRouter`: The Message List Router is responsible to handle the navigation of the Message List, like showing the User Profile View, the Gallery View, the Message Actions Popup, etc.
- `AlertsRouter`: The Alerts Router is responsible to show alerts in the Chat SDK, like confirmation dialogues.

### Presenting a custom user profile view

Currently, the StreamChatUI SDK does not come with a user profile view out of the box, since most apps already have their own user profile view. If you want to show your user profile view whenever the user clicks on an avatar or clicks on a user mention, you can do so my customizing the `ChatMessageListRouter`.

```swift
import Foundation
import StreamChatUI
import StreamChat

final class CustomMessageListRouter: ChatMessageListRouter {

    override func showUser(_ user: ChatUser) {
        // Create your profile view controller with the given user info
        let profileViewController = ...
        // Present the view controller
        rootViewController.present(profileViewController, animated: true)
    }
}
```

Then, you should replace your customer router in the `Components` configuration:

```swift
Components.default.messageListRouter = CustomMessageListRouter.self
```

In case you want to have a different view for when the user clicks on the avatar vs when it clicks on a user mention, you can also override the following methods to have more flexibility: 
- `ChatMessageListVC.messageContentViewDidTapOnMentionedUser()`
- `ChatMessageListVC.messageContentViewDidTapOnAvatarView()` 