//
//  AudioControls.swift
//  ComfyDock
//
//  Created by Aryan Rogye on 11/9/25.
//

import SwiftUI

struct AudioControls: View {
    
    
    @Bindable var audioManager : AudioManager
    private let iconWidth: CGFloat = 7
    private let iconHeight: CGFloat = 8
    private let iconPadding: CGFloat = 15
    
    var body: some View {
        HStack(spacing: 8) {
            Button(action: {
                audioManager.playPreviousTrack()
            }) {
                // Apply image-specific modifiers here
                Image(systemName: "backward.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: iconWidth, height: iconHeight)
                    .foregroundColor(.white)
            }
            .buttonStyle(MusicControlButton(size: iconPadding, tint: audioManager.nowPlayingInfo.dominantColor)) // Apply custom style
            
            Button(action: {
                audioManager.togglePlayPause()
            }) {
                // Apply image-specific modifiers here
                Image(systemName: audioManager.nowPlayingInfo.isPlaying ? "pause.fill" : "play.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: iconWidth, height: iconHeight)
                    .foregroundColor(.white)
            }
            .buttonStyle(MusicControlButton(size: iconPadding, tint: audioManager.nowPlayingInfo.dominantColor)) // Apply custom style
            
            Button(action: {
                audioManager.playNextTrack()
            }) {
                // Apply image-specific modifiers here
                Image(systemName: "forward.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: iconWidth, height: iconHeight)
                    .foregroundColor(.white)
            }
            .buttonStyle(MusicControlButton(size: iconPadding, tint: audioManager.nowPlayingInfo.dominantColor)) // Apply custom style
        }
    }
}
