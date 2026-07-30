//
//  ContentView.swift
//  DockExperiment
//
//  Created by Aryan Rogye on 7/29/26.
//

import SwiftUI
import Dock

struct ContentView: View {
    
    @Bindable var vm: ViewModel
    @State var loadingWindows: Bool = false
    
    var body: some View {
        Form {
            Section("Window") {
                Button("Get Windows") {
                    Task {
                        loadingWindows = true
                        defer { loadingWindows = false }
                        await self.vm.windowCore?.loadWindows()
                    }
                }
                .disabled(loadingWindows)
                if let windowCore = vm.windowCore {
                    if !windowCore.windows.isEmpty {
                        ForEach(windowCore.windows, id: \.id) { window in
                            HStack {
                                Text(window.app.localizedName ?? "")
                                Divider()
                                Text(window.app.bundleIdentifier ?? "")
                                Spacer()
                                Text("pid: \(window.pid)")
                                if window.app.localizedName == "Dock" {
                                    Button("Attach Observer") {
                                        vm.attachObserverOnDock(dockPID: window.pid)
                                    }
                                }
                            }
                        }
                    }
                }
            }
            Section("Dock Stats") {
                Button("GetCoreDockOrientation") {
                    vm.getCoreDockOrientationAndPinning()
                }
                if let orientation = vm.orientation {
                    Text("Orientation: \(orientation.label)")
                }
                HStack {
                    Button("Toggle Dock") {
                        vm.toggleDock()
                    }
                    Text("Dock \(vm.isDockHidden ? "Hidden" : "Shown")")
                }
                HStack {
                    Button("Get Dock Tile Size") {
                        vm.getDockTileSize()
                    }
                    if let dockTileSize = vm.dockTileSize {
                        Text("\(dockTileSize)")
                    }
                }
                VStack(alignment: .leading) {
                    Button("Get Dock Rect") {
                        vm.getCoreDockRect()
                    }
                    if let rect = vm.dockRect {
                        CGRectInfoView(rect: rect)
                    }
                }
            }
        }
        .formStyle(.grouped)
    }
}

#Preview {
    ContentView(vm: ViewModel())
        .frame(width: 350, height: 400)
}


private struct CGRectInfoView: View {
    
    let rect: CGRect
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            
            Section("Origin") {
                VStack(alignment: .leading, spacing: 8) {
                    InfoRow(title: "X", value: rect.origin.x)
                    InfoRow(title: "Y", value: rect.origin.y)
                }
            }
            
            Section("Size") {
                VStack(alignment: .leading, spacing: 8) {
                    InfoRow(title: "Width", value: rect.width)
                    InfoRow(title: "Height", value: rect.height)
                }
            }
            
            Section("Bounds") {
                VStack(alignment: .leading, spacing: 8) {
                    InfoRow(title: "Min X", value: rect.minX)
                    InfoRow(title: "Mid X", value: rect.midX)
                    InfoRow(title: "Max X", value: rect.maxX)
                    
                    Divider()
                    
                    InfoRow(title: "Min Y", value: rect.minY)
                    InfoRow(title: "Mid Y", value: rect.midY)
                    InfoRow(title: "Max Y", value: rect.maxY)
                }
            }
            
            Section("Derived") {
                VStack(alignment: .leading, spacing: 8) {
                    InfoRow(title: "Center X", value: rect.midX)
                    InfoRow(title: "Center Y", value: rect.midY)
                    InfoRow(title: "Area", value: rect.width * rect.height)
                }
            }
        }
        .padding()
    }
}

private struct InfoRow: View {
    
    let title: String
    let value: CGFloat
    
    var body: some View {
        HStack {
            Text(title)
                .foregroundStyle(.secondary)
            
            Spacer()
            
            Text(
                Double(value).formatted(
                    .number.precision(.fractionLength(2))
                )
            )
            .fontDesign(.monospaced)
        }
    }
}
