
### `container`

The main container of the composer that layouts all the other containers around the message input view.

``` swift
public private(set) lazy var container = ContainerStackView()
        .withoutAutoresizingMaskConstraints
```

### `headerView`

The header view that displays components above the message input view.

``` swift
public private(set) lazy var headerView = UIView()
        .withoutAutoresizingMaskConstraints
```

### `bottomContainer`

The container that displays the components below the message input view.

``` swift
public private(set) lazy var bottomContainer = ContainerStackView()
        .withoutAutoresizingMaskConstraints
```

### `centerContainer`

The container that layouts the message input view and the leading/trailing containers around it.

``` swift
public private(set) lazy var centerContainer = ContainerStackView()
        .withoutAutoresizingMaskConstraints
```

### `leadingContainer`

The container that displays the components in the leading side of the message input view.

``` swift
public private(set) lazy var leadingContainer = ContainerStackView()
        .withoutAutoresizingMaskConstraints
```

### `trailingContainer`

The container that displays the components in the trailing side of the message input view.

``` swift
public private(set) lazy var trailingContainer = ContainerStackView()
        .withoutAutoresizingMaskConstraints
```

### `inputMessageView`

A view to to input content of the new message.

``` swift
public private(set) lazy var inputMessageView: _InputChatMessageView<ExtraData> = components
        .inputMessageView.init()
        .withoutAutoresizingMaskConstraints
```

### `sendButton`

A button to send the message.

``` swift
public private(set) lazy var sendButton: UIButton = components
        .sendButton.init()
        .withoutAutoresizingMaskConstraints
```

### `confirmButton`

A button to confirm when editing a message.

``` swift
public private(set) lazy var confirmButton: UIButton = components
        .confirmButton.init()
        .withoutAutoresizingMaskConstraints
```

### `attachmentButton`

A button to open the user attachments.

``` swift
public private(set) lazy var attachmentButton: UIButton = components
        .attachmentButton.init()
        .withoutAutoresizingMaskConstraints
```

### `commandsButton`

A button to open the available commands.

``` swift
public private(set) lazy var commandsButton: UIButton = components
        .commandsButton.init()
        .withoutAutoresizingMaskConstraints
```

### `shrinkInputButton`

A Button for shrinking the input view to allow more space for other actions.

``` swift
public private(set) lazy var shrinkInputButton: UIButton = components
        .shrinkInputButton.init()
        .withoutAutoresizingMaskConstraints
```

### `dismissButton`

A button to dismiss the current state (quoting, editing, etc..).

``` swift
public private(set) lazy var dismissButton: UIButton = components
        .closeButton.init()
        .withoutAutoresizingMaskConstraints
```

### `titleLabel`

A label part of the header view to display the current state (quoting, editing, etc..).

``` swift
public private(set) lazy var titleLabel: UILabel = UILabel()
        .withoutAutoresizingMaskConstraints
        .withBidirectionalLanguagesSupport
        .withAdjustingFontForContentSizeCategory
```

### `checkboxControl`

A checkbox to check/uncheck if the message should also
be sent to the channel while replying in a thread.

``` swift
public private(set) lazy var checkboxControl: CheckboxControl = components
        .checkmarkControl.init()
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
