//
//  AffloApp.swift
//  Afflo
//
//  Created by Muhammad M on 11/9/25.
//

import SwiftUI
import CoreData

@main
struct AffloApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            AuthView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
