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


