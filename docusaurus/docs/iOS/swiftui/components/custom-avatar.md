---
title: Message Avatar View
---

## Injecting Custom Avatar View

The default avatar shown for the message sender in the SDK is a rounded image with the user's photo. You can change the look and feel of this component, as well as introduce additional elements, such as the sender name.

To do this, you need to implement the `makeMessageAvatarView` of the `ViewFactory` and return your custom view. Here's an example on how to create a custom avatar with the author's name bellow the image. 

```swift
import StreamChat
import NukeUI
import Nuke

struct CustomUserAvatar: View {
    var author: ChatUser
    
    public var body: some View {
        VStack {
            if let url = author.imageURL?.absoluteString {
                LazyImage(source: url)
                    .clipShape(Circle())
                    .frame(width: 40, height: 40)
            } else {
                Image(systemName: "person.circle")
                    .resizable()
                    .frame(width: 40, height: 40)
            }
            Text(author.name ?? "")
                .font(.system(size: 13))
                .frame(maxWidth: 60)
        }
    }

}
```

After the view is created, you need to provide it in your custom factory, and afterwards inject the factory in our view hierarchy.

```swift
class CustomFactory: ViewFactory {
    
    @Injected(\.chatClient) public var chatClient
    
    init() {}
   
    func makeMessageAvatarView(for user: ChatUser) -> some View {
        CustomUserAvatar(author: user)
    }
    
}
```

With this, you can have a custom avatar view in the message list view.