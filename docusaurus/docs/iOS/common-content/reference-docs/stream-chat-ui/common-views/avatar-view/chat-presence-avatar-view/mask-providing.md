---
title: MaskProviding
---

Protocol used to get path to make a cutout in a parent view.

``` swift
public protocol MaskProviding 
```

This protocol is used to make a transparent "border" around online indicator in avatar view.

## Requirements

### maskingPath

Path used to mask space in super view.

``` swift
var maskingPath: CGPath? 
```

No mask is used when nil is returned
