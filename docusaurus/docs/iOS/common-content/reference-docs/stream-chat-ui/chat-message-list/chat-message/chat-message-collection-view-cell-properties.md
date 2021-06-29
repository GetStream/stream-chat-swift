
### `reuseId`

``` swift
public static var reuseId: String 
```

### `messageContentView`

``` swift
public private(set) var messageContentView: _ChatMessageContentView<ExtraData>?
```

## Methods

### `prepareForReuse()`

``` swift
override public func prepareForReuse() 
```

### `setMessageContentIfNeeded(contentViewClass:attachmentViewInjectorType:options:)`

``` swift
public func setMessageContentIfNeeded(
        contentViewClass: _ChatMessageContentView<ExtraData>.Type,
        attachmentViewInjectorType: _AttachmentViewInjector<ExtraData>.Type?,
        options: ChatMessageLayoutOptions
    ) 
```

### `preferredLayoutAttributesFitting(_:)`

``` swift
override public func preferredLayoutAttributesFitting(
        _ layoutAttributes: UICollectionViewLayoutAttributes
    ) -> UICollectionViewLayoutAttributes 
