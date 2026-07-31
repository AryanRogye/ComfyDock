//
//  AppCoordinator.swift
//  DockExperiment
//
//  Created by Aryan Rogye on 7/30/26.
//

import AppKit
import SwiftUI

@MainActor
class AppCoordinator {
    
    let windowCoordinator = WindowCoordinator()
    let dockCoordinator = DockCoordinator()
    let windowCore = WindowCore()
    let dockObserver: DockObserver
    let dockPreviewCoordinator: DockPreviewCoordinator
    let permissionService = PermissionService()
    let audioManager = AudioManager()
    
    init() {
        if !permissionService.isAccessibilityEnabled {
            permissionService.requestPermission()
        }
        if !permissionService.isScreenRecordingEnabled {
            permissionService.requestScreenRecordingPermission()
        }
        
        self.dockPreviewCoordinator = DockPreviewCoordinator(audioManager: audioManager)
        self.dockObserver = DockObserver(windowCore: windowCore)
        
        self.dockPreviewCoordinator.onGetCoreDockRect = { [weak self] in
            guard let self else { return }
            self.dockCoordinator.getCoreDockRect()
        }

        self.dockPreviewCoordinator.shouldHideWhenTrackingEnds = { [weak self] in
            self?.dockCoordinator.usesAutoHide == true
        }
        
        self.dockCoordinator.onDockRectFound = { [weak self] rect in
            guard let self else { return }
            self.dockPreviewCoordinator.dockCoordinatorDidFindBaseDock(rect)
        }
        
        /// Setting Up DockObserver Callback
        
        self.dockObserver.onNoHover = { [weak self] in
            guard let self else { return }
            if self.dockCoordinator.usesAutoHide {
                self.dockPreviewCoordinator.autoHiddenDockDidLoseHover()
                return
            }

            self.dockCoordinator.getCoreDockRect()
            self.dockPreviewCoordinator.dockObserverDidCallNoHover()
        }
        self.dockObserver.onMagnifiedBoundsChanged = { [weak self] rect in
            guard let self else { return }
            if self.dockCoordinator.usesAutoHide {
                self.dockPreviewCoordinator.showPrimedDockPanels()
            }
            self.dockPreviewCoordinator.dockObserverDidReceiveMagnifiedBoundsChanged(rect)
        }
        Task {
            let startsAutoHidden = await self.dockCoordinator.primeDockTracking()
            defer {
                self.dockCoordinator.finishDockTrackingPrime(
                    restoreAutoHide: startsAutoHidden
                )
                if startsAutoHidden {
                    self.dockPreviewCoordinator.hidePrimedDockPanels()
                }
            }

            await self.windowCore.loadWindows()
            self.dockObserver.observeDock()
        }
    }
}
