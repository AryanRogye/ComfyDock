//
//  AudioControls.swift
//  ComfyDock
//
//  Created by Aryan Rogye on 11/9/25.
//

import SwiftUI

struct AudioControls: View {
    
    @Bindable var audioManager : AudioManager
    
    private let forwardBackButtonWidth: CGFloat = 10
    private let forwardBackButtonHeight: CGFloat = 10
    
    private var iconWidth: CGFloat {
        return /*self.dockManager.hoveringOverMusicPlayer ? 10 :*/ 8
    }
    private var iconHeight: CGFloat {
        return /*self.dockManager.hoveringOverMusicPlayer ? 10 :*/ 9
    }
    
    private var buttonWidth : CGFloat {
        return /*self.dockManager.hoveringOverMusicPlayer ? 35 :*/ 20
    }
    private var buttonHeight: CGFloat {
        return /*self.dockManager.hoveringOverMusicPlayer ? 15 :*/ 12
    }
    
    var body: some View {
        HStack(spacing: 8) {
            Spacer()
            
            Button(action: {
                audioManager.playPreviousTrack()
            }) {
                // Apply image-specific modifiers here
                Image(systemName: "backward.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: forwardBackButtonWidth, height: forwardBackButtonHeight)
                    .foregroundColor(Color(nsColor: audioManager.nowPlayingInfo.dominantColor))
            }
            .buttonStyle(MusicControlButton(width: buttonWidth, height: buttonHeight, tint: audioManager.nowPlayingInfo.dominantColor)) // Apply custom style
            
            Button(action: {
                audioManager.togglePlayPause()
            }) {
                // Apply image-specific modifiers here
                Image(systemName: audioManager.nowPlayingInfo.isPlaying ? "pause.fill" : "play.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: iconWidth, height: iconHeight)
                    .foregroundColor(Color(nsColor: audioManager.nowPlayingInfo.dominantColor))
            }
            .buttonStyle(MusicControlButton(width: buttonWidth, height: buttonHeight, tint: audioManager.nowPlayingInfo.dominantColor)) // Apply custom style
            
            Button(action: {
                audioManager.playNextTrack()
            }) {
                // Apply image-specific modifiers here
                Image(systemName: "forward.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: forwardBackButtonWidth, height: forwardBackButtonHeight)
                    .foregroundColor(Color(nsColor: audioManager.nowPlayingInfo.dominantColor))
            }
            .buttonStyle(MusicControlButton(width: buttonWidth, height: buttonHeight, tint: audioManager.nowPlayingInfo.dominantColor)) // Apply custom style
            
            Spacer()
                .transition(.opacity.combined(with: .move(edge: .trailing)))
        }
    }
}
