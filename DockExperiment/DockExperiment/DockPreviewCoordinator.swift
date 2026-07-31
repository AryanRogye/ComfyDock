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
    
    let audioManager: AudioManager
    
    /// Main Panel Holding Content To Preview Border Around Dock
    var dockPanel: NSPanel!
    var dockUIPanel: NSPanel!
    var dockRect: NSRect?
    var baseDockRect: CGRect?
    private var lastExpandedDockRect: CGRect?
    private var mouseMovedMonitor: Any?
    private var dockMenuDismissalTask: Task<Void, Never>?
    private var isDockMenuInteractionActive = false
    private var isInTrackingArea: Bool = false
    
    // this should trigger
    var onGetCoreDockRect: (() -> Void)?
    
    private let leadingDockUIPadding: CGFloat = 10
    private let trailingDockUIPadding: CGFloat = 5
    private var animationGeneration: UInt64 = 0
    
    init(audioManager: AudioManager) {
        self.audioManager = audioManager
    }
    
    deinit {
        dockMenuDismissalTask?.cancel()
        if let mouseMovedMonitor {
            NSEvent.removeMonitor(mouseMovedMonitor)
        }
    }
    
    private func load(_ rect: CGRect) {
        self.dockRect = rect
        if dockPanel != nil {
            let dockPanelRect = rect.convertToAppKit()
            guard let screen = NSScreen.screen(containing: dockPanelRect) else {
                return
            }

            self.dockPanel.setFrame(dockPanelRect, display: true)
            var dockUIPanelRect = createDockUIRect(from: dockPanelRect, in: screen)
            // we will keep the baseDockRect height tho
            dockUIPanelRect.size.height = baseDockRect?.height ?? dockUIPanelRect.size.height
            
            let startFrame = self.dockUIPanel.frame
            let trueFrame = dockUIPanelRect
            
            if startFrame == trueFrame {
                return
            }
            
            iOSAnimation(
                panel: self.dockUIPanel,
                startFrame: startFrame,
                trueFrame: trueFrame,
            )
        } else {
            setupDockPanel()
            setupDockUIPanel()
        }
    }
}

// MARK: - UI
extension DockPreviewCoordinator {
    public func hidePrimedDockPanels() {
        dockPanel?.orderOut(nil)
        dockUIPanel?.orderOut(nil)
    }

    public func showPrimedDockPanels() {
        dockPanel?.orderFront(nil)
        dockUIPanel?.orderFront(nil)
    }

    public func autoHiddenDockDidLoseHover() {
        if isPointerInsidePanel() {
            isInTrackingArea = true
            return
        }

        isInTrackingArea = false
        lastExpandedDockRect = nil
        hidePrimedDockPanels()
    }

    public func setupDockUIPanel() {
        guard let dockRect else { return }
        let dockPanelRect = dockRect.convertToAppKit()
        guard let screen = NSScreen.screen(containing: dockPanelRect) else {
            return
        }

        dockUIPanel = ActiveAppearancePanel(
            contentRect: .zero,
            styleMask: [.borderless, .nonactivatingPanel, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        
        let dockUIRect = createDockUIRect(from: dockPanelRect, in: screen)
        
        dockUIPanel.setFrame(dockUIRect, display: true)
        dockUIPanel.contentView?.wantsLayer = true
        dockUIPanel.acceptsMouseMovedEvents = true
        
        let overlayRaw = CGWindowLevelForKey(.overlayWindow)
        dockUIPanel.level = NSWindow.Level(rawValue: Int(overlayRaw))
        
        dockUIPanel.collectionBehavior = [
            .canJoinAllSpaces,
            .fullScreenAuxiliary,
            .fullScreenDisallowsTiling,
            .ignoresCycle,
            .transient
        ]
        
        dockUIPanel.isMovableByWindowBackground = false
        dockUIPanel.backgroundColor = .clear
        dockUIPanel.isOpaque = false
        dockUIPanel.hasShadow = false
        dockUIPanel.becomesKeyOnlyIfNeeded = true
        dockUIPanel.hidesOnDeactivate = false
        dockUIPanel.animationBehavior = .none
        // we want to allow touching stuff
        dockUIPanel.ignoresMouseEvents = false
        
        let view = NSHostingView(
            rootView: DockContentView(height: dockUIRect.height)
                .environment(audioManager)
        )
        
        view.wantsLayer = true
        view.layer?.masksToBounds = false
        
        dockUIPanel.contentView = view
        dockUIPanel.makeKeyAndOrderFront(nil)
    }
    
    public func setupDockPanel() {
        guard let dockRect else { return }
        dockPanel = FocusablePanel(
            contentRect: .zero,
            styleMask: [.borderless, .nonactivatingPanel, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        dockPanel.setFrame(dockRect.convertToAppKit(), display: true)
        dockPanel.contentView?.wantsLayer = true
        dockPanel.acceptsMouseMovedEvents = true
        
        let overlayRaw = CGWindowLevelForKey(.overlayWindow)
        dockPanel.level = NSWindow.Level(rawValue: Int(overlayRaw))
        
        dockPanel.collectionBehavior = [
            .canJoinAllSpaces,
            .fullScreenAuxiliary,
            .fullScreenDisallowsTiling,
            .ignoresCycle,
            .transient
        ]
        
        dockPanel.isMovableByWindowBackground = false
        dockPanel.backgroundColor = .clear
        dockPanel.isOpaque = false
        dockPanel.hasShadow = false
        dockPanel.becomesKeyOnlyIfNeeded = true
        dockPanel.hidesOnDeactivate = false
        dockPanel.animationBehavior = .none
        dockPanel.ignoresMouseEvents = true
        
        let view = NSHostingView(
            rootView: DockPreviewView()
        )
        
        view.wantsLayer = true
        view.layer?.masksToBounds = false
        
        dockPanel.contentView = view
        dockPanel.makeKeyAndOrderFront(nil)
        startMouseTracking()
    }
}

// MARK: - Helpers
extension DockPreviewCoordinator {
    private func startMouseTracking() {
        guard mouseMovedMonitor == nil else { return }
        mouseMovedMonitor = NSEvent.addGlobalMonitorForEvents(
            matching: [
                .mouseMoved,
                .leftMouseDragged,
                .rightMouseDragged,
                .leftMouseDown,
                .rightMouseDown,
                .keyDown,
            ]
        ) { [weak self] event in
            Task { @MainActor in
                guard let self else { return }
                
                switch event.type {
                case .rightMouseDown:
                    if self.isPointerInsidePanel() {
                        self.beginDockMenuInteraction()
                    } else if self.isDockMenuInteractionActive {
                        self.scheduleDockMenuInteractionEnd()
                    }
                case .leftMouseDown:
                    if event.modifierFlags.contains(.control),
                       self.isPointerInsidePanel() {
                        self.beginDockMenuInteraction()
                    } else if self.isDockMenuInteractionActive {
                        self.scheduleDockMenuInteractionEnd()
                    }
                case .keyDown:
                    if self.isDockMenuInteractionActive,
                       event.keyCode == 36 ||
                        event.keyCode == 53 ||
                        event.keyCode == 76 {
                        self.scheduleDockMenuInteractionEnd()
                    }
                default:
                    self.updatePointerTracking()
                }
            }
        }
    }
    
    private func createDockUIRect(from dockPanelRect: CGRect, in screen: NSScreen) -> CGRect {
        CGRect(
            x: dockPanelRect.maxX + leadingDockUIPadding,
            y: dockPanelRect.minY,
            width: screen.frame.maxX - dockPanelRect.maxX - trailingDockUIPadding,
            height: dockPanelRect.height
        )
    }
    
    private func updatePointerTracking() {
        let isInside = isPointerInsidePanel()
        if isInside || isDockMenuInteractionActive {
            isInTrackingArea = true
        } else if isInTrackingArea {
            collapseToBaseDock()
        }
    }
    
    private func beginDockMenuInteraction() {
        dockMenuDismissalTask?.cancel()
        isDockMenuInteractionActive = true
        isInTrackingArea = true
        onGetCoreDockRect?()
        
        if let lastExpandedDockRect {
            load(lastExpandedDockRect)
        }
    }
    
    private func scheduleDockMenuInteractionEnd() {
        dockMenuDismissalTask?.cancel()
        dockMenuDismissalTask = Task { [weak self] in
            try? await Task.sleep(for: .milliseconds(120))
            guard !Task.isCancelled, let self else { return }
            
            self.isDockMenuInteractionActive = false
            if self.isPointerInsidePanel() {
                self.isInTrackingArea = true
            } else {
                self.collapseToBaseDock()
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
        dockPanel?.frame.contains(NSEvent.mouseLocation) == true
    }
}

// MARK: - Animation
extension DockPreviewCoordinator {
    private func iOSAnimation(
        panel: NSPanel,
        startFrame: NSRect,
        trueFrame: NSRect
    ) {
        let snappyFn = CAMediaTimingFunction(controlPoints: 0.2, 0.8, 0.2, 1.0)
        let isAppearing = panel.alphaValue == 0.0 || !panel.isVisible
        
        if isAppearing {
            panel.alphaValue = 0.0
            panel.setFrame(startFrame, display: false)
        }
        
        animationGeneration &+= 1
        let myGeneration = animationGeneration
        
        panel.orderFront(nil)
        
        NSAnimationContext.runAnimationGroup({ ctx in
            ctx.duration = 0.25
            ctx.timingFunction = snappyFn
            
            if isAppearing {
                panel.animator().alphaValue = 1.0
            }
            panel.animator().setFrame(trueFrame, display: true)
            
        }, completionHandler: { [weak self] in
            guard let self else { return }
            Task { @MainActor in
                guard self.animationGeneration == myGeneration else { return }
                panel.alphaValue = 1.0
                panel.setFrame(trueFrame, display: true)
            }
        })
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
        if self.isDockMenuInteractionActive || self.isPointerInsidePanel() {
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

        self.lastExpandedDockRect = rectToView
        self.load(rectToView)
    }
    
    /// Called when the base Dock bounds are found.
    ///
    /// These bounds represent the Dock in its non-magnified state.
    ///
    /// We only update the preview if the pointer is not currently hovering
    /// over the Dock, or if the preview panel has not been created yet.
    public func dockCoordinatorDidFindBaseDock(_ rect: CGRect) {
        baseDockRect = rect
        if !isInTrackingArea || dockPanel == nil {
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
//        .border(.yellow, width: 1)
    }
}
