//
//  AlbumCover.swift
//  ComfyDock
//
//  Created by Aryan Rogye on 11/9/25.
//

import SwiftUI

struct AlbumCover: View {

    @Bindable var dockManager : DockManager
    @Bindable var audioManager : AudioManager

    @State private var cachedArtwork: NSImage?
    @State private var flipRotation: Double = 0

    private let flipDuration: Double = 0.3
    private var isFrontSide: Bool {
        abs(flipRotation.truncatingRemainder(dividingBy: 360)) < 90 ||
        abs(flipRotation.truncatingRemainder(dividingBy: 360)) > 270
    }

    var height : CGFloat {
        let height = dockManager.height - 10
        return dockManager.hoveringOverMusicPlayer ? height + 10: height
    }
    var width : CGFloat {
        let height = dockManager.height - 10
        return dockManager.hoveringOverMusicPlayer ? height + 10: height
    }

    var shadowColor : Color {
        Color(nsColor: audioManager.nowPlayingInfo.dominantColor)
    }

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            ZStack {
                if let cachedArtwork = cachedArtwork {
                    renderImage(for: cachedArtwork)
                        .compositingGroup()
                        .opacity(isFrontSide ? 1 : 0)
                } else {
                    placeholderAlbumCover
                        .compositingGroup()
                }

                // Back side (new image) - visible at 180°
                if let artwork = audioManager.nowPlayingInfo.artworkImage {
                    renderImage(for: artwork)
                        .rotation3DEffect(.degrees(180), axis: (x: 0, y: 1, z: 0))
                        .compositingGroup()
                        .opacity(isFrontSide ? 0 : 1)
                }
            }
            .rotation3DEffect(.degrees(flipRotation), axis: (x: 0, y: 1, z: 0))
            .animation(.easeInOut(duration: flipDuration), value: flipRotation)
            .drawingGroup(opaque: false, colorMode: .extendedLinear)
            
            /// These should be out, These valus will make sure no weird "box" shows
            /// up around the image
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .shadow(color: shadowColor, radius: 2)
        }
        .onAppear {
            cachedArtwork = audioManager.nowPlayingInfo.artworkImage
        }
        .onChange(of: audioManager.nowPlayingInfo.artworkImage) { _, newArtwork in
            self.handleArtworkFlip(newArtwork: newArtwork)
        }
    }

    private func renderImage(for nsImage: NSImage) -> some View {
        return Image(nsImage: nsImage)
            .resizable()
            .aspectRatio(contentMode: .fill)
            .frame(width: width, height: height)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
            )
    }

    private var placeholderAlbumCover: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12)
                .fill(
                    LinearGradient(
                        colors: [
                            Color.gray.opacity(0.4),
                            Color.gray.opacity(0.2)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )

            Image(systemName: "music.note")
                .font(.system(size: 32, weight: .light))
                .foregroundColor(.white.opacity(0.5))
        }
        .frame(width: width, height: height)
    }

    // MARK: - Handle 180° Flip with Two-Sided Card
    private func handleArtworkFlip(newArtwork: NSImage?) {
        // Only flip if artwork actually changed
        guard cachedArtwork != newArtwork else { return }

        flipRotation = 180

        // After flip completes, reset for next flip and update cache
        DispatchQueue.main.asyncAfter(deadline: .now() + flipDuration) {
            // Reset rotation back to 0° WITHOUT animation (critical!)
            var transaction = Transaction()
            transaction.disablesAnimations = true
            withTransaction(transaction) {
                flipRotation = 0
            }
            // The new image becomes the cached "front" for next flip
            cachedArtwork = newArtwork
        }
    }
}
