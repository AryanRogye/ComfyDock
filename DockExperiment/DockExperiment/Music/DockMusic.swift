//
//  DockMusic.swift
//  ComfyDock
//
//  Created by Aryan Rogye on 11/9/25.
//

import AppKit
import SwiftUI

struct DockMusic: View {

    let height: CGFloat
    @Bindable var audioManager : AudioManager
    
    // height, we set -7 to bring it up from the ground
    var adjustedHeight: CGFloat {
        height - 7
    }

    @State var metalAnimationState = MetalAnimationState()
    @State private var hoverTask: DispatchWorkItem?

    var body: some View {
        HStack(alignment: .center) {

            AlbumCover(dockHeight: adjustedHeight, audioManager: audioManager)
                .frame(alignment: .leading)

//            // MARK: - Song Information and Controls
            VStack(alignment: .leading, spacing: 0) {
                /// name/artist/album
                renderSongInformation()
                    .padding(.top, 2)
                
                /// Slider
                AudioSlider(audioManager: audioManager)
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
                
                /// Button
                AudioControls(audioManager: audioManager)
            }
            .padding(.leading, 1)
            .frame(height: adjustedHeight, alignment: .topLeading)
        }
        // inner horizontal padding
        .padding(.horizontal, 4)
        // width of the music player
        .frame(maxWidth: 200, alignment: .leading)
        .frame(height: adjustedHeight)
        .background {
            AppKitGlassBackground()
        }
        // this is the way that the dock positions windows on top
        .padding(.top, 1)
    }
    
    var shouldBlur : Bool {
        true
    }
    
    private func renderSongInformation() -> some View {
        VStack(alignment: .leading, spacing: -1) {
            Text(audioManager.nowPlayingInfo.trackName)
                .font(.system(size: 11, weight: .semibold, design: .rounded))
                .foregroundColor(.white)
                .lineLimit(1)
                .truncationMode(.tail)

            // Artist name
            Text(audioManager.nowPlayingInfo.artistName)
                .font(.system(size: 9, weight: .medium, design: .rounded))
                .foregroundColor(.white.opacity(0.8))
                .lineLimit(1)
                .truncationMode(.tail)
        }
    }
}

private struct AppKitGlassBackground: NSViewRepresentable {
    func makeNSView(context: Context) -> NSGlassEffectView {
        let glassView = NSGlassEffectView()
        glassView.style = .clear
        glassView.tintColor = .black.withAlphaComponent(0.1)
        glassView.cornerRadius = 12
        glassView.effectIsInteractive = true
        return glassView
    }

    func updateNSView(_ glassView: NSGlassEffectView, context: Context) {
        glassView.style = .clear
        glassView.cornerRadius = 12
        glassView.effectIsInteractive = true
    }
}
