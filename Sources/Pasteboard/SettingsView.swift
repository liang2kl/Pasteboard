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
                LaunchAtLogin.Toggle() {
                    Text("SETTINGSVIEW_LAUNCH_AT_LOGIN_TOGGLE")
                }
                .toggleStyle(.switch)
            }
            .tabItem { Text("SETTINGSVIEW_GENERAL_TAB") }

            Form {
                Toggle("SETTINGSVIEW_SAVE_HISTORY_TOGGLE", isOn: $storingHistory)
                    .toggleStyle(.switch)

                HStack {
                    Stepper("SETTINGSVIEW_MAX_HISTORY_COUNT_STEPPER", value: $maxStoreCount, in: 5...20)
                    Text(String(maxStoreCount))
                        .font(.system(.body, design: .monospaced))
                }
            }
            .tabItem { Text("SETTINGSVIEW_HISTORY_TAB") }
        }
        .frame(minWidth: 400, maxWidth: 600, minHeight: 250, maxHeight: 450)
        .padding()
        .font(.system(.body, design: .monospaced))
    }
}
