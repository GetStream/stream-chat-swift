---
title: Message Attachments
---

## Message Attachments Overview

The SwiftUI SDK supports the following types of attachments:

- Images
- Giphys
- Videos
- Links
- Files

They all come with default views displaying the attachments. In addition, they are all swappable, so you can easily change some of them if you want a more customized look.

## Swapping Attachment Views

Let's see a simple example of how you can swap the existing attachments with your custom view. We will create a custom message view that displays the texts, but with bold font and different text color, as well as small checkmark in the bottom right corner, hinting that the message was sent.

```swift
struct CustomMessageTextView: View {
    @Injected(\.colors) var colors
    @Injected(\.fonts) var fonts

    var message: ChatMessage
    var isFirst: Bool

    public var body: some View {
        Text(message.text)
            .padding()
            .messageBubble(for: message, isFirst: isFirst)
            .foregroundColor(Color.blue)
            .font(fonts.bodyBold)
            .overlay(
                BottomRightView {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                        .offset(x: 1, y: -1)
                }
            )
    }
}
```

Next, we need to implement `makeMessageTextView` in the `ViewFactory` protocol, in our own `CustomFactory`.

```swift
class CustomFactory: ViewFactory {

    @Injected(\.chatClient) public var chatClient

    private init() {}

    public static let shared = CustomFactory()

    func makeMessageTextView(
        for message: ChatMessage,
        isFirst: Bool,
        availableWidth: CGFloat,
        scrolledId: Binding<String?>
    ) -> some View {
        CustomMessageTextView(
            message: message,
            isFirst: isFirst,
            scrolledId: scrolledId
        )
    }

}
```

Finally, we need to inject the `CustomFactory` in our view hierarchy.

```swift
var body: some Scene {
    WindowGroup {
        ChatChannelListView(viewFactory: CustomFactory.shared)
    }
}
```

These are all the steps needed to change the default SDK view with your custom one.

## Handling Custom Attachments

You can go a step further and introduce your own custom attachments with their corresponding custom views. Use-cases can be workout attachments, food delivery, money sending and anything else that might be supported within your apps.

Supporting custom attachment views is straightforward and can be implemented in a few simple steps. As an example, let's create a custom view that will detect if there's an email address in our message, and if there is - it will create a custom view with an additional email icon.

First, you need to create a custom view.

```swift
struct CustomAttachmentView: View {

    let message: ChatMessage
    let width: CGFloat
    let isFirst: Bool

    var body: some View {
        HStack {
            Image(systemName: "envelope")
            Text(message.text)
        }
        .padding()
        .frame(maxWidth: width)
        .messageBubble(for: message, isFirst: isFirst)
    }

}
```

Next, you need to define a custom rule in our `MessageTypeResolving` protocol, which has a default implementation in our SDK. What we are interested in is the `hasCustomAttachment` method. Therefore, we will provide our own implementation of it to check if there are any emails in the text message.

```swift
class CustomMessageResolver: MessageTypeResolving {

    func hasCustomAttachment(message: ChatMessage) -> Bool {
        let messageComponents = message.text.components(separatedBy: CharacterSet.whitespacesAndNewlines)
        return messageComponents.filter { component in
            isValidEmail(component)
        }
        .count > 0
    }

    private func isValidEmail(_ email: String) -> Bool {
        let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"

        let emailPred = NSPredicate(format:"SELF MATCHES %@", emailRegEx)
        return emailPred.evaluate(with: email)
    }

}
```

Next, we need to replace the default `MessageTypeResolving` implementation, with the one we have just created in our `Utils` class of the `StreamChat` object.

```swift
let messageTypeResolver = CustomMessageResolver()
let utils = Utils(messageTypeResolver: messageTypeResolver)

let streamChat = StreamChat(chatClient: chatClient, utils: utils)
```

Next, in our `CustomFactory`, we need to return the new view we have created above, in the method `makeCustomAttachmentViewType`.

```swift
func makeCustomAttachmentViewType(
    for message: ChatMessage,
    isFirst: Bool,
    availableWidth: CGFloat,
    scrolledId: Binding<String?>
) -> some View {
    CustomAttachmentView(
        message: message,
        width: availableWidth,
        isFirst: isFirst
    )
}
```

Finally, you need to inject the `CustomFactory` into our view hierarchy if you haven't done it already.

Note, if you want to support several different custom views, you will need to do if-else or switch logic in both the message type resolver and the custom view, which will act as container for several views.
