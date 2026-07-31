//
//  AudioManager.swift
//  ComfyDock
//
//  Created by Aryan Rogye on 11/8/25.
//

import Foundation
import AppKit

@Observable
@MainActor
final class AudioManager {
    
    public init() {
        appleScriptMusicController = AppleScriptMusicController()
        mediaRemoteMusicController = MediaRemoteMusicController()
        updateNowPlayingInfo()
    }
    
    @ObservationIgnored
    private let appleScriptMusicController: AppleScriptMusicController

    @ObservationIgnored
    private let mediaRemoteMusicController: MediaRemoteMusicController
    
    /// Single Now Playing "Information"
    var nowPlayingInfo : NowPlayingInfo = NowPlayingInfo()
    
    /// Which Controller is playing, maybe change this later
    private var controller : MusicController = .mediaRemote

    private var activeController: any NowPlayingController {
        switch controller {
        case .mediaRemote:
            mediaRemoteMusicController
        case .appleScriptController:
            appleScriptMusicController
        }
    }
    
    private var timer: Timer?
    
    /**
     * Stops the periodic media info update timer.
     */
    func stopMediaTimer() {
        timer?.invalidate()
        timer = nil
    }

    /*
     *
     */
    func startMediaTimer() {
        print("Started Timer")
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            DispatchQueue.main.async {
                guard let self = self else { return }
                self.updateNowPlayingInfo()
            }
        }
        RunLoop.main.add(timer!, forMode: .common)
    }
    
    /**
     * Skips to the previous track in the current provider.
     * Checks which provider is active before sending the command.
     */
    func playPreviousTrack() {
        activeController.playPreviousTrack()
    }
    
    /**
     * Skips to the next track in the current provider.
     */
    func playNextTrack() {
        activeController.playNextTrack()
    }
    
    /**
     * Toggles play/pause state for the current provider.
     */
    func togglePlayPause() {
        activeController.togglePlayPause()
    }

    
    func playAtTime(to time: Double) {
        activeController.playAtTime(to: time)
    }
    
    public func updateNowPlayingInfo() {
        activeController.getNowPlayingInfo(
            trackNameChanged: { trackName in
                self.nowPlayingInfo.trackName = trackName
            },
            artistNameChanged: { artistName in
                self.nowPlayingInfo.artistName = artistName
            },
            albumNameChanged: { albumName in
                self.nowPlayingInfo.albumName = albumName
            },
            artworkImageChanged: { albumImage in
                self.nowPlayingInfo.artworkImage = albumImage
            },
            dominantColorChanged: { dominantColor in
                self.nowPlayingInfo.dominantColor = dominantColor
            },
            positionSecondsChanged: { postionSeconds in
                self.nowPlayingInfo.positionSeconds = postionSeconds
            },
            durationSecondsChanged: { durationSeconds in
                self.nowPlayingInfo.durationSeconds = durationSeconds
            },
            isPlayingAudioChanged: { isPlayingAudio in
                self.nowPlayingInfo.isPlaying = isPlayingAudio
            },
            musicProviderChanged: { musicProvider in
                self.nowPlayingInfo.musicProvider = musicProvider
            }
        )
    }
}


/// Which Controller Is Being Used
enum MusicController: String, Codable, CaseIterable, Identifiable{
    case mediaRemote
    case appleScriptController
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .mediaRemote : return "All Media"
        case .appleScriptController : return "Spotify/Apple Music"
        }
    }
}

/// From Which Source Audio is playing from
public enum MusicProvider: String, Codable, CaseIterable, Identifiable{
    case none
    case apple_music
    case spotify
    
    public var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .none : return "None"
        case .spotify : return "Spotify"
        case .apple_music : return "Apple Music"
        }
    }
}

@Observable @MainActor
final class NowPlayingInfo {
    /// The name of the currently playing track. Defaults to "No Song Playing" if nothing is playing.
    var trackName: String = "No Song Playing"
    /// The name of the artist for the current track. Defaults to "Unknown Artist".
    var artistName: String = "Unknown Artist"
    /// The name of the album for the current track. Defaults to "Unknown Album".
    var albumName: String = "Unknown Album"
    /// The artwork image associated with the current track, if available.
    var artworkImage: NSImage? = nil
    /// The dominant color extracted from the artwork image, used for UI theming. Defaults to white.
    var dominantColor: NSColor = .white
    /// The current playback position in seconds.
    var positionSeconds: Double = 0.0
    /// The total duration of the current track in seconds.
    var durationSeconds: Double = 0.0
    /// Indicates whether the track is currently playing.
    var isPlaying: Bool = false
    /// The music provider (e.g., Apple Music, Spotify) currently in use.
    var musicProvider: MusicProvider = .none
}
