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
    
    var body: some View {
        HStack(alignment: .top) {
            
            AlbumCover(dockManager: dockManager, audioManager: audioManager)
                .frame(alignment: .leading)
                .padding(.top, 5)
            
            // MARK: - Song Information and Controls
            VStack(alignment: .leading, spacing: 0) {
                /// name/artist/album
                renderSongInformation()
                
                /// Slider
                AudioSlider(audioManager: audioManager)
                
                /// Button
                AudioControls(audioManager: audioManager)
                    .padding(.bottom, 4)
            }
            .frame(alignment: .topLeading)
        }
        .padding(.horizontal, 4)
        
        .background {
            ZStack {
                
                VisualEffectView(material: .hudWindow)
                    .clipShape(
                        RoundedRectangle(cornerRadius: 12)
                    )
                
                MetalBackground(audioManager: audioManager, metalAnimationState: metalAnimationState)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .opacity(0.3)
            }
        }
        
        .frame(maxHeight: dockManager.height)
        .padding(.bottom, dockManager.paddingFromBottom)
        .frame(maxWidth: 250)
    }
    
    private func renderSongInformation() -> some View {
        VStack(alignment: .leading) {
            // Song title with better typography
            Text(audioManager.nowPlayingInfo.trackName)
                .font(.system(size: 13, weight: .semibold, design: .default))
                .foregroundColor(.primary)
                .minimumScaleFactor(0.8)
                .lineLimit(1)
            
            // Artist name
            Text(audioManager.nowPlayingInfo.artistName)
                .font(.system(size: 11, weight: .semibold, design: .default))
                .foregroundColor(.secondary.opacity(0.7))
                .minimumScaleFactor(0.7)
                .lineLimit(1)
        }
        .frame(maxHeight: .infinity, alignment: .topLeading)
        .padding(.top, 2)
    }
}
