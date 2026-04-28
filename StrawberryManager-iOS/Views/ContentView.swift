// ContentView.swift
// Root navigation controller - Updated with proper dependency injection

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var connectionViewModel: ConnectionViewModel
    
    var body: some View {
        Group {
            switch connectionViewModel.state {
            case .idle, .connecting, .error, .needsAuth:
                ConnectView()
            case .connected:
                // Create dashboard with proper API service initialization
                if let api = connectionViewModel.api,
                   let baseURL = URL(string: connectionViewModel.serverAddress) {
                    DashboardView(
                        apiService: api,
                        baseURL: baseURL,
                        token: connectionViewModel.token
                    )
                } else {
                    // Fallback to connect screen if API not initialized
                    ConnectView()
                }
            }
        }
        .animation(.easeInOut, value: connectionViewModel.state)
    }
}

#Preview {
    ContentView()
        .environmentObject(ConnectionViewModel())
}
