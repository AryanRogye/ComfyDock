//
//  RunningApps.swift
//  ComfyDock
//
//  Created by Aryan Rogye on 11/7/25.
//

import AppKit

struct RunningApp: Hashable, Identifiable {
    let id: pid_t
    let bundleID: String
    let name: String
    let icon: NSImage
    let isActive: Bool
    var axElement: AXUIElement?
    
    public func activate() {
        guard let runningApp = NSRunningApplication(processIdentifier: id) else {
            launchApp()
            return
        }
        
        if runningApp.isHidden {
            runningApp.unhide()
        }
        
        // Just do it, don't check return value
        let result = runningApp.activate(options: [.activateIgnoringOtherApps])
        
        guard let axElement else { return }
        // Multiple focus attempts
        for i in 0...2 {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1 + Double(i) * 0.05) {
                AXUIElementSetAttributeValue(axElement, kAXFocusedAttribute as CFString, true as CFTypeRef)
                AXUIElementSetAttributeValue(axElement, kAXMainAttribute as CFString, true as CFTypeRef)
                AXUIElementPerformAction(axElement, kAXRaiseAction as CFString)
            }
        }
    }
    
    private func launchApp() {
        print("Launching App \(name)")
        guard let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleID) else {
            print("❌ No app found for bundle ID: \(bundleID)")
            return
        }
        
        let config = NSWorkspace.OpenConfiguration()
        config.activates = true
        
        NSWorkspace.shared.openApplication(at: url, configuration: config) { app, error in
            if let error = error {
                print("❌ Launch failed: \(error.localizedDescription)")
            } else {
                print("✅ Launched \(bundleID)")
            }
        }
    }
}

protocol RunningAppsProviding {
    func getRunningApps() -> [RunningApp]
}

final class RunningAppsService: RunningAppsProviding {
    
    func getRunningApps() -> [RunningApp] {
        let ws = NSWorkspace.shared
        let running = ws.runningApplications
        
        var items = running.compactMap { app -> RunningApp? in
            guard app.activationPolicy == .regular,
                  !app.isHidden,
                  let url = app.bundleURL
            else { return nil }
            
            // skip minimized windows
            let appElement = AXUIElementCreateApplication(app.processIdentifier)
            var minimizedRef: AnyObject?
            if AXUIElementCopyAttributeValue(appElement, "AXMinimized" as CFString, &minimizedRef) == .success {
                if let minimized = minimizedRef as? Bool, minimized { return nil }
            }
            
            let icon = ws.icon(forFile: url.path)
            icon.size = NSSize(width: 32, height: 32)
            
            let pid = app.processIdentifier
            
            let axElement = Self.findMatchingAXWindow(pid: pid)
            if let bundleID = app.bundleIdentifier {
                return RunningApp(
                    id: pid,
                    bundleID: bundleID,
                    name: app.localizedName ?? "App",
                    icon: icon,
                    isActive: app.isActive,
                    axElement: axElement
                )
            } else { return nil }
        }
        
        items = Array(Set(items))
            .sorted {
                if $0.isActive != $1.isActive { return $0.isActive && !$1.isActive }
                return $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending
            }
        return items
    }
    
    public static func findMatchingAXWindow(
        pid: pid_t,
    ) -> AXUIElement? {
        
        let appAX = AXUIElementCreateApplication(pid)
        
        var windowsRef: AnyObject?
        guard AXUIElementCopyAttributeValue(appAX, kAXWindowsAttribute as CFString, &windowsRef) == .success,
              let axWindowsAll = windowsRef as? [AXUIElement]
        else { return nil }
        
        let tol: CGFloat = 12.0 // be generous; titles/shadows/scale can skew a bit
        
        for ax in AXUIElement.windowsByBruteForce(pid) {
            if let axRect = getAXWindowRect(ax),
               axRect.width >= 5, axRect.height >= 5 {
                return ax
            }
        }
        
        return nil
    }
    
    private static func getAXWindowRect(_ axWindow: AXUIElement) -> CGRect? {
        var positionRef: AnyObject?
        var sizeRef: AnyObject?
        guard AXUIElementCopyAttributeValue(axWindow, kAXPositionAttribute as CFString, &positionRef) == .success,
              AXUIElementCopyAttributeValue(axWindow, kAXSizeAttribute as CFString, &sizeRef) == .success
        else { return nil }
        
        var cgPoint: CGPoint = .zero
        var cgSize: CGSize = .zero
        AXValueGetValue(positionRef as! AXValue, .cgPoint, &cgPoint)
        AXValueGetValue(sizeRef as! AXValue, .cgSize, &cgSize)
        
        guard cgSize.width > 50 && cgSize.height > 50 else { return nil }
        return CGRect(origin: cgPoint, size: cgSize)
    }
}
