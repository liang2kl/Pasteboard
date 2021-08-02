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
                    Stepper("Maximum history count", value: $maxStoreCount)
                    Text(String(maxStoreCount))
                        .font(.system(.body, design: .monospaced))
                }
            }
            .tabItem { Text("History") }
        }
        .frame(minWidth: 400, minHeight: 400)
        .padding()
    }
}
