//
//  EulaApp.swift
//  Eula
//
//  Created by Zhan Si on 2/12/26.
//

import SwiftUI
import CoreData

@main
struct EulaApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
