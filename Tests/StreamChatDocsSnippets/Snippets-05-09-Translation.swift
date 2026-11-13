//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

// https://getstream.io/chat/docs/ios-swift/translation/

import StreamChat

struct Snippets_05_09_Translation {
    var channelId: ChannelId!
    var chatClient: ChatClient!
    var message: ChatMessage!
    var messageId: MessageId!
    var userToken: Token!

    func enableAutomaticTranslation() {
        // Turning auto-translation on or off is server-side only. Use one of our server-side
        // SDKs to enable it for the app or a channel.

        // Read the current settings back from the channel
        let channelController = chatClient.channelController(for: ChannelId(type: .messaging, id: "melting-pot"))
        channelController.synchronize { error in
          let isEnabled = channelController.channel?.isAutoTranslationEnabled
          let languages = channelController.channel?.autoTranslationLanguages // e.g. [.english, .spanish, .french]
          suppressUnusedWarning(isEnabled, languages)
        }
    }

    func setUserLanguage() {
        // Sets the user language
        chatClient.connectUser(
            userInfo: UserInfo(id: "userId", language: .english),
            token: userToken
        )
    }

    func readingTranslations() {
        // Translations are keyed by language, and the original language is its own field
        let translations = message.translations // e.g. [.french: "Bonjour, ...", .italian: "Ciao, ..."]
        let originalLanguage = message.originalLanguage // .english

        // Show the reader's language, falling back to the original text
        let language = chatClient.currentUserController().currentUser?.language
        let text = language.flatMap { message.translatedText(for: $0) } ?? message.text
        suppressUnusedWarning(translations, originalLanguage, text)
    }

    func translateAMessageOnDemand() {
        let messageController = chatClient.messageController(cid: channelId, messageId: messageId)
        messageController.translate(to: .french) { error in
          if error == nil {
            let translation = messageController.message?.translations?[.french]
            suppressUnusedWarning(translation)
          }
        }
    }

    func pollTranslation() {
        guard let poll = message.poll else { return }
        let language = chatClient.currentUserController().currentUser?.language

        // Fall back to the original text when a field has no translation for the language
        let name = poll.name(in: language)
        let options = poll.options.map { option in option.text(in: language) }
        let answers = poll.latestAnswers.map { answer in answer.answerText(in: language) }

        // Or read a single translation, which is nil when there is none for the language
        let spanishName = poll.translatedName(for: .spanish)
        suppressUnusedWarning(name, options, answers, spanishName)
    }
}
