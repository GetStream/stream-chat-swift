---
title: AttachmentPreviewProvider
---

``` swift
public protocol AttachmentPreviewProvider 
```

## Requirements

### previewView(components:​)

The view representing the attachment.

``` swift
func previewView<ExtraData: ExtraDataTypes>(components: _Components<ExtraData>) -> UIView
```

### preferredAxis

The preferred axis to be used for attachment previews in attachments view.

``` swift
static var preferredAxis: NSLayoutConstraint.Axis 
```
