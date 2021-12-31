---
title: Message Composer Commands
---

## Composer Commands Overview

The SwiftUI SDK has support for several types of commands in the composer. For example, when a user types "@" in the input field, a list of users that can be mentioned will be displayed. Additionally, the composer supports instant commands ("/"), similar to Slack. For example, you can share a giphy, by typing the "/giphy" command, or mute/unmute users. All the symbols and text for the commands are configurable, so you can use different displaying information for them. Additionally, you can create your own commands, and define their rules and handling. For example, you can create a "/pay" command, to send money to a user in the chat.

## Modifying the Supported Commands

Before creating your own custom commands, let's see how you can modify the supported ones, to fit your needs. First, you can change the order of the commands, as well as remove the ones you don't want to support. Additionally, you can change the invoking symbols of the commands. In order to accomplish this, you will need to implement your own `CommandsConfig` and inject it in the `Utils` class inside the `StreamChat` object.

```swift
public class CustomCommandsConfig: CommandsConfig {
    
    public init() {}
    
    // Change these properties for different symbols for the commands.
    public let mentionsSymbol: String = "@"
    public let instantCommandsSymbol: String = "/"
    
    public func makeCommandsHandler(
        with channelController: ChatChannelController
    ) -> CommandsHandler {
    	// Modify the configuration of the commands here:
        let mentionsCommand = MentionsCommandHandler(
            channelController: channelController,
            commandSymbol: mentionsSymbol,
            mentionAllAppUsers: false
        )
        let giphyCommand = GiphyCommandHandler(commandSymbol: "/giphy")
        let muteCommand = MuteCommandHandler(
            channelController: channelController,
            commandSymbol: "/mute"
        )
        let unmuteCommand = UnmuteCommandHandler(
            channelController: channelController,
            commandSymbol: "/unmute"
        )

        // Add or remove commands here, or change the order.
        let instantCommands = InstantCommandsHandler(
            commands: [giphyCommand, muteCommand, unmuteCommand]
        )
        return CommandsHandler(commands: [mentionsCommand, instantCommands])
    }
}
```

In the code above, you can modify the command symbols by changing the `mentionsSymbol` and `instantCommandsSymbol` properties accordingly. In the `makeCommandsHandler` method, you can change the order of the commands, or add or remove commands.

After you have created the `CustomCommandsConfig`, you need pass it to the `StreamChat` object in the setup step (for example in your `AppDelegate`):

```swift
let utils = Utils(commandsConfig: CustomCommandsConfig())    
let streamChat = StreamChat(chatClient: chatClient, utils: utils)
```

## Creating a Custom Command

In order to create a custom command, you need to create your own class implementing the `CommandHandler` protocol. After you create your own implementation, you will need to inject it in your own `CustomCommandsConfig`, as described in the above example.

The methods defined by the `CommandHandler` are the following:

```swift
public protocol CommandHandler {
    
    /// Identifier of the command.
    var id: String { get }
    
    /// Display info for the command.
    var displayInfo: CommandDisplayInfo? { get }
    
    /// Whether execution of the command replaces sending of a message.
    var replacesMessageSent: Bool { get }
    
    /// Checks whether the command can be handled.
    /// - Parameters:
    ///  - text: the user entered text.
    ///  - caretLocation: the end location of a selected text range.
    /// - Returns: optional `ComposerCommand` (if the handler can handle the command).
    func canHandleCommand(
        in text: String,
        caretLocation: Int
    ) -> ComposerCommand?
    
    /// Returns a command handler for a command (if available).
    /// - Parameter command: the command whose handler will be returned.
    /// - Returns: Optional `CommandHandler`.
    func commandHandler(for command: ComposerCommand) -> CommandHandler?
    
    /// Shows suggestions for the provided command.
    /// - Parameter command: the command whose suggestions will be shown.
    /// - Returns: `Future` with the suggestions, or an error.
    func showSuggestions(
        for command: ComposerCommand
    ) -> Future<SuggestionInfo, Error>
    
    /// Handles the provided command.
    /// - Parameters:
    ///  - text: the user entered text.
    ///  - selectedRangeLocation: the end location of the selected text.
    ///  - command: binding of the command.
    ///  - extraData: additional data that can be passed from the command.
    func handleCommand(
        for text: Binding<String>,
        selectedRangeLocation: Binding<Int>,
        command: Binding<ComposerCommand?>,
        extraData: [String: Any]
    )
    
    /// Checks whether the command can be executed on message sent.
    /// - Parameter command: the command to be checked.
    /// - Returns: `Bool` whether the command can be executed.
    func canBeExecuted(composerCommand: ComposerCommand) -> Bool
    
    /// Needs to be implemented if you need some code executed before the message is sent.
    /// - Parameters:
    ///  - composerCommand: the command to be executed.
    ///  - completion: called when the command is executed.
    func executeOnMessageSent(
        composerCommand: ComposerCommand,
        completion: @escaping (Error?) -> Void
    )
}
```

You can implement these methods to have the most customized command handling behavior. However, in most cases you will need support for a two-step command process, where in the first one, you will pick the instant command and in the second step, you will mention a user, that will be affected by your command. These can be actions both supported by the SDK (muting, banning, flagging, etc), or your own custom actions.

In order to re-use the two-step command process from the SDK, you will need to subclass the `TwoStepMentionCommand`. For example, let's see how the mute action can be implemented by subclassing the `TwoStepMentionCommand`. 

```swift
public class MuteCommandHandler: TwoStepMentionCommand {
    
    @Injected(\.images) private var images
    @Injected(\.chatClient) private var chatClient
                        
    public init(
        channelController: ChatChannelController,
        commandSymbol: String,
        id: String = "/mute"
    ) {
        super.init(
            channelController: channelController,
            commandSymbol: commandSymbol,
            id: id
        )
        let displayInfo = CommandDisplayInfo(
            displayName: L10n.Composer.Commands.mute,
            icon: images.commandMute,
            format: "\(id) [\(L10n.Composer.Commands.Format.username)]",
            isInstant: true
        )
        self.displayInfo = displayInfo
    }

    override public func executeOnMessageSent(
        composerCommand: ComposerCommand,
        completion: @escaping (Error?) -> Void
    ) {
        if let mutedUser = selectedUser {
            chatClient
                .userController(userId: mutedUser.id)
                .mute { [weak self] error in
                    self?.selectedUser = nil
                    completion(error)
                }

            return
        }
    }
}
``` 

In the `init` method, we setup display info of the command. If this is not specified, the command will not appear in the instant commands suggestions popup above the composer.

Additionally, we only need to override the `executeOnMessageSent` method, which is called when all the data is selected and the user is allowed to execute the command. In this method, we can make use of the `selectedUser` variable, which gives us information about the mentioned user in the command. In the example, we are muting the user. You can execute your own code here, for example sending a payment to the user, or anything else that fits your app's use-cases. You only need to call the `completion` handler when you are done with the action. 

By default, these commands don't send the message in the message list. However, you can easily change this by returning `false` in the `replacesMessageSent` variable:


```swift
override public var replacesMessageSent: Bool {
    return false
}
```

### Customizing the Command Suggestions Views

The SDK comes with a default container view, that is displayed above the composer and over the message list. You can replace this view, either to adjust the user interface, or to support different types of suggestions for your custom commands.

In order to do this, you will need to implement the `makeCommandsContainerView` in the `ViewFactory`:

```swift
class CustomViewFactory: ViewFactory {

	@Injected(\.chatClient) public var chatClient
    
	public func makeCommandsContainerView(
        suggestions: [String: Any],
        handleCommand: @escaping ([String: Any]) -> Void
    ) -> some View {
        CustomCommandsContainerView(
            suggestions: suggestions,
            handleCommand: handleCommand
        )
    }
}
```

In this method, you receive a `Dictionary` with the suggestions provided to the user, depending on the command that's being executed. Additionally, you get a callback, which needs to be called when the user selects something in your own custom views. This data will be passed to your custom `CommandHandler`, where you will be able to react to the command accordingly.

```swift
struct CustomCommandsContainerView: View {
    
    var suggestions: [String: Any]
    var handleCommand: ([String: Any]) -> Void
    
    var body: some View {
        ZStack {
            if let suggestedUsers = suggestions["mentions"] as? [ChatUser] {
                MentionUsersView(
                    users: suggestedUsers,
                    userSelected: { user in
                        handleCommand(["chatUser": user])
                    }
                )
            }
            
            if let instantCommands = suggestions["instantCommands"] as? [CommandHandler] {
                InstantCommandsView(
                    instantCommands: instantCommands,
                    commandSelected: { command in
                        handleCommand(["instantCommand": command])
                    }
                )
            }
        }
    }
}
```

Finally, you need to inject the `CustomViewFactory` in your view hierarchy.

```swift
var body: some Scene {
    WindowGroup {
        ChatChannelListView(viewFactory: CustomViewFactory.shared)
    }
}
```