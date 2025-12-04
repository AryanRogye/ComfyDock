//
//  AppCoordinator.swift
//  ComfyDock
//
//  Created by Aryan Rogye on 11/8/25.
//

import Dock
import SwiftUI

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
    let dockOverlayCoordinator : DockOverlayCoordinator
    let tempCoordinator        : TempCoordinator

    init(appEnv : AppEnv) {
        /// Initialize Services
        self.runningAppsFetcher = appEnv.runningAppFetcher
        self.dockControls = appEnv.dockControls

        /// Initialize Managers
        self.dockManager = DockManager()
        self.audioManager = AudioManager()
        self.permissionManager = PermissionManager()
        
        self.dockOverlayCoordinator = DockOverlayCoordinator(dockControls: dockControls, dockManager: dockManager, audioManager: audioManager)
        self.tempCoordinator = TempCoordinator()
        
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
//        observeContextMenuDismissal()
        
        Task {
            try await dockControls.startPolling { rect in
                print("Showing Temp Coordinator With: \(rect)")
                self.tempCoordinator.show(with: rect.toWindowSpace(using: NSScreen.main).makeAllValuesPositive())
            }
        }
        
//        let onChange: (Bool) -> Void = { in_radius in
//            self.lastWasIn = in_radius
//            if in_radius {
//                if self.dockManager.rightClickApp == nil {
        /// Just Show for now
//        self.dockOverlayCoordinator.show()
//                }
//            } else {
//                /// If No App Is getting right clicked
//                if self.dockManager.rightClickApp == nil {
//                    self.dockOverlayCoordinator.hide()
//                }
//            }
//        }
        
        /**
         * This is useful for re-triggering the tracker
         * Would only be called on observation
         */
//        globalTracker.lastOnChange = onChange
//        globalTracker.startTracking(onChange)
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
    
//    /**
//     * This Configuration is very important, when we right click a app, it will
//     * show something, when that app is set back to nil, our mouse might be "off"
//     * of the set strip in the global tracker, that means we can just hide the dock
//     * This is dependent, on OnChange setting the lastWasIn property in `startApp()`
//     */
//    func observeContextMenuDismissal() {
//        withObservationTracking {
//            _ = dockManager.rightClickApp
//        } onChange: {
//            DispatchQueue.main.async {
//                if self.dockManager.rightClickApp == nil {
//                    print("Right Click App Set Nil")
//                    /// check if the last was a false
//                    /// Get A Instant Value
//                    
//                    let insideNow = self.globalTracker.isMouseInZoneInstantaneously()
//                    if insideNow != self.lastWasIn {
//                        if insideNow {
//                            self.dockOverlayCoordinator.show()
//                        } else {
//                            self.dockOverlayCoordinator.hide()
//                        }
//                    }
//                }
//                self.observeContextMenuDismissal()
//            }
//        }
//    }
}


final class TempCoordinator : NSObject {
    
    var panel : NSPanel?
    
    override init() {
        super.init()
    }
    
    // MARK: - Show / Hide
    func show(with rect: CGRect) {
        print("📍 Showing panel at rect: \(rect)")
        print("📍 Screen bounds: \(NSScreen.main?.frame ?? .zero)")
        
        if panel == nil {
            createPanel(with: rect)
        } else {
            panel?.setFrame(rect, display: true, animate: false)
        }
        panel?.orderFrontRegardless()
        
        // Verify panel is actually visible
        print("📍 Panel isVisible: \(panel?.isVisible ?? false)")
        print("📍 Panel frame: \(panel?.frame ?? .zero)")
    }
    
    public func hide() {
        panel?.orderOut(nil)
    }
    
    // MARK: - Core
    public func createPanel(with rect: CGRect) {
        let p = FocusablePanel(
            contentRect: rect,
            styleMask: [.borderless, .nonactivatingPanel, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        p.setFrame(rect, display: true)
        
        p.contentView?.wantsLayer = true
        p.acceptsMouseMovedEvents = true
        
        let overlayRaw = CGWindowLevelForKey(.overlayWindow)
        p.level = NSWindow.Level(rawValue: Int(overlayRaw))
        
        p.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        p.isMovableByWindowBackground = false
        
        p.backgroundColor = .clear
        p.isOpaque = false
        p.hasShadow = false
        
        let view : NSView = NSHostingView(
            rootView: TempView()
//                DockView(dockControls: dockControls, dockManager: dockManager, audioManager: audioManager)
        )
        
        view.wantsLayer = true
        view.layer?.masksToBounds = true
        
        p.contentView = view
        
        self.panel = p
        print("Created Panel")
    }
}

struct TempView: View {
    var body: some View {
        RoundedRectangle(cornerRadius: 12)
            .fill(Color.red.opacity(0.4))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.white, lineWidth: 2)
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

extension CGRect {
    
    func makeAllValuesPositive() -> CGRect {
        return CGRect(
            x: abs(self.minX),
            y: abs(self.minY),
            width: abs(self.width),
            height: abs(self.height)
        )
    }
    
    func toWindowSpace(using screen: NSScreen?) -> CGRect {
        guard let screen = screen else { return self }
        let screenHeight = screen.frame.height
        
        return CGRect(
            x: origin.x,
            y: screenHeight - origin.y - height,
            width: width,
            height: height
        )
    }
}
