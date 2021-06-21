---
id: attachmentspreviewvc 
title: AttachmentsPreviewVC
--- 

``` swift
open class _AttachmentsPreviewVC<ExtraData: ExtraDataTypes>: _ViewController, ComponentsProvider 
```

## Inheritance

[`_ViewController`](../_ViewController), [`ComponentsProvider`](../../Utils/ComponentsProvider)

## Properties

### `content`

``` swift
open var content: [AttachmentPreviewProvider] = [] 
```

### `didTapRemoveItemButton`

The closure handler when an attachment has been removed.

``` swift
open var didTapRemoveItemButton: ((Int) -> Void)?
```

### `selectedAttachmentType`

``` swift
open var selectedAttachmentType: AttachmentType?
```

### `scrollViewHeightConstraint`

``` swift
public private(set) var scrollViewHeightConstraint: NSLayoutConstraint?
```

### `horizontalConstraints`

``` swift
open private(set) var horizontalConstraints: [NSLayoutConstraint] = []
```

### `verticalConstraints`

``` swift
open private(set) var verticalConstraints: [NSLayoutConstraint] = []
```

### `scrollView`

``` swift
open private(set) lazy var scrollView: UIScrollView = UIScrollView()
        .withoutAutoresizingMaskConstraints
```

### `horizontalStackView`

``` swift
open private(set) lazy var horizontalStackView: ContainerStackView = ContainerStackView(axis: .horizontal, spacing: 8)
        .withoutAutoresizingMaskConstraints
```

### `verticalStackView`

``` swift
open private(set) lazy var verticalStackView: ContainerStackView = ContainerStackView(axis: .vertical, spacing: 8)
        .withoutAutoresizingMaskConstraints
```

### `attachmentViews`

``` swift
open var attachmentViews: [UIView] 
```

### `stackViewAxis`

``` swift
open var stackViewAxis: NSLayoutConstraint.Axis 
```

## Methods

### `setUpAppearance()`

``` swift
override open func setUpAppearance() 
```

### `setUpLayout()`

``` swift
override open func setUpLayout() 
```

### `updateContent()`

``` swift
override open func updateContent() 
```

### `setupHorizontalStackView()`

``` swift
open func setupHorizontalStackView() 
```

### `setupVerticalStackView()`

``` swift
open func setupVerticalStackView() 
```
