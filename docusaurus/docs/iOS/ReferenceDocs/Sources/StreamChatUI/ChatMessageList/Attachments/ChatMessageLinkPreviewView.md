---
id: chatmessagelinkpreviewview 
title: ChatMessageLinkPreviewView
--- 

``` swift
open class _ChatMessageLinkPreviewView<ExtraData: ExtraDataTypes>: _Control, ThemeProvider 
```

## Inheritance

[`_Control`](../../CommonViews/_Control), [`ThemeProvider`](../../Utils/ThemeProvider)

## Properties

### `content`

``` swift
public var content: ChatMessageLinkAttachment? 
```

### `imagePreview`

Image view showing link's preview image.

``` swift
public private(set) lazy var imagePreview = UIImageView()
        .withoutAutoresizingMaskConstraints
```

### `authorBackground`

Background for `authorLabel`.

``` swift
public private(set) lazy var authorBackground = UIView()
        .withoutAutoresizingMaskConstraints
```

### `authorLabel`

Label showing author of the link.

``` swift
public private(set) lazy var authorLabel = UILabel()
        .withoutAutoresizingMaskConstraints
        .withBidirectionalLanguagesSupport
```

### `titleLabel`

Label showing `title`.

``` swift
public private(set) lazy var titleLabel = UILabel()
        .withoutAutoresizingMaskConstraints
        .withBidirectionalLanguagesSupport
```

### `bodyTextView`

Text view for showing `content`'s `text`.

``` swift
public private(set) lazy var bodyTextView = UITextView()
        .withoutAutoresizingMaskConstraints
```

### `textStack`

`ContainerStackView` for labels with text metadata.

``` swift
public private(set) lazy var textStack = ContainerStackView()
        .withoutAutoresizingMaskConstraints
```

### `authorOnImageConstraint`

Constraint for `authorLabel`.

``` swift
open var authorOnImageConstraint: NSLayoutConstraint?
```

## Methods

### `setUpAppearance()`

``` swift
override open func setUpAppearance() 
```

### `setUp()`

``` swift
override open func setUp() 
```

### `setUpLayout()`

``` swift
override open func setUpLayout() 
```

### `updateContent()`

``` swift
override open func updateContent() 
```

### `tintColorDidChange()`

``` swift
override open func tintColorDidChange() 
```
