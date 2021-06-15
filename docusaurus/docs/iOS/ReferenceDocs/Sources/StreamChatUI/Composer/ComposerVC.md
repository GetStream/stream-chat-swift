
A view controller that manages the composer view.

``` swift
open class _ComposerVC<ExtraData: ExtraDataTypes>: _ViewController,
    ThemeProvider,
    UITextViewDelegate,
    UIImagePickerControllerDelegate,
    UIDocumentPickerDelegate,
    UINavigationControllerDelegate 
```

## Inheritance

[`_ViewController`](../CommonViews/_ViewController), [`ThemeProvider`](../Utils/ThemeProvider), `UIDocumentPickerDelegate`, `UIImagePickerControllerDelegate`, `UINavigationControllerDelegate`, `UITextViewDelegate`

## Properties

### `content`

The content of the composer.

``` swift
public var content: Content 
```

### `delegate`

The delegate of the ComposerVC that notifies composer events.

``` swift
open weak var delegate: ComposerVCDelegate?
```

### `mentionSymbol`

A symbol that is used to recognise when the user is mentioning a user.

``` swift
open var mentionSymbol = "@"
```

### `commandSymbol`

A symbol that is used to recognise when the user is typing a command.

``` swift
open var commandSymbol = "/"
```

### `userSearchController`

A controller to search users and that is used to populate the mention suggestions.

``` swift
open var userSearchController: _ChatUserSearchController<ExtraData>!
```

### `channelController`

A controller that manages the channel that the composer is creating content for.

``` swift
open var channelController: _ChatChannelController<ExtraData>?
```

### `channelConfig`

The channel config. If it's a new channel, an empty config should be created. (Not yet supported right now)

``` swift
public var channelConfig: ChannelConfig? 
```

### `composerView`

The view of the composer.

``` swift
open private(set) lazy var composerView: _ComposerView<ExtraData> = components
        .messageComposerView.init()
        .withoutAutoresizingMaskConstraints
```

### `suggestionsVC`

The view controller that shows the suggestions when the user is typing.

``` swift
open private(set) lazy var suggestionsVC: _ChatSuggestionsViewController<ExtraData> 
```

### `attachmentsVC`

The view controller that shows the suggestions when the user is typing.

``` swift
open private(set) lazy var attachmentsVC: _AttachmentsPreviewVC<ExtraData> 
```

### `imagePickerVC`

The view controller for selecting image attachments.

``` swift
open private(set) lazy var imagePickerVC: UIViewController 
```

### `filePickerVC`

The view controller for selecting file attachments.

``` swift
open private(set) lazy var filePickerVC: UIViewController 
```

### `selectedAttachmentType`

``` swift
open var selectedAttachmentType: AttachmentType?
```

## Methods

### `setDelegate(_:)`

``` swift
public func setDelegate(_ delegate: ComposerVCDelegate) 
```

### `setUp()`

``` swift
override open func setUp() 
```

### `setUpLayout()`

``` swift
override open func setUpLayout() 
```

### `viewDidDisappear(_:)`

``` swift
override open func viewDidDisappear(_ animated: Bool) 
```

### `updateContent()`

``` swift
override open func updateContent() 
```

### `setupAttachmentsView()`

``` swift
open func setupAttachmentsView() 
```

### `publishMessage(sender:)`

``` swift
@objc open func publishMessage(sender: UIButton) 
```

### `showAttachmentsPicker(sender:)`

``` swift
@objc open func showAttachmentsPicker(sender: UIButton) 
```

### `shrinkInput(sender:)`

``` swift
@objc open func shrinkInput(sender: UIButton) 
```

### `showAvailableCommands(sender:)`

``` swift
@objc open func showAvailableCommands(sender: UIButton) 
```

### `clearContent(sender:)`

``` swift
@objc open func clearContent(sender: UIButton) 
```

### `createNewMessage(text:)`

Creates a new message and notifies the delegate that a new message was created.

``` swift
open func createNewMessage(text: String) 
```

#### Parameters

  - text: The text content of the message.

### `editMessage(withId:newText:)`

Updates an existing message.

``` swift
open func editMessage(withId id: MessageId, newText: String) 
```

#### Parameters

  - id: The id of the editing message.
  - newText: The new text content of the message.

### `typingMention(in:)`

Returns a potential user mention in case the user is currently typing a username.

``` swift
open func typingMention(in textView: UITextView) -> (String, NSRange)? 
```

#### Parameters

  - textView: The text view of the message input view where the user is typing.

#### Returns

A tuple with the potential user mention and the position of the mention so it can be autocompleted.

### `typingCommand(in:)`

Returns a potential command in case the user is currently typing a command.

``` swift
open func typingCommand(in textView: UITextView) -> String? 
```

#### Parameters

  - textView: The text view of the message input view where the user is typing.

#### Returns

A string of the corresponding potential command.

### `showCommandSuggestions(for:)`

Shows the command suggestions for the potential command the current user is typing.

``` swift
open func showCommandSuggestions(for typingCommand: String) 
```

#### Parameters

  - typingCommand: The potential command that the current user is typing.

### `showMentionSuggestions(for:mentionRange:)`

Shows the mention suggestions for the potential mention the current user is typing.

``` swift
open func showMentionSuggestions(for typingMention: String, mentionRange: NSRange) 
```

#### Parameters

  - typingMention: The potential user mention the current user is typing.
  - mentionRange: The position where the current user is typing a mention to it can be replaced with the suggestion.

### `showSuggestions()`

Shows the suggestions view

``` swift
open func showSuggestions() 
```

### `dismissSuggestions()`

Dismisses the suggestions view.

``` swift
open func dismissSuggestions() 
```

### `textViewDidChange(_:)`

``` swift
open func textViewDidChange(_ textView: UITextView) 
```

### `imagePickerController(_:didFinishPickingMediaWithInfo:)`

``` swift
open func imagePickerController(
        _ picker: UIImagePickerController,
        didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]
    ) 
```

### `documentPicker(_:didPickDocumentsAt:)`

``` swift
open func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) 
```
