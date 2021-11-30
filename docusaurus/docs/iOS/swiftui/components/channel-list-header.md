---
title: Channel List Header
---

## Customizing the Channel List Header

In most cases, you will need to customize the channel list header to fit in with the rest of your app. The SwiftUI SDK provides several customization options, starting from small tweaks, to completely providing your own header.

The most simple change you can do is to change the title of the header, while keeping the same look and feel of it. In order to do this, simple pass the title in the initializer of the `ChatChannelListScreen` or `ChatChannelListView` component.

```swift
var body: some Scene {
    WindowGroup {
		ChatChannelListScreen(title: "Custom title")
    }
}
```

Another simple change you can do is to change the tint color of the header. This will change the navigation bar buttons in all of the SDK components. To do this, simple initialize the `StreamChat` object with your preferred tint color.

```swift
var colors = ColorPalette()
colors.tintColor = Color.red
        
let appearance = Appearance(colors: colors)
         
let streamChat = StreamChat(chatClient: chatClient, appearance: appearance)
```

## Creating Your Own Header

In most cases, you will need to customize the navigation bar even further - either by adding branding information, like logo and text, or even additional buttons that will either push a new view, display a modal sheet or an alert.

In order to do this, you will need to perform few steps. First, you need to create your own header, conforming to SwiftUI's `ToolbarContent` protocol. Let's create a header that will show title and two buttons, one opening a sheet and the other pushing a new view.

```swift
public struct CustomChannelHeader: ToolbarContent {
    
    @Injected(\.fonts) var fonts
    @Injected(\.images) var images
        
    public var title: String
    public var onTapLeading: () -> ()
    
    public var body: some ToolbarContent {
        ToolbarItem(placement: .principal) {
            Text(title)
                .font(fonts.bodyBold)
        }
        ToolbarItem(placement: .navigationBarTrailing) {
            NavigationLink {
                Text("This is injected view")
            } label: {
                Image(uiImage: images.messageActionEdit)
                    .resizable()
            }
        }
        ToolbarItem(placement: .navigationBarLeading) {
            Button {
                onTapLeading()
            } label: {
                Image(systemName: "line.3.horizontal")
                    .resizable()
            }
        }
    }
}
```

Our custom header implementation exposes an onTapLeading callback, that will be called when the leading button is tapped (for example a profile view). The implementation of this button will be done in a `ViewModifier`, since the `ToolbarContent` can't keep `@State` variables. The traling button has a simple `NavigationLink`, pointing to a new view. 

However, if you want additional logic, like using the other navigation approaches available in SwiftUI, you can do the same trick as with exposing the onTapLeading method - either passing a `@Binding` whether the `NavigationLink` is active, or pass an optional selected item for the `NavigationLink`. For the title, you can pass anything you want, instead of the Text in the sample - for example an `Image`, `VStack`, `HStack` or any other `View` component.

The next step is to provide a new implementation of the `ChannelListHeaderViewModifier`. This protocol has only a `title` requirement and you can add as many additional state and data properties you need in your custom implementation. In our case, we need to provide handling for the onTapLeading method from the `CustomChannelHeader`. To do this, we will introduce a new `@State` variable in the modifier and change its state to true when the button is tapped.

```swift
struct CustomChannelModifier: ChannelListHeaderViewModifier {
    
    var title: String
    
    @State var profileShown = false
    
    func body(content: Content) -> some View {
        content.toolbar {
            CustomChannelHeader(title: title) {
                profileShown = true
            }
        }
        .sheet(isPresented: $profileShown) {
            Text("Profile View")
        }
    }
    
}
```

The next step we need to do is to create our own custom view factory (or update existing one if you've already created it) to return the newly created channel view modifier. 

```swift
class CustomFactory: ViewFactory {
    
    @Injected(\.chatClient) public var chatClient
    
    private init() {}
    
    public static let shared = CustomFactory()
    
    func makeChannelListHeaderViewModifier(title: String) -> some ChannelListHeaderViewModifier {
        CustomChannelModifier(title: title)
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

These are all the steps needed to provide your own navigation header. 

