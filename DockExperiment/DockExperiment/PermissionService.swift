//
//  PermissionService.swift
//  DockExperiment
//
//  Created by Aryan Rogye on 7/29/26.
//

import ApplicationServices
import AppKit
import CoreGraphics


@MainActor
@Observable
class PermissionService {
    var isAccessibilityEnabled: Bool = false
    var isScreenRecordingEnabled: Bool = false
    
    var permissionService: PermissionProviding = PermissionFetcherService()

    private var didBecomeActiveObserver: NSObjectProtocol?
    
    private var pollTask: Task<Void, Never>?

    
    init() {
        self.isAccessibilityEnabled = permissionService.getAccessibilityPermissions()
        self.isScreenRecordingEnabled = permissionService.getScreenRecordingPermission()
        observeAppActivation()
        if !isAccessibilityEnabled {
            self.requestPermission()
        }
        if !isScreenRecordingEnabled {
            self.requestScreenRecordingPermission()
        }
    }

    @MainActor
    deinit {
        pollTask?.cancel()
        if let didBecomeActiveObserver {
            NotificationCenter.default.removeObserver(didBecomeActiveObserver)
        }
    }
    
    public func resetAccessibility() throws {
        let process = Process()
        /// tccutil reset Accessibility com.aryanrogye.ComfyTile
        process.executableURL = URL(fileURLWithPath: "/usr/bin/tccutil")
        
        process.arguments = [
            "reset",
            "Accessibility",
            "com.aryanrogye.DockExperiment"
        ]

        try process.run()
    }
    
    public func requestPermission() {
        let status = permissionService.requestAccessibilityPermission()
        permissionService.openPermissionSettings()
        self.isAccessibilityEnabled = status
        startPollingAccessibility()
    }

    public func requestScreenRecordingPermission() {
        let status = permissionService.requestScreenRecordingPermission()
        self.isScreenRecordingEnabled = status
        if !status {
            permissionService.openScreenRecordingSettings()
        }
    }

    public func openPermissionSettings() {
        permissionService.openPermissionSettings()
    }
    
    @MainActor
    private func startPollingAccessibility() {
        pollTask?.cancel()
        pollTask = Task { [weak self] in
            guard let self else { return }
            
            for _ in 1...30 {
                let status = self.permissionService.getAccessibilityPermissions()
                if status != self.isAccessibilityEnabled {
                    self.isAccessibilityEnabled = status
                }
                let screenRecordingStatus = self.permissionService.getScreenRecordingPermission()
                if screenRecordingStatus != self.isScreenRecordingEnabled {
                    self.isScreenRecordingEnabled = screenRecordingStatus
                }
                if status && screenRecordingStatus { break }
                try? await Task.sleep(nanoseconds: 1_000_000_000)
            }
        }
    }

    private func observeAppActivation() {
        didBecomeActiveObserver = NotificationCenter.default.addObserver(
            forName: NSApplication.didBecomeActiveNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            guard let self else { return }
            
            DispatchQueue.main.async {
                let status = self.permissionService.getAccessibilityPermissions()
                if status != self.isAccessibilityEnabled {
                    self.isAccessibilityEnabled = status
                }
                let screenRecordingStatus = self.permissionService.getScreenRecordingPermission()
                if screenRecordingStatus != self.isScreenRecordingEnabled {
                    self.isScreenRecordingEnabled = screenRecordingStatus
                }
            }
        }
    }
}

protocol PermissionProviding {
    func getAccessibilityPermissions() -> Bool
    func getScreenRecordingPermission() -> Bool
    func openPermissionSettings()
    func openScreenRecordingSettings()
    func requestAccessibilityPermission() -> Bool
    func requestScreenRecordingPermission() -> Bool
}


class PermissionFetcherService: PermissionProviding {
    
    func getAccessibilityPermissions() -> Bool {
        AXIsProcessTrusted()
    }
    
    func openPermissionSettings() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
            NSWorkspace.shared.open(url)
        }
    }

    func getScreenRecordingPermission() -> Bool {
        CGPreflightScreenCaptureAccess()
    }

    func openScreenRecordingSettings() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_ScreenCapture") {
            NSWorkspace.shared.open(url)
        }
    }
    
    /// Request Accessibility Permissions
    func requestAccessibilityPermission() -> Bool {
        let options = ["AXTrustedCheckOptionPrompt": true] as CFDictionary
        let trusted = AXIsProcessTrustedWithOptions(options)
        
        print(trusted ? "Accessibility permission granted." : "Accessibility permission denied.")
        return trusted
    }

    func requestScreenRecordingPermission() -> Bool {
        let granted = CGRequestScreenCaptureAccess()
        print(granted ? "Screen Recording permission granted." : "Screen Recording permission denied.")
        return granted
    }
}
