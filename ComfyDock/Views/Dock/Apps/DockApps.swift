//
//  DockApps.swift
//  ComfyDock
//
//  Created by Aryan Rogye on 11/9/25.
//

import Parser
import SwiftUI

private struct AppAnchorKey: PreferenceKey {
    static var defaultValue: [RunningApp: Anchor<CGRect>] { [:] }

    static func reduce(value: inout [RunningApp: Anchor<CGRect>],
                       nextValue: () -> [RunningApp: Anchor<CGRect>]) {
        value.merge(nextValue(), uniquingKeysWith: { $1 })
    }
}

private struct PanelSizeKey: PreferenceKey {
    static var defaultValue: CGSize { .zero }
    static func reduce(value: inout CGSize, nextValue: () -> CGSize) {
        value = nextValue()
    }
}

struct DockApps: View {

    @Bindable var dockManager : DockManager

    let parser = XcodeParser()

    var height : CGFloat {
        dockManager.height
    }


    @State private var xcodeRecentProjects: [URL]? = nil
    @State private var hoverIcon: Bool = false
    @State private var hoverPanel: Bool = false
    @State private var contextPanelSize: CGSize = .zero

    var body: some View {
        ZStack(alignment: .bottom) {
            HStack {
                ForEach(dockManager.runningApps, id: \.self) { app in
                    /// Button To Activate The App
                    Button(action: app.activate) {
                        /// App Icon
                        Image(nsImage: app.icon)
                            .resizable()
                            .frame(width: height, height: height)
                            /// If Right Click, increase z index to show one out
                            .zIndex(dockManager.rightClickApp == app ? 1 : 0)
                            .scaleEffect(dockManager.rightClickApp == app ? 1.1 : 1.0)
                            .animation(.spring, value: dockManager.rightClickApp)
                    }
                    .buttonStyle(.plain)
                    // Keep anchor preference for potential future manual layout (not used with popover)
                    .anchorPreference(key: AppAnchorKey.self, value: .bounds) { [app: $0] }
                    // System popover for automatic positioning & arrow per Apple guidelines
                    .contextMenu {
                            Button("Quit \(app.name)") { app.quitApp() }
                            .onAppear {
                                print("DOCK RIGHT CLICK SET")
                                self.dockManager.rightClickApp = app
                            }
                            .onDisappear {
                                print("DOCK RIGHT CLICK CLEARED")
                                self.dockManager.rightClickApp = nil
                            }
                        if app.name == "Xcode" {
                            Divider()
                                .onAppear {
                                    xcodeRecentProjects = parser.parse()
                                }
                            if let xcodeRecentProjects {
                                ForEach(xcodeRecentProjects, id: \.self) { project in
                                    Label {
                                        Text(project.lastPathComponent)
                                            .font(.system(size: 13))
                                            .lineLimit(1)
                                            .truncationMode(.middle)
                                    } icon: {
                                        Image(systemName: "folder.fill")
                                            .symbolRenderingMode(.hierarchical)
                                            .foregroundStyle(.tint)
                                    }
                                }
                            }
                        }
                    }
                }
            }
            .padding(.horizontal)
            .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 12))
            .frame(maxHeight: dockManager.height)
            .padding(.bottom, dockManager.paddingFromBottom)

            // Manual overlay removed in favor of popover.
        }
    }

    private func maybeClose() {
        // Close when neither the icon nor the panel are hovered
        if !hoverIcon && !hoverPanel {
            dockManager.rightClickApp = nil
        }
    }
}
