---
id: linkattachmentviewinjector 
title: LinkAttachmentViewInjector
--- 

View injector for showing link attachments.

``` swift
open class _LinkAttachmentViewInjector<ExtraData: ExtraDataTypes>: _AttachmentViewInjector<ExtraData> 
```

## Inheritance

`_AttachmentViewInjector<ExtraData>`

## Properties

### `linkPreviewView`

``` swift
open private(set) lazy var linkPreviewView = _ChatMessageLinkPreviewView<ExtraData>()
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
