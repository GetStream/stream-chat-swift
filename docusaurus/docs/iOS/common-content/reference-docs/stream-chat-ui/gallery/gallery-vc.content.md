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
            message: ChatMessage,
            currentPage: Int = 0
        ) 
```

## Properties

### `message`

The message which attachments are displayed by the gallery.

``` swift
public var message: ChatMessage
```

### `currentPage`

The index of currently visible gallery item.

``` swift
public var currentPage: Int
```
