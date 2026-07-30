//
//  AXHelpers.swift
//  ComfyTile
//  Copyright (C) 2025 Aryan Rogye
//  SPDX-License-Identifier: GPL-3.0-or-later
//  Derived from DockDoor (GPL-3.0) and/or alt-tab-macos (GPL); modified by Aryan Rogye.
//
//  This program is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with this program.  If not, see <https://www.gnu.org/licenses/>.

import ApplicationServices
import Cocoa
import Dock

extension AXValue {
    func toValue<T>() -> T? {
        let pointer = UnsafeMutablePointer<T>.allocate(capacity: 1)
        let success = AXValueGetValue(self, AXValueGetType(self), pointer)
        let value = pointer.pointee
        pointer.deallocate()
        return success ? value : nil
    }
    
    static func from<T>(value: T, type: AXValueType) -> AXValue? {
        var value = value
        return withUnsafePointer(to: &value) { valuePointer in
            AXValueCreate(type, valuePointer)
        }
    }
}

/// Stripped out version from DockDoor
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
    
    func getValue(_ attribute: NSAccessibility.Attribute) -> AnyObject? {
        var value: AnyObject?
        let result = AXUIElementCopyAttributeValue(self, attribute.rawValue as CFString, &value)
        guard result == .success else { return nil }
        return value
    }
    
    func closeButton() throws -> AXUIElement? {
        try attribute(kAXCloseButtonAttribute, AXUIElement.self)
    }
    
    func children() throws -> [AXUIElement]? {
        try attribute(kAXChildrenAttribute, [AXUIElement].self)
    }
    
    func role() throws -> String? {
        try attribute(kAXRoleAttribute, String.self)
    }
    
    func subscribeToNotification(_ axObserver: AXObserver, _ notification: String, _ callback: (() -> Void)? = nil) throws {
        let result = AXObserverAddNotification(axObserver, self, notification as CFString, nil)
        if result == .success || result == .notificationAlreadyRegistered {
            callback?()
        } else if result != .notificationUnsupported, result != .notImplemented {
            throw AxError.runtimeError
        }
    }
    
    private func setWrappedValue<T>(_ attribute: NSAccessibility.Attribute, _ value: T, _ type: AXValueType) {
        guard let value = AXValue.from(value: value, type: type) else { return }
        setValue(attribute, value)
    }
    
    func setValue(_ attribute: NSAccessibility.Attribute, _ value: CGPoint) {
        setWrappedValue(attribute, value, .cgPoint)
    }
    
    func setValue(_ attribute: NSAccessibility.Attribute, _ value: CGSize) {
        setWrappedValue(attribute, value, .cgSize)
    }
    
    func setValue(_ attribute: NSAccessibility.Attribute, _ value: AnyObject) {
        AXUIElementSetAttributeValue(self, attribute.rawValue as CFString, value)
    }
    
    func performAction(_ action: String) throws {
        var unused: Void = ()
        try axCallWhichCanThrow(AXUIElementPerformAction(self, action as CFString), &unused)
    }
    
    
    func getWrappedValue<T>(_ attribute: NSAccessibility.Attribute) -> T? {
        guard let value = getValue(attribute), CFGetTypeID(value) == AXValueGetTypeID() else { return nil }
        return (value as! AXValue).toValue()
    }
    
    func attribute<T>(_ key: String, _ _: T.Type) throws -> T? {
        var value: AnyObject?
        return try axCallWhichCanThrow(AXUIElementCopyAttributeValue(self, key as CFString, &value), &value) as? T
    }
    
    func windows() throws -> [AXUIElement]? {
        try attribute(kAXWindowsAttribute, [AXUIElement].self)
    }
    
    @MainActor
    func _cgWindowID() -> CGWindowID? {
        var id: CGWindowID = 0
        guard let axUIElementGetWindow = WindowServerBridge.shared.axUIElementGetWindow else {
            return nil
        }
        let err = axUIElementGetWindow(self, &id)
        guard err == .success, id != 0 else { return nil }
        return id
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

let kAXFullscreenAttribute = "AXFullScreen"
