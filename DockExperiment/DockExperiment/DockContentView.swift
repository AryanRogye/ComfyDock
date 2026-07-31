//
//  DockContentView.swift
//  DockExperiment
//
//  Created by Aryan Rogye on 7/30/26.
//

import SwiftUI

struct DockContentView: View {
    
    @Environment(AudioManager.self) var audioManager
    let height: CGFloat
    
    var body: some View {
        DockMusic(
            height: height,
            audioManager: audioManager
        )
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
//        .border(.yellow, width: 1)
    }
}
