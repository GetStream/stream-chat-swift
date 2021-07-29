---
title: Localization
---

StreamChat offers pre-defined localization for text indicating across the whole UISDK. Currently, StreamChat supports only English language, but if you want to provide your custom strings, it's very easy to do.
The whole approach to StreamChat SDK is to stay as much consistent as possible with native iOS paradigms and approaches to certain problems. That's why we use `strings` and `stringsdict` files to handle localize the framework.
For advanced plural localization cases (typing indicator showing how many people are typing or how many responses are in thread), we use `stringsdict` with `NSStringPluralRuleType` 

## Adding Custom Localization

As said earlier, StreamChatUI uses `strings` and `stringsdict` files to handle localize the framework.
`Appearance` structure contains closure `localizationProvider`, which is responsible for deriving `localizedString` from exact bundle. 
By default, the bundle is  `StreamChatUI` framework bundle, but you can customize it to anything you need in 3 steps:

1. First thing you need to do is to copy `StreamChatUI` localization keys into your `strings` file (Or just copy the default `Localizable.strings` and `Localizable.stringsdict` files to your project from our repository).
2. Once you have those files in your application, you need to set the `localizationProvider` to provide your `AppBundle` instead of `StreamChatUI` frameworks like this: 
```swift
Appearance.default.localizationProvider = { key, table in
    // For most cases, you will probably use Bundle.main, unless your strings are in different Bundle.
    // Note: `table` is equivalent to filename of the `Localization.strings` file without file extension. 
    Bundle.main.localizedString(forKey: key, value: nil, table: table)
}
```
3. Now everything that has left is to implement your  `strings` and `stringsdict`  files for different languages or even customize the default strings for your own.

:::caution
Because of internal implementation of `L10n` inside StreamChatSDK, you should assign the custom `localizationProvider` only to `Appearance.default` instance. Setting the provider to custom appearance instance would cause custom localization not to won't work.
:::

## Resources

To ease your work, you can just copy the following content of files and add it to your current Localization: 

### `Localizable.strings`:

```swift 
"channel.name.and" = "and";
"channel.name.andXMore" = "and %@ more";
"channel.name.missing" = "NoChannel";
"channel.item.empty-messages" = "No messages";
"channel.item.typing-singular" = "is typing ...";
"channel.item.typing-plural" = "are typing ...";

"message.actions.inline-reply" = "Reply";
"message.actions.thread-reply" = "Thread Reply";
"message.actions.edit" = "Edit Message";
"message.actions.copy" = "Copy Message";
"message.actions.delete" = "Delete Message";
"message.actions.delete.confirmation-title" = "Delete Message";
"message.actions.delete.confirmation-message" = "Are you sure you want to permanently delete this message?";
"message.actions.user-unblock" = "Unblock User";
"message.actions.user-block" = "Block User";
"message.actions.user-unmute" = "Unmute User";
"message.actions.user-mute" = "Mute User";
"message.actions.resend" = "Resend";

"messageList.typingIndicator.typing-unknown" = "Someone is typing";

"message.threads.reply" = "Thread Reply";
"message.threads.replyWith" = "with %@";

"alert.actions.cancel" = "Cancel";
"alert.actions.delete" = "Delete";
"alert.actions.ok" = "Ok";

"message.only-visible-to-you" = "Only visible to you";
"message.deleted-message-placeholder" = "Message deleted";

"composer.title.edit" = "Edit Message";
"composer.title.reply" = "Reply to Message";
"composer.placeholder.message" = "Send a message";
"composer.placeholder.giphy" = "Search GIFs";
"composer.checkmark.direct-message-reply" = "Also send as direct message";
"composer.checkmark.channel-reply" = "Also send in channel";
"composer.picker.title" = "Choose attachment type: ";
"composer.picker.file" = "File";
"composer.picker.media" = "Photo or Video";
"composer.picker.cancel" = "Cancel";

"composer.suggestions.commands.header" = "Instant Commands";
"message.sending.attachment-uploading-failed" = "UPLOADING FAILED";

"message.title.online" = "Online";
"message.title.see-minutes-ago" = "Seen %@ ago";
"message.title.offline" = "Offline";
"message.title.group" = "%d members, %d online";

"current-selection" = "%d of %d";

"attachment.max-size-exceeded" = "Attachment size exceed the limit.";
```

### `Localizable.stringsdict`:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>messageList.typingIndicator.users</key>
    <dict>
        <key>NSStringLocalizedFormatKey</key>
        <string>%1$@%2$#@typing@</string>
        <key>typing</key>
        <dict>
            <key>NSStringFormatSpecTypeKey</key>
            <string>NSStringPluralRuleType</string>
            <key>NSStringFormatValueTypeKey</key>
            <string>d</string>
            <key>zero</key>
            <string> is typing</string>
            <key>one</key>
            <string> and %2$d more is typing</string>
            <key>other</key>
            <string> and %2$d more are typing</string>
        </dict>
    </dict>
    <key>message.threads.count</key>
    <dict>
        <key>NSStringLocalizedFormatKey</key>
        <string>%#@replies@</string>
        <key>replies</key>
        <dict>
            <key>NSStringFormatSpecTypeKey</key>
            <string>NSStringPluralRuleType</string>
            <key>NSStringFormatValueTypeKey</key>
            <string>d</string>
            <key>one</key>
            <string>%d Thread Reply</string>
            <key>other</key>
            <string>%d Thread Replies</string>
        </dict>
    </dict>
</dict>
</plist>
```

For implementation of Czech localization, you can refer to [`DemoApp`](https://github.com/GetStream/stream-chat-swift/tree/main/DemoApp) in StreamChat repository on github.
