//
//  OnboardingView.swift
//  ComfyDock
//
//  Created by Aryan Rogye on 11/12/25.
//

import SwiftUI
import Metal
import MetalKit

struct OnboardingView: View {
    var body: some View {
        ZStack {
            OnboardingBackgroundView()
        }
    }
}


struct OnboardingBackgroundView: View {
    @State private var glowOpacity: CGFloat = 0
    @State private var particleOpacity : CGFloat = 0.2
    @State private var glowScale: CGFloat = 0.8
    @State private var particlesActive = false
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Base background with black gradient
                Color.black
                    .overlay(
                        LinearGradient(
                            colors: [
                                Color.black,
                                Color.black.opacity(0.8),
                                Color.black.opacity(0.6)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .ignoresSafeArea()
                
                // Animated glow effect
                Circle()
                    .fill(Color.accentColor)
                    .frame(width: min(geometry.size.width, geometry.size.height) * 0.4)
                    .blur(radius: 100)
                    .opacity(glowOpacity)
                    .scaleEffect(glowScale)
                    .position(
                        x: geometry.size.width * 0.5,
                        y: geometry.size.height * 0.3
                    )
                
                // Enhanced particles with reduced opacity
                ParticlesView(isActive: $particlesActive)
                    .opacity(particleOpacity)
            }
        }
        .onAppear {
            startAnimations()
        }
    }
    
    private func startAnimations() {
        // Glow animation
        withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
            
            particleOpacity = 0.4
            glowOpacity = 0.5
            glowScale = 1.2
        }
        
        // Start particles
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            particlesActive = true
        }
    }
}


struct Uniforms {
    var time: Float
    var size: simd_float2   // drawable size in px
    var count: UInt32
    var baseScale: Float    // 3
    var speed: Float        // 0.3
}

struct ParticlesView: NSViewRepresentable {
    
    @Binding var isActive: Bool
    
    var ctx = MetalContext.shared
    
    func makeCoordinator() -> ParticlesCoordinator {
        ParticlesCoordinator(self)
    }
    
    func makeNSView(context: Context) -> MTKView {
        let mtkView = MTKView()
        mtkView.device = ctx.device
        mtkView.delegate = context.coordinator
        mtkView.layer?.isOpaque = false
        mtkView.layer?.backgroundColor = NSColor.clear.cgColor
        
        mtkView.colorPixelFormat = .bgra8Unorm
        mtkView.clearColor = MTLClearColor(red: 0, green: 0, blue: 0, alpha: 0)
        mtkView.autoResizeDrawable = true
        mtkView.framebufferOnly = true
        
        mtkView.enableSetNeedsDisplay = false
        mtkView.isPaused = false
        
        return mtkView
    }
    
    func updateNSView(_ nsView: MTKView, context: Context) {
    }
}



class ParticlesCoordinator : NSObject, MTKViewDelegate {
    
    var device : MTLDevice!
    var queue : MTLCommandQueue!
    var parent : ParticlesView
    
    let count = 100
    
    private var pso: MTLRenderPipelineState!
    
    private var particlesBuffer   : MTLBuffer!
    
    init(_ parent: ParticlesView) {
        self.parent = parent
        
        super.init()
        
        setupMetal()
    }
    
    private func setupMetal() {
        device = parent.ctx.device
        queue  = parent.ctx.queue
        let lib = parent.ctx.library
        
        let desc = MTLRenderPipelineDescriptor()
        desc.vertexFunction   = lib.makeFunction(name: "vs_particles")
        desc.fragmentFunction = lib.makeFunction(name: "fs_particles")
        desc.colorAttachments[0].pixelFormat = .bgra8Unorm
        
        // Additive blending BEFORE makeRenderPipelineState
        let att = desc.colorAttachments[0]!
        att.isBlendingEnabled = true
        att.rgbBlendOperation = .add
        att.alphaBlendOperation = .add
        att.sourceRGBBlendFactor = .one
        att.sourceAlphaBlendFactor = .one
        att.destinationRGBBlendFactor = .one
        att.destinationAlphaBlendFactor = .one
        
        pso = try! device.makeRenderPipelineState(descriptor: desc)
    }
    
    func draw(in view: MTKView) {
        guard let rpd = view.currentRenderPassDescriptor,
              let drw = view.currentDrawable else { return }
        
        let cmd = queue.makeCommandBuffer()!
        let enc = cmd.makeRenderCommandEncoder(descriptor: rpd)!
        
        var u = Uniforms(
            time: Float(CACurrentMediaTime()),
            size: .init(Float(view.drawableSize.width), Float(view.drawableSize.height)),
            count: UInt32(count),
            baseScale: 3,
            speed: 0.3
        )
        
        enc.setRenderPipelineState(pso)
        enc.setVertexBytes(
            &u,
            length: MemoryLayout<Uniforms>.stride,
            index: 0
        )
        
        enc.drawPrimitives(type: .point, vertexStart: 0, vertexCount: Int(u.count))
        
        cmd.addCompletedHandler { cb in
            /// Once Command Buffer is done
        }
        
        enc.endEncoding()
        cmd.present(drw)
        cmd.commit()
    }
    
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        
    }
}
