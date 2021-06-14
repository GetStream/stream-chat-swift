
``` swift
open class _ChatMessageInteractiveAttachmentView<ExtraData: ExtraDataTypes>: _View, ThemeProvider 
```

## Inheritance

[`_View`](../../CommonViews/_View), [`ThemeProvider`](../../Utils/ThemeProvider)

## Properties

### `content`

``` swift
public var content: ChatMessageGiphyAttachment? 
```

### `didTapOnAction`

``` swift
public var didTapOnAction: ((AttachmentAction) -> Void)?
```

### `preview`

``` swift
public private(set) lazy var preview = components
        .giphyView
        .init()
        .withoutAutoresizingMaskConstraints
```

### `separator`

``` swift
public private(set) lazy var separator = UIView()
        .withoutAutoresizingMaskConstraints
```

### `actionsStackView`

``` swift
public private(set) lazy var actionsStackView: UIStackView 
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
