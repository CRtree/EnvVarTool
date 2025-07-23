//
//  EnvVarListView.swift
//  EnvVarTool
//
//  Created by Samuel on 2025/7/23.
//

import SwiftUI
import SwiftData

struct EnvVarListView: View {
    var profile: ShellProfile
    var onEdit: (EnvVar) -> Void
    var onAdd: () -> Void
    var onDelete: (EnvVar) -> Void
    
    var body: some View {
        List {
            ForEach(profile.envVars) { envVar in
                HStack {
                    Text(envVar.key)
                    Spacer()
                    Text(envVar.value)
                    Button("Edit") {
                        onEdit(envVar)
                    }
                    Button(role: .destructive) {
                        onDelete(envVar)
                    } label: {
                        Image(systemName: "trash")
                    }
                }
            }
        }
        .navigationTitle(profile.name)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button(action: onAdd) {
                    Label("Add Environment Variable", systemImage: "plus")
                }
            }
            ToolbarItem {
                Button(action: exportProfile) {
                    Label("Export Profile", systemImage: "square.and.arrow.up")
                }
            }
        }
    }
    
    private func exportProfile() {
        
        let savePanel = NSSavePanel()
        savePanel.title = "Export Environment Variables"
        savePanel.nameFieldStringValue = "\(profile.name)_env_vars.json"
        savePanel.allowedFileTypes = ["json"]
        
        savePanel.begin { response in
            if response == .OK, let url = savePanel.url {
                do {
                    let exportData = ExportData(profileName: profile.name, envVars: profile.envVars)
                    let encoder = JSONEncoder()
                    encoder.outputFormatting = .prettyPrinted
                    let jsonData = try encoder.encode(exportData)
                    try jsonData.write(to: url)
                    print("Successfully exported to \(url)")
                } catch {
                    print("Failed to export: \(error)")
                }
            }
        }
    }
}
