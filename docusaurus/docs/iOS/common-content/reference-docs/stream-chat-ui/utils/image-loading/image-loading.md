---
title: ImageLoading
---

ImageLoading is providing set of functions for downloading of images from URLs.

``` swift
public protocol ImageLoading: AnyObject 
```

## Inheritance

`AnyObject`

## Default Implementations

### `loadImage(into:url:imageCDN:placeholder:resize:preferredSize:completion:)`

``` swift
@discardableResult
    func loadImage(
        into imageView: UIImageView,
        url: URL?,
        imageCDN: ImageCDN,
        placeholder: UIImage? = nil,
        resize: Bool = true,
        preferredSize: CGSize? = nil,
        completion: ((_ result: Result<UIImage, Error>) -> Void)? = nil
    ) -> Cancellable? 
```

### `loadImages(from:placeholders:loadThumbnails:thumbnailSize:imageCDN:completion:)`

``` swift
func loadImages(
        from urls: [URL],
        placeholders: [UIImage],
        loadThumbnails: Bool = true,
        thumbnailSize: CGSize = .avatarThumbnailSize,
        imageCDN: ImageCDN,
        completion: @escaping (([UIImage]) -> Void)
    ) 
```

## Requirements

### loadImage(using:​cachingKey:​completion:​)

Load an image from using the given URL request

``` swift
@discardableResult
    func loadImage(
        using urlRequest: URLRequest,
        cachingKey: String?,
        completion: @escaping ((_ result: Result<UIImage, Error>) -> Void)
    ) -> Cancellable?
```

#### Parameters

  - urlRequest: The `URLRequest` object used to fetch the image
  - cachingKey: The key to be used for caching this image
  - completion: Completion that gets called when the download is finished

### loadImage(into:​url:​imageCDN:​placeholder:​resize:​preferredSize:​completion:​)

Load an image into an imageView from the given URL

``` swift
@discardableResult
    func loadImage(
        into imageView: UIImageView,
        url: URL?,
        imageCDN: ImageCDN,
        placeholder: UIImage?,
        resize: Bool,
        preferredSize: CGSize?,
        completion: ((_ result: Result<UIImage, Error>) -> Void)?
    ) -> Cancellable?
```

#### Parameters

  - imageView: The `UIImageView` object in which the image should be loaded
  - url: The `URL` from which the image is to be loaded
  - imageCDN: The `ImageCDN`object which is to be used
  - placeholder: The placeholder `UIImage` to be used
  - resize: Whether to resize the image or not
  - preferredSize: The preferred size of the image to be loaded
  - completion: Completion that gets called when the download is finished

### loadImages(from:​placeholders:​loadThumbnails:​thumbnailSize:​imageCDN:​completion:​)

Load images from a given URLs

``` swift
func loadImages(
        from urls: [URL],
        placeholders: [UIImage],
        loadThumbnails: Bool,
        thumbnailSize: CGSize,
        imageCDN: ImageCDN,
        completion: @escaping (([UIImage]) -> Void)
    )
```

#### Parameters

  - urls: The URLs to load the images from
  - placeholders: The placeholder images. Placeholders are used when an image fails to load from a URL. The placeholders are used rotationally
  - loadThumbnails: Should load the images as thumbnails. If this is set to `true`, the thumbnail URL is derived from the `imageCDN` object
  - thumbnailSize: The size of the thumbnail. This parameter is used only if the `loadThumbnails` parameter is true
  - imageCDN: The imageCDN to be used
  - completion: Completion that gets called when all the images finish downloading
