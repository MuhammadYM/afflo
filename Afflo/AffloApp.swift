//
//  AffloApp.swift
//  Afflo
//
//  Created by Muhammad M on 11/9/25.
//

import CoreData
import SwiftUI

@main
struct AffloApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
