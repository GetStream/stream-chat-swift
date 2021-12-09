---
title: Customize Message Actions
---

The `ChatMessageActionsVC` is the ViewController responsible for displaying the actions when the tap & hold gesture is triggered on an individual message. The responsibility of this ViewController is to build up a small UIView that will display actions that a user can perform based on membership of the Channel.

The standard message actions consist of:

<img
  src={require('../assets/actions-screenshot.png').default}
  width="300"
  align="right"
/>

- Edit Message
- Delete Message
- Resend Message
- Mute Action
- Unmute Action
- Inline Reply
- Thread Reply
- Copy Message

These actions will be displayed based on where it's triggered in the StreamChatUI SDK. It will also depend on the user's membership.

## How to Change the List of Actions Based on Membership

You might want to change the list of actions displayed based on your permissions. For example, here, you will demonstrate the `delete` action for `admins`.

Start by creating a new Swift file.

*File -> New -> New File...*

<img src={require("../assets/create-new-file.png").default}/>

Next, add the `imports` for the SDK.

```swift
import StreamChat
import StreamChatUI
```

All of our SDK is open for customization, so the next step is to subclass the `ChatMessageActionsVC`.

```swift
class CustomChatMessageActionsVC: ChatMessageActionsVC {

}
```

You are going to require access to the current user's membership so let's go ahead and create a new variable that will return this.

```swift
class CustomChatMessageActionsVC: ChatMessageActionsVC {
    var currentUserMembership: ChatChannelMember? {
        guard
            let cid = message?.cid,
            let channel = messageController.dataStore.channel(cid: cid)
        else { return nil }

        return channel.membership
    }
  }
```

This code will query the message controller's dataStore and return the channel membership for the current user.

The final step in our subclass is to return the array of `MessageActions`.

```swift
override var messageActions: [ChatMessageActionItem] {

///1.
    var action = super.messageActions

///2.
    if let message = message,
       !message.isDeleted,
       !message.isSentByCurrentUser,
       let membership = currentUserMembership,
       membership.isAdmin
    {
      ///3.
        action += [
            deleteActionItem()
        ]
    }

    ///4.
    return action
}
```

So let's step through this code:

1. We grab the current list of actions defined within the SDK.
2. We're checking if we have a message that is not deleted, sent by the current user, and is an admin.
3. Add the `deleteActionItem` to the array of actions.
4. Return the actions.

Your final subclass should look like this:

```swift
import StreamChat
import StreamChatUI

class CustomChatMessageActionsVC: ChatMessageActionsVC {
    var currentUserMembership: ChatChannelMember? {
        guard
            let cid = message?.cid,
            let channel = messageController.dataStore.channel(cid: cid)
        else { return nil }

        return channel.membership
    }

    override var messageActions: [ChatMessageActionItem] {
        var action = super.messageActions

        if let message = message,
           !message.isDeleted,
           !message.isSentByCurrentUser,
           let membership = currentUserMembership,
           membership.isAdmin
        {
            action += [
                deleteActionItem()
            ]
        }

        return action
    }
}
```

And of course, you can change this to suit your requirements.

The final step is to create an extension to create the `isAdmin` bool flag on the membership.

```swift
extension ChatChannelMember {
    var isAdmin: Bool {
        MemberRole.adminRoles.contains(memberRole)
    }
}

extension MemberRole {
    static let adminRoles: [Self] = [
        .moderator,
        .admin,
        .owner
    ]
}
```

This code will allow you to extend `ChatChannelMember` and create a variable that returns a Boolean based on `adminRoles`. We also have an extension on `MemberRole` to encapsulate what an `admin` comprises. In our example, an admin is either `moderator`, `admin` or `owner`.
