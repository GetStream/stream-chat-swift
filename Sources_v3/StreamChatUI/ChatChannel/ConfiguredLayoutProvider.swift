//
// Copyright © 2020 Stream.io Inc. All rights reserved.
//

import Foundation

/// Object responsible for calculation of view sizes + frames of its subviews
/// Shouldn't be used. Only subclassed.
open class ConfiguredLayoutProvider<ExtraData: UIExtraDataTypes> {
    var parent: ConfiguredLayoutProvider<ExtraData>?
    private var _uiConfig: UIConfig<ExtraData>?
    var uiConfig: UIConfig<ExtraData> {
        get {
            _uiConfig ?? parent?.uiConfig ?? UIConfig<ExtraData>.default
        }
        set {
            _uiConfig = newValue
        }
    }

    init(uiConfig: UIConfig<ExtraData>? = nil, parent: ConfiguredLayoutProvider<ExtraData>? = nil) {
        _uiConfig = uiConfig
        self.parent = parent
    }
}
