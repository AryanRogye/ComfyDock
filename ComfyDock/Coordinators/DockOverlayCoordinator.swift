//
//  DockOverlayCoordinator.swift
//  ComfyDock
//
//  Created by Aryan Rogye on 11/7/25.
//

import AppKit
import SwiftUI

final class DockOverlayCoordinator: NSObject {
    
    var dockManager: DockManager
    var audioManager : AudioManager
    private var panel: NSPanel?
    private var host: NSHostingView<AnyView>?
    
    init(dockManager: DockManager, audioManager: AudioManager) {
        self.dockManager = dockManager
        self.audioManager = audioManager
        super.init()
        
        createPanel()
        hide()
    }
    
    // MARK: - Public API
    func show() {
        guard let panel = panel else { createPanel(); return show() }
        let final = currentFrame()                 // <- your target rect (uses dock.height)
        var start = final
        start.size.height = 0                      // slide up from bottom
        
        panel.animationBehavior = .none
        panel.alphaValue = 0
        panel.setFrame(start, display: true)
        panel.orderFrontRegardless()
        
        NSAnimationContext.runAnimationGroup { ctx in
            ctx.duration = 0.22
            ctx.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            panel.animator().setFrame(final, display: true)
            panel.animator().alphaValue = 1
        } completionHandler: {
            DispatchQueue.main.async {
                self.dockManager.isVisible = true
                self.syncContentSize()
            }
        }
    }
    
    func hide() {
        guard let panel = panel else { return }
        let final = currentFrame()
        var down = final
        down.size.height = 0
        
        NSAnimationContext.runAnimationGroup { ctx in
            ctx.duration = 0.18
            ctx.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            panel.animator().setFrame(down, display: true)
            panel.animator().alphaValue = 0
        } completionHandler: {
            DispatchQueue.main.async {
                panel.orderOut(nil)
                panel.alphaValue = 1
                self.dockManager.isVisible = false
            }
        }
    }
    
    private func syncContentSize() {
        guard let panel = panel else { return }
        CATransaction.begin()
        CATransaction.setDisableActions(true) // avoid layer “stretch” flicker
        panel.contentView?.frame = CGRect(origin: .zero, size: panel.contentRect(forFrameRect: panel.frame).size)
        panel.contentView?.layoutSubtreeIfNeeded()
        CATransaction.commit()
    }
    
    // MARK: - Core
    private func createPanel() {
        let p = FocusablePanel(
            contentRect: currentFrame(),
            styleMask: [.borderless, .nonactivatingPanel, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        p.setFrame(currentFrame(), display: true)
        
        p.contentView?.wantsLayer = true
        p.acceptsMouseMovedEvents = true
        
        let overlayRaw = CGWindowLevelForKey(.overlayWindow)
        p.level = NSWindow.Level(rawValue: Int(overlayRaw))
        
        p.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        p.isMovableByWindowBackground = false
        
        p.backgroundColor = .clear
        p.isOpaque = false
        p.hasShadow = false
        
        let view : NSView = NSHostingView(rootView: DockView(dockManager: dockManager, audioManager: audioManager))
        
        view.wantsLayer = true
        view.layer?.masksToBounds = true
        
        p.contentView = view
        
        self.panel = p
    }
    
    private func relayout(animated: Bool = true) {
        guard let panel else { return }
        let rect = currentFrame()
        if animated {
            panel.setFrame(rect, display: true, animate: true)
        } else {
            panel.setFrame(rect, display: true)
        }
        panel.contentView?.frame = CGRect(origin: .zero, size: rect.size)
    }
    
    private func currentFrame() -> CGRect {
        guard let screen = NSScreen.main else { return .zero }
        return screen.frame
    }
    
    // Re-armable Observation so height changes keep updating the panel
    private func armObservation() {
        withObservationTracking(
            { _ = dockManager.height; _ = dockManager.isVisible },
            onChange: { [weak self] in
                guard let self else { return }
                DispatchQueue.main.async {
                    if self.dockManager.isVisible { self.show(); self.relayout() } else { self.hide() }
                    self.armObservation()
                }
            }
        )
    }
}

