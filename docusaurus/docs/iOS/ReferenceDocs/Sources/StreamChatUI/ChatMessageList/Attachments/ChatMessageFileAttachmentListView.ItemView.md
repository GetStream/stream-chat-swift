---
id: chatmessagefileattachmentlistview.itemview 
title: ChatMessageFileAttachmentListView.ItemView
--- 

``` swift
open class ItemView: _View, ThemeProvider 
```

## Inheritance

[`_View`](../../CommonViews/_View), [`ThemeProvider`](../../Utils/ThemeProvider)

## Properties

### `content`

Content of the attachment `ChatMessageFileAttachment`

``` swift
public var content: ChatMessageFileAttachment? 
```

### `didTapOnAttachment`

Closure what should happen on tapping the given attachment.

``` swift
open var didTapOnAttachment: ((ChatMessageFileAttachment) -> Void)?
```

### `fileNameLabel`

Label which shows name of the file, usually with extension (file.pdf)

``` swift
open private(set) lazy var fileNameLabel = UILabel()
            .withoutAutoresizingMaskConstraints
            .withBidirectionalLanguagesSupport
            .withAdjustingFontForContentSizeCategory
```

### `fileSizeLabel`

Label indicating size of the file.

``` swift
open private(set) lazy var fileSizeLabel = UILabel()
            .withoutAutoresizingMaskConstraints
            .withBidirectionalLanguagesSupport
            .withAdjustingFontForContentSizeCategory
```

### `loadingIndicator`

Animated indicator showing progress of uploading of a file.

``` swift
open private(set) lazy var loadingIndicator = components
            .loadingIndicator
            .init()
            .withoutAutoresizingMaskConstraints
```

### `actionIconImageView`

imageView indicating action for the file attachment. (Download / Retry upload...)

``` swift
open private(set) lazy var actionIconImageView = UIImageView().withoutAutoresizingMaskConstraints
```

### `mainContainerStackView`

``` swift
open private(set) lazy var mainContainerStackView: ContainerStackView = ContainerStackView()
            .withoutAutoresizingMaskConstraints
```

### `spinnerAndSizeStack`

Stack containing loading indicator and label with fileSize.

``` swift
open private(set) lazy var spinnerAndSizeStack: ContainerStackView = ContainerStackView()
            .withoutAutoresizingMaskConstraints
```

### `fileNameAndSizeStack`

Stack containing file name and and the size of the file.

``` swift
open private(set) lazy var fileNameAndSizeStack: ContainerStackView = ContainerStackView()
            .withoutAutoresizingMaskConstraints
```

### `fileIconImageView`

``` swift
open private(set) lazy var fileIconImageView = UIImageView().withoutAutoresizingMaskConstraints
```

## Methods

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
