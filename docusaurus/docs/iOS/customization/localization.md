---
title: Adding Localization
---

If your application is going to have a userbase of people that speak more than one language, you will need to build localization (i10n)  and internationalization (i18n) into your application.
The StreamChat SDK provides a built in way to handle localization by overriding the default strings in the UI components. The strings are stored in two files:

- [`Localizable.strings`](https://github.com/GetStream/stream-chat-swift/blob/main/Sources/StreamChatUI/Resources/en.lproj/Localizable.strings) contains the strings for simple UI components.
- [`Localizable.stringsdict`](https://github.com/GetStream/stream-chat-swift/blob/main/Sources/StreamChatUI/Resources/en.lproj/Localizable.stringsdict) contains the strings for advanced components like typing indicators or the number of responses in the thread. `stringsdict` uses the `NSStringPluralRuleType`. 

## Changing the device's language

Stream Chat tries to use the same language as the device it's running on. If the device is set to a language that Stream Chat does not support, then Stream Chat will default to English.
See [how to change device language](https://support.apple.com/en-us/HT204031).

## Adding a new language or changing the default

StreamChatUI uses `strings` and `stringsdict` files to handle localization or even just overriding the default strings for the UI framework.
`Appearance` structure contains closure `localizationProvider`, which is responsible for deriving `localizedString` from exact bundle. 
By default, this bundle is the  `StreamChatUI` framework bundle, but you can customize it to anything else with the following steps:

1.If you don't have `strings` or `stringsdict` files in your project, add those new files to `Localizable.strings` and `Localizable.stringsdict`.
2. Next [add new language to the project](https://developer.apple.com/documentation/xcode/adding-support-for-languages-and-regions).
3. Copy the StreamChatUI localization keys into your `strings` and `stringsdict` files.
4. Set the `localizationProvider` to provide your `AppBundle` instead of `StreamChatUI` frameworks:
```swift
Appearance.default.localizationProvider = { key, table in
// A best practice is to use Bundle.main unless your strings are in a different bundle.
    // Note: `table` is equivalent to filename of the `Localization.strings` file without file extension. 
    // the name for `strings` and `stringsdict` should be same!
    Bundle.main.localizedString(forKey: key, value: nil, table: table)
}
```
5. Now, you're ready to implement your strings and stringsdict files for different languages.

You can use the same steps to change the default strings for an existing language too.

:::tip
For easier implementation, it's advised to name your `strings` and `stringsdict` files as follows: `Localizable.strings`, `Localizable.stringsdict` . Also you need to name those 2 files the same. 
If you don't want to have those files named like this, be sure to set the `table` argument to your filename ( `Bundle.main.localizedString(forKey: key, value: nil, table: "MyLocalizableStrings")`)
:::

:::caution
You should assign your custom `localizationProvider`  to `Appearance.default` only. If you create your custom `Appearance`, assign the `localizationProvider` to it and assign the `appearance` to some component, expect the component to have StreamChat localization instead of your custom one.
:::

## Resources

To make setting up localization easier, you can just copy the following content of files and add it to your current Localization: 

- [`Localizable.strings`](https://github.com/GetStream/stream-chat-swift/blob/main/Sources/StreamChatUI/Resources/en.lproj/Localizable.strings)
- [`Localizable.stringsdict`](https://github.com/GetStream/stream-chat-swift/blob/main/Sources/StreamChatUI/Resources/en.lproj/Localizable.stringsdict)

For example implementation of Czech localization, you can refer to [`DemoApp`](https://github.com/GetStream/stream-chat-swift/tree/main/DemoApp) in StreamChat repository on github and take a look at `Localizable.string`, `Localizable.stringsdict` and `DemoAppCoordinator.swift` where the assignment of the localization takes place.
