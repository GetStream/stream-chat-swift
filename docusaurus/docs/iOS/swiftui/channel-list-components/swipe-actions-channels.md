---
title: Swipe Actions for the Channel List
---

## Changing the Swipe Actions Ui

When the user swipes left on a channel in the channel list, there are additional actions that can be performed on that channel. By default, one of them is the deleting of a conversation, while the other one is about performing other actions.

The SwiftUI SDK allows you to either use the same view, with additional actions you want to provide, or inject a completely different view, with your own design.

### Adding Additional Actions

First, we will explore how you can extend the existing channel actions view with your own actions. The default actions provided by the SDK are leaving group, muting/unmuting group and users, as well as deleting the conversation. 

Let's now add additional action that will freeze the channel. In order to do this, we need to create our own view factory, which will provide its own implementation of the `supportedMoreChannelActions` method of the SDK. This method returns an array of the channel actions displayed when the ellipsis button is tapped in the swiped state of a channel.

```swift
func supportedMoreChannelActions(
    for channel: ChatChannel,
    onDismiss: @escaping () -> Void,
    onError: @escaping (Error) -> Void
) -> [ChannelAction] {
    var defaultActions = ChannelAction.defaultActions(
        for: channel,
        chatClient: chatClient,
        onDismiss: onDismiss,
        onError: onError
    )
    
    let freeze = {
        let controller = self.chatClient.channelController(for: channel.cid)
        controller.freezeChannel { error in
            if let error = error {
                onError(error)
            } else {
                onDismiss()
            }
        }
    }
    
    let confirmationPopup = ConfirmationPopup(
        title: "Freeze channel",
        message: "Are you sure you want to freeze this channel?",
        buttonTitle: "Freeze"
    )
    
    let channelAction = ChannelAction(
        title: "Freeze channel",
        iconName: "person.crop.circle.badge.minus",
        action: freeze,
        confirmationPopup: confirmationPopup,
        isDestructive: false
    )
    
    defaultActions.insert(channelAction, at: 0)
    return defaultActions
}

```

Let's explore the code sample above in more details. First, we take the currently default actions provided by the SDK. If you don't want to use them as basis, you can create a new list of actions from scratch. 

Next, we create the freeze action, which creates a channel controller, and executes the `freezeChannel` method of the low-level chat client. In the completion handler, we provide the onError and onDismiss actions, depending on the result of the freeze action. These are the default ones, which either close the actions view on success, or display an alert in case of a failure. You can add additional logic here if needed.  

We can optionally specify a confirmation popup, where the end-users are asked if they really want to perform the action. The `ConfrimationPopup` struct has title, message and button title. If you don't create one and pass nil, the popup will not be displayed and the action will be performed immediately. Apart from the confirmation popup, you can also specify the title and icon shown in the menu of actions, as well as whether the action is destrutive.

Finally, we need to inject the `CustomFactory` in our view hierarchy.

```swift
var body: some Scene {
    WindowGroup {
        ChatChannelListView(viewFactory: CustomFactory.shared)
    }
}
```

### Swapping the Whole View

If the user interface or logic don't match your app's requirements, you can easily create your own view and inject it in the place of the SDK's default one. In order to do that, similarly to other places in the SDK, you just need to implement the corresponding method of the `ViewFactory` in your own custom implementation. In this case, that's the `makeMoreChannelActionsView` method.

```swift
func makeMoreChannelActionsView(
    for channel: ChatChannel,
    swipedChannelId: Binding<String?>,
    onDismiss: @escaping () -> Void,
    onError: @escaping (Error) -> Void
) -> some View {
    VStack {
        Text("This is our custom view")
        Spacer()
        HStack {
            Button {
                onDismiss()
            } label: {
                Text("Action")
            }
        }
        .padding()
    }
}
```

Afterwards, don't forget to inject your custom factory to our view hierarchy.

```swift
var body: some Scene {
    WindowGroup {
        ChatChannelListView(viewFactory: CustomFactory.shared)
    }
}
```