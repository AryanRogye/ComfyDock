//
//  DockView.swift
//  ComfyDock
//
//  Created by Aryan Rogye on 11/7/25.
//

import SwiftUI
import Parser

struct DockView: View {
    
    @Bindable var dockManager : DockManager
    @Bindable var audioManager : AudioManager
    
    
    @State private var xcodeRecentProjects : [URL]? = nil
    
    var body: some View {
        VStack {
            Spacer()
            BottomDock(dockManager: dockManager, audioManager: audioManager)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct BottomDock: View {
    
    @Bindable var dockManager : DockManager
    @Bindable var audioManager : AudioManager
    
    @State private var isDragging = false
    @State private var manualDragPosition: Double = 0
    
    let trackHeight: CGFloat = 8
    let hitHeight: CGFloat = 20
    
    private let iconWidth: CGFloat = 7
    private let iconHeight: CGFloat = 8
    private let iconPadding: CGFloat = 20
    
    private let flipDuration: Double = 0.3
    
    @State private var cachedArtwork: NSImage?
    @State private var flipRotation: Double = 0
    
    private var isFrontSide: Bool {
        abs(flipRotation.truncatingRemainder(dividingBy: 360)) < 90 ||
        abs(flipRotation.truncatingRemainder(dividingBy: 360)) > 270
    }


    
    let parser = XcodeParser()
    
    var height : CGFloat {
        dockManager.height
    }

    var body: some View {
        HStack(alignment: .center) {
            
            HStack {
                ForEach(dockManager.runningApps, id: \.self) { app in
                    Button(action: app.activate) {
                        Image(nsImage: app.icon)
                            .resizable()
                            .frame(width: height, height: height)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal)
            .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 12))
            .frame(maxHeight: dockManager.height)
            .padding(.bottom, dockManager.paddingFromBottom)

//            Divider().padding(.vertical, 4)
            
            HStack {
                renderAlbumCover()
                    .frame(alignment: .leading)
                    .padding(.top, 8)
                
                // MARK: - Song Information and Controls
                VStack(alignment: .leading, spacing: 0) {
                    /// name/artist/album
                    renderSongInformation()
                    
                    /// Slider
                    renderCurrentSongPosition()
                    
                    /// Button
                    renderSongMusicControls()
                        .padding(.bottom, 8)
                }
                .frame(alignment: .topLeading)
            }
            .padding(.horizontal, 4)
            .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 12))
            .frame(maxHeight: dockManager.height)
            .padding(.bottom, dockManager.paddingFromBottom)
            .onChange(of: audioManager.nowPlayingInfo.artworkImage) { _, newArtwork in
                self.handleArtworkFlip(newArtwork: newArtwork)
            }
            .frame(maxWidth: 250)
        }
    }
    
    // MARK: - Handle 180° Flip with Two-Sided Card
    private func handleArtworkFlip(newArtwork: NSImage?) {
        // Only flip if artwork actually changed
        guard cachedArtwork != newArtwork else { return }
        
        // Start the 180° flip (0° to 180°)
        
        withAnimation(.easeInOut(duration: flipDuration)) {
            flipRotation = 180
        }
        
        // After flip completes, reset for next flip and update cache
        DispatchQueue.main.asyncAfter(deadline: .now() + flipDuration) {
            // Reset rotation back to 0° without animation
            flipRotation = 0
            // The new image becomes the cached "front" for next flip
            cachedArtwork = newArtwork
        }
    }

    
    func renderAlbumCover() -> some View {
        ZStack(alignment: .bottomTrailing) {
            ZStack {
                if let cachedArtwork = cachedArtwork {
                    renderImage(for: cachedArtwork)
                        .opacity(isFrontSide ? 1 : 0)
                } else {
                    placeholderAlbumCover
                        .opacity(isFrontSide ? 1 : 0)
                }
                
                // Back side (new image) - visible at 180°
                if let artwork = audioManager.nowPlayingInfo.artworkImage {
                    renderImage(for: artwork)
                        .rotation3DEffect(.degrees(180), axis: (x: 0, y: 1, z: 0))
                        .opacity(isFrontSide ? 0 : 1)
                }
            }
            .rotation3DEffect(.degrees(flipRotation), axis: (x: 0, y: 1, z: 0))
        }
        .onAppear {
            cachedArtwork = audioManager.nowPlayingInfo.artworkImage
        }
    }
    
    private func renderImage(for nsImage: NSImage) -> some View {
        return Image(nsImage: nsImage)
            .resizable()
            .aspectRatio(contentMode: .fill)
            .frame(width: height - 5, height: height - 5)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.3), radius: 8, x: 0, y: 4)
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
        .frame(width: height - 5, height: height - 5)
        .shadow(color: .black.opacity(0.3), radius: 8, x: 0, y: 4)
    }


    
    @ViewBuilder
    func renderCurrentSongPosition() -> some View {
        HStack(alignment: .center, spacing: 4) {
            Text(formatDuration(audioManager.nowPlayingInfo.positionSeconds))
                .font(.system(size: 8, weight: .medium, design: .default))
                .foregroundColor(.white.opacity(0.7))
                .frame(maxHeight: .infinity, alignment: .top)
                .padding(.top, 2)

            VStack(spacing: 6) {
                // Progress bar
                ZStack {
                    GeometryReader { geometry in
                        
                        Color.clear
                            .contentShape(Rectangle())     // make the whole area hittable
                            .frame(height: hitHeight)
                            .highPriorityGesture(          // win conflicts vs other gestures
                                DragGesture(minimumDistance: 0)
                                    .onChanged { value in
                                        // Set the dragging flag to true
                                        isDragging = true
                                        let percentage = min(max(0, value.location.x / geometry.size.width), 1)
                                        manualDragPosition = Double(percentage) * audioManager.nowPlayingInfo.durationSeconds
                                    }
                                    .onEnded { value in
                                        let percentage = min(max(0, value.location.x / geometry.size.width), 1)
                                        
                                        // Convert % ➜ absolute seconds
                                        let newTimeInSeconds = percentage * audioManager.nowPlayingInfo.durationSeconds
                                        
                                        // 1. Seek the real player
                                        audioManager.playAtTime(to: newTimeInSeconds)
                                        
                                        // 2. Keep the thumb where the user left it (UI won't flash back)
                                        manualDragPosition = newTimeInSeconds
                                        
                                        /// This is delayed because someone like me plays spotify on my tv
                                        /// the device is seperate from the controller so updates for spotify
                                        /// take some time to propagate.
                                        checkPositionUpdate(targetPosition: newTimeInSeconds, attempts: 0)
                                    }
                            )
                        
                        let effectivePosition = isDragging ? manualDragPosition : audioManager.nowPlayingInfo.positionSeconds
                        ZStack(alignment: .leading) {
                            // Background track
                            Rectangle()
                                .fill(Color.gray.opacity(0.3))
                                .frame(height: 6)
                                .cornerRadius(2)
                            
                            // Progress bar
                            Rectangle()
                                .fill(Color(nsColor: audioManager.nowPlayingInfo.dominantColor))
                                .frame(width: min(max(CGFloat(effectivePosition / max(audioManager.nowPlayingInfo.durationSeconds,1)) * geometry.size.width, 0), geometry.size.width), height: 6)
                                .cornerRadius(2)
                                .shadow(color: Color(nsColor: audioManager.nowPlayingInfo.dominantColor).opacity(0.5), radius: 4, x: 0, y: 2)
                        }
                    }
                }
            }
            .padding(.horizontal, 4)
            .padding(.top, 2)
            
            // Time labels
            Text(formatDuration(audioManager.nowPlayingInfo.durationSeconds))
                .font(.system(size: 8, weight: .medium, design: .default))
                .foregroundColor(.white.opacity(0.7))
                .frame(maxHeight: .infinity, alignment: .top)
                .padding(.top, 2)
        }
    }
    
    @ViewBuilder
    func renderSongMusicControls() -> some View {
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

    
    private func renderSongInformation() -> some View {
        VStack(alignment: .leading) {
            // Song title with better typography
            Text(audioManager.nowPlayingInfo.trackName)
                .font(.system(size: 13, weight: .semibold, design: .default))
                .foregroundColor(.white)
                .minimumScaleFactor(0.8)
                .lineLimit(1)
            
            // Artist name
            Text(audioManager.nowPlayingInfo.artistName)
                .font(.system(size: 11, weight: .semibold, design: .default))
                .foregroundColor(.gray.opacity(0.7))
                .minimumScaleFactor(0.7)
                .lineLimit(1)
        }
        .frame(maxHeight: .infinity, alignment: .topLeading)
        .padding(.top, 2)
    }
    
    // Helper function to format seconds as "MM:SS"
    private func formatDuration(_ seconds: Double) -> String {
        let minutes = Int(seconds) / 60
        let remainingSeconds = Int(seconds) % 60
        return String(format: "%d:%02d", minutes, remainingSeconds)
    }
    
    private func checkPositionUpdate(targetPosition: Double, attempts: Int) {
        let maxAttempts = 10
        let checkInterval = 0.5
        
        if attempts >= maxAttempts {
            // Give up and reset
            isDragging = false
            return
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + checkInterval) {
            let currentDiff = abs(audioManager.nowPlayingInfo.positionSeconds - targetPosition)
            
            if currentDiff < 1.0 { // Within 1 second tolerance
                isDragging = false
            } else {
                checkPositionUpdate(targetPosition: targetPosition, attempts: attempts + 1)
            }
        }
    }

//                        .contextMenu {
//                            //                            ZStack {
//                            //                                if app.name == "Xcode" {
//                            //                                    if let xcodeRecentProjects {
//                            //                                        Section("Xcode") {
//                            //                                            ForEach(xcodeRecentProjects, id: \.self) { url in
//                            //                                                Menu(url.lastPathComponent) {
//                            //                                                    Button("Open") { NSWorkspace.shared.open(url) }
//                            //                                                    Button("Reveal in Finder") {
//                            //                                                        NSWorkspace.shared.activateFileViewerSelecting([url])
//                            //                                                    }
//                            //                                                    Button("Copy Path") { NSPasteboard.general.setString(url.path, forType: .string) }
//                            //                                                }
//                            //                                            }
//                            //                                        }
//                            //                                    }
//                            //                                }
//                            //                            }
//                            //                            .onAppear {
//                            //                                xcodeRecentProjects = parser.parse()
//                            //                            }
//                            //                            .onHover { hovering in
//                            //                                print("Is Hovering: \(hovering)")
//                            //                                dock.isHoveringOverXcodeRects = hovering
//                            //                            }
//                        }
//                }
//                .buttonStyle(.plain)
//            }
//            
//            Divider().padding(.vertical, 4)
//        }
    
}


struct MusicControlButton: ButtonStyle {
    
    let size: CGFloat
    let tintColor: NSColor
    
    init(size: CGFloat = 32, tint: NSColor = .white) {
        self.size = size
        self.tintColor = tint
    }
    
    func makeBody(configuration: Configuration) -> some View {
        MusicControlButtonView(
            isPressed: configuration.isPressed,
            size: size,
            tintColor: Color(tintColor)
        ) {
            configuration.label
        }
    }
    
    struct MusicControlButtonView<Label: View>: View {
        @State private var isHovering = false
        let isPressed: Bool
        let size: CGFloat
        let tintColor: Color
        let label: () -> Label
        
        var body: some View {
            ZStack {
//                if isHovering {
//                    RoundedRectangle(cornerRadius: 10)
//                        .fill(
//                            LinearGradient(
//                                colors: [
//                                    tintColor.opacity(isHovering ? 0.25 : 0.15),
//                                    tintColor.opacity(isHovering ? 0.15 : 0.05)
//                                ],
//                                startPoint: .topLeading,
//                                endPoint: .bottomTrailing
//                            )
//                        )
//                        .overlay(
//                            RoundedRectangle(cornerRadius: 10)
//                                .stroke(tintColor.opacity(0.25), lineWidth: 1)
//                        )
//                        .scaleEffect(isPressed ? 0.95 : (isHovering ? 1.05 : 1.0))
//                        .shadow(
//                            color: .black.opacity(isHovering ? 0.3 : 0.1),
//                            radius: isHovering ? 8 : 4,
//                            x: 0,
//                            y: isHovering ? 4 : 2
//                        )
//                }
                label()
                    .foregroundColor(.white)
                    .scaleEffect(isPressed ? 0.9 : 1.0)
            }
            .animation(.easeInOut(duration: 0.2), value: isHovering)
            .animation(.easeInOut(duration: 0.1), value: isPressed)
            .onHover { hovering in
                isHovering = hovering
            }
        }
    }
}
