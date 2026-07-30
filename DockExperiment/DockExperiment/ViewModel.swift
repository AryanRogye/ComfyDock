//
//  ViewModel.swift
//  DockExperiment
//
//  Created by Aryan Rogye on 7/29/26.
//

import Foundation
import Dock
import AppKit

@Observable
@MainActor
final class ViewModel {
    
    let permissionService = PermissionService()
    var windowCore: WindowCore?
    var orientation: DockOrientation?
    var dockRect: CGRect?
    var isDockHidden: Bool = false
    var dockTileSize: Float?
    
    var onDockRectFound: ((CGRect) -> Void)?
    private var dockObserver: AXObserver?
    private var observedDockList: AXUIElement?
    
    @MainActor
    deinit {
        detachDockObserver()
    }
    
    @MainActor
    public func attachObserverOnDock(dockPID: pid_t) {
        detachDockObserver()

        let dockApplication = AXUIElementCreateApplication(dockPID)
        
        guard
            let children = try? dockApplication.children(),
            let dockList = try? children.first(where: {
                try $0.role() == kAXListRole
            })
        else {
            return
        }
        
        var observer: AXObserver?
        guard
            AXObserverCreate(dockPID, Self.callback, &observer) == .success,
            let observer
        else {
            return
        }
        
        let result = AXObserverAddNotification(
            observer,
            dockList,
            kAXSelectedChildrenChangedNotification as CFString,
            Unmanaged.passUnretained(self).toOpaque()
        )
        
        guard result == .success ||
                result == .notificationAlreadyRegistered
        else {
            return
        }
        
        CFRunLoopAddSource(
            CFRunLoopGetMain(),
            AXObserverGetRunLoopSource(observer),
            .commonModes
        )
        
        dockObserver = observer
        observedDockList = dockList
        print("Attached Observer")
    }
    
    @MainActor
    public func detachDockObserver() {
        if let observer = dockObserver,
           let dockList = observedDockList {
            AXObserverRemoveNotification(
                observer,
                dockList,
                kAXSelectedChildrenChangedNotification as CFString
            )
            
            CFRunLoopRemoveSource(
                CFRunLoopGetMain(),
                AXObserverGetRunLoopSource(observer),
                .commonModes
            )
        }
        
        dockObserver = nil
        observedDockList = nil
    }

    
    private static let callback: AXObserverCallback = { observer, element, notification, refcon in
        
        guard let refcon else { return }
        
        let instance = Unmanaged<ViewModel>
            .fromOpaque(refcon)
            .takeUnretainedValue()
        
        instance.handle(
            element: element,
            notification: notification
        )
    }
    
    private func handle(element dockList: AXUIElement, notification: CFString) {
        print("got notification: \(notification)")
        
        guard notification as String ==
                kAXSelectedChildrenChangedNotification
        else {
            return
        }
        
        let selected = try? dockList.attribute(
            kAXSelectedChildrenAttribute,
            [AXUIElement].self
        )
        guard let _ = selected?.first else {
            getCoreDockRect()
            return
        }
        
        guard let dockItems = try? dockList.children() else {
            return
        }
        
        let frames = dockItems.compactMap { item -> CGRect? in
            guard
                let position: CGPoint = item.getWrappedValue(.position),
                let size: CGSize = item.getWrappedValue(.size),
                size.width > 0,
                size.height > 0
            else {
                return nil
            }
            
            return CGRect(origin: position, size: size)
        }
        
        guard let magnifiedBounds = frames.reduce(nil, {
            current, frame in current?.union(frame) ?? frame
        }) else {
            return
        }
        
        print("Magnified AX bounds:", magnifiedBounds)
        onDockRectFound?(magnifiedBounds)
    }

    
    init() {
        if !permissionService.isAccessibilityEnabled {
            permissionService.requestPermission()
        }
        if !permissionService.isScreenRecordingEnabled {
            permissionService.requestScreenRecordingPermission()
        }
        NotificationCenter.default.addObserver(
            forName: NSApplication.didChangeScreenParametersNotification,
            object: nil,
            queue: .main
        ) { _ in
            Task { @MainActor in
                self.getCoreDockRect()
            }
        }

        getDockHidden()
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
