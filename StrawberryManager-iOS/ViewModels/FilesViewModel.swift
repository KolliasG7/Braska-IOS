// FilesViewModel.swift
// File manager view model

import Foundation
import Combine
import UniformTypeIdentifiers

struct FileItem: Identifiable, Codable {
    let name: String
    let path: String
    let isDirectory: Bool
    let size: Int64
    let modifiedTime: String?
    
    var id: String { path }
    
    enum CodingKeys: String, CodingKey {
        case name, path
        case isDirectory = "is_directory"
        case size
        case modifiedTime = "modified_time"
    }
}

struct DirectoryListing: Codable {
    let path: String
    let files: [FileItem]
}

@MainActor
class FilesViewModel: ObservableObject {
    @Published var currentPath: String = "/user/home"
    @Published var files: [FileItem] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    
    private let apiService: APIService
    private var cancellables = Set<AnyCancellable>()
    
    init(apiService: APIService) {
        self.apiService = apiService
        loadDirectory(currentPath)
    }
    
    func loadDirectory(_ path: String) {
        isLoading = true
        errorMessage = nil
        
        // Note: Simplified - actual API call would need implementation
        // in APIService for file listing
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            self?.isLoading = false
            // Mock data for now
            self?.files = [
                FileItem(name: "documents", path: "\(path)/documents", isDirectory: true, size: 0, modifiedTime: nil),
                FileItem(name: "downloads", path: "\(path)/downloads", isDirectory: true, size: 0, modifiedTime: nil),
                FileItem(name: "file.txt", path: "\(path)/file.txt", isDirectory: false, size: 1024, modifiedTime: "2024-01-01"),
            ]
            self?.currentPath = path
        }
    }
    
    func navigateUp() {
        guard currentPath != "/" else { return }
        let components = currentPath.split(separator: "/")
        if components.count > 1 {
            let parentPath = "/" + components.dropLast().joined(separator: "/")
            loadDirectory(parentPath)
        } else {
            loadDirectory("/")
        }
    }
    
    func deleteFile(_ file: FileItem) {
        // Implement file deletion
        files.removeAll { $0.id == file.id }
    }
}
