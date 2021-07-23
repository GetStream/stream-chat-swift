---
title: VideoAttachmentComposerPreview
---

A view that displays the video attachment preview in composer.

``` swift
open class _VideoAttachmentComposerPreview<ExtraData: ExtraDataTypes>: _View, ThemeProvider 
```

## Inheritance

[`_View`](../../../_view), [`ThemeProvider`](../../../../utils/theme-provider)

## Properties

### `width`

``` swift
open var width: CGFloat = 100
```

### `height`

``` swift
open var height: CGFloat = 100
```

### `content`

Local URL of the video to show a preview for.

``` swift
public var content: URL? 
```

### `previewImageView`

The view that displays the video preview.

``` swift
open private(set) lazy var previewImageView: UIImageView = UIImageView()
        .withoutAutoresizingMaskConstraints
```

### `cameraIconView`

The view that displays camera icon.

``` swift
open private(set) lazy var cameraIconView: UIImageView = UIImageView()
        .withoutAutoresizingMaskConstraints
```

### `videoDurationLabel`

The view that displays video duration.

``` swift
open private(set) lazy var videoDurationLabel: UILabel = UILabel()
        .withAdjustingFontForContentSizeCategory
        .withBidirectionalLanguagesSupport
        .withoutAutoresizingMaskConstraints
```

### `gradientView`

The view that renders the gradient behind camera and video duration.

``` swift
open private(set) lazy var gradientView = components
        .gradientView.init()
        .withoutAutoresizingMaskConstraints
```

### `loadingIndicator`

The view that displays a loading indicator while the video preview is loading.

``` swift
open private(set) lazy var loadingIndicator = components
        .loadingIndicator.init()
        .withoutAutoresizingMaskConstraints
```

## Methods

### `setUpAppearance()`

``` swift
override open func setUpAppearance() 
```

### `setUpLayout()`

``` swift
override open func setUpLayout() 
```

### `updateContent()`

``` swift
override open func updateContent() 
```
