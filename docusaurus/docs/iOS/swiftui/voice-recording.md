---
title: Voice Recording
---

Stream Chat's SwiftUI SDK allows you to record and share async voice messages in your channels. The voice recordings have a built-in attachment type (as defined [here](https://getstream.io/chat/docs/sdk/ios/uikit/guides/working-with-attachments/)).

:::note
Voice Recordings on SwiftUI are available since version [4.46.0](https://github.com/GetStream/stream-chat-swiftui/releases/tag/4.46.0).
:::

Voice recording is disabled by default. In order to enable it, you should setup the `isVoiceRecordingEnabled` property to `true`, when setting up the `StreamChat` client:

```swift
let utils = Utils(
    composerConfig: ComposerConfig(isVoiceRecordingEnabled: true)
)
let streamChat = StreamChat(chatClient: chatClient, utils: utils)
```

## Recording UI Flows

The voice recording feature supports several different UI flows.

### Recording

When the user long presses on the voice recording button longer than 1 second, the recording is started. In that case, while the button is still pressed, the recording view is shown.

The recording view provides the following actions:
- add the recording to the composer input (invoked when releasing the long press button)
- slide to cancel (invoked when you drag to the slide to cancel indicator)
- lock the recording (invoked when drag towards the lock button)

In order to replace this view with your own implementation, you can implement the following `ViewFactory` method.

```swift
public func makeComposerRecordingView(
        viewModel: MessageComposerViewModel,
        gestureLocation: CGPoint
) -> some View {
    CustomRecordingView(viewModel: MessageComposerViewModel, location: gestureLocation)
```

### Locked View

When the user decides to lock the recording, `LockedView` is presented. It provides the user the following actions:
- discard the recording - the user is back to the initial state.
- stop the recording - the user goes into the recording preview state.
- confirm the recording - the recording is added to the composer input.

If you want to replace this view with your own implementation, you can implement the following method.

```swift
public func makeComposerRecordingLockedView(
    viewModel: MessageComposerViewModel
) -> some View {
    CustomLockedView(viewModel: viewModel)
}
```

#### Preview Recording

If you stop the recording, the `LockedView` goes into a preview state. This means that there's no recording in progress, but you can still both discard or confirm the recording. Additionally, you can play the recording.

### Recording Tip View

If you press and release the voice recording button for less than 1 second, a tip view is presented. If you want to customize this view, you can implement the following method in the `ViewFactory`.

```swift
public func makeComposerRecordingTipView() -> some View {
    CustomRecordingTipView()
}
```

## Voice Recording Attachment

When a message with a voice recording attachment is sent, it appears in the message list with a voice recording specific user interface.

If you want to change the default UI, you should implement the `makeVoiceRecordingView` in the `ViewFactory`.

```swift
public func makeVoiceRecordingView(
    for message: ChatMessage,
    isFirst: Bool,
    availableWidth: CGFloat,
    scrolledId: Binding<String?>
) -> some View {
    CustomVoiceRecordingView(
        message: message,
        width: availableWidth,
        isFirst: isFirst,
        scrolledId: scrolledId
    )
}
```