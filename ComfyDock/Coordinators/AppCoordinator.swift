//
//  AppCoordinator.swift
//  ComfyDock
//
//  Created by Aryan Rogye on 11/8/25.
//

import Dock

@MainActor
final class AppCoordinator {
    
    /// Services
    let runningAppsFetcher : RunningAppsProviding
    let dockControls       : DockControls
    lazy var globalTracker = GlobalHoverTracker(dockController: dockManager)

    /// Managers
    let dockManager         : DockManager
    let audioManager        : AudioManager
    let permissionManager   : PermissionManager
    
    
    /// Coorinatonrs
    lazy var dockOverlayCoordinator = DockOverlayCoordinator(dockManager: dockManager, audioManager: audioManager)

    init(appEnv : AppEnv) {
        /// Initialize Services
        self.runningAppsFetcher = appEnv.runningAppFetcher
        self.dockControls = appEnv.dockControls

        /// Initialize Managers
        self.dockManager = DockManager()
        self.audioManager = AudioManager()
        self.permissionManager = PermissionManager()
        
        
        refreshNow()
        watchApps()
    }
    
    func start() {
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
    
    func stop() {
        dockControls.showDock()
        globalTracker.stop()
    }
    
    func startApp() {
        dockControls.hideDock()
        
        let onChange: (Bool) -> Void = { in_radius in
            if in_radius {
                self.dockOverlayCoordinator.show()
            } else {
                if self.dockManager.isHoveringOverXcodeRects { return }
                self.dockOverlayCoordinator.hide()
            }
        }
        
        globalTracker.lastOnChange = onChange
        globalTracker.startTracking(onChange)
    }
}


// MARK: - Observing
extension AppCoordinator {
    public func watchApps() {
        NSWorkspace.shared.notificationCenter.addObserver(self, selector: #selector(refreshNow), name: NSWorkspace.didLaunchApplicationNotification, object: nil)
        NSWorkspace.shared.notificationCenter.addObserver(self, selector: #selector(refreshNow), name: NSWorkspace.didTerminateApplicationNotification, object: nil)
        NSWorkspace.shared.notificationCenter.addObserver(self, selector: #selector(refreshNow), name: NSWorkspace.didActivateApplicationNotification, object: nil)
        NSWorkspace.shared.notificationCenter.addObserver(self, selector: #selector(refreshNow), name: NSWorkspace.didDeactivateApplicationNotification, object: nil)
        NSWorkspace.shared.notificationCenter.addObserver(self, selector: #selector(refreshNow), name: NSWorkspace.didHideApplicationNotification, object: nil)
        NSWorkspace.shared.notificationCenter.addObserver(self, selector: #selector(refreshNow), name: NSWorkspace.didUnhideApplicationNotification, object: nil)
    }
    
    @objc func refreshNow() {
        self.dockManager.runningApps = runningAppsFetcher.getRunningApps()
    }
}
