//
//  ContextPanel.swift
//  ComfyDock
//
//  Created by Aryan Rogye on 11/9/25.
//

import SwiftUI
import Parser

//                        }
//                }
//                .buttonStyle(.plain)
//            }
//
//            Divider().padding(.vertical, 4)

struct ContextPanel: View {
    let app: RunningApp
    @Binding var isOpen: Bool
    @Binding var hovering: Bool

    @State private var xcodeRecentProjects: [URL]? = nil
    let parser : XcodeParser = XcodeParser()

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            if app.name == "Xcode" {
                if let xcodeRecentProjects {

                    ForEach(xcodeRecentProjects, id: \.self) { url in
                        Menu {
                            Button("Open") { NSWorkspace.shared.open(url) }
                            Button("Reveal in Finder") {
                                NSWorkspace.shared.activateFileViewerSelecting([url])
                            }
                            Button("Copy Path") {
                                NSPasteboard.general.setString(url.path, forType: .string)
                            }
                        } label: {
                            HStack {
                                Text(url.lastPathComponent)
                                    .font(.system(size: 13))
                                    .lineLimit(1)
                                    .truncationMode(.middle)
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 10, weight: .semibold))
                                    .foregroundColor(.secondary)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 6)
                            .contentShape(Rectangle())
                        }
                    }
                }
            } else {
                Button("Quit \(app.name)") {
                    app.quitApp()
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
            }
        }
        .padding(.vertical, 4)
        .frame(minWidth: 260, alignment: .leading)
        .menuStyle(BorderlessButtonMenuStyle())
        .background {
            RoundedRectangle(cornerRadius: 6)
                .fill(.regularMaterial)
                .shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: 4)
        }
        .overlay {
            RoundedRectangle(cornerRadius: 6)
                .strokeBorder(Color.primary.opacity(0.1), lineWidth: 0.5)
        }
//        .onHover { hovering in
//            self.hovering = hovering
//        }
        .onAppear {
            xcodeRecentProjects = parser.parse()
        }
    }
}
