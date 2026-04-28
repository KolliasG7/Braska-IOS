// FilesView.swift
// File browser view

import SwiftUI

struct FilesView: View {
    @StateObject var viewModel: FilesViewModel
    @State private var showingDeleteAlert = false
    @State private var fileToDelete: FileItem?
    
    var body: some View {
        VStack(spacing: 0) {
            // Current path
            HStack {
                Button {
                    viewModel.navigateUp()
                } label: {
                    Image(systemName: "arrow.up")
                }
                .disabled(viewModel.currentPath == "/")
                
                ScrollView(.horizontal, showsIndicators: false) {
                    Text(viewModel.currentPath)
                        .font(.system(.caption, design: .monospaced))
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
            }
            .padding()
            .background(Color.appSecondaryBackground)
            
            if viewModel.isLoading {
                ProgressView()
                    .frame(maxHeight: .infinity)
            } else if viewModel.files.isEmpty {
                ContentUnavailableView(
                    "No Files",
                    systemImage: "folder",
                    description: Text("This directory is empty")
                )
            } else {
                List {
                    ForEach(viewModel.files) { file in
                        FileRow(file: file) {
                            if file.isDirectory {
                                viewModel.loadDirectory(file.path)
                            }
                        } onDelete: {
                            fileToDelete = file
                            showingDeleteAlert = true
                        }
                    }
                }
                .listStyle(.plain)
            }
        }
        .navigationTitle("Files")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button {
                        // Upload action
                    } label: {
                        Label("Upload File", systemImage: "arrow.up.doc")
                    }
                    
                    Button {
                        viewModel.loadDirectory(viewModel.currentPath)
                    } label: {
                        Label("Refresh", systemImage: "arrow.clockwise")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .alert("Delete File", isPresented: $showingDeleteAlert, presenting: fileToDelete) { file in
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                viewModel.deleteFile(file)
            }
        } message: { file in
            Text("Are you sure you want to delete '\(file.name)'?")
        }
    }
}

struct FileRow: View {
    let file: FileItem
    let onTap: () -> Void
    let onDelete: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack {
                Image(systemName: file.isDirectory ? "folder.fill" : "doc.fill")
                    .foregroundStyle(file.isDirectory ? .blue : .gray)
                    .frame(width: 24)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(file.name)
                        .foregroundStyle(.primary)
                    
                    if !file.isDirectory {
                        Text(formatFileSize(file.size))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                
                Spacer()
                
                if file.isDirectory {
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
            Button(role: .destructive) {
                onDelete()
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
    }
    
    private func formatFileSize(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB, .useGB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }
}

#Preview {
    let mockAPI = APIService(baseURL: URL(string: "http://localhost")!, token: "")
    NavigationStack {
        FilesView(viewModel: FilesViewModel(apiService: mockAPI))
    }
}
