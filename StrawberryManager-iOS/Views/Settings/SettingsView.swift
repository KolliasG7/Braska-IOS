// SettingsView.swift
// App settings screen

import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var connectionViewModel: ConnectionViewModel
    @Environment(\.dismiss) var dismiss
    
    @AppStorage("show_cpu_graph") private var showCPUGraph = true
    @AppStorage("show_ram_graph") private var showRAMGraph = true
    @AppStorage("show_thermal_graph") private var showThermalGraph = true
    @AppStorage("show_notifications") private var showNotifications = true
    @AppStorage("reduce_motion") private var reduceMotion = false
    
    @State private var showingPasswordSheet = false
    @State private var showingDisconnectAlert = false
    
    var body: some View {
        NavigationStack {
            Form {
                // Connection section
                Section {
                    HStack {
                        Text("Server")
                        Spacer()
                        Text(connectionViewModel.serverAddress)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                    
                    Button(role: .destructive) {
                        showingDisconnectAlert = true
                    } label: {
                        Label("Disconnect", systemImage: "power")
                    }
                } header: {
                    Text("Connection")
                }
                
                // Display preferences
                Section {
                    Toggle("Show CPU Graph", isOn: $showCPUGraph)
                    Toggle("Show RAM Graph", isOn: $showRAMGraph)
                    Toggle("Show Thermal Graph", isOn: $showThermalGraph)
                } header: {
                    Text("Graphs")
                }
                
                // Notifications
                Section {
                    Toggle("Show Notifications", isOn: $showNotifications)
                } header: {
                    Text("Notifications")
                } footer: {
                    Text("Receive status notifications for temperature alerts")
                }
                
                // Accessibility
                Section {
                    Toggle("Reduce Motion", isOn: $reduceMotion)
                } header: {
                    Text("Accessibility")
                }
                
                // Security
                Section {
                    Button {
                        showingPasswordSheet = true
                    } label: {
                        Label("Change Password", systemImage: "key")
                    }
                    
                    Button(role: .destructive) {
                        connectionViewModel.clearToken()
                    } label: {
                        Label("Clear Saved Token", systemImage: "trash")
                    }
                } header: {
                    Text("Security")
                }
                
                // About
                Section {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0.0")
                            .foregroundStyle(.secondary)
                    }
                    
                    Link(destination: URL(string: "https://github.com/KolliasG7/Strawberry-Manager---Reworked")!) {
                        HStack {
                            Text("GitHub Repository")
                            Spacer()
                            Image(systemName: "arrow.up.right.square")
                                .foregroundStyle(.secondary)
                        }
                    }
                } header: {
                    Text("About")
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showingPasswordSheet) {
                ChangePasswordView()
            }
            .alert("Disconnect", isPresented: $showingDisconnectAlert) {
                Button("Cancel", role: .cancel) {}
                Button("Disconnect", role: .destructive) {
                    connectionViewModel.disconnectAndForget()
                    dismiss()
                }
            } message: {
                Text("This will disconnect from the server and clear all saved data.")
            }
        }
    }
}

// Change Password Sheet
struct ChangePasswordView: View {
    @Environment(\.dismiss) var dismiss
    @State private var currentPassword = ""
    @State private var newPassword = ""
    @State private var confirmPassword = ""
    @State private var errorMessage: String?
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    SecureField("Current Password", text: $currentPassword)
                    SecureField("New Password", text: $newPassword)
                    SecureField("Confirm New Password", text: $confirmPassword)
                } header: {
                    Text("Change Password")
                } footer: {
                    if let error = errorMessage {
                        Text(error)
                            .foregroundStyle(.red)
                    }
                }
            }
            .navigationTitle("Change Password")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        changePassword()
                    }
                    .disabled(!canSave)
                }
            }
        }
    }
    
    private var canSave: Bool {
        !currentPassword.isEmpty &&
        !newPassword.isEmpty &&
        newPassword == confirmPassword &&
        newPassword.count >= 4
    }
    
    private func changePassword() {
        if newPassword != confirmPassword {
            errorMessage = "Passwords don't match"
            return
        }
        
        // Implement password change via API
        // For now, just dismiss
        dismiss()
    }
}

#Preview {
    SettingsView()
        .environmentObject(ConnectionViewModel())
}
