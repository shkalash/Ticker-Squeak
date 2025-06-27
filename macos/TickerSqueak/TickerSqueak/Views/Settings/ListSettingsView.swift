//
//  ListSettingsView.swift
//  TickerSqueak
//
//  Created by Shai Kalev on 6/26/25.
//


import SwiftUI
import Combine

// The main, internal view for the list behavior settings.
struct ListSettingsView_Content: View {
    
    @StateObject private var viewModel: ListSettingsViewModel

    init(dependencies: any AppDependencies) {
        _viewModel = StateObject(wrappedValue: ListSettingsViewModel(dependencies: dependencies))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("List Settings")
                .font(.headline)
            
            // MARK: - Removal Delay Section
            
            // This custom binding converts the ViewModel's TimeInterval (seconds)
            // into a String (minutes) for the TextField.
            let minutesBinding = Binding<String>(
                get: {
                    "\(Int(viewModel.hidingTimeout / 60))"
                },
                set: {
                    if let minutes = Int($0), minutes >= 0 {
                        viewModel.setHideTimout(to: TimeInterval(minutes * 60))
                    }
                }
            )
            
            HStack {
                Text("Hide Ticker Cooldown")
                Spacer()
                
                // Decrement Button
                Button(action: {
                    let newDelay = max(0, viewModel.hidingTimeout - 60)
                    viewModel.setHideTimout(to: newDelay)
                }) {
                    Image(systemName: "minus.circle")
                }
                .buttonStyle(.borderless)
                
                // Editable Text Field
                TextField("", text: minutesBinding)
                    .multilineTextAlignment(.center)
                    .frame(width: 40)
                    .textFieldStyle(.roundedBorder)
                    .onReceive(Just(minutesBinding.wrappedValue)) { newValue in
                        let filtered = newValue.filter { "0123456789".contains($0) }
                        if filtered != newValue {
                            minutesBinding.wrappedValue = filtered
                        }
                    }

                // Increment Button
                Button(action: {
                    viewModel.setHideTimout(to: viewModel.hidingTimeout + 60)
                }) {
                    Image(systemName: "plus.circle")
                }
                .buttonStyle(.borderless)
                
                Text("minutes")
                    .frame(width: 60, alignment: .leading)
            }
            
            // MARK: - Snooze Clear Time Section
            
            HStack {
                Text("Clear Snooze List Daily at:")
                Spacer()
                
                DatePicker(
                    "Snooze Clear Time",
                    selection: Binding(
                        get: { viewModel.snoozeClearTime },
                        set: { viewModel.setSnoozeClearTime(to: $0) }
                    ),
                    displayedComponents: .hourAndMinute
                )
                .datePickerStyle(.stepperField)
                .labelsHidden()
            }
        }
        .padding()
    }
}


/// The public-facing "loader" view.
struct ListSettingsView: View {
    @EnvironmentObject private var dependencies: DependencyContainer

    var body: some View {
        ListSettingsView_Content(dependencies: dependencies)
    }
}


#Preview {
    let previewDependencies = PreviewDependencyContainer()
    
    return ListSettingsView_Content(dependencies: previewDependencies)
        .environmentObject(previewDependencies)
        .frame(width: 350)
}
