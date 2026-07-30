//
//  DockExperimentApp.swift
//  DockExperiment
//
//  Created by Aryan Rogye on 7/29/26.
//

import SwiftUI

@main
struct DockExperimentApp: App {
    
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        WindowGroup {
            EmptyView().destroyViewWindow()
        }
    }
}
