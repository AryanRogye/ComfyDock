//
//  CGRect+convertToAppKit.swift
//  DockExperiment
//
//  Created by Aryan Rogye on 7/29/26.
//

import AppKit

extension CGRect {
    
    /// Converts a rect from a top-left origin to a bottom-left origin.
    func convertToAppKit() -> CGRect {
        let rect = self
        let mainDisplayHeight = CGDisplayBounds(CGMainDisplayID()).height
        
        return CGRect(
            x: rect.minX,
            y: mainDisplayHeight - rect.maxY,
            width: rect.width,
            height: rect.height
        )
    }
}
