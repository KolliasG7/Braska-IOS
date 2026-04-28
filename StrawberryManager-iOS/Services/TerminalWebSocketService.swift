// TerminalWebSocketService.swift
// WebSocket service for terminal PTY connection

import Foundation
import Combine

class TerminalWebSocketService: NSObject, ObservableObject {
    @Published var output: String = ""
    @Published var isConnected: Bool = false
    
    private var webSocketTask: URLSessionWebSocketTask?
    private var baseURL: URL
    private var token: String
    private var reconnectTimer: Timer?
    private var reconnectAttempts = 0
    
    init(baseURL: URL, token: String) {
        self.baseURL = baseURL
        self.token = token
        super.init()
    }
    
    func connect() {
        var wsURLString = baseURL.absoluteString
        if wsURLString.hasPrefix("https://") {
            wsURLString = wsURLString.replacingOccurrences(of: "https://", with: "wss://")
        } else if wsURLString.hasPrefix("http://") {
            wsURLString = wsURLString.replacingOccurrences(of: "http://", with: "ws://")
        } else {
            wsURLString = "ws://\(wsURLString)"
        }
        
        guard let wsURL = URL(string: "\(wsURLString)/ws/terminal") else { return }
        
        var request = URLRequest(url: wsURL)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        webSocketTask = URLSession.shared.webSocketTask(with: request)
        webSocketTask?.resume()
        
        isConnected = true
        receiveMessage()
    }
    
    private func receiveMessage() {
        webSocketTask?.receive { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .success(let message):
                switch message {
                case .string(let text):
                    DispatchQueue.main.async {
                        self.output += text
                    }
                case .data(let data):
                    if let text = String(data: data, encoding: .utf8) {
                        DispatchQueue.main.async {
                            self.output += text
                        }
                    }
                @unknown default:
                    break
                }
                self.receiveMessage()
                
            case .failure:
                DispatchQueue.main.async {
                    self.isConnected = false
                }
            }
        }
    }
    
    func sendInput(_ text: String) {
        let message = URLSessionWebSocketTask.Message.string(text)
        webSocketTask?.send(message) { error in
            if let error = error {
                print("[TerminalWebSocket] Send error: \(error)")
            }
        }
    }
    
    func sendResize(cols: Int, rows: Int) {
        let json = "{\"type\":\"resize\",\"cols\":\(cols),\"rows\":\(rows)}"
        sendInput(json)
    }
    
    func disconnect() {
        webSocketTask?.cancel(with: .goingAway, reason: nil)
        webSocketTask = nil
        isConnected = false
    }
    
    deinit {
        disconnect()
    }
}
