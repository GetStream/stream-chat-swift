---
title: Theming
---

The Stream SDK UI Components are fully customizable, but in case you don't want to change much of the built-in components and only want to change the branding, colors and images, the SDK let's you customize that with the help of an `Appearance` configuration type. Every component in the Stream SDK has access to this configuration type, so if you change the configuration it will impact have every component that is affected by the change.

## Changing Brand Color

The most basic customization you can do is to change the brand color, and for this one you don't really need the Stream's `Appearance` configuration, you only need to change the tint color of the `UIWindow`. If suitable, UI elements respect `UIView.tintColor` as the main (brand) color. The current `tintColor` depends on the tint color of the view hierarchy the UI element is presented on.

For example, by changing the tint color of the `UIWindow` of the app, you can easily modify the brand color of the whole chat UI:

```swift
class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let scene = scene as? UIWindowScene else { return }

        scene.windows.forEach {
          $0.tintColor = .systemPink 
        }
    }
}
```

| Before  | After |
| ------------- | ------------- |
| ![Chat UI with default tint color](https://github.com/GetStream/stream-chat-swift/wiki/blue-tint.png)  | ![Chat UI with pink tint color](https://github.com/GetStream/stream-chat-swift/wiki/pink-tint.png)  |

## Changing Colors and Fonts

The colors and fonts are part of the `Appearance` configuration type. Since all components have access to this configuration, by changing the theming colors and fonts, it will change every component that uses those. This makes it easy to consistently change the look and feel of all elements the framework provides.

For example, let's change the color of the messages sent by the current user and the body font. We can do this by simply modifying the values from `Appearance.default` as early as possible in your application life-cycle:
```swift
class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        ...
        Appearance.default.fonts.body = .italicSystemFont(ofSize: 20)
        Appearance.default.colorPalette.background6 = .yellow
        ...
    }
}
```

| Before  | After |
| ------------- | ------------- |
| ![Messages Default Appearance](https://github.com/GetStream/stream-chat-swift/wiki/default-appearance.png)  | ![Messages Adjusted Appearance](https://github.com/GetStream/stream-chat-swift/wiki/adjusted-appearance.png)  |

You can see the font and the background color of the message has changed. Also note, that the font in the composer text view is also changed, since it uses the same semantic font as the body of the message.

## Changing Image Assets

The image assets and icons used by buttons also use the `Appearance` configuration type. For example, let's modify the icon used for the "Send" button:

```swift
Appearance.default.images.sendArrow = UIImage(systemName: "arrowshape.turn.up.right")!
```

| Before  | After |
| ------------- | ------------- |
| ![Custom Send Button](https://github.com/GetStream/stream-chat-swift/wiki/default-send-button.png)  | ![Default Send Button](https://github.com/GetStream/stream-chat-swift/wiki/custom-send-button.png)  |

If the same image is used in multiple places, changing the image in the `Appearance` object will update it in all places.