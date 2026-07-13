//
//  Character.swift
//  BarBop
//
//  Created by Codex on 7/13/26.
//

import Foundation

struct Character: Identifiable, Codable, Equatable {
    enum Source: Codable, Equatable {
        case builtIn(resourceName: String)
        case imported(relativePath: String)
    }

    enum MediaType: String, Codable {
        case png
        case gif
    }

    let id: UUID
    var name: String
    var source: Source
    var mediaType: MediaType
}

extension Character {
    static let placeholderID = UUID(uuidString: "8D27A5F3-2E2B-4F25-90D3-1F56D5B77501")!

    static let builtInCharacters: [Character] = [
        Character(
            id: placeholderID,
            name: "Placeholder",
            source: .builtIn(resourceName: "placeholder"),
            mediaType: .png
        )
    ]
}
