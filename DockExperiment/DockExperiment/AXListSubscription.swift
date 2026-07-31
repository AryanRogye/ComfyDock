//
//  AXListSubscription.swift
//  DockExperiment
//
//  Created by Aryan Rogye on 7/29/26.
//

import ApplicationServices

public final class AXListSubscription {
    let pid: pid_t
    var observer: AXObserver? = nil
    var list: AXUIElement? = nil
    var onChange: ((pid_t, AXUIElement, CFString) -> Void)?

    init?(pid: pid_t, forlist list: AXUIElement) {
        self.pid = pid
        
        var obs: AXObserver?
        let err = AXObserverCreate(pid, Self.callback, &obs)
        
        guard err == .success, let observer = obs else {
            return nil
        }
        
        let result = AXObserverAddNotification(
            observer,
            list,
            kAXSelectedChildrenChangedNotification as CFString,
            Unmanaged.passUnretained(self).toOpaque()
        )
        
        guard result == .success ||
                result == .notificationAlreadyRegistered
        else {
            return nil
        }
        
        self.observer = observer
        self.list = list

        CFRunLoopAddSource(
            CFRunLoopGetMain(),
            AXObserverGetRunLoopSource(observer),
            .commonModes
        )
    }
    
    deinit {
        if let observer,
           let list {
            AXObserverRemoveNotification(
                observer,
                list,
                kAXSelectedChildrenChangedNotification as CFString
            )

            CFRunLoopRemoveSource(
                CFRunLoopGetMain(),
                AXObserverGetRunLoopSource(observer),
                .commonModes
            )
        }
        
        observer = nil
        list = nil
    }

    private static let callback: AXObserverCallback = { observer, element, notification, refcon in
        
        guard let refcon else { return }
        
        let instance = Unmanaged<AXListSubscription>
            .fromOpaque(refcon)
            .takeUnretainedValue()
        
        instance.handle(
            element: element,
            notification: notification
        )
    }
    
    private func handle(element: AXUIElement, notification: CFString) {
        onChange?(pid, element, notification)
    }
}
