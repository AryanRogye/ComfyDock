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

@MainActor
class AppCoordinator {
    
    let windowCoordinator = WindowCoordinator()
    let dockCoordinator = DockCoordinator()
    let windowCore = WindowCore()
    let dockObserver: DockObserver
    var baseDockRect: CGRect?
    var dockRect: NSRect?
    var panel: NSPanel!
    let permissionService = PermissionService()
    private var mouseMovedMonitor: Any?
    
    var isInTrackingArea: Bool = false

    init() {
        if !permissionService.isAccessibilityEnabled {
            permissionService.requestPermission()
        }
        if !permissionService.isScreenRecordingEnabled {
            permissionService.requestScreenRecordingPermission()
        }

        self.dockObserver = DockObserver(windowCore: windowCore)
        self.dockObserver.onNoHover = { [weak self] in
            guard let self else { return }
            if self.isPointerInsidePanel() {
                self.isInTrackingArea = true
            } else {
                self.collapseToBaseDock()
            }
        }
        self.dockCoordinator.onDockRectFound = { [weak self] rect in
            guard let self else { return }
            self.loadBaseDockRect(rect)
        }
        self.dockObserver.onDockRectFound = { [weak self] rect in
            guard let self else { return }
            guard self.isPointerInsidePanel() else { return }
            self.isInTrackingArea = true
            self.load(self.stabilizedDockRect(rect))
        }
        Task {
            await self.windowCore.loadWindows()
            self.dockObserver.observeDock()
            try? await Task.sleep(for: .seconds(1))
            self.dockCoordinator.getCoreDockRect()
        }
    }

    deinit {
        if let mouseMovedMonitor {
            NSEvent.removeMonitor(mouseMovedMonitor)
        }
    }

    private func loadBaseDockRect(_ rect: CGRect) {
        baseDockRect = rect
        if !isInTrackingArea || panel == nil {
            load(rect)
        }
    }
    
    private func load(_ rect: CGRect) {
        self.dockRect = rect
        if panel != nil {
            self.panel.setFrame(rect.convertToAppKit(), display: true)
        } else {
            setupPanel()
        }
    }

    private func stabilizedDockRect(_ observedRect: CGRect) -> CGRect {
        guard let baseDockRect else { return observedRect }
        return baseDockRect.union(observedRect)
    }

    private func collapseToBaseDock() {
        isInTrackingArea = false
        guard let baseDockRect else {
            dockCoordinator.getCoreDockRect()
            return
        }
        load(baseDockRect)
    }

    private func isPointerInsidePanel() -> Bool {
        panel?.frame.contains(NSEvent.mouseLocation) == true
    }

    private func startMouseTracking() {
        guard mouseMovedMonitor == nil else { return }
        mouseMovedMonitor = NSEvent.addGlobalMonitorForEvents(
            matching: [.mouseMoved, .leftMouseDragged, .rightMouseDragged]
        ) { [weak self] _ in
            Task { @MainActor in
                guard let self else { return }
                let isInside = self.isPointerInsidePanel()
                if isInside {
                    self.isInTrackingArea = true
                } else if self.isInTrackingArea {
                    self.collapseToBaseDock()
                }
            }
        }
    }
    
    public func setupPanel() {
        guard let dockRect else { return }
        panel = FocusablePanel(
            contentRect: .zero,
            styleMask: [.borderless, .nonactivatingPanel, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        panel.setFrame(dockRect.convertToAppKit(), display: true)
        panel.contentView?.wantsLayer = true
        panel.acceptsMouseMovedEvents = true
        
        let overlayRaw = CGWindowLevelForKey(.overlayWindow)
        panel.level = NSWindow.Level(rawValue: Int(overlayRaw))
        
        panel.collectionBehavior = [
            .canJoinAllSpaces,
            .fullScreenAuxiliary,
            .fullScreenDisallowsTiling,
            .ignoresCycle,
            .transient
        ]
        
        panel.isMovableByWindowBackground = false
        panel.backgroundColor = .clear
        panel.isOpaque = false
        panel.hasShadow = false
        panel.becomesKeyOnlyIfNeeded = true
        panel.hidesOnDeactivate = false
        panel.animationBehavior = .none
        panel.ignoresMouseEvents = true
        
        let view = NSHostingView(
            rootView: DockPreviewView()
        )
        
        view.wantsLayer = true
        view.layer?.masksToBounds = false
        
        panel.contentView = view
        panel.makeKeyAndOrderFront(nil)
        startMouseTracking()
    }
    
    public static func screenUnderMouse() -> NSScreen? {
        let loc = NSEvent.mouseLocation
        return NSScreen.screens.first {
            NSMouseInRect(loc, $0.frame, false)
        }
    }
}


struct DockPreviewView: View {
    var body: some View {
        VStack {
            
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .border(.yellow, width: 1)
    }
}
