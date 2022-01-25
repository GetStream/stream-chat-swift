---
title: Localization
---

If you deploy your app to users who speak another language, you'll need to internationalize (localize) it. That means you need to write the app in a way that makes it possible to localize values like text and layouts for each language or locale that the app supports.

## Adding a new Language

1. If you don't have `strings` or `stringsdict` files in your project, add those new files to `Localizable.strings` and `Localizable.stringsdict`.
2. Next [add new language to the project](https://developer.apple.com/documentation/xcode/adding-support-for-languages-and-regions).
3. Copy the StreamChatUI localization keys into your `strings` and `stringsdict` files. You can find the latest version [here](https://github.com/GetStream/stream-chat-swift/blob/main/Sources/StreamChatUI/Resources/en.lproj/).
4. Set the `localizationProvider` to provide your `AppBundle` instead of `StreamChatUI` frameworks:
```swift
Appearance.default.localizationProvider = { key, table in
    Bundle.main.localizedString(forKey: key, value: nil, table: table)
}
```
5. Now, you're ready to implement your `strings` and `stringsdict` files for different languages.

:::tip
We recommend naming your `strings` and `stringsdict` files: `Localizable.strings` and `Localizable.stringsdict`.
:::

## Override Existing Languages

Overriding the existing language works in the same as adding a new language.

## Resources

Every string included in StreamChat can be changed and translated to a different language. All strings used by UI components are in these two files:

- [`Localizable.strings`](https://github.com/GetStream/stream-chat-swift/blob/main/Sources/StreamChatUI/Resources/en.lproj/Localizable.strings) 
- [`Localizable.stringsdict`](https://github.com/GetStream/stream-chat-swift/blob/main/Sources/StreamChatUI/Resources/en.lproj/Localizable.stringsdict)
