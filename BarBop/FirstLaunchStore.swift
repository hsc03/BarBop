//
//  FirstLaunchStore.swift
//  BarBop
//
//  Created by Codex on 7/14/26.
//

import Foundation

final class FirstLaunchStore {
    private let userDefaults: UserDefaults
    private let presentationKey: String

    init(
        userDefaults: UserDefaults = .standard,
        presentationKey: String = "BarBop.HasPresentedInitialSettings"
    ) {
        self.userDefaults = userDefaults
        self.presentationKey = presentationKey
    }

    var shouldPresentInitialSettings: Bool {
        !userDefaults.bool(forKey: presentationKey)
    }

    func markInitialSettingsPresented() {
        userDefaults.set(true, forKey: presentationKey)
    }
}
