//
//  DockMusic.swift
//  ComfyDock
//
//  Created by Aryan Rogye on 11/9/25.
//

import SwiftUI

struct DockMusic: View {

    @Bindable var dockManager  : DockManager
    @Bindable var audioManager : AudioManager

    @State var metalAnimationState = MetalAnimationState()
    
    var height : CGFloat {
        let height = dockManager.height
        return dockManager.hoveringOverMusicPlayer ? height + 10 : height
    }
    @State private var hoverTask: DispatchWorkItem?

    var body: some View {
        HStack(alignment: .center) {

            AlbumCover(dockManager: dockManager, audioManager: audioManager)
                .frame(alignment: .leading)

            // MARK: - Song Information and Controls
            VStack(alignment: .leading, spacing: 4) {
                /// name/artist/album
                renderSongInformation()
                    .padding(.top, 2)

                /// Slider
                if dockManager.hoveringOverMusicPlayer {
                    AudioSlider(audioManager: audioManager)
                        .transition(.opacity.combined(with: .move(edge: .bottom)))
                        .animation(.easeOut(duration: 0.16), value: self.dockManager.hoveringOverMusicPlayer)
                }

                /// Button
                AudioControls(dockManager: dockManager, audioManager: audioManager)
                    .padding(.top, dockManager.hoveringOverMusicPlayer ? 2 : 4)
            }
            .frame(maxHeight: height, alignment: .topLeading)
        }
        .padding(.horizontal, 4)

        .background {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(.clear)
                    .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 12))
                
                if dockManager.isVisible {
                    MetalBackground(audioManager: audioManager, metalAnimationState: metalAnimationState)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
        }
        .frame(maxWidth: self.dockManager.hoveringOverMusicPlayer ? 250 : 180, maxHeight: height, alignment: .leading)
        .padding(.bottom, dockManager.paddingFromBottom)
        .onHover { hovering in
            hoverTask?.cancel()
            
            let task = DispatchWorkItem {
                withAnimation(.interactiveSpring(response: 0.22, dampingFraction: 0.88)) {
                    /// Hover is only true, if and only if isPlaying AND is hovering
                    self.dockManager.hoveringOverMusicPlayer  = hovering && self.audioManager.nowPlayingInfo.isPlaying
                }
            }
            hoverTask = task
            
            // quick show, slower hide (hysteresis)
            let delay: Double = hovering ? 0.1 : 0.35
            DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: task)
        }
        .onChange(of: dockManager.isVisible) {
            handleBlurringBackground()
        }
        .onChange(of: audioManager.nowPlayingInfo.isPlaying) {
            handleBlurringBackground()
        }
    }
    
    
    var shouldBlur : Bool {
        dockManager.isVisible && audioManager.nowPlayingInfo.isPlaying
    }
    
    func handleBlurringBackground() {
        metalAnimationState.animateBlurProgress(
            /// if open then blur to 1, if its closed then blur to 0
            to: shouldBlur ? 1.0 : 0.0,
            /// if open then take 2 seconds to blur, if closed then take 0.5 seconds to unblur
            duration: shouldBlur ? 2 : 0.5
        )
    }

    private func renderSongInformation() -> some View {
        VStack(alignment: .leading, spacing: -1) {
            Text(audioManager.nowPlayingInfo.trackName)
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .foregroundColor(.primary)
                .lineLimit(1)
                .truncationMode(.tail)

            // Artist name
            Text(audioManager.nowPlayingInfo.artistName)
                .font(.system(size: 10, weight: .medium, design: .rounded))
                .foregroundColor(.secondary.opacity(0.8))
                .lineLimit(1)
                .truncationMode(.tail)
        }
    }
}
