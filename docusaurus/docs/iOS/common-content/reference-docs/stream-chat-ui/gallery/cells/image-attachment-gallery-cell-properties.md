
### `reuseId`

``` swift
open class var reuseId: String 
```

### `imageView`

A view that displays an image.

``` swift
open private(set) lazy var imageView: UIImageView = UIImageView()
        .withoutAutoresizingMaskConstraints
```

## Methods

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

### `viewForZooming(in:)`

``` swift
override open func viewForZooming(in scrollView: UIScrollView) -> UIView? 
