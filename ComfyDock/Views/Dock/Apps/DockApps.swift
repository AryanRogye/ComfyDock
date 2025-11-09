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
                .contextMenu {
                }
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
                
            }
        }
        .padding(.horizontal)
        .background {
            VisualEffectView(material: .hudWindow)
                .clipShape(
                    RoundedRectangle(cornerRadius: 12)
                )
        }
//        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 12))
        .frame(maxHeight: dockManager.height)
        .padding(.bottom, dockManager.paddingFromBottom)
    }
}


struct HoverContextMenu<Content: View>: NSViewRepresentable {
    
    var content : Content
    
    init(
        @ViewBuilder content: () -> Content
    ) {
        self.content = content()
    }
    
    func makeNSView(context: Context) -> HoverContextTrackingView {
        let view = HoverContextTrackingView(content: AnyView(self.content))
        view.onHoverChange = { hovering in
            print("HOVERING STATUS: \(hovering)")
        }
        return view
    }
    
    func updateNSView(_ nsView: HoverContextTrackingView, context: Context) {}
}

final class HoverContextTrackingView: NSView {
    
    private let innerView: NSHostingView<AnyView>
    var onHoverChange: ((Bool) -> Void)?
    
    var tracking : NSTrackingArea?
    var isInside : Bool = false

    init(content: AnyView) {
        self.innerView = NSHostingView(rootView: content)
        super.init(frame: .zero)
        

        innerView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(innerView)
        
        NSLayoutConstraint.activate([
            innerView.topAnchor.constraint(equalTo: topAnchor),
            innerView.leadingAnchor.constraint(equalTo: leadingAnchor),
            innerView.trailingAnchor.constraint(equalTo: trailingAnchor),
            innerView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }
    
    deinit {
        stop()
    }
    
    required init?(coder: NSCoder) { fatalError() }
    
    override func updateTrackingAreas() {
        if let t = tracking { removeTrackingArea(t) }
        let t = NSTrackingArea(
            rect: .zero,
            options: [.mouseEnteredAndExited, .mouseMoved, .inVisibleRect, .activeInActiveApp],
            owner: self,
            userInfo: nil
        )
        addTrackingArea(t)
        tracking = t
    }
    
    override func mouseEntered(with event: NSEvent) { onHoverChange?(true) }
    override func mouseExited(with event: NSEvent) { onHoverChange?(false) }
    
    public func stop() {
        if let l = tracking { NSEvent.removeMonitor(l) }
        tracking = nil
        isInside = false
    }
}
