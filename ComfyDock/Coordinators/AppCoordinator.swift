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
    
    private var lastWasIn: Bool = false
    
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
        observeContextMenuDismissal()
        dockControls.hideDock()
        
        let onChange: (Bool) -> Void = { in_radius in
            self.lastWasIn = in_radius
            if in_radius {
                if self.dockManager.rightClickApp == nil {
                    self.dockOverlayCoordinator.show()
                }
            } else {
                /// If No App Is getting right clicked
                if self.dockManager.rightClickApp == nil {
                    self.dockOverlayCoordinator.hide()
                }
            }
        }
        
        /**
         * This is useful for re-triggering the tracker
         * Would only be called on observation
         */
        globalTracker.lastOnChange = onChange
        globalTracker.startTracking(onChange)
    }
    
}


// MARK: - Observing
extension AppCoordinator {
    
    /**
     * System Notifications for "Refreshing Our Internal, Dock"
     */
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
    
    /**
     * This Configuration is very important, when we right click a app, it will
     * show something, when that app is set back to nil, our mouse might be "off"
     * of the set strip in the global tracker, that means we can just hide the dock
     * This is dependent, on OnChange setting the lastWasIn property in `startApp()`
     */
    func observeContextMenuDismissal() {
        withObservationTracking {
            _ = dockManager.rightClickApp
        } onChange: {
            DispatchQueue.main.async {
                if self.dockManager.rightClickApp == nil {
                    print("Right Click App Set Nil")
                    /// check if the last was a false
                    /// Get A Instant Value
                    
                    let insideNow = self.globalTracker.isMouseInZoneInstantaneously()
                    if insideNow != self.lastWasIn {
                        if insideNow {
                            self.dockOverlayCoordinator.show()
                        } else {
                            self.dockOverlayCoordinator.hide()
                        }
                    }
                }
                self.observeContextMenuDismissal()
            }
        }
    }
}
