---
title: Data Formatting
---

import ThemingNote from '../common-content/theming-note.md'

You can customize how data is formatted across all the UI components provided by `StreamChatUI`. The SDK allows you to change the data formatting through the `Appearance.formatters` configuration. For simple customizations, you can use the default formatters provided by the SDK, for more custom logic you can leverage your own formatter by adhering it to the respective data formatter `protocol`.

## Changing the message timestamp formatting

For the first use case on how to customize a data formatter in the SDK we will be customizing the default timestamp formatting by changing the underlying native DateFormatter to have a `timeStyle = .medium` instead of `.short`.

```swift
let defaultTimestampFormatter = DefaultMessageTimestampFormatter()
defaultTimestampFormatter.dateFormatter.timeStyle = .medium
Appearance.default.formatters.messageTimestamp = defaultTimestampFormatter
```
<ThemingNote/>

| Before  | After |
| ------------- | ------------- |
| <img src={require("../assets/data-formatting-custom-timestamp-before.png").default} /> | <img src={require("../assets/data-formatting-custom-timestamp-after.png").default} /> |

As you can see, by changing the `timeStyle` to `.medium` the timestamp now displays the seconds. If you wanted to create a custom data formatting that doesn't rely on a `DateFormatter` you can provide your own implementation of the `MessageTimestampFormatter` protocol. In the next section we will see how can we create a custom data formatter.

## Changing the user last activity formatting

As an example to showcase how to create a custom formatter from scratch, let's change the formatting of how the last activity of a user is displayed. By default, the last activity formatting is calculated by the `DefaultUserLastActivityFormatter` which uses custom logic to display the last activity time relative to the current day in hours, weeks, months or years. For this example, we are going to create a custom formatter by conforming to the `UserLastActivityFormatter` protocol where we will make use of a `DateFormatter` to display the last activity in a different format.

```swift
class CustomUserLastActivityFormatter: UserLastActivityFormatter {
    public var dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        formatter.doesRelativeDateFormatting = true
        formatter.locale = .autoupdatingCurrent
        return formatter
    }()

    func format(_ date: Date) -> String? {
        "last active: " + dateFormatter.string(from: date)
    }
}
```

Finally, set the custom formatter in the `Appearance` config:
```swift
// Set the custom formatter in the Appearance config
Appearance.default.formatters.userLastActivity = CustomUserLastActivityFormatter()
```

| Before  | After |
| ------------- | ------------- |
| <img src={require("../assets/data-formatting-custom-user-activity-before.png").default} /> | <img src={require("../assets/data-formatting-custom-user-activity-after.png").default} /> |

With this custom formatter we changed the last activity to display the relative date and the exact time which the user was last seen.

## Changing the channel name formatting
You can also create a custom formatter that uses a combination of our default formatters with your custom logic. For example, you can create a custom `ChannelNameFormatter` that only uses custom logic when the member count is only 1, but for the rest of the cases, it uses the default logic.

```swift
class CustomChannelNameFormatter: ChannelNameFormatter {
    let defaultChannelNameFormatter = DefaultChannelNameFormatter()

    func format(channel: ChatChannel, forCurrentUserId currentUserId: UserId?) -> String? {
        if channel.memberCount == 1 {
            return channel.membership?.name
        }

        return defaultChannelNameFormatter.format(channel: channel, forCurrentUserId: currentUserId)
    }
}

Appearance.default.formatters.channelName = CustomChannelNameFormatter()
```

In the example above, if the channel has only the current user as a member, it uses the name of the current user as the channel name, otherwise, the default logic is used.

## Markdown

The SDK offers Markdown formatting out of the box for channel messages. It supports the most common Markdown syntax; _italic_, **bold**, ~~strikethrough~~, `code`, Headings, Links, etc. It uses [SwiftyMarkdown](https://github.com/SimonFairbairn/SwiftyMarkdown) library internally.

<center><img src={require("../assets/markdown-formatting.png").default} width="60%" height="60%"/></center>

Mardown support is enabled by default. You can disable it by setting the following flag to false in the `Appearance` config:

```swift
Appearance.default.formatters.markdownFormatterEnabled = false
```

You can also provide you own Markdown implementation either by subclassing our `DefaultMarkdownFormatter` class or by adopting the `MarkdownFormatter` protocol:

```swift
class CustomMarkdownFormatter: DefaultMarkdownFormatter {
    override func containsMarkdown(_ string: String) -> Bool {
        // Your custom implementation
    }

    override func format(_ string: String) -> NSAttributedString {
        // Your custom implementation
    }
}
```

Or

```swift
class CustomMarkdownFormatter: MarkdownFormatter {
    func containsMarkdown(_ string: String) -> Bool {
        // Your custom implementation
    }
    
    func format(_ string: String) -> NSAttributedString {
        // Your custom implementation
    }
}
```

Set the `markdownFormatter` property in the `Appearance` config and you are done:

```swift
Appearance.default.formatters.markdownFormatter = CustomMarkdownFormatter()
```
