//
//  Permissions.swift
//  ComfyDock
//
//  Created by Aryan Rogye on 10/5/25.
//

import ApplicationServices
import AppKit

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
