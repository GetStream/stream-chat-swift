---
id: quotedchatmessageview 
title: QuotedChatMessageView
--- 

A view that displays a quoted message.

``` swift
open class _QuotedChatMessageView<ExtraData: ExtraDataTypes>: _View, ThemeProvider, SwiftUIRepresentable 
```

## Inheritance

[`_View`](../_View), [`SwiftUIRepresentable`](../SwiftUIRepresentable), [`ThemeProvider`](../../Utils/ThemeProvider)

## Nested Type Aliases

### `ObservedObject`

Data source of `QuotedChatMessageView` represented as `ObservedObject`.

``` swift
public typealias ObservedObject<Content: SwiftUIView> = SwiftUIWrapper<Content> where Content.ExtraData == ExtraData
```

### `SwiftUIView`

`QuotedChatMessageView` represented in SwiftUI.

``` swift
public typealias SwiftUIView = _QuotedChatMessageViewSwiftUIView
```

## Properties

### `content`

The content of this view, composed by the quoted message and the desired avatar alignment.

``` swift
public var content: Content? 
```

### `isAttachmentsEmpty`

A Boolean value that checks if all attachments are empty.

``` swift
open var isAttachmentsEmpty: Bool 
```

### `containerView`

The container view that holds the `authorAvatarView` and the `contentContainerView`.

``` swift
open private(set) lazy var containerView: ContainerStackView = ContainerStackView()
        .withoutAutoresizingMaskConstraints
```

### `authorAvatarView`

The avatar view of the author's quoted message.

``` swift
open private(set) lazy var authorAvatarView: ChatAvatarView = components
        .avatarView.init()
        .withoutAutoresizingMaskConstraints
```

### `contentContainerView`

The container view that holds the `textView` and the `attachmentPreview`.

``` swift
open private(set) lazy var contentContainerView: ContainerStackView = ContainerStackView()
        .withoutAutoresizingMaskConstraints
```

### `textView`

The `UITextView` that contains quoted message content.

``` swift
open private(set) lazy var textView: UITextView = UITextView()
        .withoutAutoresizingMaskConstraints
```

### `attachmentPreviewView`

The attachments preview view if the quoted message has attachments.
The default logic is that the first attachment is displayed on the preview view.

``` swift
open private(set) lazy var attachmentPreviewView: UIImageView = UIImageView()
        .withoutAutoresizingMaskConstraints
```

### `authorAvatarSize`

The size of the avatar view that belongs to the author of the quoted message.

``` swift
open var authorAvatarSize: CGSize 
```

### `attachmentPreviewSize`

The size of the attachments preview.s

``` swift
open var attachmentPreviewSize: CGSize 
```

## Methods

### `setUp()`

``` swift
override open func setUp() 
```

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

### `setAvatar(imageUrl:)`

Sets the avatar image from a url or sets the placeholder image if the url is `nil`.

``` swift
open func setAvatar(imageUrl: URL?) 
```

#### Parameters

  - imageUrl: The url of the image.

### `setAvatarAlignment(_:)`

Sets the avatar position in relation of the text bubble.

``` swift
open func setAvatarAlignment(_ alignment: QuotedAvatarAlignment) 
```

#### Parameters

  - alignment: The avatar alignment of the author of the quoted message.

### `setAttachmentPreview(for:)`

Sets the attachment content to the preview view.
Override this function if you want to provide custom logic to present
the attachments preview of the message, or if you want to support your custom attachment.

``` swift
open func setAttachmentPreview(for message: _ChatMessage<ExtraData>) 
```

#### Parameters

  - message: The message that contains all the attachments.

### `showAttachmentPreview()`

Show the attachment preview view.

``` swift
open func showAttachmentPreview() 
```

### `hideAttachmentPreview()`

Hide the attachment preview view.

``` swift
open func hideAttachmentPreview() 
```
