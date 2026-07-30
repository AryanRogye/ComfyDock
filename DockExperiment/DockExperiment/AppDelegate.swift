//
//  AppDelegate.swift
//  DockExperiment
//
//  Created by Aryan Rogye on 7/29/26.
//

import AppKit
import SwiftUI

class AppDelegate: NSObject, NSApplicationDelegate {
    
    var appCoordinator: AppCoordinator?
    
    public func applicationDidFinishLaunching(_ notification: Notification) {
        appCoordinator = AppCoordinator()
    }
    
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows: Bool) -> Bool {
        return true
    }
    
    public func applicationWillTerminate(_ notification: Notification) {
    }
    
    public func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return false
    }
}
