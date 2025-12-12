//
//  focusTrackerApp.swift
//  focusTracker
//
//  Created by Hugo Peyron on 12/12/2025.
//

import SwiftUI
import SwiftData

@main
struct FocusTrackerApp: App {
    var body: some Scene {
        WindowGroup {
            FocusTrackerView()
        }
        .modelContainer(for: [Activity.self, FocusSession.self])
    }
}
