---
title: Message Grouping
---

Chat apps frequently group messages based on a certain criteria (for example, time interval between the sending dates). The messages that are part of a group, usually have a different compact UI to distinguish themselves from the other groups.

The messages in the message list are grouped based on the `maxTimeIntervalBetweenMessagesInGroup` value in the `MessageListConfig` (if the `groupMessages` option is set to `true`). It specifies a `TimeInterval` which determines how far apart messages can maximally be to be grouped together.

The default value of this property is 60 seconds, which means messages that are 60 seconds (or less) apart, will be grouped together. Messages that are farther apart are not grouped together and appear as standalone messages.

To change it up from the default value (`60` seconds) a different value (in this case: `20` seconds) can be specified like this:

```swift
let messageListConfig = MessageListConfig(
// highlight-start
    maxTimeIntervalBetweenMessagesInGroup: 20
// highlight-end
)
let utils = Utils(messageListConfig: messageListConfig)
streamChat = StreamChat(chatClient: chatClient, utils: utils)
```

The information whether a message is first in the group is provided via the factory method `makeMessageContainerView`, with the `showsAllInfo` parameter. If this parameter is `true`, the message is first in the group.

```swift
func makeMessageContainerView(
    channel: ChatChannel,
    message: ChatMessage,
    width: CGFloat?,
    showsAllInfo: Bool,
    isInThread: Bool,
    scrolledId: Binding<String?>,
    quotedMessage: Binding<ChatMessage?>,
    onLongPress: @escaping (MessageDisplayInfo) -> Void,
    isLast: Bool
) -> some View {
    MessageContainerView(
        factory: self,
        channel: channel,
        message: message,
        width: width,
        showsAllInfo: showsAllInfo,
        isInThread: isInThread,
        isLast: isLast,
        scrolledId: scrolledId,
        quotedMessage: quotedMessage,
        onLongPress: onLongPress
    )
}
```

You can also provide a view for the last message in the group. In order to do that, you should implement the `makeLastInGroupHeaderView` factory method.

```swift
public func makeLastInGroupHeaderView(for message: ChatMessage) -> some View {
    YourCustomViewHere()
}
```

If you want to have a different grouping criteria (different than a time interval based), you can subclass the `ChatChannelViewModel` and override the `groupMessages` method.

```swift
open func groupMessages() {
    var temp = [String: [String]]()
    for (index, message) in messages.enumerated() {
        let date = message.createdAt
        temp[message.id] = []
        if index == 0 {
            temp[message.id] = [firstMessageKey]
            continue
        } else if index == messages.count - 1 {
            temp[message.id] = [lastMessageKey]
        }
        
        let previous = index - 1
        let previousMessage = messages[previous]
        let currentAuthorId = messageCachingUtils.authorId(for: message)
        let previousAuthorId = messageCachingUtils.authorId(for: previousMessage)

        if currentAuthorId != previousAuthorId {
            temp[message.id]?.append(firstMessageKey)
            var prevInfo = temp[previousMessage.id] ?? []
            prevInfo.append(lastMessageKey)
            temp[previousMessage.id] = prevInfo
        }

        if previousMessage.type == .error
            || previousMessage.type == .ephemeral
            || previousMessage.type == .system {
            temp[message.id] = [firstMessageKey]
            continue
        }

        let delay = previousMessage.createdAt.timeIntervalSince(date)

        if delay > utils.messageListConfig.maxTimeIntervalBetweenMessagesInGroup {
            temp[message.id]?.append(firstMessageKey)
            var prevInfo = temp[previousMessage.id] ?? []
            prevInfo.append(lastMessageKey)
            temp[previousMessage.id] = prevInfo
        }
        
        if temp[message.id]?.isEmpty == true {
            temp[message.id] = nil
        }
    }
    
    messagesGroupingInfo = temp
}
```

The important part here is that you set the `messagesGroupingInfo` value, consisting of message IDs and markers if they are a first or last message key. If no grouping info is provided, the message is considered as part of a group.