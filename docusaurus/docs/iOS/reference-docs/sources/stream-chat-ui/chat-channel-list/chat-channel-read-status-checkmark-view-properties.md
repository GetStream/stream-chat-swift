
### `content`

The data this view component shows.

``` swift
open var content: Status = .empty 
```

### `imageView`

The `UIImageView` instance that shows the read/unread status image.

``` swift
open private(set) lazy var imageView = UIImageView().withoutAutoresizingMaskConstraints
```

## Methods

### `tintColorDidChange()`

``` swift
override open func tintColorDidChange() 
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
