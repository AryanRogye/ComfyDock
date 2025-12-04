//
//  MetalContext.swift
//  ComfyDock
//
//  Created by Aryan Rogye on 11/12/25.
//

import Metal
import MetalKit

final class MetalContext {
    static let shared = MetalContext()
    
    let device: MTLDevice
    let queue: MTLCommandQueue
    let library: MTLLibrary
    
    private init() {
        device = MTLCreateSystemDefaultDevice()!
        queue  = device.makeCommandQueue()!
        library = try! device.makeDefaultLibrary(bundle: .main)
    }
}
