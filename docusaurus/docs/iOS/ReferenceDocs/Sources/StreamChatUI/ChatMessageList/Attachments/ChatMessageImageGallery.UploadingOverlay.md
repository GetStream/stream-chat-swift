---
id: chatmessageimagegallery.uploadingoverlay 
title: ChatMessageImageGallery.UploadingOverlay
--- 

``` swift
open class UploadingOverlay: _View, ThemeProvider 
```

## Inheritance

[`_View`](../../CommonViews/_View), [`ThemeProvider`](../../Utils/ThemeProvider)

## Properties

### `content`

``` swift
public var content: ChatMessageImageAttachment? 
```

### `didTapOnAttachment`

``` swift
public var didTapOnAttachment: ((ChatMessageImageAttachment) -> Void)?
```

### `fileNameLabel`

``` swift
public private(set) lazy var fileNameLabel = UILabel()
            .withoutAutoresizingMaskConstraints
            .withBidirectionalLanguagesSupport
            .withAdjustingFontForContentSizeCategory
```

### `fileSizeLabel`

``` swift
public private(set) lazy var fileSizeLabel = UILabel()
            .withoutAutoresizingMaskConstraints
            .withBidirectionalLanguagesSupport
            .withAdjustingFontForContentSizeCategory
```

### `loadingIndicator`

``` swift
public private(set) lazy var loadingIndicator = components
            .loadingIndicator
            .init()
            .withoutAutoresizingMaskConstraints
```

### `actionIconImageView`

``` swift
public private(set) lazy var actionIconImageView = UIImageView()
            .withoutAutoresizingMaskConstraints
```

### `spinnerAndSizeStack`

``` swift
public private(set) lazy var spinnerAndSizeStack: UIStackView 
```

### `fileNameAndSizeStack`

``` swift
public private(set) lazy var fileNameAndSizeStack: UIStackView 
```

### `fileIconImageView`

``` swift
public private(set) lazy var fileIconImageView = UIImageView()
            .withoutAutoresizingMaskConstraints
```

### `fileSizeContainer`

``` swift
public private(set) lazy var fileSizeContainer = UIView()
            .withoutAutoresizingMaskConstraints
```

## Methods

### `layoutSubviews()`

``` swift
override open func layoutSubviews() 
```

### `setUp()`

``` swift
override open func setUp() 
```

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

### `didTapOnAttachment(_:)`

``` swift
@objc open func didTapOnAttachment(_ recognizer: UITapGestureRecognizer) 
```
