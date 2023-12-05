---
title: Audio Playback
---

The `StreamChat` framework ships with tools that enable you to playback any (supported) audio file.

:::note
Audio Playback, using an instance of `AudioPlaying`, is available since version 4.32.0.
:::

An instance of `AudioPlaying` is responsible for handling all audio playback related operations and acts as a thin abstraction layer between your app and the `AVPlayer` system. 

:::note
The SDK ships with 2 audio players out of the box, 1. `StreamAudioPlayer` and 2. `StreamAudioQueuePlayer`. As `StreamAudioQueuePlayer` is a simple sub-class of `StreamAudioPlayer` that extends its queue management capabilities, we will focus on the `StreamAudioPlayer` base class for now.
::::

The `StreamAudioPlayer` that ships with the SDK and implements the `AudioPlaying` protocol, can take care of the following responsibilities, additional to managing the audio playback of:
- Configure the `AVAudioSession` for recording.
- React on the application's state changes(move to background or foreground).
- Fetch remote properties of remote audio files (for example its duration).

`StreamAudioPlayer` follows a subscription model where in order to receive updates for playback, we need to subscribe on the player. Once subscribed we will start receiving events about the state of the playback.

### Actions
`StreamAudioPlayer` and any instance that conforms to the `AudioPlaying` protocol has the following actions that we can call on them:

#### `func loadAsset(from url: URL)`
Instructs the player to load the asset from the provided URL and prepare it for streaming. If the player's current item has a URL that matches the provided one, then the player will try to play or restart the playback.

#### `func play()`
Begin the loaded asset's playback. If no asset has been loaded, the action has no effect.

#### `func pause()`
Pauses the loaded asset's playback. If non has been loaded or the playback hasn't started yet the action has no effect.

#### `func stop()`
Stop the loaded asset's playback. If non has been loaded or the playback hasn't started yet the action has no effect.

#### `func updateRate(_:)`
Updates the loaded asset's playback rate to the provided one.

#### `func seek(to:)`
Performs a seek in the loaded asset's timeline at the provided time.

#### `configure(_ audioSessionConfigurator: AudioSessionConfiguring)`

The default object that interacts with the `AVAudioSession`, assumes that it's the only one that manages the `AVAudioSession` shared instance. In scenarios where that's not the case (for example, you have an active audio session going on because of audio/video call), you can use this method to provide a another instance that will be aware of all related features and will act as the central point of `AVAudioSession` configuration between Stream VoiceRecording feature and any other feature that uses the `AVAudioSession`.

### Receiving updates

By calling `subscribe(_ subscriber: AudioPlayingDelegate)` we are subscribing to receive updates from the `AudioPlaying` instance. Those updates include information about:
- The URL for the loaded audio file.
- The duration and current playback time.
- The player's state.
- The playback's rate.
- A flag indicating if the player is currently seeking.

## StreamAudioQueuePlayer

The `StreamAudioQueuePlayer` implementation is a sub-class of `StreamAudioPlayer` with additional queue management capabilities. It requires a data source that conforms to the `AudioQueuePlayerDatasource` protocol. Once the playback of an audio file finishes, the `StreamAudioQueuePlayer` will ask its data source for the next item to play. If the `dataSource` provide one, the new item will be automatically loaded to the player its playback will begin once ready.