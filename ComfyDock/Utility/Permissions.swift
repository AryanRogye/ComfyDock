//
//  Permissions.swift
//  ComfyDock
//
//  Created by Aryan Rogye on 10/5/25.
//

import ApplicationServices
import AppKit


@Observable @MainActor
class PermissionManager {
    var isAccessibilityEnabled: Bool = false
    
    var onPermissionGranted: (() -> Void)?
    @ObservationIgnored var permissionService: PermissionProviding = PermissionFetcherService()
    
    init() {
        self.isAccessibilityEnabled = permissionService.getAccessibilityPermissions()
        self.requestAutomationPermission()
        
        // Start monitoring if not enabled
        if !isAccessibilityEnabled {
            startMonitoring()
        }
    }
    
    func requestAutomationPermission() {
        let script = """
    tell application "System Events"
        return name of first process
    end tell
    """
        
        if let appleScript = NSAppleScript(source: script) {
            var error: NSDictionary?
            appleScript.executeAndReturnError(&error)
            
            if let error = error {
                print("⚠️ Automation permission needed. Error: \(error)")
                // This will trigger the system prompt
            } else {
                print("✅ Automation permission granted")
            }
        }
    }
    
    private func startMonitoring() {
        Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] timer in
            guard let self = self else {
                timer.invalidate()
                return
            }
            
            DispatchQueue.main.async {
                let wasEnabled = self.isAccessibilityEnabled
                self.isAccessibilityEnabled = self.permissionService.getAccessibilityPermissions()
                
                // If it just became enabled, trigger callback
                if !wasEnabled && self.isAccessibilityEnabled {
                    print("✅ Accessibility permissions granted!")
                    self.onPermissionGranted?()
                    timer.invalidate()
                }
            }
        }
    }
    
    public func requestPermission() {
        permissionService.requestAccessibilityPermission()
    }
    public func openPermissionSettings() {
        permissionService.openPermissionSettings()
    }
}

protocol PermissionProviding {
    func getAccessibilityPermissions() -> Bool
    func openPermissionSettings()
    func requestAccessibilityPermission()
}

class PermissionFetcherService: PermissionProviding {
    
    func getAccessibilityPermissions() -> Bool {
        let options: NSDictionary = [kAXTrustedCheckOptionPrompt.takeRetainedValue() as String: true]
        return AXIsProcessTrustedWithOptions(options)
    }
    
    
    var isAccessibilityEnabled   : Bool = false
    
    private var pollTimer: Timer?
    private var testTap: CFMachPort?
    
    init() {
        checkAccessibilityPermission()
        
        if !isAccessibilityEnabled {
            requestAccessibilityPermission()
        }
    }
    
    // MARK: - Accessibility
    /// Check if Accessibility Permission is Granted
    func checkAccessibilityPermission() {
        let isTrusted = AXIsProcessTrusted()
        DispatchQueue.main.async {
            self.isAccessibilityEnabled = isTrusted
        }
    }
    
    func openPermissionSettings() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
            NSWorkspace.shared.open(url)
        }
    }
    
    /// Request Accessibility Permissions
    func requestAccessibilityPermission() {
        let status = getAccessibilityPermissions()
        
        if !status {
            print("Accessibility permission denied.")
        } else {
            print("Accessibility permission granted.")
        }
        
        // Keep polling every second until enabled (max 10 tries)
        var tries = 0
        Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { timer in
            self.checkAccessibilityPermission()
            tries += 1
            
            if self.isAccessibilityEnabled || tries > 10 {
                timer.invalidate()
            }
        }
    }
}
