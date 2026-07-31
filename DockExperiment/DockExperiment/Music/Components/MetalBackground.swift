//
//  MetalBackground.swift
//  ComfyDock
//
//  Created by Aryan Rogye on 11/9/25.
//

import AppKit
import Metal
import MetalKit
import SwiftUI

enum ShaderOption: String, CaseIterable {
    case ambientGradient = "ambientGradient"
    case spotlight = "spotlight"
    case rippleEffect = "rippleEffect"
    case plasmaWave = "plasmaWave"
    case vortexSpiral = "vortexSpiral"
    case breathingGlow = "breathingGlow"
    case electricGrid = "electricGrid"
    case noiseClouds = "noiseClouds"
    case pulsingDots = "pulsingDots"
    case waveInterference = "waveInterference"
    case hexagonPattern = "hexagonPattern"
    case flowingLines = "flowingLines"
    
    var displayName: String {
        switch self {
        case .ambientGradient: return "Ambient Gradient"
        case .spotlight: return "Spotlight"
        case .rippleEffect: return "Ripple Effect"
        case .plasmaWave: return "Plasma Wave"
        case .vortexSpiral: return "Vortex Spiral"
        case .breathingGlow: return "Breathing Glow"
        case .electricGrid: return "Electric Grid"
        case .noiseClouds: return "Noise Clouds"
        case .pulsingDots: return "Pulsing Dots"
        case .waveInterference: return "Wave Interference"
        case .hexagonPattern: return "Hexagon Pattern"
        case .flowingLines: return "Flowing Lines"
        }
    }
}

@Observable
final class MetalAnimationState {
    
    var blurProgress: Float = 0.0
    
    private var animationTimer: DispatchSourceTimer?
    private var animationStartTime: CFTimeInterval = 0
    private var animationStartValue: Float = 0
    private var animationTargetValue: Float = 0
    private var animationDuration: TimeInterval = 0
    
    /// This is used when opening the panel to animate the blur effect
    func animateBlurProgress(to targetValue: Float, duration: TimeInterval = 2.0) {
        animationTimer?.cancel()
        
        animationStartTime = CACurrentMediaTime()
        animationStartValue = blurProgress
        animationTargetValue = targetValue
        animationDuration = duration
        
        animationTimer = DispatchSource.makeTimerSource(queue: .main)
        animationTimer?.schedule(deadline: .now(), repeating: 1.0/120.0)
        
        animationTimer?.setEventHandler { [weak self] in
            self?.updateAnimation()
        }
        
        animationTimer?.resume()
    }
    
    func stopAnimatingBlur(snapToTarget: Bool = false) {
        animationTimer?.cancel()
        animationTimer = nil
        
        if snapToTarget {
            blurProgress = animationTargetValue
        }
    }
    
    private func updateAnimation() {
        let elapsed = CACurrentMediaTime() - animationStartTime
        let progress = min(elapsed / animationDuration, 1.0)
        
        let easedProgress = progress * progress * (3.0 - 2.0 * progress)
        blurProgress = animationStartValue + (animationTargetValue - animationStartValue) * Float(easedProgress)
        
        if progress >= 1.0 {
            animationTimer?.cancel()
            animationTimer = nil
        }
    }
}

struct MetalBackground: NSViewRepresentable {
    
    @Bindable var audioManager : AudioManager
    @Bindable var metalAnimationState : MetalAnimationState
    
    func makeCoordinator() -> RendererCoordinator { RendererCoordinator() }
    
    func updateNSView(_ nsView: MTKView, context: Context) {}
    
    let ctx = MetalContext.shared
    
    func makeNSView(context: Context) -> MTKView {
        let mtkView = MTKView()
        
        mtkView.device = ctx.device
        mtkView.layer?.isOpaque = false
        mtkView.clearColor = MTLClearColorMake(0, 0, 0, 0)
        mtkView.colorPixelFormat = .bgra8Unorm
        mtkView.delegate = context.coordinator
        mtkView.framebufferOnly = false
        mtkView.isPaused = false
        mtkView.enableSetNeedsDisplay = false
        mtkView.preferredFramesPerSecond = 120
        context.coordinator.targetView = mtkView
        context.coordinator.audioManager = audioManager
        context.coordinator.metalAnimationState = metalAnimationState
        context.coordinator.observeBlurProgress()
        return mtkView
    }
    
    class RendererCoordinator: NSObject, MTKViewDelegate {
        
        let ctx = MetalContext.shared
        var targetView: MTKView!
        var audioManager : AudioManager?
        var metalAnimationState : MetalAnimationState?
        private var startTime = CACurrentMediaTime()
        private var pipelineState: MTLRenderPipelineState!
        private var commandQueue: MTLCommandQueue!
        private var vertexBuffer: MTLBuffer!
        
        private var blurProgress: Float = 0.0
        private var animationName: String = "ambientGradient"
        
        override init() {
            super.init()
            setupMetal()
        }
        
        public func observeBlurProgress() {
            
            withObservationTracking {
                _ = metalAnimationState?.blurProgress
            } onChange: { [weak self] in
                guard let self = self else { return }
                DispatchQueue.main.async {
                    guard let animation = self.metalAnimationState else { return }
                    self.blurProgress = animation.blurProgress
                    print("Updating Blur Progress: \(self.blurProgress)")
                    self.observeBlurProgress()
                }
            }
        }
        
        private func drawBlankFrame() {
            guard let drawable = targetView.currentDrawable,
                  let descriptor = targetView.currentRenderPassDescriptor else { return }
            
            guard let commandBuffer = commandQueue.makeCommandBuffer() else { return }
            guard let encoder = commandBuffer.makeRenderCommandEncoder(descriptor: descriptor) else { return }
            
            descriptor.colorAttachments[0].clearColor = MTLClearColorMake(0, 0, 0, 0)
            descriptor.colorAttachments[0].loadAction = .clear
            descriptor.colorAttachments[0].storeAction = .store
            
            encoder.endEncoding()
            commandBuffer.present(drawable)
            commandBuffer.commit()
        }
        
        func draw(in view: MTKView) {
            if view.isPaused { return }
            guard let pipelineState = pipelineState else { return }
            guard let audioManager else { return }
            
            guard let drawable = view.currentDrawable,
                  let renderPassDescriptor = view.currentRenderPassDescriptor else { return }
            
            let commandBuffer = commandQueue.makeCommandBuffer()!
            let encoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor)!
            encoder.setRenderPipelineState(pipelineState)
            // This is us actually Setting the vertex passthrough to get the vertex out
            encoder.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
            
            var time = Float(CACurrentMediaTime() - startTime)
            encoder.setFragmentBytes(&time, length: MemoryLayout<Float>.size, index: 0)
            
            let dominantColor = audioManager.nowPlayingInfo.dominantColor.usingColorSpace(.deviceRGB) ?? .white
            /// Generate A Tint From The Dominant Color
            var tint = SIMD3<Float>(
                Float(dominantColor.redComponent),
                Float(dominantColor.greenComponent),
                Float(dominantColor.blueComponent)
            )
            encoder.setFragmentBytes(&tint, length: MemoryLayout<SIMD3<Float>>.size, index: 1)
            encoder.setFragmentBytes(&blurProgress, length: MemoryLayout<Float>.size, index: 2)
            
            encoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 6)
            encoder.endEncoding()
            
            commandBuffer.present(drawable)
            commandBuffer.commit()
        }
        
        private func setupMetal() {
            let device = ctx.device
            let library = ctx.library
            
            let pipelineDescriptor = MTLRenderPipelineDescriptor()
            
            pipelineDescriptor.vertexFunction = library.makeFunction(name: "vertexPassthrough")
            pipelineDescriptor.fragmentFunction = library.makeFunction(name: animationName)
            
            pipelineDescriptor.colorAttachments[0].pixelFormat = .bgra8Unorm
            
            do {
                pipelineState = try device.makeRenderPipelineState(descriptor: pipelineDescriptor)
            } catch {
                print("Failed to create pipeline state with animation '\(animationName)':", error)
                pipelineState = nil
            }
            commandQueue = ctx.queue
            
            let quadVertices: [Float] = [
                -1, -1, 0, 1,  // Bottom Left
                 1, -1, 1, 1,  // Bottom Right
                 -1,  1, 0, 0,  // Top Left
                 
                 -1,  1, 0, 0,  // Top Left
                 1, -1, 1, 1,  // Bottom Right
                 1,  1, 1, 0   // Top Right
            ]
            
            vertexBuffer = device.makeBuffer(bytes: quadVertices, length: MemoryLayout<Float>.size * quadVertices.count, options: [])
        }
        
        func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {}
    }
}
