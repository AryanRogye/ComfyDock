//
//  View+onRightClick.swift
//  ComfyDock
//
//  Created by Aryan Rogye on 11/9/25.
//

import SwiftUI

struct RightClickOverlay: NSViewRepresentable {
    let onRightClick: (_ local: CGPoint, _ screen: CGPoint) -> Void
    
    func makeCoordinator() -> Coordinator { Coordinator() }
    
    func makeNSView(context: Context) -> NSView {
        let v = PassthroughView() // transparent; doesn’t steal left clicks
        context.coordinator.install(on: v, handler: onRightClick)
        return v
    }
    func updateNSView(_ nsView: NSView, context: Context) {}
    
    final class Coordinator {
        private var rightMon: Any?
        private var leftMon: Any?
        weak var host: NSView?
        var handler: ((_ local: CGPoint, _ screen: CGPoint) -> Void)?
        
        func install(on view: NSView, handler: @escaping (_ local: CGPoint, _ screen: CGPoint) -> Void) {
            host = view
            self.handler = handler
            
            rightMon = NSEvent.addLocalMonitorForEvents(matching: [.rightMouseDown]) { [weak self] e in
                guard let self, let host = self.host, let win = host.window else { return e }
                let local = host.convert(e.locationInWindow, from: nil)
                if host.bounds.contains(local) {
                    self.handler?(local, win.convertPoint(toScreen: e.locationInWindow))
                    return nil // swallow default menu
                }
                return e
            }
            
            // Control-click support
            leftMon = NSEvent.addLocalMonitorForEvents(matching: [.leftMouseDown]) { [weak self] e in
                guard let self, e.modifierFlags.contains(.control),
                      let host = self.host, let win = host.window else { return e }
                let local = host.convert(e.locationInWindow, from: nil)
                if host.bounds.contains(local) {
                    self.handler?(local, win.convertPoint(toScreen: e.locationInWindow))
                    return nil
                }
                return e
            }
        }
        
        deinit {
            if let m = rightMon { NSEvent.removeMonitor(m) }
            if let m = leftMon  { NSEvent.removeMonitor(m) }
        }
    }
    
    final class PassthroughView: NSView {
        override func hitTest(_ point: NSPoint) -> NSView? { nil } // don’t block normal clicks
        override var isFlipped: Bool { true }
    }
}

extension View {
    func onRightClick(_ action: @escaping (_ local: CGPoint, _ screen: CGPoint) -> Void) -> some View {
        // Use overlay so the catcher’s frame matches your SwiftUI view
        overlay(RightClickOverlay(onRightClick: action))
    }
}
