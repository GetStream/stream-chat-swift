---
title: Voice Recording
---

Stream chat allows you to exchange Voice Recordings in your channels. Those Voice Recordings are a built-in Attachment types (as are being defined [here](../guides/working-with-attachments.md)). We are going to take a look in the main parts of Voice Recording feature below.

:::note
Voice Recordings are available since version 4.32.0.
:::

VoiceRecording creation and playback is by default disabled. If you would like to enable it, you can do so by setting the Components `isVoiceRecordingEnabled` property to `true` like below:
```swift
Components.default.isVoiceRecordingEnabled = true
```

:::note
When the VoiceRecording feature is disabled, any message containing VoiceRecordings will render them as regular audio attachments.
:::

## UI Flows
### Recording
The recording flow is being presented on the `ComposerContentView` of the `ComposerVC` and it's being managed by `VoiceRecordingVC`. The `VoiceRecordingVC` takes care of the following:
- Update the UI based on the recordings state (for example recording, locked or in preview)
- Update the UI with recording related information (for example duration, current playback time)
- Coordinate information flow from audio recording and player.
- Communicate with `ComposerVC` in order to add a VoiceRecording as attachment or send it.

The main UI components that `VoiceRecordingVC` manages are the following:
#### recordingTipView
A view that is being used to display a tip to user when the tap duration on the recording button wasn't long enough (the display of this view relates to `RecordButton.minimumPressDuration`).

#### slideToCancelView
A view that during an unlocked recording, displays information on how to cancel the active recording.

#### recordingIndicatorView
A view that indicates to the user that we are currently recording audio.

#### lockIndicatorView
A view that indicates to the user if the currently active recording is locked or not.

#### liveRecordingView
A view that during a locked recording, displays information about the active recording or its preview.

#### bidirectionalPanGestureRecogniser
The gesture recogniser used to identify touch movements in the horizontal or vertical axis.
 
### Presentation
VoiceRecordings are being presented using the `voiceRecordingAttachmentView` that is defined and configurable in Components:
```swift
Components.default.voiceRecordingAttachmentView = ChatMessageVoiceRecordingAttachmentListView.ItemView.self
```

The view manages the visibility and state of all UI components (e.g play/pause button, waveform visualization, playback rate button and name label).

## Properties

### `content`
The content of the VoiceRecordingVC.

### `slideToCancelDistance`
The distance (in pixels) the user needs to slide to the leading side of the view to cancel a recording.
:::note
Default value: 75
:::

### `lockDistance`
The distance (in pixels) the user needs to slide to the top side of the view to lock the recording view.
:::note
Default value: 50
:::

### `waveformTargetSamples`
The number of samples (data points) we want to extract from a recording in order to render a waveform visualisation of it.
:::note
Default value: 100
:::

### `delegate`
The delegate which the `VoiceRecordingVC` will ask for support on presenting views and communicating the state of  the recording flow to its parent controller.

### `audioAnalysisFactory`
An object responsible for extracting the required number of samples from an audio file, that can be used to render a waveform visualisation.

## Customization
### Components configuration
#### isVoiceRecordingConfirmationRequiredEnabled

When set to `true` recorded messages can be grouped together and send as part of one message. When set to `false`, recorded messages will be sent instantly.

```swift
Components.default.isVoiceRecordingConfirmationRequiredEnabled = false
```
By default the property is set to `true`.

#### `voiceRecordingViewController`
A ViewController that manages all aspects of the voice recording from the ComposerVC. 
:::important
The VoiceRecordingVC even though it's a ViewController (as it manages a view) it doesn't manage its own view. Instead, the view property of the ViewController has been overridden and returns the ComposerView.

Avoid adding the ViewController's view in view hierarchy.
::::
```swift
Components.default.voiceRecordingViewController = VoiceRecordingVC.self
```

#### `audioPlayer`
The `AudioPlayer` that will be used for the voice recording playback.
```swift
Components.default.audioPlayer = StreamRemoteAudioQueuePlayer.self
```
:::note
Default value is `StreamRemoteAudioQueuePlayer.self`. In case you want to disable voice recording messages to play automatically once the previous one finishes, you can set this one to `StreamRemoteAudioPlayer.self`
:::

#### `audioRecorder`
The `AudioRecorder` that will be used to record new voice recordings.
```swift
Components.default.audioRecorder = StreamAudioRecorder.self
```

#### `audioSessionFeedbackGenerator`
A `feedbackGenerator` that will be used to provide haptic feedback during the recording flow. It can be customized in cases where you want to provide different or none haptic feedback for actions during the recording flow.
```swift
Components.default.audioSessionFeedbackGenerator = StreamAudioSessionFeedbackGenerator.self
```

#### `audioQueuePlayerNextItemProvider`
`ComposerVC` parent view controllers (`ChatChannelVC` and `ChatThreadVC`) will become the data source of the audio player if it's an instance of `StreamRemoteAudioQueuePlayer`. The default implementation of the `AudioQueuePlayerDatasource` in those view controllers is using the `audioQueuePlayerNextItemProvider` instance defined here to find the next (if any) voice recording to play.

```swift
Components.default.audioQueuePlayerNextItemProvider = AudioQueuePlayerNextItemProvider.self
```

When calling `findNextItem` on the `AudioQueuePlayerNextItemProvider` instance, we can specify a lookup scope. This will inform the `AudioQueuePlayerNextItemProvider` to know where to look for the next voice recording. The available values for the `lookUpScope` are:

##### `sameMessage`
The provider will look for the next VoiceRecording in the attachments of the message containing the currently playing URL.

##### `subsequentMessagesFromUser`
The provider will look for the next VoiceRecording in the attachments of the of the message containing the currently playing URL and if not found will apply the same logic in all subsequent messages that have the same author.

You can create your own `lookupScope` instances and override the implementation `AudioQueuePlayerNextItemProvider` in order to fit its functionality to your use-cases.
