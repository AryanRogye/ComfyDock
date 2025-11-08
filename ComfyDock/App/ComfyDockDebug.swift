//
//  ComfyDockDebug.swift
//  ComfyDock
//
//  Created by Aryan Rogye on 11/7/25.
//

import SwiftUI
import Dock

struct ComfyDockDebug: View {
    
    let dock : DockControls
    @Bindable var dockController : DockManager
    
    var body: some View {
        VStack {
            
            Slider(value: Binding(
                get: { Double(dockController.height) },
                set: { dockController.height = CGFloat($0) }
            ), in: 0...1000)
            
            Button("Show") {
                dock.showDock()
            }
        }
    }
}
