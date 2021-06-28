
### `content`

``` swift
public var content: Content? 
```

### `contentView`

``` swift
public private(set) lazy var contentView = components
        .reactionsView
        .init()
        .withoutAutoresizingMaskConstraints
```

### `tailLeadingAnchor`

``` swift
open var tailLeadingAnchor: NSLayoutXAxisAnchor 
```

### `tailTrailingAnchor`

``` swift
open var tailTrailingAnchor: NSLayoutXAxisAnchor 
```

## Methods

### `setUpLayout()`

``` swift
override open func setUpLayout() 
```

### `updateContent()`

``` swift
override open func updateContent() 
