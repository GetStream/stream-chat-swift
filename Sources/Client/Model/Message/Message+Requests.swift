//
//  Message+Requests.swift
//  StreamChatCore
//
//  Created by Alexey Bukhtin on 10/01/2020.
//  Copyright © 2020 Stream.io Inc. All rights reserved.
//

import Foundation

public extension Message {
    
    /// Delete the message.
    /// - Parameter completion: a completion block with `MessageResponse`.
    @discardableResult
    func delete(_ completion: @escaping Client.Completion<MessageResponse>) -> Cancellable {
        Client.shared.delete(message: self, completion)
    }
    
    /// Send a request for reply messages.
    /// - Parameters:
    ///   - pagination: a pagination (see `Pagination`).
    ///   - completion: a completion block with `[Message]`.
    @discardableResult
    func replies(pagination: Pagination, _ completion: @escaping Client.Completion<[Message]>) -> Cancellable {
        Client.shared.replies(for: self, pagination: pagination, completion)
    }
    
    // MARK: - Reactions
    
    /// Add a reaction to the message.
    /// - Parameters:
    ///   - type: a reaction type, e.g. like.
    ///   - completion: a completion block with `MessageResponse`.
    @discardableResult
    func addReaction(type: String,
                     score: Int,
                     extraData: Codable? = nil,
                     _ completion: @escaping Client.Completion<MessageResponse>) -> Cancellable {
        Client.shared.addReaction(type: type, score: score, extraData: extraData, to: self, completion)
    }
    
    /// Delete a reaction to the message.
    /// - Parameters:
    ///   - type: a reaction type, e.g. like.
    ///   - completion: a completion block with `MessageResponse`.
    @discardableResult
    func deleteReaction(type: String, _ completion: @escaping Client.Completion<MessageResponse>) -> Cancellable {
        Client.shared.deleteReaction(type: type, from: self, completion)
    }
    
    // MARK: Flag Message
    
    /// Flag a message.
    /// - Parameter completion: a completion block with `FlagMessageResponse`.
    @discardableResult
    func flag(_ completion: @escaping Client.Completion<FlagMessageResponse>) -> Cancellable {
        Client.shared.flag(message: self, completion)
    }
    
    /// Unflag a message.
    /// - Parameter completion: a completion block with `FlagMessageResponse`.
    @discardableResult
    func unflag(_ completion: @escaping Client.Completion<FlagMessageResponse>) -> Cancellable {
        Client.shared.unflag(message: self, completion)
    }
    
    // MARK: - Translations
    
    /// Get the message text translated in language
    /// Please call `translate` if this returns `nil` to get the message translated.
    /// - Parameters:
    ///   - locale: Destination locale. Defaults to `.current`
    /// - Returns: The translation if it exists, or nil. Please call `translate` if this returns `nil` to get the message translated.
    func translated(to locale: Locale = .current) -> String? {
        guard let language = Language(locale: locale) else {
            ClientLogger.log("❌", level: .error, "Translation for locale not supported: \(locale)")
            return nil
        }
        return translated(to: language)
    }
    
    /// Get the message text translated in language
    /// Please call `translate` if this returns `nil` to get the message translated.
    /// - Parameters:
    ///   - language: Destination language.
    /// - Returns: The translation if it exists, or nil. Please call `translate` if this returns `nil` to get the message translated.
    func translated(to language: Language) -> String? {
        guard let translation = i18n?.translated[language] else { return nil }
        return translation
    }
    
    /// Translate a message
    /// - Parameters:
    ///   - language: Destination language.
    ///   - completion: Completion block to be called with translated message text.
    /// - Returns: Cancellable to control the request.
    @discardableResult
    func translate(to language: Language,
                   _ completion: @escaping Client.Completion<String>) -> Cancellable {
        Client.shared.translate(message: self, to: language) { response in
            if let value = response.value {
                if let translated = value.message.i18n?.translated[language] {
                    completion(.success(translated))
                } else {
                    completion(.failure(.unexpectedError(description: "Translation not found. Please try again", error: nil)))
                }
            } else if let error = response.error {
                completion(.failure(error))
            }
        }
    }
    
    /// Translate a message
    /// - Parameters:
    ///   - locale: Destination locale. Defaults to `.current`
    ///   - completion: Completion block to be called with translated message text.
    /// - Returns: Cancellable to control the request.
    @discardableResult
    func translate(to locale: Locale = .current,
                   _ completion: @escaping Client.Completion<String>) -> Cancellable {
        guard let language = Language(locale: locale) else {
            completion(.failure(ClientError.unexpectedError(description: "Unsupported locale", error: nil)))
            return Subscription.empty
        }
        return translate(to: language, completion)
    }
    
    /// Translate a message
    /// - Parameters:
    ///   - language: Destination language.
    ///   - completion: Completion block to be called with translated message response.
    /// - Returns: Cancellable to control the request.
    @discardableResult
    func translate(to language: Language,
                   _ completion: @escaping Client.Completion<MessageResponse>) -> Cancellable {
        Client.shared.translate(message: self, to: language, completion)
    }
    
    /// Translate a message
    /// - Parameters:
    ///   - locale: Destination locale. Defaults to `.current`
    ///   - completion: Completion block to be called with translated message response.
    /// - Returns: Cancellable to control the request.
    @discardableResult
    func translate(to locale: Locale = .current,
                   _ completion: @escaping Client.Completion<MessageResponse>) -> Cancellable {
        guard let language = Language(locale: locale) else {
            completion(.failure(ClientError.unexpectedError(description: "Unsupported locale", error: nil)))
            return Subscription.empty
        }
        
        return translate(to: language, completion)
    }
}
