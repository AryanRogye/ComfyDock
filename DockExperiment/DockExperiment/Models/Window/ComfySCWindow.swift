//
//  ComfySCWindow.swift
//  DockExperiment
//
//  Created by Aryan Rogye on 7/29/26.
//

import ScreenCaptureKit

import Foundation

/// SCWindow is not Sendable, by only allowing what we need to be sendable
/// we can run certain parts on a background thread
public final class ComfySCWindow: Sendable {
    let windowLayer: Int
    let frame: CGRect
    let owningApplication: SCRunningApplication?
    let windowID: CGWindowID
    
    /// static function to convert a array of `SCWindow` to ComfySCWindow
    public static func toComfySCWindows(_ windows: [SCWindow]) -> [ComfySCWindow] {
        var cscWindow : [ComfySCWindow] = []
        cscWindow.reserveCapacity(windows.count)
        
        for win in windows {
            cscWindow.append(ComfySCWindow(window: win))
        }
        
        return cscWindow
    }

    init(
        window: SCWindow,
    ) {
        self.frame = window.frame
        self.owningApplication = window.owningApplication
        self.windowID = window.windowID
        self.windowLayer = window.windowLayer
    }
    
    init(
        windowLayer: Int,
        frame: CGRect,
        owningApplication: SCRunningApplication?,
        windowID: CGWindowID
    ) {
        self.windowLayer = windowLayer
        self.frame = frame
        self.owningApplication = owningApplication
        self.windowID = windowID
    }
}
