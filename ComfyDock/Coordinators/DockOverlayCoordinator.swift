//
//  DockOverlayCoordinator.swift
//  ComfyDock
//
//  Created by Aryan Rogye on 11/7/25.
//

import AppKit
import SwiftUI

final class DockOverlayCoordinator: NSObject {
    
    var dock: DockManager
    private var panel: NSPanel?
    private var host: NSHostingView<AnyView>?
    
    
    init(dock: DockManager) {
        self.dock = dock
        super.init()
        
        createPanel()
        hide()
    }
    
    // MARK: - Public API
    func show() {
        guard let panel = panel else { createPanel(); return show() }
        let vf = NSScreen.main!.visibleFrame
        let final = currentFrame()
        let start = CGRect(x: vf.minX, y: vf.minY, width: vf.width, height: 0)
        
        panel.alphaValue = 1
        panel.setFrame(start, display: true)
        panel.orderFrontRegardless()
        
        NSAnimationContext.runAnimationGroup { ctx in
            ctx.duration = 0.2
            ctx.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            panel.animator().setFrame(final, display: true)
        }
    }
    
    func hide() {
        guard let panel else { return }
        let vf = NSScreen.main!.visibleFrame
        let down = CGRect(x: vf.minX, y: vf.minY, width: vf.width, height: 0)
        
        NSAnimationContext.runAnimationGroup { ctx in
            ctx.duration = 0.16
            ctx.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            panel.animator().setFrame(down, display: true)
            panel.animator().alphaValue = 0.98 // optional slight fade
        } completionHandler: {
            panel.orderOut(nil)
            panel.alphaValue = 1
        }
    }
    
    // MARK: - Core
    private func createPanel() {
        let rect = currentFrame()
        let p = NSPanel(
            contentRect: rect,
            styleMask: [.borderless, .nonactivatingPanel, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        p.isOpaque = false
        p.hasShadow = false
        p.backgroundColor = .clear
        p.ignoresMouseEvents = false
        p.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        p.level = .statusBar   // above normal windows; use .screenSaver to be “always on top” (aggressive)
        
        // your SwiftUI content here
        let content = AnyView(DockView(dock: dock))
        
        let hv = NSHostingView(rootView: content)
        hv.wantsLayer = true
        hv.layer?.masksToBounds = true
        hv.layer?.cornerRadius = 10
        p.contentView = hv
        
        self.panel = p
        self.host = hv
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
        let vf = screen.visibleFrame
        let bottomPadding = dock.paddingFromBottom
        let h = max(0, min(dock.height, vf.height))
        return CGRect(x: vf.minX, y: vf.minY + bottomPadding, width: vf.width, height: h)
    }
    
    // Re-armable Observation so height changes keep updating the panel
    private func armObservation() {
        withObservationTracking(
            { _ = dock.height; _ = dock.isVisible },
            onChange: { [weak self] in
                guard let self else { return }
                DispatchQueue.main.async {
                    if self.dock.isVisible { self.show(); self.relayout() } else { self.hide() }
                    self.armObservation()
                }
            }
        )
    }
}
