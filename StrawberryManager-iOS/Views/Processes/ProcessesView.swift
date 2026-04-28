// ProcessesView.swift
// Process manager view

import SwiftUI

struct ProcessesView: View {
    @StateObject var viewModel: ProcessesViewModel
    @State private var showingKillAlert = false
    @State private var processToKill: ProcessInfo?
    @State private var selectedSignal: String = "SIGTERM"
    
    var body: some View {
        List {
            ForEach(viewModel.processes) { process in
                ProcessRow(process: process) {
                    processToKill = process
                    showingKillAlert = true
                }
            }
        }
        .listStyle(.plain)
        .refreshable {
            viewModel.loadProcesses()
        }
        .navigationTitle("Processes")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Menu {
                    Picker("Sort By", selection: $viewModel.sortBy) {
                        ForEach(ProcessesViewModel.SortOption.allCases, id: \.self) { option in
                            Text(option.displayName).tag(option)
                        }
                    }
                } label: {
                    Label("Sort", systemImage: "arrow.up.arrow.down")
                }
            }
            
            ToolbarItem(placement: .topBarTrailing) {
                Toggle(isOn: $viewModel.autoRefresh) {
                    Image(systemName: "arrow.clockwise")
                }
                .toggleStyle(.button)
            }
        }
        .onChange(of: viewModel.sortBy) { _, _ in
            viewModel.loadProcesses()
        }
        .onChange(of: viewModel.autoRefresh) { _, _ in
            viewModel.toggleAutoRefresh()
        }
        .alert("Kill Process", isPresented: $showingKillAlert, presenting: processToKill) { process in
            Button("Cancel", role: .cancel) {}
            Button("SIGTERM") {
                viewModel.killProcess(process, signal: "SIGTERM")
            }
            Button("SIGKILL", role: .destructive) {
                viewModel.killProcess(process, signal: "SIGKILL")
            }
        } message: { process in
            Text("Kill process '\(process.name)' (PID: \(process.pid))?")
        }
    }
}

struct ProcessRow: View {
    let process: ProcessInfo
    let onKill: () -> Void
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(process.name)
                    .font(.headline)
                
                HStack(spacing: 12) {
                    Label(String(format: "%.0f%%", process.cpuPct), systemImage: "cpu")
                        .font(.caption)
                        .foregroundStyle(.cyan)
                    
                    Label(String(format: "%.0f MB", process.memRssMb), systemImage: "memorychip")
                        .font(.caption)
                        .foregroundStyle(.purple)
                    
                    Text("PID: \(process.pid)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            
            Spacer()
        }
        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
            Button(role: .destructive) {
                onKill()
            } label: {
                Label("Kill", systemImage: "xmark.circle")
            }
        }
    }
}

#Preview {
    let mockAPI = APIService(baseURL: URL(string: "http://localhost")!, token: "")
    NavigationStack {
        ProcessesView(viewModel: ProcessesViewModel(apiService: mockAPI))
    }
}
