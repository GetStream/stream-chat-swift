---
title: Message Avatar View
---

## Injecting Custom Avatar View

The default avatar shown for the message sender in the SDK is a rounded image with the user's photo. You can change the look and feel of this component, as well as introduce additional elements.

To do this, you need to implement the `makeMessageAvatarView` of the `ViewFactory` and return your custom view. Here's an example on how to create a custom avatar with rounded rectangle clip shape. 

```swift
import StreamChat
import NukeUI
import Nuke

struct CustomUserAvatar: View {
    var avatarURL: URL?
    
    public var body: some View {
        ZStack {
            if let url = avatarURL {
                LazyImage(source: url)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .frame(width: 40, height: 40)
            } else {
                Image(systemName: "person.circle")
                    .resizable()
                    .frame(width: 40, height: 40)
            }
        }
    }

}
```

After the view is created, you need to provide it in your custom factory, and afterwards inject the factory in our view hierarchy.

```swift
class CustomFactory: ViewFactory {
    
    @Injected(\.chatClient) public var chatClient
    
    init() {}
   
    func makeMessageAvatarView(for avatarURL: URL?) -> some View {
        CustomUserAvatar(avatarURL: avatarURL)
    }
    
}
```

With this, you can have a custom avatar view in the message list view.