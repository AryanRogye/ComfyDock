//
//  NSScreen+screenContainingRect.swift
//  DockExperiment
//
//  Created by Aryan Rogye on 7/30/26.
//

import Cocoa

extension NSScreen {
    static func screen(containing rect: CGRect) -> NSScreen? {
        screens.max { lhs, rhs in
            lhs.frame.intersection(rect).area <
                rhs.frame.intersection(rect).area
        }
    }
}

private extension CGRect {
    var area: CGFloat {
        width * height
    }
}
