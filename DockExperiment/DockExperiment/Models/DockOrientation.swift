//
//  DockOrientation.swift
//  DockExperiment
//
//  Created by Aryan Rogye on 7/29/26.
//

enum DockOrientation {
    case right
    case left
    case bottom
    case unknown(Int32)
    
    init(_ orientation: Int32) {
        if orientation == 4 {
            self = .right
        }
        else if orientation == 2 {
            self = .bottom
        }
        else if orientation == 3 {
            self = .left
        }
        else {
            self = .unknown(orientation)
        }
    }
    
    var label: String {
        switch self {
        case .right:
            "Right"
        case .left:
            "Left"
        case .bottom:
            "Bottom"
        case .unknown(let int32):
            "Unkown \(int32)"
        }
    }
}
