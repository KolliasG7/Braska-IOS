// TerminalView.swift
// Interactive terminal view

import SwiftUI

struct TerminalView: View {
    @StateObject private var terminalService: TerminalWebSocketService
    @State private var inputText: String = ""
    @State private var isKeyboardVisible: Bool = false
    
    init(baseURL: URL, token: String) {
        _terminalService = StateObject(wrappedValue: TerminalWebSocketService(baseURL: baseURL, token: token))
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Terminal output
            ScrollView {
                ScrollViewReader { proxy in
                    Text(terminalService.output.isEmpty ? "Connecting to terminal..." : terminalService.output)
                        .font(.system(.body, design: .monospaced))
                        .foregroundStyle(.green)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                        .id("terminalOutput")
                        .onChange(of: terminalService.output) { _, _ in
                            proxy.scrollTo("terminalOutput", anchor: .bottom)
                        }
                }
            }
            .background(Color.black)
            
            // Input bar
            HStack(spacing: 8) {
                TextField("Enter command", text: $inputText)
                    .textFieldStyle(.roundedBorder)
                    .autocapitalization(.none)
                    .autocorrectionDisabled()
                    .onSubmit {
                        sendCommand()
                    }
                
                Button("Send") {
                    sendCommand()
                }
                .buttonStyle(.borderedProminent)
                .disabled(inputText.isEmpty)
                
                Button {
                    terminalService.sendInput("\u{03}") // Ctrl+C
                } label: {
                    Image(systemName: "xmark.circle")
                }
                .buttonStyle(.bordered)
                .tint(.red)
            }
            .padding()
            .background(Color.appSecondaryBackground)
        }
        .navigationTitle("Terminal")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    terminalService.output = ""
                } label: {
                    Image(systemName: "trash")
                }
            }
        }
        .onAppear {
            terminalService.connect()
        }
        .onDisappear {
            terminalService.disconnect()
        }
    }
    
    private func sendCommand() {
        guard !inputText.isEmpty else { return }
        terminalService.sendInput(inputText + "\n")
        inputText = ""
    }
}

#Preview {
    NavigationStack {
        TerminalView(baseURL: URL(string: "http://localhost")!, token: "")
    }
}
