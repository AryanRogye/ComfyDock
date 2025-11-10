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
                        
                        PassthroughContextMenuHost(
                            onOpen: { dockManager.rightClickApp = app },
                            onClose: { dockManager.rightClickApp = nil },
                            content: {
                                Image(nsImage: app.icon)
                                    .resizable()
                                    .frame(width: height, height: height)
                                    .zIndex(dockManager.rightClickApp == app ? 1 : 0)
                                    .scaleEffect(dockManager.rightClickApp == app ? 1.1 : 1.0)
                                    .animation(.spring, value: dockManager.rightClickApp)
                            },
                            buildMenu: {
                                let m = NSMenu()
                                m.addItem(withTitle: "Option 1", action: nil, keyEquivalent: "")
                                m.addItem(withTitle: "Option 2", action: nil, keyEquivalent: "")
                                return m
                            }
                        )
                        
//                            .contextMenu(
//                            ) {
//                                if dockManager.isVisible {
//                                    Button("Quit \(app.name)") { app.quitApp() }
//                                        .onAppear {
//                                            print("DOCK RIGHT CLICK SET")
//                                            self.dockManager.rightClickApp = app
//                                        }
//                                        .onDisappear {
//                                            print("DOCK RIGHT CLICK CLEARED")
//                                            self.dockManager.rightClickApp = nil
//                                        }
//                                    if app.name == "Xcode" {
//                                        Divider()
//                                            .onAppear {
//                                                xcodeRecentProjects = parser.parse()
//                                            }
//                                        if let xcodeRecentProjects {
//                                            ForEach(xcodeRecentProjects, id: \.self) { project in
//                                                Menu {
//                                                    Button("Open") { NSWorkspace.shared.open(project) }
//                                                    Button("Reveal in Finder") {
//                                                        NSWorkspace.shared.activateFileViewerSelecting([project])
//                                                    }
//                                                    Button("Copy Path") {
//                                                        NSPasteboard.general.setString(project.path, forType: .string)
//                                                    }
//                                                } label: {
//                                                    Label {
//                                                        Text(project.lastPathComponent)
//                                                            .font(.system(size: 13))
//                                                            .lineLimit(1)
//                                                            .truncationMode(.middle)
//                                                    } icon: {
//                                                        Image(systemName: "folder.fill")
//                                                            .symbolRenderingMode(.hierarchical)
//                                                            .foregroundStyle(.tint)
//                                                    }
//                                                }
//                                            }
//                                        }
//                                    }
//                                }
//                            } preview: {
//                                Image(nsImage: app.icon)
//                                    .resizable()
//                                    .frame(width: height, height: height)
//                            }
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

    private func maybeClose() {
        // Close when neither the icon nor the panel are hovered
        if !hoverIcon && !hoverPanel {
            dockManager.rightClickApp = nil
        }
    }
}


struct PassthroughContextMenuHost<Content: View>: NSViewRepresentable {
    let onOpen: () -> Void
    let onClose: () -> Void
    @ViewBuilder var content: () -> Content
    let buildMenu: () -> NSMenu
    
    func makeNSView(context: Context) -> Wrapper<Content> {
        let w = Wrapper(content: content(), buildMenu: buildMenu, onOpen: onOpen, onClose: onClose)
        return w
    }
    
    func updateNSView(_ nsView: Wrapper<Content>, context: Context) {
        nsView.update(content: content())
    }
    
    final class Wrapper<C: View>: NSView, NSMenuDelegate {
        private var host: NSHostingView<C>
        private let buildMenu: () -> NSMenu
        private let onOpen: () -> Void
        private let onClose: () -> Void
        
        init(content: C, buildMenu: @escaping () -> NSMenu, onOpen: @escaping () -> Void, onClose: @escaping () -> Void) {
            self.host = NSHostingView(rootView: content)
            self.buildMenu = buildMenu
            self.onOpen = onOpen
            self.onClose = onClose
            super.init(frame: .zero)
            
            addSubview(host)
            host.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                host.leadingAnchor.constraint(equalTo: leadingAnchor),
                host.trailingAnchor.constraint(equalTo: trailingAnchor),
                host.topAnchor.constraint(equalTo: topAnchor),
                host.bottomAnchor.constraint(equalTo: bottomAnchor),
            ])
        }
        
        required init?(coder: NSCoder) { fatalError() }
        
        func update(content: C) {
            host.rootView = content
        }
        
        // Let SwiftUI/NSButton handle normal clicks; we only trap right click.
        override func hitTest(_ point: NSPoint) -> NSView? {
            host.hitTest(convert(point, to: host))
        }
        
        override func rightMouseDown(with event: NSEvent) {
            let menu = buildMenu()
            menu.delegate = self
            onOpen()
            NSMenu.popUpContextMenu(menu, with: event, for: self)
            // NSMenu will call menuDidClose afterwards
        }
        
        // NSMenuDelegate
        func menuDidClose(_ menu: NSMenu) { onClose() }
    }
}
