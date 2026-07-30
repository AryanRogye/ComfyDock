//
//  DockObserver.swift
//  DockExperiment
//
//  Created by Aryan Rogye on 7/29/26.
//

import Cocoa

final class DockObserver {
    
    let windowCore: WindowCore
    var dockSubscription: AXListSubscription?
    var onDockRectFound: ((CGRect) -> Void)?
    var onNoHover: (() -> Void)?
    private var hoverRefreshTask: Task<Void, Never>?
    
    init(windowCore: WindowCore) {
        self.windowCore = windowCore
    }
    
    public func observeDock() {
        guard dockSubscription == nil else {
            print("Dock Subscription Already Exists")
            return
        }
        guard let dockPID = getDockPID() else {
            print("Coudlnt Find Dock PID")
            return
        }
        let dockApplication = AXUIElementCreateApplication(dockPID)
        
        // get children of the dock
        guard let children = try? dockApplication.children() else {
            print("No Children Found")
            return
        }
        
        // we try to grab the list of dock elements
        guard let dockList = try? children.first(where: {
            try $0.role() == kAXListRole
        })
        else {
            print("No Dock List Found")
            return
        }
        
        if let sub = AXListSubscription(pid: dockPID, forlist: dockList) {
            dockSubscription = sub
            dockSubscription?.onChange = { [weak self] pid, element, notification in
                guard let self else { return }
                
                print("got notification: \(notification)")
                
                guard notification as String ==
                        kAXSelectedChildrenChangedNotification
                else {
                    return
                }

                hoverRefreshTask?.cancel()
                hoverRefreshTask = Task { [weak self] in
                    guard let self else { return }

                    let refreshDelays: [Duration] = [
                        .milliseconds(16),
                        .milliseconds(34),
                        .milliseconds(50),
                        .milliseconds(66),
                    ]

                    for (index, delay) in refreshDelays.enumerated() {
                        try? await Task.sleep(for: delay)
                        guard !Task.isCancelled else { return }

                        let selected = try? dockList.attribute(
                            kAXSelectedChildrenAttribute,
                            [AXUIElement].self
                        )

                        guard selected?.first != nil else {
                            if index == 0 {
                                onNoHover?()
                            }
                            return
                        }

                        guard let magnifiedBounds = currentBounds(of: dockList) else {
                            return
                        }

                        print("Magnified AX bounds:", magnifiedBounds)
                        onDockRectFound?(magnifiedBounds)
                    }
                }
            }
        }
    }

    private func currentBounds(of dockList: AXUIElement) -> CGRect? {
        guard let dockItems = try? dockList.children() else {
            return nil
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

        return frames.reduce(nil) { current, frame in
            current?.union(frame) ?? frame
        }
    }
    
    private func getDockPID() -> pid_t? {
        guard let dock = windowCore.windows.first(where: {
            $0.bundleIdentifier == "com.apple.dock"
        }) else {
            return nil
        }
        return dock.pid
    }

}
