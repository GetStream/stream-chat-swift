
### `actionButton`

Button wrapped inside this ActionView

``` swift
open var actionButton: UIButton = UIButton().withoutAutoresizingMaskConstraints
```

### `action`

Action which will be called on `.touchUpInside` of `actionButton`

``` swift
open var action: (() -> Void)?
```

## Methods

### `setUp()`

``` swift
override public func setUp() 
```

### `setUpLayout()`

``` swift
override public func setUpLayout() 
