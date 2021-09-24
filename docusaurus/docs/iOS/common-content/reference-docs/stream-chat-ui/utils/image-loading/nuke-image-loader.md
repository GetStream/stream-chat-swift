---
title: NukeImageLoader
---

The class which is resposible for loading images from URLs.
Internally uses `Nuke`'s shared object of `ImagePipeline` to load the image.

``` swift
open class NukeImageLoader: ImageLoading 
```

## Inheritance

[`ImageLoading`](../image-loading)

## Methods

### `loadImage(using:cachingKey:completion:)`

``` swift
@discardableResult
    open func loadImage(
        using urlRequest: URLRequest,
        cachingKey: String?,
        completion: @escaping ((Result<UIImage, Error>) -> Void)
    ) -> Cancellable? 
```

### `loadImages(from:placeholders:loadThumbnails:thumbnailSize:imageCDN:completion:)`

``` swift
open func loadImages(
        from urls: [URL],
        placeholders: [UIImage],
        loadThumbnails: Bool,
        thumbnailSize: CGSize,
        imageCDN: ImageCDN,
        completion: @escaping (([UIImage]) -> Void)
    ) 
```

### `loadImage(into:url:imageCDN:placeholder:resize:preferredSize:completion:)`

``` swift
@discardableResult
    open func loadImage(
        into imageView: UIImageView,
        url: URL?,
        imageCDN: ImageCDN,
        placeholder: UIImage?,
        resize: Bool = true,
        preferredSize: CGSize? = nil,
        completion: ((_ result: Result<UIImage, Error>) -> Void)? = nil
    ) -> Cancellable? 
```
