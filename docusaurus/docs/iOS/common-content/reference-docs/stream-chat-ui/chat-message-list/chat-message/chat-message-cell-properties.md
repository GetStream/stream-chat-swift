
### `reuseId`

``` swift
public static var reuseId: String 
```

### `messageContentView`

The message content view the cell is showing.

``` swift
public private(set) var messageContentView: ChatMessageContentView?
```

### `minimumSpacingBelow`

The minimum spacing below the cell.

``` swift
public var minimumSpacingBelow: CGFloat = 2 
```

## Methods

### `setUp()`

``` swift
override public func setUp() 
```

### `setUpAppearance()`

``` swift
override public func setUpAppearance() 
```

### `prepareForReuse()`

``` swift
override public func prepareForReuse() 
```

### `setMessageContentIfNeeded(contentViewClass:attachmentViewInjectorType:options:)`

Creates a message content view

``` swift
public func setMessageContentIfNeeded(
        contentViewClass: ChatMessageContentView.Type,
        attachmentViewInjectorType: AttachmentViewInjector.Type?,
        options: ChatMessageLayoutOptions
    ) 
```

#### Parameters

  - contentViewClass: The type of message content view.
  - attachmentViewInjectorType: The type of attachment injector.
