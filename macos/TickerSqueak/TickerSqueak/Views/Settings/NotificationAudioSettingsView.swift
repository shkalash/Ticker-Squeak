//
//  NotificationAudioSettingsView.swift
//  TickerSqueak
//
//  Created by Shai Kalev on 6/26/25.
//


import SwiftUI

// The main, internal view for the notification audio settings.
struct NotificationAudioSettingsView_Content: View {
    
    @StateObject private var viewModel: NotificationAudioSettingsViewModel

    init(dependencies: any AppDependencies) {
        _viewModel = StateObject(wrappedValue: NotificationAudioSettingsViewModel(dependencies: dependencies))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Dynamically create a picker for each sound type defined in the SoundLibrary.
            ForEach(SoundLibrary.SoundType.allCases, id: \.self) { soundType in
                SoundPickerRow(
                    soundType: soundType,
                    availableSounds: viewModel.availableSounds,
                    selectedSound: viewModel.soundLibrary.getSound(for: soundType),
                    onSelect: { newSoundName in
                        viewModel.setSound(for: soundType, to: newSoundName)
                    },
                    onPlay: {
                        viewModel.playSound(for: soundType)
                    }
                )
            }
        }
        .padding()
    }
}

/// A reusable view for a single sound picker row.
private struct SoundPickerRow: View {
    let soundType: SoundLibrary.SoundType
    let availableSounds: [String]
    let selectedSound: String
    let onSelect: (String) -> Void
    let onPlay: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            // Label for the sound type
            Text(soundType.rawValue)
                .font(.headline)

            // Picker and Play button
            HStack {
                Picker(soundType.rawValue, selection: Binding(
                    get: { selectedSound },
                    set: { onSelect($0) }
                )) {
                    ForEach(availableSounds, id: \.self) { sound in
                        Text(sound).tag(sound)
                    }
                }
                .labelsHidden()
                .frame(maxWidth: 250)

                Button {
                    onPlay()
                } label: {
                    Image(systemName: "play.circle.fill")
                }
                .help("Play selected sound")
            }
        }
    }
}


/// The public-facing "loader" view.
struct NotificationAudioSettingsView: View {
    @EnvironmentObject private var dependencies: DependencyContainer

    var body: some View {
        NotificationAudioSettingsView_Content(dependencies: dependencies)
    }
}


#Preview {
    let previewDependencies = PreviewDependencyContainer()
    
    return NotificationAudioSettingsView_Content(dependencies: previewDependencies)
        .environmentObject(previewDependencies)
        .frame(width: 400)
}
