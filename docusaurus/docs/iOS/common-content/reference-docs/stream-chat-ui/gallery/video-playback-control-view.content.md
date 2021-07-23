---
title: VideoPlaybackControlView.Content
---

The type describing the content of the view.

``` swift
public struct Content 
```

## Initializers

### `init(videoDuration:videoState:playingProgress:)`

``` swift
public init(
            videoDuration: TimeInterval,
            videoState: VideoState,
            playingProgress: Double
        ) 
```

## Properties

### `videoDuration`

A video duration in seconds.

``` swift
public var videoDuration: TimeInterval
```

### `videoState`

A video playback state.

``` swift
public var videoState: VideoState
```

### `playingProgress`

A video playback progress in \[0...1\] range

``` swift
public var playingProgress: Double
```

### `currentTime`

A current location in video.

``` swift
public var currentTime: TimeInterval 
```

### `initial`

``` swift
public static var initial: Self 
```
