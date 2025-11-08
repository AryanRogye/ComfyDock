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
    var dock : Dock = Dock()
    var runningApps: RunningAppsProviding = RunningAppsService()
}

@MainActor
class AppDelegate: NSObject, NSApplicationDelegate {
    
    let appEnv = AppEnv()
    let dock : Dock
    let dockController = DockManager()
    
    private var permissionManager : PermissionManager?
    
    private var center = NSWorkspace.shared.notificationCenter
    
    lazy var globalTracker = GlobalHoverTracker(dockController: dockController)
    lazy var dockOverlayCoordinator = DockOverlayCoordinator(dock: dockController)
    
    override init() {
        self.dock = appEnv.dock
        super.init()
        refreshNow()
        watchApps()
    }
    
    public func watchApps() {
        center.addObserver(self, selector: #selector(refreshNow), name: NSWorkspace.didLaunchApplicationNotification, object: nil)
        center.addObserver(self, selector: #selector(refreshNow), name: NSWorkspace.didTerminateApplicationNotification, object: nil)
        center.addObserver(self, selector: #selector(refreshNow), name: NSWorkspace.didActivateApplicationNotification, object: nil)
        center.addObserver(self, selector: #selector(refreshNow), name: NSWorkspace.didDeactivateApplicationNotification, object: nil)
        center.addObserver(self, selector: #selector(refreshNow), name: NSWorkspace.didHideApplicationNotification, object: nil)
        center.addObserver(self, selector: #selector(refreshNow), name: NSWorkspace.didUnhideApplicationNotification, object: nil)
    }
    
    @objc func refreshNow() {
        self.dockController.runningApps = appEnv.runningApps.getRunningApps()
    }
    
    
    public func applicationDidFinishLaunching(_ notification: Notification) {
        permissionManager = PermissionManager()
        guard let permissionManager else { return }
        
        permissionManager.onPermissionGranted = { [weak self] in
            self?.startApp()
        }
        
        // If already have permissions, start immediately
        if permissionManager.isAccessibilityEnabled {
            startApp()
        } else {
            print("⚠️ Waiting for accessibility permissions...")
            permissionManager.requestPermission()
        }
    }
    
    func startApp() {
        dock.hideDock()
        
        let onChange: (Bool) -> Void = { in_radius in
            if in_radius {
                self.dockOverlayCoordinator.show()
            } else {
                self.dockOverlayCoordinator.hide()
            }
        }
        
        globalTracker.lastOnChange = onChange
        globalTracker.startTracking(onChange)
    }
    
    public func applicationWillTerminate(_ notification: Notification) {
        dock.showDock()
        globalTracker.stop()
    }
    
    public func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return false
    }
}
