//
//  PrivateAPIs.swift
//  Dock
//
//  Created by Aryan Rogye on 11/12/25.
//

@preconcurrency import Foundation
import ApplicationServices.HIServices.AXActionConstants
import ApplicationServices.HIServices.AXAttributeConstants
import ApplicationServices.HIServices.AXError
import ApplicationServices.HIServices.AXRoleConstants
import ApplicationServices.HIServices.AXUIElement
import ApplicationServices.HIServices.AXValue
import Cocoa

/// Core Graphics types
typealias CGSConnectionID = UInt32
typealias CGSWindowCount = UInt32
typealias CGSSpaceID = UInt64
typealias CGSSpaceMask = UInt64


// returns CoreDock orientation and pinning state
@_silgen_name("CoreDockGetOrientationAndPinning")
func CoreDockGetOrientationAndPinning(_ outOrientation: UnsafeMutablePointer<Int32>, _ outPinning: UnsafeMutablePointer<Int32>)

// Toggles the Dock's auto-hide state
@_silgen_name("CoreDockSetAutoHideEnabled")
func CoreDockSetAutoHideEnabled(_ flag: Bool)

// Retrieves the current auto-hide state of the Dock
@_silgen_name("CoreDockGetAutoHideEnabled")
func CoreDockGetAutoHideEnabled() -> Bool

// Retrieves the current magnification state of the Dock
@_silgen_name("CoreDockIsMagnificationEnabled")
func CoreDockIsMagnificationEnabled() -> Bool

// Simple version - just get the rect
@_silgen_name("CoreDockGetRect")
func CoreDockGetRect(_ outRect: UnsafeMutablePointer<CGRect>)

// Get rect + orientation
@_silgen_name("CoreDockGetRectAndOrientation")
func CoreDockGetRectAndOrientation(_ outRect: UnsafeMutablePointer<CGRect>, _ outOrientation: UnsafeMutablePointer<Int32>)

@_silgen_name("CoreDockGetTileSize")
func CoreDockGetTileSize() -> Float

// Get rect + reason (probably why it changed)
@_silgen_name("CoreDockGetRectAndReason")
func CoreDockGetRectAndReason(_ outRect: UnsafeMutablePointer<CGRect>, _ outReason: UnsafeMutablePointer<Int32>)



@_silgen_name("_AXUIElementCreateWithRemoteToken")
func _AXUIElementCreateWithRemoteToken(_ token: CFData) -> Unmanaged<AXUIElement>?

struct CGSWindowCaptureOptions: OptionSet {
    let rawValue: UInt32
    
    static let ignoreGlobalClipShape = CGSWindowCaptureOptions(rawValue: 1 << 11)
    static let nominalResolution = CGSWindowCaptureOptions(rawValue: 1 << 9)
    static let bestResolution = CGSWindowCaptureOptions(rawValue: 1 << 8)
    static let fullSize = CGSWindowCaptureOptions(rawValue: 1 << 19)
}

let kCGSAllSpacesMask: CGSSpaceMask = 0xFFFF_FFFF_FFFF_FFFF
let kAXFullscreenAttribute = "AXFullScreen"
let kAXWindowNumberAttribute = "AXWindowNumber" as CFString



extension AXUIElement {
    func axCallWhichCanThrow<T>(_ result: AXError, _ successValue: inout T) throws -> T? {
        switch result {
        case .success: return successValue
            // .cannotComplete can happen if the app is unresponsive; we throw in that case to retry until the call succeeds
        case .cannotComplete: throw AxError.runtimeError
            // for other errors it's pointless to retry
        default: return nil
        }
    }
    
    func attribute<T>(_ key: String, _ _: T.Type) throws -> T? {
        var value: AnyObject?
        return try axCallWhichCanThrow(AXUIElementCopyAttributeValue(self, key as CFString, &value), &value) as? T
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
    
    public static func copyWindowAttribute(_ appAX: AXUIElement, attribute: CFString) -> AXUIElement? {
        guard let windowRef = copyAttributeValue(appAX, attribute: attribute) else { return nil }
        return (windowRef as! AXUIElement)
    }

    
    public static func copyWindowList(_ appAX: AXUIElement) -> [AXUIElement]? {
        guard let windows = copyAttributeValue(appAX, attribute: kAXWindowsAttribute as CFString) as? [AXUIElement] else {
            return nil
        }
        return windows
    }
    
    static func windowsByBruteForce(_ pid: pid_t) -> [AXUIElement] {
        var token = Data(count: 20)
        token.replaceSubrange(0 ..< 4, with: withUnsafeBytes(of: pid) { Data($0) })
        token.replaceSubrange(4 ..< 8, with: withUnsafeBytes(of: Int32(0)) { Data($0) })
        token.replaceSubrange(8 ..< 12, with: withUnsafeBytes(of: Int32(0x636F_636F)) { Data($0) })
        
        var results: [AXUIElement] = []
        for axId: AXUIElementID in 0 ..< 1000 {
            token.replaceSubrange(12 ..< 20, with: withUnsafeBytes(of: axId) { Data($0) })
            if let el = _AXUIElementCreateWithRemoteToken(token as CFData)?.takeRetainedValue(),
               let subrole = try? el.subrole(),
               [kAXStandardWindowSubrole, kAXDialogSubrole].contains(subrole)
            {
                results.append(el)
            }
        }
        return results
    }
    
    private static func getAXWindowRect(_ axWindow: AXUIElement) -> CGRect? {
        var cgPoint: CGPoint = .zero
        var cgSize: CGSize = .zero
        AXValueGetValue(copyAttributeValue(axWindow, attribute: kAXPositionAttribute as CFString) as! AXValue, .cgPoint, &cgPoint)
        AXValueGetValue(copyAttributeValue(axWindow, attribute: kAXSizeAttribute as CFString) as! AXValue, .cgSize, &cgSize)
        
        guard cgSize.width > 50 && cgSize.height > 50 else { return nil }
        return CGRect(origin: cgPoint, size: cgSize)
    }
    
    public static func isUsableWindow(_ window: AXUIElement) -> Bool {
        guard let rect = getAXWindowRect(window) else { return false }
        
        if let minimized = copyAttributeValue(window, attribute: kAXMinimizedAttribute as CFString) as? Bool,
           minimized {
            return false
        }
        
        return rect.width >= 5 && rect.height >= 5
    }
    
    func title() throws -> String? {
        try attribute(kAXTitleAttribute, String.self)
    }
    
    func isMinimized() throws -> Bool {
        let result = try attribute(kAXMinimizedAttribute, Bool.self) == true
        return result
    }
    
    func subrole() throws -> String? {
        try attribute(kAXSubroleAttribute, String.self)
    }
}

enum AxError: Error {
    case runtimeError
}

typealias AXUIElementID = UInt64
