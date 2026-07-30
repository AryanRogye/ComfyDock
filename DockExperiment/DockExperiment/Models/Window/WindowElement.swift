//
//  WindowElement.swift
//  DockExperiment
//
//  Created by Aryan Rogye on 7/29/26.
//


//
//  WindowElement.swift
//  ComfyTileApp
//
//  Created by Aryan Rogye on 1/15/26.
//

import Cocoa

public class WindowElement {
    public var element: AXUIElement?
    
    public init(element: AXUIElement?) {
        self.element = element
    }
    
    public var title: String? {
        get {
            return element?.getWrappedValue(.title)
        }
    }
    
    public var windows: [WindowElement]? {
        guard let windows = try? element?.windows() else { return nil }
        var wins: [WindowElement] = []
        for window in windows {
            wins.append(.init(element: window))
        }
        return wins
    }
    
    public var windowsRaw: [AXUIElement]? {
        guard let windows = try? element?.windows() else { return nil }
        return windows
    }
    
    public var frame: CGRect {
        guard let position = position, let size = size else { return .null }
        return .init(origin: position, size: size)
    }
    
    @MainActor
    public var cgWindowID: CGWindowID? {
        get {
            return element?._cgWindowID()
        }
    }
    
    public var size: CGSize? {
        get {
            element?.getWrappedValue(.size)
        }
        set {
            guard let newValue = newValue else { return }
            element?.setValue(.size, newValue)
        }
    }
    
    public var position: CGPoint? {
        get {
            element?.getWrappedValue(.position)
        }
        set {
            guard let newValue = newValue else { return }
            element?.setValue(.position, newValue)
        }
    }
    
    public var windowFrame: CGRect? {
        guard let position else { return nil }
        guard let size else { return nil }
        return CGRect(origin: position, size: size)
    }
    
    public func setPosition(x: CGFloat, y: CGFloat) {
        position = CGPoint(x: x, y: y)
    }
    
    public func setSize(width: CGFloat, height: CGFloat) {
        size = CGSize(width: width, height: height)
    }
    
    public func setFrame(_ frame: CGRect, adjustSizeFirst: Bool = true) {
        if adjustSizeFirst {
            size = frame.size
        }
        position = frame.origin
        size = frame.size
    }
    
    public func toggleMinimize() {
        guard let element else { return }
        guard let isMinimized = try? element.isMinimized() else { return }
        
        let newValue: CFBoolean = isMinimized ? kCFBooleanFalse : kCFBooleanTrue
        element.setValue(.minimized, newValue)
    }
    
    public func quit() {
        guard let element else { return }
        guard let closeButton = try? element.closeButton() else { return }
        try? closeButton.performAction(kAXPressAction)
    }
}
