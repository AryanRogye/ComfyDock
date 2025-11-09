//
//  RunningAppsService.swift
//  ComfyDock
//
//  Created by Aryan Rogye on 11/7/25.
//

import AppKit
import ApplicationServices

struct RunningApp: Hashable, Identifiable {
    let id: pid_t
    let bundleID: String
    let name: String
    let icon: NSImage
    let isActive: Bool
    var axElement: AXUIElement?

    public func activate() {
        log("activate() called (onMainThread=\(Thread.isMainThread))")
        let activationWork = {
            self.performActivation()
        }

        if Thread.isMainThread {
            activationWork()
        } else {
            DispatchQueue.main.async(execute: activationWork)
        }
    }

    private func performActivation() {
        guard let runningApp = NSRunningApplication(processIdentifier: id) else {
            log("NSRunningApplication missing, launching instead")
            launchApp()
            return
        }

        if runningApp.isTerminated {
            log("app is terminated, launching instead")
            launchApp()
            return
        }

        if runningApp.isHidden {
            log("app is hidden, calling unhide()")
            runningApp.unhide()
        }

        var options: NSApplication.ActivationOptions = []
        if #available(macOS 13.0, *) {
            options.insert(.activateAllWindows)
        }
        if #available(macOS 14.0, *) {
            // kAXActivateIgnoringOtherApps has no effect
        } else {
            options.insert(.activateIgnoringOtherApps)
        }

        let didActivate = runningApp.activate(options: options)
        log("activate(options: \(options.rawValue)) -> \(didActivate)")
        if !didActivate {
            log("activation failed, falling back to launch()")
            launchApp()
            return
        }

        focusFrontWindow(for: runningApp.processIdentifier)
    }

    private func focusFrontWindow(for pid: pid_t) {
        let trusted = AXIsProcessTrusted()
        log("AXIsProcessTrusted() -> \(trusted)")
        guard trusted else { return }

        var targetWindow = axElement
        let appElement = AXUIElementCreateApplication(pid)
        var didFocus = false
        let attempts = 4

        for attempt in 0..<attempts {
            let delay = DispatchTime.now() + .milliseconds(100 + attempt * 80)
            DispatchQueue.main.asyncAfter(deadline: delay) {
                guard !didFocus else { return }
                self.log("focus attempt \(attempt + 1)")

                let frontmostResult = AXUIElementSetAttributeValue(
                    appElement, kAXFrontmostAttribute as CFString, kCFBooleanTrue)
                self.log("AX frontmost=\(frontmostResult.rawValue)")

                if targetWindow == nil {
                    self.log("cached AX window missing, refreshing…")
                    targetWindow = RunningAppsService.findMatchingAXWindow(pid: pid)
                    if targetWindow == nil {
                        self.log("findMatchingAXWindow returned nil")
                        return
                    }
                }

                guard let window = targetWindow else { return }
                let raiseResult = AXUIElementPerformAction(window, kAXRaiseAction as CFString)
                let mainResult = AXUIElementSetAttributeValue(
                    window, kAXMainAttribute as CFString, kCFBooleanTrue)
                let focusResult = AXUIElementSetAttributeValue(
                    window, kAXFocusedAttribute as CFString, kCFBooleanTrue)
                self.log(
                    "AX raise=\(raiseResult.rawValue) main=\(mainResult.rawValue) focus=\(focusResult.rawValue)"
                )

                if raiseResult == .success || focusResult == .success {
                    didFocus = true
                } else {
                    targetWindow = nil
                }
            }
        }

        let fallbackDelay = DispatchTime.now() + .milliseconds(100 + (attempts - 1) * 80 + 200)
        DispatchQueue.main.asyncAfter(deadline: fallbackDelay) {
            guard !didFocus else { return }
            didFocus = true

            if let app = NSRunningApplication(processIdentifier: pid) {
                if app.isTerminated {
                    self.log("app terminated before focus, launching instead")
                    self.launchApp()
                    return
                }
            } else {
                self.log("process disappeared, launching instead")
                self.launchApp()
                return
            }

            self.log("no focusable window detected, launching instead")
            self.launchApp()
        }
    }

    private func log(_ message: String) {
        print("[RunningApp] \(bundleID) pid=\(id): \(message)")
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
            if let minimized = Self.copyAttributeValue(appElement, attribute: kAXMinimizedAttribute as CFString) as? Bool,
               minimized {
                return nil
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

        if let focused = copyWindowAttribute(appAX, attribute: kAXFocusedWindowAttribute as CFString),
           isUsableWindow(focused) {
            return focused
        }

        if let main = copyWindowAttribute(appAX, attribute: kAXMainWindowAttribute as CFString),
           isUsableWindow(main) {
            return main
        }

        if let windows = copyWindowList(appAX) {
            for window in windows where isUsableWindow(window) {
                return window
            }
        }

        for ax in AXUIElement.windowsByBruteForce(pid) {
            if isUsableWindow(ax) {
                return ax
            }
        }

        return nil
    }

    private static func copyWindowAttribute(_ appAX: AXUIElement, attribute: CFString) -> AXUIElement? {
        guard let windowRef = copyAttributeValue(appAX, attribute: attribute) else { return nil }
        return (windowRef as! AXUIElement)
    }

    private static func copyWindowList(_ appAX: AXUIElement) -> [AXUIElement]? {
        guard let windows = copyAttributeValue(appAX, attribute: kAXWindowsAttribute as CFString) as? [AXUIElement] else {
            return nil
        }
        return windows
    }

    private static func copyAttributeValue(_ element: AXUIElement, attribute: CFString) -> AnyObject? {
        var value: AnyObject?
        for attempt in 0..<3 {
            let result = AXUIElementCopyAttributeValue(element, attribute, &value)
            if result == .success {
                return value
            }
            if result != .cannotComplete {
                break
            }
            Thread.sleep(forTimeInterval: 0.02 + Double(attempt) * 0.02)
        }
        return nil
    }

    private static func isUsableWindow(_ window: AXUIElement) -> Bool {
        guard let rect = getAXWindowRect(window) else { return false }

        if let minimized = copyAttributeValue(window, attribute: kAXMinimizedAttribute as CFString) as? Bool,
           minimized {
            return false
        }

        return rect.width >= 5 && rect.height >= 5
    }

    private static func getAXWindowRect(_ axWindow: AXUIElement) -> CGRect? {
        var cgPoint: CGPoint = .zero
        var cgSize: CGSize = .zero
        AXValueGetValue(copyAttributeValue(axWindow, attribute: kAXPositionAttribute as CFString) as! AXValue, .cgPoint, &cgPoint)
        AXValueGetValue(copyAttributeValue(axWindow, attribute: kAXSizeAttribute as CFString) as! AXValue, .cgSize, &cgSize)

        guard cgSize.width > 50 && cgSize.height > 50 else { return nil }
        return CGRect(origin: cgPoint, size: cgSize)
    }
}
