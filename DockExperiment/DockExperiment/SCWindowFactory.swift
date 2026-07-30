//
//  SCWindowFactory.swift
//  DockExperiment
//
//  Created by Aryan Rogye on 7/29/26.
//

import ObjectiveC.runtime
import Foundation
import ScreenCaptureKit


public typealias SCWindowInitWithDictFn =
@convention(c) (AnyObject, Selector, NSDictionary) -> SCWindow?

public enum SCWindowFactory {
    private static let initSelector = NSSelectorFromString("initWithDict:")

    static func makeWindow(from cgWindowInfo: [String: Any]) -> SCWindow? {
        guard
            let method = class_getInstanceMethod(SCWindow.self, initSelector),
            let rawWindow = class_createInstance(SCWindow.self, 0) as AnyObject?
        else {
            return nil
        }

        let initialize = unsafeBitCast(
            method_getImplementation(method),
            to: SCWindowInitWithDictFn.self
        )

        guard let sckDictionary = makeSCKDictionary(from: cgWindowInfo) else {
            return nil
        }

        return initialize(rawWindow, initSelector, sckDictionary)
    }

    private static func makeSCKDictionary(from cgWindowInfo: [String: Any]) -> NSDictionary? {
        guard
            let windowID = numberValue(kCGWindowNumber, in: cgWindowInfo)?.uint32Value,
            let pid = numberValue(kCGWindowOwnerPID, in: cgWindowInfo)?.int32Value,
            let layer = numberValue(kCGWindowLayer, in: cgWindowInfo)?.intValue,
            let boundsDict = cgWindowInfo[kCGWindowBounds as String] as? NSDictionary,
            let frame = CGRect(dictionaryRepresentation: boundsDict)
        else {
            return nil
        }

        let isOnScreen = numberValue(kCGWindowIsOnscreen, in: cgWindowInfo)?.boolValue ?? false
        let windowName = cgWindowInfo[kCGWindowName as String] as? String ?? ""

        return [
            "SCWindowID": windowID,
            "SCWindowBoundOriginX": frame.origin.x,
            "SCWindowBoundOriginY": frame.origin.y,
            "SCWindowBoundWidth": frame.size.width,
            "SCWindowBoundHeight": frame.size.height,
            "SCWindowName": windowName,
            "SCWindowIsOnScreen": isOnScreen,
            "SCWindowIsActive": isOnScreen,
            "SCWindowLayer": layer,
            "SCRunningApplicationPID": pid,
        ]
    }

    private static func numberValue(
        _ key: CFString,
        in dictionary: [String: Any]
    ) -> NSNumber? {
        dictionary[key as String] as? NSNumber
    }

    @MainActor
    static func getComfyWindowsPrivately(onScreenWindowsOnly: Bool) async -> [ComfySCWindow] {
        let privateWindows = getComfyWindowsPrivatelyOnly(onScreenWindowsOnly: onScreenWindowsOnly)
        if !privateWindows.isEmpty {
            return privateWindows
        }

        do {
            let content = try await SCShareableContent.excludingDesktopWindows(
                true,
                onScreenWindowsOnly: onScreenWindowsOnly
            )
            return ComfySCWindow.toComfySCWindows(content.windows)
        } catch {
            print("SCK fallback failed: \(error)")
            return []
        }
    }

    private static func getComfyWindowsPrivatelyOnly(onScreenWindowsOnly: Bool) -> [ComfySCWindow] {
        var options: CGWindowListOption = [.excludeDesktopElements]
        if onScreenWindowsOnly {
            options.insert(.optionOnScreenOnly)
        }

        guard let cgWindowList = CGWindowListCopyWindowInfo(
            options,
            kCGNullWindowID
        ) as? [[String: Any]] else {
            print("Failed to read window list from CoreGraphics")
            return []
        }

        let compiledSCWindows = cgWindowList.compactMap {
            Self.makeWindow(from: $0)
        }

        let windows: [ComfySCWindow] = ComfySCWindow.toComfySCWindows(compiledSCWindows)
        if windows.isEmpty {
            print("No Windows Extracted Privately")
        }

        return windows
    }
}
