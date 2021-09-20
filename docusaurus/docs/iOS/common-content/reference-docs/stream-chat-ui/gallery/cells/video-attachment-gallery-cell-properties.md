
### `reuseId`

A cell reuse identifier.

``` swift
open class var reuseId: String 
```

### `player`

A player that handles the video content.

``` swift
public var player: AVPlayer 
```

### `animationPlaceholderImageView`

Image view to be used for zoom in/out animation.

``` swift
open private(set) lazy var animationPlaceholderImageView: UIImageView = UIImageView()
        .withoutAutoresizingMaskConstraints
```

### `playerView`

A view that displays currently playing video.

``` swift
open private(set) lazy var playerView: PlayerView = components
        .playerView.init()
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

### `viewForZooming(in:)`

``` swift
override open func viewForZooming(in scrollView: UIScrollView) -> UIView? 
