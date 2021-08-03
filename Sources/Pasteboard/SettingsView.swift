//
//  SettingsView.swift
//  Pasteboard
//
//  Created by liang2kl on 2021/8/3.
//

import SwiftUI
import Defaults
import LaunchAtLogin

struct SettingsView: View {
    @Default(.storingHistory) var storingHistory
    @Default(.maxStoreCount) var maxStoreCount
    var body: some View {
        TabView {
            Form {
                LaunchAtLogin.Toggle()
                    .toggleStyle(.switch)
            }
            .tabItem { Text("General") }

            Form {
                Toggle("Save history", isOn: $storingHistory)
                    .toggleStyle(.switch)

                HStack {
                    Stepper("Maximum history count", value: $maxStoreCount, in: 5...20)
                    Text(String(maxStoreCount))
                        .font(.system(.body, design: .monospaced))
                }
            }
            .tabItem { Text("History") }
        }
        .frame(minWidth: 400, maxWidth: 600, minHeight: 250, maxHeight: 450)
        .padding()
        .font(.system(.body, design: .monospaced))
    }
}
