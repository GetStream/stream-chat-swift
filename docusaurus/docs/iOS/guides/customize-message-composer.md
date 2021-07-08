---
title: Customize Message Composer
---

import ThemingNote from '../common-content/theming-note.md'
import ComponentsNote from '../common-content/components-note.md'

The `ComposerVC` is the component responsible to create new messages or change existing messages. The composer belongs to the `ChatVC` component that integrates the message list and the composer in one view. But if you are not using our `ChatVC` you can use the composer component in isolation with your own chat view as well. The `ComposerVC` manages all the logic and actions of the `ComposerView`, where the latter is only responsible for the composer's layout.

## How to change the composer layout
Since the `ComposerView` is responsible for the composer's layout, if you want to change the styling, the position of the views, removing views or adding new ones, you need to override the `ComposerView`. Let's go through an example of customizing the composer to look like the iMessage app:

First thing we need to do is to subclass the `ComposerView`:
```swift
class iMessageComposerView: ComposerView {
    override func setUpLayout() {
        super.setUpLayout()

        // Remove the commands button, iMessage doesn't have it
        leadingContainer.removeArrangedSubview(commandsButton)

        // Move the send button from the trailing container to input container
        trailingContainer.removeArrangedSubview(sendButton)
        inputMessageView.inputTextContainer.addArrangedSubview(sendButton)

        // Remove spacing in leading container for bigger attachment button
        leadingContainer.spacing = 0

        // Make send button inside input container aligned to bottom
        inputMessageView.inputTextContainer.alignment = .bottom

        // Make the attachment button (camera button) bigger
        attachmentButton.widthAnchor.constraint(equalToConstant: 30).isActive = true
        attachmentButton.heightAnchor.constraint(equalToConstant: 30).isActive = true
    }
    
    override func setUpAppearance() {
        super.setUpAppearance()

        // Adjust the input corner radius to make the input rounder
        inputMessageView.container.layer.cornerRadius = 18
    }
}
```

Then, we need to replace the default composer with our custom subclass:
```swift
Components.default.messageComposerView = iMessageComposerView.self
```
<ComponentsNote/>

Finally, we change the attachments button icon:
```swift
appearance.images.openAttachments = UIImage(systemName: "camera.fill")!.withTintColor(.systemBlue)
```
<ThemingNote/>

| Before  | After |
| ------------- | ------------- |
| <img src={require("../assets/composer-imessage-ui-before.png").default}/> | <img src={require("../assets/composer-imessage-ui-after.png").default}/> |

The Composer is built with multiple `ContainerStackView`'s, which you can read more about them [here](../customization/custom-components#setuplayout). This makes it very easy to change the Composer layout since it is just a question moving/remove/adding views from different containers. In this example, we remove the `commandsButton` since the iMessage doesn't have it at all, and then we move the `sendButton` from the `trailingContainer` to the `inputTextContainer`. As a last touch, we replace the attachments button icon from a clip to a camera, to make it look more iMessage-like.

## How to add a new composer action
All the actions triggered by the Composer buttons are wired in the `ComposerVC.setUp()` lifecycle. When adding new buttons it is possible to add new actions by overriding this function. Let's pick the iMessage example and add an emoji button to the composer to open an Emoji picker.

First, we need to add the emoji button to the `ComposerView`:
```swift
class iMessageComposerView: ComposerView {

    lazy var emojiButton: UIButton = {
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setImage(UIImage(systemName: "face.smiling.fill"), for: .normal)
        return button
    }()

    override func setUpLayout() {
        super.setUpLayout()
        ...

        // Add the emoji button to the left side of attachment button
        leadingContainer.insertArrangedSubview(emojiButton, at: 0)
        // Make the emoji button same size as attachment button
        emojiButton.widthAnchor.constraint(equalToConstant: 30).isActive = true
        emojiButton.heightAnchor.constraint(equalToConstant: 30).isActive = true
    }
```

| Before  | After |
| ------------- | ------------- |
| <img src={require("../assets/composer-imessage-ui-after.png").default}/> | <img src={require("../assets/composer-imessage-emoji.png").default}/> |

Now, that we have our emoji button in the composer view, we need to setup an action for it and handle the logic of the new emoji picker. For this, we need to subclass the `ComposerVC` and override the `setUp()` function to add a new action and override `updateContent()` to hide the emoji button when the input text is empty.

```swift
class iMessageComposerVC: ComposerVC {

    // We need to cast the composerView to our new `iMessageComposerView`
    // so that we can have access to the new `emojiButton`.
    var iMessageComposerView: iMessageComposerView {
        composerView as! iMessageComposerView
    }

    override func setUp() {
        super.setUp()

        // Add a target action to the emoji button
        iMessageComposerView
            .emojiButton
            .addTarget(self, action: #selector(showEmojiPicker), for: .touchUpInside)
    }

    @objc func showEmojiPicker(sender: UIButton) {

        // For the sake of making the guide simple, 
        // we use an alert controller to select emojis.
        let sheetAlertController = UIAlertController(
            title: "Emoji Picker",
            message: nil,
            preferredStyle: .actionSheet
        )

        ["😃", "😇", "😅", "😂"].forEach { emoji in

            let action = UIAlertAction(title: emoji, style: .default) { _ in
                let inputTextView = self.composerView.inputMessageView.textView
                // Populate the emoji in the input view where is the caret position
                inputTextView.replaceSelectedText(emoji)
            }

            sheetAlertController.addAction(action)
        }

        present(sheetAlertController, animated: true)
    }

    override func updateContent() {
        super.updateContent()

        // Hide the emojiButton when the input text is not empty (Input expands)
        self.iMessageComposerView.emojiButton.isHidden = !self.content.text.isEmpty
    }
}
```
Finally, don't forget to configure the custom components:
```swift
Components.default.messageComposerVC = iMessageComposerVC.self
Components.default.messageComposerView = iMessageComposerView.self
```

After customizing the `ComposerVC` with the changes above you should now have an emoji picker when tapping the emoji button. To make the guide simple, we used an `UIAlertController` for the emoji picker but you can create your own custom emoji picker.

## Customizing typing suggestions
When typing on the composer, if you type `@` it will present a view suggesting users that you can mention, or if you type `/` as the first character, it will show command suggestions. You can customize not only the UI of the suggestions but also the logic around it, as well as disable this feature.

### Disabling the suggestions
Your app might not want to support suggestions at all like the iMessage app, or want to support only one of the suggestions available. You can disable the suggestions feature by just returning `nil` on the following functions:

```swift
class iMessageComposerVC: ComposerVC {

    override func typingMention(in textView: UITextView) -> (String, NSRange)? {
        return nil
    }

    override func typingCommand(in textView: UITextView) -> String? {
        return nil
    }
}
```

### Adding a new suggestion type
TODO: Give an example of adding an emoji suggestion?

### Changing the suggestions UI
The UI SDK provides a `ChatSuggestionsVC` component responsible for showing user suggestions and commands suggestions.

#### Customizing the suggestions container
In case you only want to change the styling of the container that shows both suggestions, you can override the `ChatSuggestionsVC`. Here is an example of a basic customization of the container component:
```swift
class CustomChatSuggestionsVC: ChatSuggestionsVC {
    override func setUpAppearance() {
        super.setUpAppearance()

        collectionView.layer.borderWidth = 1
        collectionView.layer.borderColor = appearance.colorPalette.border.cgColor
        collectionView.layer.cornerRadius = 10
        view.layer.shadowOpacity = 0.0
    }
}

components.suggestionsVC = CustomChatSuggestionsVC.self
```
Here we simply remove the shadow and customize the border style of the suggestions component.

| Before  | After |
| ------------- | ------------- |
| <img src={require("../assets/composer-suggestionsVC-before.png").default} /> | <img src={require("../assets/composer-suggestionsVC-after.png").default} /> |

#### Customizing the suggestions cells
If you want to further customize the suggestions UI and want to change the suggestions cells, the recommended way is to subclass the `ChatMentionSuggestionView` and `ChatCommandSuggestionView` components. Let's see an example of how we can change the user mention cell by remove the username and the "@" symbol:

```swift
class CustomMentionSuggestionView: ChatMentionSuggestionView {

    override func setUpLayout() {
        super.setUpLayout()

        textContainer.removeArrangedSubview(usernameTagLabel)
        mentionSymbolImageView.removeFromSuperview()
    }
}
```

Then, replace the custom component:
```swift
Components.default.suggestionsMentionView = CustomMentionSuggestionView.self
```

| Before  | After |
| ------------- | ------------- |
| <img src={require("../assets/composer-suggestionsVC-after.png").default} /> | <img src={require("../assets/composer-suggestionsVC-custom-cell.png").default} /> |

#### Bypassing how the suggestions are presented
Finally, if you need to have complete control over how the suggestions are presented and not use our `ChatSuggestionsVC` component you can by overriding the following functions:
```swift
class CustomComposerVC: ComposerVC {
    override func showMentionSuggestions(for typingMention: String, mentionRange: NSRange) {
        // Add your custom implementation to show mention suggestions
    }

    override func showCommandSuggestions(for typingCommand: String) {
        // Add your custom implementation to show command suggestions
    }
}
```