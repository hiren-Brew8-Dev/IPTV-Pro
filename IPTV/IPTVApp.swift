//
//  IPTVApp.swift
//  IPTV
//
//  Created by Hiren Lakhatariya on 04/02/26.
//

import SwiftUI
import CoreData

@main
struct IPTVApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
