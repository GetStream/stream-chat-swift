---
title: GalleryVC.Content
---

The content of gallery view controller.

``` swift
public struct Content 
```

## Initializers

### `init(message:currentPage:)`

``` swift
public init(
            message: _ChatMessage<ExtraData>,
            currentPage: Int = 0
        ) 
```

## Properties

### `message`

The message which attachments are displayed by the gallery.

``` swift
public var message: _ChatMessage<ExtraData>
```

### `currentPage`

The index of currently visible gallery item.

``` swift
public var currentPage: Int
```
