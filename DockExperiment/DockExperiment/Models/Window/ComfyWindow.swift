//
//  ComfyWindow.swift
//  DockExperiment
//
//  Created by Aryan Rogye on 7/29/26.
//

import Cocoa
import ScreenCaptureKit
import Dock

public final class ComfyWindow: Sendable, Equatable {
    public var id: String {
        if let wid = windowID {
            return "\(pid):\(wid)"
        }
        
        // UI-only fallback: title + frame fingerprint (stable-ish)
        let fx = Int(element.frame.origin.x.rounded())
        let fy = Int(element.frame.origin.y.rounded())
        let fw = Int(element.frame.size.width.rounded())
        let fh = Int(element.frame.size.height.rounded())
        
        return "\(pid):\(windowTitle):\(fx),\(fy),\(fw),\(fh)"
    }
    
    public let windowID : CGWindowID?
    public let windowTitle : String
    
    public let app: NSRunningApplication
    
    /// More stronger element
    public var element: WindowElement
    public var screen: NSScreen?
    public let pid: pid_t
    public let bundleIdentifier: String?
    public var isInSpace  : Bool
    
    public init?(
        window: ComfySCWindow
    ) async {
        guard let app = window.owningApplication else {
            // Skip junk like "Cursor", "Menubar", etc.
            return nil
        }
        
        /// Get Window Information
        guard let windowInfo = CGWindowListCopyWindowInfo([.optionIncludingWindow], window.windowID) as? [[String: Any]],
              let firstWindow = windowInfo.first,
              let pid = firstWindow["kCGWindowOwnerPID"] as? pid_t
        else { return nil }
        let windowTitle = firstWindow["kCGWindowName"] as? String

        /// Get AXElement, Doesnt matter if nil
        let axElement : AXUIElement? = WindowServerBridge.shared.findMatchingAXWindow(pid: pid, targetWindowID: window.windowID)
        
        let isInSpace = Self.isWindowInActiveSpace(window.windowID)
        let screen = NSScreen.screens.first { $0.frame.intersects(window.frame) } ?? NSScreen.main

        let windowElement = WindowElement(element: axElement)
        
        let nsapp = NSRunningApplication.runningApplications(withBundleIdentifier: app.bundleIdentifier)
        guard nsapp.count > 0 else {
            return nil
        }
        self.app = nsapp.first!
        self.windowID = window.windowID
        self.windowTitle = windowTitle ?? ""
        self.element = windowElement
        self.screen = screen
        self.bundleIdentifier = app.bundleIdentifier
        self.pid = pid
        self.isInSpace = isInSpace
    }
    
    public init(
        app: NSRunningApplication,
        windowID: CGWindowID?,
        windowTitle     : String,
        element: WindowElement,
        screen: NSScreen? = nil,
        bundleIdentifier: String?,
        pid: pid_t,
        isInSpace: Bool
    ) {
        self.app = app
        self.windowID = windowID
        self.windowTitle = windowTitle
        self.element = element
        self.screen = screen
        self.bundleIdentifier = bundleIdentifier
        self.pid = pid
        self.isInSpace = isInSpace
    }
    
    public func focusWindow() {
        if let id = windowID {
            // If we have no AX element, try to resolve one on-the-fly
            // This eliminates the need for prior caching — matches DockDoor's approach
            var axElement = element.element
            if axElement == nil {
                axElement = WindowServerBridge.shared.resolveAXElement(
                    pid: pid, windowID: id
                )
                // Update the element for future use
                if let axElement {
                    element = WindowElement(element: axElement)
                }
            }
            WindowServerBridge.shared.focusApp(
                forUserWindowID: id,
                pid: pid,
                element: axElement,
                app: app
            )
        }
    }

    public static func == (lhs: ComfyWindow, rhs: ComfyWindow) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Public Helpers
extension ComfyWindow {
    /// Maximizes this specific previewed window by resizing it to the screen's
    /// visible frame.
    ///
    /// We do this with direct geometry instead of pressing the native green
    /// zoom button because app-defined zoom behavior is inconsistent across
    /// macOS apps. Using `visibleFrame` gives us stable, DockDoor-style
    /// maximize behavior for any discovered window.
    public func maximize() {
        guard let element = resolvedElement() else { return }
        
        if let isMinimized = try? element.isMinimized(), isMinimized {
            self.element.toggleMinimize()
        }
        
        guard let screen = targetScreen() else { return }
        
        let frame = screen.visibleFrame
        let position = frame.axPosition(on: screen)
        
        self.element.setPosition(x: position.x, y: position.y)
        self.element.setSize(width: frame.width, height: frame.height)
        self.screen = screen
    }
}

// MARK: - Private Helpers

extension ComfyWindow {
    /// Returns a usable AX element for this window, resolving one on demand
    /// when the window was discovered faster than Accessibility could provide
    /// a cached element.
    ///
    /// This exists so traffic-light actions can still work for windows that are
    /// minimized, hidden, on another Space, or simply not yet in our AX cache.
    func resolvedElement() -> AXUIElement? {
        if let axElement = element.element {
            return axElement
        }

        guard let windowID,
              let axElement = WindowServerBridge.shared.resolveAXElement(
                  pid: pid,
                  windowID: windowID
              )
        else {
            return nil
        }

        element = WindowElement(element: axElement)
        return axElement
    }

    /// Finds the best screen to maximize onto using the window's current CG
    /// bounds first, then falling back to the cached screen.
    ///
    /// We added this because a window may have moved since discovery, so using
    /// only the originally stored screen can maximize it onto the wrong display.
    internal func targetScreen() -> NSScreen? {
        if let frame = currentWindowBounds() {
            return NSScreen.screens.first { $0.frame.intersects(frame) } ?? NSScreen.main
        }

        return screen ?? NSScreen.main
    }

    /// Reads the latest CoreGraphics window bounds for this window ID.
    ///
    /// We use CG window bounds here because they are a lightweight way to learn
    /// where the window currently lives on screen, even when AX state is stale
    /// or unavailable at the moment we trigger maximize.
    internal func currentWindowBounds() -> CGRect? {
        guard let windowID,
              let info = CGWindowListCopyWindowInfo([.optionIncludingWindow], windowID) as? [[String: Any]],
              let bounds = info.first?[kCGWindowBounds as String] as? NSDictionary
        else {
            return nil
        }

        return CGRect(dictionaryRepresentation: bounds)
    }
    
    /// True when a window belongs to the currently active macOS Space.
    private static func isWindowInActiveSpace(_ windowID: CGWindowID) -> Bool {
        let cid = CGSMainConnectionID()
        let activeSpace = CGSGetActiveSpace(cid)
        let windowSpaces = spacesForWindow(windowID)
        return windowSpaces.contains(activeSpace)
    }
    
    /// Returns the space identifiers a window belongs to.
    private static func spacesForWindow(_ windowID: CGWindowID) -> [CGSSpaceID] {
        let cid = CGSMainConnectionID()
        let ids: CFArray = [NSNumber(value: Int(windowID))] as CFArray
        
        guard let unmanaged = CGSCopySpacesForWindows(cid, kCGSAllSpacesMask, ids) else {
            return []
        }
        
        // Usually retained for “Copy” functions
        let cfArray = unmanaged.takeRetainedValue()
        
        // Bridge to Swift
        let nums = cfArray as NSArray as? [NSNumber] ?? []
        return nums.map { CGSSpaceID($0.uint64Value) }
    }
}
