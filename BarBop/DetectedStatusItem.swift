//
//  DetectedStatusItem.swift
//  BarBop
//
//  Created by Codex on 7/13/26.
//

import Foundation

struct DetectedStatusItem: Identifiable, Codable, Equatable {
    let id: String
    var bundleIdentifier: String?
    var applicationName: String?
    var itemTitle: String?
    var accessibilityIdentifier: String?
    var lastDetectedAt: Date
}

extension DetectedStatusItem {
    init(resolution: StatusItemResolution, detectedAt: Date = Date()) {
        self.init(
            id: resolution.identity,
            bundleIdentifier: resolution.bundleIdentifier,
            applicationName: resolution.applicationName,
            itemTitle: resolution.title,
            accessibilityIdentifier: resolution.accessibilityIdentifier,
            lastDetectedAt: detectedAt
        )
    }
}
