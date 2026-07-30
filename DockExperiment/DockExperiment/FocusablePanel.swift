//
//  FocusablePanel.swift
//  DockExperiment
//
//  Created by Aryan Rogye on 7/29/26.
//

import AppKit

/**
 * Custom NSPanel subclass that can become key and main window.
 * Enables proper focus and interaction handling.
 */
class FocusablePanel: NSPanel {
    override var canBecomeKey: Bool {
        return true
    }
    override var canBecomeMain: Bool {
        return true
    }
}
