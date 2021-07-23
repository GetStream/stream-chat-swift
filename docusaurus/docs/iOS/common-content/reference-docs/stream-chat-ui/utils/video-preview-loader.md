---
title: VideoPreviewLoader
---

A protocol the video preview uploader implementation must conform to.

``` swift
public protocol VideoPreviewLoader: AnyObject 
```

## Inheritance

`AnyObject`

## Requirements

### loadPreviewForVideo(at:​completion:​)

Loads a preview for the video at given URL.

``` swift
func loadPreviewForVideo(at url: URL, completion: @escaping (Result<UIImage, Error>) -> Void)
```

#### Parameters

  - url: A video URL.
  - completion: A completion that is called when a preview is loaded. Must be invoked on main queue.
