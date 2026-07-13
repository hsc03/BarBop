//
//  AppEnvironment.swift
//  BarBop
//
//  Created by Codex on 7/13/26.
//

import Foundation

final class AppEnvironment {
    static let shared = AppEnvironment()

    let characterStore: CharacterStore
    let assignmentStore: AssignmentStore

    init(
        characterStore: CharacterStore = CharacterStore(),
        assignmentStore: AssignmentStore = AssignmentStore()
    ) {
        self.characterStore = characterStore
        self.assignmentStore = assignmentStore
    }
}
