//
//  MediaRemoteMusicController.swift
//  ComfyNotch
//
//  Created by Aryan Rogye on 5/4/25.
//

import Foundation
import AppKit
import MediaRemoteAdapter

final class MediaRemoteMusicController: NowPlayingController {

    private let mediaController = MediaController()

    private var latestTrackInfo: TrackInfo?
    private var lastTrackIdentifier: String?
    private var lastArtworkIdentifier: String?
    private var lastIsPlaying: Bool?
    private var lastDuration: Double?
    private var lastMusicProvider: MusicProvider?
    private var isConfigured = false
    private var positionTimer: Timer?
    private var pendingArtworkClear: DispatchWorkItem?

    init() {}

    deinit {
        positionTimer?.invalidate()
        mediaController.stopListening()
    }

    func isAvailable() -> Bool {
        /// DEBUG: Return True
        return true
    }
    
    func getNowPlayingInfo(
        trackNameChanged: @escaping (String) -> Void,
        artistNameChanged: @escaping (String) -> Void,
        albumNameChanged: @escaping (String) -> Void,
        artworkImageChanged: @escaping (NSImage?) -> Void,
        dominantColorChanged: @escaping (NSColor) -> Void,
        positionSecondsChanged: @escaping (Double) -> Void,
        durationSecondsChanged: @escaping (Double) -> Void,
        isPlayingAudioChanged: @escaping (Bool) -> Void,
        musicProviderChanged: @escaping (MusicProvider) -> Void
    ) {
        guard !isConfigured else { return }
        isConfigured = true

        mediaController.onTrackInfoReceived = { [weak self] trackInfo in
            DispatchQueue.main.async {
                guard let self else { return }

                guard let trackInfo else {
                    self.clearNowPlayingInfo(
                        trackNameChanged: trackNameChanged,
                        artistNameChanged: artistNameChanged,
                        albumNameChanged: albumNameChanged,
                        artworkImageChanged: artworkImageChanged,
                        dominantColorChanged: dominantColorChanged,
                        positionSecondsChanged: positionSecondsChanged,
                        durationSecondsChanged: durationSecondsChanged,
                        isPlayingAudioChanged: isPlayingAudioChanged,
                        musicProviderChanged: musicProviderChanged
                    )
                    return
                }

                self.latestTrackInfo = trackInfo
                let trackId = self.trackIdentifier(for: trackInfo)
                let trackChanged = trackId != self.lastTrackIdentifier

                if trackChanged {
                    self.lastTrackIdentifier = trackId
                    trackNameChanged(trackInfo.payload.title ?? "Unknown")
                    artistNameChanged(trackInfo.payload.artist ?? "Unknown")
                    albumNameChanged(trackInfo.payload.album ?? "Unknown")
                }

                // MediaRemote often publishes artwork after its first metadata
                // callback, so this must run even when the track ID is unchanged.
                self.updateArtwork(
                    trackInfo: trackInfo,
                    trackIdentifier: trackId,
                    trackChanged: trackChanged,
                    artworkImageChanged: artworkImageChanged,
                    dominantColorChanged: dominantColorChanged
                )

                let isPlaying = trackInfo.payload.isPlaying ?? false
                if isPlaying != self.lastIsPlaying {
                    self.lastIsPlaying = isPlaying
                    isPlayingAudioChanged(isPlaying)
                }

                let duration = (trackInfo.payload.durationMicros ?? 0) / 1_000_000
                if duration != self.lastDuration {
                    self.lastDuration = duration
                    durationSecondsChanged(duration)
                }

                let provider = self.musicProvider(for: trackInfo.payload.bundleIdentifier)
                if provider != self.lastMusicProvider {
                    self.lastMusicProvider = provider
                    musicProviderChanged(provider)
                }

                positionSecondsChanged(self.currentPosition)
            }
        }

        mediaController.startListening()
        mediaController.getTrackInfo { [weak self] trackInfo in
            self?.mediaController.onTrackInfoReceived?(trackInfo)
        }

        positionTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            guard let self, self.lastIsPlaying == true else { return }
            positionSecondsChanged(self.currentPosition)
        }

        if let positionTimer {
            RunLoop.main.add(positionTimer, forMode: .common)
        }
    }

    private var currentPosition: Double {
        let position = latestTrackInfo?.payload.currentElapsedTime ?? 0
        guard let duration = lastDuration, duration > 0 else {
            return max(position, 0)
        }
        return min(max(position, 0), duration)
    }

    private func musicProvider(for bundleIdentifier: String?) -> MusicProvider {
        switch bundleIdentifier {
        case "com.apple.Music":
            .apple_music
        case "com.spotify.client":
            .spotify
        default:
            .none
        }
    }

    private func trackIdentifier(for trackInfo: TrackInfo) -> String {
        let metadataIdentifier = [
            trackInfo.payload.title,
            trackInfo.payload.artist,
            trackInfo.payload.album
        ]
        .compactMap { $0 }
        .joined(separator: "|")

        return metadataIdentifier.isEmpty
            ? trackInfo.payload.uniqueIdentifier
            : metadataIdentifier
    }

    private func updateArtwork(
        trackInfo: TrackInfo,
        trackIdentifier: String,
        trackChanged: Bool,
        artworkImageChanged: @escaping (NSImage?) -> Void,
        dominantColorChanged: @escaping (NSColor) -> Void
    ) {
        guard let artworkImage = trackInfo.payload.artwork else {
            guard trackChanged else { return }

            pendingArtworkClear?.cancel()
            let expectedTrackIdentifier = trackIdentifier
            let clear = DispatchWorkItem { [weak self] in
                guard
                    let self,
                    self.lastTrackIdentifier == expectedTrackIdentifier
                else {
                    return
                }

                self.lastArtworkIdentifier = nil
                artworkImageChanged(nil)
                dominantColorChanged(.white)
            }
            pendingArtworkClear = clear
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.25, execute: clear)
            return
        }

        pendingArtworkClear?.cancel()
        pendingArtworkClear = nil

        let identifier = trackIdentifier
            + (artworkImage.tiffRepresentation?.hashValue.description ?? "")
        guard identifier != lastArtworkIdentifier else { return }

        lastArtworkIdentifier = identifier
        artworkImageChanged(artworkImage)
        DispatchQueue.global(qos: .utility).async { [weak self] in
            guard let self else { return }
            let color = self.getDominantColor(from: artworkImage) ?? .white
            DispatchQueue.main.async {
                dominantColorChanged(color)
            }
        }
    }

    private func clearNowPlayingInfo(
        trackNameChanged: @escaping (String) -> Void,
        artistNameChanged: @escaping (String) -> Void,
        albumNameChanged: @escaping (String) -> Void,
        artworkImageChanged: @escaping (NSImage?) -> Void,
        dominantColorChanged: @escaping (NSColor) -> Void,
        positionSecondsChanged: @escaping (Double) -> Void,
        durationSecondsChanged: @escaping (Double) -> Void,
        isPlayingAudioChanged: @escaping (Bool) -> Void,
        musicProviderChanged: @escaping (MusicProvider) -> Void
    ) {
        guard latestTrackInfo != nil || lastTrackIdentifier != nil else { return }

        latestTrackInfo = nil
        pendingArtworkClear?.cancel()
        pendingArtworkClear = nil
        lastTrackIdentifier = nil
        lastArtworkIdentifier = nil
        lastIsPlaying = false
        lastDuration = 0
        lastMusicProvider = .none

        trackNameChanged("No Song Playing")
        artistNameChanged("Unknown Artist")
        albumNameChanged("Unknown Album")
        artworkImageChanged(nil)
        dominantColorChanged(.white)
        positionSecondsChanged(0)
        durationSecondsChanged(0)
        isPlayingAudioChanged(false)
        musicProviderChanged(.none)
    }
    
    func playPreviousTrack() {
        mediaController.previousTrack()
    }
    
    func playNextTrack() {
        mediaController.nextTrack()
    }
    
    func togglePlayPause() {
        mediaController.togglePlayPause()
    }
    
    func playAtTime(to time: Double) {
        mediaController.setTime(seconds: time)
    }
}
