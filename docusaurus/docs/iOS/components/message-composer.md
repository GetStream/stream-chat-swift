---
title: Message Composer
---

import ComposerProperties from '../common-content/reference-docs/stream-chat-ui/composer/composer-vc-properties.md'
import ComposerViewProperties from '../common-content/reference-docs/stream-chat-ui/composer/composer-view-properties.md'
import ComposerContentProperties from '../common-content/reference-docs/stream-chat-ui/composer/composer-vc.content-properties.md'

The Message Composer provides all the UI and necessary functionality for writing and sending messages. It supports sending text, handling chat commands, autocomplete suggestions, uploading attachments like images, files and video. The composer is a combination of two components, the `ComposerVC` and the `ComposerView`, the first one is a view controller responsible for the functionality of the composer, where the latter is only responsible for the UI layout.

## Composer View Controller

The `ComposerVC` is the view controller that manages all the functionality and interaction with the `ComposerView`.

### Usage

The `ComposerVC` is a child view controller of the `ChatMessageListVC` which is the view controller that manages the messages of a channel. If you have already the message list component on your application, you are already using the Message Composer. But, in case you want to use the Message Composer in isolation, you can too by adding the `ComposerVC` as a child view controller of your own message list. Although, the recommended way is to use our own message list component since you get a lot of complexity for free, like managing the keyboard.

Here is an example of how you can add the composer as child view controller of your own message list:
```swift
class CustomMessageListVC: UIViewController {

    /// The channel controller injected from the Channel List
    var channelController: ChatChannelController!

    /// Your own custom message list view
    lazy var customMessageListView: CustomMessageListView = CustomMessageListView()

    /// The Message Composer view controller
    lazy var messageComposerVC = ComposerVC()

    /// The bottom constraint of the Message Composer for managing the keyboard
    private var messageComposerBottomConstraint: NSLayoutConstraint?

    /// You can use our keyboard observer to manage the keyboard
    open lazy var keyboardObserver = ChatMessageListKeyboardObserver(
        containerView: view,
        composerBottomConstraint: messageComposerBottomConstraint,
        viewController: self
    )

    override func viewDidLoad() {
        super.viewDidLoad()

        // Set the required dependencies of the composer
        messageComposerVC.channelController = channelController
        messageComposerVC.userSearchController = ChatClient.shared.userSearchController()

        // Add the message composer as a child view controller
        messageComposerVC.view.translatesAutoresizingMaskIntoConstraints = false
        messageComposerVC.willMove(toParent: self)
        addChild(messageComposerVC)
        view.addSubview(messageComposerVC.view)
        messageComposerVC.didMove(toParent: self)

        // Set the message composer at the bottom of the view
        NSLayoutConstraint.activate([
            messageComposerVC.view.topAnchor.pin(equalTo: customMessageListView.bottomAnchor),
            messageComposerVC.view.leadingAnchor.pin(equalTo: view.leadingAnchor),
            messageComposerVC.view.trailingAnchor.pin(equalTo: view.trailingAnchor)
        ])

        // Message composer bottom constraint to manage the keyboard
        messageComposerBottomConstraint = messageComposerVC.view.bottomAnchor.pin(equalTo: view.bottomAnchor)
        messageComposerBottomConstraint?.isActive = true
    }

    override open func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        // Setup the keyboard observer
        keyboardObserver.register()
    }

    override open func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)

        // Remove the keyboard observer
        keyboardObserver.unregister()
    }
}
```
As you can see if you want to use the `ComposerVC` in your own message list view you need to setup the dependencies of the composer, add it as a child view controller of your custom message list view controller and even manage the keyboard yourself or use our keyboard observer to manage it.

### Customization

The `ComposerVC` and `ComposerView` are completely customizable. You can not only change the UI layout and styling, but you can extend the composer functionality as well. In case you want to change the styling, adding new views and new functionality you can take a look at the [Customize Message Composer](../guides/customize-message-composer) guide. If you want to add a new custom attachment and make the composer to support it, you should read the [Message Composer Custom Attachments](../guides/working-with-custom-attachments) guide. 

### Properties

Complete list of all the components of `ComposerVC`.

<ComposerProperties/>

## Composer View
The `ComposerView` class which holds all the composer subviews and implements the composer layout. The composer layout is built with multiple `ContainerStackView`'s, which are very similar how  `UIStackView`'s work, you can read more about them [here](../customization/custom-components#setuplayout). This makes it very customizable since to change the layout you only need to move/remove/add views from different containers.

In the picture below you can see all the containers and main views of the composer:

<img src={require("../assets/ComposerVC_documentation.default-light.png").default} width="100%"/>

### Customization

By default the `ComposerView` is managed by the `ComposerVC`, but if you want to provide your own custom view controller to manage the composer view from scratch you can too. The only think you need to do is to add the composer view to your custom view controller, and then manage all the actions and logic of the composer yourself:

```swift
class CustomComposerVC: UIViewController {

    lazy var composerView = ComposerView()

    override func viewDidLoad() {
        super.viewDidLoad()

        // Add the composer view as subview of custom view controller
        view.addSubview(composerView)

        // Setup the composer view constraints to cover all the view
        NSLayoutConstraint.activate([
            composerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            composerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            composerView.topAnchor.constraint(equalTo: view.topAnchor),
            composerView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
}
```

### Properties 

Complete list of all the subviews that make the `ComposerView`.

<ComposerViewProperties/>

## Composer Content

The `ComposerVC.Content` is a struct that contains all the data that will be part of the composed message. It contains the current `text` of the message, the `attachments`, the `threadMessage` in case you are inside a Thread, the `command` if you are sending for example a Giphy, and the `state` of the composer to determine whether you are creating, editing or quoting a message.

Some of the composer's content properties are mutable (`var`), like the `attachments`, `threadMessage`, `text` and `command` properties. They can be directly changed since they represent data that do not depend on the state of the composer. On the other hand, there are properties that are immutable (`let`), and only can be changed through mutating functions on the `ComposerVC.Contnet`. This is to protect against bad states, for example, having the `editingMessage` property to `nil` but the `state = .edit`.

### State
The composer has three different states, `.new`, `.edit` and `.quote`. The `.new` state is when the composer is creating a new message, the `.edit` state is when we are editing an existing message and changing it's content, and finally, the `.quote` state is when we are replying a message inline (not in a thread). In the table below we can see the composer in all the three different states:

| `.new`  | `.edit` | `.quote` |
| ------------- | ------------- | ------------- |
| <img src={require("../assets/composer-ui-state-new.png").default} width="100%"/> | <img src={require("../assets/composer-ui-state-edit.png").default} width="100%"/> | <img src={require("../assets/composer-ui-state-quote.png").default} width="100%"/> |

Initially, the composer state is set to `.new` and it is created by the `initial()` static function of `ComposerVC.Content`. You can change the state of the composer through the `ComposerVC.Content`'s mutating functions:
- `content.editMessage(message:)`: Set's the `state = .edit` and populates the `editingMessage` with the provided message.
- `content.quoteMessage(message:)`: Set's the `state = .quote` and populates the `quotingMessage` with the provided message.
- `content.clear()`: Set`s the `state = .new` and clears all the composer's content data but the `threadMessage`, since the latter is dependent if you are or not in `ChatThreadVC`.

### Properties

Complete list of all the `ComposerVC.Content` data.

<ComposerContentProperties/>