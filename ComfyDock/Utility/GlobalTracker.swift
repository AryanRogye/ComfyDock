//
//  GlobalTracker.swift
//  ComfyDock
//
//  Created by Aryan Rogye on 11/7/25.
//

import AppKit

@MainActor
public class GlobalHoverTracker {
    
    private var localMonitor : Any?
    private var gloablMonitor: Any?
    private var dockController : DockManager
    
    private var inside = false
    var stripHeight: CGFloat = 60 - 10
    
    init(dockController : DockManager) {
        self.dockController = dockController
        observeHeightChanges()
    }
    
    var lastOnChange: ((Bool) -> Void)?
    
    private func observeHeightChanges() {
        withObservationTracking {
            _ = dockController.height
        } onChange: { [weak self] in
            guard let self = self else { return }
            DispatchQueue.main.async {
                guard let lastOnChange = self.lastOnChange else { return }
                self.stripHeight = max(self.dockController.height - 10, 10)
                self.stop()
                self.startTracking(lastOnChange)
                self.observeHeightChanges()
            }
        }
    }
    
    func startTracking(_ onChange: @escaping (Bool) -> Void) {
        guard gloablMonitor == nil else { return }
        guard localMonitor == nil else { return }
        lastOnChange = onChange
        print("tracking started")
        
        gloablMonitor = NSEvent.addGlobalMonitorForEvents(matching: .mouseMoved) { _ in
            self.handleEvent(onChange: onChange)
        }
        localMonitor = NSEvent.addLocalMonitorForEvents(matching: .mouseMoved, handler: { event in
            self.handleEvent(onChange: onChange)
            return event
        })
    }
    
    private func handleEvent(onChange: @escaping (Bool) -> Void) {
        let mouse = NSEvent.mouseLocation
        guard let screen = NSScreen.main else { return }
        
        // bottom strip area
        let strip = CGRect(x: screen.frame.minX,
                           y: screen.frame.minY,
                           width: screen.frame.width,
                           height: self.stripHeight)
        
        let isNowInside = strip.contains(mouse)
        if isNowInside != self.inside {
            self.inside = isNowInside
            onChange(isNowInside)
        }
    }
    
    func stop() {
        if let m = gloablMonitor { NSEvent.removeMonitor(m) }
        if let l = localMonitor  { NSEvent.removeMonitor(l) }
        gloablMonitor = nil
        localMonitor = nil
        inside = false
    }
}
