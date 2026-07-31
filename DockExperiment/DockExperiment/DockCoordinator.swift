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

    private var dockOrientation: Int32 = 0

    var isAutoHideEnabled: Bool {
        CoreDockGetAutoHideEnabled()
    }

    /// Captures a real, fully revealed Dock frame before the preview UI is
    /// created. An auto-hidden Dock otherwise reports only its trigger strip,
    /// which is not a valid height for initializing DockContentView.
    @discardableResult
    @MainActor
    public func primeDockTracking() async -> Bool {
        let wasAutoHideEnabled = CoreDockGetAutoHideEnabled()

        var orientation: Int32 = 0
        var pinning: Int32 = 0
        CoreDockGetOrientationAndPinning(&orientation, &pinning)
        dockOrientation = orientation

        guard wasAutoHideEnabled else {
            getCoreDockRect()
            return false
        }

        CoreDockSetAutoHideEnabled(false)

        let minimumRevealedThickness = max(
            CGFloat(CoreDockGetTileSize()) * 0.75,
            6
        )

        var previousRect: CGRect?
        var stableFrameCount = 0
        var capturedRect: CGRect?

        // Two seconds covers the normal auto-hide delay and reveal animation
        // without leaving the user's preference temporarily disabled for long.
        for _ in 0..<120 {
            let rect = currentDockRect()
            let thickness = orientation == 3 || orientation == 4
                ? rect.width
                : rect.height

            if rect.width > 0,
               rect.height > 0,
               thickness >= minimumRevealedThickness {
                capturedRect = rect

                if let previousRect,
                   framesAreApproximatelyEqual(previousRect, rect) {
                    stableFrameCount += 1
                } else {
                    stableFrameCount = 0
                }

                previousRect = rect
                if stableFrameCount >= 3 {
                    break
                }
            }

            try? await Task.sleep(for: .milliseconds(16))
        }

        guard let capturedRect else { return true }
        publishDockRect(capturedRect)
        return true
    }

    /// Completes the two-phase priming lifecycle after the Dock AX observer has
    /// attached while the Dock is still revealed.
    public func finishDockTrackingPrime(restoreAutoHide: Bool) {
        guard restoreAutoHide else { return }
        CoreDockSetAutoHideEnabled(true)
    }
    
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
        let rect = currentDockRect()

        // Once primed, the auto-hidden trigger strip must never replace the
        // real base geometry used by hover and magnification calculations.
        if isAutoHideEnabled, !isUsableVisibleDockRect(rect) {
            return
        }

        publishDockRect(rect)
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

    private func currentDockRect() -> CGRect {
        var rect: CGRect = .zero
        CoreDockGetRect(&rect)
        return rect
    }

    private func publishDockRect(_ rect: CGRect) {
        dockRect = rect
        onDockRectFound?(rect)
    }

    private func isUsableVisibleDockRect(_ rect: CGRect) -> Bool {
        let thickness = dockOrientation == 3 || dockOrientation == 4
            ? rect.width
            : rect.height
        return rect.width > 0 && rect.height > 0 && thickness > 5
    }

    private func framesAreApproximatelyEqual(
        _ lhs: CGRect,
        _ rhs: CGRect
    ) -> Bool {
        let tolerance: CGFloat = 0.5
        return abs(lhs.minX - rhs.minX) <= tolerance &&
            abs(lhs.minY - rhs.minY) <= tolerance &&
            abs(lhs.width - rhs.width) <= tolerance &&
            abs(lhs.height - rhs.height) <= tolerance
    }
}
