//
// Copyright © 2020 Stream.io Inc. All rights reserved.
//

import SwiftUI

public struct ChatClientKey<ExtraData: ExtraDataTypes>: EnvironmentKey {
    public typealias Value = _ChatClient<ExtraData>
    public static var defaultValue: Value { Value(config: .init(apiKeyString: "Set chatClient value!")) }
}
