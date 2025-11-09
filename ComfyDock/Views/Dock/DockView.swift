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
    
    var body: some View {
        HStack(alignment: .center) {
            DockApps(dockManager: dockManager)
            DockMusic(dockManager: dockManager, audioManager: audioManager)
        }
    }
}


