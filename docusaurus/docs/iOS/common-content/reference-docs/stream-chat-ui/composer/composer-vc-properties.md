
### `content`

The content of the composer.

``` swift
public var content: Content 
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

### `isCommandsEnabled`

A Boolean value indicating whether the commands are enabled.

``` swift
open var isCommandsEnabled: Bool 
```

### `isMentionsEnabled`

A Boolean value indicating whether the user mentions are enabled.

``` swift
open var isMentionsEnabled: Bool 
```

### `isAttachmentsEnabled`

A Boolean value indicating whether the attachments are enabled.

``` swift
open var isAttachmentsEnabled: Bool 
```

### `mentionAllAppUsers`

When enabled mentions search users across the entire app instead of searching

``` swift
open private(set) lazy var mentionAllAppUsers: Bool = components.mentionAllAppUsers
```

### `userSearchController`

A controller to search users and that is used to populate the mention suggestions.

``` swift
open var userSearchController: ChatUserSearchController!
```

### `channelController`

A controller that manages the channel that the composer is creating content for.

``` swift
open var channelController: ChatChannelController?
```

### `channelConfig`

The channel config. If it's a new channel, an empty config should be created. (Not yet supported right now)

``` swift
public var channelConfig: ChannelConfig? 
```

### `mentionSuggester`

The component responsible for mention suggestions.

``` swift
open lazy var mentionSuggester 
```

### `commandSuggester`

The component responsible for autocomplete command suggestions.

``` swift
open lazy var commandSuggester 
```

### `composerView`

The view of the composer.

``` swift
open private(set) lazy var composerView: ComposerView = components
        .messageComposerView.init()
        .withoutAutoresizingMaskConstraints
```

### `suggestionsVC`

The view controller that shows the suggestions when the user is typing.

``` swift
open private(set) lazy var suggestionsVC: ChatSuggestionsVC 
```

### `attachmentsVC`

The view controller that shows the suggestions when the user is typing.

``` swift
open private(set) lazy var attachmentsVC: AttachmentsPreviewVC 
```

### `mediaPickerVC`

The view controller for selecting image attachments.

``` swift
open private(set) lazy var mediaPickerVC: UIViewController 
```

### `filePickerVC`

The view controller for selecting file attachments.

``` swift
open private(set) lazy var filePickerVC: UIViewController 
```

### `attachmentsPickerActions`

Returns actions for attachments picker.

``` swift
open var attachmentsPickerActions: [UIAlertAction] 
```

## Methods

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

### `showMediaPicker()`

Shows a photo/media picker.

``` swift
open func showMediaPicker() 
```

### `showFilePicker()`

Shows a document picker.

``` swift
open func showFilePicker() 
```

### `showAttachmentsPicker(sender:)`

Action that handles tap on attachments button in composer.

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

### `queryForMentionSuggestionsSearch(typingMention:)`

Returns the query to be used for searching users for the given typing mention.

``` swift
open func queryForMentionSuggestionsSearch(typingMention term: String) -> UserListQuery 
```

This function is called in `showMentionSuggestions` to retrieve the query
that will be used to search the users. You should override this if you want to change the
user searching logic.

#### Parameters

  - typingMention: The potential user mention the current user is typing.

#### Returns

`_UserListQuery` instance that will be used for searching users.

### `showMentionSuggestions(for:mentionRange:)`

Shows the mention suggestions for the potential mention the current user is typing.

``` swift
open func showMentionSuggestions(for typingMention: String, mentionRange: NSRange) 
```

#### Parameters

  - typingMention: The potential user mention the current user is typing.
  - mentionRange: The position where the current user is typing a mention to it can be replaced with the suggestion.

### `mentionText(for:)`

Provides the mention text for composer text field, when the user selects a mention suggestion.

``` swift
open func mentionText(for user: ChatUser) -> String 
```

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

### `addAttachmentToContent(from:type:)`

Creates and adds an attachment from the given URL to the `content`

``` swift
open func addAttachmentToContent(from url: URL, type: AttachmentType) throws 
```

#### Parameters

  - url: The URL of the attachment
  - type: The type of the attachment

### `textViewDidChange(_:)`

``` swift
open func textViewDidChange(_ textView: UITextView) 
```

### `textView(_:shouldChangeTextIn:replacementText:)`

``` swift
open func textView(
        _ textView: UITextView,
        shouldChangeTextIn range: NSRange,
        replacementText text: String
    ) -> Bool 
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

### `showAttachmentExceedsMaxSizeAlert()`

``` swift
open func showAttachmentExceedsMaxSizeAlert() 
```

### `inputTextView(_:didPasteImage:)`

``` swift
open func inputTextView(_ inputTextView: InputTextView, didPasteImage image: UIImage) 
