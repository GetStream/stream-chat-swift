---
title: InputChatMessageView
---

A view to input content of a message.

``` swift
open class _InputChatMessageView<ExtraData: ExtraDataTypes>: _View, ComponentsProvider, AppearanceProvider 
```

## Inheritance

[`_View`](../_view), [`AppearanceProvider`](../../utils/appearance-provider), [`ComponentsProvider`](../../utils/components-provider)

## Properties

### `content`

The content of the view

``` swift
public var content: Content? 
```

### `container`

The main container stack view that layouts all the message input content views.

``` swift
public private(set) lazy var container = ContainerStackView()
        .withoutAutoresizingMaskConstraints
```

### `quotedMessageView`

A view that displays the quoted message that the new message is replying.

``` swift
public private(set) lazy var quotedMessageView = components
        .quotedMessageView.init()
        .withoutAutoresizingMaskConstraints
```

### `attachmentsViewContainer`

A view that displays the attachments of the new message.
This is view from separate AttachmentsVC and will be injected by the ComposerVC.

``` swift
public private(set) lazy var attachmentsViewContainer = UIView()
        .withoutAutoresizingMaskConstraints
```

### `inputTextContainer`

The container stack view that layouts the command label, text view and the clean button.

``` swift
public private(set) lazy var inputTextContainer = ContainerStackView()
        .withoutAutoresizingMaskConstraints
```

### `textView`

The input text view to type a new message or command.

``` swift
public private(set) lazy var textView: InputTextView = components
        .inputTextView.init()
        .withoutAutoresizingMaskConstraints
```

### `commandLabelView`

The command label that display the command info if a new command is being typed.

``` swift
public private(set) lazy var commandLabelView: CommandLabelView = components
        .commandLabelView.init()
        .withoutAutoresizingMaskConstraints
```

### `clearButton`

A button to clear the current typing information.

``` swift
public private(set) lazy var clearButton: UIButton = components
        .closeButton.init()
        .withoutAutoresizingMaskConstraints
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
