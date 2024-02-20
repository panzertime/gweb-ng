//
//  gAppApp.swift
//  gApp
//
//

import SwiftUI
import SwiftData

@main
struct gAppApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
           // Item.self, dummy from the sample app
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(sharedModelContainer)
    }
}
