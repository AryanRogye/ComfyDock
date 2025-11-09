//
//  DockApps.swift
//  ComfyDock
//
//  Created by Aryan Rogye on 11/9/25.
//

import Parser
import SwiftUI

struct DockApps: View {
    
    @Bindable var dockManager : DockManager
    
    let parser = XcodeParser()

    var height : CGFloat {
        dockManager.height
    }

    var body: some View {
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
    }
}
