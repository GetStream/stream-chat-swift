---
title: LinkAttachmentViewInjector
---

View injector for showing link attachments.

``` swift
@available(iOSApplicationExtension, unavailable)
open class LinkAttachmentViewInjector: AttachmentViewInjector 
```

## Inheritance

[`AttachmentViewInjector`](../attachment-view-injector)

## Properties

### `linkPreviewView`

``` swift
open private(set) lazy var linkPreviewView = contentView
        .components
        .linkPreviewView
        .init()
        .withoutAutoresizingMaskConstraints
```

## Methods

### `contentViewDidLayout(options:)`

``` swift
override open func contentViewDidLayout(options: ChatMessageLayoutOptions) 
```

### `contentViewDidUpdateContent()`

``` swift
override open func contentViewDidUpdateContent() 
```

### `handleTapOnAttachment()`

Triggered when `attachment` is tapped.

``` swift
@objc
    open func handleTapOnAttachment() 
```
