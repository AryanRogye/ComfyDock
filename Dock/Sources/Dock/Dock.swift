// The Swift Programming Language
// https://docs.swift.org/swift-book

import Foundation

/*
 * autohide-delay: the wait time after your cursor hits the screen edge before
 *                 the dock even begins to appear.
 * ------------------------------------------------------┐
 * defaults write com.apple.dock autohide-delay -float 60|
 * ------------------------------------------------------┘
 *
 * autohide-time-modifier: the duration of the slide animation once it does start
 * --------------------------------------------------------------┐
 * defaults write com.apple.dock autohide-time-modifier -float 2;|
 * --------------------------------------------------------------┘
 *
 * Revert Dock To Default:
 * -----------------------------------------------------┐
 * defaults delete com.apple.dock autohide-delay        |
 * defaults delete com.apple.dock autohide-time-modifier|
 * killall Dock                                         |
 * -----------------------------------------------------┘
 */

@Observable @MainActor
public class Dock {
    
    var hidden = true
    
    public init() {}
    
    public func hideDock() {
        setDockHiding(to: true)
        changeDockShowTime(to: 1000)
        
        restartDock()
    }
    
    public func showDock() {
        setDockHiding(to: false)
        resetAutoHide()
        
        restartDock()
    }

    private func setDockHiding(to value: Bool) {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/defaults")
        process.arguments = ["write", "com.apple.dock", "autohide", "-bool", "\(value ? "true" : "false")"]
        try? process.run()
        process.waitUntilExit()
    }
    
    private func changeDockShowTime(to value: CGFloat) {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/defaults")
        process.arguments = ["write", "com.apple.dock", "autohide-delay", "-float", "\(value)"]
        try? process.run()
        process.waitUntilExit()
    }
    
    private func resetAutoHide() {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/defaults")
        process.arguments = ["delete", "com.apple.dock", "autohide-delay"]
        try? process.run()
        process.waitUntilExit()
    }
    
    private func restartDock() {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/killall")
        process.arguments = ["Dock"]
        try? process.run()
        process.waitUntilExit()
    }
}
