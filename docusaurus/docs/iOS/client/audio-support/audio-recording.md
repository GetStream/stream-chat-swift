---
title: Audio Recording
---

The `StreamChat` framework ships with tools that enable you to record audio files.

:::note
Audio Recording is available since version 4.32.0.
:::

An instance of `AudioRecording` is responsible for handling all recording related operations and acts as a thin abstraction layer between your app and the `AVAudioRecorder` system. 

The `StreamAudioRecorder` that ships with the SDK and implements the `AudioRecording` protocol, can take care of the following responsibilities, additional to recording audio:
- Request any required permissions.
- Configure the `AVAudioSession` for recording.
- React on the application's state changes(move to background or foreground).

`StreamAudioRecorder` follows a subscription model where in order to receive updates for a recording, we need to subscribe on the recorder. Once subscribed we will start receiving events about the state of the recording.

### Configuration
The `StreamAudioRecorder` records audio in `audio/aac` format (`.aac`), with `12000` sample rate, using `1 audio channel` on `high quality`. If you need to customize any of those values you can do so by sub-classing `StreamAudioRecorder` and provide your own configuration like below.:
```swift
final class MyAppAudioRecorder: StreamAudioRecorder {

    override required convenience init() {
        self.init(configuration: .init(
            audioRecorderSettings: [
                AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
                AVSampleRateKey: 44100,
                AVNumberOfChannelsKey: 1,
                AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
            ]
            ...
        ))
    }
}
```
By doing so, you can customize other parts of the `StreamAudioRecorder` like:
- The path where audio files will be stored.
- The name and extension of the currently recording file.
- The interval that will be used to observe and receive updates on the duration of the recording audio file.
- The interval that will be used to observe and receive updates from the recorder's [meters](https://developer.apple.com/documentation/avfaudio/avaudiorecorder/1386355-meteringenabled#managing-audio-level-metering).

:::note
The `StreamAudioRecorder` doesn't support (yet) the pause and continue of a recording.
:::

### Actions
`StreamAudioRecorder` and any instance that conforms to the `AudioRecording` protocol has the following actions that we can call on them:

#### `func beginRecording(_ completionHandler: @escaping (() -> Void))`

Instructs the recorder to begin recording. The `StreamAudioRecorder` will perform the following operations prior to begin recording:
1. Activate the `AVAudioSession` for recording.
2. Request recording permission (if it hasn't been requested before).

#### `func stopRecording()`

It will stop the current recording and inform the `AVAudioSession` that recording capability is not needed any more.

#### `func pauseRecording()` & `func resumeRecording()`

They will pause and resume respectively, the current recording.

#### `configure(_ audioSessionConfigurator: AudioSessionConfiguring)`

The default object that interacts with the `AVAudioSession`, assumes that it's the only one that manages the `AVAudioSession` shared instance. In scenarios where that's not the case (for example, you have an active audio session going on because of audio/video call), you can use this method to provide a another instance that will be aware of all related features and will act as the central point of `AVAudioSession` configuration between Stream VoiceRecording feature and any other feature that uses the `AVAudioSession`.

### Receiving updates
By calling `subscribe(_ subscriber: AudioRecordingDelegate)` we are subscribing to receive updates from the `AudioRecording` instance. Those updates include information about:
- Active recording and its properties (for example its duration, state and [average power](https://developer.apple.com/documentation/avfaudio/avaudiorecorder/1387176-averagepowerforchannel))
- Successfully finished recording and the location of the audio file.
- Errors that occurred during any part of the recording flow.

## Errors

Errors thrown by `StreamAudioRecorder` are instances of the `AudioRecorderError` error class and you can see references to all of them below:
#### `noRecordPermission`
During the `beginRecording` flow, the recorder failed to obtain permission to record. That may occur if the user of your app didn't allow recording and access 

#### `failedToBegin`
Error thrown when the recorder fails to begin recording.

#### `failedToResume`
Error thrown when the recorder fails to resume an already paused recording.

#### `failedToSave`
Error thrown when the recorder fails to save the audio file of a stopped recording.

#### `unknown`
Generic error thrown in cases where the recorder failed but no error was provided.