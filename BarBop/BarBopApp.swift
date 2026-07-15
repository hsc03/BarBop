//
//  BarBopApp.swift
//  BarBop
//
//  Created by 황성철 on 7/7/26.
//

import SwiftUI

@main
struct BarBopApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        Settings {
            EmptyView()
        }
        .commands {
            CommandGroup(replacing: .appSettings) { }
        }
    }
}
