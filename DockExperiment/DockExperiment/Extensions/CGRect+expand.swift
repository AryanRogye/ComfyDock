//
//  CGRect+expand.swift
//  DockExperiment
//
//  Created by Aryan Rogye on 7/29/26.
//
import CoreGraphics

extension CGRect {
    /// Expands the rectangle equally on all sides.
    func expanded(by amount: CGFloat) -> CGRect {
        CGRect(
            x: origin.x - amount,
            y: origin.y - amount,
            width: width + amount * 2,
            height: height + amount * 2
        )
    }
}
