---
title: Theming
---

You can customize the look and feel of all UI components provided by `StreamChatUI`. The SDK allows you to change appearance of components such as colors and fonts via the `Appearance` component. Changes to appearance should be done as early as possible in your application, `SceneDelegate` and `AppDelegate` are usually the right place to do this. The SDK comes with a singleton object `Appearance.default`.

Here is an example on how you can change the default font size and the background color of messages

```swift
class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        /// ...

        Appearance.default.fonts.body = .italicSystemFont(ofSize: 20)
        Appearance.default.colorPalette.background6 = .yellow
        
        /// ...

        guard let _ = (scene as? UIWindowScene) else { return }

    }

    /// ...
}
```

| default       | custom                    |
| ------------- | ------------------------- |
| ![Chat UI with default tint color](https://github.com/GetStream/stream-chat-swift/wiki/default-appearance.png)  | ![Chat UI with pink tint color](https://github.com/GetStream/stream-chat-swift/wiki/adjusted-appearance.png)  |


:::note
More information on the styling properties used by UI components is available in their own doc page.
:::

### Properties 

Appearance style properties are organized in three groups:

#### colorPalette

A color palette to provide basic set of colors for all UI components. The full reference can be found [here](../reference-docs/sources/stream-chat-ui/appearance.color-palette.md)

#### fonts

The set of fonts used by UI components. The full reference can be found [here](../reference-docs/sources/stream-chat-ui/appearance.fonts.md)

#### images

The set of images used by UI components. The full reference can be found [here](../reference-docs/sources/stream-chat-ui/appearance.images.md)

### Changing Brand Color

If suitable, UI elements respect `UIView.tintColor` as the main (brand) color. The current `tintColor` depends on the tint color of the view hierarchy the UI element is presented on.

For example, by changing the tint color of the `UIWindow` of the app, you can easily modify the brand color of the whole chat UI:

```swift
class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let scene = scene as? UIWindowScene else { return }
        scene.windows.forEach { $0.tintColor = .systemPink }
    }
}
```

| default `tintColor`  | `tintColor = .systemPink` |
| ------------- | ------------- |
| ![Chat UI with default tint color](https://github.com/GetStream/stream-chat-swift/wiki/blue-tint.png)  | ![Chat UI with pink tint color](https://github.com/GetStream/stream-chat-swift/wiki/pink-tint.png)  |
