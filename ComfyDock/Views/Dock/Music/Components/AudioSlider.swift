//
//  AudioSlider.swift
//  ComfyDock
//
//  Created by Aryan Rogye on 11/9/25.
//

import SwiftUI

struct AudioSlider: View {
    
    @Bindable var audioManager : AudioManager
    
    @State private var isDragging = false
    
    @State private var manualDragPosition: Double = 0
    
    let trackHeight: CGFloat = 8
    let hitHeight: CGFloat = 20

    var body: some View {
        HStack(alignment: .center, spacing: 4) {
            Text(formatDuration(audioManager.nowPlayingInfo.positionSeconds))
                .font(.system(size: 8, weight: .medium, design: .default))
                .foregroundColor(.primary.opacity(0.7))
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
            .padding(.horizontal, 2)
            .padding(.top, 4)
            
            // Time labels
            Text(formatDuration(audioManager.nowPlayingInfo.durationSeconds))
                .font(.system(size: 8, weight: .medium, design: .default))
                .foregroundColor(.primary.opacity(0.7))
                .frame(maxHeight: .infinity, alignment: .top)
                .padding(.top, 2)
        }
        .shadow(
            color: Color(nsColor: audioManager.nowPlayingInfo.dominantColor).opacity(0.6),
            radius: 3, x: 0, y: 0
        )
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

}
