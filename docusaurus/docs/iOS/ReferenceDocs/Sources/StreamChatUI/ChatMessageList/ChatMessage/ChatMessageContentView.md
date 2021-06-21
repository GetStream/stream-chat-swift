---
id: chatmessagecontentview 
title: ChatMessageContentView
--- 

A view that displays the message content.

``` swift
open class _ChatMessageContentView<ExtraData: ExtraDataTypes>: _View, ThemeProvider 
```

## Inheritance

[`_View`](../../CommonViews/_View), [`ThemeProvider`](../../Utils/ThemeProvider)

## Nested Type Aliases

### `ObservedObject`

Data source of `_ChatMessageContentView` represented as `ObservedObject`.

``` swift
public typealias ObservedObject<Content: SwiftUIView> = SwiftUIWrapper<Content> where Content.ExtraData == ExtraData
```

### `SwiftUIView`

`_ChatMessageContentView` represented in SwiftUI.

``` swift
public typealias SwiftUIView = _ChatMessageContentViewSwiftUIView
```

## Properties

### `indexPath`

The provider of cell index path which displays the current content view.

``` swift
public var indexPath: (() -> IndexPath?)?
```

### `delegate`

The delegate responsible for action handling.

``` swift
public weak var delegate: ChatMessageContentViewDelegate?
```

### `content`

The message this view displays.

``` swift
open var content: _ChatMessage<ExtraData>? 
```

### `dateFormatter`

The date formatter of the `timestampLabel`

``` swift
public lazy var dateFormatter: DateFormatter 
```

### `maxContentWidthMultiplier`

Specifies the max possible width of `mainContainer`.
Should be in \[0...1\] range, where 1 makes the container fill the entire superview's width.

``` swift
open var maxContentWidthMultiplier: CGFloat 
```

### `messageAuthorAvatarSize`

Specifies the size of `authorAvatarView`. In case `.avatarSizePadding` option is set the leading offset
for the content will taken from the provided `width`.

``` swift
open var messageAuthorAvatarSize: CGSize 
```

### `bubbleView`

Shows the bubble around message content.
Exists if `layout(options:​ MessageLayoutOptions)` was invoked with the options containing `.bubble`.

``` swift
public private(set) var bubbleView: _ChatMessageBubbleView<ExtraData>?
```

### `authorAvatarView`

Shows message author avatar.
Exists if `layout(options:​ MessageLayoutOptions)` was invoked with the options containing `.author`.

``` swift
public private(set) var authorAvatarView: ChatAvatarView?
```

### `authorAvatarSpacer`

Shows a spacer where the author avatar should be.
Exists if `layout(options:​ MessageLayoutOptions)` was invoked with the options containing `.avatarSizePadding`.

``` swift
public private(set) var authorAvatarSpacer: UIView?
```

### `textView`

Shows message text content.
Exists if `layout(options:​ MessageLayoutOptions)` was invoked with the options containing `.text`.

``` swift
public private(set) var textView: UITextView?
```

### `timestampLabel`

Shows message timestamp.
Exists if `layout(options:​ MessageLayoutOptions)` was invoked with the options containing `.timestamp`.

``` swift
public private(set) var timestampLabel: UILabel?
```

### `authorNameLabel`

Shows message author name.
Exists if `layout(options:​ MessageLayoutOptions)` was invoked with the options containing `.authorName`.

``` swift
public private(set) var authorNameLabel: UILabel?
```

### `onlyVisibleForYouIconImageView`

Shows the icon part of the indicator saying the message is visible for current user only.
Exists if `layout(options:​ MessageLayoutOptions)` was invoked with the options
containing `.onlyVisibleForYouIndicator`.

``` swift
public private(set) var onlyVisibleForYouIconImageView: UIImageView?
```

### `onlyVisibleForYouLabel`

Shows the text part of the indicator saying the message is visible for current user only.
Exists if `layout(options:​ MessageLayoutOptions)` was invoked with the options
containing `.onlyVisibleForYouIndicator`

``` swift
public private(set) var onlyVisibleForYouLabel: UILabel?
```

### `errorIndicatorView`

Shows error indicator.
Exists if `layout(options:​ MessageLayoutOptions)` was invoked with the options containing `.errorIndicator`.

``` swift
public private(set) var errorIndicatorView: ChatMessageErrorIndicator?
```

### `quotedMessageView`

Shows the message quoted by the message this view displays.
Exists if `layout(options:​ MessageLayoutOptions)` was invoked with the options containing `.quotedMessage`.

``` swift
public private(set) var quotedMessageView: _QuotedChatMessageView<ExtraData>?
```

### `reactionsView`

Shows message reactions.
Exists if `layout(options:​ MessageLayoutOptions)` was invoked with the options containing `.reactions`.

``` swift
public private(set) var reactionsView: _ChatMessageReactionsView<ExtraData>?
```

### `reactionsBubbleView`

Shows the bubble around message reactions.
Exists if `layout(options:​ MessageLayoutOptions)` was invoked with the options containing `.reactions`.

``` swift
public private(set) var reactionsBubbleView: ChatReactionsBubbleView?
```

### `threadReplyCountButton`

Shows the \# of thread replies on the message.
Exists if `layout(options:​ MessageLayoutOptions)` was invoked with the options containing `.threadInfo`.

``` swift
public private(set) var threadReplyCountButton: UIButton?
```

### `threadAvatarView`

Shows the avatar of the user who left the latest thread reply.
Exists if `layout(options:​ MessageLayoutOptions)` was invoked with the options containing `.threadInfo`.

``` swift
public private(set) var threadAvatarView: ChatAvatarView?
```

### `threadArrowView`

Shows the arrow from message bubble to `threadAvatarView` view.
Exists if `layout(options:​ MessageLayoutOptions)` was invoked with the options containing `.threadInfo`.

``` swift
public private(set) var threadArrowView: ChatThreadArrowView?
```

### `attachmentViewInjector`

An object responsible for injecting the views needed to display the attachments content.

``` swift
public private(set) var attachmentViewInjector: _AttachmentViewInjector<ExtraData>?
```

### `mainContainer`

The root container which holds `authorAvatarView` (or the avatar padding) and `bubbleThreadMetaContainer`.

``` swift
public lazy var mainContainer = ContainerStackView(axis: .horizontal)
        .withoutAutoresizingMaskConstraints
```

### `bubbleThreadMetaContainer`

The container which holds `bubbleView` (or `bubbleContentContainer` directly), `threadInfoContainer`, and `metadataView`

``` swift
public private(set) lazy var bubbleThreadMetaContainer = ContainerStackView(axis: .vertical, spacing: 4)
        .withoutAutoresizingMaskConstraints
```

### `bubbleContentContainer`

The container which holds `quotedMessageView` and `textView`. It will be added as a subview to `bubbleView` if it exists
otherwise it will be added to `bubbleThreadMetaContainer`.

``` swift
public private(set) lazy var bubbleContentContainer = ContainerStackView(axis: .vertical)
        .withoutAutoresizingMaskConstraints
```

### `threadInfoContainer`

The container which holds `threadArrowView`, `threadAvatarView`, and `threadReplyCountButton`

``` swift
public private(set) var threadInfoContainer: ContainerStackView?
```

### `metadataContainer`

The container which holds `timestampLabel`, `authorNameLabel`, and `onlyVisibleForYouContainer`.
Exists if `layout(options:​ MessageLayoutOptions)` was invoked with any of
`.timestamp/.authorName/.onlyVisibleForYouIndicator` options

``` swift
public private(set) var metadataContainer: ContainerStackView?
```

### `onlyVisibleForYouContainer`

The container which holds `onlyVisibleForYouIconImageView` and `onlyVisibleForYouLabel`

``` swift
public private(set) var onlyVisibleForYouContainer: ContainerStackView?
```

### `errorIndicatorContainer`

The container which holds `errorIndicatorView`
Exists if `layout(options:​ MessageLayoutOptions)` was invoked with the options containing `.errorIndicator`.

``` swift
public private(set) var errorIndicatorContainer: UIView?
```

### `bubbleToReactionsConstraint`

Constraint between bubble and reactions.

``` swift
public private(set) var bubbleToReactionsConstraint: NSLayoutConstraint?
```

## Methods

### `setUpLayoutIfNeeded(options:attachmentViewInjectorType:)`

Makes sure the `layout(options:​ ChatMessageLayoutOptions)` is called just once.

``` swift
open func setUpLayoutIfNeeded(
        options: ChatMessageLayoutOptions,
        attachmentViewInjectorType: _AttachmentViewInjector<ExtraData>.Type?
    ) 
```

#### Parameters

  - options: The options describing the layout of the content view.

### `layout(options:)`

Instantiates the subviews and laid them out based on the received options.

``` swift
open func layout(options: ChatMessageLayoutOptions) 
```

#### Parameters

  - options: The options describing the layout of the content view.

### `updateContent()`

``` swift
override open func updateContent() 
```

### `tintColorDidChange()`

``` swift
override open func tintColorDidChange() 
```

### `handleTapOnErrorIndicator()`

Handles tap on `errorIndicatorView` and forwards the action to the delegate.

``` swift
@objc open func handleTapOnErrorIndicator() 
```

### `handleTapOnThread()`

Handles tap on `threadReplyCountButton` and forwards the action to the delegate.

``` swift
@objc open func handleTapOnThread() 
```

### `handleTapOnQuotedMessage()`

Handles tap on `quotedMessageView` and forwards the action to the delegate.

``` swift
@objc open func handleTapOnQuotedMessage() 
```

### `createTextView()`

Instantiates, configures and assigns `textView` when called for the first time.

``` swift
open func createTextView() -> UITextView 
```

#### Returns

The `textView` subview.

### `createAvatarView()`

Instantiates, configures and assigns `authorAvatarView` when called for the first time.

``` swift
open func createAvatarView() -> ChatAvatarView 
```

#### Returns

The `authorAvatarView` subview.

### `createAvatarSpacer()`

Instantiates, configures and assigns `createAvatarSpacer` when called for the first time.

``` swift
open func createAvatarSpacer() -> UIView 
```

#### Returns

The `authorAvatarSpacer` subview.

### `createThreadAvatarView()`

Instantiates, configures and assigns `threadAvatarView` when called for the first time.

``` swift
open func createThreadAvatarView() -> ChatAvatarView 
```

#### Returns

The `threadAvatarView` subview.

### `createThreadArrowView()`

Instantiates, configures and assigns `threadArrowView` when called for the first time.

``` swift
open func createThreadArrowView() -> ChatThreadArrowView 
```

#### Returns

The `threadArrowView` subview.

### `createThreadReplyCountButton()`

Instantiates, configures and assigns `threadReplyCountButton` when called for the first time.

``` swift
open func createThreadReplyCountButton() -> UIButton 
```

#### Returns

The `threadReplyCountButton` subview.

### `createBubbleView()`

Instantiates, configures and assigns `bubbleView` when called for the first time.

``` swift
open func createBubbleView() -> _ChatMessageBubbleView<ExtraData> 
```

#### Returns

The `bubbleView` subview.

### `createQuotedMessageView()`

Instantiates, configures and assigns `quotedMessageView` when called for the first time.

``` swift
open func createQuotedMessageView() -> _QuotedChatMessageView<ExtraData> 
```

#### Returns

The `quotedMessageView` subview.

### `createReactionsView()`

Instantiates, configures and assigns `reactionsView` when called for the first time.

``` swift
open func createReactionsView() -> _ChatMessageReactionsView<ExtraData> 
```

#### Returns

The `reactionsView` subview.

### `createErrorIndicatorView()`

Instantiates, configures and assigns `errorIndicatorView` when called for the first time.

``` swift
open func createErrorIndicatorView() -> ChatMessageErrorIndicator 
```

#### Returns

The `errorIndicatorView` subview.

### `createErrorIndicatorContainer()`

Instantiates, configures and assigns `errorIndicatorContainer` when called for the first time.

``` swift
open func createErrorIndicatorContainer() -> UIView 
```

#### Returns

The `errorIndicatorContainer` subview.

### `createReactionsBubbleView()`

Instantiates, configures and assigns `reactionsBubbleView` when called for the first time.

``` swift
open func createReactionsBubbleView() -> ChatReactionsBubbleView 
```

#### Returns

The `reactionsBubbleView` subview.

### `createTimestampLabel()`

Instantiates, configures and assigns `timestampLabel` when called for the first time.

``` swift
open func createTimestampLabel() -> UILabel 
```

#### Returns

The `timestampLabel` subview.

### `createAuthorNameLabel()`

Instantiates, configures and assigns `authorNameLabel` when called for the first time.

``` swift
open func createAuthorNameLabel() -> UILabel 
```

#### Returns

The `authorNameLabel` subview.

### `createOnlyVisibleForYouIconImageView()`

Instantiates, configures and assigns `onlyVisibleForYouIconImageView` when called for the first time.

``` swift
open func createOnlyVisibleForYouIconImageView() -> UIImageView 
```

#### Returns

The `onlyVisibleForYouIconImageView` subview.

### `createOnlyVisibleForYouLabel()`

Instantiates, configures and assigns `onlyVisibleForYouLabel` when called for the first time.

``` swift
open func createOnlyVisibleForYouLabel() -> UILabel 
```

#### Returns

The `onlyVisibleForYouLabel` subview.
