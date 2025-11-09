//
//  MusicControlButton.swift
//  ComfyDock
//
//  Created by Aryan Rogye on 11/9/25.
//

import SwiftUI

struct MusicControlButton: ButtonStyle {
    
    let width  : CGFloat
    let height : CGFloat
    let tintColor: NSColor
    
    init(width: CGFloat, height: CGFloat, tint: NSColor = .white) {
        self.width = width
        self.height = height
        self.tintColor = tint
    }
    
    func makeBody(configuration: Configuration) -> some View {
        MusicControlButtonView(
            isPressed: configuration.isPressed,
            width: width,
            height: height,
            tintColor: Color(tintColor)
        ) {
            configuration.label
        }
    }
    
    struct MusicControlButtonView<Label: View>: View {
        @State private var isHovering = false
        let isPressed: Bool
        let width: CGFloat
        let height: CGFloat
        let tintColor: Color
        let label: () -> Label
        
        var body: some View {
            ZStack(alignment: .center) {
                if isHovering {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(
                            LinearGradient(
                                colors: [
                                    tintColor.opacity(isHovering ? 0.15 : 0.05),
                                    tintColor.opacity(isHovering ? 0.05 : 0.15)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(tintColor.opacity(0.1), lineWidth: 1)
                        )
                        .scaleEffect(isPressed ? 0.95 : (isHovering ? 1.05 : 1.0))
                        .shadow(
                            color: .black.opacity(isHovering ? 0.3 : 0.1),
                            radius: isHovering ? 8 : 4,
                            x: 0,
                            y: isHovering ? 4 : 2
                        )
                }
                label()
                    .foregroundColor(.white)
                    .scaleEffect(isPressed ? 0.9 : 1.0)
            }
            .frame(width: width, height: height)
            .animation(.easeInOut(duration: 0.2), value: isHovering)
            .animation(.easeInOut(duration: 0.1), value: isPressed)
            .onHover { hovering in
                isHovering = hovering
            }
        }
    }
}
