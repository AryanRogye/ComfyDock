//
//  WindowCore.swift
//  DockExperiment
//
//  Created by Aryan Rogye on 7/29/26.
//

import CoreGraphics
import Dock
import ApplicationServices

final class WindowCore {
    
    /**
     * All User Windows
     */
    public var windows: [ComfyWindow] = []
    
    /**
     * Main Load Window Task
     */
    var loadWindowTask: Task<[ComfyWindow], Never>?
    
    /**
     We cache WindowElements when the window is in the active Space
     because they behave more reliably.
     
     AXUIElements can act differently depending on when/how they’re grabbed.
     Reusing a previously cached one keeps window interactions stable.
     */
    private var elementCache: [CGWindowID: WindowElement] = [:]
    
    @discardableResult
    public func loadWindows() async -> [ComfyWindow] {
        loadWindowTask = Task.detached(priority: .userInitiated) { [weak self] in
            guard let self else { return [] }
            var userWindows: [ComfyWindow] = []
            
            let cscWindows: [ComfySCWindow] = await SCWindowFactory.getComfyWindowsPrivately(onScreenWindowsOnly: false)
            
            for w in cscWindows {
                /// Create a ComfyWindow Object
                if let cw = await ComfyWindow(window: w) {
                    
                    await MainActor.run {
                        if let windowID = cw.windowID {
                            /// if the element in ComfyWindow is a valid AXUIElement?, we can update cache
                            if cw.element.element != nil {
                                self.elementCache[windowID] = cw.element
                            }
                            /// if AXUIElement is nil, we can check our cache and update
                            else if let element = self.elementCache[windowID] {
                                cw.element = element
                            }
                            /// Brute-force fallback: resolve via _AXUIElementCreateWithRemoteToken
                            /// This catches windows on other Spaces, minimized, or hidden
                            /// that neither standard AX nor our cache can find
                            else if let ax = WindowServerBridge.shared.resolveAXElement(
                                pid: cw.pid,
                                windowID: windowID
                            ) {
                                let resolved = WindowElement(element: ax)
                                cw.element = resolved
                                self.elementCache[windowID] = resolved
                            }
                        }
                    }
                    /// Add Window into userWindows
                    userWindows.append(cw)
                    
                }
            }
            /// Return of the task
            return userWindows
        }
        
        
        if let loadWindowTask = loadWindowTask {
            let userWindows = await loadWindowTask.value
            if userWindows.isEmpty { return [] }
            
            // fast lookup of the newest snapshot by windowID
            let newByID = Dictionary(uniqueKeysWithValues: userWindows.map { ($0.windowID, $0) })
            
            var merged: [ComfyWindow] = []
            merged.reserveCapacity(userWindows.count)
            
            // 1) preserve previous order (self.windows), refreshing data when present
            var seen = Set<String>()
            seen.reserveCapacity(userWindows.count)
            
            for old in self.windows {
                if let updated = newByID[old.windowID] {
                    merged.append(updated)
                    seen.insert(old.id)
                }
            }
            
            // 2) append any brand-new windows (order = snapshot order for new ones)
            for w in userWindows where !seen.contains(w.id) {
                merged.append(w)
                seen.insert(w.id)
            }
            
            self.windows = merged
            return merged
        } else {
            return []
        }
    }
}
