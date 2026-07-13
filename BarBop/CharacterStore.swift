//
//  CharacterStore.swift
//  BarBop
//
//  Created by Codex on 7/13/26.
//

import Foundation

final class CharacterStore {
    var characters: [Character] {
        Character.builtInCharacters
    }

    func character(for id: UUID) -> Character {
        characters.first { $0.id == id } ?? Character.builtInCharacters[0]
    }
}
