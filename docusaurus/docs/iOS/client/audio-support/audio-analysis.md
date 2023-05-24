---
title: Audio Analysis
---

The `StreamChat` framework ships with tools that enable you to analyze audio files and extract data points that can be used to visualize your files.

:::note
Audio Analysis is available since version 4.32.0.
:::

The `AudioAnalysisEngine` that ships by default with the SDK, can extract data points for the waveform visualization of an audio file.

### Actions
#### `waveformVisualisation(fromAudioURL audioURL: URL, for targetSamples: Int, completionHandler: @escaping (Result<[Float], Error>) -> Void)`

Analyses the file located in the `audioURL` and calculates its waveform representation limited to the number of requested `targetSamples`.

#### `waveformVisualisation(fromLiveAudioURL audioURL: URL, for targetSamples: Int) throws -> [Float]`
Analyses the live recording file located in the `audioURL` and calculates its waveform representation limited to the number of requested `targetSamples`.

## Errors

Errors thrown by `AudioAnalysisEngine` are instances of the `AudioAnalysisEngineError` error class and you can see references to all of them below:

#### `failedToLoadAVAssetTrack`
An error occurred when the Audio track cannot be loaded from the AudioFile provided.

#### `failedToLoadFormatDescriptions`
An error occurred when the AudioFormatDescriptions cannot be loaded from the AudioFile provided.
