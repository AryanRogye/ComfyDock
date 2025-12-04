// The Swift Programming Language
// https://docs.swift.org/swift-book

import Foundation
import AppKit

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


/// For Now Simple Thing -
/// Is Dock Showing?

private struct DockConfigurations {
    public let pollingInterval : TimeInterval
    
    init(pollingInterval: TimeInterval) {
        self.pollingInterval = pollingInterval
    }
}

@Observable @MainActor
public class DockControls {
    
    public var isDockShowing: Bool = false
    public var dockPosition: DockPosition = .unknown
    public var dockRect : CGRect = .zero

    private var isPolling = false
    fileprivate let dockConfigurations : DockConfigurations
    
    private var lastRect  : CGRect = .zero
    
    public init() {
        dockConfigurations = DockConfigurations(pollingInterval: 0.5)
    }
    
    public func startPolling(completion : @escaping (CGRect) -> Void) async throws {
        
        if isPolling { return }
        isPolling = true

        defer { isPolling = false }
        while !Task.isCancelled {
            var rect = getDockRect()
            
            let tile = CGFloat(CoreDockGetTileSize())
            let dockHeight = tile + 18.0
            
            rect = CGRect(
                x: rect.minX,
                y: rect.minY,
                width: rect.width,
                height: dockHeight
            )
            
            if rect != lastRect || isMouseNearDock() {
                let isShowing = isDockShowing(for: rect)
                isDockShowing = isShowing
                dockPosition = getCurrentDockPosition()
                lastRect = rect
                
                completion(rect)
                
                print("isShowing: \(isShowing)", "rect: \(rect), isMagnified: \(CoreDockIsMagnificationEnabled())")
            }
            
            try await Task.sleep(nanoseconds: UInt64(dockConfigurations.pollingInterval * 1_000_000_000))
        }

    }
    
    private func isMouseNearDock() -> Bool {
        let mouseLocation = NSEvent.mouseLocation
        let screenHeight = NSScreen.main?.frame.height ?? 0
        return mouseLocation.y < 100 // Within 100px of bottom
    }
    
    /// Function tells us if the dock is showing or not
    private func isDockShowing(for rect: CGRect) -> Bool {
        rect.height > 5
    }
    
    private func getDockRect() -> CGRect {
        var dockRect : CGRect = .zero
        CoreDockGetRect(&dockRect)
        
        return dockRect
    }
    
    
    
    
    
    /// Probably Dont Need Right now
    public func hideDock() {
        
        let dockEnabled = CoreDockGetAutoHideEnabled()
        
        /// If Dock Enabled, only then we set it hiding
        if !dockEnabled {
            setDockHiding(to: true)
            changeDockShowTime(to: 1000)
            restartDock()
        }
    }
    
    public func showDock() {
        
        let dockEnabled = CoreDockGetAutoHideEnabled()
        
        if dockEnabled {
            setDockHiding(to: false)
            resetAutoHide()
            
            restartDock()
        }
    }
    
    /// Helper For Now
    private func getCurrentDockPosition() -> DockPosition {
        
        var orientation: Int32 = 0
        var pinning: Int32 = 0
        CoreDockGetOrientationAndPinning(&orientation, &pinning)
        
        var dockPosition : DockPosition = .unknown
        switch orientation {
        case 1: dockPosition = .top
        case 2: dockPosition = .bottom
        case 3: dockPosition = .left
        case 4: dockPosition = .right
        default: dockPosition = .unknown
        }
        
        
        return dockPosition
    }
    

    private func setDockHiding(to value: Bool) {
        CoreDockSetAutoHideEnabled(value)
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



public enum DockPosition: String, CaseIterable {
    case top = "Top"
    case bottom = "Bottom"
    case left = "Left"
    case right = "Right"
    case unknown = "Unkown"
}
