//
//  ContentView.swift
//  EnvVarTool
//
//  Created by Samuel on 2025/7/15.
//

import SwiftUI
import SwiftData

struct ShellProfile: Identifiable {
    let id = UUID()
    let name: String
    let path: String
    var envVars: [EnvVar]
}

struct EnvVar: Identifiable {
    let id = UUID()
    var key: String
    var value: String
}

struct ContentView: View {
    @State private var shellProfiles: [ShellProfile] = []
    @State private var selectedProfile: ShellProfile?
    @State private var showAddVarSheet = false
    @State private var editingEnvVar: EnvVar?
    @State private var newKey: String = ""
    @State private var newValue: String = ""
    @State private var editValue: String = ""
    @State private var envVarToDelete: EnvVar?
    @State private var showDeleteAlert = false
    
    var body: some View {
        NavigationSplitView {
            List(shellProfiles) { profile in
                Button(action: {
                    selectedProfile = profile
                }) {
                    HStack {
                        Text(profile.name)
                        if selectedProfile?.id == profile.id {
                            Spacer()
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.accentColor)
                        }
                    }
                }
            }
            .navigationTitle("Shell Profiles")
            .onAppear {
                if shellProfiles.isEmpty {
                    loadShellProfiles()
                }
            }
            .toolbar {
                ToolbarItem {
                    Button(action: loadShellProfiles) {
                        Label("Reload", systemImage: "arrow.clockwise")
                    }
                }
                ToolbarItem {
                    Button(action: importProfile) {
                        Label("Import Profile", systemImage: "square.and.arrow.down")
                    }
                }
            }
        } detail: {
            if let profile = selectedProfile {
                EnvVarListView(profile: profile, onEdit: { envVar in
                    editingEnvVar = envVar
                    editValue = envVar.value
                }, onAdd: {
                    newKey = ""
                    newValue = ""
                    showAddVarSheet = true
                }, onDelete: { envVar in
                    envVarToDelete = envVar
                    showDeleteAlert = true
                })
            } else if !shellProfiles.isEmpty {
                Text("Select a shell configuration file")
            } else {
                Text("No shell configuration files detected. Click Reload to refresh or add manually!")
            }
        }
        .sheet(isPresented: $showAddVarSheet) {
            VStack(spacing: 20) {
                Text("Add Environment Variable")
                    .font(.headline)
                TextField("Variable Name", text: $newKey)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                TextField("Variable Value", text: $newValue)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                HStack {
                    Button("Cancel") {
                        showAddVarSheet = false
                    }
                    Spacer()
                    Button("Save") {
                        addEnvVar()
                        showAddVarSheet = false
                    }.disabled(newKey.isEmpty || newValue.isEmpty)
                }
            }
            .padding()
            .frame(width: 350)
        }
        .sheet(item: $editingEnvVar) { envVar in
            VStack(spacing: 20) {
                Text("Edit Environment Variable")
                    .font(.headline)
                Text(envVar.key)
                    .font(.subheadline)
                TextField("Variable Value", text: $editValue)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                HStack {
                    Button("Cancel") {
                        editingEnvVar = nil
                    }
                    Spacer()
                    Button("Save") {
                        editEnvVar(envVar)
                        editingEnvVar = nil
                    }.disabled(editValue.isEmpty)
                }
            }
            .padding()
            .frame(width: 350)
            .onAppear {
                editValue = envVar.value
            }
        }
        .alert("Confirm Delete", isPresented: $showDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                if let envVar = envVarToDelete, let profile = selectedProfile {
                    deleteEnvVar(envVar, from: profile)
                }
            }
        } message: {
            if let envVar = envVarToDelete {
                Text("Are you sure you want to delete variable '\(envVar.key)'?")
            } else {
                Text("Are you sure you want to delete this environment variable?")
            }
        }
        .onAppear {
            loadShellProfiles()
            if selectedProfile == nil, let first = shellProfiles.first {
                selectedProfile = first
            }
        }
    }
    
    private func loadShellProfiles() {
        // Access the real user home directory instead of sandbox container
        let home = ProcessInfo.processInfo.environment["HOME"] ?? NSHomeDirectory()
        let candidates = [".zshrc", ".bash_profile", ".bashrc"]
        var profiles: [ShellProfile] = []
        
        var checkedPaths: [String] = []
        for file in candidates {
            let path = home + "/" + file
            checkedPaths.append(path)
            if FileManager.default.fileExists(atPath: path) {
                let envVars = parseEnvVars(from: path)
                profiles.append(ShellProfile(name: file, path: path, envVars: envVars))
            }
        }
        
        let previousSelectedName = selectedProfile?.name
        shellProfiles = profiles
        
        if let previousName = previousSelectedName,
           let newSelected = profiles.first(where: { $0.name == previousName }) {
            selectedProfile = newSelected
        } else if selectedProfile == nil, let first = profiles.first {
            selectedProfile = first
        }
    }
    
    private func parseEnvVars(from path: String) -> [EnvVar] {
        guard let content = try? String(contentsOfFile: path, encoding: .utf8) else {
            print("Failed to read file: \(path)")
            return []
        }
        let lines = content.split(separator: "\n")
        var vars: [EnvVar] = []
        
        print("Parsing file: \(path)")
        print("Total lines: \(lines.count)")
        
        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.hasPrefix("export ") {
                print("Found export: \(trimmed)")
                let kv = trimmed.dropFirst(7).split(separator: "=", maxSplits: 1)
                if kv.count == 2 {
                    let key = String(kv[0]).trimmingCharacters(in: .whitespacesAndNewlines)
                    let value = String(kv[1]).trimmingCharacters(in: .whitespacesAndNewlines)
                    vars.append(EnvVar(key: key, value: value))
                    print("Parsed: \(key) = \(value)")
                } else {
                    print("Failed to parse: \(trimmed)")
                }
            }
        }
        
        print("Parsed \(vars.count) variables from \(path)")
        return vars
    }
    
    private func addEnvVar() {
        guard let profile = selectedProfile else { return }
        let newEnv = EnvVar(key: newKey, value: newValue)
        var updatedVars = profile.envVars.filter { $0.key != newKey }
        updatedVars.append(newEnv)
        saveEnvVars(updatedVars, to: profile.path)
        loadShellProfiles()
    }
    
    private func editEnvVar(_ envVar: EnvVar) {
        guard let profile = selectedProfile else { return }
        let updatedVars = profile.envVars.map { v in
            if v.key == envVar.key {
                return EnvVar(key: v.key, value: editValue)
            } else {
                return v
            }
        }
        saveEnvVars(updatedVars, to: profile.path)
        loadShellProfiles()
    }
    private func deleteEnvVar(_ envVar: EnvVar, from profile: ShellProfile) {
        let updatedVars = profile.envVars.filter { $0.key != envVar.key }
        saveEnvVars(updatedVars, to: profile.path)
        loadShellProfiles()
    }
    private func saveEnvVars(_ vars: [EnvVar], to path: String) {
        guard let originalContent = try? String(contentsOfFile: path, encoding: .utf8) else {
            print("Failed to read original content for saving")
            return
        }
        
        let originalLines = originalContent.split(separator: "\n")
        var newLines: [String] = []
        
        // Keep non-export lines
        for line in originalLines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if !trimmed.hasPrefix("export ") {
                newLines.append(String(line))
            }
        }
        
        // Add new export lines
        let exportLines = vars.map { "export \($0.key)=\($0.value)" }
        newLines.append(contentsOf: exportLines)
        
        let content = newLines.joined(separator: "\n")
        do {
            try content.write(toFile: path, atomically: true, encoding: .utf8)
            print("Successfully saved to \(path)")
        } catch {
            print("Failed to save to \(path): \(error)")
        }
    }
    
    private func importProfile() {
        let openPanel = NSOpenPanel()
        openPanel.title = "Import Environment Variables"
        openPanel.allowedFileTypes = ["json"]
        openPanel.allowsMultipleSelection = false
        
        openPanel.begin { response in
            if response == .OK, let url = openPanel.url {
                do {
                    let data = try Data(contentsOf: url)
                    let decoder = JSONDecoder()
                    let importData = try decoder.decode(ExportData.self, from: data)
                    
                    // Find or create profile
                    let profileName = importData.profileName
                    let home = ProcessInfo.processInfo.environment["HOME"] ?? NSHomeDirectory()
                    
                    // Map common profile names to their actual files
                    let profileMapping = [
                        "zshrc": ".zshrc",
                        "bash_profile": ".bash_profile",
                        "bashrc": ".bashrc",
                        "profile": ".profile"
                    ]
                    
                    let actualFileName = profileMapping[profileName] ?? profileName
                    let profilePath = home + "/" + actualFileName
                    
                    // Update existing profile or create new one
                    let updatedVars = importData.envVars
                    self.saveEnvVars(updatedVars, to: profilePath)
                    
                    // Ensure the file exists if it doesn't
                    if !FileManager.default.fileExists(atPath: profilePath) {
                        FileManager.default.createFile(atPath: profilePath, contents: nil)
                    }
                    
                    // Reload profiles
                    self.loadShellProfiles()
                    
                    print("Successfully imported from \(url)")
                } catch {
                    print("Failed to import: \(error)")
                }
            }
        }
    }
}

struct ExportData: Codable {
    let profileName: String
    let envVars: [EnvVar]
    
    enum CodingKeys: String, CodingKey {
        case profileName = "profile_name"
        case envVars = "environment_variables"
    }
}

extension EnvVar: Codable {
    enum CodingKeys: String, CodingKey {
        case key
        case value
    }
}

#Preview {
    ContentView()
}
