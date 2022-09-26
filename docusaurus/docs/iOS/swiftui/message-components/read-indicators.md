---
title: Read Indicators
---

## Read Indicators Overview

The SwiftUI SDK supports read indicators, which indicate whether a message was read by the other channel participants. 

The read indicators are available in both the channel and the message list. The default implementation shows one gray checkmark if a message was sent, but not read by anyone and two blue (depending on tint color) checkmarks for a read message. If a message is sent in a group, the number of readers of the message is also shown.

It is possible to customize the read indicator in the message list. For example, some messaging apps show small icons of the users who have read the message. 

In order to implement your own version of the read indicator, you will need to implement the `makeMessageReadIndicatorView` in the `ViewFactory` protocol.

```swift
public func makeMessageReadIndicatorView(
    channel: ChatChannel,
    message: ChatMessage
) -> some View {
	CustomMessageReadIndicatorView(
		channel: ChatChannel,
    	message: ChatMessage
	)
}
```

In this method, you receive the channel and the message as parameters. You can use the channel to extract the users who have read the message. In order to do this, call the `readUsers(currentUserId:message:)` method of the channel. If you need more information about the reads (e.g. last read date), you can access the `reads` property of the channel.