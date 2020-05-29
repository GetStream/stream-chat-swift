//
// ChatClient.swift
// Copyright © 2020 Stream.io Inc. All rights reserved.
//

import CoreData
import Foundation

/// If you want to use your custom extra data types to extend `UserModel`, `MessageModel`, or `ChannelModel`,
/// you can use this protocol to set up `Client` with it.
///
/// Example usage:
/// ```
///   enum CustomDataTypes: ExtraDataTypes {
///     typealias Channel = MyCustomChannelExtraData
///     typealias Message = MyCustomMessageExtraData
///   }
///
///   let client = Client<CustomDataTypes>(currentUser: user, config: config)
/// ```
///
/// Additionally, you can introduce the following type aliases in your module to make the work with generic
/// models more convenient:
/// ```
///  typealias Channel = ChannelModel<CustomDataTypes>
///  typealias Message = MessageModel<CustomDataTypes>
/// ```
///
public protocol ExtraDataTypes {
  associatedtype User: Codable & Hashable = NameAndAvatarUserData
  associatedtype Message: Codable & Hashable = NoExtraMessageData
  associatedtype Channel: Codable & Hashable = NoExtraChannelData
}

/// A concrete implementation of `ExtraDataTypes` with the default values.
public struct DefaultDataTypes: ExtraDataTypes {}

/// A convenience typealias for `Client` with the default data types.
public typealias ChatClient = Client<DefaultDataTypes>

/// The root object representing a Stream Chat.
///
/// If you don't need to specify your custom extra data types for `User`, `Channel`, or `Message`, use the convenient non-generic
/// typealias `ChatClient` which specifies the default extra data types.
///
public final class Client<ExtraData: ExtraDataTypes> {
  // MARK: - Public

  public let currentUser: UserModel<ExtraData.User>

  public let config: ChatClientConfig

  public let callbackQueue: DispatchQueue

  public convenience init(currentUser: UserModel<ExtraData.User>, config: ChatClientConfig, callbackQueue: DispatchQueue? = nil) {
    // All production workers
    let workerBuilders: [WorkerBuilder] = [
      MessageSender.init,
      ChannelEventsHandler<ExtraData>.init
    ]

    self.init(
      currentUser: currentUser,
      config: config,
      workerBuilders: workerBuilders,
      callbackQueue: callbackQueue ?? DispatchQueue(label: "io.getstream.chat.core.mainCallbackQueue"),
      environment: .init()
    )
  }

  // MARK: - Internal

  struct Environment {
    var apiClientBuilder: (_ apiKey: String, _ baseURL: URL, _ sessionConfiguration: URLSessionConfiguration)
      -> APIClient = APIClient.init
    var webSocketClientBuilder: (_ urlRequest: URLRequest, _ eventDecoder: AnyEventDecoder, _ callbackQueue: DispatchQueue)
      -> WebSocketClient = { WebSocketClient(urlRequest: $0, eventDecoder: $1, callbackQueue: $2) }
    var databaseContainerBuilder: (_ kind: DatabaseContainer.Kind) throws
      -> DatabaseContainer = { try DatabaseContainer(kind: $0) }
  }

  private var backgroundWorkers: [Worker]!

  private(set) lazy var apiClient: APIClient = self.environment
    .apiClientBuilder(self.config.apiKey, self.baseURL.baseURL, self.urlSessionConfiguration)

  private(set) lazy var webSocketClient: WebSocketClient = {
    let jsonParameter = WebSocketPayload<ExtraData>(user: self.currentUser, token: token)

    var urlComponents = URLComponents()
    urlComponents.scheme = baseURL.wsURL.scheme
    urlComponents.host = baseURL.wsURL.host
    urlComponents.path = baseURL.wsURL.path.appending("connect")
    urlComponents.queryItems = [URLQueryItem(name: "api_key", value: config.apiKey)]

//      if user.isAnonymous {
//          urlComponents.queryItems?.append(URLQueryItem(name: "stream-auth-type", value: "anonymous"))
//      } else {
    urlComponents.queryItems?.append(URLQueryItem(name: "authorization", value: token))
    urlComponents.queryItems?.append(URLQueryItem(name: "stream-auth-type", value: "jwt"))
    //      }

    let jsonData = try! JSONEncoder.default.encode(jsonParameter)

    if let jsonString = String(data: jsonData, encoding: .utf8) {
      urlComponents.queryItems?.append(URLQueryItem(name: "json", value: jsonString))
    } else {
      //          logger?.log("❌ Can't create a JSON parameter string from the json: \(jsonParameter)", level: .error)
    }

    guard let url = urlComponents.url else {
      fatalError()
      //          logger?.log("❌ Bad URL: \(urlComponents)", level: .error)
      //          throw ClientError.invalidURL(urlComponents.description)
    }

    var request = URLRequest(url: url)
    request.allHTTPHeaderFields = authHeaders(token: token)

    //      let callbackQueue = DispatchQueue(label: "io.getstream.Chat.WebSocket", qos: .userInitiated)
    //      let webSocketOptions: WebSocketOptions = [] // = stayConnectedInBackground ? WebSocketOptions.stayConnectedInBackground : []
    //      let webSocketProvider = defaultWebSocketProviderType.init(request: request, callbackQueue: callbackQueue)

    return WebSocketClient(
      urlRequest: request,
      eventDecoder: EventDecoder<ExtraData>(),
      callbackQueue: callbackQueue
    )
  }()

  private(set) lazy var persistentContainer: DatabaseContainer = {
    do {
      if config.isLocalStorageEnabled {
        guard let storeURL = config.localStorageFolderURL else {
          throw ClientError.MissingLocalStorageURL()
        }

        // Create the folder if needed
        try? FileManager.default.createDirectory(
          at: config.localStorageFolderURL!,
          withIntermediateDirectories: true,
          attributes: nil
        )
        let dbFileURL = config.localStorageFolderURL!.appendingPathComponent(currentUser.id)
        return try environment.databaseContainerBuilder(.onDisk(databaseFileURL: dbFileURL))
      }

      // Example error handling:

    } catch let error as ClientError.MissingLocalStorageURL {
      assertionFailure("The URL provided in ChatClientConfig can't be `nil`.")

    } catch {
      let handledError = ClientError.Unexpect(underlyingError: error)
      let handledError2 = ClientError.Unexpect("Something went wrong...")
      // TODO: Log
      print("Failed to initalized the local storage with error: \(error). Falling back to the in-memory option.")
    }

    do {
      return try environment.databaseContainerBuilder(.inMemory)
    } catch {
      fatalError("Failed to initialize the in-memory storage with erorr: \(error). This is a non-recoverable error.")
    }
  }()

  private let environment: Environment

  init(
    currentUser: UserModel<ExtraData.User>,
    config: ChatClientConfig,
    workerBuilders: [WorkerBuilder],
    callbackQueue: DispatchQueue,
    environment: Environment
  ) {
    self.config = config
    self.currentUser = currentUser
    self.environment = environment
    self.callbackQueue = callbackQueue

    apiClient.connectionIdProvider = webSocketClient

    self.backgroundWorkers = workerBuilders.map { builder in
      builder(self.persistentContainer, self.webSocketClient, self.apiClient)
    }
  }
}

// MARK: ========= TEMPORARY!

extension Client {
  var baseURL: BaseURL { .dublin }
  var token: String {
    "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJ1c2VyX2lkIjoiYnJva2VuLXdhdGVyZmFsbC01In0.d1xKTlD_D0G-VsBoDBNbaLjO-2XWNA8rlTm4ru4sMHg"
  }

  var urlSessionConfiguration: URLSessionConfiguration {
    let headers = authHeaders(token: token)
    let config = URLSessionConfiguration.default
    config.waitsForConnectivity = true
    config.httpAdditionalHeaders = headers
    return config
  }

  func authHeaders(token: String) -> [String: String] {
    var headers = [
      "X-Stream-Client": "stream-chat-swift-client-\(SystemEnvironment.version)",
      "X-Stream-Device": SystemEnvironment.deviceModelName,
      "X-Stream-OS": SystemEnvironment.systemName,
      "X-Stream-App-Environment": SystemEnvironment.name
    ]

    //      if token.isBlank || user.isAnonymous {
    //          headers["Stream-Auth-Type"] = "anonymous"
    //      } else {
    headers["Stream-Auth-Type"] = "jwt"
    headers["Authorization"] = token
    //      }

    if let bundleId = Bundle.main.id {
      headers["X-Stream-BundleId"] = bundleId
    }

    return headers
  }
}

extension ClientError {
  // An example of a simple error
  public class MissingLocalStorageURL: ClientError {
    public let localizedDescription: String = "The URL provided in ChatClientConfig is `nil`."
  }
}
