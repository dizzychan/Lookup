//
//  SettingsView.swift
//  LookUp
//
//  Created by Wangzhen Wu on 17/03/2025.
//

import SwiftUI

struct SettingsView: View {
    @AppStorage("darkMode") private var darkMode = false
    @AppStorage("fontSize") private var fontSize = 16.0
    
    var body: some View {
        Form {
            Section("Display Settings") {
                Toggle("Dark Mode", isOn: $darkMode)
                Stepper("Font Size: \(Int(fontSize))", value: $fontSize, in: 12...24)
            }
            
            Section("About") {
                HStack {
                    Text("Version")
                    Spacer()
                    Text("1.0.0")
                }
                Link("Help Documentation", destination: URL(string: "https://example.com")!)
            }
        }
        .navigationTitle("Settings")
    }
}
