//
//  DockView.swift
//  ComfyDock
//
//  Created by Aryan Rogye on 11/7/25.
//

import SwiftUI
import Parser

struct DockView: View {
    
    @Bindable var dock : DockManager
    let parser = XcodeParser()
    
    var height : CGFloat {
        dock.height
    }
    
    var body: some View {
        HStack {
            ForEach(dock.runningApps, id: \.self) { app in
                Button(action: app.activate) {
                    Image(nsImage: app.icon)
                        .resizable()
                        .frame(width: height, height: height)
                        .contextMenu {
                            if app.name == "Xcode" {
                                Button("Try") {
                                    parser.parse()
                                }
                            }
                        }
                }
                .buttonStyle(.plain)
            }
            
            Divider().padding(.vertical, 4)
        }
        .padding(.horizontal)
        .frame(maxHeight: .infinity)
        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 12))
    }
}
