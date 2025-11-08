//
//  DockManager.swift
//  ComfyDock
//
//  Created by Aryan Rogye on 11/7/25.
//

import SwiftUI

@Observable @MainActor
public class DockManager {
    var height: CGFloat = 60
    var paddingFromBottom : CGFloat = 5
    var isVisible = true
    
    var runningApps : [RunningApp] = []
    var isHoveringOverXcodeRects = false
}
