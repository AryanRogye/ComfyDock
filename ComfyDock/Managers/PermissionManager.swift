//
//  PermissionManager.swift
//  ComfyDock
//
//  Created by Aryan Rogye on 11/8/25.
//

import Foundation

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
