---
title: ChatMessageCell
---

The cell that displays the message content of a dynamic type and layout.
Once the cell is set up it is expected to be de-queued for messages with
the same content and layout the cell has already been configured with.

``` swift
public final class ChatMessageCell: _TableViewCell 
```

## Inheritance

[`_TableViewCell`](../../../common-views/table-view-cell)

## Properties

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

  - `contentViewClass`: The type of message content view.
  - `attachmentViewInjectorType`: The type of attachment injector.
  - `options`: The layout options describing the message content view layout.
