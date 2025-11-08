//
//  AppDelegate.swift
//  ComfyDock
//
//  Created by Aryan Rogye on 11/7/25.
//

import SwiftUI
import AppKit
import Dock

struct AppEnv {
    var dockControls : DockControls = DockControls()
    var runningAppFetcher: RunningAppsProviding = RunningAppsService()
}

@MainActor
class AppDelegate: NSObject, NSApplicationDelegate {
    
    /// Coordinates what goes on in the app
    let appCoordinator : AppCoordinator
    
    /// Everything the app needs to run
    let appEnv = AppEnv()
    
    override init() {
        appCoordinator = AppCoordinator(appEnv: appEnv)
    }
    
    public func applicationDidFinishLaunching(_ notification: Notification) {
        appCoordinator.start()
    }
    
    
    public func applicationWillTerminate(_ notification: Notification) {
        appCoordinator.stop()
    }
    
    public func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return false
    }
}
