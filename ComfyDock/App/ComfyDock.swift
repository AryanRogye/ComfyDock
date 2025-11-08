//
//  ComfyDock.swift
//  ComfyDock
//
//  Created by Aryan Rogye on 10/30/25.
//

import SwiftUI
import DockKit
import Dock

@main
struct ComfyDock: App {
    
    @NSApplicationDelegateAdaptor(AppDelegate.self) var delegate
    
    let dock = Dock()
    
    var body: some Scene {
        WindowGroup {
            ComfyDockDebug(dock: dock, dockController: delegate.dockManager)
        }
    }
}
