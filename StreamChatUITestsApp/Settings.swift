//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import Foundation

enum Setting: String, CaseIterable {
    case showsConnectivity
    case setConnectivity
    case isConnected
    case isLocalStorageEnabled
    case staysConnectedInBackground
}

struct SettingValue {
    var setting: Setting
    var isOn: Bool
}

struct Settings {

    // Connectivity
    var showsConnectivity = SettingValue(setting: .showsConnectivity, isOn: false)
    var setConnectivity = SettingValue(setting: .setConnectivity, isOn: false)
    var isConnected = SettingValue(setting: .isConnected, isOn: true)

    // Config
    var isLocalStorageEnabled = SettingValue(setting: .isLocalStorageEnabled, isOn: false)
    var staysConnectedInBackground = SettingValue(setting: .staysConnectedInBackground, isOn: false)

    var all: [SettingValue] {
        [
            isLocalStorageEnabled,
            staysConnectedInBackground,
            showsConnectivity,
            setConnectivity,
            isConnected
        ]
    }

    mutating func updateSetting(with value: String?, isOn: Bool) {
        guard var setting = all.first(where: { $0.setting.rawValue == value }) else { return }
        setting.isOn = isOn
        setSetting(setting)
    }

    mutating func setSetting(_ setting: SettingValue) {
        switch setting.setting {
        case .setConnectivity:
            setConnectivity = setting
        case .isConnected:
            isConnected = setting
        case .showsConnectivity:
            showsConnectivity = setting
        case .isLocalStorageEnabled:
            isLocalStorageEnabled = setting
        case .staysConnectedInBackground:
            staysConnectedInBackground = setting
        }
    }
}
