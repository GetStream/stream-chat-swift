
The delegate used `GiphyAttachmentViewInjector` to communicate user interactions.

``` swift
public protocol GiphyActionContentViewDelegate: ChatMessageContentViewDelegate 
```

## Inheritance

[`ChatMessageContentViewDelegate`](../ChatMessage/ChatMessageContentViewDelegate)

## Requirements

### didTapOnAttachmentAction(\_:​at:​)

Called when the user taps on attachment action

``` swift
func didTapOnAttachmentAction(_ action: AttachmentAction, at indexPath: IndexPath)
```
