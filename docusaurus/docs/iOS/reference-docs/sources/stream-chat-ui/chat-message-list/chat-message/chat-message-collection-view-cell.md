---
title: ChatMessageCollectionViewCell
---

The cell that displays the message content of a dynamic type and layout.
Once the cell is set up it is expected to be dequeued for messages with
the same content and layout the cell has already been configured with.

``` swift
public final class _ChatMessageCollectionViewCell<ExtraData: ExtraDataTypes>: _CollectionViewCell 
```

## Inheritance

[`_CollectionViewCell`](../../common-views/_collection-view-cell.md)

## Properties

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
```
