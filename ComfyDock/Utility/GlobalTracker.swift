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
    var stripHeight: CGFloat = 60
    
    /// Delay before considering the pointer "inside" when entering the strip.
    /// Set to 0 for immediate show. Exit remains instant regardless of this value.
    public var enterDelay: TimeInterval = 0.1
    
    private var pendingEnterTask: DispatchWorkItem?
    
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
                self.stripHeight = self.dockController.height
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
        
        // If state hasn't changed, nothing to do
        if isNowInside == inside { return }
        
        if isNowInside {
            // Entering: schedule delayed show if needed
            pendingEnterTask?.cancel()
            let work = DispatchWorkItem { [weak self] in
                guard let self = self else { return }
                // Confirm still inside at fire time
                let currentMouse = NSEvent.mouseLocation
                guard let currentScreen = NSScreen.main else { return }
                let currentStrip = CGRect(x: currentScreen.frame.minX,
                                          y: currentScreen.frame.minY,
                                          width: currentScreen.frame.width,
                                          height: self.stripHeight)
                let stillInside = currentStrip.contains(currentMouse)
                if stillInside && self.inside == false {
                    self.inside = true
                    onChange(true)
                }
            }
            pendingEnterTask = work
            if enterDelay > 0 {
                DispatchQueue.main.asyncAfter(deadline: .now() + enterDelay, execute: work)
            } else {
                // No delay requested: run immediately
                DispatchQueue.main.async(execute: work)
            }
        } else {
            // Exiting: cancel any pending enter, hide instantly
            pendingEnterTask?.cancel()
            pendingEnterTask = nil
            if inside {
                inside = false
                onChange(false)
            }
        }
    }
    
    func stop() {
        if let m = gloablMonitor { NSEvent.removeMonitor(m) }
        if let l = localMonitor  { NSEvent.removeMonitor(l) }
        pendingEnterTask?.cancel()
        pendingEnterTask = nil
        gloablMonitor = nil
        localMonitor = nil
        inside = false
    }
}
