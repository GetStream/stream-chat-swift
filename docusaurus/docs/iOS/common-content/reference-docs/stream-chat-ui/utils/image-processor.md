---
title: ImageProcessor
---

``` swift
public protocol ImageProcessor 
```

## Requirements

### crop(image:​to:​)

Crop the image to a given size. The image is center-cropped

``` swift
func crop(image: UIImage, to size: CGSize) -> UIImage?
```

#### Parameters

  - image: The image to crop
  - size: The size to which the image needs to be cropped

#### Returns

The cropped image

### scale(image:​to:​)

Scale an image to a given size maintaing the aspect ratio.

``` swift
func scale(image: UIImage, to size: CGSize) -> UIImage
```

#### Parameters

  - image: The image to scale
  - size: The size to which the image needs to be scaled

#### Returns

The scaled image
