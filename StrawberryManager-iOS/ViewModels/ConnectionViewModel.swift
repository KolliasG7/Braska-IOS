// ConnectionViewModel.swift
// Manages connection state and authentication - Updated

import Foundation
import Combine

@MainActor
class ConnectionViewModel: ObservableObject {
    @Published var state: ConnectionState = .idle
    @Published var serverAddress: String = ""
    @Published var isTunnel: Bool = false
    @Published var token: String = ""
    
    private(set) var apiService: APIService?
    var api: APIService? { apiService }
    
    private var cancellables = Set<AnyCancellable>()
    private let storageService = StorageService.shared
    
    init() {
        loadSavedConnection()
    }
    
    func loadSavedConnection() {
        if let savedAddress = storageService.serverAddress {
            serverAddress = savedAddress
            isTunnel = storageService.isTunnel
            token = storageService.authToken ?? ""
            
            // Auto-connect if we have a saved address
            if !savedAddress.isEmpty {
                connect()
            }
        }
    }
    
    func connect() {
        state = .connecting
        
        let urlString = detectTunnel(serverAddress) ? 
            (serverAddress.hasPrefix("http") ? serverAddress : "https://\(serverAddress)") :
            "http://\(serverAddress)"
        
        guard let url = URL(string: urlString) else {
            state = .error("Invalid server address")
            return
        }
        
        let savedToken = storageService.authToken ?? ""
        apiService = APIService(baseURL: url, token: savedToken)
        
        apiService?.getHealth()
            .sink { [weak self] completion in
                if case .failure(let error) = completion {
                    self?.state = .error(error.localizedDescription)
                }
            } receiveValue: { [weak self] health in
                guard let self = self else { return }
                
                if health.authRequired == true {
                    // Check if saved token is valid
                    self.verifyAuthentication()
                } else {
                    // No auth required
                    self.completeConnection()
                }
            }
            .store(in: &cancellables)
    }
    
    func login(password: String) {
        guard let api = apiService else { return }
        
        api.login(password: password)
            .sink { [weak self] completion in
                if case .failure(let error) = completion {
                    self?.state = .error(error.localizedDescription)
                }
            } receiveValue: { [weak self] newToken in
                self?.token = newToken
                self?.storageService.authToken = newToken
                self?.apiService?.updateToken(newToken)
                self?.completeConnection()
            }
            .store(in: &cancellables)
    }
    
    func disconnect() {
        state = .idle
        cancellables.removeAll()
    }
    
    func disconnectAndForget() {
        disconnect()
        storageService.clearAll()
        serverAddress = ""
        token = ""
    }
    
    func clearToken() {
        storageService.authToken = nil
        token = ""
    }
    
    // MARK: - Private Methods
    
    private func verifyAuthentication() {
        apiService?.verifyToken()
            .sink { [weak self] completion in
                if case .failure = completion {
                    self?.state = .needsAuth
                }
            } receiveValue: { [weak self] isValid in
                if isValid {
                    self?.completeConnection()
                } else {
                    self?.state = .needsAuth
                }
            }
            .store(in: &cancellables)
    }
    
    private func completeConnection() {
        storageService.serverAddress = serverAddress
        storageService.isTunnel = isTunnel
        state = .connected
    }
    
    private func detectTunnel(_ address: String) -> Bool {
        address.hasPrefix("https://") ||
        address.hasPrefix("http://") ||
        address.contains(".trycloudflare.com") ||
        address.contains(".cloudflare")
    }
}
