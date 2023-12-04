---
title: Message Composer Overview
---


The message composer is the component that allows you to send messages consisting of text, images, video, files and links. The composer is customizable - you can provide your own views for several slots. The default component consists of several parts:

- Leading composer view - displayed in the left part of the component. The default implementation shows buttons for displaying media picker and giphy commands.
- Composer input view - the view that displays the input for the message. The default component allows adding text, as well as images, files and videos.
- Trailing composer view - displayed in the right part of the component. Usually used for sending the message.
- Attachment picker view - component that allows you to pick several different types of attachments. The default component has three types of attachments (images and videos from the photo library, files and camera input). When an attachment is selected, by default it is added to the composer's input view. You can inject custom views (alternative pickers) in the component itself as well.

## Applying a Custom Modifier

If you want to customize the background, padding and other styling properties of the composer view, you can apply a custom modifier by implementing the method `makeComposerViewModifier` in the `ViewFactory`. Here's an example that changes the background of the composer view.

```swift
func makeComposerViewModifier() -> some ViewModifier {
    BackgroundViewModifier()
}

struct BackgroundViewModifier: ViewModifier {

    public func body(content: Content) -> some View {
        content
            .background(Color.red)
    }
}
```

## Customizing the Trailing Composer View

If you want to change the button for sending messages (or add additional content alongside it), you will need to implement the `makeTrailingComposerView` method in the `ViewFactory`. Here's an example usage:

```swift
public func makeTrailingComposerView(
    enabled: Bool,
    cooldownDuration: Int,
    onTap: @escaping () -> Void
) -> some View {
    CustomSendMessageButton(enabled: enabled, onTap: onTap)
}
```

The method provides the following parameters:
- `enabled` - whether there's content (text / attachment) for the message to be sent.
- `cooldownDuration` - if the channel is in cooldown mode, use this property to show a timer with the duration (in seconds) until the user can send messages again.
- `onTap` - the action to be executed when the user taps on the button to send a message. You should attach this action to your custom button, in order for the message to be sent.

Some messaging apps hide the send button when there's no text or attachments input provided by the users. To support such case, you can use the `enabled` property to hide or show the send message button.

## Customizing the Leading Composer View

You can also swap the leading composer view with your own implementation. This might be useful if you want to change the behaviour of the attachment picker (provide a different one), or even just hide the component.

In order to do this, you need to implement the `makeLeadingComposerView`, which receives a binding of the `PickerTypeState`. Having the `PickerTypeState` as a parameter allows you to control the visibility of the attachment picker view. The `PickerTypeState` has two states - expanded and collapsed. If the state is collapsed, the composer is in the minimal mode (only the text input and leading and trailing areas are shown). If the `enum` state is expanded, it has associated value with it, which is of type `AttachmentPickerType`. This defines the type of picker which is currently displayed in the attachment picker view. The possible states are `none` (nothing is selected), `media` (media picker is selected), `giphy` (giphy commands picker is shown) and custom (for your own custom pickers).

Apart from the `PickerTypeState`, you also receive the `ChannelConfig` as a parameter. This configuration allows you to control the display of some elements from the channel response from the backend, such as enabling / disabling of the attachments, max message length, typing indicators, etc. More details about the available settings in the channel configuration can be found [here](https://getstream.io/chat/docs/ios-swift/channel_features/?language=swift).

Here's an example on how to provide a view for the leading composer view:

```swift
public func makeLeadingComposerView(
        state: Binding<PickerTypeState>,
        channelConfig: ChannelConfig?
) -> some View {
    AttachmentPickerTypeView(
        pickerTypeState: state,
        channelConfig: channelConfig
    )
}
```

The `AttachmentPickerTypeView` comes with a lot of functionalities, in terms of image and video picker, file picker and selecting media from the camera. While you can just swap this component if it doesn't fit your needs (like shown above), it's also possible to extend it with additional message attachment types to fit your needs.

To learn more, check our [Custom Attachments guide](./message-composer.md).

## Customizing the Composer Input View

The input text view can also be replaced with your own implementation. To do this, you need to provide your own implementation of the `makeComposerInputView`.

```swift
public func makeComposerInputView(
        text: Binding<String>,
        selectedRangeLocation: Binding<Int>,
        command: Binding<ComposerCommand?>,
        addedAssets: [AddedAsset],
        addedFileURLs: [URL],
        addedCustomAttachments: [CustomAttachment],
        quotedMessage: Binding<ChatMessage?>,
        maxMessageLength: Int?,
        cooldownDuration: Int,
        onCustomAttachmentTap: @escaping (CustomAttachment) -> Void,
        shouldScroll: Bool,
        removeAttachmentWithId: @escaping (String) -> Void
    ) -> some View {
    CustomComposerInputView(
        factory: self,
        text: text,
        selectedRangeLocation: selectedRangeLocation,
        command: command,
        addedAssets: addedAssets,
        addedFileURLs: addedFileURLs,
        addedCustomAttachments: addedCustomAttachments,
        quotedMessage: quotedMessage,
        maxMessageLength: maxMessageLength,
        cooldownDuration: cooldownDuration,
        onCustomAttachmentTap: onCustomAttachmentTap,
        removeAttachmentWithId: removeAttachmentWithId
    )
}
```

The following parameters are provided to this method:
- `text` - the binding of the text that's entered in the input view.
- `selectedRangeLocation` - the location of the cursor.
- `command` - optional, if a command is selected in the composer (for example `giphy`).
- `addedAssets` - a list of the added assets.
- `addedFileURLs` - a list of the added file URLs.
- `addedCustomAttachments` - a list of the added custom attachments.
- `quotedMessage` - optional, binding for a quoted message.
- `maxMessageLength` - optional, the maximum allowed length of a message.
- `cooldownDuration` - if the channel is in slow-mode, it provides the cooldown duration.
- `onCustomAttachmentTap` - called when a custom attachment is tapped.
- `shouldScroll` - whether the input view should be scrollable.
- `removeAttachmentWithId` - called when an attachment should be removed from the selected attachments.

## Next Steps

Our SDK has support for providing custom attachments. If you want to learn more how to do this, please check our [Custom Attachments guide](./message-composer.md).

Additionally, learn how to create your own composer by building Apple Messages' iOS 17 Composer [here](../swiftui-cookbook/custom-composer.md).