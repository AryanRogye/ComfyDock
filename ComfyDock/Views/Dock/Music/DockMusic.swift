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
            VStack(alignment: .leading, spacing: 4) {
                /// name/artist/album
                renderSongInformation()
                    .padding(.top, 2)

                /// Slider
                AudioSlider(audioManager: audioManager)

                /// Button
                AudioControls(audioManager: audioManager)
            }
            .frame(maxHeight: dockManager.height, alignment: .topLeading)
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
                    .opacity(0.5)
            }
        }

        .frame(maxHeight: dockManager.height)
        .padding(.bottom, dockManager.paddingFromBottom)
        .frame(maxWidth: 250)
    }

    private func renderSongInformation() -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(audioManager.nowPlayingInfo.trackName)
                .font(.system(size: 11, weight: .semibold, design: .rounded))
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
