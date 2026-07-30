//
//  CGSPrivate.swift
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


import CoreGraphics

@_silgen_name("CGSMainConnectionID")
public func CGSMainConnectionID() -> CGSConnectionID

@_silgen_name("CGSGetActiveSpace")
public func CGSGetActiveSpace(_ cid: CGSConnectionID) -> CGSSpaceID

@_silgen_name("CGSHWCaptureWindowList")
public func CGSHWCaptureWindowList(
    _ cid: CGSConnectionID,
    _ windowList: UnsafePointer<UInt32>?,
    _ count: CGSWindowCount,
    _ options: UInt32
) -> Unmanaged<CFArray>?

@_silgen_name("CGSGetWindowLevel")
func CGSGetWindowLevel(
    _ cid: CGSConnectionID,
    _ wid: UInt32,
    _ outLevel: UnsafeMutablePointer<Int32>?
) -> Int32

@_silgen_name("CGSCopyWindowProperty")
func CGSCopyWindowProperty(
    _ cid: CGSConnectionID,
    _ wid: UInt32,
    _ key: CFString,
    _ outValue: UnsafeMutablePointer<CFTypeRef?>?
) -> Int32

/**
 * Usage:
 * func getSpacesForWindow(in cid: CGSConnectionID, window: ComfyWindow) -> [CGSSpaceID]? {
 *     guard let wid = window.windowID else { return nil }
 *     let windowIDs = [NSNumber(value: Int(wid))] as CFArray
 *     guard let unmanaged = CGSCopySpacesForWindows(
 *         cid,
 *         kCGSAllSpacesMask,
 *         windowIDs
 *     ) else {
 *         return nil
 *     }
 *     let nums = unmanaged.takeRetainedValue() as NSArray as? [NSNumber] ?? []
 *     return nums.map { CGSSpaceID($0.uint64Value) }
 }
 */
@_silgen_name("CGSCopySpacesForWindows")
public func CGSCopySpacesForWindows(
    _ cid: CGSConnectionID,
    _ mask: CGSSpaceMask,
    _ windowIDs: CFArray
) -> Unmanaged<CFArray>?

/**
 * Usage:
 * func getSpacesArray(from cid: CGSConnectionID) -> [CGSSpaceID]? {
 *     return CGSCopySpaces(cid, 7)?.takeRetainedValue() as? [CGSSpaceID]
 * }
 */
@_silgen_name("CGSCopySpaces")
func CGSCopySpaces(
    _ cid: CGSConnectionID,
    _ mask: Int
) -> Unmanaged<CFArray>?

@_silgen_name("CGSRemoveWindowsFromSpaces")
func CGSRemoveWindowsFromSpaces(
    _ cid: CGSConnectionID,
    _ windows: CFArray,
    _ spaces: CFArray
)

@_silgen_name("CGSAddWindowsToSpaces")
func CGSAddWindowsToSpaces(
    _ cid: CGSConnectionID,
    _ windows: CFArray,
    _ spaces: CFArray
)

@_silgen_name("CGSManagedDisplaySetCurrentSpace")
func CGSManagedDisplaySetCurrentSpace(
    _ cid: CGSConnectionID,
    _ display: CFString,
    _ space: CGSSpaceID
)

struct CGSWindowCaptureOptions: OptionSet {
    let rawValue: UInt32
    
    static let ignoreGlobalClipShape = CGSWindowCaptureOptions(rawValue: 1 << 11)
    static let nominalResolution     = CGSWindowCaptureOptions(rawValue: 1 << 9)
    static let bestResolution        = CGSWindowCaptureOptions(rawValue: 1 << 8)
    static let fullSize              = CGSWindowCaptureOptions(rawValue: 1 << 19)
}

public let kCGSAllSpacesMask: CGSSpaceMask = CGSSpaceMask.max
