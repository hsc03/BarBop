//
//  AppEnvironment.swift
//  BarBop
//
//  Created by Codex on 7/13/26.
//

import Foundation

final class AppEnvironment {
    static let shared = AppEnvironment()

    let effectSettingsStore: EffectSettingsStore

    init(
        effectSettingsStore: EffectSettingsStore = EffectSettingsStore()
    ) {
        self.effectSettingsStore = effectSettingsStore
    }
}
