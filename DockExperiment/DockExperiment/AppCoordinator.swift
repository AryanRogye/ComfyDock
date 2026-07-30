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
    
    

    init() {
        if !permissionService.isAccessibilityEnabled {
            permissionService.requestPermission()
        }
        if !permissionService.isScreenRecordingEnabled {
            permissionService.requestScreenRecordingPermission()
        }
        
        self.dockPreviewCoordinator = DockPreviewCoordinator()
        self.dockObserver = DockObserver(windowCore: windowCore)
        
        self.dockPreviewCoordinator.onGetCoreDockRect = { [weak self] in
            guard let self else { return }
            self.dockCoordinator.getCoreDockRect()
        }
        
        self.dockCoordinator.onDockRectFound = { [weak self] rect in
            guard let self else { return }
            self.dockPreviewCoordinator.dockCoordinatorDidFindBaseDock(rect)
        }
        
        /// Setting Up DockObserver Callback
        
        self.dockObserver.onNoHover = { [weak self] in
            guard let self else { return }
            self.dockCoordinator.getCoreDockRect()
            self.dockPreviewCoordinator.dockObserverDidCallNoHover()
        }
        self.dockObserver.onMagnifiedBoundsChanged = { [weak self] rect in
            guard let self else { return }
            self.dockPreviewCoordinator.dockObserverDidReceiveMagnifiedBoundsChanged(rect)
        }
        self.dockObserver.onDockMenuVisibilityChanged = { [weak self] isOpen in
            guard let self else { return }
            self.dockPreviewCoordinator.dockObserverDidReceiveDockMenuVisibilityChanged(isOpen: isOpen)
        }
        
        Task {
            await self.windowCore.loadWindows()
            self.dockObserver.observeDock()
            try? await Task.sleep(for: .seconds(1))
            self.dockCoordinator.getCoreDockRect()
        }
    }
}
