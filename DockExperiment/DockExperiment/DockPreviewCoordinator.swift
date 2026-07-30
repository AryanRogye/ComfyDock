//
//  DockPreviewCoordinator.swift
//  DockExperiment
//
//  Created by Aryan Rogye on 7/30/26.
//

import AppKit
import SwiftUI

@MainActor
final class DockPreviewCoordinator {
    
    /// Main Panel Holding Content To Preview Border Around Dock
    var panel: NSPanel!
    var dockRect: NSRect?
    var baseDockRect: CGRect?
    private var mouseMovedMonitor: Any?
    private var isDockMenuOpen = false
    private var isInTrackingArea: Bool = false
    
    // this should trigger
    var onGetCoreDockRect: (() -> Void)?
    
    init() {
        
    }
    
    deinit {
        if let mouseMovedMonitor {
            NSEvent.removeMonitor(mouseMovedMonitor)
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
    
    private func startMouseTracking() {
        guard mouseMovedMonitor == nil else { return }
        mouseMovedMonitor = NSEvent.addGlobalMonitorForEvents(
            matching: [.mouseMoved, .leftMouseDragged, .rightMouseDragged]
        ) { [weak self] _ in
            Task { @MainActor in
                guard let self else { return }
                let isInside = self.isPointerInsidePanel()
                if isInside || self.isDockMenuOpen {
                    self.isInTrackingArea = true
                } else if self.isInTrackingArea {
                    self.collapseToBaseDock()
                }
            }
        }
    }
    
    private func collapseToBaseDock() {
        isInTrackingArea = false
        guard let baseDockRect else {
            onGetCoreDockRect?()
            return
        }
        load(baseDockRect)
    }
    
    private func isPointerInsidePanel() -> Bool {
        panel?.frame.contains(NSEvent.mouseLocation) == true
    }
}

// MARK: - Event Handling
extension DockPreviewCoordinator {
    /// Called when the pointer is no longer hovering over a Dock item.
    ///
    /// We check two conditions before collapsing the preview:
    /// 1. Whether a Dock menu (such as a context menu) is currently open.
    /// 2. Whether the mouse is still inside our preview panel.
    ///
    /// If either condition is true, we preserve the current expanded state.
    /// Otherwise, we collapse back to the base (non-magnified) Dock bounds.
    public func dockObserverDidCallNoHover() {
        if self.isDockMenuOpen || self.isPointerInsidePanel() {
            self.isInTrackingArea = true
        } else {
            self.collapseToBaseDock()
        }
    }
    
    /// Combines the observed magnified Dock bounds with the base Dock bounds.
    ///
    /// The observed rect only covers the currently magnified tiles. Taking the
    /// union preserves the full Dock area while expanding to include the
    /// magnified region, preventing the preview from shrinking around the
    /// hovered icons.
    public func dockObserverDidReceiveMagnifiedBoundsChanged(_ rect: CGRect) {
        guard self.isPointerInsidePanel() else { return }
        self.isInTrackingArea = true
        self.onGetCoreDockRect?()
        
        let rectToView: CGRect
        if let baseDockRect {
            rectToView = baseDockRect.union(rect)
        } else {
            rectToView = rect
        }
        
        self.load(rectToView)
    }
    
    /// Called when a context menu is opened or closed in the observed Dock.
    ///
    /// Opening a menu keeps the preview expanded. Once the menu closes, the
    /// preview collapses only if the pointer is no longer inside the panel.
    public func dockObserverDidReceiveDockMenuVisibilityChanged(isOpen: Bool) {
        self.isDockMenuOpen = isOpen
        
        if isOpen {
            self.isInTrackingArea = true
            self.onGetCoreDockRect?()
        } else if !self.isPointerInsidePanel() {
            self.collapseToBaseDock()
        }
    }
    
    /// Called when the base Dock bounds are found.
    ///
    /// These bounds represent the Dock in its non-magnified state.
    ///
    /// We only update the preview if the pointer is not currently hovering
    /// over the Dock, or if the preview panel has not been created yet.
    public func dockCoordinatorDidFindBaseDock(_ rect: CGRect) {
        baseDockRect = rect
        if !isInTrackingArea || panel == nil {
            load(rect)
        }
    }
}

public func screenUnderMouse() -> NSScreen? {
    let loc = NSEvent.mouseLocation
    return NSScreen.screens.first {
        NSMouseInRect(loc, $0.frame, false)
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
