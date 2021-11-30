---
title: Message Composer
---

import ComposerProperties from '../../common-content/reference-docs/stream-chat-ui/composer/composer-vc-properties.md'
import ComposerViewProperties from '../../common-content/reference-docs/stream-chat-ui/composer/composer-view-properties.md'
import ComposerContentProperties from '../../common-content/reference-docs/stream-chat-ui/composer/composer-vc.content-properties.md'

The Message Composer provides all the UI and necessary functionality for writing and sending messages. It supports sending text, handling chat commands, suggestions autocompletion, uploading attachments like images, files, and videos. The composer is a combination of two components, the `ComposerVC` and the `ComposerView`, the first one is a view controller responsible for the functionality, where the latter is only responsible for the UI and layout.

## Composer View Controller

The `ComposerVC` is the view controller that manages all the functionality and interaction with the `ComposerView`.

### Usage

The `ComposerVC` is used by both the Channel and Thread components, but you can also add the `ComposerVC` in your View Controller as a child view if needed. Please keep in mind that if you do so you will need to manage the keyboard yourself. Here is an example of how you can add the composer as a child view controller:

```swift
class CustomChatVC: UIViewController {

    /// The channel controller injected from the Channel List
    var channelController: ChatChannelController!

    /// Your own custom message list view
    lazy var customMessageListView: CustomMessageListView = CustomMessageListView()

    /// The Message Composer view controller
    lazy var messageComposerVC = ComposerVC()

    /// The bottom constraint of the Message Composer for managing the keyboard
    private var messageComposerBottomConstraint: NSLayoutConstraint?

    /// Component responsible for setting the correct offset when keyboard frame is changed.
    open lazy var keyboardHandler: KeyboardHandler = ComposerKeyboardHandler(
        composerParentVC: self,
        composerBottomConstraint: messageComposerBottomConstraint
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

        keyboardHandler.start()
    }

    override open func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)

        keyboardHandler.stop()
    }
}
```
As you can see if you want to use the `ComposerVC` in your custom message list view you need to setup the dependencies of the composer, add it as a child view controller of your custom message list view controller, and even manage the keyboard yourself or use our keyboard observer to manage it.

### Customization

The `ComposerVC` and `ComposerView` are highly customizable in both styling and functionality. In case you want to change the styling, adding new views, and new functionality you can take a look at the [Customize Message Composer](../guides/customize-message-composer) guide. If you want to introduce a new custom attachment and make the composer support it, please read the [Message Composer Custom Attachments](../guides/working-with-custom-attachments) guide.

### Properties

The complete list of all the `ComposerVC`'s components.

<ComposerProperties/>

## Composer View

The `ComposerView` class holds all the composer subviews and implements the composer layout. The composer layout is built with multiple `ContainerStackView`'s, which are very similar how `UIStackView`'s work, you can read more about them [here](../uikit/custom-components#setuplayout). This makes it very customizable since to change the layout you only need to move/remove/add views from different containers.

In the picture below you can see all the containers and main views of the composer:

<img src={require("../../assets/ComposerVC_documentation.default-light.png").default} width="100%"/>

### Customization

By default, the `ComposerView` is managed by the `ComposerVC`, but if you want to provide your custom view controller to manage the composer view from scratch you can too. The only thing you need to do is to add the composer view to your custom view controller, and then manage all the actions and logic of the composer yourself:

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

The `ComposerVC.Content` is a struct that contains all the data that will be part of the composed message. It contains the current `text` of the message, the `attachments`, the `threadMessage` in case you are inside a Thread, the `command` if you are sending, for example, a Giphy, and the `state` of the composer to determine whether you are creating, editing or quoting a message.

### State
The composer has three states: `.new`, `.edit`, and `.quote`. The `.new` state is when the composer is creating a new message, the `.edit` state is when we are editing an existing message and changing its content, and finally, the `.quote` state is when we are replying to a message inline (not in a thread). In the table below we can see the composer in all three different states:

| `.new`  | `.edit` | `.quote` |
| ------------- | ------------- | ------------- |
| <img src={require("../../assets/composer-ui-state-new.png").default} width="100%"/> | <img src={require("../../assets/composer-ui-state-edit.png").default} width="100%"/> | <img src={require("../../assets/composer-ui-state-quote.png").default} width="100%"/> |

The `.new` state is the composer's default state, and it is initialized by the `initial()` static function of `ComposerVC.Content`:
```swift
/// The content of the composer. Property of `ComposerVC`.
public var content: Content = .initial() {
    didSet {
        updateContentIfNeeded()
    }
}
```

 You can change the state of the composer through the `ComposerVC.Content`'s mutating functions:
- `content.editMessage(message:)`: Set's the state to `.edit` and populates the `editingMessage` with the provided message.
- `content.quoteMessage(message:)`: Set's the state to `.quote` and populates the `quotingMessage`.
- `content.clear()`: Set's the state to `.new` and clears all the composer's content data.

### Adding a Command
When adding a command to a message we need to make sure we clean the attachments and the current text. This is why you can only add a command through the `ComposerVC.Content`'s `addCommand(command:)` mutating function which does this automatically for you.

### Properties

Complete list of all the `ComposerVC.Content` data and functions.

<ComposerContentProperties/>