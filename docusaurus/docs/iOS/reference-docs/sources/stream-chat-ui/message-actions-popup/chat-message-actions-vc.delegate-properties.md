
### `didTapOnActionItem`

Triggered when action item was tapped.
You can decide what to do with message based on which instance of `ChatMessageActionItem` you received.

``` swift
public var didTapOnActionItem: (_ChatMessageActionsVC, _ChatMessage<ExtraData>, ChatMessageActionItem) -> Void
```

### `didFinish`

Triggered when `_ChatMessageActionsVC` should be dismissed.

``` swift
public var didFinish: (_ChatMessageActionsVC) -> Void
