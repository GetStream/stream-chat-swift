---
id: defaultattachmentpreviewprovider 
title: DefaultAttachmentPreviewProvider
--- 

Default provider that is used when AttachmentPreviewProvider is not implemented for custom attachment payload. This
provider always returns a new instance of `AttachmentPlaceholderView`.

``` swift
public struct DefaultAttachmentPreviewProvider: AttachmentPreviewProvider 
```

## Inheritance

[`AttachmentPreviewProvider`](AttachmentPreviewProvider)

## Properties

### `preferredAxis`

``` swift
public static var preferredAxis: NSLayoutConstraint.Axis 
```

## Methods

### `previewView(components:)`

``` swift
public func previewView<ExtraData: ExtraDataTypes>(components: _Components<ExtraData>) -> UIView 
```
