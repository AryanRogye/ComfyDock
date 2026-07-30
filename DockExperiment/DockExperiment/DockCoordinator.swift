//
//  DockCoordinator.swift
//  DockExperiment
//
//  Created by Aryan Rogye on 7/29/26.
//

import Cocoa
import Dock

final class DockCoordinator {
    
    var orientation: DockOrientation?
    var dockRect: CGRect?
    var isDockHidden: Bool = false
    var dockTileSize: Float?
    var onDockRectFound: ((CGRect) -> Void)?
    
    public func getCoreDockOrientationAndPinning() {
        var orientation_local: Int32 = 0
        var outPinning_local: Int32 = 0
        CoreDockGetOrientationAndPinning(
            &orientation_local,
            &outPinning_local
        )
        self.orientation = .init(orientation_local)
    }
    
    public func getCoreDockRect() {
        var outRect: CGRect = .zero
        CoreDockGetRect(
            &outRect,
        )
        dockRect = outRect
        onDockRectFound?(outRect)
    }
    
    public func toggleDock() {
        CoreDockSetAutoHideEnabled(!isDockHidden)
        getDockHidden()
    }
    
    private func getDockHidden() {
        isDockHidden = CoreDockGetAutoHideEnabled()
    }
    
    public func getDockTileSize() {
        dockTileSize = CoreDockGetTileSize()
    }
}
