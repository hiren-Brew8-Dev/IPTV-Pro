//
//  IPTVApp.swift
//  IPTV
//
//  Created by Hiren Lakhatariya on 04/02/26.
//

import CoreData
import SwiftUI

@main
struct IPTVApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            
            RootView()
                .environment(
                    \.managedObjectContext, persistenceController.container.viewContext)
        }
        
    }
}
