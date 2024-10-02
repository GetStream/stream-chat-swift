---
title: Polls
---

import PollState from '../common-content/polls/state.md'
import PollController from '../common-content/polls/poll-controller.md'
import PollControllerDelegate from '../common-content/polls/poll-controller-delegate.md'
import PollVoteListController from '../common-content/polls/poll-vote-list-controller.md'
import PollVoteListControllerDelegate from '../common-content/polls/poll-vote-list-controller-delegate.md'

Stream Chat's SwiftUI SDK includes the capability to create polls within your chat application. Polls are an effective tool for enhancing user interaction and engagement, providing a dynamic way to gather opinions and feedback.

:::note
Polls on SwiftUI are available since version [4.57.0](https://github.com/GetStream/stream-chat-swiftui/releases/tag/4.57.0).
:::

Polls are disabled by default. In order to enable this feature, you need to go to the Stream dashboard for your app, and enable the "Polls" flag for your channel type.

![Screenshot showing how to enable polls](../assets/polls-dashboard.png)

As soon as you do that, an additional "Polls" icon would be shown in the attachment picker in the default composer implementation in the SDK.

![Screenshot showing polls icon in the composer](../assets/polls-composer.png)

## Poll configuration

When you tap the "Polls" icon, a new screen for creating polls would be shown. On this screen, you can configure the poll title, the options, as well as several other settings, such as the maximum number of votes, whether the poll is anonymous and if it allows comments.

![Screenshot showing create poll view](../assets/create-poll.png)

You can setup which of these options are going to be configurable for the users creating the poll. In order to do that, you need to provide your own `PollsConfig`.

For example, let's create a new configuration that removes the suggestions feature and enables multiples votes by default.

```swift
let pollsConfig = PollsConfig(
    multipleAnswers: PollsEntryConfig(configurable: true, defaultValue: true),
    anonymousPoll: .default,
    suggestAnOption: .notConfigurable,
    addComments: .default,
    maxVotesPerPerson: .default
)

let utils = Utils(
    pollsConfig: pollsConfig
)

let streamChat = StreamChat(chatClient: chatClient, utils: utils)
```

## Poll creation view

You can also swap the whole view that shows the poll creation sheet. To do that, you need to implement the method `makeComposerPollView` in the `ViewFactory` protocol:

```swift
func makeComposerPollView(
        channelController: ChatChannelController,
        messageController: ChatMessageController?
) -> some View {
    CustomComposerPollView(channelController: channelController, messageController: messageController)
}
```

The `CustomComposerPollView` can then show your custom poll creation flow with a code similar to this one:

```swift
struct CustomComposerPollView: View {
    @State private var showsOnAppear = true
    @State private var showsCreatePoll = false
    
    let channelController: ChatChannelController
    var messageController: ChatMessageController?
    
    var body: some View {
        VStack {
            Spacer()
            Button {
                showsCreatePoll = true
            } label: {
                Text("Create poll")
            }

            Spacer()
        }
        .fullScreenCover(isPresented: $showsCreatePoll) {
            CustomCreatePollView(chatController: channelController, messageController: messageController)
        }
        .onAppear {
            guard showsOnAppear else { return }
            showsOnAppear = false
            showsCreatePoll = true
        }
    }
}
```

## Poll attachment view

When a message contains a poll, the optional `poll` property inside `ChatMessage` would have a value of type `Poll`. In those cases, the `PollAttachmentView` would be shown. 

Poll attachments have the same behaviour as other types of messages - you can send reactions, reply, delete them or pin them.

The default poll attachment view has the following UI:

![Screenshot showing poll attachment view](../assets/poll-attachment.png)

You can swap the default view with your own implementation. To do that, you would need to implement the `makePollView` in the `ViewFactory` protocol:

```swift
func makePollView(message: ChatMessage, poll: Poll, isFirst: Bool) -> some View {
    CustomPollAttachmentView(factory: self, message: message, poll: poll, isFirst: isFirst)
}
```

The `message`, the `poll` and whether the message is first in the group are provided in this method.

To facilitate your custom implementation, you can use the public `PollAttachmentViewModel` class, that is used by the default `PollAttachmentView`.

## Poll state

<PollState />

### PollController

<PollController />

### PollControllerDelegate

<PollControllerDelegate />

### PollVoteListController

<PollVoteListController />

### PollVoteListControllerDelegate

<PollVoteListControllerDelegate />