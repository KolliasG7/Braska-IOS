// ControlTab.swift
// Control tab for fan and LED settings

import SwiftUI

struct ControlTab: View {
    @StateObject var viewModel: ControlViewModel
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Error message
                if let error = viewModel.errorMessage {
                    ErrorBanner(message: error) {
                        viewModel.errorMessage = nil
                    }
                }
                
                // Fan Control Card
                FanControlCard(viewModel: viewModel)
                
                // LED Control Card
                LEDControlCard(viewModel: viewModel)
                
                // Power Controls
                PowerControlsCard()
            }
            .padding()
        }
        .background(Color.appBackground)
    }
}

// Fan Control Card
struct FanControlCard: View {
    @ObservedObject var viewModel: ControlViewModel
    @State private var tempThreshold: Double
    
    init(viewModel: ControlViewModel) {
        self.viewModel = viewModel
        _tempThreshold = State(initialValue: Double(viewModel.currentFanThreshold))
    }
    
    var body: some View {
        TelemetryCard(
            title: "Fan Control",
            icon: "fan",
            accentColor: Color.fanThresholdColor(for: Int(tempThreshold))
        ) {
            VStack(spacing: 20) {
                // Large display
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text("\(Int(tempThreshold))")
                        .font(.system(size: 56, weight: .bold, design: .rounded))
                        .foregroundStyle(Color.fanThresholdColor(for: Int(tempThreshold)))
                    
                    Text("°C")
                        .font(.title)
                        .foregroundStyle(.secondary)
                }
                
                // Slider
                VStack(spacing: 8) {
                    Slider(value: $tempThreshold, in: -10...80, step: 1)
                        .tint(Color.fanThresholdColor(for: Int(tempThreshold)))
                        .disabled(viewModel.isUpdatingFan)
                    
                    HStack {
                        Text("-10°C")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        
                        Spacer()
                        
                        Text("80°C")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                
                // Apply button
                Button {
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    viewModel.setFanThreshold(Int(tempThreshold))
                } label: {
                    if viewModel.isUpdatingFan {
                        HStack {
                            ProgressView()
                                .progressViewStyle(.circular)
                            Text("Applying...")
                        }
                        .frame(maxWidth: .infinity)
                    } else {
                        Text("Apply Threshold")
                            .frame(maxWidth: .infinity)
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(
                    viewModel.isUpdatingFan || 
                    Int(tempThreshold) == viewModel.currentFanThreshold
                )
                
                // Info text
                Text("Lower threshold = Fan starts cooling earlier")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .onChange(of: viewModel.currentFanThreshold) { _, newValue in
            tempThreshold = Double(newValue)
        }
    }
}

// LED Control Card
struct LEDControlCard: View {
    @ObservedObject var viewModel: ControlViewModel
    
    var body: some View {
        TelemetryCard(
            title: "LED Control",
            icon: "lightbulb.led",
            accentColor: .yellow
        ) {
            VStack(spacing: 16) {
                // Current selection
                HStack {
                    Circle()
                        .fill(ledColor(for: viewModel.selectedLEDProfile))
                        .frame(width: 32, height: 32)
                    
                    Text(viewModel.selectedLEDProfile.capitalized)
                        .font(.title3.weight(.semibold))
                    
                    Spacer()
                }
                
                // LED profile picker
                if !viewModel.availableLEDProfiles.isEmpty {
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 12) {
                        ForEach(viewModel.availableLEDProfiles, id: \.self) { profile in
                            LEDProfileButton(
                                profile: profile,
                                isSelected: viewModel.selectedLEDProfile == profile,
                                isUpdating: viewModel.isUpdatingLED
                            ) {
                                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                viewModel.setLEDProfile(profile)
                            }
                        }
                    }
                } else {
                    Text("Loading profiles...")
                        .foregroundStyle(.secondary)
                        .padding()
                }
            }
        }
    }
    
    private func ledColor(for profile: String) -> Color {
        switch profile.lowercased() {
        case "white", "white_pulsing": return .white
        case "blue", "blue_pulsing": return .blue
        case "red", "red_pulsing": return .red
        case "green": return .green
        case "pink": return .pink
        case "off": return .gray
        default: return .white
        }
    }
}

// LED Profile Button
struct LEDProfileButton: View {
    let profile: String
    let isSelected: Bool
    let isUpdating: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Circle()
                    .fill(ledColor)
                    .frame(width: 40, height: 40)
                    .overlay {
                        if isSelected {
                            Circle()
                                .stroke(Color.blue, lineWidth: 3)
                        }
                    }
                
                Text(profile.capitalized)
                    .font(.caption2)
                    .foregroundStyle(.primary)
                    .lineLimit(1)
            }
        }
        .disabled(isUpdating)
        .opacity(isUpdating && !isSelected ? 0.5 : 1)
    }
    
    private var ledColor: Color {
        switch profile.lowercased() {
        case "white", "white_pulsing": return .white
        case "blue", "blue_pulsing": return .blue
        case "red", "red_pulsing": return .red
        case "green": return .green
        case "pink": return .pink
        case "off": return .gray
        default: return .white
        }
    }
}

// Power Controls Card
struct PowerControlsCard: View {
    @State private var showingPowerAlert = false
    @State private var selectedPowerAction: PowerAction?
    
    enum PowerAction {
        case shutdown
        case reboot
        
        var title: String {
            switch self {
            case .shutdown: return "Shutdown"
            case .reboot: return "Reboot"
            }
        }
        
        var message: String {
            switch self {
            case .shutdown: return "Are you sure you want to shutdown the PS4?"
            case .reboot: return "Are you sure you want to reboot the PS4?"
            }
        }
        
        var icon: String {
            switch self {
            case .shutdown: return "power"
            case .reboot: return "arrow.clockwise"
            }
        }
    }
    
    var body: some View {
        TelemetryCard(
            title: "Power",
            icon: "bolt.circle",
            accentColor: .red
        ) {
            HStack(spacing: 12) {
                Button {
                    selectedPowerAction = .reboot
                    showingPowerAlert = true
                } label: {
                    Label("Reboot", systemImage: "arrow.clockwise")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .tint(.orange)
                
                Button {
                    selectedPowerAction = .shutdown
                    showingPowerAlert = true
                } label: {
                    Label("Shutdown", systemImage: "power")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .tint(.red)
            }
        }
        .alert(
            selectedPowerAction?.title ?? "Power Action",
            isPresented: $showingPowerAlert,
            presenting: selectedPowerAction
        ) { action in
            Button("Cancel", role: .cancel) {}
            Button(action.title, role: .destructive) {
                // Perform power action
                print("[PowerControls] \(action.title) action triggered")
            }
        } message: { action in
            Text(action.message)
        }
    }
}

// Error Banner
struct ErrorBanner: View {
    let message: String
    let onDismiss: () -> Void
    
    var body: some View {
        HStack {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.red)
            
            Text(message)
                .font(.subheadline)
                .foregroundStyle(.primary)
            
            Spacer()
            
            Button {
                onDismiss()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .background(Color.red.opacity(0.15))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

#Preview {
    let mockAPI = APIService(baseURL: URL(string: "http://localhost")!, token: "")
    let viewModel = ControlViewModel(apiService: mockAPI)
    viewModel.availableLEDProfiles = ["white", "blue", "red", "green", "pink", "white_pulsing", "blue_pulsing", "off"]
    
    return NavigationStack {
        ControlTab(viewModel: viewModel)
            .navigationTitle("Control")
    }
}
