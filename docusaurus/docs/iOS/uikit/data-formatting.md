---
title: Data Formatting
---

import ThemingNote from '../common-content/theming-note.md'

You can customize how data is formatted across all the UI components provided by `StreamChatUI`. The SDK allows you to change the data formatting through the `Appearance` configuration where you can change, for example, how message dates, video durations, and times are formatted in each component. Each formatter can be accessed through the `Appearance.formatters` property. You can replace a formatter with a custom one since each formatter is represented by a `Protocol`, but you can also do simple changes by changing the default formatters provided by the SDK.

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

## Changing the channel name formatting

As an example to showcase how to create a custom formatter let's change the formatting of how the last activity of a user is displayed. By default, the last activity formatting is calculated by the `DefaultUserLastActivityFormatter` which uses a custom logic to display the last activity time relative to the current day in hours, weeks, months or years. For this example, we are going to create a custom formatter by conforming to the `UserLastActivityFormatter` protocol where we will make use of a `DateFormatter` to display the last activitiy in a different format.

```swift
class CustomUserLastActivityFormatter: UserLastActivityFormatter {
    public lazy var dateFormatter: DateFormatter = {
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

Then, set the custom formatter in the `Appearance` config:
```swift
// Set the custom formatter in the Appearance config
Appearance.default.formatters.userLastActivity = CustomUserLastActivityFormatter()
```

| Before  | After |
| ------------- | ------------- |
| <img src={require("../assets/data-formatting-custom-user-activity-before.png").default} /> | <img src={require("../assets/data-formatting-custom-user-activity-after.png").default} /> |

With this custom formatter we changed the last activity to display the relative date and the exact time which the user was last seen.