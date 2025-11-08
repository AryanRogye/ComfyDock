//
//  PrivateAPIs.swift
//  ComfyDock
//
//  Created by Aryan Rogye on 11/8/25.
//

//
//  PrivateAPIs.swift
//  ComfyTile
//
//  Created by Aryan Rogye on 11/2/25.
//

import Foundation
import ApplicationServices.HIServices.AXActionConstants
import ApplicationServices.HIServices.AXAttributeConstants
import ApplicationServices.HIServices.AXError
import ApplicationServices.HIServices.AXRoleConstants
import ApplicationServices.HIServices.AXUIElement
import ApplicationServices.HIServices.AXValue
import Cocoa

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
