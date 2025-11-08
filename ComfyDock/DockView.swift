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
    
    
    @State private var xcodeRecentProjects : [URL]? = nil
    
    var body: some View {
        VStack {
            Spacer()
            BottomDock(dock: dock)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct BottomDock: View {
    
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
                }
                .buttonStyle(.plain)
            }
            Divider().padding(.vertical, 4)
        }
        .padding(.horizontal)
        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 12))
        .frame(maxHeight: dock.height)
        .padding(.bottom, dock.paddingFromBottom)
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
}
